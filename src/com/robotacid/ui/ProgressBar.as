package com.robotacid.ui {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	/**
	 * This is a progress bar for loading, health, experience, etc.
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class ProgressBar extends Sprite{
		
		public var active:Boolean;
		public var bitmap:Bitmap
		public var bitmapData:BitmapData;
		public var glowShape:Shape;
		public var glowActive:Boolean;
		
		public var borderCol:uint = 0xFFFFFFFF;
		public var backCol:uint = 0xFF000000;
		public var barCol:uint = 0xFFFFFFFF;
		
		private var glowCol:uint;
		private var glowRatio:Number;
		
		private var rect:Rectangle;
		private var barRect:Rectangle;
		private var backRect:Rectangle;
		private var value:Number;
		
		public static var glowTable:Vector.<Number>;
		public static var glowCount:int;
		
		public function ProgressBar(x:Number, y:Number, width:Number, height:Number, glowRatio:Number = 0, glowCol:uint = 0xFFFFFF) {
			this.x = x;
			this.y = y;
			rect = new Rectangle(0, 0, width, height);
			barRect = new Rectangle(1, 1, width - 2, height - 2);
			backRect = barRect.clone();
			value = 1.0;
			this.glowRatio = glowRatio;
			this.glowCol = glowCol;
			if(glowRatio){
				glowShape = new Shape();
				addChild(glowShape);
				addEventListener(Event.ENTER_FRAME, main, false, 0, true);
			}
			bitmap = new Bitmap(new BitmapData(width, height, true, 0x0));
			bitmapData = bitmap.bitmapData;
			addChild(bitmap);
			active = true;
			update();
		}
		
		public function setValue(n:Number, total:Number):void{
			if(total != 1) value = (1.0 / total) * n;
			else value = n;
			if(value < 0) value = 0;
			if(value > 1) value = 1;
			if(glowShape) glowActive = glowRatio && value <= glowRatio;
			update();
		}
		
		public function update():void{
			if(glowShape){
				graphics.clear();
				if(glowActive){
					graphics.beginFill(glowCol, glowTable[glowCount]);
					graphics.drawRect(0, 0, rect.width, rect.height);
				}
			}
			bitmapData.fillRect(rect, borderCol);
			bitmapData.fillRect(backRect, glowActive ? 0x0 : backCol);
			barRect.width = (value * backRect.width) >> 0;
			bitmapData.fillRect(barRect, barCol);
		}
		
		private function main(e:Event):void{
			if(glowActive) update();
			if(active){
				if(alpha < 1){
					alpha += 0.1;
					if(alpha >= 1 && glowRatio == 0){
						removeEventListener(Event.ENTER_FRAME, main);
					}
				}
			} else if(!active){
				if(alpha > 0){
					alpha -= 0.1;
					if(alpha <= 0){
						removeEventListener(Event.ENTER_FRAME, main);
					}
				}
			}
		}
		
		public function activate():void{
			active = true;
			if(alpha < 1){
				addEventListener(Event.ENTER_FRAME, main);
			}
		}
		
		public function deactivate():void{
			active = false;
			if(alpha > 0){
				addEventListener(Event.ENTER_FRAME, main);
			}
		}
		
		public static function initGlowTable():void{
			var step:Number = Math.PI / 15;
			glowTable = new Vector.<Number>();
			for(var r:Number = 0; r < Math.PI * 2; r += step){
				glowTable.push(Math.sin(r));
			}
		}
		
	}
	
}