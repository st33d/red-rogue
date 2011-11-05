package com.robotacid.engine {
	
	import com.robotacid.ai.Brain;
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
	import com.robotacid.engine.MapRenderer;
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
		public var searchCount:int;
		public var disarmableTraps:Vector.<Trap>;
		public var cameraDisplacement:Point;
		public var camera:CanvasCamera;
		
		private var i:int, j:int;
		
		// states
		public var actionsLockout:int;
		public var portalContact:Portal;
		
		public static var portalEntryType:int = Portal.UP;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		public static const XP_LEVELS:Array = [0, 10, 20, 40, 80, 160, 320, 640, 1280, 2560, 5120, 10240, 20480, 40960, 81920, 163840, 327680, 655360, 1310720, 2621440];
		
		public static const DEFAULT_LIGHT_RADIUS:int = 5;
		public static const SEARCH_DELAY:int = 90;
		
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
			if(searchCount){
				searchCount--;
				if(actions || moving){
					searchCount = 0;
					g.console.print("search abandoned");
				} else if(searchCount == 0){
					g.console.print("search complete");
					g.revealTrapsAndSecrets();
				}
			}
			
			// update exiting a level
			if(state == EXITING){
				moving = true;
				var exitDir:int = portal.type == Portal.DOWN ? 1 : -1;
				if(portal.type == Portal.DOWN){
					if(moveCount){
						if(dir == RIGHT) gfx.x += PORTAL_SPEED;
						else if(dir == LEFT) gfx.x -= PORTAL_SPEED;
						gfx.y += PORTAL_SPEED;
					}
					if(gfx.y >= (portal.mapY + 1) * Game.SCALE + PORTAL_DISTANCE) portal = null;
				} else if(portal.type == Portal.UP){
					if(moveCount){
						if(dir == RIGHT) gfx.x += PORTAL_SPEED;
						else if(dir == LEFT) gfx.x -= PORTAL_SPEED;
						gfx.y -= PORTAL_SPEED;
					}
					if(gfx.y <= (portal.mapY + 1) * Game.SCALE - PORTAL_DISTANCE) portal = null;
				} else if(portal.type == Portal.SIDE){
					if(dir == RIGHT){
						gfx.x += PORTAL_SPEED;
						if(gfx.x > portal.mapX * Game.SCALE + PORTAL_DISTANCE) portal = null;
					} else if(dir == LEFT){
						gfx.x -= PORTAL_SPEED;
						if(gfx.x > (portal.mapX + 1) * Game.SCALE - PORTAL_DISTANCE) portal = null;
					}
				}
				if(!portal){
					g.world.removeCollider(collider);
					var newLevelStr:String = (exitDir > 0 ? "descended" : "ascended") + " to level " + (g.dungeon.level + exitDir);
					if(g.dungeon.level == 1 && exitDir < 0) newLevelStr = "ascended to overworld";
					g.console.print(newLevelStr);
					g.changeLevel(g.dungeon.level + exitDir);
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
						if(portal.rect.intersects(collider) && state == Character.WALKING){
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
			if(portal.type == Portal.UP){
				portalEntryType = Portal.DOWN;
				dir = looking = LEFT;
			} else if(portal.type == Portal.DOWN){
				portalEntryType = Portal.UP;
				dir = looking = RIGHT;
			} else if(portal.type == Portal.SIDE){
				portalEntryType = Portal.SIDE;
			}
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