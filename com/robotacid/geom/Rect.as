package com.robotacid.geom {
	import flash.display.Graphics;
	
	/**
	* Lightweight version of flash's Rectangle class
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class Rect {
		
		public var x:Number;
		public var y:Number;
		public var cx:Number;
		public var cy:Number;
		public var width:Number;
		public var height:Number;
		
		/* The following constants are used throughout the engine to infer
		 * sides and directions. They can be stacked in an int using the OR bitwise
		 * operator "|". The presence of one of these properties can be determine using
		 * the AND bitwise operator "&"
		 *
		 * eg:
		 *
		 * n |= UP
		 *
		 * if(n & UP) // do something
		 */
		
		public static const UP:int = 1 << 0;
		public static const RIGHT:int = 1 << 1;
		public static const DOWN:int = 1 << 2;
		public static const LEFT:int = 1 << 3;
		
		// applying XOR to a value with the following masks will flip the direction
		// eg: UP becomes DOWN, however - if UP and DOWN are present, it will clear UP and DOWN rather than flip them
		public static const FLIP_VERTICAL:int = (1 << 0) + (1 << 2);
		public static const FLIP_HORIZONTAL:int = (1 << 1) + (1 << 3);
		
		public function Rect(x:Number = 0, y:Number = 0, width:Number = 0, height:Number = 0){
			this.x = x;
			this.y = y;
			this.width = width;
			this.height = height;
		}
		
		public function resize(x:Number, y:Number, width:Number, height:Number):void{
			this.x = x;
			this.y = y;
			this.width = width;
			this.height = height;
		}
		
		/* Do two Rects intersect? */
		public function intersects(b:Rect):Boolean{
			return !(this.x > b.x + (b.width - 1) || this.x + (this.width - 1) < b.x || this.y > b.y + (b.height - 1) || this.y + (this.height - 1) < b.y);
		}
		/* Is this point inside the Rect */
		public function contains(x:Number, y:Number):Boolean{
			return x >= this.x && y >= this.y && x < this.x + width && y < this.y + height;
		}
		/* Is this Rect inside Rect 'r' (extreme version of intersection) */
		public function inside(r:Rect):Boolean{
			return x + (width - 1) < r.x + r.width && y + (height - 1) < r.y + r.height && x >= r.x && y >= r.y;
		}
		/* Return the intersection between this and another Rect as a Rect
		 * - TEST FOR AN INTERSECTION FIRST -
		 * this is to optimise whilst doing intersection tests
		 */
		public function intersection(b:Rect):Rect{
			return new Rect(Math.max(x, b.x), Math.max(y, b.y), Math.abs(Math.max(x, b.x) - Math.min(x + width, b.x + b.width)), Math.abs(Math.max(y, b.y) - Math.min(y + height, b.y + b.height)));
		}
		/* Return a rect as the bounding box of two points */
		public static function boundingBox(x0:Number, y0:Number, x1:Number, y1:Number):Rect{
			return new Rect(Math.min(x0, x1), Math.min(y0, y1),  Math.abs(x0 - x1), Math.abs(y0 - y1));
		}
		/* Does this rect intersect a circle with center point cx,cy and radius r */
		public function intersectsCircle(cx:Number, cy:Number, r:Number):Boolean{
			var test_x:Number = cx;
			var test_y:Number = cy;
			if(test_x < x) test_x = x;
			if(test_x > (x + width-1)) test_x = (x + width-1);
			if(test_y < y) test_y = y;
			if(test_y > (y + height-1)) test_y = (y + height-1);
			return ((cx - test_x) * (cx - test_x) + (cy - test_y) * (cy - test_y)) < r * r;
		}
		/* Returns a lazy check for what side of this rect is x,y
		 * assumes Rect is a perfect square
		 */
		public function sideOf(x:Number, y:Number):int{
			cx = this.x + width*0.5;
			cy = this.y + height*0.5;
			if(x == cx && y == cy) return 2;
			var vx:Number = x-cx;
			var vy:Number = y-cy;
			//establish octant
			if (x > cx && y > cy && Math.abs(vy) < Math.abs(vx)) return 2;
			if (x > cx && y > cy && Math.abs(vy) > Math.abs(vx)) return 4;
			if (x < cx && y > cy && Math.abs(vy) > Math.abs(vx)) return 4;
			if (x < cx && y > cy && Math.abs(vy) < Math.abs(vx)) return 8;
			if (x < cx && y < cy && Math.abs(vy) < Math.abs(vx)) return 8; // reversal of octant 0
			if (x < cx && y < cy && Math.abs(vy) > Math.abs(vx)) return 1; // reversal of octant 1
			if (x > cx && y < cy && Math.abs(vy) > Math.abs(vx)) return 1; // reversal of octant 2
			if (x > cx && y < cy && Math.abs(vy) < Math.abs(vx)) return 2; // reversal of octant 3
			//line must be on division of octants
			if (y == cy && x > cx) return 2;
			if (x == cx && y > cy) return 4;
			if (y == cy && x < cx) return 8;
			if (x == cx && y < cy) return 1;
			if(vx == Math.abs(vx) && vy == -Math.abs(vy)) return 2;
			if(vy == Math.abs(vy) && vx == Math.abs(vx)) return 4;
			if(vy == Math.abs(vy) && vx == -Math.abs(vx)) return 8;
			if(vy == -Math.abs(vy) && vx == -Math.abs(vx)) return 1;
			return 0;
		}
		/* Takes a prepared array of Dots / Points and loads them with the corners of the rect */
		public function getCorners(corners:Array):Array{
			corners[0].x = x;
			corners[0].y = y;
			corners[1].x = x + width - 1;
			corners[1].y = y;
			corners[2].x = x + width - 1;
			corners[2].y = y + height - 1;
			corners[3].x = x;
			corners[3].y = y + height - 1;
			return corners;
		}
		/* Return the side opposite to the one offered an invalid side returns 0 */
		public static function oppositeSide(n:int):int{
			if(n == UP) return DOWN;
			else if(n == RIGHT) return LEFT;
			else if(n == DOWN) return UP;
			else if(n == LEFT) return RIGHT;
			return 0;
		}
		/* Return a Dot where the current center of this rect is */
		public function center():Dot{
			return new Dot(x + width * 0.5, y + height * 0.5);
		}
		/* Returns a string describing this rect */
		public function toString():String{
			return "(x:"+x+" y:"+y+" width:"+width+" height:"+height+")";
		}
		/* Draw this rect */
		public function draw(gfx:Graphics):void{
			gfx.drawRect(x, y, width, height);
		}
	}
	
}