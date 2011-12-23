package com.robotacid.ui.menu {
	import com.robotacid.dungeon.Map;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.Missile;
	import com.robotacid.engine.Player;
	import com.robotacid.engine.Portal;
	import com.robotacid.gfx.PNGEncoder;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.Dialog;
	import com.robotacid.ui.FileManager;
	import com.robotacid.ui.QuickSave;
	import flash.display.BitmapData;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	
	/**
	 * This is a situ-specific menu specially for this game
	 *
	 * It has extra variables defining references to game menu options
	 * and it sets up a majority of the core menu elements in the constructor
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class GameMenu extends Menu{
		
		public var game:Game;
		
		public var inventoryList:InventoryMenuList;
		public var optionsList:MenuList;
		public var actionsList:MenuList;
		public var debugList:MenuList;
		public var creditsList:MenuList;
		
		public var giveItemList:GiveItemMenuList;
		public var raceList:MenuList;
		public var sureList:MenuList;
		public var soundList:MenuList;
		public var menuMoveList:MenuList;
		
		public var inventoryOption:MenuOption;
		public var actionsOption:MenuOption;
		public var debugOption:MenuOption;
		
		public var exitLevelOption:MenuOption;
		public var summonOption:MenuOption;
		public var searchOption:MenuOption;
		public var disarmTrapOption:MenuOption;
		public var missileOption:ToggleMenuOption;
		public var screenshotOption:MenuOption;
		
		public var giveItemOption:MenuOption;
		public var changeRogueRaceOption:MenuOption;
		public var changeMinionRaceOption:MenuOption;
		public var loadOption:MenuOption;
		public var saveOption:MenuOption;
		public var newGameOption:MenuOption;
		public var sureOption:MenuOption;
		
		public var steedOption:MenuOption;
		public var nateOption:MenuOption;
		
		public var onOffList:MenuList;
		public var onOffOption:ToggleMenuOption;
		
		public function GameMenu(width:Number, height:Number, game:Game) {
			this.game = game;
			super(width, height);
			init();
		}
		
		/* This is where all of the pre-amble goes, the aim is to make this as readable
		 * as possible, so it will end up being quite long.
		 */
		public function init():void{
			var i:int;
			
			// MENU LISTS
			
			var trunk:MenuList = new MenuList();
			
			inventoryList = new InventoryMenuList(this, game);
			optionsList = new MenuList();
			actionsList = new MenuList();
			debugList = new MenuList();
			creditsList = new MenuList();
			
			giveItemList = new GiveItemMenuList(this, game);
			raceList = new MenuList();
			soundList = new MenuList();
			menuMoveList = new MenuList(Vector.<MenuOption>([
				new MenuOption("1", null, false),
				new MenuOption("2", null, false),
				new MenuOption("3", null, false),
				new MenuOption("4", null, false),
				new MenuOption("5", null, false)
			]));
			menuMoveList.selection = DEFAULT_MOVE_DELAY - 1;
			
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
			var creditsOption:MenuOption = new MenuOption("credits", creditsList);
			creditsOption.help = "those involved with making the game.\nthis part of the menu will be moved to the title screen when i've made it."
			
			giveItemOption = new MenuOption("give item", giveItemList);
			giveItemOption.help = "put a custom item in the player's inventory";
			giveItemOption.recordable = false;
			
			changeRogueRaceOption = new MenuOption("change rogue race", raceList);
			changeRogueRaceOption.help = "change the current race of the rogue";
			changeRogueRaceOption.recordable = false;
			changeMinionRaceOption = new MenuOption("change minion race", raceList);
			changeMinionRaceOption.help = "change the current race of the minion";
			changeMinionRaceOption.recordable = false;
			
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
			screenshotOption = new MenuOption("screenshot");
			screenshotOption.help = "take a screen shot of the game (making the menu temporarily invisible) and open a filebrowser to save the screenshot to the desktop.";
			var menuMoveOption:MenuOption = new MenuOption("menu move speed", menuMoveList);
			menuMoveOption.help = "change the speed that the menu moves. lower values move the menu faster. simply move the selection to change the speed.";
			loadOption = new MenuOption("load", sureList, false);
			loadOption.help = "disabled whilst I work out how to continue a game from save and quit (permadeath)";
			saveOption = new MenuOption("save", sureList, false);
			saveOption.help = "disabled whilst I work out how permadeath and save and quit work";
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
			
			steedOption = new MenuOption("aaron steed - code/art/design");
			steedOption.help = "opens a window to aaron steed's site - robotacid.com";
			nateOption = new MenuOption("nathan gallardo - music");
			nateOption.help = "opens a window to nathan gallardo's site (where this game's OST is available) - icefishingep.tk";
			
			
			onOffOption = new ToggleMenuOption(["off", "on"]);
			sureOption = new MenuOption("sure?");
			
			// OPTION ARRAYS
			
			trunk.options.push(inventoryOption);
			trunk.options.push(actionsOption);
			trunk.options.push(optionsOption);
			trunk.options.push(debugOption);
			trunk.options.push(creditsOption);
			
			optionsList.options.push(soundOption);
			optionsList.options.push(fullScreenOption);
			optionsList.options.push(screenshotOption);
			optionsList.options.push(menuMoveOption);
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
			debugList.options.push(changeRogueRaceOption);
			debugList.options.push(changeMinionRaceOption);
			
			for(i = 0; i < Character.stats["names"].length; i++){
				raceList.options.push(new MenuOption(Character.stats["names"][i]));
			}
			
			creditsList.options.push(steedOption);
			creditsList.options.push(nateOption);
			
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
			var hotKeyMap:HotKeyMap;
			for(i = 0; i < defaultHotKeyXML.length; i++){
				hotKeyMap = new HotKeyMap(i, this);
				hotKeyMap.init(defaultHotKeyXML[i]);
				hotKeyMaps[i] = hotKeyMap;
			}
			
		}
		
		public function activate():void{
			update();
			holder.addChild(this);
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
					inventoryList.equipOption.state = (item.user && item.user == game.player) ? 1 : 0;
					inventoryList.equipMinionOption.state = (item.user && item.user == game.minion) ? 1 : 0;
					inventoryList.equipMinionOption.active = Boolean(game.minion);
					inventoryList.enchantmentList.update(item);
					
					// cursed items disable equipping items of that type, they cannot be dropped either (except by the dead)
					if(item.curseState == Item.CURSE_REVEALED && item.user && !item.user.undead){
						inventoryList.equipOption.active = false;
						inventoryList.equipMinionOption.active = false;
					} else {
						inventoryList.equipOption.active = true;
					}
					
					// no equipping face armour on the overworld
					if(item.type == Item.ARMOUR && item.name == Item.FACE){
						if(game.dungeon.level == 0){
							inventoryList.equipOption.active = false;
							inventoryList.equipMinionOption.active = false;
						}
					}
					inventoryList.dropOption.active = game.player.undead || item.curseState != Item.CURSE_REVEALED;
					
				} else if(item.type == Item.HEART){
					if(!hotKeyMapRecord) inventoryList.eatOption.active = game.player.health < game.player.totalHealth;
					else inventoryList.eatOption.active = true;
					if(!hotKeyMapRecord) inventoryList.feedMinionOption.active = Boolean(game.minion) && game.minion.health < game.minion.totalHealth;
					else inventoryList.feedMinionOption.active = true;
					
				} else if(item.type == Item.RUNE){
					inventoryList.throwOption.active = game.player.attackCount >= 1;
					inventoryList.eatOption.active = true;
					inventoryList.feedMinionOption.active = Boolean(game.minion);
					if(item.name == Effect.XP){
						if(game.minion) inventoryList.feedMinionOption.active = game.minion.level < Game.MAX_LEVEL;
						inventoryList.eatOption.active = game.player.level < Game.MAX_LEVEL;
					} else if(item.name == Effect.PORTAL){
						inventoryList.eatOption.active = game.dungeon.type == Map.MAIN_DUNGEON;
						if(game.minion) inventoryList.feedMinionOption.active = inventoryList.eatOption.active;
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
				onOffOption.state = game.stage.displayState == "normal" ? 1 : 0;
				renderMenu();
				
			} else if(option == inventoryList.enchantOption){
				var runeName:int = inventoryList.options[inventoryList.selection].userData.name;
				for(var i:int = 0; i < inventoryList.equipmentList.options.length; i++){
					inventoryList.equipmentList.options[i].active = inventoryList.equipmentList.options[i].userData.enchantable(runeName);
				}
				
			} else if(option == giveItemOption){
				
			} else if(option == actionsOption){
				if(game.player.weapon) missileOption.active = game.player.attackCount >= 1 && !game.player.indifferent && Boolean(game.player.weapon.range & (Item.MISSILE | Item.THROWN));
			} else if(currentMenuList == menuMoveList){
				moveDelay = currentMenuList.selection + 1;
			}
		}
		
		public function onSelect(e:Event = null):void{
			var option:MenuOption = currentMenuList.options[selection];
			var item:Item, n:int, i:int, effect:Effect, prevItem:Item;
			
			// equipping items on the player - toggle logic follows
			if(option == inventoryList.equipOption){
				item = previousMenuList.options[previousMenuList.selection].userData;
				if(item.location == Item.EQUIPPED && item.user == game.player){
					item = game.player.unequip(item);
					// indifference armour is one-shot
					if(item.name == Item.INDIFFERENCE) item = indifferenceCrumbles(item, game.player);
				} else {
					if(item.type == Item.WEAPON){
						if(game.player.weapon) game.player.unequip(game.player.weapon);
						if(game.minion && game.minion.weapon && game.minion.weapon == item) game.minion.unequip(game.minion.weapon);
					}
					if(item.type == Item.ARMOUR){
						if(game.player.armour){
							prevItem = game.player.armour;
							game.player.unequip(game.player.armour);
							// indifference armour is one-shot
							if(prevItem.name == Item.INDIFFERENCE) prevItem = indifferenceCrumbles(prevItem, game.player);
						}
						if(game.minion && game.minion.armour && game.minion.armour == item) game.minion.unequip(game.minion.armour);
						// indifference armour is one-shot
						if(item.name == Item.INDIFFERENCE){
							game.console.print("indifference is fragile");
						}
					}
					item = game.player.equip(item);
				}
			
			// equipping items on minions - toggle logic follows
			} else if(option == inventoryList.equipMinionOption){
				item = previousMenuList.options[previousMenuList.selection].userData;
				if(item.location == Item.EQUIPPED && item.user == game.minion){
					item = game.minion.unequip(item);
					// indifference armour is one-shot
					if(item.name == Item.INDIFFERENCE) item = indifferenceCrumbles(item, game.minion);
				} else {
					if(item.type == Item.WEAPON){
						if(game.minion.weapon) game.minion.unequip(game.minion.weapon);
						if(game.player.weapon && game.player.weapon == item) game.player.unequip(game.player.weapon);
					}
					if(item.type == Item.ARMOUR){
						if(game.minion.armour){
							prevItem = game.minion.armour;
							game.minion.unequip(game.minion.armour);
							// indifference armour is one-shot
							if(prevItem.name == Item.INDIFFERENCE) prevItem = indifferenceCrumbles(prevItem, game.minion);
						}
						if(game.player.armour && game.player.armour == item) game.player.unequip(game.player.armour);
						// indifference armour is one-shot
						if(item.name == Item.INDIFFERENCE){
							game.console.print("indifference is fragile");
							game.minion.brain.clear();
						}
					}
					item = game.minion.equip(item);
				}
				
			// dropping items
			} else if(option == inventoryList.dropOption){
				item = previousMenuList.options[previousMenuList.selection].userData;
				if(item.user) item = item.user.unequip(item);
				item = inventoryList.removeItem(item);
				item.dropToMap(game.player.mapX, game.player.mapY);
				
			// eating items
			} else if(option == inventoryList.eatOption){
				item = previousMenuList.options[previousMenuList.selection].userData;
				if(item.type == Item.HEART){
					game.player.applyHealth(Character.stats["healths"][item.name] + Character.stats["health levels"][item.name] * item.level);
				} else if(item.type == Item.RUNE){
					Item.revealName(item.name, inventoryList);
					effect = new Effect(item.name, 20, Effect.EATEN, game.player);
				}
				inventoryList.removeItem(item);
				game.console.print("rogue eats " + item.nameToString());
			
			// feeding runes to the minion
			} else if(option == inventoryList.feedMinionOption){
				item = previousMenuList.options[previousMenuList.selection].userData;
				if(item.type == Item.HEART){
					game.minion.applyHealth(Character.stats["healths"][item.name] + Character.stats["health levels"][item.level]);
				} else if(item.type == Item.RUNE){
					Item.revealName(item.name, inventoryList);
					effect = new Effect(item.name, 20, Effect.EATEN, game.minion);
				}
				inventoryList.removeItem(item);
				game.console.print("minion eats " + item.nameToString());
			
			// loading / saving / new game
			} else if(option == sureOption){
				if(previousMenuList.options[previousMenuList.selection] == loadOption){
					QuickSave.load(game);
				} else if(previousMenuList.options[previousMenuList.selection] == saveOption){
					QuickSave.save(game);
				} else if(previousMenuList.options[previousMenuList.selection] == newGameOption){
					inventoryList.reset();
					inventoryOption.active = false;
					actionsOption.active = false;
					game.reset();
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
						if(!Game.dialog){
							Game.dialog = new Dialog(
								"activate fullscreen",
								"flash's security restrictions require you to click okay to continue\n\nThese restrictions also limit keyboard input to cursor keys and space. Press Esc to exit fullscreen.",
								200, 120, fullscreen
							);
						}
					} else {
						stage.displayState = "normal";
						stage.scaleMode = StageScaleMode.NO_SCALE;
					}
				}
			
			// taking a screenshot
			} else if(option == screenshotOption){
				if(!Game.dialog){
					Game.dialog = new Dialog(
						"screenshot",
						"flash's security restrictions require you to click okay to continue\n",
						200, 120, screenshot
					);
				}
			
			// throwing runes
			} else if(option == inventoryList.throwOption){
				item = previousMenuList.options[previousMenuList.selection].userData;
				item = inventoryList.removeItem(item);
				game.player.shoot(Missile.RUNE, new Effect(item.name, 20, Effect.THROWN));
			
			// enchanting items
			} else if(previousMenuList.options[previousMenuList.selection] == inventoryList.enchantOption){
				item = option.userData;
				var rune:Item = inventoryList.options[inventoryList.selection].userData;
				effect = new Effect(rune.name, 1, 1);
				
				Item.revealName(rune.name, inventoryList);
				game.console.print(item.nameToString() + " enchanted with " + rune.nameToString());
				
				// items need to be unequipped and then equipped again to apply their new settings to a Character
				var user:Character = item.user;
				if(user) item = user.unequip(item);
				
				item = effect.enchant(item, inventoryList, user ? user : game.player);
				
				if(user && item.location == Item.INVENTORY) item = user.equip(item);
				
				rune = inventoryList.removeItem(rune);
			
			// exit the level
			} else if(option == exitLevelOption){
				game.player.exitLevel(exitLevelOption.userData as Portal);
				exitLevelOption.active = false;
				game.player.disarmableTraps.length = 0;
				disarmTrapOption.active = false;
			
			// searching
			} else if(option == searchOption){
				game.player.search();
				game.console.print("beginning search, please stay still...");
			
			// summoning
			} else if(option == summonOption){
				if(game.minion) game.minion.teleportToPlayer();
			
			// disarming
			} else if(option == disarmTrapOption){
				game.console.print("trap" + (game.player.disarmableTraps.length > 1 ? "s" : "") + " disarmed");
				game.player.disarmTraps();
				disarmTrapOption.active = false;
			
			// missile weapons
			} else if(option == missileOption){
				game.player.shoot(Missile.ITEM);
			
			// creating an item
			} else if(option == giveItemList.createOption){
				giveItemList.createItem();
			
			// credits
			} else if(option == steedOption){
				navigateToURL(new URLRequest("http://robotacid.com"), "_blank");
				
			} else if(option == nateOption){
				navigateToURL(new URLRequest("http://icefishingep.tk"), "_blank");
				
			// changing race
			} else if(currentMenuList == raceList){
				if(previousMenuList.options[previousMenuList.selection] == changeRogueRaceOption){
					if(game.player.armour && game.player.armour.name == Item.FACE) game.player.unequip(game.player.armour);
					game.player.changeName(currentMenuList.selection);
					game.console.print("changed rogue to " + game.player.nameToString());
				} else if(previousMenuList.options[previousMenuList.selection] == changeMinionRaceOption){
					if(!game.minion){
						game.console.print("resurrect the minion with the undead rune applied to a monster before using this option");
					} else {
						if(game.minion.armour && game.minion.armour.name == Item.FACE) game.minion.unequip(game.minion.armour);
						game.minion.changeName(currentMenuList.selection);
						game.console.print("changed minion to " + game.minion.nameToString());
					}
				}
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
			missileOption.active = false;
			disarmTrapOption.active = false;
			update();
		}
		
		/* Activates fullscreen mode */
		private function fullscreen():void{
			game.stage.fullScreenSourceRect = new Rectangle(0, 0, Game.WIDTH * 2, Game.HEIGHT * 2);
			game.stage.scaleMode = StageScaleMode.SHOW_ALL;
			game.stage.displayState = "fullScreen";
		}
		
		/* Takes a screen shot of the game (sans menu) and opens a file browser to save it as a png */
		private function screenshot():void{
			visible = false;
			if(Game.dialog) Game.dialog.visible = false;
			var bitmapData:BitmapData = new BitmapData(Game.WIDTH * 2, Game.HEIGHT * 2, true, 0x00000000);
			bitmapData.draw(game, game.transform.matrix);
			FileManager.save(PNGEncoder.encode(bitmapData, {"creator":"red-rogue"}), "screenshot.png");
			if(Game.dialog) Game.dialog.visible = true;
			visible = true;
		}
		
		/* Whenever armour of indifference is removed it is destroyed */
		private function indifferenceCrumbles(item:Item, user:Character):Item{
			game.console.print("indifference crumbles");
			Game.renderer.createDebrisRect(user.collider, 0, 10, Renderer.STONE);
			inventoryList.removeItem(item);
			return null;
		}
		
	}
}