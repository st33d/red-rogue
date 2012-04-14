package com.robotacid.level {
	import com.robotacid.geom.Pixel;
	import com.robotacid.phys.Collider;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	
	/**
	 * Describes a position on the map that has a supporting surface below it
	 * 
	 * The properties value describes the surface being stood on if a Collider is at map position x,y
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Surface extends Pixel {
		
		public static var map:Vector.<Vector.<Surface>>;
		public static var surfaces:Vector.<Surface>;
		public static var fragmentationMap:BitmapData;
		public static var entranceCol:uint;
		
		public var properties:int;
		public var room:Room;
		public var nearEntrance:Boolean;
		
		public function Surface(x:int = 0, y:int = 0, properties:int = 0) {
			super(x, y);
			this.properties = properties;
			nearEntrance = false;
		}
		
		public static function initMap(width:int, height:int):void{
			var r:int, c:int, i:int;
			map = new Vector.<Vector.<Surface>>();
			for(r = 0; r < height; r++){
				map.push(new Vector.<Surface>());
				for(c = 0; c < width; c++){
					map[r].push(null);
				}
			}
			surfaces = new Vector.<Surface>();
			fragmentationMap = null;
			entranceCol = 0x0;
		}
		
		public static function removeSurface(x:int, y:int):void{
			if(map[y][x]){
				var n:int;
				var surface:Surface = map[y][x];
				map[y][x] = null;
				n = surfaces.indexOf(surface);
				if(n > -1) surfaces.splice(n, 1);
				if(surface.room){
					n = surface.room.surfaces.indexOf(surface);
					if(n > -1) surface.room.surfaces.splice(n, 1);
				}
			}
		}
		
		public static function getClosestSurface(x:int, y:int):Surface{
			return null;
		}
		
		/* Diagnositic illustration of the AI graph for the map */
		public static function draw(gfx:Graphics, scale:Number, topLeft:Pixel, bottomRight:Pixel):void{
			var r:int, c:int, i:int, surface:Surface;
			for(r = topLeft.y; r <= bottomRight.y; r++){
				for(c = topLeft.x; c <= bottomRight.x; c++){
					if(map[r][c]){
						surface = map[r][c];
						gfx.moveTo(surface.x * scale, (surface.y + 1) * scale);
						gfx.lineTo((surface.x + 1) * scale, (surface.y + 1) * scale);
						
						if(surface.properties == (Collider.SOLID | Collider.WALL)){
							gfx.moveTo(surface.x * scale, 2 + (surface.y + 1) * scale);
							gfx.lineTo((surface.x + 1) * scale, 2 + (surface.y + 1) * scale);
						}
						
						if(surface.room){
							gfx.moveTo(surface.x * scale, 2 + (surface.y + 1) * scale);
							gfx.lineTo(surface.room.x * scale, surface.room.y * scale);
						}
					}
				}
			}
		}
		
	}

}