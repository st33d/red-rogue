package com.robotacid.gfx {
	import com.robotacid.dungeon.Map;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Entity;
	import com.robotacid.engine.Entity;
	import com.robotacid.engine.Player;
	import com.robotacid.phys.Block;
	import com.robotacid.util.Bresenham;
	import com.robotacid.util.HiddenInt;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class LightMap {
		
		private var i:int;
		
		public var g:Game;
		public var block_map:Vector.<Vector.<int>>;
		public var rect:Rectangle;
		public var dark_image:BitmapData;
		public var fade_image:BitmapData;
		public var edge_image:BitmapData;
		public var bitmap:Bitmap;
		public var entities:Vector.<Entity>;
		public var horiz_edge:Rectangle;
		public var vert_edge:Rectangle;
		public var wall_rect:Rectangle;
		public var width:int;
		public var height:int;
		
		
		public static const EDGE_COL:uint = 0xFFDDDDDD;
		public static const EDGE_OFFSET:Number = 14;
		
		public static var p:Point = new Point();
		
		// tables
		public var dists:Array;
		public var r_slopes:Array;
		public var l_slopes:Array;
		
		public static const MAX_RADIUS:int = 15;
		
		// Multipliers for transforming coordinates to other octants:
		public static const MULT:Array = [
			[1,  0,  0, -1, -1,  0,  0,  1],
			[0,  1, -1,  0,  0, -1,  1,  0],
			[0,  1,  1,  0,  0, -1, -1,  0],
			[1,  0,  0,  1, -1,  0,  0, -1]
		];
		
		public static const FADE_STEP:uint = 0X44000000;
		public static const THRESHOLD:uint = 0XF1000000;
		public static const WALL_COL:uint = 0XFFFFFFFF;
		public static const MINI_MAP_COL:uint = 0x99FFFFFF;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		public static const WALL:int = 1 << 11;
		
		public static const SCALE:Number = Game.SCALE;
		public static const INV_SCALE:Number = Game.INV_SCALE;
		
		
		public function LightMap(block_map:Vector.<Vector.<int>>, g:Game) {
			this.g = g;
			this.block_map = block_map;
			width = block_map[0].length;
			height = block_map.length;
			rect = new Rectangle(0, 0, g.renderer.tiles_width + g.renderer.border_x[g.renderer.master_layer] * 2, g.renderer.tiles_height + g.renderer.border_y[g.renderer.master_layer] * 2);
			dark_image = new BitmapData(width, height, true, 0xFF000000);
			fade_image = new BitmapData(rect.width, rect.height, true, FADE_STEP);
			bitmap = new Bitmap(dark_image);
			bitmap.scaleX = 16;
			bitmap.scaleY = 16;
			entities = new Vector.<Entity>();
			getTables(MAX_RADIUS);
			vert_edge = new Rectangle(0, 0, 2, 16);
			horiz_edge = new Rectangle(0, 0, 16, 2);
			wall_rect = new Rectangle(0, 0, 16, 16);
			edge_image = g.tile_image;
			
			//bitmap.visible = false;
			
		}
		
		public function newMap(block_map:Vector.<Vector.<int>>):void{
			entities = new Vector.<Entity>();
			this.block_map = block_map;
			width = block_map[0].length;
			height = block_map.length;
			rect = new Rectangle(0, 0, g.renderer.tiles_width + g.renderer.border_x[g.renderer.master_layer] * 2, g.renderer.tiles_height + g.renderer.border_y[g.renderer.master_layer] * 2);
			bitmap.bitmapData = dark_image = new BitmapData(width, height, true, 0xFF000000);
			fade_image = new BitmapData(rect.width, rect.height, true, FADE_STEP);
		}
		
		public function main():void{
			p.x = (g.renderer.scroll_topleft_x * INV_SCALE) >> 0;
			p.y = (g.renderer.scroll_topleft_y * INV_SCALE) >> 0;
			rect.x = rect.y = 0;
			dark_image.copyPixels(fade_image, rect, p, null, null, true);
			// flash can't fade to black properly, so we threshold test against the value
			// THRESHOLD and turn that to full black
			rect.x = p.x; rect.y = p.y;
			dark_image.threshold(dark_image, rect, p, ">=", THRESHOLD, 0xff000000);
			var radius:int, entity:Entity;
			for(var i:int = 0; i < entities.length; i++){
				entity = entities[i];
				if(entity.active){
					radius = entity.light;
					if(entity.map_x + radius > p.x && entity.map_y + radius > p.y && entity.map_x - radius < p.x + rect.width && entity.map_y - radius < p.y + rect.height){
						light(entity);
					}
				} else {
					entities.splice(i, 1);
					i--;
				}
			}
		}
		/* Blacks out the entire lightmap, used for teleport */
		public function blackOut():void{
			dark_image.fillRect(dark_image.rect, 0xFF000000);
		}
		/* Executes the lighting routine on the Entity */
		public function light(entity:Entity):void{
			var update_minimap:Boolean = entity is Player;
			var radius:int = entity.light > MAX_RADIUS ? MAX_RADIUS : entity.light;
			// run the shadow casting algorithm on the 8 octants it needs to propagate along
			for(i = 0; i < 8; i++){
				castLight(entity.map_x, entity.map_y, 1, 1.0, 0.0, radius, MULT[0][i], MULT[1][i], MULT[2][i], MULT[3][i], entity.light_cols, update_minimap);
			}
			
			var col:uint = dark_image.getPixel32(entity.map_x, entity.map_y);
			if(col > entity.light_cols[0]){
				col = col >= FADE_STEP ? col - FADE_STEP : 0x00000000;
				if(col < entity.light_cols[0]) col = entity.light_cols[0];
				dark_image.setPixel32(entity.map_x, entity.map_y, col);
			}
			
			// edge lighting code
			if(entity.map_x > 0 && (block_map[entity.map_y][entity.map_x - 1] & WALL)){
				vert_edge.x = -g.back_fx_image_holder.x + EDGE_OFFSET + (entity.map_x - 1) * SCALE;
				vert_edge.y = -g.back_fx_image_holder.y + entity.map_y * SCALE;
				edge_image.fillRect(vert_edge, EDGE_COL);
			}
			if(entity.map_y > 0 && (block_map[entity.map_y - 1][entity.map_x] & WALL)){
				horiz_edge.x = -g.back_fx_image_holder.x + entity.map_x * SCALE;
				horiz_edge.y = -g.back_fx_image_holder.y + EDGE_OFFSET + (entity.map_y - 1) * SCALE;
				edge_image.fillRect(horiz_edge, EDGE_COL);
			}
			if(entity.map_x < width - 1 && (block_map[entity.map_y][entity.map_x + 1] & WALL)){
				vert_edge.x = -g.back_fx_image_holder.x + (entity.map_x + 1) * SCALE;
				vert_edge.y = -g.back_fx_image_holder.y + entity.map_y * SCALE;
				edge_image.fillRect(vert_edge, EDGE_COL);
			}
			if(entity.map_y < height - 1 && (block_map[entity.map_y + 1][entity.map_x] & WALL)){
				horiz_edge.x = -g.back_fx_image_holder.x + entity.map_x * SCALE;
				horiz_edge.y = -g.back_fx_image_holder.y + (entity.map_y + 1) * SCALE;
				edge_image.fillRect(horiz_edge, EDGE_COL);
			}
		}
		/* Recursive shadow casting method - ported from the Python version here:
		 *
		 * http://roguebasin.roguelikedevelopment.org/index.php?title=Python_shadowcasting_implementation
		 *
		 * optimisations include lookup tables, ditching redundant variables and inlining
		 */
		public function castLight(cx:int, cy:int, row:int, start:Number, end:Number, radius:int, xx:int, xy:int, yx:int, yy:int, light_cols:Vector.<uint>, update_minimap:Boolean):void{
		
			var new_start:Number;
			var dx:int, dy:int;
			var block:Boolean;
			var map_x:int, map_y:int;
			var dist:int;
			var l_slope:Number, r_slope:Number;
			var col:uint;

			if(start < end) return;

			for(var j:int = row; j < radius + 1; j++){
				dx = -j - 1;
				dy = -j;
				block = false;
				while(dx <= 0){
					dx++;
					// Translate the dx, dy coordinates into map coordinates:

					map_x = cx + dx * xx + dy * xy;
					map_y = cy + dx * yx + dy * yy;

					// l_slope and r_slope store the slopes of the left and right
					// extremities of the square we're considering:

					l_slope = l_slopes[MAX_RADIUS + dy][MAX_RADIUS + dx];
					r_slope = r_slopes[MAX_RADIUS + dy][MAX_RADIUS + dx];
					
					if(start < r_slope) continue;

					else if(end > l_slope) break;

					else{
					// Our light beam is touching this square; light it:
						dist = dists[MAX_RADIUS + dx][MAX_RADIUS + dy];
						//if(dx * dx + dy * dy < radius_squared){
						if(dist < radius){
							// this is where I take over and light my own map
							if(map_x > -1 && map_y > -1 && map_x < width && map_y < height){
								col = dark_image.getPixel32(map_x, map_y);
								if(col > light_cols[dist]){
									col = col >= FADE_STEP ? col - FADE_STEP : 0x00000000;
									if(col < light_cols[dist]) col = light_cols[dist];
									dark_image.setPixel32(map_x, map_y, col);
									// edge lighting code
									
									if(!(block_map[map_y][map_x] & WALL)){
										if(map_x > 0 && (block_map[map_y][map_x - 1] & WALL)){
											vert_edge.x = -g.back_fx_image_holder.x + EDGE_OFFSET + (map_x - 1) * SCALE;
											vert_edge.y = -g.back_fx_image_holder.y + map_y * SCALE;
											edge_image.fillRect(vert_edge, EDGE_COL - col);
										}
										if(map_y > 0 && (block_map[map_y - 1][map_x] & WALL)){
											horiz_edge.x = -g.back_fx_image_holder.x + map_x * SCALE;
											horiz_edge.y = -g.back_fx_image_holder.y + EDGE_OFFSET + (map_y - 1) * SCALE;
											edge_image.fillRect(horiz_edge, EDGE_COL - col);
										}
										if(map_x < width - 1 && (block_map[map_y][map_x + 1] & WALL)){
											vert_edge.x = -g.back_fx_image_holder.x + (map_x + 1) * SCALE;
											vert_edge.y = -g.back_fx_image_holder.y + map_y * SCALE;
											edge_image.fillRect(vert_edge, EDGE_COL - col);
										}
										if(map_y < height - 1 && (block_map[map_y + 1][map_x] & WALL)){
											horiz_edge.x = -g.back_fx_image_holder.x + map_x * SCALE;
											horiz_edge.y = -g.back_fx_image_holder.y + (map_y + 1) * SCALE;
											edge_image.fillRect(horiz_edge, EDGE_COL - col);
										}
									}
									
									
									if(update_minimap){
										if(!(block_map[map_y][map_x] & WALL)) g.mini_map.data.setPixel32(map_x, map_y, MINI_MAP_COL);
									}
								}
								
							}
						}
						if(block){
							// we're scanning a row of blocked squares:
							if(map_x < 0 || map_y < 0 || map_x >= width || map_y >= height || (block_map[map_y][map_x] & WALL)){
								new_start = r_slope;
								continue;
							} else{
								block = false;
								start = new_start;
							}
						} else {
							if((map_x < 0 || map_y < 0 || map_x >= width || map_y >= height || (block_map[map_y][map_x] & WALL)) && j < radius){
								// This is a blocking square, start a child scan:
								block = true;
								castLight(cx, cy, j+1, start, l_slope, radius, xx, xy, yx, yy, light_cols, update_minimap)
								new_start = r_slope;
							}
						}
					}
				}
				// Row is scanned; do next row unless last square was blocked:
				if (block) break;
			}
		}
		
		
		/* Add a GameObject to the lighting queue */
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
			entity.light_cols = new Vector.<uint>(temp_radius + 1);
			var col:uint = 0xFF000000;
			var prev_col:uint = col;
			for(var i:int = temp_radius + 1; i > -1; i--, col -= 0x01000000 * step){
				if(prev_col < col) col = 0x00000000;
				entity.light_cols[i] = col;
				prev_col = col;
			}
			entity.light_cols[0] = 0xFF000000 - (0x01000000 * strength);
		}
		/* Create look up tables */
		public function getTables(radius:int):void{
			dists = Map.createGrid(0, 1 + radius * 2, 1 + radius * 2);
			r_slopes = Map.createGrid(0, 1 + radius * 2, 1 + radius * 2);
			l_slopes = Map.createGrid(0, 1 + radius * 2, 1 + radius * 2);
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
					l_slopes[r][c] = (vx - 0.5) / (vy + 0.5);
					r_slopes[r][c] = (vx + 0.5) / (vy - 0.5);
				}
			}
		}
		
	}
	
}