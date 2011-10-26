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
		public var target:MenuList;
		public var help:String;
		public var recordable:Boolean; // set to false to prevent a hot key recording of this option
		
		// A reference to an object that this option affects
		public var userData:*;
		
		// hot key maps need to find paths of similar context when the original path is removed
		public var context:String;
		public var hotKeyOption:Boolean = false;
		
		public function MenuOption(name:String, target:MenuList = null, active:Boolean = true) {
			this.name = name;
			this.target = target;
			this.active = active;
			this.recordable = true;
		}
		
	}

}