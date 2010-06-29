package com.robotacid.ui.menu {
	/**
	 * A pointer to a MenuList, or a label in a MenuList that when stepped forward
	 * through will activate a Menu's SELECT event
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class MenuOption{
		
		public var name:String;
		public var active:Boolean;
		public var next:MenuList;
		public var help:String;
		
		// A reference to an object that this option affects
		public var target:*;
		
		// stepping forward through an option with deactivates assigned will deactivate that
		// option. Stepping back through this option will reactivate the targeted option.
		// Use this feature to prevent infinite recursion
		public var deactivates:Vector.<MenuOption>;
		// hot key maps need to find paths of similar context when the original path is removed
		public var context:String;
		public var hotKeyOption:Boolean = false;
		
		public function MenuOption(name:String, next:MenuList = null, active:Boolean = true) {
			this.name = name;
			this.next = next;
			this.active = active;
		}
		
	}

}