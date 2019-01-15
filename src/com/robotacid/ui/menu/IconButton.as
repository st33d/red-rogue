package com.robotacid.ui.menu 
{
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class IconButton extends MovieClip {
		
		public static var game:Game;
		public static var addListeners:Function;
		public static var removeListeners:Function;
		
		public var hotKeyMap:HotKeyMap;
		public var disabled:Boolean;
		public var pressed:Bitmap;
		public var id:int;
		
		public static const SEARCH:int = 1;
		public static const DISARM:int = 2;
		[Embed(source = "../../../../assets/button-down.png")] public var PressedB:Class;
		[Embed(source = "../../../../assets/search-button-up.png")] public var SearchB:Class;
		[Embed(source="../../../../assets/disarm-button-up.png")] public var DisarmB:Class;
		
		public function IconButton() {
			if(Boolean(addListeners)){
				addListeners(this);
			} else {
				addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
				game.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
			}
			disabled = false;
		}
		
		public function setId(id:int):void{
			this.id = id;
			x = Game.WIDTH - width
			y = height + 1;
			
			var b:Bitmap;
			if(id == SEARCH){
				b = new SearchB();
			} else if(id == DISARM){
				b = new DisarmB();
			}
			addChild(b);
			pressed = new PressedB();
			addChild(pressed);
			pressed.visible = false;
		}
		
		
		/* We generate a HotKeyMap as an instruction for the Menu to execute */
		public function initHotKey(menu:Menu):void{
			hotKeyMap = new HotKeyMap(0, menu);
			if(id == SEARCH){
				hotKeyMap.init(<hotKey><branch selection="0" name="actions" context="null"/><branch selection="0" name="search"/></hotKey>);
			} else if(id == DISARM){
				hotKeyMap.init(<hotKey><branch selection="0" name="actions" context="null"/><branch selection="2" name="disarm"/></hotKey>);
			}
			
		}
		
		public function setDisabled(value:Boolean):void{
			disabled = value;
			alpha = value ? 0.5 : 1;
		}
		
		public function onMouseUp(e:Event):void{
			pressed.visible = false;
		}
		
		public function onMouseDown(e:Event):void{
			pressed.visible = true;
			if(!Game.dialog && !disabled){
				hotKeyMap.execute();
			}
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