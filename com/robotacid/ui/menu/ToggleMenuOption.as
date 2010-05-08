package com.robotacid.ui.menu {
	
	/**
	 * A MenuOption that can be flipped between a number of states
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class ToggleMenuOption extends MenuOption{
		
		private var _state:int;
		public var names:Array;
		
		public function ToggleMenuOption(names:Array, next:MenuList = null, active:Boolean = true) {
			this.names = names;
			super(names[0], next, active);
			_state = 0;
			
		}
		
		public function get state():int{
			return _state;
		}
		
		public function set state(n:int):void{
			_state = n;
			name = names[n];
		}
		
	}

}