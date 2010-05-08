package com.robotacid.gfx {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class BlitBackgroundClip extends Sprite{
		
		public var data:BitmapData;
		
		public var buffer:BitmapData;
		
		public var image_mask:BitmapData;
		
		public var rect:Rectangle;
		
		public static var g:Game;
		public static var image_holder:Bitmap;
		public static var image:BitmapData;
		public static var dx:Number;
		public static var dy:Number;
		public static var zero_point:Point = new Point();
		public static var point:Point = new Point();
		
		public static const CAPTURE_WIDTH:int = 18;
		public static const CAPTURE_HEIGHT:int = 18;
		
		public function BlitBackgroundClip() {
			if(!image_mask){
				g = Game.g;
				image_holder = g.front_fx_image_holder;
				image = g.front_fx_image;
				dx = -CAPTURE_WIDTH >> 1;
				dy = -CAPTURE_HEIGHT + 1;
			}
			image_mask = new BitmapData(CAPTURE_WIDTH, CAPTURE_HEIGHT, true, 0x00000000);
			data = new BitmapData(CAPTURE_WIDTH, CAPTURE_HEIGHT, true, 0x00000000);
			buffer = new BitmapData(CAPTURE_WIDTH, CAPTURE_HEIGHT, true, 0x00000000);
			rect = new Rectangle(0, 0, CAPTURE_WIDTH, CAPTURE_HEIGHT);
		}
		
		public function render():void{
			
			point.x = -image_holder.x + (parent.x + dx);
			point.y = -image_holder.y + (parent.y + dy);
			
			if(point.x + data.width > 0 && point.y + data.height > 0 && point.x < image.width && point.y < image.height){
			
				g.player_holder.visible = false;
				g.entities_holder.visible = false;
				g.light_map.bitmap.visible = false;
				
				// because we're calling this before the end of ENTER_FRAME we get a mask that's a frame late.
				// but because we only show a silhouette we ignore the lag by making the parent invisible
				// drawbacks:
				// leaves a mess when removed (the parent has visible set to false)
				parent.visible = true;
				image_mask.fillRect(image_mask.rect, 0x00000000);
				image_mask.draw(parent, new Matrix(parent.scaleX, 0, 0, 1, -dx, -dy));
				parent.visible = false;
				
				buffer.copyPixels(data, data.rect, zero_point);
				//data.draw(g.canvas, new Matrix(1, 0, 0, 1, -(parent.x + dx), -(parent.y + dy)));
				rect.x = (parent.x+dx)-g.tile_image_holder.x;
				rect.y = (parent.y+dy)-g.tile_image_holder.y;
				data.copyPixels(g.tile_image, rect, zero_point);
				data.copyChannel(image_mask, data.rect, zero_point, BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
				
				g.player_holder.visible = true;
				g.entities_holder.visible = true;
				g.light_map.bitmap.visible = true;
				
				image.copyPixels(buffer, data.rect, point, null, null, true);
			}
		}
		
	}

}