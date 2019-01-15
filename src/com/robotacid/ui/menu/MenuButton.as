package com.robotacid.ui.menu {
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class MenuButton extends MenuButtonMC{
		
		public static var game:Game;
		public static var addListeners:Function;
		public static var removeListeners:Function;
		
		public function MenuButton() {
			if(Boolean(addListeners)){
				addListeners(this);
			} else {
				addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
				game.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
			}
		}
		
		public function onMouseUp(e:Event):void{
			// don't interrupt animations
			if(currentLabel == "over"){
				gotoAndStop("up");
			}
		}
		
		public function onMouseDown(e:Event):void{
			gotoAndStop("over");
			if(!Game.dialog){
				Game.game.mousePressed = false;
				game.menuToggle();
			}
		}
		
		public function ping():void{
			gotoAndPlay("once");
		}
		
		public function alert():void{
			gotoAndPlay("loop");
		}
		
		public function destroy():void{
			if(Boolean(removeListeners)) removeListeners(this);
			if(stage) stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			if(parent) parent.removeChild(this);
		}
		
	}

}