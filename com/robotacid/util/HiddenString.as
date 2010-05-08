package com.robotacid.util {
	
	/**
	* A wrapper for Strings to protect them from tools like CheatEngine
	*
	* uses crummilicious XOR encryption :D
	*
	* @author Aaron Steed
	*/
	public class HiddenString {

		private var _value:String;
		private var r:int;

		public function HiddenString(string:String = "") {
			value = string;
		}

		public function set value(new_value:String):void {
			_value = "";
			r = Math.random() * 1000000;
			for(var i:int = 0; i < new_value.length; i++) {
				_value += String.fromCharCode(new_value.charCodeAt(i) ^ r);
			}
		}

		public function get value():String {
			var result:String = "";
			for(var i:int = 0; i < _value.length; i++) {
				result += String.fromCharCode(_value.charCodeAt(i) ^ r);
			}
				return result;
		}

	}
	
}