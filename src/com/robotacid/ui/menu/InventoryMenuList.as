package com.robotacid.ui.menu {
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Minion;
	import com.robotacid.engine.Player;
	import com.robotacid.level.Content;
	import flash.utils.Dictionary;
	import com.robotacid.engine.Item;
	
	/**
	 * A special MenuList just for the inventory, because managing the items is quite complicated
	 * and makes quite mess on its own without having all the other game options farting around it
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class InventoryMenuList extends MenuList{
		
		public var game:Game;
		public var menu:Menu;
		
		public var autoSort:Boolean;
		
		public var weaponsList:MenuList;
		public var armourList:MenuList;
		public var runesList:MenuList;
		public var heartsList:MenuList;
		
		public var weaponActionList:MenuList;
		public var armourActionList:MenuList;
		public var runeActionList:MenuList;
		public var heartActionList:MenuList;
		public var enchantmentList:EnchantmentList;
		
		public var enchantableList:MenuList;
		public var enchantableWeaponsList:MenuList;
		public var enchantableArmourList:MenuList;
		
		public var weaponsOption:MenuOption;
		public var armourOption:MenuOption;
		public var runesOption:MenuOption;
		public var heartsOption:MenuOption;
		public var autoSortOption:MenuOption;
		
		public var equipOption:ToggleMenuOption;
		public var equipMinionOption:ToggleMenuOption;
		public var equipMainOption:ToggleMenuOption;
		public var equipMinionMainOption:ToggleMenuOption;
		public var equipThrowOption:ToggleMenuOption;
		public var equipMinionThrowOption:ToggleMenuOption;
		public var dropOption:MenuOption;
		public var eatOption:MenuOption;
		public var feedMinionOption:MenuOption;
		public var enchantOption:MenuOption
		public var throwRuneOption:MenuOption;
		public var enchantmentsOption:MenuOption;
		public var enchantableWeaponsOption:MenuOption;
		public var enchantableArmourOption:MenuOption;
		
		public var itemToOption:Dictionary;
		public var enchantableToOption:Dictionary;
		
		public static const EQUIP:int = 0;
		public static const UNEQUIP:int = 1;
		
		public static const SELECTION_STEP:int = 3;
		
		public function InventoryMenuList(menu:Menu, game:Game) {
			super();
			this.menu = menu;
			this.game = game;
			autoSort = UserData.settings.autoSortInventory;
			
			// MENU LISTS
			
			weaponsList = new MenuList();
			armourList = new MenuList();
			runesList = new MenuList();
			heartsList = new MenuList();
			
			weaponActionList = new MenuList();
			armourActionList = new MenuList();
			runeActionList = new MenuList();
			heartActionList = new MenuList();
			enchantmentList = new EnchantmentList();
			
			enchantableList = new MenuList();
			enchantableWeaponsList = new MenuList();
			enchantableArmourList = new MenuList();
			
			// MENU OPTIONS
			
			weaponsOption = new MenuOption("weapons", weaponsList, false);
			weaponsOption.help = "The list of weapons you and the minion can equip.";
			armourOption = new MenuOption("armour", armourList, false);
			armourOption.help = "The list of armour you and the minion can equip.";
			runesOption = new MenuOption("runes", runesList, false);
			runesOption.help = "The list of runes that can be used on yourself, the minion, monsters and your equipment.";
			heartsOption = new MenuOption("hearts", heartsList, false);
			heartsOption.help = "The list of hearts you and the minion can eat to regain health.";
			autoSortOption = new MenuOption("auto-sort", (menu as GameMenu).onOffList);
			autoSortOption.selectionStep = 1;
			autoSortOption.recordable = false;
			autoSortOption.help = "auto-sort sorts weapons and armour according to the highest combat stats. does not consider special abilities or enchantments.";
			
			enchantOption = new MenuOption("enchant", enchantableList, false);
			enchantableWeaponsOption = new MenuOption("weapons", enchantableWeaponsList, false);
			enchantableWeaponsOption.help = "The list of weapons you can enchant.";
			enchantableArmourOption = new MenuOption("armour", enchantableArmourList, false);
			enchantableArmourOption.help = "The list of armour you can enchant.";
			
			equipMainOption = new ToggleMenuOption(["equip main", "unequip main"]);
			equipMainOption.selectionStep = SELECTION_STEP;
			equipThrowOption = new ToggleMenuOption(["equip throw", "unequip throw"]);
			equipThrowOption.selectionStep = SELECTION_STEP;
			equipMinionMainOption = new ToggleMenuOption(["equip minion main", "unequip minion main"]);
			equipMinionMainOption.selectionStep = SELECTION_STEP;
			equipMinionThrowOption = new ToggleMenuOption(["equip minion throw", "unequip minion throw"]);
			equipMinionThrowOption.selectionStep = SELECTION_STEP;
			equipOption = new ToggleMenuOption(["equip", "unequip"]);
			equipOption.selectionStep = SELECTION_STEP;
			equipMinionOption = new ToggleMenuOption(["equip minion", "unequip minion"]);
			equipMinionOption.selectionStep = SELECTION_STEP;
			dropOption = new MenuOption("drop");
			dropOption.selectionStep = SELECTION_STEP;
			eatOption = new MenuOption("eat");
			eatOption.selectionStep = SELECTION_STEP;
			feedMinionOption = new MenuOption("feed minion");
			feedMinionOption.selectionStep = SELECTION_STEP;
			throwRuneOption = new MenuOption("throw");
			throwRuneOption.selectionStep = SELECTION_STEP;
			enchantmentsOption = new MenuOption("enchantments", enchantmentList);
			
			enchantmentList.pointers = new Vector.<MenuOption>();
			enchantmentList.pointers.push(enchantmentsOption);
			
			// OPTION ARRAYS
			
			options.push(weaponsOption);
			options.push(armourOption);
			options.push(runesOption);
			options.push(heartsOption);
			options.push(autoSortOption);
			
			weaponActionList.options.push(equipMainOption);
			weaponActionList.options.push(equipThrowOption);
			weaponActionList.options.push(equipMinionMainOption);
			weaponActionList.options.push(equipMinionThrowOption);
			weaponActionList.options.push(dropOption);
			weaponActionList.options.push(enchantmentsOption);
			
			armourActionList.options.push(equipOption);
			armourActionList.options.push(equipMinionOption);
			armourActionList.options.push(dropOption);
			armourActionList.options.push(enchantmentsOption);
			
			runeActionList.options.push(enchantOption);
			runeActionList.options.push(eatOption);
			runeActionList.options.push(throwRuneOption);
			runeActionList.options.push(feedMinionOption);
			runeActionList.options.push(dropOption);
			
			heartActionList.options.push(eatOption);
			heartActionList.options.push(feedMinionOption);
			heartActionList.options.push(dropOption);
			
			enchantableList.options.push(enchantableWeaponsOption);
			enchantableList.options.push(enchantableArmourOption);
			
			itemToOption = new Dictionary(true);
			enchantableToOption = new Dictionary(true);
		}
		
		/* Called when a new game starts */
		public function reset():void{
			weaponsList.options.length = 0;
			weaponsList.selection = 0;
			weaponsOption.active = false;
			weaponsOption.visited = true;
			armourList.options.length = 0;
			armourList.selection = 0;
			armourOption.active = false;
			armourOption.visited = true;
			runesList.options.length = 0;
			runesList.selection = 0;
			runesOption.active = false;
			runesOption.visited = true;
			heartsList.options.length = 0;
			heartsList.selection = 0;
			heartsOption.active = false;
			heartsOption.visited = true;
			enchantableList.selection = 0;
			enchantableWeaponsOption.active = false;
			enchantableArmourOption.active = false;
			enchantableWeaponsList.options.length = 0;
			enchantableWeaponsList.selection = 0;
			enchantableArmourList.options.length = 0;
			enchantableArmourList.selection = 0;
			enchantOption.active = false;
			itemToOption = new Dictionary(true);
			enchantableToOption = new Dictionary(true);
			enchantOption.active = false;
		}
		
		/* Adds a new menu item and selects that item on the MenuList */
		public function addItem(item:Item, visited:Boolean = false):Item{
			var enchantableOption:MenuOptionStack, itemOption:MenuOptionStack, usageOptions:MenuList, i:int, context:String;
			
			var targetList:MenuList;
			var targetOption:MenuOption;
			if(item.type == Item.WEAPON){
				targetList = weaponsList;
				targetOption = weaponsOption;
			} else if(item.type == Item.ARMOUR){
				targetList = armourList;
				targetOption = armourOption;
			} else if(item.type == Item.RUNE){
				targetList = runesList;
				targetOption = runesOption;
			} else if(item.type == Item.HEART){
				targetList = heartsList;
				targetOption = heartsOption;
			}
			if(!visited) targetOption.visited = false;
			
			if(item.type == Item.RUNE || item.type == Item.HEART){
				// first see if this item can go into an existing stack
				var itemStack:Item;
				var optionStack:MenuOptionStack;
				for(i = 0; i < targetList.options.length; i++){
					optionStack = targetList.options[i] as MenuOptionStack;
					itemStack = optionStack.userData as Item;
					if(item.stackable(itemStack)){
						itemStack.stacked = true;
						optionStack.total++;
						
						// since the new item was copyable - it now goes into the garbage
						// collector, preserving memory
						
						menu.update();
						return itemStack;
					}
				}
			}
			
			// set up what can be done with this item
			if(item.type == Item.WEAPON){
				usageOptions = weaponActionList;
				
			} else if(item.type == Item.ARMOUR){
				usageOptions = armourActionList;
				
			} else if(item.type == Item.HEART){
				// health items should be targetable under the same context
				context = "heart";
				usageOptions = heartActionList;
				
			} else if(item.type == Item.RUNE){
				usageOptions = runeActionList;
			}
			
			itemOption = new MenuOptionStack(item.toString(), usageOptions);
			itemOption.context = context;
			itemOption.userData = item;
			itemOption.help = item.getHelpText();
			itemToOption[item] = itemOption
			
			targetList.options.push(itemOption);
			targetList.selection = targetList.options.length - 1;
			if(targetList.options.length == 1){
				targetOption.active = true;
			}
			
			// equipment needs to be targetable by runes and so gets added to the equipment list
			if(item.type == Item.ARMOUR || item.type == Item.WEAPON){
				enchantableOption = new MenuOptionStack(item.toString());
				enchantableOption.selectionStep = 4;
				enchantableOption.userData = item;
				enchantableOption.help = item.getHelpText() + "\npress right to enchant this item";
				enchantableToOption[item] = enchantableOption;
				// make sure the enchant option is active
				enchantOption.active = true;
				if(item.type == Item.WEAPON){
					enchantableWeaponsList.options.push(enchantableOption);
					enchantableWeaponsList.selection = enchantableWeaponsList.options.length - 1;
					enchantableWeaponsOption.active = true;
				} else if(item.type == Item.ARMOUR){
					enchantableArmourList.options.push(enchantableOption);
					enchantableArmourList.selection = enchantableArmourList.options.length - 1;
					enchantableArmourOption.active = true;
				}
			}
			
			if(autoSort) sortEquipment()
			else menu.update();
			return item;
		}
		
		/* Inserts an item into the inventory using an XML */
		public function addItemFromXML(itemXML:XML, print:Boolean = false):Item{
			var item:Item = Content.XMLToEntity(0, 0, itemXML);
			item.collect(game.player, print);
			return item;
		}
		
		/* Removes an item from the menu tree. Used for dropping */
		public function removeItem(item:Item):Item{
			var option:MenuOptionStack = itemToOption[item];
			
			// first see if this item is in a stack
			if(option.total > 1){
				option.total--;
				if(option.total == 1) item.stacked = false;
				return item.copy();
			}
			
			var targetList:MenuList;
			var targetOption:MenuOption;
			if(item.type == Item.WEAPON){
				targetList = weaponsList;
				targetOption = weaponsOption;
			} else if(item.type == Item.ARMOUR){
				targetList = armourList;
				targetOption = armourOption;
			} else if(item.type == Item.RUNE){
				targetList = runesList;
				targetOption = runesOption;
			} else if(item.type == Item.HEART){
				targetList = heartsList;
				targetOption = heartsOption;
			}
			
			targetList.options.splice(targetList.options.indexOf(option), 1);
			
			// a reference to this item may still exist in a hot key map - we need to neutralise it
			option.active = false;
			itemToOption[item] = null;
			
			var enchantableTypeList:MenuList;
			var enchantableTypeOption:MenuOption;
			
			if(item.type == Item.WEAPON){
				enchantableTypeList = enchantableWeaponsList;
				enchantableTypeOption = enchantableWeaponsOption;
			} else if(item.type == Item.ARMOUR){
				enchantableTypeList = enchantableArmourList;
				enchantableTypeOption = enchantableArmourOption;
			}
			
			if(enchantableTypeList){
				var equipmentIndex:int = enchantableTypeList.options.indexOf(enchantableToOption[item]);
				if(equipmentIndex == enchantableTypeList.options.length - 1) enchantableTypeList.selection = 0;
				enchantableTypeList.options.splice(equipmentIndex, 1);
				// a reference to this item may still exist in a hot key map - we need to neutralise it
				enchantableToOption[item].active = false;
				enchantableToOption[item] = null;
				// if there is no equipment, there is nothing to enchant
				if(enchantableTypeList.options.length == 0){
					enchantableTypeOption.active = false;
					if(enchantableWeaponsList.options.length == 0 && enchantableArmourList.options.length == 0) enchantOption.active = false;
				// don't let the equipment option point to a blank space
				} else if(enchantableTypeList.selection >= enchantableTypeList.options.length){
					enchantableTypeList.selection = enchantableTypeList.options.length - 1;
				}
			}
			
			// block empty lists
			if(targetList.options.length == 0){
				targetOption.active = false;
				
			// don't let the target option point to a blank space
			} else if(targetList.selection >= targetList.options.length){
				targetList.selection = targetList.options.length - 1;
			}
			
			// if this is being called from Effect.enchant and there is only one item in the enchantables list
			// menu.update() will crash the game - walking back to the trunk is necessary
			if(menu.currentMenuList.options.length == 0) while(menu.previousMenuList) menu.stepLeft();
			
			menu.update();
			
			return item;
		}
		
		/* Resets the name of an option linked to this item - called when equipping items */
		public function updateItem(item:Item):void{
			itemToOption[item].name = item.toString();
			itemToOption[item].help = item.getHelpText();
			if(item.type == Item.ARMOUR || item.type == Item.WEAPON){
				enchantableToOption[item].name = item.nameToString();
				enchantableToOption[item].help = item.getHelpText() + "\nstep right to enchant this item";
			}
			menu.update();
		}
		
		/* Return the first matching item */
		public function getItem(name:int, type:int):Item{
			var i:int, item:Item, list:MenuList;
			if(type == Item.ARMOUR) list = armourList;
			else if(type == Item.WEAPON) list = weaponsList;
			else if(type == Item.RUNE) list = runesList;
			else if(type == Item.HEART) list = heartsList;
			if(list){
				for(i = 0; i < list.options.length; i++){
					item = list.options[i].userData as Item;
					if(item.name == name) return item;
				}
			}
			return null;
		}
		
		/* Iterates through the runes in the inventory and identifies them */
		public function identifyRunes():void{
			var i:int, rune:Item;
			for(i = 0; i < runesList.options.length; i++){
				rune = runesList.options[i].userData as Item;
				Item.revealName(rune.name, runesList);
			}
		}
		
		/* Iterates through the equipment in the inventory and reveals any curses */
		public function revealCurses():void{
			var i:int, item:Item;
			for(i = 0; i < weaponsList.options.length; i++){
				item = weaponsList.options[i].userData as Item;
				if(item.holyState == Item.CURSE_HIDDEN){
					item.revealCurse(true);
					updateItem(item);
				}
			}
			for(i = 0; i < armourList.options.length; i++){
				item = armourList.options[i].userData as Item;
				if(item.holyState == Item.CURSE_HIDDEN){
					item.revealCurse(true);
					updateItem(item);
				}
			}
		}
		
		/* Does a basic ordering of items based on stats */
		public function sortEquipment():void{
			weaponsList.selection = 0;
			armourList.selection = 0;
			enchantableWeaponsList.selection = 0;
			enchantableArmourList.selection = 0;
			weaponsList.options.sort(weaponSortCallback);
			armourList.options.sort(armourSortCallback);
			enchantableWeaponsList.options.sort(weaponSortCallback);
			enchantableArmourList.options.sort(armourSortCallback);
			//var i:int;
			//trace("");
			//for(i = 0; i < weaponsList.options.length; i++){
				//trace(weaponsList.options[i].name, getWeaponValue(weaponsList.options[i].userData as Item));
			//}
			menu.update();
		}
		
		private function weaponSortCallback(a:MenuOption, b:MenuOption):Number{
			var aValue:Number = getWeaponValue(a.userData as Item);
			var bValue:Number = getWeaponValue(b.userData as Item);
			if(aValue > bValue) return -1;
			else if(aValue < bValue) return 1;
			return 0;
		}
		
		private function getWeaponValue(item:Item):Number{
			return item.damage + item.attack * 10 + item.knockback / Character.KNOCKBACK_DIST + item.stun + item.butcher + item.leech;
		}
		
		private function armourSortCallback(a:MenuOption, b:MenuOption):Number{
			var aValue:Number = getArmourValue(a.userData as Item);
			var bValue:Number = getArmourValue(b.userData as Item);
			if(aValue > bValue) return -1;
			else if(aValue < bValue) return 1;
			return 0;
		}
		
		private function getArmourValue(item:Item):Number{
			return item.defence * 10 + item.endurance + item.thorns;
		}
		
		/* Create a description of the inventory for the epitaph file */
		public function getEpitaph():String{
			var i:int, item:Item;
			var str:String = "INVENTORY:\n";
			str += "\nweapons:";
			if(weaponsList.options.length){
				for(i = 0; i < weaponsList.options.length; i++){
					item = weaponsList.options[i].userData as Item;
					if(item) str += " " + item.getEpitaph();
					if(i < weaponsList.options.length - 1) str += ",";
				}
			} else {
				str += " none";
			}
			str += "\narmour:";
			if(armourList.options.length){
				for(i = 0; i < armourList.options.length; i++){
					item = armourList.options[i].userData as Item;
					if(item) str += " " + item.getEpitaph();
					if(i < armourList.options.length - 1) str += ",";
				}
			} else {
				str += " none";
			}
			str += "\nrunes:";
			if(runesList.options.length){
				for(i = 0; i < runesList.options.length; i++){
					item = runesList.options[i].userData as Item;
					if(item) str += " " + item.getEpitaph();
					if(i < runesList.options.length - 1) str += ",";
				}
			} else {
				str += " none";
			}
			str += "\n\hearts:";
			if(heartsList.options.length){
				for(i = 0; i < heartsList.options.length; i++){
					item = heartsList.options[i].userData as Item;
					if(item) str += " " + item.getEpitaph();
					if(i < heartsList.options.length - 1) str += ",";
				}
			} else {
				str += " none";
			}
			return str;
		}
		
		/* Create an object for the SharedObject to save inventory data */
		public function saveToObject():Object{
			var obj:Object = {
				weapons:[],
				armour:[],
				runes:[],
				hearts:[]
			}
			var i:int, item:Item, optionStack:MenuOptionStack, stack:int;
			if(weaponsList.options.length){
				for(i = 0; i < weaponsList.options.length; i++){
					item = weaponsList.options[i].userData as Item;
					if(item) obj.weapons.push(item.toXML());
				}
			}
			if(armourList.options.length){
				for(i = 0; i < armourList.options.length; i++){
					item = armourList.options[i].userData as Item;
					if(item) obj.armour.push(item.toXML());
				}
			}
			if(runesList.options.length){
				for(i = 0; i < runesList.options.length; i++){
					optionStack = runesList.options[i] as MenuOptionStack;
					stack = optionStack.total;
					item = runesList.options[i].userData as Item;
					if(item) while(stack--) obj.runes.push(item.toXML());
				}
			}
			if(heartsList.options.length){
				for(i = 0; i < heartsList.options.length; i++){
					optionStack = heartsList.options[i] as MenuOptionStack;
					stack = optionStack.total;
					item = heartsList.options[i].userData as Item;
					if(item) while(stack--) obj.hearts.push(item.toXML());
				}
			}
			return obj;
		}
		
		/* Load the items from the save object */
		public function loadFromObject(obj:Object):void{
			var items:Array = [obj.weapons, obj.armour, obj.runes, obj.hearts];
			var i:int, j:int, itemList:Array, item:Item, xml:XML;
			
			var playerName:String = game.player.nameToString();
			var minionName:String = game.minion ? game.minion.nameToString() : null;
			var userName:String, equippedToThrowable:Boolean;
			
			for(i = 0; i < items.length; i++){
				itemList = items[i];
				for(j = 0; j < itemList.length; j++){
					xml = itemList[j];
					item = addItemFromXML(xml);
					userName = xml.@user;
					if(int(xml.@location) == Item.EQUIPPED){
						equippedToThrowable = xml.@equippedToThrowable == "true";
						// sanity checks to prevent stacked equipping
						if(userName == playerName){
							if(
								(item.type == Item.ARMOUR && !game.player.armour) ||
								(item.type == Item.WEAPON && !equippedToThrowable && !game.player.weapon) ||
								(item.type == Item.WEAPON && equippedToThrowable && !game.player.throwable)
							){
								game.player.equip(item, equippedToThrowable);
							}
						} else if(game.minion && userName == minionName){
							if(
								(item.type == Item.ARMOUR && !game.minion.armour) ||
								(item.type == Item.WEAPON && !equippedToThrowable && !game.minion.weapon) ||
								(item.type == Item.WEAPON && equippedToThrowable && !game.minion.throwable)
							){
								game.minion.equip(item, equippedToThrowable);
							}
						}
					}
				}
			}
		}
	}

}