package com.robotacid.ai {
	import com.robotacid.engine.Character;
	import com.robotacid.ui.Key;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.ui.Keyboard;
	
	/**
	 * Manages controlling the player character
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class PlayerBrain extends Brain {
		
		public var confusionOverlay:Bitmap;
		
		public static const CONFUSION_SCALE_TRANSFORMS:Vector.<Matrix> = Vector.<Matrix>([
			new Matrix(-1, 0, 0, 1, Game.WIDTH, 0),
			new Matrix(1, 0, 0, -1, 0, Game.HEIGHT),
			new Matrix(-1, 0, 0, -1, Game.WIDTH, Game.HEIGHT)
		]);
		
		public function PlayerBrain(char:Character, leader:Character = null) {
			super(char, PLAYER, leader);
			confusionOverlay = new Bitmap(new BitmapData(Game.WIDTH, Game.HEIGHT, true, 0x0));
		}
		
		override public function main():void {
			
			// check confusion state
			if(confusedCount){
				if(char == game.minion){
					super.main();
					return;
				}
				confusedCount--;
				if(confusedCount == 0) clear();
			}
			
			// capture input state
			if(char == game.player){
				if(
					((!game.multiplayer && Key.isDown(Keyboard.UP)) || Key.customDown(Game.UP_KEY)) &&
					!((!game.multiplayer && Key.isDown(Keyboard.DOWN)) || Key.customDown(Game.DOWN_KEY))
				){
					char.actions |= UP;
					char.looking |= UP;
					char.looking &= ~DOWN;
				} else {
					char.actions &= ~UP;
					char.looking &= ~UP;
				}
				if(
					((!game.multiplayer && Key.isDown(Keyboard.LEFT)) || Key.customDown(Game.LEFT_KEY)) &&
					!((!game.multiplayer && Key.isDown(Keyboard.RIGHT)) || Key.customDown(Game.RIGHT_KEY))
				){
					char.actions |= LEFT;
					char.looking |= LEFT;
					char.looking &= ~RIGHT;
				} else {
					char.actions &= ~LEFT;
				}
				if(
					((!game.multiplayer && Key.isDown(Keyboard.RIGHT)) || Key.customDown(Game.RIGHT_KEY)) &&
					!((!game.multiplayer && Key.isDown(Keyboard.LEFT)) || Key.customDown(Game.LEFT_KEY))
				){
					char.actions |= RIGHT;
					char.looking |= RIGHT;
					char.looking &= ~LEFT;
				} else {
					char.actions &= ~RIGHT;
				}
				if (
					((!game.multiplayer && Key.isDown(Keyboard.DOWN)) || Key.customDown(Game.DOWN_KEY)) &&
					!((!game.multiplayer && Key.isDown(Keyboard.UP)) || Key.customDown(Game.UP_KEY))
				){
					char.actions |= DOWN;
					char.looking |= DOWN;
					char.looking &= ~UP;
				} else {
					char.looking &= ~DOWN;
					char.actions &= ~DOWN;
				}
			} else if(char == game.minion){
				if(Key.isDown(Keyboard.UP) && !Key.isDown(Keyboard.DOWN)){
					char.actions |= UP;
					char.looking |= UP;
					char.looking &= ~DOWN;
				} else {
					char.actions &= ~UP;
					char.looking &= ~UP;
				}
				if(Key.isDown(Keyboard.LEFT) && !Key.isDown(Keyboard.RIGHT)){
					char.actions |= LEFT;
					char.looking |= LEFT;
					char.looking &= ~RIGHT;
				} else {
					char.actions &= ~LEFT;
				}
				if(Key.isDown(Keyboard.RIGHT) && !Key.isDown(Keyboard.LEFT)){
					char.actions |= RIGHT;
					char.looking |= RIGHT;
					char.looking &= ~LEFT;
				} else {
					char.actions &= ~RIGHT;
				}
				if(Key.isDown(Keyboard.DOWN) && !Key.isDown(Keyboard.UP)){
					char.actions |= DOWN;
					char.looking |= DOWN;
					char.looking &= ~UP;
				} else {
					char.looking &= ~DOWN;
					char.actions &= ~DOWN;
				}
			}
			
			char.dir = char.actions & (UP | RIGHT | LEFT | DOWN);
		}
		
		override public function clear():void {
			if(char == game.player){
				if(confusionOverlay.parent) confusionOverlay.parent.removeChild(confusionOverlay);
				confusedCount = 0;
			} else {
				super.clear();
			}
		}
		
		override public function confuse(delay:int):void {
			super.confuse(delay);
			if(char == game.player && !confusionOverlay.parent){
				confusionOverlay.transform.matrix = CONFUSION_SCALE_TRANSFORMS[game.random.rangeInt(CONFUSION_SCALE_TRANSFORMS.length)];
				game.confusionOverlayHolder.addChild(confusionOverlay);
			}
		}
		
		public function renderConfusion():void{
			confusionOverlay.visible = false;
			game.gameMenu.visible = false;
			if(Game.dialog) Game.dialog.visible = false;
			confusionOverlay.bitmapData.draw(game);
			if(Game.dialog) Game.dialog.visible = true;
			game.gameMenu.visible = true;
			confusionOverlay.visible = true;
		}
		
	}

}