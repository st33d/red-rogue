package {
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.display.MovieClip;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.TouchEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.media.AudioPlaybackMode;
	import flash.media.SoundMixer;
	import flash.system.Capabilities;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import com.robotacid.ui.menu.MenuButton;
	import com.robotacid.ui.menu.MissileButton;
	
	/**
	 * Wrapper that activates mobile version of the game
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Main extends Sprite {
		
		public var game:Game;
		
		public function Main():void {
			//stage.scaleMode = StageScaleMode.NO_SCALE;
			//stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.DEACTIVATE, deactivate);
			
			// touch or gesture?
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			
			MenuButton.addListeners = addTouchListeners;
			MissileButton.addListeners = addTouchListeners;
			MenuButton.removeListeners = removeTouchListeners;
			MissileButton.removeListeners = removeTouchListeners;
			
			// handle Android sleep - exits application
			//NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
			NativeApplication.nativeApplication.addEventListener(Event.DEACTIVATE, deactivate);
			
			// iOS mute
			//SoundMixer.audioPlaybackMode = AudioPlaybackMode.AMBIENT;
			
			// entry point
			//Game.MOBILE = !Capabilities.isDebugger;
			//Library.loadUserLevelsCallback = libraryLoad;
			//Library.saveUserLevelsCallback = librarySave;
			// these don't work on some Android devices
			//UserData.fileLoadCallback = settingsLoad;
			//UserData.fileSaveCallback = settingsSave;
			
			Game.MOBILE = true;
			game = new Game();
			addChild(game);
			
			game.scaleX = game.scaleY = 1;
			stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			stage.fullScreenSourceRect = new Rectangle(0, 0, Game.WIDTH, Game.HEIGHT);
		}
		
		public function addTouchListeners(instance:MovieClip):void{
			instance.addEventListener(TouchEvent.TOUCH_BEGIN, instance.onMouseDown, false, 0, true);
			game.stage.addEventListener(TouchEvent.TOUCH_END, instance.onMouseUp, false, 0, true);
		}
		
		public function removeTouchListeners(instance:MovieClip):void{
			instance.removeEventListener(TouchEvent.TOUCH_BEGIN, instance.onMouseDown);
			game.stage.removeEventListener(TouchEvent.TOUCH_END, instance.onMouseUp);
		}
		
		private function deactivate(e:Event):void {
			// auto-close
			//Game.game.saveProgress(true);
			//NativeApplication.nativeApplication.exit();
		}
		
		//private function librarySave():void{
			//try{
				//var str:String = JSON.stringify(Library.levels);
				//var file:File = File.documentsDirectory.resolvePath("levels.json");
				//var writeStream:FileStream = new FileStream();
				//writeStream.open(file, FileMode.WRITE);
				//writeStream.writeUTFBytes(str);
				//writeStream.close();
			//} catch(e:Error){
				//
			//}
		//}
		//
		//private function libraryLoad():void{
			//try{
				//var file:File = File.documentsDirectory.resolvePath("levels.json");
				//var readStream:FileStream = new FileStream();
				//readStream.open(file, FileMode.READ);
				//var str:String = readStream.readUTFBytes(file.size);
				//Library.USER_LEVELS = JSON.parse(str) as Array;
				//readStream.close();
			//} catch(e:Error){
			//}
		//}
		//
		//private function settingsSave(obj:Object):void{
			//try{
				//var str:String = JSON.stringify(obj);
				//var file:File = File.documentsDirectory.resolvePath("settings.json");
				//var writeStream:FileStream = new FileStream();
				//writeStream.open(file, FileMode.WRITE);
				//writeStream.writeUTFBytes(str);
				//writeStream.close();
			//} catch(e:Error){
				//
			//}
		//}
		//
		//private function settingsLoad():Object{
			//var obj:Object;
			//try{
				//var file:File = File.documentsDirectory.resolvePath("settings.json");
				//var readStream:FileStream = new FileStream();
				//readStream.open(file, FileMode.READ);
				//var str:String = readStream.readUTFBytes(file.size);
				//obj = JSON.parse(str);
				//readStream.close();
			//} catch(e:Error){
			//}
			//return obj;
		//}
		
	}
	
}