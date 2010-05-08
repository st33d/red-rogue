package com.robotacid.gfx {
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	* Provides a less cpu intensive version of a Sprite
	* Ideal for particles, but not for complex animated characters or large animations
	* Also operates as a super class to BlitClip
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class BlitSprite extends BlitRect{
		
		public var data:BitmapData;
		
		public static var mp:Point = new Point();
		public static var bounds:Rectangle;
		
		public function BlitSprite(mc:DisplayObject, color_transform:ColorTransform = null) {
			bounds = mc.getBounds(mc);
			data = new BitmapData(Math.ceil(bounds.width), Math.ceil(bounds.height), true, 0x00000000);
			data.draw(mc, new Matrix(1, 0, 0, 1, -bounds.left, -bounds.top), color_transform);
			super(bounds.left, bounds.top, Math.ceil(bounds.width), Math.ceil(bounds.height));
		}
		override public function render(destination:BitmapData, frame:int = 0):void{
			p.x = x + dx;
			p.y = y + dy;
			destination.copyPixels(data, rect, p, null, null, true);
		}
		/* Given a plane of multiple bitmaps that have been tiled together, calculate which bitmap(s) this
		 * should appear on and render to as many as required to compensate for tiling
		 * 
		 * bitmaps is a 2d Vector of tiled bitmapdatas
		 */
		override public function multiRender(bitmaps:Vector.<Vector.<Bitmap>>, scale:int = 2880, frame:int = 0):void{
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
					mp.x = p.x - (scale * left_tile_x);
					mp.y = p.y - (scale * top_tile_y);
					bitmaps[top_tile_y][left_tile_x].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
			}
			// two tiles to paint to
			else if(left_tile_x == right_tile_x && top_tile_y != bottom_tile_y){
				if(left_tile_x > -1 && left_tile_x < w && top_tile_y > -1 && top_tile_y < h){
					mp.x = p.x - (scale * left_tile_x);
					mp.y = p.y - (scale * top_tile_y);
					bitmaps[top_tile_y][left_tile_x].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
				if(left_tile_x > -1 && left_tile_x < w && bottom_tile_y > -1 && bottom_tile_y < h){
					mp.x = p.x - (scale * left_tile_x);
					mp.y = p.y - (scale * bottom_tile_y);
					bitmaps[bottom_tile_y][left_tile_x].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
			} else if(left_tile_x != right_tile_x && top_tile_y == bottom_tile_y){
				if(left_tile_x > -1 && left_tile_x < w && top_tile_y > -1 && top_tile_y < h){
					mp.x = p.x - (scale * left_tile_x);
					mp.y = p.y - (scale * top_tile_y);
					bitmaps[top_tile_y][left_tile_x].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
				if(right_tile_x > -1 && right_tile_x < w && top_tile_y > -1 && top_tile_y < h){
					mp.x = p.x - (scale * right_tile_x);
					mp.y = p.y - (scale * top_tile_y);
					bitmaps[top_tile_y][right_tile_x].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
			}
			// four tiles to paint to
			else if(left_tile_x != right_tile_x && top_tile_y != bottom_tile_y){
				if(left_tile_x > -1 && left_tile_x < w && top_tile_y > -1 && top_tile_y < h){
					mp.x = p.x - (scale * left_tile_x);
					mp.y = p.y - (scale * top_tile_y);
					bitmaps[top_tile_y][left_tile_x].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
				if(right_tile_x > -1 && right_tile_x < w && top_tile_y > -1 && top_tile_y < h){
					mp.x = p.x - (scale * right_tile_x);
					mp.y = p.y - (scale * top_tile_y);
					bitmaps[top_tile_y][right_tile_x].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
				if(left_tile_x > -1 && left_tile_x < w && bottom_tile_y > -1 && bottom_tile_y < h){
					mp.x = p.x - (scale * left_tile_x);
					mp.y = p.y - (scale * bottom_tile_y);
					bitmaps[bottom_tile_y][left_tile_x].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
				if(right_tile_x > -1 && right_tile_x < w && bottom_tile_y > -1 && bottom_tile_y < h){
					mp.x = p.x - (scale * right_tile_x);
					mp.y = p.y - (scale * bottom_tile_y);
					bitmaps[bottom_tile_y][right_tile_x].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
			}
			
		}
		
	}
	
}