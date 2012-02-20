package com.robotacid.engine {
	
	import com.robotacid.ai.Brain;
	import com.robotacid.ai.PlayerBrain;
	import com.robotacid.dungeon.Map;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Portal;
	import com.robotacid.geom.Pixel;
	import com.robotacid.gfx.CanvasCamera;
	import com.robotacid.phys.Cast;
	import com.robotacid.engine.Character;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.menu.GameMenu;
	import com.robotacid.ui.menu.InventoryMenuList;
	import com.robotacid.util.HiddenInt;
	import com.robotacid.util.HiddenNumber;
	import com.robotacid.geom.Line;
	import com.robotacid.engine.MapTileManager;
	import com.robotacid.geom.Trig;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.events.Event;
	import flash.display.BlendMode;
	
	/**
	* Platform game character
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class Player extends Character{
		
		// properties
		
		public var xp:Number;
		//public var mapRect:Rectangle;
		public var inventory:InventoryMenuList;
		public var disarmableTraps:Vector.<Trap>;
		public var cameraDisplacement:Point;
		public var camera:CanvasCamera;
		
		public var searchRadius:int;
		
		private var searchMax:int;
		private var searchCount:int;
		private var searchRevealCount:int;
		
		private var i:int, j:int;
		
		// states
		public var portalContact:Portal;
		
		public static var previousLevel:int = Map.OVERWORLD;
		public static var previousPortalType:int = Portal.STAIRS;
		public static var previousMapType:int = Map.AREA;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		public static const XP_LEVELS:Array = [0, 10, 20, 40, 80, 160, 320, 640, 1280, 2560, 5120, 10240, 20480, 40960, 81920, 163840, 327680, 655360, 1310720, 2621440, int.MAX_VALUE];
		
		public static const DEFAULT_LIGHT_RADIUS:int = 5;
		public static const SEARCH_DELAY:int = 2;
		public static const ROGUE_SEARCH_MAX:int = 20;
		public static const DEFAULT_SEARCH_MAX:int = 10;
		
		public static const CAMERA_DISPLACE_SPEED:Number = 1;
		public static const CAMERA_DISPLACEMENT:Number = 70;
		
		public static const DEFAULT_UNIQUE_NAME_STR:String = "rogue";
		
		public static var point:Point = new Point();
		
		public function Player(mc:DisplayObject, x:Number, y:Number) {
			super(mc, x, y, ROGUE, PLAYER, 1, false);
			
			active = true;
			
			// init states
			dir = RIGHT;
			actions = 0;
			looking = RIGHT | UP;
			active = true;
			callMain = false;
			stepNoise = true;
			searchRadius = -1;
			uniqueNameStr = DEFAULT_UNIQUE_NAME_STR;
			
			cameraDisplacement = new Point();
			
			// init properties
			missileIgnore |= Collider.PLAYER | Collider.MINION | Collider.PLAYER_MISSILE;
			
			game.lightMap.setLight(this, DEFAULT_LIGHT_RADIUS);
			
			disarmableTraps = new Vector.<Trap>();
			
			xp = 0;
			game.playerXpBar.setValue(0, 1);
			
			game.console.print("welcome rogue");
			
			inventory = game.menu.inventoryList;
			
			brain = new PlayerBrain(this);
			Brain.playerCharacters.push(this);
		}
		
		override public function createCollider(x:Number, y:Number, properties:int, ignoreProperties:int, state:int = 0, positionByBase:Boolean = true):void {
			super.createCollider(x, y, properties, ignoreProperties, state, positionByBase);
			collider.properties |= Collider.PLAYER;
			collider.ignoreProperties |= Collider.PLAYER | Collider.MINION | Collider.PLAYER_MISSILE;
			collider.stompProperties = Collider.MONSTER;
			collider.stackCallback = hitFloor;
		}
		
		private function hitFloor():void{
			game.soundQueue.add("thud");
		}
		
		// Loop
		override public function main():void{
			
			// keyboard input is managed from the PlayerBrain - thus psychological states can be inflicted upon the player
			if(state == WALKING) brain.main();
			
			super.main();
			
			// search for traps/secrets
			if(searchRadius > -1){
				if(actions || moving){
					searchRadius = -1;
					game.console.print("search abandoned");
					if(searchRevealCount == 0){
						game.console.print("found nothing");
					} else {
						game.console.print(searchRevealCount + " discover" + (searchRevealCount > 1 ? "ies" : "y"));
					}
				} else {
					if(searchCount) searchCount--;
					else {
						searchRadius++
						searchArea(searchRadius);
						if(
							(name == ROGUE && searchRadius >= ROGUE_SEARCH_MAX) ||
							(name != ROGUE && searchRadius >= DEFAULT_SEARCH_MAX)
						){
							searchRadius = -1;
							game.console.print("search complete");
							if(searchRevealCount == 0){
								game.console.print("found nothing");
							} else {
								game.console.print(searchRevealCount + " discover" + (searchRevealCount > 1 ? "ies" : "y"));
							}
						}
						searchCount = SEARCH_DELAY;
					}
				}
			}
			
			// update exiting a level
			if(state == EXITING){
				// capture the exit direction before we clear the reference to the portal
				var exitDir:int = portal.targetLevel > game.dungeon.level ? 1 : -1;
				var portalType:int = portal.type;
				var portalTargetLevel:int = portal.targetLevel;
				moving = true;
				if(portal.type == Portal.STAIRS){
					if(portal.targetLevel > game.dungeon.level){
						if(moveCount){
							if(dir == RIGHT) gfx.x += STAIRS_SPEED;
							else if(dir == LEFT) gfx.x -= STAIRS_SPEED;
							gfx.y += STAIRS_SPEED;
						}
						if(gfx.y >= (portal.mapY + 1) * Game.SCALE + PORTAL_DISTANCE) portal = null;
					} else if(portal.targetLevel < game.dungeon.level){
						if(moveCount){
							if(dir == RIGHT) gfx.x += STAIRS_SPEED;
							else if(dir == LEFT) gfx.x -= STAIRS_SPEED;
							gfx.y -= STAIRS_SPEED;
						}
						if(gfx.y <= (portal.mapY + 1) * Game.SCALE - PORTAL_DISTANCE) portal = null;
					}
				} else {
					if(dir == RIGHT){
						gfx.x += speed * collider.dampingX;
						if(gfx.x > (portal.mapX + 1) * Game.SCALE + PORTAL_DISTANCE) portal = null;
					} else if(dir == LEFT){
						gfx.x -= speed * collider.dampingX;
						if(gfx.x < portal.mapX * Game.SCALE - PORTAL_DISTANCE) portal = null;
					}
				}
				if(!portal){
					game.console.print(Portal.usageMsg(portalType, portalTargetLevel));
					game.transition.init(function():void{
						game.changeLevel(portalTargetLevel, portalType);
						// warm up the renderer
						renderer.main();
						if(game.dungeon.type != Map.AREA){
							for(i = 0; i < 8; i++){
								game.lightMap.main();
							}
							game.miniMap.render();
						}
					});
				}
			} else if(state == ENTERING){
				
			} else {
				if(portalContact){
					if(!portalContact.rect.intersects(collider) || state != Character.WALKING){
						portalContact = null;
						game.menu.exitLevelOption.active = false;
						game.menu.update();
					}
					// restore access to menu
					if(collider.world && !game.menu.actionsOption.active){
						game.menu.actionsOption.active = true;
						game.menu.inventoryOption.active = Boolean(game.menu.inventoryList.options.length);
						game.menu.update();
					}
					
				} else {
					// check for portals
					var portal:Portal;
					
					for(i = 0; i < game.portals.length; i++){
						portal = game.portals[i];
						if(portal.playerPortal && portal.rect.intersects(collider) && state == Character.WALKING){
							if(!portalContact){
								portalContact = portal
								game.menu.exitLevelOption.active = true;
								game.menu.update();
								game.menu.exitLevelOption.userData = portal;
								break;
							}
						}
					}
				}
			}
			
			// camera control based on intent and movement
			if(looking & RIGHT){
				if(cameraDisplacement.x < CAMERA_DISPLACEMENT){
					cameraDisplacement.x += CAMERA_DISPLACE_SPEED;
					if(dir & RIGHT) cameraDisplacement.x += CAMERA_DISPLACE_SPEED;
				}
			} else if(looking & LEFT){
				if(cameraDisplacement.x > -CAMERA_DISPLACEMENT){
					cameraDisplacement.x -= CAMERA_DISPLACE_SPEED;
					if(dir & LEFT) cameraDisplacement.x -= CAMERA_DISPLACE_SPEED;
				}
			} else {
				if(cameraDisplacement.x > 0) cameraDisplacement.x -= CAMERA_DISPLACE_SPEED;
				else if(cameraDisplacement.x < 0) cameraDisplacement.x += CAMERA_DISPLACE_SPEED;
			}
			if(looking & DOWN){
				if(cameraDisplacement.y < CAMERA_DISPLACEMENT){
					cameraDisplacement.y += CAMERA_DISPLACE_SPEED * 0.5;
					if(dir & DOWN) cameraDisplacement.y += CAMERA_DISPLACE_SPEED * 0.5;
				}
			} else if(looking & UP){
				if(cameraDisplacement.y > -CAMERA_DISPLACEMENT){
					cameraDisplacement.y -= CAMERA_DISPLACE_SPEED * 0.5;
					if(dir & UP) cameraDisplacement.y -= CAMERA_DISPLACE_SPEED * 0.5;
				}
			} else {
				if(cameraDisplacement.y > 0) cameraDisplacement.y -= CAMERA_DISPLACE_SPEED;
				else if(cameraDisplacement.y < 0) cameraDisplacement.y += CAMERA_DISPLACE_SPEED;
			}
			
		}
		
		/* Initiates a search for traps and secrets */
		public function search():void{
			if(searchRadius > -1) return;
			searchRadius = 0;
			searchCount = SEARCH_DELAY;
			searchRevealCount = 0;
			game.miniMap.triggerFlashPrompt();
		}
		
		/* Searches the border of a square described by the search radius */
		public function searchArea(radius:int):void{
			var r:int, c:int, i:int;
			var item:*;
			
			// note that this method is not optimised at all.
			// I started to inline everything and it looked like it was going to be a tedious several
			// hundred lines of for loops and if statements. The lack of movement demanded by the search
			// as a gameplay mechanic probably offsets the cpu load of this method.
			
			// top row
			r = mapY - radius;
			for(c = mapX - radius; c <= mapX + radius; c++){
				item = game.mapTileManager.getTile(c, r, MapTileManager.ENTITY_LAYER);
				if(item is Array){
					for(i = 0; i < item.length; i++){
						if((item[i] is Stone || item[i] is Trap) && !item[i].revealed){
							item[i].reveal();
							searchRevealCount++;
						}
					}
				} else {
					if((item is Stone || item is Trap) && !item.revealed){
						item.reveal();
						searchRevealCount++;
					}
				}
			}
			// bottom row
			r = mapY + radius;
			for(c = mapX - radius; c <= mapX + radius; c++){
				item = game.mapTileManager.getTile(c, r, MapTileManager.ENTITY_LAYER);
				if(item is Array){
					for(i = 0; i < item.length; i++){
						if((item[i] is Stone || item[i] is Trap) && !item[i].revealed){
							item[i].reveal();
							searchRevealCount++;
						}
					}
				} else {
					if((item is Stone || item is Trap) && !item.revealed){
						item.reveal();
						searchRevealCount++;
					}
				}
			}
			// left column
			c = mapX - radius;
			for(r = mapY - radius; r <= mapY + radius; r++){
				item = game.mapTileManager.getTile(c, r, MapTileManager.ENTITY_LAYER);
				if(item is Array){
					for(i = 0; i < item.length; i++){
						if((item[i] is Stone || item[i] is Trap) && !item[i].revealed){
							item[i].reveal();
							searchRevealCount++;
						}
					}
				} else {
					if((item is Stone || item is Trap) && !item.revealed){
						item.reveal();
						searchRevealCount++;
					}
				}
			}
			// right column
			c = mapX + radius;
			for(r = mapY - radius; r <= mapY + radius; r++){
				item = game.mapTileManager.getTile(c, r, MapTileManager.ENTITY_LAYER);
				if(item is Array){
					for(i = 0; i < item.length; i++){
						if((item[i] is Stone || item[i] is Trap) && !item[i].revealed){
							item[i].reveal();
							searchRevealCount++;
						}
					}
				} else {
					if((item is Stone || item is Trap) && !item.revealed){
						item.reveal();
						searchRevealCount++;
					}
				}
			}
		}
		
		public function snapCamera():void{
			renderer.camera.setTarget(
				collider.x +  collider.width * 0.5 +  cameraDisplacement.x,
				collider.y +  collider.height * 0.5 +  cameraDisplacement.y
			);
			renderer.camera.skipPan();
		}
		
		/* Various things that need to be hidden or killed upon death or finishing a level */
		public function tidyUp():void {
			gfx.visible = false;
			game.mousePressed = false;
			moving = false;
			mapX = mapY = 0;
		}
		
		/* Select an item as a weapon or armour */
		override public function equip(item:Item, throwing:Boolean = false):Item{
			super.equip(item, throwing);
			if(item.curseState == Item.CURSE_HIDDEN) item.revealCurse();
			// set the active state and name of the missile option in the menu
			if(item.type == Item.WEAPON){
				game.menu.missileOption.active = (
					!indifferent &&
					(
						(weapon && weapon.range & Item.MISSILE) ||
						(throwable && !(throwable.curseState == Item.CURSE_REVEALED && !undead))
					)
				);
				if(game.menu.missileOption.active){
					game.menu.missileOption.state = throwable ? GameMenu.THROW : GameMenu.SHOOT;
				}
			}
			inventory.updateItem(item);
			return item;
		}
		
		/* Unselect item as equipped */
		override public function unequip(item:Item):Item{
			if(item == throwable || (item.type == Item.WEAPON && item.range & Item.MISSILE)) game.menu.missileOption.active = false;
			super.unequip(item);
			inventory.updateItem(item);
			return item;
		}
		
		override public function death(cause:String = "crushing", decapitation:Boolean = false, aggressor:Character = null):void{
			if(!active) return;
			super.death(cause, decapitation);
			game.soundQueue.add("rogueDeath");
			if(!active){
				Brain.playerCharacters.splice(Brain.playerCharacters.indexOf(this), 1);
				game.menu.death();
				tidyUp();
			}
			renderer.shake(0, 5);
		}
		
		public function exitLevel(portal:Portal):void{
			// the player must be denied the opportunity to dick about whilst exiting a level
			game.menu.actionsOption.active = false;
			game.menu.inventoryOption.active = false;
			game.menu.update();
			this.portal = portal;
			gfx.x = (portal.mapX + 0.5) * Game.SCALE;
			state = EXITING;
			// prepare the dungeon generator for what entrance the player will use
			previousLevel = game.dungeon.level;
			previousPortalType = portal.type;
			previousMapType = game.dungeon.type;
			if(portal.targetLevel < game.dungeon.level){
				dir = looking = LEFT;
			} else if(portal.targetLevel > game.dungeon.level){
				dir = looking = RIGHT;
			} else {
				dir = looking & (LEFT | RIGHT);
			}
			game.world.removeCollider(collider);
		}
		
		override public function applyDamage(n:Number, source:String, knockback:Number = 0, critical:Boolean = false, aggressor:Character = null, defaultSound:Boolean = true):void {
			super.applyDamage(n, source, knockback, critical, aggressor, defaultSound);
			game.playerHealthBar.setValue(health, totalHealth);
		}
		
		override public function applyHealth(n:Number):void {
			super.applyHealth(n);
			game.playerHealthBar.setValue(health, totalHealth);
		}
		
		public function addXP(n:Number):void{
			// level up check
			while(xp + n > XP_LEVELS[level]){
				levelUp();
			}
			xp += n;
			game.playerXpBar.setValue(xp - XP_LEVELS[level - 1], XP_LEVELS[level] - XP_LEVELS[level - 1]);
		}
		
		override public function levelUp():void {
			super.levelUp();
			if(game.minion) game.minion.levelUp();
			game.levelNumGfx.gotoAndStop(level);
		}
		
		override public function changeName(name:int, gfx:MovieClip = null):void {
			super.changeName(name, gfx);
			// a change to the undead stat affects throwables
			if(throwable){
				game.menu.missileOption.active = (
					!indifferent && !(throwable.curseState == Item.CURSE_REVEALED && !undead)
				);
				game.menu.missileOption.state = GameMenu.THROW;
			}
		}
		
		/* Adds a trap that the rogue could possibly disarm and updates the menu */
		public function addDisarmableTrap(trap:Trap):void{
			disarmableTraps.push(trap);
			if(!game.menu.disarmTrapOption.active){
				game.menu.disarmTrapOption.active = true;
				game.menu.update();
			}
		}
		/* Removes a trap that the rogue could possibly disarm and updates the menu */
		public function removeDisarmableTrap(trap:Trap):void{
			disarmableTraps.splice(disarmableTraps.indexOf(trap), 1);
			if(disarmableTraps.length == 0){
				game.menu.disarmTrapOption.active = false;
				game.menu.update();
			}
		}
		
		/* Disarms any traps on the disarmableTraps list - effectively destroying them */
		public function disarmTraps():void{
			for(var i:int = 0; i < disarmableTraps.length; i++){
				disarmableTraps[i].disarm();
			}
			disarmableTraps.length = 0;
			game.soundQueue.add("click");
		}
		
		public function toString():String{
			var state_string:String = "";
			if(state == WALKING){
				state_string = "WALKING";
			} else if(state == LUNGING){
				state_string = "LUNGING";
			} else if(state == QUICKENING){
				state_string = "QUICKENING";
			} else if(state == EXITING){
				state_string = "EXITING";
			} else if(state == ENTERING){
				state_string = "ENTERING";
			} else if(state == STUNNED){
				state_string = "STUNNED";
			}
			return "("+collider+","+state_string+")";
		}
		
		override public function toXML():XML {
			var xml:XML = super.toXML();
			xml.@xp = xp;
			return xml;
		}
	}
	
}