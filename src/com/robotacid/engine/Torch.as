package com.robotacid.engine {
	import flash.display.DisplayObject;
	
	/**
	 * Ambient lighting entity
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Torch extends Entity {
		
		public static const RADIUS:int = 3;
		public static const BRIGHTNESS:int = 127;
		
		public function Torch(gfx:DisplayObject, mapX:int, mapY:int) {
			super(gfx, false, false);
			gfx.x = mapX * SCALE;
			gfx.y = mapY * SCALE;
			this.mapX = mapX;
			this.mapY = mapY;
			mapZ = MapTileManager.ENTITY_LAYER;
		}
		
		public function mapInit():void{
			game.lightMap.setLight(this, RADIUS + game.random.rangeInt(2), BRIGHTNESS);
		}
		
		override public function remove():void {
			super.remove();
			var n:int = game.torches.indexOf(this);
			if(n > -1) game.torches.splice(n, 1);
		}
	}

}