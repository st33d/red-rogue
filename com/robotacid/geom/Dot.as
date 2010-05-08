package com.robotacid.geom {
	
	/**
	* Light weight version of flash's Point
	* 
	* I've discovered that whilst member access and creation times are the same
	* Flash's methods for distance and such are amazingly slow for some reason
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class Dot {
		public var x:Number;
		public var y:Number;
		
		public function Dot(x:Number = 0, y:Number = 0) {
			this.x = x;
			this.y = y;
		}
		public function dist(d:Dot):Number{
			return Math.sqrt((d.x - x) * (d.x - x) + (d.y - y) * (d.y - y));
		}
		/* squared distance */
		public function sqDist(d:Dot):Number{
			return (d.x - x) * (d.x - x) + (d.y - y) * (d.y - y);
		}
		public function lerp(d:Dot, n:Number):Dot{
			return new Dot(x + ((d.x - x) * n), y + ((d.y - y) * n));
		}
		public function toString():String {
			return "(" + x + "," + y + ")";
		}
	}
	
}