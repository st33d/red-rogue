package com.robotacid.ui.menu {
	import com.robotacid.ui.Editor;
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class EditorMenuList extends MenuList {
		
		public var createBlockList:MenuList;
		public var createObjectList:MenuList;
		
		public var blockList:MenuList;
		public var objectList:MenuList;
		public var raceList:MenuList;
		public var featureList:MenuList;
		
		public var blockOption:MenuOption;
		public var objectOption:MenuOption;
		
		public var createBlockOption:MenuOption;
		public var createObjectOption:MenuOption;
		public var deleteOption:MenuOption;
		
		public function EditorMenuList(editor:Editor) {
			editor.menuList = this;
			
			createBlockList = new MenuList();
			createObjectList = new MenuList();
			raceList = new MenuList();
			
			blockOption = new MenuOption("block layer", createBlockList);
			objectOption = new MenuOption("object layer", createObjectList);
			
			createBlockOption = new MenuOption("create", blockList);
			
			options.push(blockOption);
			options.push(objectOption);
		}
		
	}

}