package com.robotacid.engine {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	/**
	 * A fading light marking the death of the player
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class DeathLight extends Entity {
		
		private var count:int;
		private var lightCount:int;
		private var secondLight:Entity;
		private var secondLightCount:int;
		
		public static const LIGHT_DELAY:int = 6;
		public static const DELAY:int = 60;
		
		public function DeathLight(mapX:int, mapY:int) {
			super(new Sprite, true);
			secondLight = new Entity(new Sprite(), true, false);
			secondLight.active = true;
			this.mapX = secondLight.mapX = mapX;
			this.mapY = secondLight.mapY = mapY;
			lightCount = LIGHT_DELAY;
			secondLightCount = LIGHT_DELAY + 3;
			game.lightMap.setLight(this, lightCount, 255);
			game.lightMap.setLight(secondLight, secondLightCount, 117);
			callMain = true;
			count = DELAY;
		}
		
		override public function main():void {
			trace(count, lightCount);
			if(count){
				count--;
			} else {
				if(lightCount){
					lightCount--;
					game.lightMap.setLight(this, lightCount, 255);
				}
				if(secondLightCount){
					secondLightCount--;
					game.lightMap.setLight(secondLight, secondLightCount, 117);
				}
				if(lightCount == 0 && secondLightCount == 0){
					active = false;
					secondLight.active = false;
				} else {
					count = DELAY;
				}
			}
		}
		
	}

}