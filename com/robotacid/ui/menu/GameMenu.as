package com.robotacid.ui.menu {
	import com.robotacid.engine.Character;
	import com.robotacid.engine.CharacterAttributes;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.Missile;
	import com.robotacid.engine.Stairs;
	import com.robotacid.sound.SoundManager;
	import flash.events.Event;
	
	/**
	 * This is a situ-specific menu specially for this game
	 * 
	 * It has extra variables defining references to game menu options
	 * and it sets up a majority of the core menu elements in the constructor
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class GameMenu extends Menu{
		
		public var g:Game;
		
		// tier 1
		// branch 0
		
		// tier 2
		public var inventory_list:InventoryMenuList;
		public var inventory_option:MenuOption;
		public var options_list:MenuList;
		public var stairs_option:MenuOption;
		public var stairs_list:MenuList;
		
		// tier 3
		public var go_up_down_option:ToggleMenuOption;
		public var reset_list:MenuList;
		public var reset_option:MenuOption;
		public var sure_list:MenuList;
		public var sure_option:MenuOption;
		
		// tier 4
		public var on_off_list:MenuList;
		public var on_off_option:ToggleMenuOption;
		
		public function GameMenu(width:Number, height:Number, g:Game) {
			this.g = g;
			super(width, height);
			init();
		}
		
		/* This is where all of the pre-amble goes, the aim is to make this as readable
		 * as possible, so it will end up being quite long.
		 */
		public function init():void{
			// MENU LISTS
			
			// tier 1
			var trunk:MenuList = new MenuList();
			// tier 2
			inventory_list = new InventoryMenuList(this, g);
			options_list = new MenuList();
			stairs_list = new MenuList();
			// tier 3
			reset_list = new MenuList();
			
			on_off_list = new MenuList();
			sure_list = new MenuList();
			
			// MENU OPTIONS
			
			// tier 1
			inventory_option = new MenuOption("inventory", inventory_list, false);
			inventory_option.help = "a list of items the rogue currently possesses in her\nhandbag of holding";
			inventory_list.pointers = new Vector.<MenuOption>();
			inventory_list.pointers.push(inventory_option);
			var options_option:MenuOption = new MenuOption("options", options_list);
			options_option.help = "change game settings";
			stairs_option = new MenuOption("stairs", stairs_list, false);
			
			// tier 2
			var change_keys_option:MenuOption = Menu.createChangeKeysMenuOption();
			change_keys_option.help = "change the movement keys, menu key and hot keys"
			var hot_key_deactivates:Vector.<MenuOption> = new Vector.<MenuOption>();
			hot_key_deactivates.push(change_keys_option);
			var hot_key_option:MenuOption = Menu.createHotKeyMenuOption(trunk, hot_key_deactivates);
			hot_key_option.help = "set up a key to perform a menu action\nthe hot key will work even if the menu is hidden\nthe hot key will also adapt to menu changes";
			
			var sound_option:MenuOption = new MenuOption("sound", on_off_list);
			sound_option.help = "toggle sound";
			reset_option = new MenuOption("reset", sure_list);
			reset_option.help = "start a new game";
			
			go_up_down_option = new ToggleMenuOption(["go up", "go down"]);
			
			// tier 3
			on_off_option = new ToggleMenuOption(["off", "on"]);
			sure_option = new MenuOption("sure?");
			
			// OPTION ARRAYS
			
			trunk.options.push(inventory_option);
			trunk.options.push(options_option);
			trunk.options.push(stairs_option);
			
			options_list.options.push(sound_option);
			options_list.options.push(change_keys_option);
			options_list.options.push(hot_key_option);
			options_list.options.push(reset_option);
			
			stairs_list.options.push(go_up_down_option);
			
			reset_list.options.push(reset_option);
			
			sure_list.options.push(sure_option);
			
			on_off_list.options.push(on_off_option);
			
			setTrunk(trunk);
			
			addEventListener(Event.CHANGE, change);
			addEventListener(Event.SELECT, select);
			
			var option:MenuOption = current_menu_list.options[_selection];
			help.text = option.help;
			
		}
		
		public function change(e:Event = null):void{
			
			var option:MenuOption = current_menu_list.options[_selection];
			
			if(parent && option.help){
				help.text = option.help;
			}
			
			if(option.target is Item){
				var item:Item = option.target;
				if(item.type == Item.WEAPON || item.type == Item.ARMOUR){
					if(item.type == Item.WEAPON && item.name == Item.BOW){
						inventory_list.shoot_option.active = (item.state == Item.EQUIPPED);
					}
					inventory_list.equip_option.state = item.state == Item.EQUIPPED ? 1 : 0;
					inventory_list.equip_minion_option.state = (g.minion && item.state == Item.MINION_EQUIPPED) ? 1 : 0;
					inventory_list.equip_minion_option.active = Boolean(g.minion);
					inventory_list.enchantment_list.update(item);
					// cursed items disable equipping items of that type, they cannot be dropped either
					if(item.type == Item.WEAPON && g.player.weapon && g.player.weapon.curse_state == Item.CURSE_REVEALED){
						inventory_list.equip_option.active = false;
						inventory_list.equip_minion_option.active = false;
					} else if(item.type == Item.ARMOUR && g.player.armour && g.player.armour.curse_state == Item.CURSE_REVEALED){
						inventory_list.equip_option.active = false;
						inventory_list.equip_minion_option.active = false;
					} else {
						inventory_list.equip_option.active = true;
					}
					inventory_list.drop_option.active = item.curse_state != Item.CURSE_REVEALED
				} else if(item.type == Item.HEART){
					if(!hot_key_map_record) inventory_list.eat_option.active = g.player.health < g.player.total_health;
					else inventory_list.eat_option.active = true;
				} else if(item.type == Item.RUNE){
					inventory_list.eat_option.active = true;
					inventory_list.feed_minion_option.active = Boolean(g.minion);
					if(item.name == Item.XP){
						if(g.minion) inventory_list.feed_minion_option.active = g.minion.level < Game.MAX_LEVEL;
						inventory_list.eat_option.active = g.player.level < Game.MAX_LEVEL;
					}
				}
				renderMenu();
			} else if(option.name == "sound"){
				on_off_option.state = SoundManager.sfx ? 0 : 1;
				renderMenu();
			} else if(option == inventory_list.enchant_option){
				var rune_name:int = inventory_list.options[inventory_list.selection].target.name;
				for(var i:int = 0; i < inventory_list.equipment_list.options.length; i++){
					inventory_list.equipment_list.options[i].active = inventory_list.equipment_list.options[i].target.enchantable(rune_name);
				}
			}
		}
		
		public function select(e:Event = null):void{
			var option:MenuOption = current_menu_list.options[_selection];
			var item:Item, n:int, i:int, effect:Effect;
			
			// equipping items on the player
			if(option == inventory_list.equip_option){
				item = previous_menu_list.options[previous_menu_list.selection].target;
				if(item.state == Item.EQUIPPED){
					g.player.unequip(item);
				} else {
					if(item.type == Item.WEAPON){
						if(g.player.weapon) g.player.unequip(g.player.weapon);
						if(g.minion && g.minion.weapon && g.minion.weapon == item) g.minion.unequip(g.minion.weapon);
					}
					if(item.type == Item.ARMOUR){
						if(g.player.armour) g.player.unequip(g.player.armour);
						if(g.minion && g.minion.armour && g.minion.armour == item) g.minion.unequip(g.minion.armour);
					}
					item = g.player.equip(item);
				}
				g.player.updateMC();
				if(g.minion) g.minion.updateMC();
			
			// equipping items on minions
			} else if(option == inventory_list.equip_minion_option){
				item = previous_menu_list.options[previous_menu_list.selection].target;
				if(item.state == Item.MINION_EQUIPPED){
					g.minion.unequip(item);
				} else {
					if(item.type == Item.WEAPON){
						if(g.minion.weapon) g.minion.unequip(g.minion.weapon);
						if(g.player.weapon && g.player.weapon == item) g.player.unequip(g.player.weapon);
					}
					if(item.type == Item.ARMOUR){
						if(g.minion.armour) g.minion.unequip(g.minion.armour);
						if(g.player.armour && g.player.armour == item) g.player.unequip(g.player.armour);
					}
					item = g.minion.equip(item);
				}
				g.player.updateMC();
				g.minion.updateMC();
				
			// dropping items
			} else if(option == inventory_list.drop_option){
				item = previous_menu_list.options[previous_menu_list.selection].target;
				if(item.state == Item.EQUIPPED){
					item = g.player.unequip(item);
				}
				if(g.minion && item.state == Item.MINION_EQUIPPED){
					item = g.minion.unequip(item);
				}
				item = inventory_list.removeItem(item);
				item.dropToMap(g.player.map_x, g.player.map_y);
				g.entities.push(item);
				
			// eating items
			} else if(option == inventory_list.eat_option){
				item = previous_menu_list.options[previous_menu_list.selection].target;
				if(item.type == Item.HEART){
					g.player.applyHealth(CharacterAttributes.NAME_HEALTHS[item.name] + CharacterAttributes.NAME_HEALTH_LEVELS[item.level]);
				} else if(item.type == Item.RUNE){
					Item.revealName(item.name, inventory_list);
					effect = new Effect(item.name, 20, Effect.EATEN, g, g.player);
				}
				inventory_list.removeItem(item);
				n = g.player.loot.indexOf(item);
				if(n > -1) g.player.loot.splice(n , 1);
				g.console.print("rogue eats " + item.nameToString());
			
			// feeding runes to the minion
			} else if(option == inventory_list.feed_minion_option){
				item = previous_menu_list.options[previous_menu_list.selection].target;
				Item.revealName(item.name, inventory_list);
				effect = new Effect(item.name, 20, Effect.EATEN, g, g.minion);
				inventory_list.removeItem(item);
				n = g.player.loot.indexOf(item);
				if(n > -1) g.player.loot.splice(n , 1);
				g.console.print("minion eats " + item.nameToString());
			
			// resetting the game
			} else if(option == sure_option){
				if(previous_menu_list.options[previous_menu_list.selection] == reset_option){
					inventory_list.reset();
					inventory_option.active = false;
					g.reset();
				}
			
			// turning off sound
			} else if(option == on_off_option){
				if(previous_menu_list.options[previous_menu_list.selection].name == "sound"){
					SoundManager.sfx = on_off_option.state == 1;
				}
			
			// shooting the bow
			} else if(option == inventory_list.shoot_option){
				g.player.shoot(Missile.ARROW);
			
			
			// throwing runes
			} else if(option == inventory_list.throw_option){
				item = previous_menu_list.options[previous_menu_list.selection].target;
				item = inventory_list.removeItem(item);
				g.player.shoot(Missile.RUNE, new Effect(item.name, 20, Effect.THROWN, g));
			
			
			// enchanting items
			} else if(previous_menu_list.options[previous_menu_list.selection] == inventory_list.enchant_option){
				item = option.target;
				var rune:Item = inventory_list.options[inventory_list.selection].target;
				
				effect = new Effect(rune.name, 1, 0, g);
				
				Item.revealName(rune.name, inventory_list);
				
				item = effect.enchant(item, inventory_list);
				
				rune = inventory_list.removeItem(rune);
				g.console.print(item.nameToString() + " enchanted with " + rune.nameToString());
			
			// exit the level
			} else if(option == go_up_down_option){
				g.player.exitLevel(go_up_down_option.target as Stairs);
				stairs_option.active = false;
			}
		}
		/* In the event of player death, we need to change the menu to deactivate the inventory,
		 * and maybe some other stuff in future
		 */
		public function death():void{
			for(var i:int = 0; i < branch.length; i++){
				if(branch[i] == inventory_list){
					while(branch.length > 1) stepBack();
					break;
				}
			}
			inventory_option.active = false;
			// update
			selection = _selection;
		}
		
	}

}