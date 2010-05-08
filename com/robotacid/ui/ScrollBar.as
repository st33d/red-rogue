package com.robotacid.ui {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class ScrollBar extends Sprite{
		
		public var bar:Sprite;
		public var _border_col:uint = 0xFFFFFF;
		public var _back_col:uint = 0x000000;
		public var _bar_col:uint = 0xFFFFFF;
		public var _units:int;
		public var _width:Number;
		public var _height:Number;
		public var _value:Number;
		
		private var y_diff:Number;
		
		public var length:Number;
		public var ration:Number;
		
		public static const MIN_BAR_HEIGHT:Number = 5;
		
		public function ScrollBar(width:Number, height:Number, units:int) {
			bar = new Sprite();
			addChild(bar);
			_units = units;
			mouseChildren = true;
			_width = width;
			_height = height;
			bar.addEventListener(MouseEvent.MOUSE_DOWN, barPressed);
			bar.addEventListener(MouseEvent.MOUSE_UP, barReleased);
			addEventListener(MouseEvent.CLICK, trackPressed);
			bar.x = bar.y = 1;
			update();
		}
		
		public function trackPressed(e:MouseEvent = null):void{
			//bar.y = mouseY;
			if(bar.y > _height - 1 - bar.height * 0.5) bar.y = _height - 1 - bar.height * 0.5;
			if(bar.y < 1 + bar.height * 0.5) bar.y = 1 + bar.height * 0.5;
		}
		
		public function barPressed(e:MouseEvent = null):void{
			addEventListener(Event.ENTER_FRAME, barUpdate);
			y_diff = bar.mouseY;
		}
		
		public function barReleased(e:MouseEvent = null):void{
			removeEventListener(Event.ENTER_FRAME, barUpdate);
		}
		
		public function barUpdate(e:Event = null):void{
			bar.y = mouseY - y_diff;

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
			bar.graphics.beginFill(_bar_col);
			bar.graphics.drawRect(0, 0, _width - 2, 5);
			bar.graphics.endFill();
		}
	}

}