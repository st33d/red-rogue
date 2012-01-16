package com.robotacid.ui.menu {
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Item;
	import com.robotacid.ui.TextBox;
	import flash.geom.Rectangle;
	/**
	 * Manages the Lore section of the menu, updating through use of the identify Effect as well as
	 * housing the map renderer
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class LoreMenuList extends MenuList {
		
		public var game:Game;
		public var menu:Menu;
		public var infoTextBox:TextBox
		
		public var racesList:MenuList;
		public var itemsList:MenuList;
		public var weaponsList:MenuList;
		public var armourList:MenuList;
		
		public var mapInfo:MenuInfo;
		public var raceInfo:MenuInfo;
		public var weaponInfo:MenuInfo;
		public var armourInfo:MenuInfo;
		
		public function LoreMenuList(infoTextBox:TextBox, menu:Menu, game:Game) {
			super();
			this.infoTextBox = infoTextBox;
			this.menu = menu;
			this.game = game;
			
			racesList = new MenuList();
			itemsList = new MenuList();
			weaponsList = new MenuList();
			armourList = new MenuList();
			
			mapInfo = new MenuInfo(renderMap, true);
			raceInfo = new MenuInfo(renderRaceInfo);
			weaponInfo = new MenuInfo(renderWeaponInfo);
			armourInfo = new MenuInfo(renderArmourInfo);
			
			var option:MenuOption, i:int;
			for(i = 0; i < Character.stats["names"].length; i++){
				option = new MenuOption(Character.stats["names"][i], raceInfo, i == 0);
				option.recordable = false;
				racesList.options.push(option);
			}
			for(i = 0; i < Item.stats["weapon names"].length; i++){
				option = new MenuOption(Item.stats["weapon names"][i], weaponInfo, false);
				option.recordable = false;
				weaponsList.options.push(option);
			}
			for(i = 0; i < Item.stats["armour names"].length; i++){
				option = new MenuOption(Item.stats["armour names"][i], armourInfo, false);
				option.recordable = false;
				armourList.options.push(option);
			}
			
			var mapOption:MenuOption = new MenuOption("map", mapInfo);
			mapOption.recordable = false;
			var racesOption:MenuOption = new MenuOption("races", racesList);
			var itemsOption:MenuOption = new MenuOption("items", itemsList);
			var weaponsOption:MenuOption = new MenuOption("weapons", weaponsList);
			var armourOption:MenuOption = new MenuOption("armour", armourList);
			
			options.push(mapOption);
			options.push(racesOption);
			options.push(itemsOption);
			
			itemsList.options.push(weaponsOption);
			itemsList.options.push(armourOption);
			
		}
		
		/* Callback for mapInfo rendering */
		private function renderMap():void{
			if(infoTextBox.text != "") infoTextBox.text = "";
			var col:uint = infoTextBox.backgroundCol;
			infoTextBox.backgroundCol = 0x99666666;
			infoTextBox.drawBorder();
			infoTextBox.backgroundCol = col;
			game.miniMap.renderTo(infoTextBox.bitmapData);
			// redraw border - overlap looks ugly
			var horiz:Rectangle = new Rectangle(0, 0, infoTextBox.width, 1);
			infoTextBox.bitmapData.fillRect(horiz, infoTextBox.borderCol);
			horiz.y = infoTextBox.height - 1;
			infoTextBox.bitmapData.fillRect(horiz, infoTextBox.borderCol);
			var vert:Rectangle = new Rectangle(0, 0, 1, infoTextBox.height);
			infoTextBox.bitmapData.fillRect(vert, infoTextBox.borderCol);
			vert.y = infoTextBox.width - 1;
			infoTextBox.bitmapData.fillRect(vert, infoTextBox.borderCol);
		}
		
		private function renderRaceInfo():void{
			var n:int = racesList.selection;
			var str:String = "";
			str += Character.stats["names"][n] + "\n\n";
			str += Character.stats["descriptions"][n] + "\n\n";
			str += "special: " + Character.stats["specials"][n] + "\n";
			str += "attack: " + Character.stats["attacks"][n] + " + " + Character.stats["attack levels"][n] + " x lvl\n";
			str += "defence: " + Character.stats["defences"][n] + " + " + Character.stats["defence levels"][n] + " x lvl\n";
			str += "health: " + Character.stats["healths"][n] + " + " + Character.stats["health levels"][n] + " x lvl\n";
			str += "damage: " + Character.stats["damages"][n] + " + " + Character.stats["damage levels"][n] + " x lvl\n";
			str += "attack speed: " + Character.stats["attack speeds"][n] + " + " + Character.stats["attack speed levels"][n] + " x lvl\n";
			str += "move speed: " + Character.stats["speeds"][n] + " + " + Character.stats["speed levels"][n] + " x lvl\n";
			str += "knockback: " + Character.stats["knockbacks"][n] + "\n";
			str += "stun: " + Character.stats["stuns"][n] + "\n";
			str += "endurance: " + Character.stats["endurances"][n] + "\n";
			infoTextBox.wordWrap = false;
			infoTextBox.marquee = true;
			infoTextBox.text = str;
		}
		
		private function renderWeaponInfo():void{
			
		}
		
		private function renderArmourInfo():void{
			
		}
		
	}

}