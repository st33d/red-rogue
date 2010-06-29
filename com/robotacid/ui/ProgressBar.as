package com.robotacid.ui {
	import flash.display.Shape;
	import flash.events.Event;
	
	/**
	 * This is a progress bar for loading, health, experience, etc.
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class ProgressBar extends Shape{
		
		private var _borderCol:uint = 0xFFFFFF;
		private var _backCol:uint = 0x000000;
		private var _barCol:uint = 0xFFFFFF;
		
		private var _width:Number;
		private var _height:Number;
		
		private var _value:Number;
		
		public var active:Boolean = true;
		
		public function ProgressBar(x:Number, y:Number, width:Number, height:Number) {
			this.x = x;
			this.y = y;
			_width = width;
			_height = height;
			_value = 1.0;
			update();
		}
		
		public function setValue(n:Number, total:Number):void{
			_value = (1.0 / total) * n;
			if(_value < 0) _value = 0;
			update();
		}
		
		public function set value(n:Number):void{
			_value = n;
			update();
		}
		
		public function get value():Number{
			return _value;
		}
		
		public function set borderCol(n:uint):void{
			_borderCol = n;
			update();
		}
		
		public function get borderCol():uint{
			return _borderCol;
		}
		
		public function set barCol(n:uint):void{
			_barCol = n;
			update();
		}
		
		public function get barCol():uint{
			return _barCol;
		}
		
		public function set backCol(n:uint):void{
			_backCol = n;
			update();
		}
		
		public function get backCol():uint{
			return _backCol;
		}
		
		private function update():void{
			graphics.clear();
			graphics.beginFill(_borderCol);
			graphics.drawRect(0, 0, _width, _height);
			graphics.endFill();
			graphics.beginFill(_backCol);
			graphics.drawRect(1, 1, _width-2, _height-2);
			graphics.endFill();
			graphics.beginFill(barCol);
			graphics.drawRect(1, 1, (_width-2) * _value, _height-2);
			graphics.endFill();
		}
		
		private function change(e:Event):void{
			if(active){
				if(alpha < 1){
					alpha += 0.1;
					if(alpha >= 1){
						removeEventListener(Event.ENTER_FRAME, change);
					}
				}
			} else if(!active){
				if(alpha > 0){
					alpha -= 0.1;
					if(alpha <= 0){
						removeEventListener(Event.ENTER_FRAME, change);
					}
				}
			}
		}
		
		public function activate():void{
			active = true;
			if(alpha < 1){
				addEventListener(Event.ENTER_FRAME, change);
			}
		}
		
		public function deactivate():void{
			active = false;
			if(alpha > 0){
				addEventListener(Event.ENTER_FRAME, change);
			}
		}
		
	}
	
}