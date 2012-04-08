package com.robotacid.gfx {
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	/**
	 * Renders a collection of cogs at the corners of a rectangle
	 * 
	 * The x and y is given as the center of the rectangle
	 * 
	 * The formation and extension are customisable
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class CogRectBlit extends BlitClip {
		
		public var displacement:Number;
		public var visibles:Vector.<Boolean>;
		public var allVisible:Boolean;
		public var dirs:Vector.<int>;
		
		private static var i:int;
		
		public static const TOP_LEFT:int = 0;
		public static const TOP_RIGHT:int = 1;
		public static const BOTTOM_RIGHT:int = 2;
		public static const BOTTOM_LEFT:int = 3;
		public static const VECTORS:Vector.<Point> = Vector.<Point>([
			new Point(-1, -1), new Point(1, -1), new Point(1, 1), new Point(-1, 1)
		]);
		
		public static const TOTAL:int = 4;
		
		private static var vector:Point;
		
		public function CogRectBlit() {
			super(new CogMC);
			visibles = Vector.<Boolean>([true, true, true, true]);
			allVisible = true;
			dirs = Vector.<int>([1, -1, -1, 1]);
			displacement = 0;
		}
		
		override public function render(destination:BitmapData, frame:int = 0):void {
			for(i = 0; i < TOTAL; i++){
				if(allVisible || visibles[i]){
					vector = VECTORS[i];
					p.x = x + dx + vector.x * displacement;
					p.y = y + dy + vector.y * displacement;
					destination.copyPixels(frames[(dirs[i] > 0 ? frame : (totalFrames - 1) - frame)], rect, p, null, null, true);
				}
			}
		}
		
	}

}