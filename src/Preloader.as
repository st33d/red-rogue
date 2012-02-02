package {
	import com.robotacid.ui.ProgressBar;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.utils.getDefinitionByName;
	
	[SWF(width = "640", height = "480", frameRate="30", backgroundColor = "#000000")]
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class Preloader extends MovieClip {
		
		public var bar:ProgressBar;
		public var focusPrompt:Boolean;
		
		public function Preloader() {
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			addEventListener(Event.ENTER_FRAME, checkFrame);
			focusPrompt = true;
			stage.addEventListener(Event.ACTIVATE, onFocus);
			loaderInfo.addEventListener(ProgressEvent.PROGRESS, progress);
            stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			// show loader
			bar = new ProgressBar(0, 0, 100, 10);
			bar.barCol = 0xFFAA0000;
			bar.setValue(0, 1);
			bar.scaleX = bar.scaleY = 2;
			bar.x = 320 - bar.width * 0.5;
			bar.y = 240 - bar.height * 0.5;
			addChild(bar);
		}
		
		private function progress(e:ProgressEvent):void {
			// update loader
			bar.setValue(root.loaderInfo.bytesLoaded / root.loaderInfo.bytesTotal, 1);
		}
		
		private function checkFrame(e:Event):void {
			if(currentFrame == totalFrames){
				removeEventListener(Event.ENTER_FRAME, checkFrame);
				startup();
			}
		}
		
		private function startup():void {
			// hide loader
			removeChild(bar);
			stop();
			loaderInfo.removeEventListener(ProgressEvent.PROGRESS, progress);
			var mainClass:Class = getDefinitionByName("Game") as Class;
			var game:* = new mainClass();
			game.forceFocus = focusPrompt;
			addChild(game as DisplayObject);
		}
		
		/* This is a double hack to get around the force focus hack not working with
		 * a pre-loader */
		private function onFocus(e:Event = null):void{
			focusPrompt = false;
			stage.removeEventListener(Event.ACTIVATE, onFocus);
		}
		
	}
	
}