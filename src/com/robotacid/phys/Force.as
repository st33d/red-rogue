package com.robotacid.phys {
	import flash.geom.Point;
	
	/**
	 * Applies movement to a Collider separate from its vx,vy properties
	 * @author Aaron Steed, robotacid.com
	 */
	public class Force extends Point {
		
		public var active:Boolean;
		public var dampingX:Number;
		public var dampingY:Number;
		public var collider:Collider;
		
		private var activity:int;
		
		public function Force(collider:Collider, x:Number = 0, y:Number = 0, dampingX:Number = 1, dampingY:Number = 1) {
			super(x, y);
			this.dampingX = dampingX;
			this.dampingY = dampingY;
			this.collider = collider;
			active = true;
		}
		
		public function main():void{
			if(!collider.world){
				active = false;
				return;
			}
			// forces are run before the collider's main(),
			// state changes are left for the Collider to check and manage
			activity = 0;
			if((x > 0 ? x : -x) > Collider.MOVEMENT_TOLERANCE){
				collider.moveX(x);
				activity++;
			}
			if((y > 0 ? y : -y) > Collider.MOVEMENT_TOLERANCE){
				collider.moveY(y);
				activity++;
			}
			// self destruct once damping has eroded the force enough
			if(activity == 0){
				active = false;
			} else {
				x *= dampingX;
				y *= dampingY;
			}
		}
		
	}

}