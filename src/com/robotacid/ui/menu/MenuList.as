package com.robotacid.ui.menu {
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextLineMetrics;
	import flash.ui.Keyboard;
	
	/**
	 * A wrapper for a list of MenuOptions that stores the current selected
	 * option. The selection value is vital for figuring out the route taken
	 * to the selected option.
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class MenuList {
		
		/* This variable can be used to store all the references that lead to this MenuList
		 * this is not a default owing to how cumbersome this could be to manage */
		public var pointers:Vector.<MenuOption>;
		
		public var options:Vector.<MenuOption>;
		public var selection:int;
		public var accessible:Boolean;
		
		public function MenuList(options:Vector.<MenuOption> = null) {
			if(options) this.options = options;
			else this.options = new Vector.<MenuOption>();
			accessible = true;
			selection = 0;
		}
		
		public function optionsToString(separator:String = "\n", hotKeyMapStrings:Vector.<String> = null):String{
			var str:String = "";
			var option:MenuOption;
			for(var i:int = 0; i < options.length; i++){
				option = options[i];
				str += option.hidden ? "" : option.name;
				if(hotKeyMapStrings && hotKeyMapStrings[i] != "") str += " " + hotKeyMapStrings[i];
				if(i < options.length - 1) str += separator;
			}
			return str;
		}
		
		/* Change all options within to point to a given target */
		public function changeTargets(target:MenuList):void{
			for(var i:int = 0; i < options.length; i++){
				options[i].target = target;
			}
		}
		
	}
	
}