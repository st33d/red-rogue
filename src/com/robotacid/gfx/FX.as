package com.robotacid.gfx {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	/**
	* Self managing BlitClip wrapper
	* Accounts for Blit being projected onto tracking the viewport and
	* self terminates after animation is complete
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class FX extends Point{
		
		public var blit:BlitRect;
		public var g:Game
		public var frame:int;
		public var active:Boolean;
		public var imageHolder:Bitmap;
		public var image:BitmapData;
		public var dir:Point;
		public var looped:Boolean;
		
		public function FX(x:Number, y:Number, blit:BlitRect, image:BitmapData, imageHolder:Bitmap, g:Game, dir:Point = null, delay:int = 0, looped:Boolean = false) {
			super(x, y);
			this.blit = blit;
			this.image = image;
			this.imageHolder = imageHolder;
			this.g = g;
			this.dir = dir;
			this.looped = looped;
			frame = 0 - delay;
			active = true;
		}
		
		public function main():void {
			if(frame > -1){
				blit.x = ( -imageHolder.x) + x;
				blit.y = ( -imageHolder.y) + y;
				// just trying to ease the collosal rendering requirements going on
				if(blit.x + blit.dx + blit.width >= 0 &&
					blit.y + blit.dy + blit.height >= 0 &&
					blit.x + blit.dx <= imageHolder.width &&
					blit.y + blit.dy <= imageHolder.height){
					blit.render(image, frame++);
				} else {
					frame++;
				}
				if(blit is BlitClip && frame == (blit as BlitClip).totalFrames){
					if(!looped) active = false;
					else frame = 0;
				}
				if(blit is FadingBlitRect && frame == (blit as FadingBlitRect).totalFrames){
					if(!looped) active = false;
					else frame = 0;
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