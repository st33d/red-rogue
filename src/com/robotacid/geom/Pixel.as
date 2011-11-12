package com.robotacid.geom {
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class Pixel {
		
		public var x:int;
		public var y:int;
		
		public function Pixel(x:int = 0, y:int = 0) {
			this.x = x;
			this.y = y;
		}
		/* Manhattan distance */
		public function mDist(p:Pixel):int{
			return (p.x < x ? x - p.x : p.x - x) + (p.y < y ? y - p.y : p.y - y);
		}
		public function toString():String {
			return "(" + x + "," + y + ")";
		}
		public function copy():Pixel{
			return new Pixel(x, y);
		}
		
	}
	
}