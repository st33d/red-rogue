package com.robotacid.gfx {
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	/**
	* Self managing BlitClip wrapper
	* Accounts for Blit being projected onto tracking the viewport and
	* self terminates after animation is complete
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class FX extends Point{
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		public var blit:BlitRect;
		public var frame:int;
		public var active:Boolean;
		public var bitmap:DisplayObject;
		public var bitmapData:BitmapData;
		public var dir:Point;
		public var looped:Boolean;
		
		public function FX(x:Number, y:Number, blit:BlitRect, bitmapData:BitmapData, bitmap:DisplayObject, dir:Point = null, delay:int = 0, looped:Boolean = false) {
			super(x, y);
			this.blit = blit;
			this.bitmapData = bitmapData;
			this.bitmap = bitmap;
			this.dir = dir;
			this.looped = looped;
			frame = 0 - delay;
			active = true;
		}
		
		public function main():void {
			if(frame > -1){
				blit.x = ( -bitmap.x) + x;
				blit.y = ( -bitmap.y) + y;
				// just trying to ease the collosal rendering requirements going on
				if(blit.x + blit.dx + blit.width >= 0 &&
					blit.y + blit.dy + blit.height >= 0 &&
					blit.x + blit.dx <= bitmap.width &&
					blit.y + blit.dy <= bitmap.height){
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