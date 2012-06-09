package com.robotacid.ui.menu {
	/**
	 * A menu for the title screen
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class TitleMenu extends Menu {
		
		public var optionsList:MenuList;
		
		public var newGameOption:MenuOption;
		public var continueOption:MenuOption;
		public var optionsOption:MenuOption;
		public var resetTimeTravelOption:MenuOption;
		
		public var seedOption:MenuOption;
		public var dogmaticOption:MenuOption;
		
		public function TitleMenu(gameMenu:GameMenu) {
			super(Game.WIDTH, Game.HEIGHT);
			
			var trunk:MenuList = new MenuList();
			optionsList = new MenuList();
			sureList = new MenuList();
			
			newGameOption = new MenuOption("new game");
			continueOption = new MenuOption("continue game", null, false);
			resetTimeTravelOption = new MenuOption("reset time loop", sureList);
			optionsOption = new MenuOption("options", optionsList);
			
			trunk.options.push(newGameOption);
			trunk.options.push(continueOption);
			trunk.options.push(resetTimeTravelOption);
			trunk.options.push(optionsOption);
			
			// link direct to game menu objects - easier to keep consistent
			optionsList.options.push(gameMenu.soundOption);
			optionsList.options.push(gameMenu.fullScreenOption);
			optionsList.options.push(gameMenu.menuMoveOption);
			optionsList.options.push(gameMenu.changeKeysOption);
			optionsList.options.push(gameMenu.seedOption);
			optionsList.options.push(gameMenu.dogmaticOption);
			
			setTrunk(trunk);
			
		}
		
	}

}