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
		
		public var equipment_list:MenuList;
		
		public var item_list:MenuList;
		public var bow_list:MenuList;
		public var rune_list:MenuList;
		public var heart_list:MenuList;
		public var enchantment_list:EnchantmentList;
		
		public var equip_option:ToggleMenuOption;
		public var equip_minion_option:ToggleMenuOption;
		public var drop_option:MenuOption;
		public var eat_option:MenuOption;
		public var feed_minion_option:MenuOption;
		public var enchant_option:MenuOption
		public var throw_option:MenuOption;
		public var shoot_option:MenuOption;
		public var enchantments_option:MenuOption;
		
		public var item_to_option:Dictionary;
		public var equipment_to_option:Dictionary;
		
		public function InventoryMenuList(menu:Menu, g:Game) {
			super();
			this.menu = menu;
			this.g = g;
			// MENU LISTS
			
			equipment_list = new MenuList();
			
			item_list = new MenuList();
			bow_list = new MenuList();
			rune_list = new MenuList();
			heart_list = new MenuList();
			enchantment_list = new EnchantmentList();
			
			// MENU OPTIONS
			
			enchant_option = new MenuOption("enchant", equipment_list, false);
			
			equip_option = new ToggleMenuOption(["equip", "unequip"]);
			equip_minion_option = new ToggleMenuOption(["equip minion", "unequip minion"]);
			drop_option = new MenuOption("drop");
			eat_option = new MenuOption("eat");
			feed_minion_option = new MenuOption("feed minion");
			throw_option = new MenuOption("throw");
			shoot_option = new MenuOption("shoot");
			enchantments_option = new MenuOption("enchantments", enchantment_list);
			
			enchantment_list.pointers = new Vector.<MenuOption>();
			enchantment_list.pointers.push(enchantments_option);
			
			// OPTION ARRAYS
			
			item_list.options.push(equip_option);
			item_list.options.push(drop_option);
			item_list.options.push(equip_minion_option);
			item_list.options.push(enchantments_option);
			
			bow_list.options.push(equip_option);
			bow_list.options.push(shoot_option);
			bow_list.options.push(drop_option);
			bow_list.options.push(equip_minion_option);
			bow_list.options.push(enchantments_option);
			
			rune_list.options.push(enchant_option);
			rune_list.options.push(eat_option);
			rune_list.options.push(throw_option);
			rune_list.options.push(feed_minion_option);
			rune_list.options.push(drop_option);
			
			heart_list.options.push(eat_option);
			heart_list.options.push(drop_option);
			
			item_to_option = new Dictionary(true);
			equipment_to_option = new Dictionary(true);
		}
		
		public function reset():void{
			selection = 0;
			options = new Vector.<MenuOption>();
			equipment_list.options = new Vector.<MenuOption>();
			item_to_option = new Dictionary(true);
			equipment_to_option = new Dictionary(true);
			enchant_option.active = false;
		}
		
		/* Adds a new menu item and selects that item on the MenuList */
		public function addItem(item:Item, stack:Boolean = true):Item{
			var equipment_option:MenuOptionStack, item_option:MenuOptionStack, usage_options:MenuList, i:int, context:String;
			
			if(stack){
				// first see if this item can go into an existing stack
				var item_stack:Item;
				for(i = 0; i < options.length; i++){
					item_stack = options[i].target as Item;
					if(item.stackable(item_stack)){
						item_stack.stacked = true;
						(options[i] as MenuOptionStack).total++;
						
						// since the new item was copyable - it now goes into the garbage
						// collector, preserving memory
						
						// update the menu and return
						menu.selection = menu.current_menu_list.selection;
						return item_stack;
					}
				}
			}
			
			// set up what can be done with this item
			if(item.type == Item.ARMOUR || item.type == Item.WEAPON){
				if(item.type == Item.WEAPON && item.name == Item.BOW) usage_options = bow_list;
				else usage_options = item_list;
			} else if(item.type == Item.HEART){
				// health items should be targetable under the same context
				context = "heart";
				usage_options = heart_list;
			} else if(item.type == Item.RUNE){
				usage_options = rune_list;
			}
			
			item_option = new MenuOptionStack(item.toString(), usage_options);
			item_option.context = context;
			item_option.target = item;
			item_option.help = item.getHelpText();
			options.push(item_option);
			selection = options.length - 1;
			item_to_option[item] = item_option
			
			// equipment needs to be targetable by runes and so gets added to the equipment list
			if(item.type == Item.ARMOUR || item.type == Item.WEAPON){
				equipment_option = new MenuOptionStack(item.toString());
				equipment_option.target = item;
				equipment_option.help = item.getHelpText() + "\nstep right to enchant this item";
				equipment_list.options.push(equipment_option);
				equipment_list.selection = equipment_list.options.length - 1;
				equipment_to_option[item] = equipment_option;
				// make sure the enchant option is active
				enchant_option.active = true;
			}
			
			if(options.length == 1){
				// this list has just become viable - activate pointers to it
				for(i = 0; i < pointers.length; i++){
					pointers[i].active = true;
				}
			}
			// update the menu
			menu.selection = menu.current_menu_list.selection;
			return item;
		}
		
		/* Removes an item from the menu tree. Used for dropping */
		public function removeItem(item:Item):Item{
			
			// first see if this item is in a stack
			if(item_to_option[item].total > 1){
				item_to_option[item].total--;
				if(item_to_option[item].total == 1) item.stacked = false;
				return item.copy();
			}
			
			var item_index:int = options.indexOf(item_to_option[item]);
			if(item_index == options.length - 1) selection = 0;
			options.splice(item_index, 1);
			// a reference to this item may still exist in a hot key map - we need to neutralise it
			item_to_option[item].active = false;
			item_to_option[item] = null;
			
			if(item.type == Item.ARMOUR || item.type == Item.WEAPON){
				var equipment_index:int = equipment_list.options.indexOf(equipment_to_option[item]);
				if(equipment_index == equipment_list.options.length - 1) equipment_list.selection = 0;
				equipment_list.options.splice(equipment_index, 1);
				// a reference to this item may still exist in a hot key map - we need to neutralise it
				equipment_to_option[item].active = false;
				equipment_to_option[item] = null;
				// if there is no equipment, there is nothing to enchant
				if(equipment_list.options.length == 0){
					enchant_option.active = false;
				// don't let the equipment option point to a blank space
				} else if(equipment_list.selection >= equipment_list.options.length){
					equipment_list.selection = equipment_list.options.length - 1;
				}
			}
			if(options.length == 0){
				// block all access to this list
				for(var i:int = 0; i < pointers.length; i++){
					pointers[i].active = false;
				}
			// don't let the inventory option point to a blank space
			} else if(selection >= options.length){
				selection = options.length - 1;
			}
			
			// update the menu
			if(menu.current_menu_list.options.length) menu.selection = menu.current_menu_list.selection;
			return item;
		}
		
		/* If the item is in a stack, this method decrements the stack and returns a copy,
		 * or otherwise returns the object provided */
		public function unstack(item:Item):Item{
			if(item.stacked){
				item_to_option[item].total--;
				if(item_to_option[item].total == 1){
					item.stacked = false;
				}
				var item_copy:Item = item.copy();
				addItem(item_copy, false);
				return item_copy;
			}
			return item;
		}
		
		/* This loads an item into an existing stack if one exists */
		public function stack(item:Item):Item{
			// first see if this item can go into an existing stack
			
			//trace("\nstack attempt");
			
			var item_stack:Item;
			for(var i:int = 0; i < options.length; i++){
				item_stack = options[i].target as Item;
				
				//trace(item + " to " + item_stack);
				
				if(item.stackable(item_stack)){
					
					//trace("stacked");
					
					item_stack.stacked = true;
					(options[i] as MenuOptionStack).total++;
					// given that the item is still in the options list, it needs removing
					removeItem(item);
					
					return item_stack;
				}
			}
			return item;
		}
		
		/* Resets the name of an option linked to this item - called when equipping items */
		public function updateItem(item:Item):void{
			item_to_option[item].name = item.toString();
			item_to_option[item].help = item.getHelpText();
			if(item.type == Item.ARMOUR || item.type == Item.WEAPON){
				equipment_to_option[item].name = item.toString();
				equipment_to_option[item].help = item.getHelpText() + "\nstep right to enchant this item";
			}
			menu.selection = menu.current_menu_list.selection;
		}
	}

}