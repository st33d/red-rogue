/**
* Keyboard input utility to overcome Adobe's marvellous security restrictions
* Outstanding bug with keys sticking that occurs once in a blue moon - still haven't caught it yet
*
* @author Aaron Steed, robotacid.com
* @version 1.1
*
* Adapted from http://www.kirupa.com/forum/showthread.php?p=2098269
*
* Comments from original follow:
*
* The Key class recreates functionality of
* Key.isDown of ActionScript 1 and 2. Before using
* Key.isDown, you first need to initialize the
* Key class with a reference to the stage using
* its Key.initialize() method. For key
* codes use the flash.ui.Keyboard class.
*
* Usage:
* Key.initialize(stage);
* if (Key.isDown(Keyboard.LEFT)) {
*    // Left key is being pressed
* }
*/

package com.robotacid.ui {
    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	public class Key {
		public static var initialized:Boolean = false;  // marks whether or not the class has been initialized
        private static var keysDown:Array = [];  // stores key codes of all keys pressed
		public static var custom:Array; // list of customised keys
		public static var reserved:Array = []; // list of reserved keys
		public static var lockOut:Boolean = false; // used to brick the Key class
		public static var stage:Stage;
		public static var keysPressed:int = 0;
		public static const NUMBER_0:int = 48;
		public static const NUMBER_1:int = 49;
		public static const NUMBER_2:int = 50;
		public static const NUMBER_3:int = 51;
		public static const NUMBER_4:int = 52;
		public static const NUMBER_5:int = 53;
		public static const NUMBER_6:int = 54;
		public static const NUMBER_7:int = 55;
		public static const NUMBER_8:int = 56;
		public static const NUMBER_9:int = 57;
		public static const A:int = 65;
		public static const B:int = 66;
		public static const C:int = 67;
		public static const D:int = 68;
		public static const E:int = 69;
		public static const F:int = 70;
		public static const G:int = 71;
		public static const H:int = 72;
		public static const I:int = 73;
		public static const J:int = 74;
		public static const K:int = 75;
		public static const L:int = 76;
		public static const M:int = 77;
		public static const N:int = 78;
		public static const O:int = 79;
		public static const P:int = 80;
		public static const Q:int = 81;
		public static const R:int = 82;
		public static const S:int = 83;
		public static const T:int = 84;
		public static const U:int = 85;
		public static const V:int = 86;
		public static const W:int = 87;
		public static const X:int = 88;
		public static const Y:int = 89;
		public static const Z:int = 90;
		
		public static var keyLog:Array = [];
		public static var keyLogString:String = "";
		public static const KEY_LOG_LENGTH:int = 10;
		
		public static var hotKeyTotal:int = 0;
		
		public static const KONAMI_CODE:String = [Keyboard.UP, Keyboard.UP, Keyboard.DOWN, Keyboard.DOWN, Keyboard.LEFT, Keyboard.RIGHT, Keyboard.LEFT, Keyboard.RIGHT, B, A].toString();
		
		public function Key() {
		}
        /*
        * Initializes the key class creating assigning event
        * handlers to capture necessary key events from the stage
		*
		* optional customKeys is an array of key codes referring to
		* user definable keys
        */
        public static function init(_stage:Stage):void {
            if (!initialized) {
                stage = _stage;
				
				// assign listeners for key presses and deactivation of the player
                stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
                stage.addEventListener(KeyboardEvent.KEY_UP, keyReleased);
                stage.addEventListener(Event.DEACTIVATE, clearKeys);
				
				// init key logger
				for(var i:int = 0; i < KEY_LOG_LENGTH; i++) keyLog.push(0);
				keyLogString = keyLog.toString();
				
                // mark initialization as true so redundant
                // calls do not reassign the event handlers
                initialized = true;
            }
        }
		
        /**
        * Returns true or false if the key represented by the
        * custom key index is being pressed
        */
        public static function customDown(index:int):Boolean {
            return !lockOut && custom != null && Boolean(keysDown[custom[index]]);
        }
		
        /**
        * Returns true or false if the key represented by the
        * keyCode passed is being pressed
        */
        public static function isDown(keyCode:int):Boolean {
            return !lockOut && Boolean(keysDown[keyCode]);
        }
		
		/* Tests whether a pattern of key codes matches the recent key log
		 * patterns are given as strings to skip laborious trawling through arrays of numbers */
		public static function matchLog(pattern:String):Boolean{
			if(pattern.length > keyLogString.length) return false;
			return keyLogString.substr(keyLogString.length - pattern.length) == pattern;
		}
		
        /**
        * Event handler for capturing keys being pressed
        */
        private static function keyPressed(event:KeyboardEvent):void {
            // create a property in keysDown with the name of the keyCode
			if(!Boolean(keysDown[event.keyCode])) keysPressed++;
            keysDown[event.keyCode] = true;
			
			keyLog.shift();
			keyLog[KEY_LOG_LENGTH - 1] = event.keyCode;
			keyLogString = keyLog.toString();
        }
		
        /**
        * Event handler for capturing keys being released
        */
        private static function keyReleased(event:KeyboardEvent):void {
            keysDown[event.keyCode] = false;
			if(keysPressed > 0) keysPressed--;
			else {
				// the keyboard layout may have changed, clear the buffer to repair damage
				clearKeys();
			}
        }
		
        /**
        * Event handler for Flash Player deactivation
        */
        public static function clearKeys(event:Event = null):void {
            // clear all keys in keysDown since the player cannot
            // detect keys being pressed or released when not focused
            keysDown = [];
			keysPressed = 0;
        }
		
		/*
		 * Return a string representing a key pressed
		 * a 3 letter string is returned for special characters
		 *
		 */
		public static function keyString(keyCode:uint):String{
			switch(keyCode){
				case Keyboard.BACKSPACE:
					return "bsp";
				case Keyboard.CAPS_LOCK:
					return "cpl";
				case Keyboard.CONTROL:
					return "ctr";
				case Keyboard.DELETE:
					return "del";
				case Keyboard.DOWN:
					return "dwn";
				case Keyboard.END:
					return "end";
				case Keyboard.ENTER:
					return "ent";
				case Keyboard.ESCAPE:
					return "esc";
				case Keyboard.HOME:
					return "hom";
				case Keyboard.INSERT:
					return "ins";
				case Keyboard.LEFT:
					return "lft";
				case Keyboard.PAGE_DOWN:
					return "pgd";
				case Keyboard.PAGE_UP:
					return "pgu";
				case Keyboard.RIGHT:
					return "rgt";
				case Keyboard.SHIFT:
					return "sht";
				case Keyboard.SPACE:
					return "spc";
				case Keyboard.TAB:
					return "tab";
				case Keyboard.UP:
					return "up";
				case 186:
					return ":";
				case 188:
					return ".";
				case 190:
					return ",";
				case 191:
					return "?";
				case 109:
					return "n -";
				case 107:
					return "n +";
				case 187:
					return "+";
				case 189:
					return "-";
				case 222:
					return "'";
				default:
					if(keyCode >= 96 && keyCode <= 105){
						return "n "+String.fromCharCode(keyCode-48);
					} else {
						return String.fromCharCode(keyCode);
					}
			}
			return "";
		}
	}
}
