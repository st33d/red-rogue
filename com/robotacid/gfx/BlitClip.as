package com.robotacid.gfx {
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
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
		public var total_frames:int;
		
		public function BlitClip(mc:MovieClip, color_transform:ColorTransform = null) {
			super(mc);
			frames = new Vector.<BitmapData>();
			frames[0] = data;
			for (var i:int = 2; i < mc.totalFrames + 1; i++){
				mc.gotoAndStop(i);
				frames[i-1] = new BitmapData(Math.ceil(bounds.width), Math.ceil(bounds.height), true, 0x00000000);
				frames[i-1].draw(mc, new Matrix(1, 0, 0, 1, -bounds.left, -bounds.top), color_transform);
			}
			total_frames = mc.totalFrames;
		}
		override public function render(destination:BitmapData, frame:int = 0):void{
			p.x = x + dx;
			p.y = y + dy;
			destination.copyPixels(frames[frame], rect, p, null, null, true);
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
		
	}
	
}