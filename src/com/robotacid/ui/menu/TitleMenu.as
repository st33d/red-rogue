package com.robotacid.ui.menu {
	/**
	 * A small menu for the title screen
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class TitleMenu extends Menu {
		
		public var optionsList:MenuList;
		public var sureList:MenuList;
		
		public var newGameOption:MenuOption;
		public var continueOption:MenuOption;
		public var optionsOption:MenuOption;
		public var resetTimeTravelOption:MenuOption;
		
		public var screenshotOption:MenuOption;
		public var saveLogOption:MenuOption;
		public var editorOption:MenuOption;
		public var giveItemOption:MenuOption;
		public var changeRogueRaceOption:MenuOption;
		public var changeMinionRaceOption:MenuOption;
		public var portalTeleportOption:MenuOption;
		public var giveDebugEquipmentOption:MenuOption;
		public var quitToTitleOption:MenuOption;
		public var newGameOption:MenuOption;
		public var seedOption:MenuOption;
		public var dogmaticOption:MenuOption;
		public var consoleDirOption:MenuOption;
		
		public var sureOption:MenuOption;
		
		public static const NO:int = 0;
		public static const YES:int = 1;
		
		public function TitleMenu(width:Number, height:Number, trunk:MenuList = null) {
			super(Game.WIDTH, Game.HEIGHT);
			
			var trunk:MenuList = new MenuList();
			optionsList = new MenuList();
			sureList = new MenuList();
			
			newGameOption = new MenuOption("new game");
			continueOption = new MenuOption("continue game", null, false);
			resetTimeTravelOption = new MenuOption("reset time travel", sureList);
			
			optionsList.options.push(soundOption);
			optionsList.options.push(fullScreenOption);
			optionsList.options.push(screenshotOption);
			optionsList.options.push(saveLogOption);
			optionsList.options.push(menuMoveOption);
			optionsList.options.push(consoleDirOption);
			optionsList.options.push(changeKeysOption);
			optionsList.options.push(hotKeyOption);
			optionsList.options.push(seedOption);
			optionsList.options.push(dogmaticOption);
			optionsList.options.push(quitToTitleOption);
			optionsList.options.push(newGameOption);
			
			sureList.options = Vector.<MenuOption>([
				new MenuOption("no"),
				new MenuOption("yes")
			]);
			
		}
		
	}

}