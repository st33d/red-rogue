package com.robotacid.ui.menu {
	
	/**
	 * A way of making a MenuOption appear to be multiple MenuOptions in the same option
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class MenuOptionStack extends MenuOption{
		
		private var _total:int;
		
		public var singleName:String;
		
		public function MenuOptionStack(name:String, next:MenuList = null, active:Boolean = true) {
			super(name, next, active);
			singleName = name;
			_total = 1;
		}
		
		public function get total():int{
			return _total;
		}
		
		public function set total(n:int):void{
			_total = n;
			name = (_total > 1 ? _total + " x " : "") + singleName;
		}
		
		/* Updates the stacked name */
		public function updateName():void{
			total = _total;
		}
	}

}