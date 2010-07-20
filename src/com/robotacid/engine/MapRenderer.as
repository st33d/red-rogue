package com.robotacid.engine {
	import com.robotacid.geom.Pixel;
	import com.robotacid.geom.Rect;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	
	/**
	* Keeps the game content limited to a window surrounding the available view,
	* and conserves memory by converting map elements from numbers to objects and back
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class MapRenderer {
		
		public var converter:MapTileConverter;
		public var mapArray:Array;
		public var mapArrayLayers:Array;
		public var renderedArray:Array;
		public var renderedArrayLayers:Array;
		public var mapRowsIndex:Vector.<int>;
		public var mapRowsIndexLayers:Vector.<Vector.<int>>;
		public var mapColsIndex:Vector.<int>;
		public var mapColsIndexLayers:Vector.<Vector.<int>>;
		public var tileLayers:Array;
		public var tileLayers_behind:Array;
		public var signage:Array;
		public var tiles:Sprite;
		public var tileHolder:Sprite;
		public var layers:int;
		public var currentLayer:int;
		public var stage:Sprite;
		public var scrollX:Boolean;
		public var scrollY:Boolean;
		public var image:BitmapData;
		public var imageHolder:Bitmap;
		public var imageLayers:Vector.<BitmapData>;
		public var imageHolderLayers:Vector.<Bitmap>;
		public var scale:Number;
		public var width:int;
		public var height:int;
		public var stageWidth:int;
		public var stageHeight:int;
		public var borderX:Vector.<int>;
		public var borderY:Vector.<int>;
		public var tilesWidth:int;
		public var tilesHeight:int;
		public var lastStageX:int;
		public var lastStageY:int;
		public var updateLayer:Vector.<Boolean>;
		public var scrollTopleftX:int;
		public var scrollTopleftY:int;
		public var scrollBottomrightX:int;
		public var scrollBottomrightY:int;
		public var masterLayer:int;
		public var mapRect:Rect;
		public var SCALE:Number;
		
		public var topLeft:Pixel;
		public var topLeftLayers:Vector.<Pixel>;
		public var bottomRight:Pixel;
		public var bottomRightLayers:Vector.<Pixel>;
		
		private var tempArray:Array;
		private var n:int;
		
		public static const BLOCK_LAYER:int = 1;
		public static const GAME_OBJECT_LAYER:int = 2;
		public static const TEXT_LAYER:int = 2;
		
		public static const HORIZ:int = 1;
		public static const VERT:int = 2;
		
		public static const TOTAL_LAYERS:int = 4;
		
		public function MapRenderer(g:Game, stage:Sprite, tileHolder:Sprite, scale:Number, width:int, height:int, stageWidth:int, stageHeight:int){
			this.stage = stage;
			this.tileHolder = tileHolder;
			this.scale = scale;
			SCALE = 1.0 / scale;
			this.width = width;
			this.height = height;
			this.stageWidth = stageWidth;
			this.stageHeight = stageHeight;
			converter = new MapTileConverter(g, this);
			scrollX = true;
			scrollY = true;
			setBorder([1, 0, 3, 1], [1, 0, 3, 1]);
			tilesWidth = Math.ceil(stageWidth / scale);
			tilesHeight = Math.ceil(stageHeight / scale);
			tileLayers = [];
			tileLayers_behind = [];
			mapArrayLayers = [];
			renderedArrayLayers = [];
			mapRowsIndexLayers = new Vector.<Vector.<int>>(TOTAL_LAYERS, true);
			mapColsIndexLayers = new Vector.<Vector.<int>>(TOTAL_LAYERS, true);
			updateLayer = new Vector.<Boolean>(TOTAL_LAYERS, true);
			imageLayers = new Vector.<BitmapData>(TOTAL_LAYERS, true);
			imageHolderLayers = new Vector.<Bitmap>(TOTAL_LAYERS, true);
			topLeftLayers = new Vector.<Pixel>(TOTAL_LAYERS, true);
			bottomRightLayers = new Vector.<Pixel>(TOTAL_LAYERS, true);
			currentLayer = 0;
			layers = 0;
			masterLayer = GAME_OBJECT_LAYER;
			scrollTopleftX=0;
			scrollTopleftY=0;
			scrollBottomrightX=0;
			scrollBottomrightY = 0;
			mapRect = new Rect(0, 0, width * scale, height * scale);
		}
		/* Sets the extension of the rendering around the viewport
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
		/* Add a reference array layer to the scroller
		 * image and imageHolder properties tells the scroller that this layer consists Blit objects
		
		public function addLayer(mapLayer:Array, image:BitmapData = null, imageHolder:Bitmap = null):void {
			if(tileLayers.length == layers){
				//tileLayers_behind.push(tileHolder.createEmptyMovieClip("tiles_behind"+layers, layers*10));
				var temp:Sprite = new Sprite();
				tileHolder.addChild(temp);
				tileLayers.push(temp);
			}
			imageLayers.push(image);
			imageHolderLayers.push(imageHolder);
			mapArrayLayers.push(mapLayer);
			renderedArrayLayers.push([]);
			mapRowsIndexLayers.push([]);
			mapColsIndexLayers.push([]);
			topLeftLayers.push(new Pixel());
			bottomRightLayers.push(new Pixel());
			updateLayer.push(true);
			layers++;
		} */
		/* A block version of addLayer to take advantage of the Vector datatype */
		public function setLayers(mapLayers:Array, tiles:Array, images:Array, imageHolders:Array):void{
			mapArrayLayers = mapLayers;
			for(var i:int = 0; i < TOTAL_LAYERS; i++){
				renderedArrayLayers[i] = [];
				if(tiles[i]) this.tileLayers[i] = tiles[i];
				else{
					var temp:Sprite = new Sprite();
					tileHolder.addChild(temp);
					tileLayers[i] = temp;
				}
				imageLayers[i] = images[i];
				imageHolderLayers[i] = imageHolders[i];
				topLeftLayers[i] = new Pixel();
				bottomRightLayers[i] = new Pixel();
				updateLayer[i] = true;
			}
			layers = mapArrayLayers.length;
		}
		/* This sets up the renderer for a new map, resizing it and flushing the arrays that
		 * help the rendering */
		public function newMap(width:int, height:int, newMapArrayLayers:Array):void{
			mapArrayLayers = newMapArrayLayers;
			this.width = width;
			this.height = height;
			mapRect = new Rect(0, 0, width * scale, height * scale);
		}
		/* Force the scroller to use tileLayer as the mount for the next layer
		 * instead of generating its own layer internally
		 */
		public function addTileLayer(tileLayer:Sprite):void{
			tileLayers.push(tileLayer);
		}
		/* Add signs for the map */
		public function setSignage(signage:Array):void{
			this.signage = signage;
		}
		/* Change the layer the scroller is operating on */
		public function changeLayer(n:int):void{
			tiles = tileLayers[n];
			mapArray = mapArrayLayers[n];
			renderedArray = renderedArrayLayers[n];
			mapRowsIndex = mapRowsIndexLayers[n];
			mapColsIndex = mapColsIndexLayers[n];
			image = imageLayers[n];
			imageHolder = imageHolderLayers[n];
			topLeft = topLeftLayers[n];
			bottomRight = bottomRightLayers[n];
			currentLayer = n;
		}
		/* Turn on / off scrolling behaviour on a layer */
		public function setLayerUpdate(n:int, setting:Boolean):void{
			updateLayer[n] = setting;
		}
		/* Convert all numbers to tiles / clips on a given layer twice over
		 * to generate a scrollable layer
		 */
		public function renderScrollLayer(n:int, type:int):void {
			changeLayer(n);
			tiles = new Sprite();
			var r:int, c:int;
			for (r = 0; r < height; r++) {
				for (c = 0; c < width; c++) {
					converter.createTile(c, r);
				}
			}
			if(type == HORIZ) {
				tiles.x = Game.SCALE * width;
			} else if(type == VERT) {
				tiles.y = Game.SCALE * height;
			}
			tileLayers[n].addChild(tiles);
			tiles = new Sprite();
			for (r = 0; r < height; r++) {
				for (c = 0; c < width; c++) {
					converter.createTile(c, r);
				}
			}
			tileLayers[n].addChild(tiles);
			setLayerUpdate(n, false);
		}
		/* Renders layer n, then converts it to BitmapData tiles, attaches Bitmaps
		 * to layer n, then sets that layer to no longer update
		 */
		public function layerToBitmap(n:Number):void{
			changeLayer(n);
			tiles = new Sprite();
			// the maximum bitmap size in Flash
			var max:int = 2880;
			var pixelWidth:int = width * scale;
			var pixelHeight:int = height * scale;
			var captureWidth:int = max;
			var captureHeight:int = max;
			var bitmaps:Array = [];
			var r:int, c:int;
			for (r = 0; r < height; r++) {
				for (c = 0; c < width; c++) {
					converter.createTile(c, r);
				}
			}
			var matrix:Matrix = new Matrix();
			for(r = 0; r < pixelHeight; r += max) {
				captureWidth = max;
				for(c = 0; c < pixelWidth; c += max) {
					if(c + captureWidth > pixelWidth) captureWidth = pixelWidth - c;
					if(r + captureHeight > pixelHeight) captureHeight = pixelHeight - r;
					var bitmapdata:BitmapData = new BitmapData(captureWidth, captureHeight, true, 0x00FFFFFF);
					matrix.tx = -c;
					matrix.ty = -r;
					bitmapdata.draw(tiles, matrix);
					var bitmap:Bitmap = new Bitmap(bitmapdata);
					bitmap.x = c;
					bitmap.y = r;
					bitmaps.push(bitmap);
					// debug gfx: (draw a green square at the top left of each bitmap and a red one at bottom right)
					//bitmapdata.fillRect(new Rectangle(0, 0, 10, 10), 0xFF00FF00);
					//bitmapdata.fillRect(new Rectangle(captureWidth-10, captureHeight-10, 10, 10), 0xFFFF0000);
				}
			}
			tiles = tileLayers[n];
			for(var i:int = 0; i < bitmaps.length; i++) {
				tiles.addChild(bitmaps[i]);
			}
			updateLayer[n] = false;
		}
		/* Gets rid of a tile (coins, enemies, etc) */
		public function removeTile(layer:int, x:int, y:int):void{
			mapArrayLayers[layer][y][x] = null;
		}
		/* Puts a tile on the map (useful for enemies with AI that change their map locale) */
		public function addTile(layer:int, x:int, y:int, id:*):void{
			mapArrayLayers[layer][y][x] = id;
		}
		/* Draw the edge of the scroll border and the stage edge */
		public function draw(gfx:Graphics):void{
			gfx.moveTo(scrollTopleftX, scrollTopleftY);
			gfx.lineTo(scrollBottomrightX, scrollTopleftY);
			gfx.lineTo(scrollBottomrightX, scrollBottomrightY);
			gfx.lineTo(scrollTopleftX, scrollBottomrightY);
			gfx.lineTo(scrollTopleftX, scrollTopleftY);
			gfx.moveTo( -stage.x, -stage.y);
			gfx.lineTo( -stage.x+stageWidth, -stage.y);
			gfx.lineTo( -stage.x+stageWidth, -stage.y+stageHeight);
			gfx.lineTo( -stage.x, -stage.y+stageHeight);
			gfx.lineTo( -stage.x, -stage.y);
		}
		/* Return true if a point is inside the edge of the scrolling area */
		public function contains(x:Number, y:Number):Boolean{
			return x < scrollBottomrightX - 1 && x >= scrollTopleftX && y < scrollBottomrightY - 1 && y >= scrollTopleftY;
		}
		/* Return true if a rect intersects the scrolling area */
		public function intersects(b:Rect, border:Number = 0):Boolean{
			return !(scrollTopleftX - border > b.x + (b.width - 1) || scrollBottomrightX - 1 + border < b.x || scrollTopleftY - border > b.y + (b.height - 1) || scrollBottomrightY - 1 + border < b.y);
		}
		/* Reset the lastStageX and lastStageY to indicate no scroll should occur */
		public function reset():void{
			lastStageX = (stage.x * SCALE) >> 0;
			lastStageY = (stage.y * SCALE) >> 0;
		}
		/* Paint the initial view when a level starts and initialise the scrolling arrays */
		public function init(x:int, y:int):void{
			
			var halfTilesWidth:int = Math.round(tilesWidth*0.5);
			var halfTilesHeight:int = Math.round(tilesHeight*0.5);
			stage.x = -((x - halfTilesWidth) * scale);
			stage.y = -((y - halfTilesHeight) * scale);
			lastStageX = (stage.x / scale) >> 0;
			lastStageY = (stage.y / scale) >> 0;
			
			var rezCol:int = x - halfTilesWidth - borderX[masterLayer] * 2;
			var rezRow:int = y - halfTilesHeight - borderY[masterLayer] * 2;
			var rezWidth:int = rezCol + tilesWidth + borderX[masterLayer] * 4;
			var rezHeight:int = rezRow + tilesHeight + borderY[masterLayer] * 4;
			if(rezCol < 0) rezCol = 0;
			if(rezRow < 0) rezRow = 0;
			if(rezWidth > width) rezWidth = width;
			if(rezHeight > height) rezHeight = height;
			
			scrollTopleftX = rezCol * scale;
			scrollTopleftY = rezRow * scale;
			scrollBottomrightX = rezWidth * scale;
			scrollBottomrightY = rezHeight * scale;
			
			renderedArrayLayers = [];
			mapRowsIndexLayers = new Vector.<Vector.<int>>(TOTAL_LAYERS, true);
			mapColsIndexLayers = new Vector.<Vector.<int>>(TOTAL_LAYERS, true);
			
			var c:int, r:int;
			for(var i:int = 0; i < layers; i++){
				topLeftLayers[i] = new Pixel(rezCol, rezRow);
				bottomRightLayers[i] = new Pixel(rezWidth, rezHeight);
				renderedArrayLayers[i] = [];
				mapRowsIndexLayers[i] = new Vector.<int>();
				mapColsIndexLayers[i] = new Vector.<int>();
				changeLayer(i);
				if(updateLayer[i]){
					for(c = rezCol; c < rezWidth; c++){
						mapColsIndex.push(c);
					}
					for(r = rezRow; r < rezHeight; r++){
						pushRow(r);
					}
				}
			}
		}
		/* iterate through the map and generate tiles marked with "F", for synchronized and "difficult" items
		public function renderForced():void {
			for(var i:int = 0; i < layers; i++) {
				changeLayer(i);
				for(var r:int = 0; r < height; r++) {
					for(var c:int = 0; c < width; c++) {
						if(!(mapArray[r][c] >= 0 || mapArray[r][c] <= 0)) {
							if(mapArray[r][c] is String && mapArray[r][c].search(/F/) > -1) {
								mapArray[r][c] = mapArray[r][c].replace(/F/, "");
								converter.createTile(c, r, true);
								mapArray[r][c] = 0;
							}
						}
					}
				}
			}
		}*/
		/* iterate through the map and generate tiles of the given id */
		public function renderElement(n:int):void {
			for(var i:int = 0; i < layers; i++) {
				changeLayer(i);
				for(var r:int = 0; r < height; r++) {
					for(var c:int = 0; c < width; c++) {
						if(mapArray[r][c] >= 0 || mapArray[r][c] <= 0) {
							if(mapArray[r][c] == n){
								converter.createTile(c, r);
								mapArray[r][c] = 0;
							}
						} else {
							var id:int = mapArray[r][c].match(/\d+/)[0];
							if(id == n){
								converter.createTile(c, r);
								mapArray[r][c] = 0;
							}
						}
					}
				}
			}
		}
		/* iterate through the map and generate ALL tiles */
		public function renderAll():void {
			for(var i:int = 0; i < layers; i++) {
				changeLayer(i);
				for(var r:int = 0; r < height; r++) {
					for(var c:int = 0; c < width; c++) {
						converter.createTile(c, r);
					}
				}
			}
		}
		/* Add an object to the dynamic array grid of the clip manager at a specific map location */
		public function addToRenderedArray(x:int, y:int, layer:int, item:*):void{
			if(x < topLeft.x || y < topLeft.y || x > bottomRight.x || y > bottomRight.y) return;
			changeLayer(layer);
			x -= topLeft.x;
			y -= topLeft.y;
			// are we stacking into this location?
			if(renderedArray[y][x]){
				if(renderedArray[y][x] is Array){
					renderedArray[y][x].push(item);
				} else {
					renderedArray[y][x] = [renderedArray[y][x], item];
				}
			} else renderedArray[y][x] = item;
		}
		/* Remove an object from the dynamic array grid of the clip manager at a specific map location */
		public function removeFromRenderedArray(x:int, y:int, layer:int, item:*):void{
			if(x < topLeft.x || y < topLeft.y || x > bottomRight.x || y > bottomRight.y) return;
			changeLayer(layer);
			x -= topLeft.x;
			y -= topLeft.y;
			// are we stacking into this location?
			if(renderedArray[y][x]){
				if(renderedArray[y][x] is Array){
					var i:int = renderedArray[y][x].indexOf(item);
					renderedArray[y][x].splice(i);
					if(renderedArray[y][x].length == 0) renderedArray[y][x] = null;
				} else {
					renderedArray[y][x] = null;
				}
			}
		}
		/* Takes care of erasing and painting clips onto the stage
		 * The edge of rendered area is defined by the arrays borderX and borderY
		 * Some layers will obviously need to expand further beyond the view port than
		 * purely graphical ones
		 */
		public function main():void{
			var stageX:int = (stage.x * SCALE) >> 0;
			var stageY:int = (stage.y * SCALE) >> 0;
			var diff:int;
			for(var i:int = 0; i < layers; i++) {
				changeLayer(i);
				if(updateLayer[i]){
					if(scrollX){
						// scroll left - adding to the left, destroying on the right, stage moving right
						if(stageX > lastStageX){
							if(mapColsIndex[0] > 0 && mapColsIndex[0] > -stageX - borderX[i]){
								diff = mapColsIndex[0] - ( -stageX - borderX[i]);
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
							if(mapColsIndex[mapColsIndex.length-1] > -stageX + tilesWidth + borderX[i]){
								diff = mapColsIndex[mapColsIndex.length - 1] - (-stageX + tilesWidth + borderX[i]);;
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
						// scroll right - adding to the right, destroying on the left, stage moving left
						if(stageX < lastStageX){
							if(mapColsIndex[mapColsIndex.length-1] < width-1 && mapColsIndex[mapColsIndex.length-1] < -stageX + tilesWidth + borderX[i]){
								diff = (-stageX + tilesWidth + borderX[i]) - mapColsIndex[mapColsIndex.length-1];
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
							if(mapColsIndex[0] < -stageX - borderX[i]){
								diff = ( -stageX - borderX[i]) - mapColsIndex[0];
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
						// scroll up - adding above, destroying below, stage moving down
						if(stageY > lastStageY){
							if(mapRowsIndex[0] > 0 && mapRowsIndex[0] > -stageY - borderY[i]){
								diff = mapRowsIndex[0] - ( -stageY - borderY[i]);
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
							if(mapRowsIndex[mapRowsIndex.length-1] > -stageY + tilesHeight + borderY[i]){
								diff = mapRowsIndex[mapRowsIndex.length - 1] - (-stageY + tilesHeight + borderY[i]);;
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
						// scroll down - adding below, destroying above, stage moving up
						if(stageY < lastStageY){
							if(mapRowsIndex[mapRowsIndex.length-1] < height-1 && mapRowsIndex[mapRowsIndex.length-1] < -stageY + tilesHeight + borderY[i]){
								diff = (-stageY + tilesHeight + borderY[i]) - mapRowsIndex[mapRowsIndex.length-1];
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
							if(mapRowsIndex[0] < -stageY - borderY[i]){
								diff = ( -stageY - borderY[i]) - mapRowsIndex[0];
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
					// if this layer is a blitting layer, we iterate through the renderedArray and blit all that
					// we find to the appropriate blitting image
					if(image){
						var r:int, c:int;
						for(r = 0; r < renderedArray.length; r++){
							for(c = 0; c < renderedArray[r].length; c++){
								if(renderedArray[r][c]){
									//trace(currentLayer+" "+renderedArray[r][c]);
									renderedArray[r][c].x = -imageHolder.x + (topLeft.x + c) * scale;
									renderedArray[r][c].y = -imageHolder.y + (topLeft.y + r) * scale;
									renderedArray[r][c].render(image);
								}
								
							}
						}
					}
				}
			}
			lastStageX = stageX;
			lastStageY = stageY;
		}
		// LEFT RIGHT PUSHER POPPERS =========================================================
		
		/* Add a column of clips left of stage */
		protected function pushCol(x:Number):void{
			mapColsIndex.push(x);
			for(var y:int = 0; y < mapRowsIndex.length; y++){
				renderedArray[y].push(converter.createTile(x, y + mapRowsIndex[0]));
			}
		}
		/* Add a column of clips right of the stage */
		protected function unshiftCol(x:Number):void{
			mapColsIndex.unshift(x);
			for(var y:int = 0; y < mapRowsIndex.length; y++){
				renderedArray[y].unshift(converter.createTile(x, y + mapRowsIndex[0]));
			}
		}
		/* Remove a column of clips left of the stage */
		protected function popCol():void{
			for(var y:int = 0; y < mapRowsIndex.length; y++){
				if(renderedArray[y][mapColsIndex.length - 1]) {
					if(!image){
						// is this a stack of objects to remove?
						if(renderedArray[y][mapColsIndex.length - 1] is Array){
							tempArray = renderedArray[y][mapColsIndex.length - 1];
							for(n = 0; n < tempArray.length; n++){
								tempArray[n].remove();
							}
						}
						else renderedArray[y][mapColsIndex.length - 1].remove();
					}
				}
				renderedArray[y].pop();
			}
			mapColsIndex.pop();
		}
		/* Remove a column of clips right of the stage */
		protected function shiftCol():void{
			for(var y:int = 0; y < mapRowsIndex.length; y++){
				if(renderedArray[y][0] != null) {
					if(!image){
						// is this a stack of objects to remove?
						if(renderedArray[y][0] is Array){
							tempArray = renderedArray[y][0];
							for(n = 0; n < tempArray.length; n++){
								tempArray[n].remove();
							}
						}
						else renderedArray[y][0].remove();
					}
				}
				renderedArray[y].shift();
			}
			mapColsIndex.shift();
		}
		// UP DOWN PUSHER POPPERS =========================================================
		
		/* Add a row of clips to the bottom of the stage */
		protected function pushRow(y:int):void{
			renderedArray.push([]);
			mapRowsIndex.push(y);
			for(var x:int = 0; x < mapColsIndex.length; x++){
				renderedArray[renderedArray.length-1].push(converter.createTile(x + mapColsIndex[0], y));
			}
		}
		/* Add a row of clips to the top of the stage */
		protected function unshiftRow(y:int):void{
			renderedArray.unshift([]);
			mapRowsIndex.unshift(y);
			for(var x:int = 0; x < mapColsIndex.length; x++){
				renderedArray[0].push(converter.createTile(x + mapColsIndex[0], y));
			}
		}
		/* Remove a row of clips from below the stage */
		protected function popRow():void{
			for(var x:int = 0; x < mapColsIndex.length; x++){
				if(renderedArray[renderedArray.length - 1][x] != null) {
					if(!image){
						// is this a stack of objects to remove?
						if(renderedArray[renderedArray.length - 1][x] is Array){
							tempArray = renderedArray[renderedArray.length - 1][x];
							for(n = 0; n < tempArray.length; n++){
								tempArray[n].remove();
							}
						}
						else renderedArray[renderedArray.length - 1][x].remove();
					}
				}
			}
			renderedArray.pop();
			mapRowsIndex.pop();
		}
		/* Remove a row of clips from above the stage */
		protected function shiftRow():void{
			for(var x:int = 0; x < mapColsIndex.length; x++){
				if(renderedArray[0][x] != null) {
					if(!image){
						// is this a stack of objects to remove?
						if(renderedArray[0][x] is Array){
							tempArray = renderedArray[0][x];
							for(n = 0; n < tempArray.length; n++){
								tempArray[n].remove();
							}
						}
						else renderedArray[0][x].remove();
					}
				}
			}
			renderedArray.shift();
			mapRowsIndex.shift();
		}
	}
	
}