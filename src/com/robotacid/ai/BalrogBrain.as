package com.robotacid.ai {
	import com.robotacid.engine.Character;
	
	/**
	 * Runs away from the player and minion towards the next floor of the dungeon
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class BalrogBrain extends Brain {
		
		public function BalrogBrain(char:Character, allegiance:int, leader:Character = null) {
			super(char, allegiance, leader);
			
		}
		
	}

}