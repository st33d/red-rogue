package com.robotacid.ui.menu {
	import com.robotacid.engine.Item;
	import com.robotacid.level.Map;
	import com.robotacid.ui.Dialog;
	import com.robotacid.ui.FileManager;
	import flash.system.Capabilities;
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
			newGameOption = new MenuOption("reincarnate");
			newGameOption.help = "start a new game";
			newGameOption.selectionStep = MenuOption.EXIT_MENU;
			saveEpitaphOption = new MenuOption("save epitaph");
			saveEpitaphOption.help = "save log and current inventory state before the rogue's death to a text file";
			quitToTitleOption = new MenuOption("quit to title", null, false);
			quitToTitleOption.help = "return to the title screen";
			
			trunk.options.push(youDiedOption);
			trunk.options.push(newGameOption);
			trunk.options.push(saveEpitaphOption);
			trunk.options.push(quitToTitleOption);
			//trunk.options.push(game.gameMenu.debugOption);
			
			setTrunk(trunk);
			
			var option:MenuOption = currentMenuList.options[selection];
			help.text = option.help;
		}
		
		override public function executeSelection():void {
			var option:MenuOption = currentMenuList.options[selection];
			if(option == newGameOption){
				game.gameMenu.reset();
			} else if(option == saveEpitaphOption){
				if(Capabilities.playerType == "StandAlone"){
					saveEpitaph();
				} else {
					if(!Game.dialog){
						Game.dialog = new Dialog(
							"save epitaph",
							"flash's security restrictions require you to press the menu key to continue\n",
							saveEpitaph
						);
					}
				}
			} else if(option == quitToTitleOption){
				
			}
		}
		
		/* Save a description of the events leading to the player's death */
		public function saveEpitaph():void{
			var i:int;
			var date:Date = new Date();
			var str:String = "EPITAPH " + date.toLocaleString().toLocaleUpperCase() + "\n\n";
			str += "red the " + game.player.nameStr + "\n";
			str += "died in the " + Map.getName(game.map.type, game.map.level);
			if(game.map.type == Map.MAIN_DUNGEON) str += " (level " + game.map.level + ")";
			str += "\n\n";
			if(game.minion){
				str += "leaving behind her husband " + game.minion.nameToString() + "\n\n";
			} else {
				str += "whose husband waits in the underworld" + "\n\n";
			}
			str += "random seed to recreate: " + Map.random.seed + "\n\n";
			str += "xp level: " + game.player.level + " \nxp: " + game.player.xp + "\n\n";
			// equipment list
			str += "runes identified: ";
			var runesList:Array = [];
			for(i = 0; i < Item.runeNames.length; i++){
				if(Item.runeNames[i] != Item.UNIDENTIFIED) runesList.push(Item.runeNames[i]);
			}
			for(i = 0; i < runesList.length; i++){
				str += runesList[i];
				if(i < runesList.length - 1) str += ", ";
			}
			str += "\n\n";
			str += game.gameMenu.inventoryList.getEpitaph();
			str += "\n\n";
			str += "LOG:\n\n" + game.console.log.toLocaleLowerCase() + "\n";
			FileManager.save(str, "epitaph.txt");
		}
		
	}

}