package com.robotacid.gfx {
	import com.robotacid.dungeon.Map;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	/**
	 * Generates custom FX objects and overlays for certain areas
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class SceneManager {
		
		public static var g:Game;
		public static var renderer:Renderer;
		
		public var mapLevel:int;
		public var mapType:int;
		
		// utilities
		private var i:int;
		private var n:Number;
		private var vx:Number;
		private var vy:Number;
		private var length:Number;
		private var fx:Vector.<FX>;
		private var bitmapData:BitmapData;
		private var matrix:Matrix = new Matrix();
		private var point:Point = new Point();
		
		public static const UNDERWORLD_NOVAS:int = 20;
		public static const UNDERWORLD_NOVA_HEIGHT:int = 9;
		public static const UNDERWORLD_WAVE_HEIGHT:int = 12;
		public static const WAVE_SPEED:Number = 0.5;
		
		public function SceneManager(mapLevel:int, mapType:int) {
			this.mapLevel = mapLevel;
			this.mapType = mapType;
			if(mapLevel == Map.UNDERWORLD && mapType == Map.OUTSIDE_AREA){
				fx = new Vector.<FX>();
				for(i = 0; i < UNDERWORLD_NOVAS; i++){
					fx[i] = renderer.addFX(g.random.range(g.dungeon.width * Game.SCALE), g.random.range(UNDERWORLD_NOVA_HEIGHT * Game.SCALE), renderer.novaBlit);
					fx[i].frame = g.random.rangeInt(renderer.novaBlit.totalFrames);
				}
				var bitmap:Bitmap = new g.library.WaveB()
				bitmapData = bitmap.bitmapData;
				vx = 0;
			}
		}
		
		public function render():void{
			// the underworld requires animation of waves and the constant upkeep of exploding stars in the sky
			if(mapLevel == Map.UNDERWORLD && mapType == Map.OUTSIDE_AREA){
				// maintain nova animations
				var item:FX;
				for(i = fx.length - 1; i > -1; i--){
					item = fx[i];
					if(!item.active) fx[i] = renderer.addFX(g.random.range(g.dungeon.width * Game.SCALE), g.random.range(UNDERWORLD_NOVA_HEIGHT * Game.SCALE), renderer.novaBlit);
				}
				// render the waves
				if(vx < bitmapData.width) vx += WAVE_SPEED;
				else vx = 0;
				point.y = -renderer.bitmap.y + UNDERWORLD_WAVE_HEIGHT * Game.SCALE-bitmapData.height;
				for(point.x = -bitmapData.width + vx; point.x < g.dungeon.width * Game.SCALE; point.x += bitmapData.width){
					renderer.bitmapData.copyPixels(bitmapData, bitmapData.rect, point, null, null, true);
				}
			}
		}
		
		public static function getSceneManager(level:int, type:int):SceneManager{
			if(level == Map.UNDERWORLD && type == Map.OUTSIDE_AREA){
				return new SceneManager(level, type);
			}
			return null;
		}
		
	}

}