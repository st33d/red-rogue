package com.robotacid.engine {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	/**
	 * Like a trap but will listen for contact with all active ColliderEntities on a level
	 * 
	 * The callback must have a single parameter that accepts an ColliderEntity object
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class ColliderEntitySensor extends Entity {
		
		public var rect:Rectangle;
		public var callback:Function;
		
		private static var i:int;
		private static var colliderEntity:ColliderEntity;
		
		public function ColliderEntitySensor(rect:Rectangle, callback:Function) {
			super(new Sprite(), false, true);
			gfx.visible = false;
			this.rect = rect;
			this.callback = callback;
			callMain = true;
		}
		
		override public function main():void {
			if(game.player.collider.intersects(rect)) callback(game.player);
			for(i = 0; i < game.entities.length; i++){
				colliderEntity = game.entities[i] as ColliderEntity;
				if(colliderEntity && colliderEntity.collider.intersects(rect)){
					callback(colliderEntity);
				}
			}
		}
	}

}