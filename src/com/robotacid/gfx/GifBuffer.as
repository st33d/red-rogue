package com.robotacid.gfx {
	import com.robotacid.ui.FileManager;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Matrix;
	import org.bytearray.gif.encoder.GIFEncoder;
	/**
	 * Records an animated gif
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class GifBuffer {
		
		public var game:Game;
		
		public var active:Boolean;
		public var width:int;
		public var height:int;
		public var frames:Vector.<BitmapData>;
		public var duration:int;
		public var target:DisplayObject;
		
		private var bitmapData:BitmapData;
		private var matrix:Matrix;
		
		public function GifBuffer(width:int, height:int, duration:int, target:DisplayObject, game:Game) {
			this.width = width;
			this.height = height;
			this.duration = duration;
			this.target = target;
			this.game = game;
			frames = new Vector.<BitmapData>();
			matrix = new Matrix();
			active = false;
		}
		
		public function activate():void{
			active = true;
		}
		
		public function deactivate():void{
			active = false;
			frames.length = 0;
		}
		
		public function record(x:int, y:int):void{
			bitmapData = new BitmapData(width, height, true, 0xFF000000);
			matrix.identity();
			matrix.translate( -x, -y);
			matrix.scale(2, 2);
			bitmapData.draw(target, matrix);
			frames.push(bitmapData);
			if(frames.length > duration){
				frames.shift();
			}
		}
		
		public function save():void{
			var encoder:GIFEncoder = new GIFEncoder();
			encoder.setRepeat(0);
			encoder.setDelay(35);
			encoder.start();
			for(var i:int = 0; i < frames.length; i++){
				encoder.addFrame(frames[i]);
			}
			encoder.finish();
			FileManager.save(encoder.stream, "anim.gif");
		}
		
	}

}