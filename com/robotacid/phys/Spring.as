package com.robotacid.phys {
	import com.robotacid.geom.Dot;
	import com.robotacid.geom.Line;
	
	/**
	* Basic (really basic) spring class based on Flade engine springs
	* Fast and barely customisable
	* If you want proper springs, goto processing.org and nick the ones off of there
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class Spring extends Line{
		
		public var rest_length:Number;	// length the spring returns to
		public var stiffness:Number;	// the speed the spring returns to normal - a value above 0.5 is unstable
		
		public function Spring(a:Dot, b:Dot){
			super(a, b);
			stiffness = 0.5;
			rest_length = length;
		}
		// Spring physics
		public function updateSpring():void{
			vx = b.x - a.x;
			vy = b.y - a.y;
			length = Math.sqrt(vx * vx + vy * vy);
			var diff:Number = 0;
			if(length > 0){
				diff = (length - rest_length) / length;
			}
			var mul:Number = diff * stiffness;
			var move_by:Dot = new Dot( -vx * mul, -vy * mul);
			a.x -= move_by.x;
			a.y -= move_by.y;
			b.x += move_by.x;
			b.y += move_by.y;
			updateLine();
		}
		// constrain spring length
		public function constrainFromA(min_length:Number, max_length:Number):void{
			updateLine();
			if(length < min_length){
				b.x = a.x + min_length * dx;
				b.y = a.y + min_length * dy;
				updateLine();
			} else if(length > max_length){
				b.x = a.x + max_length * dx;
				b.y = a.y + max_length * dy;
				updateLine();
			}
		}
		public function constrainFromB(min_length:Number, max_length:Number):void{
			updateLine();
			if(length < min_length){
				a.x = b.x + min_length * -dx;
				a.y = b.y + min_length * -dy;
				updateLine();
			} else if(length > max_length){
				a.x = b.x + max_length * -dx;
				a.y = b.y + max_length * -dy;
				updateLine();
			}
		}
	}
	
}