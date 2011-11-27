package com.robotacid.engine {
	
	import com.robotacid.ai.Brain;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Portal;
	import com.robotacid.geom.Pixel;
	import com.robotacid.gfx.CanvasCamera;
	import com.robotacid.phys.Cast;
	import com.robotacid.engine.Character;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.menu.InventoryMenuList;
	import com.robotacid.util.HiddenInt;
	import com.robotacid.util.HiddenNumber;
	import com.robotacid.geom.Line;
	import com.robotacid.engine.MapTileManager;
	import com.robotacid.geom.Trig;
	import com.robotacid.ui.Key;
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
	import flash.ui.Keyboard;
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
		public var actionsLockout:int;
		public var portalContact:Portal;
		
		public static var previousLevel:int = 0;
		public static var previousPortalType:int = Portal.STAIRS;
		
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
		
		public static var point:Point = new Point();
		
		public function Player(mc:DisplayObject, x:Number, y:Number) {
			super(mc, x, y, ROGUE, PLAYER, 1, false);
			
			active = true;
			
			// init states
			dir = RIGHT;
			actions = actionsLockout = 0;
			looking = RIGHT | UP;
			active = true;
			callMain = false;
			stepNoise = true;
			searchRadius = -1;
			
			cameraDisplacement = new Point();
			
			// init properties
			missileIgnore |= Collider.PLAYER | Collider.MINION;
			
			g.lightMap.setLight(this, DEFAULT_LIGHT_RADIUS);
			
			disarmableTraps = new Vector.<Trap>();
			
			xp = 0;
			g.playerXpBar.value = 0;
			
			g.console.print("welcome rogue");
			
			inventory = g.menu.inventoryList;
			
			Brain.playerCharacters.push(this);
		}
		
		override public function createCollider(x:Number, y:Number, properties:int, ignoreProperties:int, state:int = 0, positionByBase:Boolean = true):void {
			super.createCollider(x, y, properties, ignoreProperties, state, positionByBase);
			collider.properties |= Collider.PLAYER;
			collider.ignoreProperties |= Collider.PLAYER | Collider.MINION;
			collider.stompProperties = Collider.MONSTER;
			collider.stackCallback = hitFloor;
		}
		
		private function hitFloor():void{
			g.soundQueue.add("thud");
		}
		
		// Loop
		override public function main():void{
			
			if(state == WALKING){
				checkKeys();
			}
			
			super.main();
			
			// search for traps/secrets
			if(searchRadius > -1){
				if(actions || moving){
					searchRadius = -1;
					g.console.print("search abandoned");
					if(searchRevealCount == 0){
						g.console.print("found nothing");
					} else {
						g.console.print(searchRevealCount + " discover" + (searchRevealCount > 1 ? "ies" : "y"));
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
							g.console.print("search complete");
							if(searchRevealCount == 0){
								g.console.print("found nothing");
							} else {
								g.console.print(searchRevealCount + " discover" + (searchRevealCount > 1 ? "ies" : "y"));
							}
						}
						searchCount = SEARCH_DELAY;
					}
				}
			}
			
			// update exiting a level
			if(state == EXITING){
				// capture the exit direction before we clear the reference to the portal
				var exitDir:int = portal.targetLevel > g.dungeon.level ? 1 : -1;
				var portalType:int = portal.type;
				var portalTargetLevel:int = portal.targetLevel;
				moving = true;
				if(portal.type == Portal.STAIRS){
					if(portal.targetLevel > g.dungeon.level){
						if(moveCount){
							if(dir == RIGHT) gfx.x += STAIRS_SPEED;
							else if(dir == LEFT) gfx.x -= STAIRS_SPEED;
							gfx.y += STAIRS_SPEED;
						}
						if(gfx.y >= (portal.mapY + 1) * Game.SCALE + PORTAL_DISTANCE) portal = null;
					} else if(portal.targetLevel < g.dungeon.level){
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
					var newLevelStr:String;
					if(portalType == Portal.STAIRS){
						if(portalTargetLevel == 0){
							newLevelStr = "ascended to overworld";
						} else {
							newLevelStr = (portalTargetLevel > g.dungeon.level ? "descended" : "ascended") + " to level " + portalTargetLevel;
						}
					} else if(portalType == Portal.ROGUE) newLevelStr = "travelled to overworld";
					else if(portalType == Portal.ROGUE_RETURN || portalType == Portal.ITEM_RETURN) newLevelStr = "returned to level " + portalTargetLevel;
					else if(portalType == Portal.ITEM) newLevelStr = "travelled to retrieve item";
					g.console.print(newLevelStr);
					g.changeLevel(portalTargetLevel, portalType);
				}
			} else if(state == ENTERING){
				
			} else {
				if(portalContact){
					if(!portalContact.rect.intersects(collider) || state != Character.WALKING){
						portalContact = null;
						g.menu.exitLevelOption.active = false;
						g.menu.update();
					}
					// restore access to menu
					if(collider.world && !g.menu.actionsOption.active){
						g.menu.actionsOption.active = true;
						g.menu.inventoryOption.active = Boolean(g.menu.inventoryList.options.length);
						g.menu.update();
					}
				} else {
					// check for portals
					var portal:Portal;
					
					for(i = 0; i < g.portals.length; i++){
						portal = g.portals[i];
						if(portal.playerPortal && portal.rect.intersects(collider) && state == Character.WALKING){
							if(!portalContact){
								portalContact = portal
								g.menu.exitLevelOption.active = true;
								g.menu.update();
								g.menu.exitLevelOption.userData = portal;
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
				item = g.mapTileManager.getTile(c, r, MapTileManager.ENTITY_LAYER);
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
				item = g.mapTileManager.getTile(c, r, MapTileManager.ENTITY_LAYER);
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
				item = g.mapTileManager.getTile(c, r, MapTileManager.ENTITY_LAYER);
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
				item = g.mapTileManager.getTile(c, r, MapTileManager.ENTITY_LAYER);
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
			g.mousePressed = false;
			moving = false;
			mapX = mapY = 0;
		}
		
		/* Select an item as a weapon or armour */
		override public function equip(item:Item):Item{
			if(item.curseState == Item.CURSE_HIDDEN) item.revealCurse();
			item = inventory.unstack(item);
			super.equip(item);
			// set the active state and name of the missile option in the menu
			if(item.type == Item.WEAPON){
				g.menu.missileOption.active = !indifferent && Boolean(item.range & (Item.MISSILE | Item.THROWN));
				if(item.range & Item.MISSILE) g.menu.missileOption.state = 0;
				else if(item.range & Item.THROWN) g.menu.missileOption.state = 1;
			}
			inventory.updateItem(item);
			return item;
		}
		
		/* Unselect item as equipped */
		override public function unequip(item:Item):Item{
			super.unequip(item);
			item = inventory.stack(item);
			if(item.type == Item.WEAPON) g.menu.missileOption.active = false;
			inventory.updateItem(item);
			return item;
		}
		
		override public function death(cause:String = "crushing", decapitation:Boolean = false, aggressor:int = 0):void{
			if(g.god_mode || !active) return;
			super.death(cause, decapitation);
			g.soundQueue.add("rogueDeath");
			if(!active){
				Brain.playerCharacters.splice(Brain.playerCharacters.indexOf(this), 1);
				g.menu.death();
				tidyUp();
			}
			renderer.shake(0, 5);
		}
		
		public function exitLevel(portal:Portal):void{
			// the player must be denied the opportunity to dick about whilst exiting a level
			g.menu.actionsOption.active = false;
			g.menu.inventoryOption.active = false;
			g.menu.update();
			this.portal = portal;
			gfx.x = (portal.mapX + 0.5) * Game.SCALE;
			state = EXITING;
			// prepare the dungeon generator for what entrance the player will use
			previousLevel = g.dungeon.level;
			previousPortalType = portal.type;
			if(portal.targetLevel < g.dungeon.level){
				dir = looking = LEFT;
			} else if(portal.targetLevel > g.dungeon.level){
				dir = looking = RIGHT;
			} else {
				dir = looking & (LEFT | RIGHT);
			}
			g.world.removeCollider(collider);
		}
		
		/* Check mouse movement, presses, keys etc. */
		public function checkKeys():void{
			// capture input state
			if((Key.isDown(Keyboard.UP) || Key.customDown(Game.UP_KEY)) && !(Key.isDown(Keyboard.DOWN) || Key.customDown(Game.DOWN_KEY))){
				actions |= UP;
				looking |= UP;
				looking &= ~DOWN;
			} else {
				actions &= ~UP;
				actionsLockout &= ~UP;
				looking &= ~UP;
			}
			if((Key.isDown(Keyboard.LEFT) || Key.customDown(Game.LEFT_KEY)) && !(Key.isDown(Keyboard.RIGHT) || Key.customDown(Game.RIGHT_KEY))){
				actions |= LEFT;
				looking |= LEFT;
				looking &= ~RIGHT;
			} else {
				actions &= ~LEFT;
				actionsLockout &= ~LEFT;
			}
			if((Key.isDown(Keyboard.RIGHT) || Key.customDown(Game.RIGHT_KEY)) && !(Key.isDown(Keyboard.LEFT) || Key.customDown(Game.LEFT_KEY))){
				actions |= RIGHT;
				looking |= RIGHT;
				looking &= ~LEFT;
			} else {
				actions &= ~RIGHT;
				actionsLockout &= ~RIGHT;
			}
			if ((Key.isDown(Keyboard.DOWN) || Key.customDown(Game.DOWN_KEY)) && !(Key.isDown(Keyboard.UP) || Key.customDown(Game.UP_KEY))){
				actions |= DOWN;
				looking |= DOWN;
				looking &= ~UP;
			} else {
				looking &= ~DOWN;
				actions &= ~DOWN;
				actionsLockout &= ~DOWN;
			}
			
			dir = actions & (UP | RIGHT | LEFT | DOWN);
			
		}
		
		override public function applyDamage(n:Number, source:String, knockback:Number = 0, critical:Boolean = false, aggressor:int = PLAYER):void {
			super.applyDamage(n, source, knockback, critical);
			g.playerHealthBar.setValue(health, totalHealth);
		}
		
		override public function applyHealth(n:Number):void {
			super.applyHealth(n);
			g.playerHealthBar.setValue(health, totalHealth);
		}
		
		public function addXP(n:Number):void{
			// level up check
			while(xp + n > XP_LEVELS[level]){
				levelUp();
			}
			xp += n;
			g.playerXpBar.setValue(xp - XP_LEVELS[level - 1], XP_LEVELS[level] - XP_LEVELS[level - 1]);
		}
		
		override public function levelUp():void {
			super.levelUp();
			if(g.minion) g.minion.levelUp();
		}
		/* Adds a trap that the rogue could possibly disarm and updates the menu */
		public function addDisarmableTrap(trap:Trap):void{
			disarmableTraps.push(trap);
			if(!g.menu.disarmTrapOption.active){
				g.menu.disarmTrapOption.active = true;
				g.menu.update();
			}
		}
		/* Removes a trap that the rogue could possibly disarm and updates the menu */
		public function removeDisarmableTrap(trap:Trap):void{
			disarmableTraps.splice(disarmableTraps.indexOf(trap), 1);
			if(disarmableTraps.length == 0){
				g.menu.disarmTrapOption.active = false;
				g.menu.update();
			}
		}
		/* Disarms any traps on the disarmableTraps list - effectively destroying them */
		public function disarmTraps():void{
			for(var i:int = 0; i < disarmableTraps.length; i++){
				disarmableTraps[i].disarm();
			}
			disarmableTraps.length = 0;
		}
		
		public function toString():String{
			var state_string:String = "";
			if(state == WALKING){
				state_string = "WALKING";
			} else if(state == DEAD){
				state_string = "DEAD";
			} else if(state == LUNGING){
				state_string = "LUNGING";
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