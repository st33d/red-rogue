package com.robotacid.ui {
	import com.robotacid.gfx.BlitClip;
	import flash.display.BitmapData;
	import flash.geom.Point;
	/**
	 * Indicates where a given Entity is on the map
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class MinimapFeature {
		
		public static var minimap:MiniMap;
		public static var revealBlit:BlitClip;
		
		public var blit:BlitClip;
		public var active:Boolean;
		public var x:Number;
		public var y:Number;
		
		private var searchRevealFrame:int;
		private var frame:int;
		
		private static var point:Point = new Point();
		
		public function MinimapFeature(x:Number, y:Number, blit:BlitClip, searchReveal:Boolean) {
			this.x = x;
			this.y = y;
			this.blit = blit;
			if(searchReveal) searchRevealFrame = revealBlit.totalFrames;
			frame = 0;
			active = true;
		}
		
		public function render():void {
			blit.x = ( -minimap.view.x) + x;
			blit.y = ( -minimap.view.y) + y;
			blit.render(minimap.window.bitmapData, frame++);
			if(frame >= blit.totalFrames) frame = 0;
			if(searchRevealFrame){
				revealBlit.x = ( -minimap.view.x) + x;
				revealBlit.y = ( -minimap.view.y) + y;
				revealBlit.render(minimap.window.bitmapData, revealBlit.totalFrames - searchRevealFrame);
				searchRevealFrame--;
			}
		}
	}

}