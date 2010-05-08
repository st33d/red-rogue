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
		public var call_main:Boolean;
		public var collision:Boolean;
		public var rect:Rect;
		
		public var name:int;
		public var light:int;
		public var light_cols:Vector.<uint>;
		public var tile_id:String;
		public var free:Boolean = false;
		public var map_x:int, map_y:int;
		public var init_x:int, init_y:int;
		public var layer:int;
		public var id_tag:int = -1;
		
		public var holder:DisplayObjectContainer;
		
		// these are debug tools for differentiating between objects and their instantiation order
		public static var object_count:int = 0;
		public var object_num:int;
		
		public static const SCALE:Number = Game.SCALE;
		public static const INV_SCALE:Number = Game.INV_SCALE;
		
		public function Entity(mc:DisplayObject, g:Game, free:Boolean = false, active:Boolean = true) {
			super(mc.x, mc.y);
			this.mc = mc;
			this.g = g;
			this.free = free;
			this.active = active;
			collision = false;
			call_main = false;
			light = 0;
			map_x = x * INV_SCALE;
			map_y = y * INV_SCALE;
			object_num = object_count++;
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
				if(g.renderer.map_array_layers[layer][map_y][map_x]){
					if(g.renderer.map_array_layers[layer][map_y][map_x] is Array){
						g.renderer.map_array_layers[layer][map_y][map_x].push(this);
					} else {
						g.renderer.map_array_layers[layer][map_y][map_x] = [g.renderer.map_array_layers[layer][map_y][map_x], this];
					}
				} else g.renderer.map_array_layers[layer][map_y][map_x] = this;
			}
		}
		
		public function nameToString():String{
			return "none";
		}
		
	}

}