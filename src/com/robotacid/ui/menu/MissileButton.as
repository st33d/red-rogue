package com.robotacid.ui.menu {
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class MissileButton extends MissileButtonMC{
		
		public static var game:Game;
		public static var addListeners:Function;
		public static var removeListeners:Function;
		
		public var hotKeyMap:HotKeyMap;
		public var disabled:Boolean;
		
		public function MissileButton():void {
			if(Boolean(addListeners)){
				addListeners(this);
			} else {
				addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
				game.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
			}
			visible = false;
			disabled = false;
		}
		
		/* We generate a HotKeyMap as an instruction for the Menu to execute */
		public function initHotKey(menu:Menu):void{
			hotKeyMap = new HotKeyMap(0, menu);
			hotKeyMap.init(<hotKey><branch selection="0" name="actions" context="null"/><branch selection="3" name="shoot" context="missile"/></hotKey>);
		}
		
		public function setDisabled(value:Boolean):void{
			disabled = value;
			alpha = value ? 0.5 : 1;
		}
		
		public function onMouseUp(e:Event):void{
			// don't interrupt animations
			if(currentLabel == "over"){
				gotoAndStop("up");
			}
		}
		
		public function onMouseDown(e:Event):void{
			if(disabled) return;
			gotoAndStop("over");
			if(!Game.dialog){
				hotKeyMap.execute();
			}
		}
		
		public function ping():void{
			visible = true;
			gotoAndPlay("once");
		}
		
		public function alert():void{
			visible = true;
			gotoAndPlay("loop");
		}
		
		public function hide():void{
			visible = false;
		}
		
		public function destroy():void{
			if(Boolean(removeListeners)) removeListeners(this);
			if(stage) stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			if(parent) parent.removeChild(this);
		}
		
	}

}