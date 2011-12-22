package com.robotacid.ai {
	import com.robotacid.engine.Character;
	import com.robotacid.ui.Key;
	import flash.ui.Keyboard;
	
	/**
	 * Manages controlling the player character
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class PlayerBrain extends Brain {
		
		public function PlayerBrain(char:Character) {
			super(char, PLAYER);
			
		}
		
		override public function main():void {
			
			// capture input state
			if((Key.isDown(Keyboard.UP) || Key.customDown(Game.UP_KEY)) && !(Key.isDown(Keyboard.DOWN) || Key.customDown(Game.DOWN_KEY))){
				char.actions |= UP;
				char.looking |= UP;
				char.looking &= ~DOWN;
			} else {
				char.actions &= ~UP;
				char.looking &= ~UP;
			}
			if((Key.isDown(Keyboard.LEFT) || Key.customDown(Game.LEFT_KEY)) && !(Key.isDown(Keyboard.RIGHT) || Key.customDown(Game.RIGHT_KEY))){
				char.actions |= LEFT;
				char.looking |= LEFT;
				char.looking &= ~RIGHT;
			} else {
				char.actions &= ~LEFT;
			}
			if((Key.isDown(Keyboard.RIGHT) || Key.customDown(Game.RIGHT_KEY)) && !(Key.isDown(Keyboard.LEFT) || Key.customDown(Game.LEFT_KEY))){
				char.actions |= RIGHT;
				char.looking |= RIGHT;
				char.looking &= ~LEFT;
			} else {
				char.actions &= ~RIGHT;
			}
			if ((Key.isDown(Keyboard.DOWN) || Key.customDown(Game.DOWN_KEY)) && !(Key.isDown(Keyboard.UP) || Key.customDown(Game.UP_KEY))){
				char.actions |= DOWN;
				char.looking |= DOWN;
				char.looking &= ~UP;
			} else {
				char.looking &= ~DOWN;
				char.actions &= ~DOWN;
			}
			
			char.dir = char.actions & (UP | RIGHT | LEFT | DOWN);
		}
		
	}

}