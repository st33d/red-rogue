package com.robotacid.gfx {
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	* Provides a less cpu intensive version of a Sprite
	* Ideal for particles, but not for complex animated characters or large animations
	* Also operates as a super class to BlitSprite
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class BlitRect {
		
		public var x:int, y:int, width:int, height:int;
		public var dx:int, dy:int;
		public var rect:Rectangle;
		public var col:uint;
		
		public static var p:Point = new Point();
		
		public function BlitRect(dx:int = 0, dy:int = 0, width:int = 1, height:int = 1, col:uint = 0xFF000000) {
			x = y = 0;
			this.dx = dx;
			this.dy = dy;
			this.width = width;
			this.height = height;
			this.col = col;
			rect = new Rectangle(x, y, width, height);
		}
		public function render(destination:BitmapData, frame:int = 0):void{
			rect.x = x + dx;
			rect.y = y + dy;
			destination.fillRect(rect, col);
		}
		/* Given a plane of multiple bitmaps that have been tiled together, calculate which bitmap(s) this
		 * should appear on and render to as many as required to compensate for tiling
		 * 
		 * bitmaps is a 2d Vector of tiled bitmapdatas
		 */
		public function multiRender(bitmaps:Vector.<Vector.<Bitmap>>, scale:int = 2880, frame:int = 0):void{
			var inv_scale:Number = 1.0 / scale;
			var h:int = bitmaps.length;
			var w:int = bitmaps[0].length;
			// take point position
			p.x = x + dx;
			p.y = y + dy;
			// find bitmap boundaries in tiles
			var left_tile_x:int = (p.x * inv_scale) >> 0;
			var top_tile_y:int = (p.y * inv_scale) >> 0;
			var right_tile_x:int = ((p.x + width) * inv_scale) >> 0;
			var bottom_tile_y:int = ((p.y + height) * inv_scale) >> 0;
			
			// logically the bitmap will only be painted onto 1, 2 or 4 tiles, we can use conditionals for this
			// to speed things up
			// Of course with the option of scale, this could mean painting to many more bitmaps, and such a
			// task can fuck right off for the time being
			
			// only one tile to paint to
			if(left_tile_x == right_tile_x && top_tile_y == bottom_tile_y){
				if(left_tile_x > -1 && left_tile_x < w && top_tile_y > -1 && top_tile_y < h){
					rect.x = p.x - (scale * left_tile_x);
					rect.y = p.y - (scale * top_tile_y);
					bitmaps[top_tile_y][left_tile_x].bitmapData.fillRect(rect, col);
				}
			}
			// two tiles to paint to
			else if(left_tile_x == right_tile_x && top_tile_y != bottom_tile_y){
				if(left_tile_x > -1 && left_tile_x < w && top_tile_y > -1 && top_tile_y < h){
					rect.x = p.x - (scale * left_tile_x);
					rect.y = p.y - (scale * top_tile_y);
					bitmaps[top_tile_y][left_tile_x].bitmapData.fillRect(rect, col);
				}
				if(left_tile_x > -1 && left_tile_x < w && bottom_tile_y > -1 && bottom_tile_y < h){
					rect.x = p.x - (scale * left_tile_x);
					rect.y = p.y - (scale * bottom_tile_y);
					bitmaps[bottom_tile_y][left_tile_x].bitmapData.fillRect(rect, col);
				}
			} else if(left_tile_x != right_tile_x && top_tile_y == bottom_tile_y){
				if(left_tile_x > -1 && left_tile_x < w && top_tile_y > -1 && top_tile_y < h){
					rect.x = p.x - (scale * left_tile_x);
					rect.y = p.y - (scale * top_tile_y);
					bitmaps[top_tile_y][left_tile_x].bitmapData.fillRect(rect, col);
				}
				if(right_tile_x > -1 && right_tile_x < w && top_tile_y > -1 && top_tile_y < h){
					rect.x = p.x - (scale * right_tile_x);
					rect.y = p.y - (scale * top_tile_y);
					bitmaps[top_tile_y][right_tile_x].bitmapData.fillRect(rect, col);
				}
			}
			// four tiles to paint to
			else if(left_tile_x != right_tile_x && top_tile_y != bottom_tile_y){
				if(left_tile_x > -1 && left_tile_x < w && top_tile_y > -1 && top_tile_y < h){
					rect.x = p.x - (scale * left_tile_x);
					rect.y = p.y - (scale * top_tile_y);
					bitmaps[top_tile_y][left_tile_x].bitmapData.fillRect(rect, col);
				}
				if(right_tile_x > -1 && right_tile_x < w && top_tile_y > -1 && top_tile_y < h){
					rect.x = p.x - (scale * right_tile_x);
					rect.y = p.y - (scale * top_tile_y);
					bitmaps[top_tile_y][right_tile_x].bitmapData.fillRect(rect, col);
				}
				if(left_tile_x > -1 && left_tile_x < w && bottom_tile_y > -1 && bottom_tile_y < h){
					rect.x = p.x - (scale * left_tile_x);
					rect.y = p.y - (scale * bottom_tile_y);
					bitmaps[bottom_tile_y][left_tile_x].bitmapData.fillRect(rect, col);
				}
				if(right_tile_x > -1 && right_tile_x < w && bottom_tile_y > -1 && bottom_tile_y < h){
					rect.x = p.x - (scale * right_tile_x);
					rect.y = p.y - (scale * bottom_tile_y);
					bitmaps[bottom_tile_y][right_tile_x].bitmapData.fillRect(rect, col);
				}
			}
		}
		/* Creates an array of bitmaps to render to stitched together to compensate for the minimum bitmap size 
		 * 
		 * holder is the Sprite that will stand as parent to all these bitmaps
		 */
		public static function createMultiRenderArray(width:int, height:int, holder:Sprite, scale:int = 2880):Vector.<Vector.<Bitmap>>{
			var w:int = Math.ceil(width / scale);
			var h:int = Math.ceil(height / scale);
			var bitmaps:Vector.<Vector.<Bitmap>> = new Vector.<Vector.<Bitmap>>(h, true);
			var r:int, c:int;
			var bitmapdata:BitmapData, bitmap:Bitmap;
			var bitmap_width:int;
			var bitmap_height:int = scale;
			for(r = 0; r < height; r += scale){
				if(r + bitmap_height > height) bitmap_height = height - r;
				bitmaps[(r / scale) >> 0] = new Vector.<Bitmap>(w, true);
				bitmap_width = scale;
				for(c = 0; c < width; c += scale){
					if(c + bitmap_width > width) bitmap_width = width - c;
					bitmapdata = new BitmapData(bitmap_width, bitmap_height, true, 0x00000000);
					bitmap = new Bitmap(bitmapdata);
					bitmap.x = c;
					bitmap.y = r;
					bitmaps[(r / scale) >> 0][(c / scale) >> 0] = bitmap;
					holder.addChild(bitmap);
				}
			}
			return bitmaps;
		}
		
	}
	
}