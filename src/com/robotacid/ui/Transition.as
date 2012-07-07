package com.robotacid.ui {
	import flash.display.Sprite;
	/**
	 * A simple fade to segue between scenes with optional text inbetween
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Transition extends Sprite{
		
		public var active:Boolean;
		public var changeOverCallback:Function;
		public var completeCallback:Function;
		public var dir:int;
		public var forceComplete:Boolean;
		
		private var textBox:TextBox;
		private var textCount:int;
		
		public static const FADE_STEP:Number = 1.0 / 10;
		public static const TEXT_DELAY:int = 60;
		
		public function Transition() {
			active = false;
			dir = 0;
			textBox = new TextBox(100, 28, 0xFF000000, 0xFFAA0000);
			textBox.x = Game.WIDTH * 0.5 - textBox.width * 0.5;
			textBox.y = Game.HEIGHT * 0.5 - textBox.height * 0.5;
			textBox.alignVert = "center";
			textBox.align = "center";
			textBox.visible = false;
			addChild(textBox);
		}
		
		public function main():void{
			// fade in text and delay
			if(alpha == 1 && textBox.visible){
				if(textCount){
					if(textBox.alpha < 1){
						textBox.alpha += FADE_STEP;
						if(textBox.alpha >= 1) textBox.alpha = 1;
					} else {
						textCount--;
					}
				} else {
					if(textBox.alpha > 0){
						textBox.alpha -= FADE_STEP;
						if(textBox.alpha <= 0){
							textBox.alpha = 0;
							textBox.visible = false;
						}
					}
				}
			// fade in, callback, fade out, callback
			} else {
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
		}
		
		/* Initiate a transition */
		public function init(changeOverCallback:Function, completeCallback:Function = null, text:String = "", skipToBlack:Boolean = false, forceComplete:Boolean = false):void{
			this.changeOverCallback = changeOverCallback;
			this.completeCallback = completeCallback;
			this.forceComplete = forceComplete;
			active = true;
			graphics.beginFill(0);
			graphics.drawRect(0, 0, Game.WIDTH, Game.HEIGHT);
			graphics.endFill();
			if(skipToBlack){
				dir = -1;
				alpha = 1;
				changeOverCallback();
			} else {
				dir = 1;
				alpha = 0;
			}
			if(text != ""){
				textCount = TEXT_DELAY;
				textBox.text = text;
				textBox.visible = true;
				textBox.alpha = 0;
			}
		}
		
	}

}