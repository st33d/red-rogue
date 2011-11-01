package com.robotacid.ui.menu {
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.Missile;
	import com.robotacid.engine.Player;
	import com.robotacid.engine.Portal;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.QuickSave;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
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
		
		public var inventoryList:InventoryMenuList;
		public var optionsList:MenuList;
		public var actionsList:MenuList;
		public var debugList:MenuList;
		
		public var giveItemList:GiveItemMenuList;
		public var sureList:MenuList;
		public var soundList:MenuList;
		
		public var inventoryOption:MenuOption;
		public var actionsOption:MenuOption;
		public var debugOption:MenuOption;
		
		public var exitLevelOption:MenuOption;
		public var summonOption:MenuOption;
		public var searchOption:MenuOption;
		public var disarmTrapOption:MenuOption;
		public var missileOption:ToggleMenuOption;
		
		public var giveItemOption:MenuOption;
		public var loadOption:MenuOption;
		public var saveOption:MenuOption;
		public var newGameOption:MenuOption;
		public var sureOption:MenuOption;
		
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
			
			var trunk:MenuList = new MenuList();
			
			inventoryList = new InventoryMenuList(this, g);
			optionsList = new MenuList();
			actionsList = new MenuList();
			debugList = new MenuList();
			
			giveItemList = new GiveItemMenuList(this, g);
			soundList = new MenuList();
			
			onOffList = new MenuList();
			sureList = new MenuList();
			
			// MENU OPTIONS
			
			inventoryOption = new MenuOption("inventory", inventoryList, false);
			inventoryOption.help = "a list of items the rogue currently possesses in her handbag of holding";
			inventoryOption.recordable = false;
			inventoryList.pointers = new Vector.<MenuOption>();
			inventoryList.pointers.push(inventoryOption);
			var optionsOption:MenuOption = new MenuOption("options", optionsList);
			optionsOption.help = "change game settings";
			actionsOption = new MenuOption("actions", actionsList, false);
			actionsOption.help = "perform actions like searching for traps and going up and down stairs";
			debugOption = new MenuOption("debug", debugList);
			debugOption.help = "debug tools for allowing access to game elements that are hard to find in a procedurally generated world"
			
			giveItemOption = new MenuOption("give item", giveItemList);
			giveItemOption.help = "put a custom item in the player's inventory";
			giveItemOption.recordable = false;
			
			initChangeKeysMenuOption();
			changeKeysOption.help = "change the movement keys, menu key and hot keys"
			initHotKeyMenuOption(trunk);
			hotKeyOption.help = "set up a key to perform a menu action the hot key will work even if the menu is hidden the hot key will also adapt to menu changes";
			
			var soundOption:MenuOption = new MenuOption("sound", soundList);
			soundOption.help = "toggle sound";
			var sfxOption:MenuOption = new MenuOption("sfx", onOffList);
			var musicOption:MenuOption = new MenuOption("music", onOffList);
			var fullScreenOption:MenuOption = new MenuOption("fullscreen", onOffList);
			fullScreenOption.help = "toggle fullscreen.\nthe flash player only allows use of the cursor keys and space when fullscreen.";
			loadOption = new MenuOption("load", sureList);
			loadOption.help = "load a saved game player status is saved automatically when using stairs";
			saveOption = new MenuOption("save", sureList);
			saveOption.help = "save the menu state player status is saved automatically when using stairs";
			newGameOption = new MenuOption("new game", sureList);
			newGameOption.help = "start a new game";
			exitLevelOption = new MenuOption("exit level", null, false);
			exitLevelOption.help = "exit this level when standing next to a stairway";
			summonOption = new MenuOption("summon");
			summonOption.help = "teleport your minion to your location";
			searchOption = new MenuOption("search");
			searchOption.help = "search immediate area for traps and secret areas. the player must not move till the search is over, or it will be aborted";
			disarmTrapOption = new MenuOption("disarm trap", null, false);
			disarmTrapOption.help = "disarms any revealed traps that the rogue is standing next to";
			missileOption = new ToggleMenuOption(["shoot", "throw"], null, false);
			missileOption.help = "shoot/throw a missile using one's equipped weapon";
			missileOption.context = "missile";
			
			
			onOffOption = new ToggleMenuOption(["off", "on"]);
			sureOption = new MenuOption("sure?");
			
			// OPTION ARRAYS
			
			trunk.options.push(inventoryOption);
			trunk.options.push(actionsOption);
			trunk.options.push(optionsOption);
			trunk.options.push(debugOption);
			
			optionsList.options.push(soundOption);
			optionsList.options.push(fullScreenOption);
			optionsList.options.push(changeKeysOption);
			optionsList.options.push(hotKeyOption);
			optionsList.options.push(loadOption);
			optionsList.options.push(saveOption);
			optionsList.options.push(newGameOption);
			
			actionsList.options.push(searchOption);
			actionsList.options.push(summonOption);
			actionsList.options.push(disarmTrapOption);
			actionsList.options.push(exitLevelOption);
			actionsList.options.push(missileOption);
			
			debugList.options.push(giveItemOption);
			
			soundList.options.push(sfxOption);
			soundList.options.push(musicOption);
			
			sureList.options.push(sureOption);
			
			onOffList.options.push(onOffOption);
			
			setTrunk(trunk);
			
			addEventListener(Event.CHANGE, onChange);
			addEventListener(Event.SELECT, onSelect);
			
			var option:MenuOption = currentMenuList.options[selection];
			help.text = option.help;
			
			// construct the default hot-key maps
			var defaultHotKeyXML:Array = [
				<hotKey>
				  <branch selection="1" name="actions" context="null"/>
				  <branch selection="3" name="exit level" context="null"/>
				</hotKey>,
				<hotKey>
				  <branch selection="1" name="actions" context="null"/>
				  <branch selection="4" name="shoot" context="missile"/>
				</hotKey>,
				<hotKey>
				  <branch selection="1" name="actions" context="null"/>
				  <branch selection="0" name="search" context="null"/>
				</hotKey>,
				<hotKey>
				  <branch selection="1" name="actions" context="null"/>
				  <branch selection="2" name="disarm trap" context="null"/>
				</hotKey>,
				<hotKey>
				  <branch selection="1" name="actions" context="null"/>
				  <branch selection="1" name="summon" context="null"/>
				</hotKey>
			];
			var i:int, hotKeyMap:HotKeyMap;
			for(i = 0; i < defaultHotKeyXML.length; i++){
				hotKeyMap = new HotKeyMap(i, this);
				hotKeyMap.init(defaultHotKeyXML[i]);
				hotKeyMaps[i] = hotKeyMap;
			}
			
		}
		
		public function onChange(e:Event = null):void{
			
			var option:MenuOption = currentMenuList.options[selection];
			
			if(parent && option.help){
				help.text = option.help;
			}
			
			if(currentMenuList == branch[0]){
				giveItemList.active = false;
			} else if(currentMenuList == giveItemList){
				giveItemList.active = true;
			}
			if(giveItemList.active){
				giveItemList.update();
			}
			
			if(option.userData is Item){
				var item:Item = option.userData;
				if(item.type == Item.WEAPON || item.type == Item.ARMOUR){
					inventoryList.equipOption.state = (item.user && item.user == g.player) ? 1 : 0;
					inventoryList.equipMinionOption.state = (item.user && item.user == g.minion) ? 1 : 0;
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
					if(!hotKeyMapRecord) inventoryList.feedMinionOption.active = Boolean(g.minion) && g.minion.health < g.minion.totalHealth;
					else inventoryList.feedMinionOption.active = true;
				} else if(item.type == Item.RUNE){
					inventoryList.eatOption.active = true;
					inventoryList.feedMinionOption.active = Boolean(g.minion);
					if(item.name == Item.XP){
						if(g.minion) inventoryList.feedMinionOption.active = g.minion.level < Game.MAX_LEVEL;
						inventoryList.eatOption.active = g.player.level < Game.MAX_LEVEL;
					}
				}
				renderMenu();
			} else if(option.name == "sfx"){
				onOffOption.state = SoundManager.sfx ? 0 : 1;
				renderMenu();
			} else if(option.name == "music"){
				onOffOption.state = SoundManager.music ? 0 : 1;
				renderMenu();
			} else if(option.name == "fullscreen"){
				onOffOption.state = stage.displayState == "normal" ? 1 : 0;
				renderMenu();
			} else if(option == inventoryList.enchantOption){
				var runeName:int = inventoryList.options[inventoryList.selection].userData.name;
				for(var i:int = 0; i < inventoryList.equipmentList.options.length; i++){
					inventoryList.equipmentList.options[i].active = inventoryList.equipmentList.options[i].userData.enchantable(runeName);
				}
			} else if(option == giveItemOption){
				
			}
		}
		
		public function onSelect(e:Event = null):void{
			var option:MenuOption = currentMenuList.options[selection];
			var item:Item, n:int, i:int, effect:Effect;
			
			// equipping items on the player - toggle logic follows
			if(option == inventoryList.equipOption){
				item = previousMenuList.options[previousMenuList.selection].userData;
				if(item.location == Item.EQUIPPED && item.user == g.player){
					item = g.player.unequip(item);
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
			
			// equipping items on minions - toggle logic follows
			} else if(option == inventoryList.equipMinionOption){
				item = previousMenuList.options[previousMenuList.selection].userData;
				if(item.location == Item.EQUIPPED && item.user == g.minion){
					item = g.minion.unequip(item);
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
				
			// dropping items
			} else if(option == inventoryList.dropOption){
				item = previousMenuList.options[previousMenuList.selection].userData;
				if(item.user) item = item.user.unequip(item);
				item = inventoryList.removeItem(item);
				item.dropToMap(g.player.mapX, g.player.mapY);
				
			// eating items
			} else if(option == inventoryList.eatOption){
				item = previousMenuList.options[previousMenuList.selection].userData;
				if(item.type == Item.HEART){
					g.player.applyHealth(Character.stats["healths"][item.name] + Character.stats["health levels"][item.name] * item.level);
				} else if(item.type == Item.RUNE){
					Item.revealName(item.name, inventoryList);
					effect = new Effect(item.name, 20, Effect.EATEN, g.player);
				}
				inventoryList.removeItem(item);
				g.console.print("rogue eats " + item.nameToString());
			
			// feeding runes to the minion
			} else if(option == inventoryList.feedMinionOption){
				item = previousMenuList.options[previousMenuList.selection].userData;
				if(item.type == Item.HEART){
					g.minion.applyHealth(Character.stats["healths"][item.name] + Character.stats["health levels"][item.level]);
				} else if(item.type == Item.RUNE){
					Item.revealName(item.name, inventoryList);
					effect = new Effect(item.name, 20, Effect.EATEN, g.minion);
				}
				inventoryList.removeItem(item);
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
					actionsOption.active = false;
					g.reset();
				}
			
			} else if(option == onOffOption){
				
				// turning off sfx
				if(previousMenuList.options[previousMenuList.selection].name == "sfx"){
					SoundManager.sfx = onOffOption.state == 1;
				
				// turning off music
				} else if(previousMenuList.options[previousMenuList.selection].name == "music"){
					if(SoundManager.music) SoundManager.turnOffMusic();
					else SoundManager.turnOnMusic();
					
				// toggle fullscreen
				} else if(previousMenuList.options[previousMenuList.selection].name == "fullscreen"){
					if(onOffOption.state == 1){
						stage.fullScreenSourceRect = new Rectangle(0, 0, Game.WIDTH * 2, Game.HEIGHT * 2);
						stage.scaleMode = StageScaleMode.SHOW_ALL;
						stage.displayState = "fullScreen";
					} else {
						stage.displayState = "normal";
						stage.scaleMode = StageScaleMode.NO_SCALE;
					}
				}
			
			// throwing runes
			} else if(option == inventoryList.throwOption){
				item = previousMenuList.options[previousMenuList.selection].userData;
				item = inventoryList.removeItem(item);
				g.player.shoot(Missile.RUNE, new Effect(item.name, 20, Effect.THROWN));
			
			
			// enchanting items
			} else if(previousMenuList.options[previousMenuList.selection] == inventoryList.enchantOption){
				item = option.userData;
				var rune:Item = inventoryList.options[inventoryList.selection].userData;
				
				effect = new Effect(rune.name, 1, 1);
				
				Item.revealName(rune.name, inventoryList);
				
				// items need to be unequipped and then equipped again to apply their new settings to a Character
				var user:Character = item.user;
				if(user) item = user.unequip(item);
				
				item = effect.enchant(item, inventoryList, user);
				
				if(user && item.location == Item.INVENTORY) item = user.equip(item);
				
				rune = inventoryList.removeItem(rune);
				g.console.print(item.nameToString() + " enchanted with " + rune.nameToString());
			
			// exit the level
			} else if(option == exitLevelOption){
				g.player.exitLevel(exitLevelOption.userData as Portal);
				exitLevelOption.active = false;
				g.player.disarmableTraps.length = 0;
				disarmTrapOption.active = false;
			
			// searching
			} else if(option == searchOption){
				g.player.searchCount = Player.SEARCH_DELAY;
				g.console.print("beginning search, please stay still...");
			
			// summoning
			} else if(option == summonOption){
				if(g.minion) g.minion.teleportToPlayer();
			
			// disarming
			} else if(option == disarmTrapOption){
				g.console.print("trap" + (g.player.disarmableTraps.length > 1 ? "s" : "") + " disarmed");
				g.player.disarmTraps();
				disarmTrapOption.active = false;
			
			// missile weapons
			} else if(option == missileOption){
				g.player.shoot(Missile.ITEM);
			
			// creating an item
			} else if(option == giveItemList.createOption){
				giveItemList.createItem();
			}
			
		}
		/* In the event of player death, we need to change the menu to deactivate the inventory,
		 * and maybe some other stuff in future
		 */
		public function death():void{
			for(var i:int = 0; i < branch.length; i++){
				if(branch[i] == inventoryList){
					while(branch.length > 1) stepLeft();
					break;
				}
			}
			inventoryOption.active = false;
			update();
		}
		
	}
}