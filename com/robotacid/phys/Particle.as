package com.robotacid.phys {
	import com.robotacid.geom.Dot;
	
	/**
	* Free floating Verlet Integration particle
	*
	* This is more a reference than something I use these days
	* it's far more efficient to inline verlet integration
	*
	* Useful for doing basic springs though
	*
	* To manage a physics system with springs, call methods in the following order:
	*
	* verlet, then update springs, then pin static particles, then constrain any springs
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class Particle extends Dot{
		public var ix:Number;//		initial x position
		public var iy:Number;//		initial y position
		public var px:Number;//		previous x position
		public var py:Number;//		previous y position
		public var tempX:Number;//		temp variable
		public var tempY:Number;//		temp variable
		
		public function Particle(x:Number = 0, y:Number = 0){
			super(x, y);
			px = tempX = x;
			py = tempY = y;
		}
		/* Moves the particle */
		public function verlet(gravity_x:Number, gravity_y:Number, damping:Number):void{
			tempX = x;
			tempY = y;
			x += damping * (x - px) + gravity_x;
			y += damping * (y - py) + gravity_y;
			px = tempX;
			py = tempY;
		}
		/* Set the position and initial position */
		public function setPosition(x:Number, y:Number):void{
			this.x = px = tempX = ix = x;
			this.y = py = tempY = iy = y;
		}
		/* Fix the particle to it's start position */
		public function pin():void{
			x = px = tempX = ix;
			y = py = tempY = iy;
		}
		/* Fix the particle to a given position */
		public function pinTo(x:Number, y:Number):void{
			this.x = ix = px = tempX = x;
			this.y = iy = py = tempY = y;
		}
		/* Create a Line describing the last frame of movement */
		public function getLine():Line{
			return new Line(new Dot(px, py), this);
		}
		/* Calculate current speed */
		public function speed():Number{
			return Math.sqrt((x-px)*(x-px)+(y-py)*(y-py));
		}
		/* Calculate current y speed */
		public function yspeed():Number{
			return y-py;
		}
		/* Calculate current x speed */
		public function xspeed():Number{
			return x-px;
		}
		/* Add velocity to the particle */
		public function addVelocity(x:Number, y:Number):void{
			px -= x;
			py -= y;
		}
		/* Generate a copy of this particle with duplicate velocity */
		public function copy():Particle{
			var temp = new Particle(x, y);
			temp.px = px;
			temp.py = py;
			return temp;
		}
		/* Add counter-thrust to the direction it last travelled */
		public function reverse(strength:Number):void{
			var vx:Number = px-x;
			var vy:Number = py-y;
			addVelocity(vx * strength, vy * strength);
		}
		/* Return a string describing the current and previous location of this Particle */
		override public function toString():String{
			return "("+x+","+y+") "+x+","+y;
		}
		
	}
	
}