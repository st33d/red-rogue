package com.robotacid.gfx {
	import com.robotacid.engine.Portal;
	import com.robotacid.level.Map;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * Generates custom FX objects and overlays for certain areas
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class SceneManager {
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		public var mapLevel:int;
		public var mapType:int;
		public var mapZone:int;
		
		// utilities
		private var i:int;
		private var n:Number;
		private var vx:Number;
		private var vy:Number;
		private var length:Number;
		private var fx:Vector.<FX>;
		private var automata:Vector.<ChaosAutomata>;
		private var bitmapData:BitmapData;
		private var matrix:Matrix = new Matrix();
		private var point:Point = new Point();
		private var auto:ChaosAutomata;
		
		public static const UNDERWORLD_NOVAS:int = 20;
		public static const UNDERWORLD_NOVA_HEIGHT:int = 9;
		public static const UNDERWORLD_WAVE_HEIGHT:int = 12;
		public static const WAVE_SPEED:Number = 0.5;
		public static const STAR_SOUNDS:Array = ["star1", "star2", "star3", "star4"];
		
		public function SceneManager(mapLevel:int, mapType:int) {
			this.mapLevel = mapLevel;
			this.mapType = mapType;
			mapZone = game.content.getLevelZone(mapLevel);
			if(mapLevel == Map.UNDERWORLD && mapType == Map.AREA){
				fx = new Vector.<FX>();
				for(i = 0; i < UNDERWORLD_NOVAS; i++){
					fx[i] = new FX(game.random.range(game.map.width * Game.SCALE), game.random.range(UNDERWORLD_NOVA_HEIGHT * Game.SCALE), renderer.novaBlit, renderer.bitmapData, renderer.bitmap);
					fx[i].frame = game.random.rangeInt(renderer.novaBlit.totalFrames);
				}
				var bitmap:Bitmap = new game.library.WaveB()
				bitmapData = bitmap.bitmapData;
				vx = 0;
				
			} else if(mapZone == Map.CHAOS){
				ChaosAutomata.pixels = renderer.backgroundBitmapData.getVector(renderer.backgroundBitmapData.rect);
				automata = new Vector.<ChaosAutomata>();
				for(i = 0; i < 30; i++){
					automata.push(new ChaosAutomata(i < 15));
				}
			}
			
		}
		
		public function renderBackground():void{
			if(mapLevel == Map.UNDERWORLD && mapType == Map.AREA){
				// the underworld requires the constant upkeep of exploding stars in the sky
				var item:FX;
				for(i = fx.length - 1; i > -1; i--){
					item = fx[i];
					if(!item.active) fx[i] = new FX(game.random.range(game.map.width * Game.SCALE), game.random.range(UNDERWORLD_NOVA_HEIGHT * Game.SCALE), renderer.novaBlit, renderer.bitmapData, renderer.bitmap);
					else{
						item.main();
						if(item.frame == item.blit.totalFrames) game.soundQueue.addRandom("star", STAR_SOUNDS);
					}
				}
			} else if(mapZone == Map.CHAOS){
				for(i = 0; i < automata.length; i++){
					auto = automata[i];
					auto.main();
				}
				renderer.backgroundBitmapData.setVector(renderer.backgroundBitmapData.rect, ChaosAutomata.pixels);
			}
		}
		
		public function renderForeground():void{
			if(mapLevel == Map.UNDERWORLD && mapType == Map.AREA){
				// the underworld requires animation of waves
				if(vx < bitmapData.width) vx += WAVE_SPEED;
				else vx = 0;
				point.y = -renderer.bitmap.y + UNDERWORLD_WAVE_HEIGHT * Game.SCALE-bitmapData.height;
				for(point.x = -bitmapData.width + vx; point.x < game.map.width * Game.SCALE; point.x += bitmapData.width){
					renderer.bitmapData.copyPixels(bitmapData, bitmapData.rect, point, null, null, true);
				}
				
			} else if(mapLevel == Map.OVERWORLD && mapType == Map.AREA){
				
				// not sure I want to keep the following effect because the underworld is also an item warehouse
				
				// the overworld requires an effect over portals to imply the time loop spell
				/*if(game.portals.length){
					var portal:Portal;
					for(i = 0; i < game.portals.length; i++){
						portal = game.portals[i];
						renderer.createSparkRect(new Rectangle(portal.rect.x, portal.rect.y, portal.rect.width, portal.rect.height), 2, 0, -1);
					}
				}*/
			}
		}
		
		public static function getSceneManager(level:int, type:int):SceneManager{
			if(type == Map.AREA){
				return new SceneManager(level, type);
			} else if(type == Map.MAIN_DUNGEON || type == Map.ITEM_DUNGEON){
				// account for being in the test bed
				if(level == -1){
					level = game.gameMenu.editorList.dungeonLevelList.selection
				}
				var zone:int = game.content.getLevelZone(level);
				if(zone == Map.CHAOS){
					return new SceneManager(level, type);
				}
			}
			return null;
		}
		
	}

}