package com.robotacid.ui.menu {
	/**
	 * Instead of a list of options an image or text is shown as the next list
	 * 
	 * A callback is given to the object to render the info
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class MenuInfo extends MenuList {
		
		public var renderCallback:Function;
		public var update:Boolean;
		
		public static const TEXT_BOX_LINES:int = 15;
		
		public function MenuInfo(renderCallback:Function, update:Boolean = false) {
			super();
			this.renderCallback = renderCallback;
			this.update = update;
			//accessible = false;
		}
		
	}

}