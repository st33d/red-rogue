package com.robotacid.gfx {
	import com.robotacid.level.Map;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Entity;
	import com.robotacid.engine.Entity;
	import com.robotacid.engine.Explosion;
	import com.robotacid.engine.Player;
	import com.robotacid.util.Bresenham;
	import com.robotacid.util.HiddenInt;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Uses the shadow-casting algorithm to create a lit area around designated objects in the game
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class LightMap {
		
		private var i:int;
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		public var blockMap:Vector.<Vector.<int>>;
		public var rect:Rectangle;
		public var darkImage:BitmapData;
		public var fadeImage:BitmapData;
		public var edgeImage:BitmapData;
		public var entities:Vector.<Entity>;
		public var horizEdge:Rectangle;
		public var vertEdge:Rectangle;
		public var wallRect:Rectangle;
		public var width:int;
		public var height:int;
		
		
		public static const EDGE_COL:uint = 0xFFDDDDDD;
		public static const EDGE_OFFSET:Number = 14;
		
		public static var p:Point = new Point();
		
		// tables
		public var dists:Array;
		public var rSlopes:Array;
		public var lSlopes:Array;
		
		public static const MAX_RADIUS:int = 15;
		
		// Multipliers for transforming coordinates to other octants:
		public static const MULT:Array = [
			[1,  0,  0, -1, -1,  0,  0,  1],
			[0,  1, -1,  0,  0, -1,  1,  0],
			[0,  1,  1,  0,  0, -1, -1,  0],
			[1,  0,  0,  1, -1,  0,  0, -1]
		];
		
		public static const FADE_STEP:uint = 0x44000000;
		public static const THRESHOLD:uint = 0xF1000000;
		public static const WALL_COL:uint = 0xFFFFFFFF;
		public static const MINIMAP_EMPTY_COL:uint = 0x99FFFFFF;
		public static const MINIMAP_REVEAL_COL:uint = 0x99AAAAAA;
		public static const MINIMAP_WALL_COL:uint = 0xDD000000;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		public static const WALL:int = 1 << 11;
		
		public static const SCALE:Number = Game.SCALE;
		public static const INV_SCALE:Number = Game.INV_SCALE;
		
		public function LightMap(blockMap:Vector.<Vector.<int>>) {
			this.blockMap = blockMap;
			width = blockMap[0].length;
			height = blockMap.length;
			rect = new Rectangle(0, 0, game.mapTileManager.tilesWidth + game.mapTileManager.borderX[game.mapTileManager.masterLayer] * 2, game.mapTileManager.tilesHeight + game.mapTileManager.borderY[game.mapTileManager.masterLayer] * 2);
			darkImage = new BitmapData(width, height, true, 0xFF000000);
			fadeImage = new BitmapData(rect.width, rect.height, true, FADE_STEP);
			entities = new Vector.<Entity>();
			getTables(MAX_RADIUS);
			vertEdge = new Rectangle(0, 0, 2, 16);
			horizEdge = new Rectangle(0, 0, 16, 2);
			wallRect = new Rectangle(0, 0, 16, 16);
			edgeImage = renderer.bitmapData;
			renderer.lightBitmap.bitmapData = darkImage;
		}
		
		/* A new collision map from the physics engine is used start the basis for the next level's lighting engine */
		public function newMap(blockMap:Vector.<Vector.<int>>):void{
			entities = new Vector.<Entity>();
			this.blockMap = blockMap;
			width = blockMap[0].length;
			height = blockMap.length;
			rect = new Rectangle(0, 0, game.mapTileManager.tilesWidth + game.mapTileManager.borderX[game.mapTileManager.masterLayer] * 2, game.mapTileManager.tilesHeight + game.mapTileManager.borderY[game.mapTileManager.masterLayer] * 2);
			renderer.lightBitmap.bitmapData = darkImage = new BitmapData(width, height, true, 0xFF000000);
			fadeImage = new BitmapData(rect.width, rect.height, true, FADE_STEP);
		}
		
		public function main():void{
			
			//bitmap.visible = false;
			
			p.x = (game.mapTileManager.scrollTopleftX * INV_SCALE) >> 0;
			p.y = (game.mapTileManager.scrollTopleftY * INV_SCALE) >> 0;
			rect.x = rect.y = 0;
			darkImage.copyPixels(fadeImage, rect, p, null, null, true);
			// flash can't fade to black properly, so we threshold test against the value
			// THRESHOLD and turn that to full black
			rect.x = p.x; rect.y = p.y;
			darkImage.threshold(darkImage, rect, p, ">=", THRESHOLD, 0xff000000);
			var radius:int, entity:Entity;
			for(var i:int = entities.length - 1; i > -1; i--){
				entity = entities[i];
				if(entity.active){
					// skip sleeping characters
					if(entity is Character && (entity as Character).asleep) continue;
					radius = entity.light;
					if(entity.mapX + radius > p.x && entity.mapY + radius > p.y && entity.mapX - radius < p.x + rect.width && entity.mapY - radius < p.y + rect.height){
						light(entity);
					}
				} else {
					entities.splice(i, 1);
				}
			}
		}
		
		/* Blacks out the entire lightmap, used for teleport */
		public function blackOut():void{
			darkImage.fillRect(darkImage.rect, 0xFF000000);
		}
		
		/* Executes the lighting routine on the Entity */
		public function light(entity:Entity):void{
			var updateMinimap:Boolean = entity is Player;
			var radius:int = entity.light > MAX_RADIUS ? MAX_RADIUS : entity.light;
			// run the shadow casting algorithm on the 8 octants it needs to propagate along
			for(i = 0; i < 8; i++){
				castLight(entity.mapX, entity.mapY, 1, 1.0, 0.0, radius, MULT[0][i], MULT[1][i], MULT[2][i], MULT[3][i], entity.lightCols, updateMinimap);
			}
			
			var col:uint = darkImage.getPixel32(entity.mapX, entity.mapY);
			if(col > entity.lightCols[0]){
				col = col >= FADE_STEP ? col - FADE_STEP : 0x0;
				if(col < entity.lightCols[0]) col = entity.lightCols[0];
				darkImage.setPixel32(entity.mapX, entity.mapY, col);
			}
			
			// edge lighting code
			if(entity.mapX > 0 && (blockMap[entity.mapY][entity.mapX - 1] & WALL)){
				vertEdge.x = -renderer.bitmap.x + EDGE_OFFSET + (entity.mapX - 1) * SCALE;
				vertEdge.y = -renderer.bitmap.y + entity.mapY * SCALE;
				edgeImage.fillRect(vertEdge, EDGE_COL);
			}
			if(entity.mapY > 0 && (blockMap[entity.mapY - 1][entity.mapX] & WALL)){
				horizEdge.x = -renderer.bitmap.x + entity.mapX * SCALE;
				horizEdge.y = -renderer.bitmap.y + EDGE_OFFSET + (entity.mapY - 1) * SCALE;
				edgeImage.fillRect(horizEdge, EDGE_COL);
			}
			if(entity.mapX < width - 1 && (blockMap[entity.mapY][entity.mapX + 1] & WALL)){
				vertEdge.x = -renderer.bitmap.x + (entity.mapX + 1) * SCALE;
				vertEdge.y = -renderer.bitmap.y + entity.mapY * SCALE;
				edgeImage.fillRect(vertEdge, EDGE_COL);
			}
			if(entity.mapY < height - 1 && (blockMap[entity.mapY + 1][entity.mapX] & WALL)){
				horizEdge.x = -renderer.bitmap.x + entity.mapX * SCALE;
				horizEdge.y = -renderer.bitmap.y + (entity.mapY + 1) * SCALE;
				edgeImage.fillRect(horizEdge, EDGE_COL);
			}
		}
		/* Recursive shadow casting method - ported from the Python version here:
		 *
		 * http://roguebasin.roguelikedevelopment.org/index.php?title=Python_shadowcasting_implementation
		 *
		 * optimisations include lookup tables, ditching redundant variables and inlining
		 */
		public function castLight(cx:int, cy:int, row:int, start:Number, end:Number, radius:int, xx:int, xy:int, yx:int, yy:int, lightCols:Vector.<uint>, updateMinimap:Boolean):void{
		
			var new_start:Number;
			var dx:int, dy:int;
			var block:Boolean;
			var mapX:int, mapY:int;
			var dist:int;
			var lSlope:Number, rSlope:Number;
			var col:uint;

			if(start < end) return;

			for(var j:int = row; j < radius + 1; j++){
				dx = -j - 1;
				dy = -j;
				block = false;
				while(dx <= 0){
					dx++;
					// Translate the dx, dy coordinates into map coordinates:

					mapX = cx + dx * xx + dy * xy;
					mapY = cy + dx * yx + dy * yy;

					// lSlope and rSlope store the slopes of the left and right
					// extremities of the square we're considering:

					lSlope = lSlopes[MAX_RADIUS + dy][MAX_RADIUS + dx];
					rSlope = rSlopes[MAX_RADIUS + dy][MAX_RADIUS + dx];
					
					if(start < rSlope) continue;

					else if(end > lSlope) break;

					else{
					// Our light beam is touching this square; light it:
						dist = dists[MAX_RADIUS + dx][MAX_RADIUS + dy];
						//if(dx * dx + dy * dy < radiusSquared){
						if(dist < radius){
							// this is where I take over and light my own map
							if(mapX > -1 && mapY > -1 && mapX < width && mapY < height){
								col = darkImage.getPixel32(mapX, mapY);
								if(col > lightCols[dist]){
									col = col >= FADE_STEP ? col - FADE_STEP : 0x0;
									if(col < lightCols[dist]) col = lightCols[dist];
									darkImage.setPixel32(mapX, mapY, col);
									// edge lighting code
									
									if(!(blockMap[mapY][mapX] & WALL)){
										if(mapX > 0 && (blockMap[mapY][mapX - 1] & WALL)){
											vertEdge.x = -renderer.bitmap.x + EDGE_OFFSET + (mapX - 1) * SCALE;
											vertEdge.y = -renderer.bitmap.y + mapY * SCALE;
											edgeImage.fillRect(vertEdge, EDGE_COL - col);
										}
										if(mapY > 0 && (blockMap[mapY - 1][mapX] & WALL)){
											horizEdge.x = -renderer.bitmap.x + mapX * SCALE;
											horizEdge.y = -renderer.bitmap.y + EDGE_OFFSET + (mapY - 1) * SCALE;
											edgeImage.fillRect(horizEdge, EDGE_COL - col);
										}
										if(mapX < width - 1 && (blockMap[mapY][mapX + 1] & WALL)){
											vertEdge.x = -renderer.bitmap.x + (mapX + 1) * SCALE;
											vertEdge.y = -renderer.bitmap.y + mapY * SCALE;
											edgeImage.fillRect(vertEdge, EDGE_COL - col);
										}
										if(mapY < height - 1 && (blockMap[mapY + 1][mapX] & WALL)){
											horizEdge.x = -renderer.bitmap.x + mapX * SCALE;
											horizEdge.y = -renderer.bitmap.y + (mapY + 1) * SCALE;
											edgeImage.fillRect(horizEdge, EDGE_COL - col);
										}
									}
									
									if(updateMinimap){
										if(!(blockMap[mapY][mapX] & WALL)) game.miniMap.bitmapData.setPixel32(mapX, mapY, MINIMAP_EMPTY_COL);
										else if(blockMap[mapY][mapX] & WALL) game.miniMap.bitmapData.setPixel32(mapX, mapY, MINIMAP_WALL_COL);
									}
								}
								
							}
						}
						if(block){
							// we're scanning a row of blocked squares:
							if(mapX < 0 || mapY < 0 || mapX >= width || mapY >= height || (blockMap[mapY][mapX] & WALL)){
								new_start = rSlope;
								continue;
							} else{
								block = false;
								start = new_start;
							}
						} else {
							if((mapX < 0 || mapY < 0 || mapX >= width || mapY >= height || (blockMap[mapY][mapX] & WALL)) && j < radius){
								// This is a blocking square, start a child scan:
								block = true;
								castLight(cx, cy, j+1, start, lSlope, radius, xx, xy, yx, yy, lightCols, updateMinimap)
								new_start = rSlope;
							}
						}
					}
				}
				// Row is scanned; do next row unless last square was blocked:
				if (block) break;
			}
		}
		
		/* Add an Entity to the lighting queue */
		public function setLight(entity:Entity, radius:int, strength:int = 255):void{
			
			entity.light = radius < 0 ? 0 : radius;
			
			// check if this object is already in the queue
			var n:int = entities.indexOf(entity);
			if(n > -1){
				if(radius <= 0){
					entities.splice(n, 1);
				}
			} else {
				entities.push(entity);
			}
			
			if(radius <= 0) return;
			
			var temp_radius:int = radius > MAX_RADIUS ? MAX_RADIUS : radius;
			var step:int = Number(strength) / temp_radius;
			entity.lightCols = new Vector.<uint>(temp_radius + 1);
			var col:uint = 0xFF000000;
			var prevCol:uint = col;
			for(var i:int = temp_radius + 1; i > -1; i--, col -= 0x01000000 * step){
				if(prevCol < col) col = 0x0;
				entity.lightCols[i] = col;
				prevCol = col;
			}
			entity.lightCols[0] = 0xFF000000 - (0x01000000 * strength);
		}
		
		/* Create look up tables */
		public function getTables(radius:int):void{
			dists = Map.createGrid(0, 1 + radius * 2, 1 + radius * 2);
			rSlopes = Map.createGrid(0, 1 + radius * 2, 1 + radius * 2);
			lSlopes = Map.createGrid(0, 1 + radius * 2, 1 + radius * 2);
			var r:int, c:int, vx:Number, vy:Number;
			for(r = 0; r < 1 + radius * 2; r++){
				for(c = 0; c < 1 + radius * 2; c++){
					vx = c - radius;
					vy = r - radius;
					dists[r][c] = Math.sqrt(vx * vx + vy * vy) >> 0;
				}
			}
			for(r = 0; r < 1 + radius * 2; r++){
				for(c = 0; c < 1 + radius * 2; c++){
					vx = c - radius;
					vy = r - radius;
					lSlopes[r][c] = (vx - 0.5) / (vy + 0.5);
					rSlopes[r][c] = (vx + 0.5) / (vy - 0.5);
				}
			}
		}
		
	}
	
}