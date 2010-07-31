package com.robotacid.engine {
	
	import com.robotacid.ai.Brain;
	import com.robotacid.engine.Stairs;
	import com.robotacid.geom.Pixel;
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Cast;
	import com.robotacid.engine.Character;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.menu.InventoryMenuList;
	import com.robotacid.util.HiddenInt;
	import com.robotacid.util.HiddenNumber;
	import com.robotacid.geom.Line;
	import com.robotacid.phys.Particle;
	import com.robotacid.engine.MapRenderer;
	import com.robotacid.geom.Trig;
	import com.robotacid.ui.Key;
	import com.robotacid.phys.Spring;
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
		
		private var i:int, j:int;
		
		// states
		public var actionsLockout:int;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		public static const XP_LEVELS:Array = [0, 10, 20, 40, 80, 160, 320, 640, 1280, 2560, 5120, 10240, 20480, 40960, 81920, 163840, 327680, 655360, 1310720, 2621440];
		
		public static const DEFAULT_LIGHT_RADIUS:int = 5;
		public static const SEARCH_DELAY:int = 90;
		
		public static var point:Point = new Point();
		
		public function Player(mc:DisplayObject, width:Number, height:Number, entrance:Stairs, g:Game) {
			super(mc, ROGUE, PLAYER, 1, width, height, g, true);
			
			// init states
			dir = RIGHT;
			actions = actionsLockout = 0;
			looking = RIGHT | UP;
			active = true;
			callMain = false;
			collision = false;
			stepNoise = true;
			
			// init properties
			block.type |= Block.PLAYER;
			ignore |= Block.PLAYER | Block.MINION;
			missileIgnore |= Block.PLAYER | Block.MINION;
			
			g.lightMap.setLight(this, DEFAULT_LIGHT_RADIUS);
			
			disarmableTraps = new Vector.<Trap>();
			
			xp = 0;
			g.playerXpBar.value = 0;
			
			g.console.print("welcome rogue");
			
			inventory = g.menu.inventoryList;
			holder = g.playerHolder;
			
			Brain.playerCharacters.push(this);
			
			// being a character, the rogue automatically gets added to the entities list
			// so we remove her here
			g.entities.splice(g.entities.indexOf(this), 1);
			
		}
		// Loop
		override public function main():void{
			if(state == WALKING || state == FALLING || state == CLIMBING){
				checkKeys();
			}
			if(dir & UP){
				itemCheck();
			}
			super.main();
			if(state == EXIT){
				if(x >= rect.x + rect.width * 0.5 + SCALE * 2 || x <= (rect.x + rect.width * 0.5) - SCALE * 2){
					var exitDir:int = stairs.type == Stairs.DOWN ? 1 : -1;
					stairs = null;
					var newLevelStr:String = (exitDir > 0 ? "descended" : "ascended") + " to level " + (g.dungeon.level + exitDir);
					if(g.dungeon.level == 1 && exitDir < 0) newLevelStr = "ascended to overworld";
					g.console.print(newLevelStr);
					g.changeLevel(g.dungeon.level + exitDir);
				}
			}
			if(searchCount){
				searchCount--;
				if((actions) || !(state == WALKING || state == FALLING || state == CLIMBING)){
					searchCount = 0;
					g.console.print("search abandoned");
				} else if(searchCount == 0){
					g.console.print("search complete");
					g.revealTrapsAndSecrets();
				}
			}
		}
		/* Various things that need to be hidden or killed upon death or finishing a level */
		public function tidyUp():void {
			rect = new Block();
			mc.visible = false;
			g.mousePressed = false;
			moving = false;
			divorce();
			mapX = mapY = 0;
			
		}
		public function itemCheck():void{
			for(var i:int = 0; i < g.items.length; i++){
				if(intersects(g.items[i].rect)){
					g.console.print("picked up " + g.items[i].nameToString());
					g.items[i].collect(this);
				}
			}
		}
		/* Select an item as a weapon or armour */
		override public function equip(item:Item):Item{
			if(item.curseState == Item.CURSE_HIDDEN) item.revealCurse();
			item = inventory.unstack(item);
			super.equip(item);
			inventory.updateItem(item);
			return item;
		}
		/* Unselect item as equipped */
		override public function unequip(item:Item):Item{
			super.unequip(item);
			item = inventory.stack(item);
			inventory.updateItem(item);
			return item;
		}
		
		override public function death(cause:String, decapitation:Boolean = false, aggressor:int = 0):void{
			if(g.god_mode || !active) return;
			super.death(cause, decapitation);
			SoundManager.playSound(g.library.RogueDeathSound);
			if(!active){
				Brain.playerCharacters.splice(Brain.playerCharacters.indexOf(this), 1);
				g.menu.death();
				tidyUp();
			}
			g.shake(0, 5);
		}
		
		public function enterLevel(entrance:Stairs):void{
			// it's best at this point to yank the character out of the collider framework
			// completely to avoid any collision whilst entering
			g.colliders.splice(g.colliders.indexOf(this), 1);
			stairs = entrance;
			(mc as Sprite).parent.addChild(stairs.mask);
			mc.cacheAsBitmap = true;
			mc.mask = stairs.mask;
			if(stairs.type == Stairs.UP){
				x -= SCALE * 2;
				y -= SCALE * 2;
			} else if(stairs.type == Stairs.DOWN){
				x += SCALE * 2;
				y += SCALE * 2;
			}
			updateMC();
			state = ENTER;
		}
		
		public function exitLevel(stairs:Stairs):void{
			this.stairs = stairs;
			(mc as Sprite).parent.addChild(stairs.mask);
			mc.cacheAsBitmap = true;
			mc.mask = stairs.mask;
			if(x + width * 0.5 > stairs.rect.x + stairs.rect.width) x = (stairs.rect.x + stairs.rect.width) - width * 0.5;
			if(x - width * 0.5 < stairs.rect.x) x = stairs.rect.x + width * 0.5;
			divorce();
			updateRect();
			// it's best at this point to yank the character out of the collider framework
			// completely to avoid any collision with the shell they left behind
			g.colliders.splice(g.colliders.indexOf(this), 1);
			updateMC();
			state = EXIT;
			Stairs.lastStairsUsedType = stairs.type;
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
		
		override public function updateAnimState(mc:MovieClip):void {
			super.updateAnimState(mc);
		}
		
		/* Handles refreshing animation and the position the canvas
		override public function updateMC():void{
			mc.x = (x + 0.1) >> 0;
			mc.y = ((y + height * 0.5) + 0.1) >> 0;
			if(mc.alpha < 1){
				mc.alpha += 0.1;
			}
			if(weapon){
				if((mc as MovieClip).weapon){
					weapon.mc.x = (mc as MovieClip).weapon.x;
					weapon.mc.y = (mc as MovieClip).weapon.y;
					if(state == CLIMBING) weapon.mc.visible = false;
					else weapon.mc.visible = true;
				}
			}
			if(armour){
				if((mc as MovieClip).hat){
					armour.mc.x = (mc as MovieClip).hat.x;
					armour.mc.y = (mc as MovieClip).hat.y;
				}
			}
		}*/
		
		override public function applyDamage(n:Number, source:String, critical:Boolean = false, aggressor:int = PLAYER):void {
			super.applyDamage(n, source, critical);
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
				g.menu.selection = g.menu.selection;
			}
		}
		/* Removes a trap that the rogue could possibly disarm and updates the menu */
		public function removeDisarmableTrap(trap:Trap):void{
			disarmableTraps.splice(disarmableTraps.indexOf(trap), 1);
			if(disarmableTraps.length == 0){
				g.menu.disarmTrapOption.active = false;
				g.menu.selection = g.menu.selection;
			}
		}
		/* Disarms any traps on the disarmableTraps list - effectively destroying them */
		public function disarmTraps():void{
			for(var i:int = 0; i < disarmableTraps.length; i++){
				disarmableTraps[i].disarm();
			}
			disarmableTraps.length = 0;
		}
		
		override public function toString():String{
			var state_string:String = "";
			if(state == WALKING){
				state_string = "WALKING";
			} else if(state == FALLING){
				state_string = "FALLING";
			} else if(state == CLIMBING){
				state_string = "CLIMBING";
			} else if(state == DEAD){
				state_string = "DEAD";
			} else if(state == ATTACK){
				state_string = "ATTACK";
			}
			var xs:String = "" + (x >> 0);
			while (xs.length < 4) xs = "0" + xs;
			var ys:String = "" + (y >> 0);
			while (ys.length < 4) ys = "0" + ys;
			return "("+xs+","+ys+","+state_string+")";
		}
		
		override public function toXML():XML {
			var xml:XML = super.toXML();
			xml.@xp = xp;
			return xml;
		}
	}
	
}