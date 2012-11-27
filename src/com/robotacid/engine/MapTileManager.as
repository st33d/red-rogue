package com.robotacid.engine {
	import com.robotacid.geom.Pixel;
	import com.robotacid.gfx.BlitRect;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	/**
	* Keeps the game content limited to a window surrounding the available view
	* Also converts item indices to objects with the aid of the MapTileConverter
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class MapTileManager {
		
		public var converter:MapTileConverter;
		
		public var mapRect:Rectangle;
		
		// lists
		public var map:Array;
		public var mapLayers:Array;
		public var activeMap:Array;
		public var activeMapLayers:Array;
		public var mapRowsIndex:Vector.<int>;
		public var mapRowsIndexLayers:Vector.<Vector.<int>>;
		public var mapColsIndex:Vector.<int>;
		public var mapColsIndexLayers:Vector.<Vector.<int>>;
		public var borderX:Vector.<int>;
		public var borderY:Vector.<int>;
		public var updateLayer:Vector.<Boolean>;
		public var bitmapLayers:Vector.<Boolean>;
		public var topLeftLayers:Vector.<Pixel>;
		public var bottomRightLayers:Vector.<Pixel>;
		
		// states
		public var layers:int;
		public var currentLayer:int;
		public var bitmapLayer:Boolean;
		public var canvas:Sprite;
		public var scrollX:Boolean;
		public var scrollY:Boolean;
		public var scale:Number;
		public var width:int;
		public var height:int;
		public var viewWidth:Number;
		public var viewHeight:Number;
		public var tilesWidth:int;
		public var tilesHeight:int;
		public var lastCanvasMapX:int;
		public var lastCanvasMapY:int;
		public var scrollTopleftX:int;
		public var scrollTopleftY:int;
		public var scrollBottomrightX:int;
		public var scrollBottomrightY:int;
		public var masterLayer:int;
		public var invScale:Number;
		public var topLeft:Pixel;
		public var bottomRight:Pixel;
		
		private var tempArray:Array;
		private var n:int;
		
		public static const BACKGROUND_LAYER:int = 0;
		public static const BLOCK_LAYER:int = 1;
		public static const ENTITY_LAYER:int = 2;
		
		public static const TOTAL_LAYERS:int = 3;
		
		public function MapTileManager(game:Game, canvas:Sprite, scale:Number, width:int, height:int, viewWidth:Number, viewHeight:Number){
			this.canvas = canvas;
			this.scale = scale;
			invScale = 1.0 / scale;
			this.width = width;
			this.height = height;
			this.viewWidth = viewWidth;
			this.viewHeight = viewHeight;
			converter = new MapTileConverter(this, game, Game.renderer);
			scrollX = true;
			scrollY = true;
			setBorder([0, 0, 3], [0, 0, 3]);
			tilesWidth = Math.ceil(viewWidth * invScale);
			tilesHeight = Math.ceil(viewHeight * invScale);
			mapLayers = [];
			activeMapLayers = [];
			mapRowsIndexLayers = new Vector.<Vector.<int>>(TOTAL_LAYERS, true);
			mapColsIndexLayers = new Vector.<Vector.<int>>(TOTAL_LAYERS, true);
			updateLayer = new Vector.<Boolean>(TOTAL_LAYERS, true);
			bitmapLayers = new Vector.<Boolean>(TOTAL_LAYERS, true);
			topLeftLayers = new Vector.<Pixel>(TOTAL_LAYERS, true);
			bottomRightLayers = new Vector.<Pixel>(TOTAL_LAYERS, true);
			currentLayer = 0;
			layers = 0;
			masterLayer = ENTITY_LAYER;
			scrollTopleftX = 0;
			scrollTopleftY = 0;
			scrollBottomrightX = 0;
			scrollBottomrightY = 0;
			mapRect = new Rectangle(0, 0, width * scale, height * scale);
		}
		
		/* Sets the extension of the active elements around the viewport
		 *
		 * Some elements may require some distance away from the viewport before they get yanked
		 */
		public function setBorder(xLayers:Array, yLayers:Array):void{
			var i:int;
			borderX = new Vector.<int>(xLayers.length, true);
			borderY = new Vector.<int>(yLayers.length, true);
			for(i = 0; i < xLayers.length; i++){
				borderX[i] = xLayers[i];
			}
			for(i = 0; i < yLayers.length; i++){
				borderY[i] = yLayers[i];
			}
		}
		
		/* Initialises the properties for layers and loads in a pre-prepared map */
		public function setLayers(mapLayers:Array):void{
			this.mapLayers = mapLayers;
			for(var i:int = 0; i < TOTAL_LAYERS; i++){
				activeMapLayers[i] = [];
				topLeftLayers[i] = new Pixel();
				bottomRightLayers[i] = new Pixel();
				updateLayer[i] = true;
				bitmapLayers[i] = false;
			}
			layers = mapLayers.length;
		}
		
		/* Sets up the manager for a new map, resizing it and flushing the arrays that
		 * help the rendering */
		public function newMap(width:int, height:int, newMapArrayLayers:Array):void{
			mapLayers = newMapArrayLayers;
			this.width = width;
			this.height = height;
			mapRect = new Rectangle(0, 0, width * scale, height * scale);
		}
		
		/* Change the layer the scroller is operating on */
		public function changeLayer(n:int):void{
			map = mapLayers[n];
			activeMap = activeMapLayers[n];
			mapRowsIndex = mapRowsIndexLayers[n];
			mapColsIndex = mapColsIndexLayers[n];
			topLeft = topLeftLayers[n];
			bottomRight = bottomRightLayers[n];
			bitmapLayer = bitmapLayers[n];
			currentLayer = n;
		}
		
		/* Renders layer n to a BitmapData, then sets that layer to no longer update */
		public function layerToBitmapData(n:int, bitmapData:BitmapData = null):BitmapData{
			bitmapLayers[n] = true;
			changeLayer(n);
			if(!bitmapData){
				var pixelWidth:int = width * scale;
				var pixelHeight:int = height * scale;
				bitmapData = new BitmapData(pixelWidth, pixelHeight, true, 0x0);
			}
			var r:int, c:int, item:BlitRect;
			for(r = 0; r < height; r++) {
				for(c = 0; c < width; c++) {
					item = converter.createTile(c, r) as BlitRect;
					if(item){
						item.x = c * scale;
						item.y = r * scale;
						item.render(bitmapData);
					}
				}
			}
			updateLayer[n] = false;
			return bitmapData;
		}
		
		/* Turn on / off scrolling behaviour on a layer */
		public function setLayerUpdate(n:int, value:Boolean):void{
			updateLayer[n] = value;
		}
		
		/* Draw the edge of the scroll border and the stage edge */
		public function draw(gfx:Graphics):void{
			gfx.moveTo(scrollTopleftX, scrollTopleftY);
			gfx.lineTo(scrollBottomrightX, scrollTopleftY);
			gfx.lineTo(scrollBottomrightX, scrollBottomrightY);
			gfx.lineTo(scrollTopleftX, scrollBottomrightY);
			gfx.lineTo(scrollTopleftX, scrollTopleftY);
			gfx.moveTo( -canvas.x, -canvas.y);
			gfx.lineTo( -canvas.x + viewWidth, -canvas.y);
			gfx.lineTo( -canvas.x + viewWidth, -canvas.y + viewHeight);
			gfx.lineTo( -canvas.x, -canvas.y + viewHeight);
			gfx.lineTo( -canvas.x, -canvas.y);
		}
		
		/* Return true if a point is inside the edge of the scrolling area */
		public function contains(x:Number, y:Number):Boolean{
			return x < scrollBottomrightX && x >= scrollTopleftX && y < scrollBottomrightY && y >= scrollTopleftY;
		}
		
		/* Return true if a tile position is inside the edge of the scrolling area */
		public function containsTile(x:int, y:int, layer:int):Boolean{
			return x >= topLeftLayers[layer].x && y >= topLeftLayers[layer].y && x < bottomRightLayers[layer].x && y < bottomRightLayers[layer].y;
		}
		
		/* Return true if a rect intersects the scrolling area
		 * 
		 * - note the slight aggression on keeping within the open interval, leaving this in for now */
		public function intersects(b:Rectangle, border:Number = 0):Boolean{
			return !(scrollTopleftX - border > b.x + (b.width - 1) || scrollBottomrightX - 1 + border < b.x || scrollTopleftY - border > b.y + (b.height - 1) || scrollBottomrightY - 1 + border < b.y);
		}
		
		/* Reset the lastCanvasMapX and lastCanvasMapY to indicate no scroll should occur */
		public function reset():void{
			lastCanvasMapX = (canvas.x * invScale) >> 0;
			lastCanvasMapY = (canvas.y * invScale) >> 0;
		}
		
		/* Paint the initial view when a level starts and initialise the scrolling arrays */
		public function init(x:int, y:int):void{
			
			var halfTilesWidth:int = Math.round(tilesWidth*0.5);
			var halfTilesHeight:int = Math.round(tilesHeight*0.5);
			canvas.x = -((x - halfTilesWidth) * scale);
			canvas.y = -((y - halfTilesHeight) * scale);
			lastCanvasMapX = (canvas.x / scale) >> 0;
			lastCanvasMapY = (canvas.y / scale) >> 0;
			
			var rezLeft:int = x - halfTilesWidth - borderX[masterLayer] * 2;
			var rezTop:int = y - halfTilesHeight - borderY[masterLayer] * 2;
			var rezRight:int = rezLeft + tilesWidth + borderX[masterLayer] * 4;
			var rezBottom:int = rezTop + tilesHeight + borderY[masterLayer] * 4;
			if(rezLeft < 0) rezLeft = 0;
			if(rezTop < 0) rezTop = 0;
			if(rezRight > width) rezRight = width;
			if(rezBottom > height) rezBottom = height;
			
			scrollTopleftX = rezLeft * scale;
			scrollTopleftY = rezTop * scale;
			scrollBottomrightX = rezRight * scale;
			scrollBottomrightY = rezBottom * scale;
			
			activeMapLayers = [];
			mapRowsIndexLayers = new Vector.<Vector.<int>>(TOTAL_LAYERS, true);
			mapColsIndexLayers = new Vector.<Vector.<int>>(TOTAL_LAYERS, true);
			
			var c:int, r:int;
			for(var i:int = 0; i < layers; i++){
				topLeftLayers[i] = new Pixel(rezLeft, rezTop);
				bottomRightLayers[i] = new Pixel(rezRight, rezBottom);
				activeMapLayers[i] = [];
				mapRowsIndexLayers[i] = new Vector.<int>();
				mapColsIndexLayers[i] = new Vector.<int>();
				changeLayer(i);
				if(updateLayer[i]){
					for(c = rezLeft; c < rezRight; c++){
						mapColsIndex.push(c);
					}
					for(r = rezTop; r < rezBottom; r++){
						pushRow(r);
					}
				}
			}
		}
		
		/* iterate through the map and generate ALL tiles */
		public function createAll():void {
			for(var i:int = 0; i < layers; i++) {
				changeLayer(i);
				for(var r:int = 0; r < height; r++) {
					for(var c:int = 0; c < width; c++) {
						converter.createTile(c, r);
					}
				}
			}
		}
		
		/* Get the tile at a given position, whether it is in the activeMap or the map */
		public function getTile(x:int, y:int, layer:int):*{
			if(x < 0 || y < 0 || x >= width || y >= height) return null;
			if(x < topLeftLayers[layer].x || y < topLeftLayers[layer].y || x >= bottomRightLayers[layer].x || y >= bottomRightLayers[layer].y){
				return mapLayers[layer][y][x];
			} else {
				return activeMapLayers[layer][y - topLeftLayers[layer].y][x - topLeftLayers[layer].x];
			}
		}
		
		/* Add an object to the MapTileManager */
		public function addTile(tile:*, x:int, y:int, layer:int):void{
			changeLayer(layer);
			if(x < topLeft.x || y < topLeft.y || x >= bottomRight.x || y >= bottomRight.y){
				if(map[y][x]){
					if(map[y][x] is Array){
						map[y][x].push(tile);
					} else {
						map[y][x] = [map[y][x], tile];
					}
				} else map[y][x] = tile;
			} else {
				// target rendered array
				x -= topLeft.x;
				y -= topLeft.y;
				// stacked?
				if(activeMap[y][x]){
					if(activeMap[y][x] is Array){
						activeMap[y][x].push(tile);
					} else {
						activeMap[y][x] = [activeMap[y][x], tile];
					}
				} else activeMap[y][x] = tile;
			}
		}
		
		/* Remove an object from the MapTileManager */
		public function removeTile(tile:*, x:int, y:int, layer:int):void{
			var i:int;
			changeLayer(layer);
			if(x < topLeft.x || y < topLeft.y || x >= bottomRight.x || y >= bottomRight.y){
				// stacked?
				if(map[y][x]){
					if(map[y][x] is Array){
						i = map[y][x].indexOf(tile);
						if(i > -1){
							map[y][x].splice(i, 1);
							if(map[y][x].length == 0) map[y][x] = null;
						}
					} else {
						if(map[y][x] == tile) map[y][x] = null;
					}
				}
			} else {
				// target rendered array
				x -= topLeft.x;
				y -= topLeft.y;
				// stacked?
				if(activeMap[y][x]){
					if(activeMap[y][x] is Array){
						i = activeMap[y][x].indexOf(tile);
						if(i > -1){
							activeMap[y][x].splice(i, 1);
							if(activeMap[y][x].length == 0) activeMap[y][x] = null;
						}
					} else {
						if(activeMap[y][x] == tile) activeMap[y][x] = null;
					}
				}
			}
		}
		
		/* Takes care of the active area of content in the game
		 * The edge of rendered area is defined by the arrays borderX and borderY
		 * Some layers will obviously need to expand further beyond the view port to preserve the illusion
		 */
		public function main():void{
			var canvasMapX:int = (canvas.x * invScale) >> 0;
			var canvasMapY:int = (canvas.y * invScale) >> 0;
			var diff:int;
			for(var i:int = 0; i < layers; i++) {
				changeLayer(i);
				if(updateLayer[i]){
					if(scrollX){
						// scroll left - adding to the left, destroying on the right, canvas moving right
						if(canvasMapX > lastCanvasMapX){
							if(mapColsIndex[0] > 0 && mapColsIndex[0] > -canvasMapX - borderX[i]){
								diff = mapColsIndex[0] - ( -canvasMapX - borderX[i]);
								while(diff > 0){
									unshiftCol(mapColsIndex[0]-1);
									
									if(i == masterLayer){
										scrollTopleftX -= scale;
									}
									topLeft.x--;
									
									--diff;
									if(mapColsIndex[0] == 0) break;
								}
							}
							if(mapColsIndex[mapColsIndex.length-1] > -canvasMapX + tilesWidth + borderX[i]){
								diff = mapColsIndex[mapColsIndex.length - 1] - (-canvasMapX + tilesWidth + borderX[i]);;
								while(diff > 0){
									popCol();
									
									if(i == masterLayer){
										scrollBottomrightX -= scale;
									}
									bottomRight.x--;
									
									--diff;
								}
							}
						}
						// scroll right - adding to the right, destroying on the left, canvas moving left
						if(canvasMapX < lastCanvasMapX){
							if(mapColsIndex[mapColsIndex.length-1] < width-1 && mapColsIndex[mapColsIndex.length-1] < -canvasMapX + tilesWidth + borderX[i]){
								diff = (-canvasMapX + tilesWidth + borderX[i]) - mapColsIndex[mapColsIndex.length-1];
								while(diff > 0){
									pushCol(mapColsIndex[mapColsIndex.length - 1] + 1);
									
									if(i == masterLayer){
										scrollBottomrightX += scale;
									}
									bottomRight.x++;
									
									--diff;
									if(mapColsIndex[mapColsIndex.length - 1] == width - 1) break;
								}
							}
							if(mapColsIndex[0] < -canvasMapX - borderX[i]){
								diff = ( -canvasMapX - borderX[i]) - mapColsIndex[0];
								while(diff > 0){
									shiftCol();
									
									if(i == masterLayer){
										scrollTopleftX += scale;
									}
									topLeft.x++;
									
									--diff;
								}
							}
						}
					}
					if(scrollY){
						// scroll up - adding above, destroying below, canvas moving down
						if(canvasMapY > lastCanvasMapY){
							if(mapRowsIndex[0] > 0 && mapRowsIndex[0] > -canvasMapY - borderY[i]){
								diff = mapRowsIndex[0] - ( -canvasMapY - borderY[i]);
								while(diff > 0){
									unshiftRow(mapRowsIndex[0]-1);
									
									if(i == masterLayer){
										scrollTopleftY -= scale;
									}
									topLeft.y--;
									
									--diff;
									if(mapRowsIndex[0] == 0) break;
								}
							}
							if(mapRowsIndex[mapRowsIndex.length-1] > -canvasMapY + tilesHeight + borderY[i]){
								diff = mapRowsIndex[mapRowsIndex.length - 1] - (-canvasMapY + tilesHeight + borderY[i]);;
								while(diff > 0){
									popRow();
									
									if(i == masterLayer){
										scrollBottomrightY -= scale;
									}
									bottomRight.y--;
									
									--diff;
								}
							}
						}
						// scroll down - adding below, destroying above, canvas moving up
						if(canvasMapY < lastCanvasMapY){
							if(mapRowsIndex[mapRowsIndex.length-1] < height-1 && mapRowsIndex[mapRowsIndex.length-1] < -canvasMapY + tilesHeight + borderY[i]){
								diff = (-canvasMapY + tilesHeight + borderY[i]) - mapRowsIndex[mapRowsIndex.length-1];
								while(diff > 0){
									pushRow(mapRowsIndex[mapRowsIndex.length-1]+1);
									
									if(i == masterLayer){
										scrollBottomrightY += scale;
									}
									bottomRight.y++;
									
									--diff;
									if(mapRowsIndex[mapRowsIndex.length - 1] == height - 1) break;
								}
							}
							if(mapRowsIndex[0] < -canvasMapY - borderY[i]){
								diff = ( -canvasMapY - borderY[i]) - mapRowsIndex[0];
								while(diff > 0){
									shiftRow();
									
									if(i == masterLayer){
										scrollTopleftY += scale;
									}
									topLeft.y++;
									
									--diff;
								}
							}
						}
					}
				}
			}
			lastCanvasMapX = canvasMapX;
			lastCanvasMapY = canvasMapY;
		}
		// LEFT RIGHT PUSHER POPPERS =========================================================
		
		/* Add a column of content left of view */
		protected function pushCol(x:Number):void{
			mapColsIndex.push(x);
			for(var y:int = 0; y < mapRowsIndex.length; y++){
				activeMap[y].push(converter.createTile(x, y + mapRowsIndex[0]));
			}
		}
		/* Add a column of content right of the view */
		protected function unshiftCol(x:Number):void{
			mapColsIndex.unshift(x);
			for(var y:int = 0; y < mapRowsIndex.length; y++){
				activeMap[y].unshift(converter.createTile(x, y + mapRowsIndex[0]));
			}
		}
		/* Remove a column of content left of the view */
		protected function popCol():void{
			for(var y:int = 0; y < mapRowsIndex.length; y++){
				if(activeMap[y][mapColsIndex.length - 1]) {
					// is this a stack of objects to remove?
					if(activeMap[y][mapColsIndex.length - 1] is Array){
						tempArray = activeMap[y][mapColsIndex.length - 1];
						for(n = 0; n < tempArray.length; n++){
							tempArray[n].remove();
						}
					}
					else activeMap[y][mapColsIndex.length - 1].remove();
				}
				activeMap[y].pop();
			}
			mapColsIndex.pop();
		}
		/* Remove a column of content right of the view */
		protected function shiftCol():void{
			for(var y:int = 0; y < mapRowsIndex.length; y++){
				if(activeMap[y][0] != null) {
					// is this a stack of objects to remove?
					if(activeMap[y][0] is Array){
						tempArray = activeMap[y][0];
						for(n = 0; n < tempArray.length; n++){
							tempArray[n].remove();
						}
					}
					else activeMap[y][0].remove();
				}
				activeMap[y].shift();
			}
			mapColsIndex.shift();
		}
		// UP DOWN PUSHER POPPERS =========================================================
		
		/* Add a row of content to the bottom of the view */
		protected function pushRow(y:int):void{
			activeMap.push([]);
			mapRowsIndex.push(y);
			for(var x:int = 0; x < mapColsIndex.length; x++){
				activeMap[activeMap.length-1].push(converter.createTile(x + mapColsIndex[0], y));
			}
		}
		/* Add a row of content to the top of the view */
		protected function unshiftRow(y:int):void{
			activeMap.unshift([]);
			mapRowsIndex.unshift(y);
			for(var x:int = 0; x < mapColsIndex.length; x++){
				activeMap[0].push(converter.createTile(x + mapColsIndex[0], y));
			}
		}
		/* Remove a row of content from below the view */
		protected function popRow():void{
			for(var x:int = 0; x < mapColsIndex.length; x++){
				if(activeMap[activeMap.length - 1][x] != null) {
					// is this a stack of objects to remove?
					if(activeMap[activeMap.length - 1][x] is Array){
						tempArray = activeMap[activeMap.length - 1][x];
						for(n = 0; n < tempArray.length; n++){
							tempArray[n].remove();
						}
					}
					else activeMap[activeMap.length - 1][x].remove();
				}
			}
			activeMap.pop();
			mapRowsIndex.pop();
		}
		/* Remove a row of content from above the view */
		protected function shiftRow():void{
			for(var x:int = 0; x < mapColsIndex.length; x++){
				if(activeMap[0][x] != null) {
					// is this a stack of objects to remove?
					if(activeMap[0][x] is Array){
						tempArray = activeMap[0][x];
						for(n = 0; n < tempArray.length; n++){
							tempArray[n].remove();
						}
					}
					else activeMap[0][x].remove();
				}
			}
			activeMap.shift();
			mapRowsIndex.shift();
		}
	}
	
}