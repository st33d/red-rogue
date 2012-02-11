package com.robotacid.ui.menu {
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Entity;
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
		public var questsList:QuestMenuList;
		
		public var mapInfo:MenuInfo;
		public var raceInfo:MenuInfo;
		public var weaponInfo:MenuInfo;
		public var armourInfo:MenuInfo;
		
		public var racesOption:MenuOption;
		public var itemsOption:MenuOption;
		public var armourOption:MenuOption;
		public var weaponsOption:MenuOption;
		
		public var questsOption:MenuOption;
		
		public function LoreMenuList(infoTextBox:TextBox, menu:Menu, game:Game) {
			super();
			this.infoTextBox = infoTextBox;
			this.menu = menu;
			this.game = game;
			
			racesList = new MenuList();
			itemsList = new MenuList();
			weaponsList = new MenuList();
			armourList = new MenuList();
			questsList = new QuestMenuList(menu);
			
			mapInfo = new MenuInfo(renderMap, true);
			raceInfo = new MenuInfo(renderRace);
			weaponInfo = new MenuInfo(renderWeapon);
			armourInfo = new MenuInfo(renderArmour);
			
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
			racesOption = new MenuOption("races", racesList);
			itemsOption = new MenuOption("items", itemsList);
			weaponsOption = new MenuOption("weapons", weaponsList);
			armourOption = new MenuOption("armour", armourList);
			questsOption = new MenuOption("quests", questsList);
			
			options.push(mapOption);
			options.push(racesOption);
			options.push(itemsOption);
			options.push(questsOption);
			
			itemsList.options.push(weaponsOption);
			itemsList.options.push(armourOption);
			
		}
		
		/* Checks for lore corresponding to the enitity submitted and unlocks the entry if currently locked */
		public function unlockLore(entity:Entity):void{
			var option:MenuOption;
			var newLore:Boolean = false;
			if(entity is Character){
				option = racesList.options[entity.name];
				if(!option.active){
					newLore = true;
					racesOption.visited = false;
				}
			} else if(entity is Item){
				var item:Item = entity as Item;
				if(item.type == Item.WEAPON){
					option = weaponsList.options[item.name];
					if(!option.active){
						newLore = true;
						weaponsOption.visited = false;
						itemsOption.visited = false;
					}
				} else if(item.type == Item.ARMOUR){
					option = armourList.options[item.name];
					if(!option.active){
						newLore = true;
						armourOption.visited = false;
						itemsOption.visited = false;
					}
				}
			}
			if(newLore){
				option.active = true;
				option.visited = false;
				menu.update();
				game.console.print("new lore unlocked");
			}
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
		
		/* Callback for raceInfo rendering */
		private function renderRace():void{
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
			str += "endurance: " + Character.stats["endurances"][n];
			infoTextBox.wordWrap = false;
			infoTextBox.marquee = true;
			infoTextBox.text = str;
		}
		
		/* Callback for weaponInfo rendering */
		private function renderWeapon():void{
			var n:int = weaponsList.selection;
			var str:String = "";
			str += Item.stats["weapon names"][n] + "\n\n";
			str += Item.stats["weapon descriptions"][n] + "\n\n";
			str += "special: " + Item.stats["weapon specials"][n] + "\n";
			str += "range: ";
			var range:int = Item.stats["weapon ranges"][n];
			var rangeStr:Array = [];
			if(range & Item.MELEE) rangeStr.push("melee");
			if(range & Item.MISSILE) rangeStr.push("missile");
			if(range & Item.THROWN) rangeStr.push("thrown");
			str += rangeStr.join(",") + "\n";
			str += "damage: " + Item.stats["weapon damages"][n] + " + " + Item.stats["weapon damage levels"][n] + " x lvl\n";
			str += "attack: " + Item.stats["weapon attacks"][n] + " + " + Item.stats["weapon attack levels"][n] + " x lvl\n";
			str += "knockback: " + Item.stats["weapon knockbacks"][n] + "\n";
			str += "stun: " + Item.stats["weapon stuns"][n] + "\n";
			str += "hearts: +" + ((Item.stats["weapon butchers"][n] * 100) >> 0) + "%";
			infoTextBox.wordWrap = false;
			infoTextBox.marquee = true;
			infoTextBox.text = str;
		}
		
		/* Callback for armourInfo rendering */
		private function renderArmour():void{
			var n:int = armourList.selection;
			var str:String = "";
			str += Item.stats["armour names"][n] + "\n\n";
			str += Item.stats["armour descriptions"][n] + "\n\n";
			str += "special: " + Item.stats["armour specials"][n] + "\n";
			str += "defence: " + Item.stats["armour defences"][n] + " + " + Item.stats["armour defence levels"][n] + " x lvl\n";
			str += "endurance: " + Item.stats["armour endurances"][n];
			infoTextBox.wordWrap = false;
			infoTextBox.marquee = true;
			infoTextBox.text = str;
		}
		
	}

}