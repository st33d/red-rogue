package com.robotacid.engine {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	/**
	 * A fading light.
	 * 
	 * The design of the light is hard coded into types to keep the constants out of the other classes
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class FadeLight extends Entity {
		
		public var type:int;
		
		private var character:Character;
		private var fadeCount:int;
		private var fadeDelay:int;
		private var lightCount:int;
		private var brightness:int;
		private var secondLight:Entity;
		private var secondLightCount:int;
		
		// types
		public static const DEATH:int = 0;
		public static const SLEEP:int = 1;
		public static const DEBUG:int = 2;
		
		public static const DEATH_LIGHT_DELAY:int = 6;
		public static const DEATH_FADE_DELAY:int = 60;
		public static const SLEEP_LIGHT_DELAY:int = 3;
		public static const SLEEP_FADE_DELAY:int = 60;
		public static const DEBUG_LIGHT_DELAY:int = 6;
		public static const DEBUG_FADE_DELAY:int = int.MAX_VALUE;
		
		public function FadeLight(type:int, mapX:int, mapY:int, character:Character = null) {
			super(new Sprite, true);
			this.type = type;
			this.mapX = mapX;
			this.mapY = mapY;
			this.character = character;
			if(type == DEATH){
				secondLight = new Entity(new Sprite(), true, false);
				secondLight.active = true;
				secondLight.mapX = mapX;
				secondLight.mapY = mapY;
				secondLightCount = DEATH_LIGHT_DELAY + 3;
				lightCount = DEATH_LIGHT_DELAY;
				game.lightMap.setLight(secondLight, secondLightCount, 117);
				fadeCount = fadeDelay = DEATH_FADE_DELAY;
				brightness = 255;
				
			} else if(type == SLEEP){
				lightCount = SLEEP_LIGHT_DELAY;
				fadeCount = fadeDelay = SLEEP_FADE_DELAY;
				brightness = 255;
				
			} else if(type == DEBUG){
				lightCount = DEBUG_LIGHT_DELAY;
				fadeCount = fadeDelay = DEBUG_FADE_DELAY;
				brightness = 255;
			}
			game.lightMap.setLight(this, lightCount, brightness);
			callMain = true;
		}
		
		override public function main():void {
			if(fadeCount){
				fadeCount--;
			} else {
				if(lightCount){
					lightCount--;
					game.lightMap.setLight(this, lightCount, brightness);
				}
				if(secondLightCount){
					secondLightCount--;
					game.lightMap.setLight(secondLight, secondLightCount, 117);
				}
				if(
					(lightCount == 0 && secondLightCount == 0) ||
					(type == SLEEP && !character.asleep)
				){
					active = false;
					if(secondLight) secondLight.active = false;
				} else {
					fadeCount = fadeDelay;
				}
			}
		}
		
	}

}