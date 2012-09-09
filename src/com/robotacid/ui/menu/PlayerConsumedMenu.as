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
	public class PlayerConsumedMenu extends Menu {
		
		public var game:Game;
		
		public var resetOption:MenuOption;
		
		public function PlayerConsumedMenu(width:Number, height:Number, game:Game) {
			this.game = game;
			super(width, height);
			
			var trunk:MenuList = new MenuList();
			
			var youLostOption:MenuOption = new MenuOption("you lost", null, false);
			youLostOption.help = "the balrog has consumed red rogue's soul. her death no longer resets the dungeon for she is not dead, but eternally in torment within the balrog.";
			resetOption = new MenuOption("reset");
			resetOption.help = "reset all game settings";
			resetOption.selectionStep = MenuOption.EXIT_MENU;
			
			trunk.options.push(youLostOption);
			trunk.options.push(resetOption);
			//trunk.options.push(game.gameMenu.debugOption);
			
			setTrunk(trunk);
			
			var option:MenuOption = currentMenuList.options[selection];
			help.text = option.help;
		}
		
		override public function executeSelection():void {
			var option:MenuOption = currentMenuList.options[selection];
			if(option == resetOption){
				game.state = Game.TITLE;
				game.gameMenu.reset(true);
			}
		}
		
	}

}