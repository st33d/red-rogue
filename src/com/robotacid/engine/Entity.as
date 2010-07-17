package com.robotacid.engine {
	import com.robotacid.geom.Dot;
	import com.robotacid.geom.Rect;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class Entity extends Dot{
		
		public var mc:DisplayObject;
		public var g:Game;
		public var active:Boolean;
		public var callMain:Boolean;
		public var collision:Boolean;
		public var rect:Rect;
		
		public var name:int;
		public var light:int;
		public var lightCols:Vector.<uint>;
		public var tileId:String;
		public var free:Boolean = false;
		public var mapX:int, mapY:int;
		public var initX:int, initY:int;
		public var layer:int;
		
		public var holder:DisplayObjectContainer;
		
		// these are debug tools for differentiating between objects and their instantiation order
		public static var objectCount:int = 0;
		public var objectNum:int;
		
		public static const SCALE:Number = Game.SCALE;
		public static const INV_SCALE:Number = Game.INV_SCALE;
		
		public function Entity(mc:DisplayObject, g:Game, free:Boolean = false, active:Boolean = true) {
			super(mc.x, mc.y);
			this.mc = mc;
			this.g = g;
			this.free = free;
			this.active = active;
			collision = false;
			callMain = false;
			light = 0;
			mapX = x * INV_SCALE;
			mapY = y * INV_SCALE;
			objectNum = objectCount++;
			if(active) g.entities.push(this);
			
		}
		
		public function main():void{
			
		}
		
		public function intersects(rect:Rect):Boolean{
			return this.rect.intersects(rect);
		}
		
		public function contains(x:Number, y:Number):Boolean {
			return rect.contains(x, y);
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
				if(g.renderer.mapArrayLayers[layer][mapY][mapX]){
					if(g.renderer.mapArrayLayers[layer][mapY][mapX] is Array){
						g.renderer.mapArrayLayers[layer][mapY][mapX].push(this);
					} else {
						g.renderer.mapArrayLayers[layer][mapY][mapX] = [g.renderer.mapArrayLayers[layer][mapY][mapX], this];
					}
				} else g.renderer.mapArrayLayers[layer][mapY][mapX] = this;
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