package com.robotacid.util {
	
	/**
	* A wrapper for ints to protect them from tools like CheatEngine
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class HiddenInt {
		
		private var _value:int;
		private var r:int;
		
		public function HiddenInt(start_value:int = 0){
			r = (Math.random()*2000000)-1000000;
			_value = start_value ^ r;
		}
		// Getter setters for value
		public function set value(v:int):void{
			r = (Math.random()*2000000)-1000000;
			_value = v ^ r;
		}
		public function get value():int{
			return _value ^ r;
		}
	}
	
}