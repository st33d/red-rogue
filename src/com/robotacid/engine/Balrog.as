package com.robotacid.engine {
	import flash.display.DisplayObject;
	
	/**
	 * The end game boss
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Balrog extends Character {
		
		public static const DEFAULT_LIGHT_RADIUS:int = 5;
		
		public static const DEFAULT_UNIQUE_NAME_STR:String = "the balrog";
		
		public function Balrog(gfx:DisplayObject, x:Number, y:Number, name:int, type:int, level:int, addToEntities:Boolean = true) {
			super(gfx, x, y, name, type, level, addToEntities);
			
			// init states
			dir = RIGHT;
			actions = 0;
			looking = RIGHT;
			active = true;
			callMain = false;
			uniqueNameStr = DEFAULT_UNIQUE_NAME_STR;
			
			game.lightMap.setLight(this, DEFAULT_LIGHT_RADIUS);
			
		}
		
	}

}