package com.robotacid.engine {
	import com.robotacid.gfx.Renderer;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Base game object
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Entity {
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		public var gfx:DisplayObject;
		public var active:Boolean;
		public var addToEntities:Boolean;
		public var callMain:Boolean;
		
		public var name:int;
		public var light:int;
		public var lightCols:Vector.<uint>;
		public var tileId:String;
		public var free:Boolean = false;
		public var mapX:int, mapY:int, mapZ:int;
		public var initX:int, initY:int;
		
		// these are debug tools for differentiating between objects and their instantiation order
		public static var entityCount:int = 0;
		public var entityNum:int;
		
		public static var matrix:Matrix = new Matrix();
		
		public static const SCALE:Number = Game.SCALE;
		public static const INV_SCALE:Number = Game.INV_SCALE;
		
		public function Entity(gfx:DisplayObject, free:Boolean = false, addToEntities:Boolean = true) {
			this.gfx = gfx;
			this.free = free;
			this.addToEntities = addToEntities;
			active = true;
			callMain = false;
			light = 0;
			entityNum = entityCount++;
			if(addToEntities) game.entities.push(this);
		}
		
		public function main():void{
			
		}
		
		/* Called to make this object visible */
		public function render():void{
			matrix = gfx.transform.matrix;
			matrix.tx -= renderer.bitmap.x;
			matrix.ty -= renderer.bitmap.y;
			renderer.bitmapData.draw(gfx, matrix, gfx.transform.colorTransform);
		}
		
		public function unpause():void{
			
		}
		
		/* Remove from play and convert back into a map number.
		 * Free roaming encounters will want to pin themselves in a new locale
		 */
		public function remove():void {
			if(active){
				active = false;
				// if there is already content on the id map, then we convert that content into an array
				if(game.mapTileManager.mapLayers[mapZ][mapY][mapX]){
					if(game.mapTileManager.mapLayers[mapZ][mapY][mapX] is Array){
						game.mapTileManager.mapLayers[mapZ][mapY][mapX].push(this);
					} else {
						game.mapTileManager.mapLayers[mapZ][mapY][mapX] = [game.mapTileManager.mapLayers[mapZ][mapY][mapX], this];
					}
				} else game.mapTileManager.mapLayers[mapZ][mapY][mapX] = this;
			}
		}
		
		public function nameToString():String{
			return "none";
		}
		
		public function toXML():XML{
			return <entity />;
		}
		
	}

}