package com.robotacid.level {
	import com.robotacid.geom.Pixel;
	
	/**
	 * Describes a position on the map that has a supporting surface below it
	 * 
	 * The properties value describes the surface being stood on if a Collider is at map position x,y
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Surface extends Pixel {
		
		public static var map:Vector.<Vector.<Surface>>;
		
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
		}
		
		public static function removeSurface(x:int, y:int):void{
			if(map[y][x]){
				var surface:Surface = map[y][x];
				map[y][x] = null;
				if(surface.room){
					var n:int = surface.room.surfaces.indexOf(surface);
					if(n > -1) surface.room.surfaces.splice(n, 1);
				}
			}
		}
		
	}

}