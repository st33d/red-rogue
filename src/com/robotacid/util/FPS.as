package com.robotacid.util {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	/**
	 * Frames Per Second
	 *
	 * I've gone for a very simple implementation, seeing as I'm not sending results to NASA
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class FPS {
		
		public static var value:int;
		
		private static var frames:int;
		private static var timer:Timer;
		private static var sprite:Sprite;
		
		public function FPS(){
		}
		
		public static function start():void{
			if(timer) return;

			frames = 0;
			timer = new Timer(1000);
			sprite = new Sprite();
			sprite.addEventListener(Event.ENTER_FRAME, enterFrame);
			timer.addEventListener(TimerEvent.TIMER, tick);
			timer.start();
		}
		
		public static function stop():void{
			sprite.removeEventListener(Event.ENTER_FRAME, enterFrame);
			timer.removeEventListener(TimerEvent.TIMER, tick);
			timer.stop();
			timer = null;
			sprite = null;
		}
		
		private static function enterFrame(e:Event):void{
			frames++;
		}
		
		private static function tick(e:TimerEvent):void{
			value = frames;
			frames = 0;
		}
		
	}

}