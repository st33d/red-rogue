package com.robotacid.ui {
	import com.robotacid.gfx.BlitClip;
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.FadingBlitRect;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * An effect that appears on the minimap
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class MinimapFX extends Point{
		
		public var blit:BlitRect;
		public var frame:int;
		public var active:Boolean;
		public var view:Rectangle;
		public var bitmapData:BitmapData;
		public var dir:Point;
		public var looped:Boolean;
		
		public function MinimapFX(x:Number, y:Number, blit:BlitRect, bitmapData:BitmapData, view:Rectangle, dir:Point = null, delay:int = 0, looped:Boolean = false) {
			super(x, y);
			this.blit = blit;
			this.bitmapData = bitmapData;
			this.view = view;
			this.dir = dir;
			this.looped = looped;
			frame = 0 - delay;
			active = true;
		}
		
		public function main():void {
			if(frame > -1){
				blit.x = ( -view.x) + x;
				blit.y = ( -view.y) + y;
				// just trying to ease the collosal rendering requirements going on
				if(blit.x + blit.dx + blit.width >= 0 &&
					blit.y + blit.dy + blit.height >= 0 &&
					blit.x + blit.dx <= view.width &&
					blit.y + blit.dy <= view.height){
					blit.render(bitmapData, frame++);
				} else {
					frame++;
				}
				if(frame == blit.totalFrames){
					if(looped) frame = 0;
					else active = false;
				}
			} else {
				frame++;
			}
			if(dir){
				x += dir.x;
				y += dir.y;
			}
		}
		
	}

}