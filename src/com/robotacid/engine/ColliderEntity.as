package com.robotacid.engine {
	import com.robotacid.phys.Collider;
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	
	/**
	 * Base Entity for all objects that use Colliders
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class ColliderEntity extends Entity {
		
		public var collider:Collider;
		
		public function ColliderEntity(gfx:DisplayObject, addToEntities:Boolean = true) {
			super(gfx, true, addToEntities);
			
		}
		
		/* Initialises the collider for this Entity */
		public function createCollider(x:Number, y:Number, properties:int, ignoreProperties:int, state:int = 0, positionByBase:Boolean = true):void{
			var bounds:Rectangle = gfx.getBounds(gfx);
			if(positionByBase){
				collider = new Collider(x - bounds.width * 0.5, y - bounds.height, bounds.width, bounds.height, Game.SCALE, properties, ignoreProperties, state);
			} else {
				collider = new Collider(x + bounds.left, y + bounds.top, bounds.width, bounds.height, Game.SCALE, properties, ignoreProperties, state);
			}
			collider.userData = this;
			mapX = (collider.x + collider.width * 0.5) * Game.INV_SCALE;
			mapY = (collider.y + collider.height * 0.5) * Game.INV_SCALE;
		}
		
		override public function remove():void {
			if(collider.world) collider.world.removeCollider(collider);
			super.remove();
		}
		
	}

}