package com.robotacid.ui.menu {
	
	/**
	 * A way of making a MenuOption appear to be multiple MenuOptions in the same option
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class MenuOptionStack extends MenuOption{
		
		private var Total:int;
		
		public var singleName:String;
		
		public function MenuOptionStack(name:String, next:MenuList = null, active:Boolean = true) {
			super(name, next, active);
			singleName = name;
			Total = 1;
		}
		
		public function get total():int{
			return Total;
		}
		
		public function set total(n:int):void{
			Total = n;
			name = (Total > 1 ? Total + " x " : "") + singleName;
		}
		
	}

}