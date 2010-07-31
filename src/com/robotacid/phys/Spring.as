package com.robotacid.phys {
	import com.robotacid.geom.Line;
	import flash.geom.Point;
	
	/**
	* Basic (really basic) spring class based on Flade engine springs
	* Fast and barely customisable
	* If you want proper springs, goto processing.org and nick the ones off of there
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class Spring extends Line{
		
		public var restLength:Number;	// length the spring returns to
		public var stiffness:Number;	// the speed the spring returns to normal - a value above 0.5 is unstable
		
		public function Spring(a:Point, b:Point){
			super(a, b);
			stiffness = 0.5;
			restLength = length;
		}
		// Spring physics
		public function updateSpring():void{
			vx = b.x - a.x;
			vy = b.y - a.y;
			length = Math.sqrt(vx * vx + vy * vy);
			var diff:Number = 0;
			if(length > 0){
				diff = (length - restLength) / length;
			}
			var mul:Number = diff * stiffness;
			var moveBy:Point = new Point( -vx * mul, -vy * mul);
			a.x -= moveBy.x;
			a.y -= moveBy.y;
			b.x += moveBy.x;
			b.y += moveBy.y;
			updateLine();
		}
		// constrain spring length
		public function constrainFromA(minLength:Number, maxLength:Number):void{
			updateLine();
			if(length < minLength){
				b.x = a.x + minLength * dx;
				b.y = a.y + minLength * dy;
				updateLine();
			} else if(length > maxLength){
				b.x = a.x + maxLength * dx;
				b.y = a.y + maxLength * dy;
				updateLine();
			}
		}
		public function constrainFromB(minLength:Number, maxLength:Number):void{
			updateLine();
			if(length < minLength){
				a.x = b.x + minLength * -dx;
				a.y = b.y + minLength * -dy;
				updateLine();
			} else if(length > maxLength){
				a.x = b.x + maxLength * -dx;
				a.y = b.y + maxLength * -dy;
				updateLine();
			}
		}
	}
	
}