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
		public var _borderCol:uint = 0xFFFFFF;
		public var _backCol:uint = 0x000000;
		public var barCol:uint = 0xFFFFFF;
		public var _units:int;
		public var _width:Number;
		public var _height:Number;
		public var _value:Number;
		
		private var yDiff:Number;
		
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
			yDiff = bar.mouseY;
		}
		
		public function barReleased(e:MouseEvent = null):void{
			removeEventListener(Event.ENTER_FRAME, barUpdate);
		}
		
		public function barUpdate(e:Event = null):void{
			bar.y = mouseY - yDiff;

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
			barCol = n;
			update();
		}
		
		public function get barCol():uint{
			return barCol;
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
			bar.graphics.beginFill(barCol);
			bar.graphics.drawRect(0, 0, _width - 2, 5);
			bar.graphics.endFill();
		}
	}

}