package com.robotacid.engine {
	
	import com.robotacid.ai.Brain;
	import com.robotacid.engine.Stairs;
	import com.robotacid.geom.Pixel;
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Cast;
	import com.robotacid.engine.Character;
	import com.robotacid.phys.Collider;
	import com.robotacid.geom.Dot;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.menu.InventoryMenuList;
	import com.robotacid.util.HiddenInt;
	import com.robotacid.util.HiddenNumber;
	import com.robotacid.geom.Line;
	import com.robotacid.phys.Particle;
	import com.robotacid.geom.Rect;
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
		public var map_rect:Rect;
		public var inventory:InventoryMenuList;
		
		
		private var i:int, j:int;
		
		// states
		public var actions_lockout:int;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		public static const XP_LEVELS:Array = [0, 10, 20, 40, 80, 160, 320, 640, 1280, 2560];
		
		public static const DEFAULT_LIGHT_RADIUS:int = 5;
		
		public static var point:Point = new Point();
		
		public function Player(mc:DisplayObject, width:Number, height:Number, entrance:Stairs, g:Game) {
			super(mc, ROGUE, PLAYER, 1, width, height, g);
			
			// init states
			dir = RIGHT;
			actions = actions_lockout = 0;
			looking = RIGHT | UP;
			active = true;
			call_main = false;
			collision = false;
			step_noise = true;
			
			// init properties
			block.type |= Block.PLAYER;
			ignore |= Block.PLAYER | Block.MINION;
			missile_ignore |= Block.PLAYER | Block.MINION;
			
			g.light_map.setLight(this, DEFAULT_LIGHT_RADIUS);
			
			xp = 0;
			g.player_xp_bar.value = 0;
			
			g.console.print("welcome rogue");
			
			inventory = g.menu.inventory_list;
			holder = g.player_holder;
			
			Brain.player_characters.push(this);
			
			// being a character, the rogue automatically gets added to the entities list
			// so we remove her here
			g.entities.splice(g.entities.indexOf(this), 1);
			
			
			// DEBUGGING HACKS *******************************************************************
			
			
			/*Item.rune_names = Item.RUNE_NAMES;
			var item:Item;
			for(var i:int = 0, j:int; i < 20; i++){
				for(j = 0; j < 6; j++){
					item = new Item(new g.library.RuneMC(), j, Item.RUNE, 0, g);
					item.collect(this);
				}
			}
			item = new Item(new g.library.BowMC(), Item.BOW, Item.WEAPON, 0, g);
			item.collect(this);
			var skeleton_mc:MovieClip = new g.library.SkeletonMC();
			skeleton_mc.x = mc.x;
			skeleton_mc.y = (-skeleton_mc.height * 0.5) + (map_y + 1) * SCALE;
			g.entities_holder.addChild(skeleton_mc);
			g.minion = new Minion(Character.SKELETON, skeleton_mc, skeleton_mc.width, skeleton_mc.height, g);*/
			
			
			// ***********************************************************************************
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
					var exit_dir:int = stairs.type == Stairs.DOWN ? 1 : -1;
					stairs = null;
					var new_level_str:String = (exit_dir > 0 ? "descended" : "ascended") + " to level " + (g.dungeon.level + exit_dir);
					if(g.dungeon.level == 1 && exit_dir < 0) new_level_str = "ascended to overworld";
					g.console.print(new_level_str);
					g.changeLevel(g.dungeon.level + exit_dir);
				}
			}
		}
		/* Various things that need to be hidden or killed upon death or finishing a level */
		public function tidyUp():void {
			rect = new Block();
			mc.visible = false;
			g.mouse_pressed = false;
			moving = false;
			divorce();
			map_x = map_y = 0;
			
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
			if(item.curse_state == Item.CURSE_HIDDEN) item.revealCurse();
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
		
		override public function get damage_bonus():Number {
			return super.damage_bonus + (weapon ? weapon.damage : 0);
		}
		override public function death(cause:String, decapitation:Boolean = false, aggressor:int = 0):void{
			if(g.god_mode || !active) return;
			super.death(cause, decapitation);
			SoundManager.playSound(g.library.RogueDeathSound);
			if(!active){
				Brain.player_characters.splice(Brain.player_characters.indexOf(this), 1);
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
			Stairs.last_stairs_used_type = stairs.type;
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
				actions_lockout &= ~UP;
				looking &= ~UP;
			}
			if((Key.isDown(Keyboard.LEFT) || Key.customDown(Game.LEFT_KEY)) && !(Key.isDown(Keyboard.RIGHT) || Key.customDown(Game.RIGHT_KEY))){
				actions |= LEFT;
				looking |= LEFT;
				looking &= ~RIGHT;
			} else {
				actions &= ~LEFT;
				actions_lockout &= ~LEFT;
			}
			if((Key.isDown(Keyboard.RIGHT) || Key.customDown(Game.RIGHT_KEY)) && !(Key.isDown(Keyboard.LEFT) || Key.customDown(Game.LEFT_KEY))){
				actions |= RIGHT;
				looking |= RIGHT;
				looking &= ~LEFT;
			} else {
				actions &= ~RIGHT;
				actions_lockout &= ~RIGHT;
			}
			if ((Key.isDown(Keyboard.DOWN) || Key.customDown(Game.DOWN_KEY)) && !(Key.isDown(Keyboard.UP) || Key.customDown(Game.UP_KEY))){
				actions |= DOWN;
				looking |= DOWN;
				looking &= ~UP;
			} else {
				looking &= ~DOWN;
				actions &= ~DOWN;
				actions_lockout &= ~DOWN;
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
			g.player_health_bar.setValue(health, total_health);
		}
		
		override public function applyHealth(n:Number):void {
			super.applyHealth(n);
			g.player_health_bar.setValue(health, total_health);
		}
		
		public function addXP(n:Number):void{
			// level up check
			while(xp + n > XP_LEVELS[level]){
				levelUp();
			}
			xp += n;
			g.player_xp_bar.setValue(xp - XP_LEVELS[level - 1], XP_LEVELS[level] - XP_LEVELS[level - 1]);
		}
		
		override public function levelUp():void {
			super.levelUp();
			if(g.minion) g.minion.levelUp();
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
	}
	
}