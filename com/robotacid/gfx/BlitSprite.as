package com.robotacid.gfx {
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.BitmapFilter;
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
		
		public function BlitSprite(mc:DisplayObject, colorTransform:ColorTransform = null) {
			bounds = mc.getBounds(mc);
			data = new BitmapData(Math.ceil(bounds.width), Math.ceil(bounds.height), true, 0x00000000);
			data.draw(mc, new Matrix(1, 0, 0, 1, -bounds.left, -bounds.top), colorTransform);
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
			var invScale:Number = 1.0 / scale;
			var h:int = bitmaps.length;
			var w:int = bitmaps[0].length;
			// take point position
			p.x = x + dx;
			p.y = y + dy;
			// find bitmap boundaries in tiles
			var leftTileX:int = (p.x * invScale) >> 0;
			var topTileY:int = (p.y * invScale) >> 0;
			var rightTileX:int = ((p.x + width) * invScale) >> 0;
			var bottomTileY:int = ((p.y + height) * invScale) >> 0;
			
			// logically the bitmap will only be painted onto 1, 2 or 4 tiles, we can use conditionals for this
			// to speed things up
			// Of course with the option of scale, this could mean painting to many more bitmaps, and such a
			// task can fuck right off for the time being
			
			// only one tile to paint to
			if(leftTileX == rightTileX && topTileY == bottomTileY){
				if(leftTileX > -1 && leftTileX < w && topTileY > -1 && topTileY < h){
					mp.x = p.x - (scale * leftTileX);
					mp.y = p.y - (scale * topTileY);
					bitmaps[topTileY][leftTileX].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
			}
			// two tiles to paint to
			else if(leftTileX == rightTileX && topTileY != bottomTileY){
				if(leftTileX > -1 && leftTileX < w && topTileY > -1 && topTileY < h){
					mp.x = p.x - (scale * leftTileX);
					mp.y = p.y - (scale * topTileY);
					bitmaps[topTileY][leftTileX].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
				if(leftTileX > -1 && leftTileX < w && bottomTileY > -1 && bottomTileY < h){
					mp.x = p.x - (scale * leftTileX);
					mp.y = p.y - (scale * bottomTileY);
					bitmaps[bottomTileY][leftTileX].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
			} else if(leftTileX != rightTileX && topTileY == bottomTileY){
				if(leftTileX > -1 && leftTileX < w && topTileY > -1 && topTileY < h){
					mp.x = p.x - (scale * leftTileX);
					mp.y = p.y - (scale * topTileY);
					bitmaps[topTileY][leftTileX].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
				if(rightTileX > -1 && rightTileX < w && topTileY > -1 && topTileY < h){
					mp.x = p.x - (scale * rightTileX);
					mp.y = p.y - (scale * topTileY);
					bitmaps[topTileY][rightTileX].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
			}
			// four tiles to paint to
			else if(leftTileX != rightTileX && topTileY != bottomTileY){
				if(leftTileX > -1 && leftTileX < w && topTileY > -1 && topTileY < h){
					mp.x = p.x - (scale * leftTileX);
					mp.y = p.y - (scale * topTileY);
					bitmaps[topTileY][leftTileX].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
				if(rightTileX > -1 && rightTileX < w && topTileY > -1 && topTileY < h){
					mp.x = p.x - (scale * rightTileX);
					mp.y = p.y - (scale * topTileY);
					bitmaps[topTileY][rightTileX].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
				if(leftTileX > -1 && leftTileX < w && bottomTileY > -1 && bottomTileY < h){
					mp.x = p.x - (scale * leftTileX);
					mp.y = p.y - (scale * bottomTileY);
					bitmaps[bottomTileY][leftTileX].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
				if(rightTileX > -1 && rightTileX < w && bottomTileY > -1 && bottomTileY < h){
					mp.x = p.x - (scale * rightTileX);
					mp.y = p.y - (scale * bottomTileY);
					bitmaps[bottomTileY][rightTileX].bitmapData.copyPixels(data, rect, mp, null, null, true);
				}
			}
			
		}
		/* Applies a filter to the bitmapdata, the start and finish variables are for the BlitClip class */
		public function applyFilter(filter:BitmapFilter, start:int = 0, finish:int = int.MAX_VALUE):void{
			p = new Point();
			data.applyFilter(data, data.rect, p, filter);
		}
		
	}
	
}