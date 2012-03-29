package com.robotacid.ui.menu {
	import com.robotacid.level.Content;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Item;
	/**
	 * A debugging tool to create any concievable item from the menu.
	 * 
	 * Recursive lists for enchanting an item would be required somehow
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class GiveItemMenuList extends MenuList {
		
		public var game:Game;
		public var menu:Menu;
		public var itemXML:XML;
		public var targetXMLNode:XML;
		public var item:Item;
		public var active:Boolean;
		
		private var enchanting:Boolean;
		
		public var nameLists:Vector.<MenuList>;
		public var itemLevelList:MenuList;
		public var raceList:MenuList;
		public var enchantmentList:MenuList;
		public var enchantmentNameList:MenuList;
		public var enchantmentLevelList:MenuList;
		public var finaliseItemList:MenuList;
		public var createList:MenuList;
		
		public var weaponOption:MenuOption;
		public var armourOption:MenuOption;
		public var runeOption:MenuOption;
		public var heartOption:MenuOption;
		public var enchantOption:MenuOption;
		public var createOption:MenuOption;
		
		public var holyStateList:MenuList;
		
		public function GiveItemMenuList(menu:Menu, game:Game) {
			super();
			this.menu = menu;
			this.game = game;
			
			enchanting = false;
			
			nameLists = Vector.<MenuList>([
				new MenuList(),
				new MenuList(),
				new MenuList(),
				new MenuList()
			]);
			itemLevelList = new MenuList();
			enchantmentList = new MenuList();
			enchantmentLevelList = new MenuList();
			finaliseItemList = new MenuList();
			createList = new MenuList();
			holyStateList = new MenuList();
			
			weaponOption = new MenuOption("weapon", nameLists[Item.WEAPON]);
			armourOption = new MenuOption("armour", nameLists[Item.ARMOUR]);
			runeOption = new MenuOption("rune", nameLists[Item.RUNE]);
			heartOption = new MenuOption("heart", nameLists[Item.HEART]);
			enchantOption = new MenuOption("enchant", nameLists[Item.RUNE]);
			createOption = new MenuOption("create");
			
			options.push(weaponOption);
			options.push(armourOption);
			options.push(runeOption);
			options.push(heartOption);
			
			var i:int, str:String;
			for(i = 0; i < Item.stats["weapon names"].length; i++){
				str = Item.stats["weapon names"][i];
				nameLists[Item.WEAPON].options.push(new MenuOption(str, itemLevelList));
			}
			for(i = 0; i < Item.stats["armour names"].length; i++){
				str = Item.stats["armour names"][i];
				nameLists[Item.ARMOUR].options.push(new MenuOption(str, itemLevelList));
			}
			for(i = 0; i < Item.stats["rune names"].length; i++){
				str = Item.stats["rune names"][i];
				nameLists[Item.RUNE].options.push(new MenuOption(str, createList));
			}
			for(i = 0; i < Character.stats["names"].length; i++){
				str = Character.stats["names"][i];
				nameLists[Item.HEART].options.push(new MenuOption(str, itemLevelList));
			}
			for(i = 1; i <= 20; i++){
				itemLevelList.options.push(new MenuOption(i + " (level)", finaliseItemList));
			}
			
			finaliseItemList.options.push(createOption);
			finaliseItemList.options.push(enchantOption);
			finaliseItemList.options.push(new MenuOption("holy state", holyStateList));
			
			createList.options.push(createOption);
			
			holyStateList.options = Vector.<MenuOption>([
				new MenuOption("none", null, false),
				new MenuOption("hidden curse", null, false),
				new MenuOption("cursed", null, false),
				new MenuOption("blessed", null, false)
			]);
		}
		
		public function update():void{
			var option:MenuOption = menu.currentMenuList.options[menu.selection];
			var previousMenuListOption:MenuOption = menu.previousMenuList.options[menu.previousMenuList.selection];
			
			if(previousMenuListOption == enchantOption){
				enchanting = true;
			}
			
			// target switching:
			// weapons and armour can be enchanted, creating a menu loop
			// hearts have levels but no enchantments
			// runes have no level and no enchantments
			
			if(menu.currentMenuList == itemLevelList){
				if(menu.previousMenuList == nameLists[Item.HEART]){
					if(option.target != createList) itemLevelList.changeTargets(createList);
				} else {
					if(option.target != finaliseItemList) itemLevelList.changeTargets(finaliseItemList);
				}
			} else if(menu.currentMenuList == nameLists[Item.RUNE]){
				if(previousMenuListOption == runeOption){
					if(option.target != createList) nameLists[Item.RUNE].changeTargets(createList);
				} else {
					if(option.target != itemLevelList) nameLists[Item.RUNE].changeTargets(itemLevelList);
				}
			}
			
			// no itemXML at the root of this tree
			if(menu.currentMenuList == this){
				itemXML = null;
			
			// heart and rune xml init
			} else if(menu.currentMenuList == createList){
				itemXML = createItemXML();
			
			// weapon and armour init
			} else if(menu.currentMenuList == finaliseItemList){
				if(!itemXML) itemXML = createItemXML();
				else if(enchanting){
					if(menu.previousMenuList == itemLevelList){
						enchantItemXML(itemXML);
					}
					enchanting = false;
				}
			}
		}
		
		public function createItem():void{
			if(int(itemXML.@type) == Item.ARMOUR || int(itemXML.@type) == Item.WEAPON){
				itemXML.@holyState = holyStateList.selection;
			}
			var item:Item = Content.XMLToEntity(0, 0, itemXML);
			item.collect(game.player);
			active = false;
		}
		
		public function createItemXML():XML{
			var xml:XML =<item />;
			xml.@type = selection;
			xml.@name = nameLists[selection].selection;
			xml.@level = selection == Item.RUNE ? 0 : itemLevelList.selection + 1;
			return xml;
		}
		
		public function enchantItemXML(itemXML:XML):void{
			var effectXML:XML = <effect />;
			effectXML.@name = nameLists[Item.RUNE].selection;
			effectXML.@level = itemLevelList.selection + 1;
			itemXML.appendChild(effectXML);
		}
		
	}

}