package com.robotacid.ui {
	import flash.display.Sprite;
	/**
	 * A simple fade to segue between scenes
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Transition extends Sprite{
		
		public var active:Boolean;
		public var changeOverCallback:Function;
		public var completeCallback:Function;
		public var dir:int;
		
		public static const FADE_STEP:Number = 1.0 / 10;
		
		public function Transition() {
			active = false;
			dir = 0;
		}
		
		public function main():void{
			if(dir > 0){
				alpha += FADE_STEP;
				if(alpha >= 1){
					alpha = 1;
					dir = -1;
					changeOverCallback();
				}
			} else if(dir < 0){
				alpha -= FADE_STEP;
				if(alpha <= 0){
					dir = 0;
					alpha = 0;
					active = false;
					graphics.clear();
					changeOverCallback = null;
					completeCallback = null;
					if(Boolean(completeCallback)) completeCallback();
				}
			}
		}
		
		/* Initiate a transition */
		public function init(changeOverCallback:Function, completeCallback:Function = null):void{
			this.changeOverCallback = changeOverCallback;
			this.completeCallback = completeCallback;
			active = true;
			dir = 1;
			alpha = 0;
			graphics.beginFill(0);
			graphics.drawRect(0, 0, Game.WIDTH, Game.HEIGHT);
			graphics.endFill();
		}
		
	}

}