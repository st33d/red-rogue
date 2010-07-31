package com.robotacid.geom {
	import flash.display.Graphics;
	import flash.geom.Point;
	
	/**
	* Line class for vector math and calculation of positions and directions
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class Line {
		
		public var a:Point;// 		Old position x,y
		public var b:Point;// 		Current position x,y
		public var vx:Number;// 	distance between p0.x and p1.x
		public var vy:Number;// 	distance between p0.y and p1.y
		public var length:Number;// vector length (pythagoras length of a to b)
		public var sqLength:Number;// squared length
		public var dx:Number;// 	x value of unit vector (equal to Math.cos(theta))
		public var dy:Number;// 	y value of unit vector (equal to Math.sin(theta))
		public var rx:Number;// 	x value of right hand unit vector
		public var ry:Number;// 	y value of right hand unit vector
		public var lx:Number;// 	x value of left hand unit vector
		public var ly:Number;// 	y value of left hand unit vector
		public var theta:Number;// 	rotation - updated by calling atan2 or rotate methods
		
		public function Line(a:Point, b:Point){
			this.a = a;
			this.b = b;
			updateLine();
		}
		/* Call this whenever the position of a or b is updated to recalculate properties */
		public function updateLine():void{
			vx = b.x - a.x;
			vy = b.y - a.y;
			// length of vector
			sqLength = vx * vx + vy * vy;
			length = Math.sqrt(sqLength);
			// normalized unit-sized components
			if (length > 0) {
				dx = vx / length;
				dy = vy / length;
			} else {
				dx = dy = 0;
			}
			// right hand normal
			rx = -dy;
			ry = dx;
			// left hand normal
			lx = dy;
			ly = -dx;
		}
		/* Rotate vector around point A */
		public function rotateA(angle:Number):void{
			angle += atan2();
			theta = angle;
			b.x = a.x + Math.cos(angle) * length;
			b.y = a.y + Math.sin(angle) * length;
			updateLine();
		}
		/* Rotate vector around point B */
		public function rotateB(angle:Number):void{
			angle += atan2();
			theta = angle;
			a.x = b.x + Math.cos(angle) * length;
			a.y = b.y + Math.sin(angle) * length;
			updateLine();
		}
		/* Calculate atan2() as an angle from dot a to dot b
		 * Stores result as property theta and returns its value */
		public function atan2():Number{
			theta = Math.atan2(vy, vx);
			return theta;
		}
		/* Return a point along the line */
		public function lerp(n:Number):Point{
			return new Point(a.x + ((b.x - a.x) * n), a.y + ((b.y - a.y) * n));
		}
		/* return the a and b properties of this line as a string */
		public function toString():String{
			return "a:("+a.x+","+a.y+") b:("+b.x+","+b.y+")";
		}
		/* draw this line */
		public function draw(gfx:Graphics):void{
			gfx.moveTo(a.x, a.y);
			gfx.lineTo(b.x, b.y);
		}
		/* draw this line with dashes */
		public function drawDashed(gfx:Graphics, step:Number, offset:Number = 0):void{
			var n:Number;
			if(offset > step * 2) offset = offset % (step * 2);
			if(offset > step) {
				gfx.moveTo(a.x, a.y);
				gfx.lineTo(a.x + (offset - step) * dx, a.y + (offset - step) * dy);
			}
			for(n = offset; n < length - step; n += step * 2) {
				gfx.moveTo(a.x + n * dx, a.y + n * dy);
				gfx.lineTo(a.x + (n + step) * dx, a.y + (n + step) * dy);
			}
			if(n > length - step && n < length) {
				gfx.moveTo(a.x + n * dx, a.y + n * dy);
				gfx.lineTo(b.x, b.y);
			}
		}
		/* Return a copy of this line with new Point objects */
		public function copy():Line{
			return new Line(new Point(a.x, a.y), new Point(b.x, b.y));
		}
		/* Returns true if x,y is within a distance of r to the line */
		public function proximity(x:Number, y:Number, r:Number):Boolean{
			var c:Point = new Point(x, y);
			// vertex region check
			var segment:Line = this;
			//Line toCircle = new Line(a, c);
			var toCircleVx:Number = c.x - a.x;
			var toCircleVy:Number = c.y - a.y;
			// vertex region check
			var length:Number = dot(segment, segment);
			var dp:Number = toCircleVx * segment.vx + toCircleVy * segment.vy;
			var vx:Number, vy:Number;
			if(dp < 0){
				// a is the closest vertex
				vx = c.x - a.x;
				vy = c.y - a.y;
				if(vx * vx + vy * vy < r * r) return true;
			} else if(dp > length){
				// b is the closest vertex
				vx = c.x - b.x;
				vy = c.y - b.y;
				if(vx * vx + vy * vy < r * r) return true;
			} else if(dp >=0 && dp <=length){
				// segment region check - check distance to line
				var np:Number = (toCircleVx*-segment.lx)+(toCircleVy*-segment.ly);
				vx = np*segment.lx;
				vy = np*segment.ly;
				var d:Number = vx*vx+vy*vy;
				if((r*r)-d >= 0) return true;
			}
			return false;
		}
		
		/* VECTOR MATH
		 *
		 * To be honest I just use this stuff as a reference these days.
		 * Any code which uses vector math is generally in an area ripe for
		 * optimisation, so a paraphrase of the math and a comment is usually
		 * for the best
		 */
		
		/* create a new Line that is a projection of la and lb */
		public static function projection(la:Line, lb:Line):Line{
			var dot:Number = Line.dot(la, lb);
			return new Line(new Point(0, 0), new Point(la.dx * dot, la.dy * dot));
		}
		/* Perpendicular product (dot product rotated 90 degrees) */
		public static function perP(va:Object, vb:Object):Number{
			var pp:Number = va.vx * vb.vy - va.vy * vb.vx;
			return pp;
		}
		/* Mini perpendicular product (normalised dot product rotated 90 degrees) */
		public static function miniPerP(va:Object, vb:Object):Number{
			var pp:Number = va.dx * vb.dy - va.dy * vb.dx;
			return pp;
		}
		/* Returns a point on the same Line as the surface you are projecting on to */
		public static function intersectionPoint(v1:Object, v2:Object):Object{
			var v3:Object = {vx:v2.a.x - v1.a.x, vy:v2.a.y - v1.a.y};
			var t:Number=perP(v3, v2)/perP(v1, v2);
			var ip:Object={};
			ip.x=v1.a.x+v1.vx*t;
			ip.y=v1.a.y+v1.vy*t;
			return ip;
		}
		/* Do two Lines intersect? */
		public static function intersects(v1:Object, v2:Object):Boolean{
			var v3:Object = {vx:v2.a.x - v1.a.x, vy:v2.a.y - v1.a.y};
			var perp0:Number = perP(v3, v2);
			var perp1:Number = perP(v1, v2);
			var t0:Number=perp0/perp1;
			var t1:Number=perp1/perp0;
			return t0 >= 0 && t0 <= 1 && t1 >= 0 && t1 <= 1;
		}
		/* Returns the dot product of two lines or Objects with vx and vy properties */
		public static function dot(v1:Object, v2:Object):Number{
			return v1.vx * v2.vx + v1.vy * v2.vy;
		}
		
	}
	
}