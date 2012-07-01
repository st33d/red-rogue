package com.robotacid.engine {
	import com.robotacid.ai.BalrogBrain;
	import com.robotacid.phys.Collider;
	import flash.display.DisplayObject;
	
	/**
	 * The end game boss
	 * 
	 * Designed to kill the player indirectly
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Balrog extends Character {
		
		public static const DEFAULT_LIGHT_RADIUS:int = 5;
		public static const DEFAULT_UNIQUE_NAME_STR:String = "the balrog";
		
		public function Balrog(gfx:DisplayObject, x:Number, y:Number, level:int, items:Vector.<Item>){
			rank = ELITE;
			super(gfx, x, y, BALROG, MONSTER, level, false);
			
			// init states
			dir = RIGHT;
			actions = 0;
			looking = RIGHT;
			active = true;
			callMain = false;
			uniqueNameStr = DEFAULT_UNIQUE_NAME_STR;
			missileIgnore |= Collider.MONSTER | Collider.MONSTER_MISSILE;
			addToEntities = true;
			
			game.lightMap.setLight(this, DEFAULT_LIGHT_RADIUS);
			
			
			
			this.rank = rank;
			super(gfx, x, y, name, MONSTER, level, false);
			
			brain = new BalrogBrain(this);
			
			if(items) loot = items;
		}
		
	}

}