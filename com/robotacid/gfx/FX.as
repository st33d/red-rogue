package com.robotacid.gfx {
	import com.robotacid.geom.Dot;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	/**
	* Self managing BlitClip wrapper
	* Accounts for Blit being projected onto tracking the viewport and
	* self terminates after animation is complete
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class FX extends Dot{
		
		public var blit:BlitRect;
		public var g:Game
		public var frame:int;
		public var active:Boolean;
		public var image_holder:Bitmap;
		public var image:BitmapData;
		public var dir:Dot;
		public var looped:Boolean;
		
		public function FX(x:Number, y:Number, blit:BlitRect, image:BitmapData, image_holder:Bitmap, g:Game, dir:Dot = null, delay:int = 0, looped:Boolean = false) {
			super(x, y);
			this.blit = blit;
			this.image = image;
			this.image_holder = image_holder;
			this.g = g;
			this.dir = dir;
			this.looped = looped;
			frame = 0 - delay;
			active = true;
		}
		
		public function main():void {
			if(frame > -1){
				blit.x = ( -image_holder.x) + x;
				blit.y = ( -image_holder.y) + y;
				// just trying to ease the collosal rendering requirements going on
				if(blit.x + blit.dx + blit.width >= 0 &&
					blit.y + blit.dy + blit.height >= 0 &&
					blit.x + blit.dx <= image_holder.width &&
					blit.y + blit.dy <= image_holder.height){
					blit.render(image, frame++);
				} else {
					frame++;
				}
				if(blit is BlitClip && frame == (blit as BlitClip).total_frames){
					if(!looped) active = false;
					else frame = 0;
				}
				if(blit is FadingBlitRect && frame == (blit as FadingBlitRect).total_frames){
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