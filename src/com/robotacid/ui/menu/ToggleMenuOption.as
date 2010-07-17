package com.robotacid.ui.menu {
	
	/**
	 * A MenuOption that can be flipped between a number of states
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class ToggleMenuOption extends MenuOption{
		
		private var State:int;
		public var names:Array;
		
		public function ToggleMenuOption(names:Array, next:MenuList = null, active:Boolean = true) {
			this.names = names;
			super(names[0], next, active);
			State = 0;
			
		}
		
		public function get state():int{
			return State;
		}
		
		public function set state(n:int):void{
			State = n;
			name = names[n];
		}
		
	}

}