package com.robotacid.ui.menu {
	import flash.utils.Dictionary;
	import com.robotacid.engine.Item;
	
	/**
	 * A special MenuList just for the inventory, because managing the items is quite complicated
	 * and makes quite mess on its own without having all the other game options farting around it
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class InventoryMenuList extends MenuList{
		
		public var g:Game;
		public var menu:Menu;
		
		public var equipmentList:MenuList;
		
		public var itemList:MenuList;
		public var runeList:MenuList;
		public var heartList:MenuList;
		public var enchantmentList:EnchantmentList;
		
		public var equipOption:ToggleMenuOption;
		public var equipMinionOption:ToggleMenuOption;
		public var dropOption:MenuOption;
		public var eatOption:MenuOption;
		public var feedMinionOption:MenuOption;
		public var enchantOption:MenuOption
		public var throwOption:MenuOption;
		public var enchantmentsOption:MenuOption;
		
		public var itemToOption:Dictionary;
		public var equipmentToOption:Dictionary;
		
		public function InventoryMenuList(menu:Menu, g:Game) {
			super();
			this.menu = menu;
			this.g = g;
			
			// MENU LISTS
			
			equipmentList = new MenuList();
			
			itemList = new MenuList();
			runeList = new MenuList();
			heartList = new MenuList();
			enchantmentList = new EnchantmentList();
			
			// MENU OPTIONS
			
			enchantOption = new MenuOption("enchant", equipmentList, false);
			
			equipOption = new ToggleMenuOption(["equip", "unequip"]);
			equipMinionOption = new ToggleMenuOption(["equip minion", "unequip minion"]);
			dropOption = new MenuOption("drop");
			eatOption = new MenuOption("eat");
			feedMinionOption = new MenuOption("feed minion");
			throwOption = new MenuOption("throw");
			enchantmentsOption = new MenuOption("enchantments", enchantmentList);
			
			enchantmentList.pointers = new Vector.<MenuOption>();
			enchantmentList.pointers.push(enchantmentsOption);
			
			// OPTION ARRAYS
			
			itemList.options.push(equipOption);
			itemList.options.push(dropOption);
			itemList.options.push(equipMinionOption);
			itemList.options.push(enchantmentsOption);
			
			runeList.options.push(enchantOption);
			runeList.options.push(eatOption);
			runeList.options.push(throwOption);
			runeList.options.push(feedMinionOption);
			runeList.options.push(dropOption);
			
			heartList.options.push(eatOption);
			heartList.options.push(feedMinionOption);
			heartList.options.push(dropOption);
			
			itemToOption = new Dictionary(true);
			equipmentToOption = new Dictionary(true);
		}
		
		public function reset():void{
			selection = 0;
			options = new Vector.<MenuOption>();
			equipmentList.options = new Vector.<MenuOption>();
			itemToOption = new Dictionary(true);
			equipmentToOption = new Dictionary(true);
			enchantOption.active = false;
		}
		
		/* Adds a new menu item and selects that item on the MenuList */
		public function addItem(item:Item, stack:Boolean = true):Item{
			var equipmentOption:MenuOptionStack, itemOption:MenuOptionStack, usageOptions:MenuList, i:int, context:String;
			
			if(stack){
				// first see if this item can go into an existing stack
				var itemStack:Item;
				for(i = 0; i < options.length; i++){
					itemStack = options[i].userData as Item;
					if(item.stackable(itemStack)){
						itemStack.stacked = true;
						(options[i] as MenuOptionStack).total++;
						
						// since the new item was copyable - it now goes into the garbage
						// collector, preserving memory
						
						menu.update();
						return itemStack;
					}
				}
			}
			
			// set up what can be done with this item
			if(item.type == Item.ARMOUR || item.type == Item.WEAPON){
				usageOptions = itemList;
				
			} else if(item.type == Item.HEART){
				// health items should be targetable under the same context
				context = "heart";
				usageOptions = heartList;
				
			} else if(item.type == Item.RUNE){
				usageOptions = runeList;
			}
			
			itemOption = new MenuOptionStack(item.toString(), usageOptions);
			itemOption.context = context;
			itemOption.userData = item;
			itemOption.help = item.getHelpText();
			options.push(itemOption);
			selection = options.length - 1;
			itemToOption[item] = itemOption
			
			// equipment needs to be targetable by runes and so gets added to the equipment list
			if(item.type == Item.ARMOUR || item.type == Item.WEAPON){
				equipmentOption = new MenuOptionStack(item.toString());
				equipmentOption.userData = item;
				equipmentOption.help = item.getHelpText() + "\npress right to enchant this item";
				equipmentList.options.push(equipmentOption);
				equipmentList.selection = equipmentList.options.length - 1;
				equipmentToOption[item] = equipmentOption;
				// make sure the enchant option is active
				enchantOption.active = true;
			}
			
			if(options.length == 1){
				// this list has just become viable - activate pointers to it
				for(i = 0; i < pointers.length; i++){
					pointers[i].active = true;
					pointers[i].recordable = true;
				}
			}
			
			menu.update();
			return item;
		}
		
		/* Removes an item from the menu tree. Used for dropping */
		public function removeItem(item:Item):Item{
			
			// first see if this item is in a stack
			if(itemToOption[item].total > 1){
				itemToOption[item].total--;
				if(itemToOption[item].total == 1) item.stacked = false;
				return item.copy();
			}
			
			var itemIndex:int = options.indexOf(itemToOption[item]);
			
			options.splice(itemIndex, 1);
			// a reference to this item may still exist in a hot key map - we need to neutralise it
			itemToOption[item].active = false;
			itemToOption[item] = null;
			
			if(item.type == Item.ARMOUR || item.type == Item.WEAPON){
				var equipmentIndex:int = equipmentList.options.indexOf(equipmentToOption[item]);
				if(equipmentIndex == equipmentList.options.length - 1) equipmentList.selection = 0;
				equipmentList.options.splice(equipmentIndex, 1);
				// a reference to this item may still exist in a hot key map - we need to neutralise it
				equipmentToOption[item].active = false;
				equipmentToOption[item] = null;
				// if there is no equipment, there is nothing to enchant
				if(equipmentList.options.length == 0){
					enchantOption.active = false;
				// don't let the equipment option point to a blank space
				} else if(equipmentList.selection >= equipmentList.options.length){
					equipmentList.selection = equipmentList.options.length - 1;
				}
			}
			if(options.length == 0){
				// block all access to this list
				for(var i:int = 0; i < pointers.length; i++){
					pointers[i].active = false;
					pointers[i].recordable = false;
				}
			// don't let the inventory option point to a blank space
			} else if(selection >= options.length){
				selection = options.length - 1;
			}
			
			// update the menu
			if(menu.currentMenuList.options.length) menu.update();
			return item;
		}
		
		/* If the item is in a stack, this method decrements the stack and returns a copy,
		 * or otherwise returns the object provided */
		public function unstack(item:Item):Item{
			if(item.stacked){
				itemToOption[item].total--;
				if(itemToOption[item].total == 1){
					item.stacked = false;
				}
				var itemCopy:Item = item.copy();
				addItem(itemCopy, false);
				return itemCopy;
			}
			return item;
		}
		
		/* This loads an item into an existing stack if one exists */
		public function stack(item:Item):Item{
			// first see if this item can go into an existing stack
			
			//trace("\nstack attempt");
			
			var itemStack:Item;
			for(var i:int = 0; i < options.length; i++){
				itemStack = options[i].userData as Item;
				
				//trace(item + " to " + itemStack);
				
				if(item.stackable(itemStack)){
					
					//trace("stacked");
					
					itemStack.stacked = true;
					(options[i] as MenuOptionStack).total++;
					// given that the item is still in the options list, it needs removing
					removeItem(item);
					
					return itemStack;
				}
			}
			return item;
		}
		
		/* Resets the name of an option linked to this item - called when equipping items */
		public function updateItem(item:Item):void{
			itemToOption[item].name = item.toString();
			itemToOption[item].help = item.getHelpText();
			if(item.type == Item.ARMOUR || item.type == Item.WEAPON){
				equipmentToOption[item].name = item.toString();
				equipmentToOption[item].help = item.getHelpText() + "\nstep right to enchant this item";
			}
			menu.update();
		}
	}

}