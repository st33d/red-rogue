package com.robotacid.util {
	
	/**
	* A wrapper for Numbers to protect them from tools like CheatEngine
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class HiddenNumber {
		
		private var _value:Number;
		private var r:Number;
		function HiddenNumber(start_value:Number = 0){
			r = (int)(Math.random()*2000000)-1000000;
			_value = r + start_value;
		}
		// Getter setters for value
		public function set value(v:Number):void{
			r = (int)(Math.random()*2000000)-1000000;
			_value = r + v;
		}
		public function get value():Number{
			return _value-r;
		}
		
	}
	
}