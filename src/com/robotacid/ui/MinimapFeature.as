package com.robotacid.ui {
	import flash.display.BitmapData;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class MinimapFeature {
		
		public static var minimap:MiniMap;
		
		public var bitmapData:BitmapData;
		public var active:Boolean;
		public var x:Number;
		public var y:Number;
		public var dx:Number;
		public var dy:Number;
		
		private static var point:Point = new Point();
		
		public function MinimapFeature(x:Number, y:Number, dx:Number, dy:Number, bitmapData:BitmapData) {
			this.x = x;
			this.y = y;
			this.dx = dx;
			this.dy = dy;
			this.bitmapData = bitmapData;
			active = true;
		}
		
		public function render():void {
			point.x = ( -minimap.view.x) + x + dx;
			point.y = ( -minimap.view.y) + y + dy;
			minimap.window.bitmapData.copyPixels(bitmapData, bitmapData.rect, point, null, null, true);
		}
	}

}