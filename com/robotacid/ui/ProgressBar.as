package com.robotacid.ui {
	import flash.display.Shape;
	import flash.events.Event;
	
	/**
	 * This is a progress bar for loading, health, experience, etc.
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class ProgressBar extends Shape{
		
		public var _border_col:uint = 0xFFFFFF;
		public var _back_col:uint = 0x000000;
		public var _bar_col:uint = 0xFFFFFF;
		
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
		
		public function set border_col(n:uint):void{
			_border_col = n;
			update();
		}
		
		public function get border_col():uint{
			return _border_col;
		}
		
		public function set bar_col(n:uint):void{
			_bar_col = n;
			update();
		}
		
		public function get bar_col():uint{
			return _bar_col;
		}
		
		public function set back_col(n:uint):void{
			_back_col = n;
			update();
		}
		
		public function get back_col():uint{
			return _back_col;
		}
		
		private function update():void{
			graphics.clear();
			graphics.beginFill(_border_col);
			graphics.drawRect(0, 0, _width, _height);
			graphics.endFill();
			graphics.beginFill(_back_col);
			graphics.drawRect(1, 1, _width-2, _height-2);
			graphics.endFill();
			graphics.beginFill(_bar_col);
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