package com.robotacid.gfx {
	
	import com.robotacid.gfx.BlitRect;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.filters.BitmapFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	* Provides a less cpu intensive version of a MovieClip
	* Ideal for particles, but not for complex animated characters or large animations
	* Expands on BlitSprite by hosting an array of bitmapdatas as frames
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class BlitClip extends BlitSprite{
		
		public var frames:Vector.<BitmapData>;
		
		public function BlitClip(mc:MovieClip = null, colorTransform:ColorTransform = null) {
			frames = new Vector.<BitmapData>();
			if(mc){
				super(mc);
				frames[0] = data;
				for (var i:int = 2; i < mc.totalFrames + 1; i++){
					mc.gotoAndStop(i);
					frames[i-1] = new BitmapData(Math.ceil(bounds.width), Math.ceil(bounds.height), true, 0x0);
					frames[i-1].draw(mc, new Matrix(1, 0, 0, 1, -bounds.left, -bounds.top), colorTransform);
				}
				totalFrames = mc.totalFrames;
			}
		}
		/* Returns a a copy of this object, must be cast into a BlitClip */
		override public function clone():BlitRect {
			var blit:BlitClip = new BlitClip();
			blit.data = data.clone();
			blit.totalFrames = totalFrames;
			blit.frames.push(blit.data);
			for(var i:int = 1; i < totalFrames; i++){
				blit.frames.push(frames[i].clone());
			}
			blit.x = x;
			blit.y = y;
			blit.dx = dx;
			blit.dy = dy;
			blit.width = width;
			blit.height = height;
			blit.rect = new Rectangle(0, 0, width, height);
			blit.col = col;
			return blit;
		}
		override public function render(destination:BitmapData, frame:int = 0):void{
			p.x = x + dx;
			p.y = y + dy;
			destination.copyPixels(frames[frame], rect, p, null, null, true);
		}
		/* Paints a channel from the bitmapData to the destination */
		override public function renderChannel(destination:BitmapData, sourceChannel:uint, destChannel:uint, frame:int = 0):void{
			p.x = x + dx;
			p.y = y + dy;
			destination.copyChannel(frames[frame], rect, p, sourceChannel, destChannel);
		}
		/* Paints the bitmapData to the destination using the alphaBitmapData's alpha channel*/
		override public function renderAlpha(destination:BitmapData, alphaBitmapData:BitmapData, alphaPoint:Point, frame:int = 0):void{
			p.x = x + dx;
			p.y = y + dy;
			destination.copyPixels(frames[frame], rect, p, alphaBitmapData, alphaPoint, true);
		}
		/* Paints the bitmapData to the destination using the merge method */
		override public function renderMerge(destination:BitmapData, redMultiplier:uint, greenMultiplier:uint, blueMultiplier:uint, alphaMultiplier:uint, frame:int = 0):void{
			p.x = x + dx;
			p.y = y + dy;
			destination.merge(frames[frame], rect, p, redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier);
		}
		/* Given a plane of multiple bitmaps that have been tiled together, calculate which bitmap(s) this
		 * should appear on and render to as many as required to compensate for tiling
		 *
		 * Assumes that bitmaps is a 2d array of tiled bitmapdatas
		 */
		override public function multiRender(bitmaps:Vector.<Vector.<Bitmap>>, scale:int = 2880, frame:int = 0):void {
			super.multiRender(bitmaps, scale, frame);
		}
		/* Does a comparison on all frames so that multiple identical frames can be reduced to one reference */
		public function compress():void{
			if(frames.length < 2) return;
			for(var i:int = 0; i < frames.length; i++){
				for(var j:int = i + 1; j < frames.length; j++){
					if(i == j) continue;
					if(frames[i].compare(frames[j]) == 0) frames[i] = frames[j];
				}
			}
		}
		/* Applies a filter to a range of frames */
		override public function applyFilter(filter:BitmapFilter, start:int = 0, finish:int = int.MAX_VALUE):void {
			p = new Point();
			if(finish > totalFrames) finish = totalFrames - 1;
			for(var i:int = start; i <= finish; i++) {
				frames[i].applyFilter(frames[i], frames[i].rect, p, filter);
			}
		}
		
	}
	
}