package com.robotacid.ui.menu {
	/**
	 * The menu available upon death
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class DeathMenu extends Menu {
		
		public var game:Game;
		
		public var newGameOption:MenuOption;
		public var quitToTitleOption:MenuOption;
		public var saveEpitaphOption:MenuOption;
		
		public function DeathMenu(width:Number, height:Number, game:Game) {
			this.game = game;
			super(width, height);
			
			var trunk:MenuList = new MenuList();
			
			var youDiedOption:MenuOption = new MenuOption("you died", null, false);
			newGameOption = new MenuOption("new game");
			newGameOption.help = "start a new game";
			newGameOption.selectionStep = MenuOption.EXIT_MENU;
			saveEpitaphOption = new MenuOption("save epitaph", null, false);
			saveEpitaphOption.help = "save log and current inventory state before the rogue's death to a text file";
			quitToTitleOption = new MenuOption("quit to title", null, false);
			quitToTitleOption.help = "return to the title screen";
			
			trunk.options.push(youDiedOption);
			trunk.options.push(newGameOption);
			trunk.options.push(saveEpitaphOption);
			trunk.options.push(quitToTitleOption);
			
			setTrunk(trunk);
			
			var option:MenuOption = currentMenuList.options[selection];
			help.text = option.help;
		}
		
		override public function executeSelection():void {
			var option:MenuOption = currentMenuList.options[selection];
			if(option == newGameOption){
				game.gameMenu.reset();
			} else if(option == saveEpitaphOption){
				saveEpitaph();
			} else if(option == quitToTitleOption){
				
			}
		}
		
		public function saveEpitaph():void{
			
		}
		
	}

}