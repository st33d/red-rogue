package com.robotacid.gfx {
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	
	/**
	 * Renders rune-like writing
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class WritingBlit extends BlitClip {
		
		public var chars:Array/*int*/;
		
		// strokes
		public static const BOTTOM_RIGHT:int = 1 << 0;
		public static const TOP_LEFT:int = 1 << 1;
		public static const BOTTOM_LEFT:int = 1 << 2;
		public static const TOP_RIGHT:int = 1 << 3;
		
		public static const TRACKING:Number = 5;
		
		public function WritingBlit(mc:MovieClip = null) {
			super(mc, null);
		}
		
		/* Renders the current string of chars */
		override public function render(destination:BitmapData, frame:int = 0):void {
			p.x = x + dx;
			p.y = y + dy;
			var i:int, j:int, char:int;
			for(i = 0; i < chars.length; i++){
				char = chars[i];
				for(j = 0; j < totalFrames; j++){
					if(char & (1 << j)) destination.copyPixels(frames[j], rect, p, null, null, true);
				}
				p.x += TRACKING;
			}
		}
		
		
		
	}

}