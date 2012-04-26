package com.robotacid.gfx {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	
	/**
	 * Wrapper for a Bitmap created to capture a DisplayObject
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class CaptureBitmap extends Bitmap {
		
		public function CaptureBitmap(bitmapData:BitmapData = null) {
			super(bitmapData ? bitmapData : new BitmapData(1, 1, true, 0x0));
		}
		
		public function capture(target:DisplayObject, matrix:Matrix = null, width:int = 0, height:int = 0):void{
			if(width == 0 || height == 0){
				if(bitmapData.width != target.width || bitmapData.height != target.height){
					bitmapData = new BitmapData(target.width, target.height, bitmapData.transparent, 0x0);
				}
			} else {
				bitmapData = new BitmapData(width, height, bitmapData.transparent, 0x0);
			}
			bitmapData.draw(target, matrix);
			x = target.x;
			y = target.y;
		}
		
	}

}