package com.robotacid.gfx {
	import com.robotacid.gfx.BlitRect;
	import flash.display.BitmapData;
	
	/**
	 * A hacky method for fading squares of colour
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class FadingBlitRect extends BlitRect{
		
		public var frames:Array;
		public var total_frames:int;
		
		public function FadingBlitRect(dx:int = 0, dy:int = 0, width:int = 1, height:int = 1, total_frames:int = 1, col:uint = 0xFF000000) {
			super(dx, dy, width, height, col);
			frames = [];
			this.total_frames = total_frames;
			var step:int = 255 / total_frames;
			for(var i:int = 0; i < total_frames; i++) {
				frames[i] = new BitmapData(width, height, true, col - 0x01000000 * i * step);
			}
		}
		
		override public function render(destination:BitmapData, frame:int = 0):void {
			p.x = x + dx;
			p.y = y + dy;
			destination.copyPixels(frames[frame], rect, p, null, null, true);
		}
		
	}

}