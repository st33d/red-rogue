package com.robotacid.ui.menu {
	import com.robotacid.engine.Character;
	import com.robotacid.engine.CharacterAttributes;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.Missile;
	import com.robotacid.engine.Stairs;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.QuickSave;
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
		public var inventoryList:InventoryMenuList;
		public var inventoryOption:MenuOption;
		public var optionsList:MenuList;
		public var stairsOption:MenuOption;
		public var stairsList:MenuList;
		
		// tier 3
		public var goUpDownOption:ToggleMenuOption;
		public var loadOption:MenuOption;
		public var saveOption:MenuOption;
		public var newGameOption:MenuOption;
		public var sureList:MenuList;
		public var sureOption:MenuOption;
		
		// tier 4
		public var onOffList:MenuList;
		public var onOffOption:ToggleMenuOption;
		
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
			inventoryList = new InventoryMenuList(this, g);
			optionsList = new MenuList();
			stairsList = new MenuList();
			// tier 3
			
			onOffList = new MenuList();
			sureList = new MenuList();
			
			// MENU OPTIONS
			
			// tier 1
			inventoryOption = new MenuOption("inventory", inventoryList, false);
			inventoryOption.help = "a list of items the rogue currently possesses in her\nhandbag of holding";
			inventoryList.pointers = new Vector.<MenuOption>();
			inventoryList.pointers.push(inventoryOption);
			var optionsOption:MenuOption = new MenuOption("options", optionsList);
			optionsOption.help = "change game settings";
			stairsOption = new MenuOption("stairs", stairsList, false);
			
			// tier 2
			var changeKeysOption:MenuOption = Menu.createChangeKeysMenuOption();
			changeKeysOption.help = "change the movement keys, menu key and hot keys"
			var hotKeyDeactivates:Vector.<MenuOption> = new Vector.<MenuOption>();
			hotKeyDeactivates.push(changeKeysOption);
			var hotKeyOption:MenuOption = Menu.createHotKeyMenuOption(trunk, hotKeyDeactivates);
			hotKeyOption.help = "set up a key to perform a menu action\nthe hot key will work even if the menu is hidden\nthe hot key will also adapt to menu changes";
			
			var soundOption:MenuOption = new MenuOption("sound", onOffList);
			soundOption.help = "toggle sound";
			loadOption = new MenuOption("load", sureList);
			loadOption.help = "load a saved game\nplayer status is saved automatically when\nusing stairs";
			saveOption = new MenuOption("save", sureList);
			saveOption.help = "save the menu state\nplayer status is saved automatically when\nusing stairs";
			newGameOption = new MenuOption("new game", sureList);
			newGameOption.help = "start a new game";
			
			goUpDownOption = new ToggleMenuOption(["go up", "go down"]);
			
			// tier 3
			onOffOption = new ToggleMenuOption(["off", "on"]);
			sureOption = new MenuOption("sure?");
			
			// OPTION ARRAYS
			
			trunk.options.push(inventoryOption);
			trunk.options.push(optionsOption);
			trunk.options.push(stairsOption);
			
			optionsList.options.push(soundOption);
			optionsList.options.push(changeKeysOption);
			optionsList.options.push(hotKeyOption);
			optionsList.options.push(loadOption);
			optionsList.options.push(saveOption);
			optionsList.options.push(newGameOption);
			
			stairsList.options.push(goUpDownOption);
			
			sureList.options.push(sureOption);
			
			onOffList.options.push(onOffOption);
			
			setTrunk(trunk);
			
			addEventListener(Event.CHANGE, change);
			addEventListener(Event.SELECT, select);
			
			var option:MenuOption = currentMenuList.options[_selection];
			help.text = option.help;
			
		}
		
		public function change(e:Event = null):void{
			
			var option:MenuOption = currentMenuList.options[_selection];
			
			if(parent && option.help){
				help.text = option.help;
			}
			
			if(option.target is Item){
				var item:Item = option.target;
				if(item.type == Item.WEAPON || item.type == Item.ARMOUR){
					if(item.type == Item.WEAPON && item.name == Item.BOW){
						inventoryList.shootOption.active = (item.state == Item.EQUIPPED);
					}
					inventoryList.equipOption.state = item.state == Item.EQUIPPED ? 1 : 0;
					inventoryList.equipMinionOption.state = (g.minion && item.state == Item.MINION_EQUIPPED) ? 1 : 0;
					inventoryList.equipMinionOption.active = Boolean(g.minion);
					inventoryList.enchantmentList.update(item);
					// cursed items disable equipping items of that type, they cannot be dropped either
					if(item.type == Item.WEAPON && g.player.weapon && g.player.weapon.curseState == Item.CURSE_REVEALED){
						inventoryList.equipOption.active = false;
						inventoryList.equipMinionOption.active = false;
					} else if(item.type == Item.ARMOUR && g.player.armour && g.player.armour.curseState == Item.CURSE_REVEALED){
						inventoryList.equipOption.active = false;
						inventoryList.equipMinionOption.active = false;
					} else {
						inventoryList.equipOption.active = true;
					}
					inventoryList.dropOption.active = item.curseState != Item.CURSE_REVEALED
				} else if(item.type == Item.HEART){
					if(!hotKeyMapRecord) inventoryList.eatOption.active = g.player.health < g.player.totalHealth;
					else inventoryList.eatOption.active = true;
				} else if(item.type == Item.RUNE){
					inventoryList.eatOption.active = true;
					inventoryList.feedMinionOption.active = Boolean(g.minion);
					if(item.name == Item.XP){
						if(g.minion) inventoryList.feedMinionOption.active = g.minion.level < Game.MAX_LEVEL;
						inventoryList.eatOption.active = g.player.level < Game.MAX_LEVEL;
					}
				}
				renderMenu();
			} else if(option.name == "sound"){
				onOffOption.state = SoundManager.sfx ? 0 : 1;
				renderMenu();
			} else if(option == inventoryList.enchantOption){
				var runeName:int = inventoryList.options[inventoryList.selection].target.name;
				for(var i:int = 0; i < inventoryList.equipmentList.options.length; i++){
					inventoryList.equipmentList.options[i].active = inventoryList.equipmentList.options[i].target.enchantable(runeName);
				}
			}
		}
		
		public function select(e:Event = null):void{
			var option:MenuOption = currentMenuList.options[_selection];
			var item:Item, n:int, i:int, effect:Effect;
			
			// equipping items on the player
			if(option == inventoryList.equipOption){
				item = previousMenuList.options[previousMenuList.selection].target;
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
			} else if(option == inventoryList.equipMinionOption){
				item = previousMenuList.options[previousMenuList.selection].target;
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
			} else if(option == inventoryList.dropOption){
				item = previousMenuList.options[previousMenuList.selection].target;
				if(item.state == Item.EQUIPPED){
					item = g.player.unequip(item);
				}
				if(g.minion && item.state == Item.MINION_EQUIPPED){
					item = g.minion.unequip(item);
				}
				item = inventoryList.removeItem(item);
				item.dropToMap(g.player.mapX, g.player.mapY);
				g.entities.push(item);
				
			// eating items
			} else if(option == inventoryList.eatOption){
				item = previousMenuList.options[previousMenuList.selection].target;
				if(item.type == Item.HEART){
					g.player.applyHealth(CharacterAttributes.NAME_HEALTHS[item.name] + CharacterAttributes.NAME_HEALTH_LEVELS[item.level]);
				} else if(item.type == Item.RUNE){
					Item.revealName(item.name, inventoryList);
					effect = new Effect(item.name, 20, Effect.EATEN, g, g.player);
				}
				inventoryList.removeItem(item);
				n = g.player.loot.indexOf(item);
				if(n > -1) g.player.loot.splice(n , 1);
				g.console.print("rogue eats " + item.nameToString());
			
			// feeding runes to the minion
			} else if(option == inventoryList.feedMinionOption){
				item = previousMenuList.options[previousMenuList.selection].target;
				Item.revealName(item.name, inventoryList);
				effect = new Effect(item.name, 20, Effect.EATEN, g, g.minion);
				inventoryList.removeItem(item);
				n = g.player.loot.indexOf(item);
				if(n > -1) g.player.loot.splice(n , 1);
				g.console.print("minion eats " + item.nameToString());
			
			// loading / saving / new game
			} else if(option == sureOption){
				if(previousMenuList.options[previousMenuList.selection] == loadOption){
					QuickSave.load(g);
				} else if(previousMenuList.options[previousMenuList.selection] == saveOption){
					QuickSave.save(g);
				} else if(previousMenuList.options[previousMenuList.selection] == newGameOption){
					inventoryList.reset();
					inventoryOption.active = false;
					g.reset();
				}
			
			// turning off sound
			} else if(option == onOffOption){
				if(previousMenuList.options[previousMenuList.selection].name == "sound"){
					SoundManager.sfx = onOffOption.state == 1;
				}
			
			// shooting the bow
			} else if(option == inventoryList.shootOption){
				g.player.shoot(Missile.ARROW);
			
			
			// throwing runes
			} else if(option == inventoryList.throwOption){
				item = previousMenuList.options[previousMenuList.selection].target;
				item = inventoryList.removeItem(item);
				g.player.shoot(Missile.RUNE, new Effect(item.name, 20, Effect.THROWN, g));
			
			
			// enchanting items
			} else if(previousMenuList.options[previousMenuList.selection] == inventoryList.enchantOption){
				item = option.target;
				var rune:Item = inventoryList.options[inventoryList.selection].target;
				
				effect = new Effect(rune.name, 1, 1, g);
				
				Item.revealName(rune.name, inventoryList);
				
				item = effect.enchant(item, inventoryList);
				
				rune = inventoryList.removeItem(rune);
				g.console.print(item.nameToString() + " enchanted with " + rune.nameToString());
			
			// exit the level
			} else if(option == goUpDownOption){
				g.player.exitLevel(goUpDownOption.target as Stairs);
				stairsOption.active = false;
			}
		}
		/* In the event of player death, we need to change the menu to deactivate the inventory,
		 * and maybe some other stuff in future
		 */
		public function death():void{
			for(var i:int = 0; i < branch.length; i++){
				if(branch[i] == inventoryList){
					while(branch.length > 1) stepBack();
					break;
				}
			}
			inventoryOption.active = false;
			// update
			selection = _selection;
		}
		
	}

}