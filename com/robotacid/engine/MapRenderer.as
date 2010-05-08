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
		public var map_array:Array;
		public var map_array_layers:Array;
		public var rendered_array:Array;
		public var rendered_array_layers:Array;
		public var map_rows_index:Vector.<int>;
		public var map_rows_index_layers:Vector.<Vector.<int>>;
		public var map_cols_index:Vector.<int>;
		public var map_cols_index_layers:Vector.<Vector.<int>>;
		public var tile_layers:Array;
		public var tile_layers_behind:Array;
		public var signage:Array;
		public var tiles:Sprite;
		public var tile_holder:Sprite;
		public var layers:int;
		public var current_layer:int;
		public var stage:Sprite;
		public var scroll_x:Boolean;
		public var scroll_y:Boolean;
		public var image:BitmapData;
		public var image_holder:Bitmap;
		public var image_layers:Vector.<BitmapData>;
		public var image_holder_layers:Vector.<Bitmap>;
		public var scale:Number;
		public var width:int;
		public var height:int;
		public var stage_width:int;
		public var stage_height:int;
		public var border_x:Vector.<int>;
		public var border_y:Vector.<int>;
		public var tiles_width:int;
		public var tiles_height:int;
		public var last_stage_x:int;
		public var last_stage_y:int;
		public var update_layer:Vector.<Boolean>;
		public var scroll_topleft_x:int;
		public var scroll_topleft_y:int;
		public var scroll_bottomright_x:int;
		public var scroll_bottomright_y:int;
		public var master_layer:int;
		public var map_rect:Rect;
		public var SCALE:Number;
		
		public var top_left:Pixel;
		public var top_left_layers:Vector.<Pixel>;
		public var bottom_right:Pixel;
		public var bottom_right_layers:Vector.<Pixel>;
		
		private var temp_array:Array;
		private var n:int;
		
		public static const BLOCK_LAYER:int = 1;
		public static const GAME_OBJECT_LAYER:int = 2;
		public static const TEXT_LAYER:int = 2;
		
		public static const HORIZ:int = 1;
		public static const VERT:int = 2;
		
		public static const TOTAL_LAYERS:int = 4;
		
		public function MapRenderer(g:Game, stage:Sprite, tile_holder:Sprite, scale:Number, width:int, height:int, stage_width:int, stage_height:int){
			this.stage = stage;
			this.tile_holder = tile_holder;
			this.scale = scale;
			SCALE = 1.0 / scale;
			this.width = width;
			this.height = height;
			this.stage_width = stage_width;
			this.stage_height = stage_height;
			converter = new MapTileConverter(g, this);
			scroll_x = true;
			scroll_y = true;
			setBorder([1, 0, 3, 1], [1, 0, 3, 1]);
			tiles_width = Math.ceil(stage_width / scale);
			tiles_height = Math.ceil(stage_height / scale);
			tile_layers = [];
			tile_layers_behind = [];
			map_array_layers = [];
			rendered_array_layers = [];
			map_rows_index_layers = new Vector.<Vector.<int>>(TOTAL_LAYERS, true);
			map_cols_index_layers = new Vector.<Vector.<int>>(TOTAL_LAYERS, true);
			update_layer = new Vector.<Boolean>(TOTAL_LAYERS, true);
			image_layers = new Vector.<BitmapData>(TOTAL_LAYERS, true);
			image_holder_layers = new Vector.<Bitmap>(TOTAL_LAYERS, true);
			top_left_layers = new Vector.<Pixel>(TOTAL_LAYERS, true);
			bottom_right_layers = new Vector.<Pixel>(TOTAL_LAYERS, true);
			current_layer = 0;
			layers = 0;
			master_layer = GAME_OBJECT_LAYER;
			scroll_topleft_x=0;
			scroll_topleft_y=0;
			scroll_bottomright_x=0;
			scroll_bottomright_y = 0;
			map_rect = new Rect(0, 0, width * scale, height * scale);
		}
		/* Sets the extension of the rendering around the viewport
		 * 
		 * Some elements may require some distance away from the viewport before they get yanked
		 */
		public function setBorder(x_layers:Array, y_layers:Array):void{
			var i:int;
			border_x = new Vector.<int>(x_layers.length, true);
			border_y = new Vector.<int>(y_layers.length, true);
			for(i = 0; i < x_layers.length; i++){
				border_x[i] = x_layers[i];
			}
			for(i = 0; i < y_layers.length; i++){
				border_y[i] = y_layers[i];
			}
		}
		/* Add a reference array layer to the scroller
		 * image and image_holder properties tells the scroller that this layer consists Blit objects
		
		public function addLayer(map_layer:Array, image:BitmapData = null, image_holder:Bitmap = null):void {
			if(tile_layers.length == layers){
				//tile_layers_behind.push(tile_holder.createEmptyMovieClip("tiles_behind"+layers, layers*10));
				var temp:Sprite = new Sprite();
				tile_holder.addChild(temp);
				tile_layers.push(temp);
			}
			image_layers.push(image);
			image_holder_layers.push(image_holder);
			map_array_layers.push(map_layer);
			rendered_array_layers.push([]);
			map_rows_index_layers.push([]);
			map_cols_index_layers.push([]);
			top_left_layers.push(new Pixel());
			bottom_right_layers.push(new Pixel());
			update_layer.push(true);
			layers++;
		} */
		/* A block version of addLayer to take advantage of the Vector datatype */
		public function setLayers(map_layers:Array, tiles:Array, images:Array, image_holders:Array):void{
			map_array_layers = map_layers;
			for(var i:int = 0; i < TOTAL_LAYERS; i++){
				rendered_array_layers[i] = [];
				if(tiles[i]) this.tile_layers[i] = tiles[i];
				else{
					var temp:Sprite = new Sprite();
					tile_holder.addChild(temp);
					tile_layers[i] = temp;
				}
				image_layers[i] = images[i];
				image_holder_layers[i] = image_holders[i];
				top_left_layers[i] = new Pixel();
				bottom_right_layers[i] = new Pixel();
				update_layer[i] = true;
			}
			layers = map_array_layers.length;
		}
		/* This sets up the renderer for a new map, resizing it and flushing the arrays that
		 * help the rendering */
		public function newMap(width:int, height:int, new_map_array_layers:Array):void{
			map_array_layers = new_map_array_layers;
			this.width = width;
			this.height = height;
			map_rect = new Rect(0, 0, width * scale, height * scale);
		}
		/* Force the scroller to use tile_layer as the mount for the next layer
		 * instead of generating its own layer internally
		 */
		public function addTileLayer(tile_layer:Sprite):void{
			tile_layers.push(tile_layer);
		}
		/* Add signs for the map */
		public function setSignage(signage:Array):void{
			this.signage = signage;
		}
		/* Change the layer the scroller is operating on */
		public function changeLayer(n:int):void{
			tiles = tile_layers[n];
			map_array = map_array_layers[n];
			rendered_array = rendered_array_layers[n];
			map_rows_index = map_rows_index_layers[n];
			map_cols_index = map_cols_index_layers[n];
			image = image_layers[n];
			image_holder = image_holder_layers[n];
			top_left = top_left_layers[n];
			bottom_right = bottom_right_layers[n];
			current_layer = n;
		}
		/* Turn on / off scrolling behaviour on a layer */
		public function setLayerUpdate(n:int, setting:Boolean):void{
			update_layer[n] = setting;
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
			tile_layers[n].addChild(tiles);
			tiles = new Sprite();
			for (r = 0; r < height; r++) {
				for (c = 0; c < width; c++) {
					converter.createTile(c, r);
				}
			}
			tile_layers[n].addChild(tiles);
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
			var pixel_width:int = width * scale;
			var pixel_height:int = height * scale;
			var capture_width:int = max;
			var capture_height:int = max;
			var bitmaps:Array = [];
			var r:int, c:int;
			for (r = 0; r < height; r++) {
				for (c = 0; c < width; c++) {
					converter.createTile(c, r);
				}
			}
			var matrix:Matrix = new Matrix();
			for(r = 0; r < pixel_height; r += max) {
				capture_width = max;
				for(c = 0; c < pixel_width; c += max) {
					if(c + capture_width > pixel_width) capture_width = pixel_width - c;
					if(r + capture_height > pixel_height) capture_height = pixel_height - r;
					var bitmapdata:BitmapData = new BitmapData(capture_width, capture_height, true, 0x00FFFFFF);
					matrix.tx = -c;
					matrix.ty = -r;
					bitmapdata.draw(tiles, matrix);
					var bitmap:Bitmap = new Bitmap(bitmapdata);
					bitmap.x = c;
					bitmap.y = r;
					bitmaps.push(bitmap);
					// debug gfx: (draw a green square at the top left of each bitmap and a red one at bottom right)
					//bitmapdata.fillRect(new Rectangle(0, 0, 10, 10), 0xFF00FF00);
					//bitmapdata.fillRect(new Rectangle(capture_width-10, capture_height-10, 10, 10), 0xFFFF0000);
				}
			}
			tiles = tile_layers[n];
			for(var i:int = 0; i < bitmaps.length; i++) {
				tiles.addChild(bitmaps[i]);
			}
			update_layer[n] = false;
		}
		/* Gets rid of a tile (coins, enemies, etc) */
		public function removeTile(layer:int, x:int, y:int):void{
			map_array_layers[layer][y][x] = 0;
		}
		/* Puts a tile on the map (useful for enemies with AI that change their map locale) */
		public function addTile(layer:int, x:int, y:int, id:int):void{
			map_array_layers[layer][y][x] = id;
		}
		/* Draw the edge of the scroll border and the stage edge */
		public function draw(gfx:Graphics):void{
			gfx.moveTo(scroll_topleft_x, scroll_topleft_y);
			gfx.lineTo(scroll_bottomright_x, scroll_topleft_y);
			gfx.lineTo(scroll_bottomright_x, scroll_bottomright_y);
			gfx.lineTo(scroll_topleft_x, scroll_bottomright_y);
			gfx.lineTo(scroll_topleft_x, scroll_topleft_y);
			gfx.moveTo( -stage.x, -stage.y);
			gfx.lineTo( -stage.x+stage_width, -stage.y);
			gfx.lineTo( -stage.x+stage_width, -stage.y+stage_height);
			gfx.lineTo( -stage.x, -stage.y+stage_height);
			gfx.lineTo( -stage.x, -stage.y);
		}
		/* Return true if a point is inside the edge of the scrolling area */
		public function contains(x:Number, y:Number):Boolean{
			return x < scroll_bottomright_x - 1 && x >= scroll_topleft_x && y < scroll_bottomright_y - 1 && y >= scroll_topleft_y;
		}
		/* Return true if a rect intersects the scrolling area */
		public function intersects(b:Rect, border:Number = 0):Boolean{
			return !(scroll_topleft_x - border > b.x + (b.width - 1) || scroll_bottomright_x - 1 + border < b.x || scroll_topleft_y - border > b.y + (b.height - 1) || scroll_bottomright_y - 1 + border < b.y);
		}
		/* Reset the last_stage_x and last_stage_y to indicate no scroll should occur */
		public function reset():void{
			last_stage_x = (stage.x * SCALE) >> 0;
			last_stage_y = (stage.y * SCALE) >> 0;
		}
		/* Paint the initial view when a level starts and initialise the scrolling arrays */
		public function init(x:int, y:int):void{
			
			var half_tiles_width:int = Math.round(tiles_width*0.5);
			var half_tiles_height:int = Math.round(tiles_height*0.5);
			stage.x = -((x - half_tiles_width) * scale);
			stage.y = -((y - half_tiles_height) * scale);
			last_stage_x = (stage.x / scale) >> 0;
			last_stage_y = (stage.y / scale) >> 0;
			
			var rez_col:int = x - half_tiles_width - border_x[master_layer] * 2;
			var rez_row:int = y - half_tiles_height - border_y[master_layer] * 2;
			var rez_width:int = rez_col + tiles_width + border_x[master_layer] * 4;
			var rez_height:int = rez_row + tiles_height + border_y[master_layer] * 4;
			if(rez_col < 0) rez_col = 0;
			if(rez_row < 0) rez_row = 0;
			if(rez_width > width) rez_width = width;
			if(rez_height > height) rez_height = height;
			
			scroll_topleft_x = rez_col * scale;
			scroll_topleft_y = rez_row * scale;
			scroll_bottomright_x = rez_width * scale;
			scroll_bottomright_y = rez_height * scale;
			
			rendered_array_layers = [];
			map_rows_index_layers = new Vector.<Vector.<int>>(TOTAL_LAYERS, true);
			map_cols_index_layers = new Vector.<Vector.<int>>(TOTAL_LAYERS, true);
			
			var c:int, r:int;
			for(var i:int = 0; i < layers; i++){
				top_left_layers[i] = new Pixel(rez_col, rez_row);
				bottom_right_layers[i] = new Pixel(rez_width, rez_height);
				rendered_array_layers[i] = [];
				map_rows_index_layers[i] = new Vector.<int>();
				map_cols_index_layers[i] = new Vector.<int>();
				changeLayer(i);
				if(update_layer[i]){
					for(c = rez_col; c < rez_width; c++){
						map_cols_index.push(c);
					}
					for(r = rez_row; r < rez_height; r++){
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
						if(!(map_array[r][c] >= 0 || map_array[r][c] <= 0)) {
							if(map_array[r][c] is String && map_array[r][c].search(/F/) > -1) {
								map_array[r][c] = map_array[r][c].replace(/F/, "");
								converter.createTile(c, r, true);
								map_array[r][c] = 0;
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
						if(map_array[r][c] >= 0 || map_array[r][c] <= 0) {
							if(map_array[r][c] == n){
								converter.createTile(c, r);
								map_array[r][c] = 0;
							}
						} else {
							var id:int = map_array[r][c].match(/\d+/)[0];
							if(id == n){
								converter.createTile(c, r);
								map_array[r][c] = 0;
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
			if(x < top_left.x || y < top_left.y || x > bottom_right.x || y > bottom_right.y) return;
			changeLayer(layer);
			x -= top_left.x;
			y -= top_left.y;
			// are we stacking into this location?
			if(rendered_array[y][x]){
				if(rendered_array[y][x] is Array){
					rendered_array[y][x].push(item);
				} else {
					rendered_array[y][x] = [rendered_array[y][x], item];
				}
			} else rendered_array[y][x] = item;
		}
		/* Remove an object from the dynamic array grid of the clip manager at a specific map location */
		public function removeFromRenderedArray(x:int, y:int, layer:int, item:*):void{
			if(x < top_left.x || y < top_left.y || x > bottom_right.x || y > bottom_right.y) return;
			changeLayer(layer);
			x -= top_left.x;
			y -= top_left.y;
			// are we stacking into this location?
			if(rendered_array[y][x]){
				if(rendered_array[y][x] is Array){
					var i:int = rendered_array[y][x].indexOf(item);
					rendered_array[y][x].splice(i);
					if(rendered_array[y][x].length == 0) rendered_array[y][x] = null;
				} else {
					rendered_array[y][x] = null;
				}
			}
		}
		/* Takes care of erasing and painting clips onto the stage
		 * The edge of rendered area is defined by the arrays border_x and border_y
		 * Some layers will obviously need to expand further beyond the view port than
		 * purely graphical ones
		 */
		public function main():void{
			var stage_x:int = (stage.x * SCALE) >> 0;
			var stage_y:int = (stage.y * SCALE) >> 0;
			var diff:int;
			for(var i:int = 0; i < layers; i++) {
				changeLayer(i);
				if(update_layer[i]){
					if(scroll_x){
						// scroll left - adding to the left, destroying on the right, stage moving right
						if(stage_x > last_stage_x){
							if(map_cols_index[0] > 0 && map_cols_index[0] > -stage_x - border_x[i]){
								diff = map_cols_index[0] - ( -stage_x - border_x[i]);
								while(diff > 0){
									unshiftCol(map_cols_index[0]-1);
									
									if(i == master_layer){
										scroll_topleft_x -= scale;
									}
									top_left.x--;
									
									--diff;
									if(map_cols_index[0] == 0) break;
								}
							}
							if(map_cols_index[map_cols_index.length-1] > -stage_x + tiles_width + border_x[i]){
								diff = map_cols_index[map_cols_index.length - 1] - (-stage_x + tiles_width + border_x[i]);;
								while(diff > 0){
									popCol();
									
									if(i == master_layer){
										scroll_bottomright_x -= scale;
									}
									bottom_right.x--;
									
									--diff;
								}
							}
						}
						// scroll right - adding to the right, destroying on the left, stage moving left
						if(stage_x < last_stage_x){
							if(map_cols_index[map_cols_index.length-1] < width-1 && map_cols_index[map_cols_index.length-1] < -stage_x + tiles_width + border_x[i]){
								diff = (-stage_x + tiles_width + border_x[i]) - map_cols_index[map_cols_index.length-1];
								while(diff > 0){
									pushCol(map_cols_index[map_cols_index.length - 1] + 1);
									
									if(i == master_layer){
										scroll_bottomright_x += scale;
									}
									bottom_right.x++;
									
									--diff;
									if(map_cols_index[map_cols_index.length - 1] == width - 1) break;
								}
							}
							if(map_cols_index[0] < -stage_x - border_x[i]){
								diff = ( -stage_x - border_x[i]) - map_cols_index[0];
								while(diff > 0){
									shiftCol();
									
									if(i == master_layer){
										scroll_topleft_x += scale;
									}
									top_left.x++;
									
									--diff;
								}
							}
						}
					}
					if(scroll_y){
						// scroll up - adding above, destroying below, stage moving down
						if(stage_y > last_stage_y){
							if(map_rows_index[0] > 0 && map_rows_index[0] > -stage_y - border_y[i]){
								diff = map_rows_index[0] - ( -stage_y - border_y[i]);
								while(diff > 0){
									unshiftRow(map_rows_index[0]-1);
									
									if(i == master_layer){
										scroll_topleft_y -= scale;
									}
									top_left.y--;
									
									--diff;
									if(map_rows_index[0] == 0) break;
								}
							}
							if(map_rows_index[map_rows_index.length-1] > -stage_y + tiles_height + border_y[i]){
								diff = map_rows_index[map_rows_index.length - 1] - (-stage_y + tiles_height + border_y[i]);;
								while(diff > 0){
									popRow();
									
									if(i == master_layer){
										scroll_bottomright_y -= scale;
									}
									bottom_right.y--;
									
									--diff;
								}
							}
						}
						// scroll down - adding below, destroying above, stage moving up
						if(stage_y < last_stage_y){
							if(map_rows_index[map_rows_index.length-1] < height-1 && map_rows_index[map_rows_index.length-1] < -stage_y + tiles_height + border_y[i]){
								diff = (-stage_y + tiles_height + border_y[i]) - map_rows_index[map_rows_index.length-1];
								while(diff > 0){
									pushRow(map_rows_index[map_rows_index.length-1]+1);
									
									if(i == master_layer){
										scroll_bottomright_y += scale;
									}
									bottom_right.y++;
									
									--diff;
									if(map_rows_index[map_rows_index.length - 1] == height - 1) break;
								}
							}
							if(map_rows_index[0] < -stage_y - border_y[i]){
								diff = ( -stage_y - border_y[i]) - map_rows_index[0];
								while(diff > 0){
									shiftRow();
									
									if(i == master_layer){
										scroll_topleft_y += scale;
									}
									top_left.y++;
									
									--diff;
								}
							}
						}
					}
					// if this layer is a blitting layer, we iterate through the rendered_array and blit all that
					// we find to the appropriate blitting image
					if(image){
						var r:int, c:int;
						for(r = 0; r < rendered_array.length; r++){
							for(c = 0; c < rendered_array[r].length; c++){
								if(rendered_array[r][c]){
									//trace(current_layer+" "+rendered_array[r][c]);
									rendered_array[r][c].x = -image_holder.x + (top_left.x + c) * scale;
									rendered_array[r][c].y = -image_holder.y + (top_left.y + r) * scale;
									rendered_array[r][c].render(image);
								}
								
							}
						}
					}
				}
			}
			last_stage_x = stage_x;
			last_stage_y = stage_y;
		}
		// LEFT RIGHT PUSHER POPPERS =========================================================
		
		/* Add a column of clips left of stage */
		protected function pushCol(x:Number):void{
			map_cols_index.push(x);
			for(var y:int = 0; y < map_rows_index.length; y++){
				rendered_array[y].push(converter.createTile(x, y + map_rows_index[0]));
			}
		}
		/* Add a column of clips right of the stage */
		protected function unshiftCol(x:Number):void{
			map_cols_index.unshift(x);
			for(var y:int = 0; y < map_rows_index.length; y++){
				rendered_array[y].unshift(converter.createTile(x, y + map_rows_index[0]));
			}
		}
		/* Remove a column of clips left of the stage */
		protected function popCol():void{
			for(var y:int = 0; y < map_rows_index.length; y++){
				if(rendered_array[y][map_cols_index.length - 1]) {
					if(!image){
						// is this a stack of objects to remove?
						if(rendered_array[y][map_cols_index.length - 1] is Array){
							temp_array = rendered_array[y][map_cols_index.length - 1];
							for(n = 0; n < temp_array.length; n++){
								temp_array[n].remove();
							}
						}
						else rendered_array[y][map_cols_index.length - 1].remove();
					}
				}
				rendered_array[y].pop();
			}
			map_cols_index.pop();
		}
		/* Remove a column of clips right of the stage */
		protected function shiftCol():void{
			for(var y:int = 0; y < map_rows_index.length; y++){
				if(rendered_array[y][0] != null) {
					if(!image){
						// is this a stack of objects to remove?
						if(rendered_array[y][0] is Array){
							temp_array = rendered_array[y][0];
							for(n = 0; n < temp_array.length; n++){
								temp_array[n].remove();
							}
						}
						else rendered_array[y][0].remove();
					}
				}
				rendered_array[y].shift();
			}
			map_cols_index.shift();
		}
		// UP DOWN PUSHER POPPERS =========================================================
		
		/* Add a row of clips to the bottom of the stage */
		protected function pushRow(y:int):void{
			rendered_array.push([]);
			map_rows_index.push(y);
			for(var x:int = 0; x < map_cols_index.length; x++){
				rendered_array[rendered_array.length-1].push(converter.createTile(x + map_cols_index[0], y));
			}
		}
		/* Add a row of clips to the top of the stage */
		protected function unshiftRow(y:int):void{
			rendered_array.unshift([]);
			map_rows_index.unshift(y);
			for(var x:int = 0; x < map_cols_index.length; x++){
				rendered_array[0].push(converter.createTile(x + map_cols_index[0], y));
			}
		}
		/* Remove a row of clips from below the stage */
		protected function popRow():void{
			for(var x:int = 0; x < map_cols_index.length; x++){
				if(rendered_array[rendered_array.length - 1][x] != null) {
					if(!image){
						// is this a stack of objects to remove?
						if(rendered_array[rendered_array.length - 1][x] is Array){
							temp_array = rendered_array[rendered_array.length - 1][x];
							for(n = 0; n < temp_array.length; n++){
								temp_array[n].remove();
							}
						}
						else rendered_array[rendered_array.length - 1][x].remove();
					}
				}
			}
			rendered_array.pop();
			map_rows_index.pop();
		}
		/* Remove a row of clips from above the stage */
		protected function shiftRow():void{
			for(var x:int = 0; x < map_cols_index.length; x++){
				if(rendered_array[0][x] != null) {
					if(!image){
						// is this a stack of objects to remove?
						if(rendered_array[0][x] is Array){
							temp_array = rendered_array[0][x];
							for(n = 0; n < temp_array.length; n++){
								temp_array[n].remove();
							}
						}
						else rendered_array[0][x].remove();
					}
				}
			}
			rendered_array.shift();
			map_rows_index.shift();
		}
	}
	
}