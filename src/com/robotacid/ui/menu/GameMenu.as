package com.robotacid.ui.menu {
	import com.robotacid.ai.Brain;
	import com.robotacid.dungeon.Map;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Face;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.MapTileConverter;
	import com.robotacid.engine.MapTileManager;
	import com.robotacid.engine.Missile;
	import com.robotacid.engine.Player;
	import com.robotacid.engine.Portal;
	import com.robotacid.geom.Pixel;
	import com.robotacid.gfx.PNGEncoder;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.Dialog;
	import com.robotacid.ui.Editor;
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
		public var actionsList:MenuList;
		public var loreList:LoreMenuList;
		public var optionsList:MenuList;
		public var debugList:MenuList;
		public var creditsList:MenuList;
		
		public var editorList:EditorMenuList;
		public var giveItemList:GiveItemMenuList;
		public var changeRaceList:MenuList;
		public var portalTeleportList:MenuList;
		public var sureList:MenuList;
		public var soundList:MenuList;
		public var menuMoveList:MenuList;
		public var seedInputList:MenuInputList;
		public var upDownList:MenuList;
		public var onOffList:MenuList;
		
		public var inventoryOption:MenuOption;
		public var actionsOption:MenuOption;
		public var debugOption:MenuOption;
		
		public var summonOption:MenuOption;
		public var searchOption:MenuOption;
		public var disarmTrapOption:MenuOption;
		public var missileOption:ToggleMenuOption;
		
		public var screenshotOption:MenuOption;
		public var editorOption:MenuOption;
		public var giveItemOption:MenuOption;
		public var changeRogueRaceOption:MenuOption;
		public var changeMinionRaceOption:MenuOption;
		public var portalTeleportOption:MenuOption;
		public var loadOption:MenuOption;
		public var saveOption:MenuOption;
		public var newGameOption:MenuOption;
		public var seedOption:MenuOption;
		public var dogmaticOption:MenuOption;
		public var sureOption:MenuOption;
		public var consoleDirOption:MenuOption;
		
		public var stairsUpPortalOption:MenuOption;
		public var stairsDownPortalOption:MenuOption;
		public var overworldPortalOption:MenuOption;
		public var underworldPortalOption:MenuOption;
		
		public var steedOption:MenuOption;
		public var nateOption:MenuOption;
		
		public var onOffOption:ToggleMenuOption;
		public var upDownOption:ToggleMenuOption;
		
		private var fullscreenOn:Boolean;
		
		public static const SHOOT:int = 0;
		public static const THROW:int = 1;
		
		public function GameMenu(width:Number, height:Number, game:Game) {
			this.game = game;
			super(width, height);
			
			var i:int;
			
			// MENU LISTS
			
			var trunk:MenuList = new MenuList();
			
			inventoryList = new InventoryMenuList(this, game);
			actionsList = new MenuList();
			loreList = new LoreMenuList(infoTextBox, this, game);
			optionsList = new MenuList();
			debugList = new MenuList();
			creditsList = new MenuList();
			
			onOffList = new MenuList();
			sureList = new MenuList();
			upDownList = new MenuList();
			seedInputList = new MenuInputList("" + Map.random.seed,/[0-9]/, String(uint.MAX_VALUE).length, seedInputCallback);
			seedInputList.promptName = "enter number";
			
			editorList = new EditorMenuList(this, game.editor);
			giveItemList = new GiveItemMenuList(this, game);
			changeRaceList = new MenuList();
			portalTeleportList = new MenuList();
			soundList = new MenuList();
			menuMoveList = new MenuList(Vector.<MenuOption>([
				new MenuOption("1", null, false),
				new MenuOption("2", null, false),
				new MenuOption("3", null, false),
				new MenuOption("4", null, false),
				new MenuOption("5", null, false)
			]));
			menuMoveList.selection = DEFAULT_MOVE_DELAY - 1;
			
			// MENU OPTIONS
			
			inventoryOption = new MenuOption("inventory", inventoryList);
			inventoryOption.help = "a list of items the rogue currently possesses in her handbag of holding";
			var optionsOption:MenuOption = new MenuOption("options", optionsList);
			optionsOption.help = "change game settings";
			actionsOption = new MenuOption("actions", actionsList, false);
			actionsOption.help = "perform actions like searching for traps and going up and down stairs";
			var loreOption:MenuOption = new MenuOption("lore", loreList);
			loreOption.help = "information that has been gathered about the world.";
			debugOption = new MenuOption("debug", debugList);
			debugOption.help = "debug tools for allowing access to game elements that are hard to find in a procedurally generated world"
			var creditsOption:MenuOption = new MenuOption("credits", creditsList);
			creditsOption.help = "those involved with making the game.\nthis part of the menu will be moved to the title screen when i've made it."
			
			giveItemOption = new MenuOption("give item", giveItemList);
			giveItemOption.help = "put a custom item in the player's inventory";
			giveItemOption.recordable = false;
			
			editorOption = new MenuOption("editor", editorList);
			editorOption.help = "activate the mouse based level editor by walking into this menu. the selection the editor is at will be palette item for the mouse.";
			editorOption.recordable = false;
			changeRogueRaceOption = new MenuOption("change rogue race", changeRaceList);
			changeRogueRaceOption.help = "change the current race of the rogue";
			changeRogueRaceOption.recordable = false;
			changeMinionRaceOption = new MenuOption("change minion race", changeRaceList);
			changeMinionRaceOption.help = "change the current race of the minion";
			changeMinionRaceOption.recordable = false;
			portalTeleportOption = new MenuOption("teleport", portalTeleportList);
			portalTeleportOption.help = "teleport to a portal - invalid locations will not effect a teleport, this is a debugging feature.";
			portalTeleportOption.recordable = false;
			
			stairsUpPortalOption = new MenuOption("stairs up");
			stairsDownPortalOption = new MenuOption("stairs down");
			overworldPortalOption = new MenuOption("overworld");
			underworldPortalOption = new MenuOption("underworld");
			
			summonOption = new MenuOption("summon");
			summonOption.help = "teleport your minion to your location";
			searchOption = new MenuOption("search");
			searchOption.help = "search immediate area for traps and secret areas. the player must not move till the search is over, or it will be aborted";
			disarmTrapOption = new MenuOption("disarm trap", null, false);
			disarmTrapOption.help = "disarms any revealed traps that the rogue is standing next to";
			missileOption = new ToggleMenuOption(["shoot", "throw"], null, false);
			missileOption.help = "shoot/throw a missile using one's equipped weapon";
			missileOption.context = "missile";
			
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
			seedOption = new MenuOption("set rng seed", seedInputList);
			seedOption.help = "set the current random seed value used to generate levels and content.\nenter no value for a random seed value.";
			dogmaticOption = new MenuOption("dogmatic mode", onOffList);
			dogmaticOption.help = "in dogmatic mode time will only pass when the player is performing an action.";
			var menuMoveOption:MenuOption = new MenuOption("menu move speed", menuMoveList);
			menuMoveOption.help = "change the speed that the menu moves. lower values move the menu faster. simply move the selection to change the speed.";
			consoleDirOption = new MenuOption("console scroll direction", upDownList);
			consoleDirOption.help = "change the direction the console at the bottom of the screen scrolls";
			loadOption = new MenuOption("load", sureList, false);
			loadOption.help = "disabled whilst I work out how to continue a game from save and quit (permadeath)";
			saveOption = new MenuOption("save", sureList, false);
			saveOption.help = "disabled whilst I work out how permadeath and save and quit work";
			newGameOption = new MenuOption("new game", sureList);
			newGameOption.help = "start a new game";
			
			steedOption = new MenuOption("aaron steed - code/art/design");
			steedOption.help = "opens a window to aaron steed's site - robotacid.com";
			nateOption = new MenuOption("nathan gallardo - sound/music");
			nateOption.help = "opens a window to nathan gallardo's site (where this game's OST is available)";
			
			onOffOption = new ToggleMenuOption(["turn off", "turn on"]);
			onOffOption.selectionStep = 1;
			sureOption = new MenuOption("sure?");
			sureOption.selectionStep = MenuOption.EXIT_MENU;
			upDownOption = new ToggleMenuOption(["up", "down"]);
			upDownOption.selectionStep = 1;
			
			// OPTION ARRAYS
			
			trunk.options.push(inventoryOption);
			trunk.options.push(actionsOption);
			trunk.options.push(loreOption);
			trunk.options.push(optionsOption);
			trunk.options.push(debugOption);
			trunk.options.push(creditsOption);
			
			actionsList.options.push(searchOption);
			actionsList.options.push(summonOption);
			actionsList.options.push(disarmTrapOption);
			actionsList.options.push(missileOption);
			
			optionsList.options.push(soundOption);
			optionsList.options.push(fullScreenOption);
			optionsList.options.push(screenshotOption);
			optionsList.options.push(menuMoveOption);
			optionsList.options.push(consoleDirOption);
			optionsList.options.push(changeKeysOption);
			optionsList.options.push(hotKeyOption);
			optionsList.options.push(seedOption);
			optionsList.options.push(dogmaticOption);
			optionsList.options.push(loadOption);
			optionsList.options.push(saveOption);
			optionsList.options.push(newGameOption);
			
			debugList.options.push(editorOption);
			debugList.options.push(giveItemOption);
			debugList.options.push(changeRogueRaceOption);
			debugList.options.push(changeMinionRaceOption);
			debugList.options.push(portalTeleportOption);
			
			for(i = 0; i < Character.stats["names"].length; i++){
				changeRaceList.options.push(new MenuOption(Character.stats["names"][i]));
			}
			
			portalTeleportList.options.push(stairsDownPortalOption);
			portalTeleportList.options.push(stairsUpPortalOption);
			portalTeleportList.options.push(overworldPortalOption);
			portalTeleportList.options.push(underworldPortalOption);
			
			creditsList.options.push(steedOption);
			creditsList.options.push(nateOption);
			
			soundList.options.push(sfxOption);
			soundList.options.push(musicOption);
			
			sureList.options.push(sureOption);
			
			onOffList.options.push(onOffOption);
			
			upDownList.options.push(upDownOption);
			
			setTrunk(trunk);
			
			var option:MenuOption = currentMenuList.options[selection];
			help.text = option.help;
			
			// construct the default hot-key maps
			var defaultHotKeyXML:Array = [
				<hotKey>
				  <branch selection="1" name="actions" context="null"/>
				  <branch selection="3" name="shoot" context="missile"/>
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
			
			// this boolean allows the fullscreen option to "bounce"
			fullscreenOn = false;
			
		}
		
		override public function changeSelection():void{
			
			var i:int, runeName:int;
			
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
				if(item.type == Item.WEAPON){
					inventoryList.equipMainOption.state = (item.user && item.user == game.player && item == game.player.weapon) ? 1 : 0;
					inventoryList.equipMinionMainOption.state = (item.user && item.user == game.minion && item == game.minion.weapon) ? 1 : 0;
					inventoryList.equipThrowOption.state = (item.user && item.user == game.player && item == game.player.throwable) ? 1 : 0;
					inventoryList.equipMinionThrowOption.state = (item.user && item.user == game.minion && item == game.minion.throwable) ? 1 : 0;
					inventoryList.enchantmentList.update(item);
					
					// cursed items disable equipping items of that type, they cannot be dropped either (but undead are immune to curses)
					inventoryList.equipMainOption.active = (
						!(item.user && item.holyState == Item.CURSE_REVEALED && !item.user.undead) &&
						!(game.player.weapon && game.player.weapon.holyState == Item.CURSE_REVEALED && !game.player.undead)
					);
					inventoryList.equipThrowOption.active = (
						(item.range & Item.THROWN) &&
						!(item.user && item.holyState == Item.CURSE_REVEALED && !item.user.undead) &&
						!(game.player.throwable && game.player.throwable.holyState == Item.CURSE_REVEALED && !game.player.undead)
					);
					inventoryList.equipMinionMainOption.active = (
						game.minion &&
						!(item.user && item.holyState == Item.CURSE_REVEALED && !item.user.undead) &&
						!(game.minion.weapon && game.minion.weapon.holyState == Item.CURSE_REVEALED && !game.minion.undead)
					);
					inventoryList.equipMinionThrowOption.active = (
						game.minion &&
						(item.range & Item.THROWN) &&
						!(item.user && item.holyState == Item.CURSE_REVEALED && !item.user.undead) &&
						!(game.minion.throwable && game.minion.throwable.holyState == Item.CURSE_REVEALED && !game.minion.undead)
					);
					
					inventoryList.dropOption.active = game.player.undead || item.holyState != Item.CURSE_REVEALED;
					
				} else if(item.type == Item.ARMOUR){
					inventoryList.equipOption.state = (item.user && item.user == game.player && item == game.player.armour) ? 1 : 0;
					inventoryList.equipMinionOption.state = (item.user && item.user == game.minion && item == game.minion.armour) ? 1 : 0;
					inventoryList.enchantmentList.update(item);
					
					// cursed items disable equipping items of that type, they cannot be dropped either (but undead are immune to curses)
					inventoryList.equipOption.active = (
						!(item.user && item.holyState == Item.CURSE_REVEALED && !item.user.undead) &&
						!(game.player.armour && game.player.armour.holyState == Item.CURSE_REVEALED && !game.player.undead)
					);
					inventoryList.equipMinionOption.active = (
						game.minion &&
						!(item.user && item.holyState == Item.CURSE_REVEALED && !item.user.undead) &&
						!(game.minion.armour && game.minion.armour.holyState == Item.CURSE_REVEALED && !game.minion.undead)
					);
					
					// no equipping face armour on the overworld
					if(item.name == Item.FACE){
						if(game.map.level == 0){
							inventoryList.equipOption.active = false;
							inventoryList.equipMinionOption.active = false;
						}
					}
					// no re-equipping indifference
					if(item.name == Item.INDIFFERENCE && item.user){
						if(item.user == game.player) inventoryList.equipMinionOption.active = false;
						else if(item.user == game.minion) inventoryList.equipOption.active = false;
					}
					
					inventoryList.dropOption.active = game.player.undead || item.holyState != Item.CURSE_REVEALED;
					
				} else if(item.type == Item.HEART){
					if(!hotKeyMapRecord) inventoryList.eatOption.active = game.player.health < game.player.totalHealth;
					else inventoryList.eatOption.active = true;
					if(!hotKeyMapRecord) inventoryList.feedMinionOption.active = Boolean(game.minion) && game.minion.health < game.minion.totalHealth;
					else inventoryList.feedMinionOption.active = true;
					
				} else if(item.type == Item.RUNE){
					inventoryList.throwRuneOption.active = game.player.canMenuAction;
					inventoryList.eatOption.active = true;
					inventoryList.feedMinionOption.active = Boolean(game.minion);
					if(item.name == Effect.XP){
						if(game.minion) inventoryList.feedMinionOption.active = game.minion.level < Game.MAX_LEVEL;
						inventoryList.eatOption.active = game.player.level < Game.MAX_LEVEL;
					} else if(item.name == Effect.PORTAL){
						inventoryList.eatOption.active = game.map.type == Map.MAIN_DUNGEON;
						if(game.minion) inventoryList.feedMinionOption.active = inventoryList.eatOption.active;
					} else if(item.name == Effect.POLYMORPH){
						inventoryList.eatOption.active = !(game.map.type == Map.AREA && game.map.level == Map.OVERWORLD);
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
				//onOffOption.state = game.stage.displayState == "normal" ? 1 : 0;
				onOffOption.state = fullscreenOn ? 0 : 1;
				renderMenu();
				
			} else if(option == dogmaticOption){
				onOffOption.state = game.dogmaticMode ? 0 : 1;
				renderMenu();
				
			} else if(option == consoleDirOption){
				upDownOption.state = game.console.targetScrollDir == 1 ? 0 : 1;
				renderMenu();
				
			} else if(option == inventoryList.enchantableWeaponsOption){
				runeName = inventoryList.runesList.options[inventoryList.runesList.selection].userData.name;
				for(i = 0; i < inventoryList.enchantableWeaponsList.options.length; i++){
					inventoryList.enchantableWeaponsList.options[i].active = inventoryList.enchantableWeaponsList.options[i].userData.enchantable(runeName);
				}
				
			} else if(option == inventoryList.enchantableArmourOption){
				runeName = inventoryList.runesList.options[inventoryList.runesList.selection].userData.name;
				for(i = 0; i < inventoryList.enchantableArmourList.options.length; i++){
					inventoryList.enchantableArmourList.options[i].active = inventoryList.enchantableArmourList.options[i].userData.enchantable(runeName);
				}
				
			} else if(option == giveItemOption){
				
			} else if(currentMenuList == menuMoveList){
				moveDelay = currentMenuList.selection + 1;
				
			} else if(currentMenuList == editorList){
				game.editor.activate();
				
			} else if(option == editorOption){
				game.editor.deactivate();
				
			}
		}
		
		override public function executeSelection():void {
			var option:MenuOption = currentMenuList.options[selection];
			var item:Item, n:int, i:int, effect:Effect, prevItem:Item, character:Character, throwing:Boolean;
			
			// equipping items on the player - toggle logic follows
			if(
				option == inventoryList.equipMainOption ||
				option == inventoryList.equipThrowOption ||
				option == inventoryList.equipMinionMainOption ||
				option == inventoryList.equipMinionThrowOption ||
				option == inventoryList.equipOption ||
				option == inventoryList.equipMinionOption
			){
				item = previousMenuList.options[previousMenuList.selection].userData;
				
				character = (
					option == inventoryList.equipMainOption ||
					option == inventoryList.equipThrowOption ||
					option == inventoryList.equipOption
				) ? game.player : game.minion;
				
				throwing = (
					option == inventoryList.equipThrowOption ||
					option == inventoryList.equipMinionThrowOption
				);
				
				// is unequip?
				if((option as ToggleMenuOption).state == InventoryMenuList.UNEQUIP){
					item = character.unequip(item);
					
					// indifference armour is one-shot
					if(item.type == Item.ARMOUR && item.name == Item.INDIFFERENCE) item = indifferenceCrumbles(item, character);
					
				} else {
					// unequip incompatible items
					if(item.type == Item.ARMOUR){
						if(character.armour){
							prevItem = character.armour;
							character.unequip(character.armour);
							// indifference armour is one-shot
							if(prevItem.name == Item.INDIFFERENCE) prevItem = indifferenceCrumbles(prevItem, character);
						}
					}
					if(item.type == Item.WEAPON){
						if(throwing){
							if(character.throwable) character.unequip(character.throwable);
							if(character.weapon && (character.weapon.range & Item.MISSILE)) character.unequip(character.weapon);
						} else {
							if(character.weapon) character.unequip(character.weapon);
							if((item.range & Item.MISSILE) && character.throwable) character.unequip(character.throwable);
						}
					}
					if(item.user) item.user.unequip(item);
					character.equip(item, throwing);
					
					// indifference armour is one-shot
					if(item.type == Item.ARMOUR && item.name == Item.INDIFFERENCE){
						game.console.print("indifference is fragile");
					}
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
				if(item.type == Item.RUNE) Item.revealName(item.name, inventoryList.runesList);
				game.console.print("rogue eats " + item.nameToString());
				
				if(item.type == Item.HEART){
					game.player.applyHealth((Character.stats["healths"][item.name] + Character.stats["health levels"][item.name] * game.player.level) * Item.HEALTH_PER_HEART);
				} else if(item.type == Item.RUNE){
					effect = new Effect(item.name, 20, Effect.EATEN, game.player);
				}
				inventoryList.removeItem(item);
			
			// feeding the minion
			} else if(option == inventoryList.feedMinionOption){
				item = previousMenuList.options[previousMenuList.selection].userData;
				if(item.type == Item.RUNE) Item.revealName(item.name, inventoryList.runesList);
				game.console.print("minion eats " + item.nameToString());
				
				if(item.type == Item.HEART){
					game.minion.applyHealth((Character.stats["healths"][item.name] + Character.stats["health levels"][item.name] * game.minion.level) * Item.HEALTH_PER_HEART);
				} else if(item.type == Item.RUNE){
					effect = new Effect(item.name, 20, Effect.EATEN, game.minion);
				}
				inventoryList.removeItem(item);
			
			// loading / saving / new game
			} else if(option == sureOption){
				if(previousMenuList.options[previousMenuList.selection] == loadOption){
					QuickSave.load(game);
				} else if(previousMenuList.options[previousMenuList.selection] == saveOption){
					QuickSave.save(game);
				} else if(previousMenuList.options[previousMenuList.selection] == newGameOption){
					inventoryList.reset();
					loreList.questsList.reset();
					actionsOption.active = false;
					game.reset();
				}
			
			} else if(option == onOffOption){
				
				// toggle dogmatic mode
				if(previousMenuList.options[previousMenuList.selection] == dogmaticOption){
					game.dogmaticMode = onOffOption.state == 1;
				
				// turning off sfx
				} else if(previousMenuList.options[previousMenuList.selection].name == "sfx"){
					SoundManager.sfx = onOffOption.state == 1;
				
				// turning off music
				} else if(previousMenuList.options[previousMenuList.selection].name == "music"){
					if(SoundManager.music){
						SoundManager.turnOffMusic();
						if(SoundManager.soundLoops["underworldMusic2"]) SoundManager.stopSound("underworldMusic2");
					} else {
						SoundManager.turnOnMusic();
						if(game.map.type == Map.AREA && game.map.level == Map.UNDERWORLD){
							SoundManager.fadeLoopSound("underworldMusic2");
						}
					}
					
				// toggle fullscreen
				} else if(previousMenuList.options[previousMenuList.selection].name == "fullscreen"){
					if(onOffOption.state == 1){
						fullscreenOn = true;
						if(!Game.dialog){
							Game.dialog = new Dialog(
								"activate fullscreen",
								"flash's security restrictions require you to press the menu key to continue\n\nThese restrictions also limit keyboard input to cursor keys and space. Press Esc to exit fullscreen.",
								fullscreen
							);
						}
					} else {
						fullscreenOn = false;
						stage.displayState = "normal";
						stage.scaleMode = StageScaleMode.NO_SCALE;
					}
				}
			
			// taking a screenshot
			} else if(option == screenshotOption){
				if(!Game.dialog){
					Game.dialog = new Dialog(
						"screenshot",
						"flash's security restrictions require you to press the menu key to continue\n",
						screenshot
					);
				}
			
			// changing the scrolling behaviour of the console
			} else if(option == upDownOption){
				if(previousMenuList.options[previousMenuList.selection] == consoleDirOption){
					game.console.toggleScrollDir();
				}
			
			// throwing runes
			} else if(option == inventoryList.throwRuneOption){
				item = previousMenuList.options[previousMenuList.selection].userData;
				item = inventoryList.removeItem(item);
				game.player.shoot(Missile.RUNE, new Effect(item.name, 20, Effect.THROWN), item);
			
			// enchanting items
			} else if(currentMenuList == inventoryList.enchantableWeaponsList || currentMenuList == inventoryList.enchantableArmourList){
				item = option.userData;
				var rune:Item = inventoryList.runesList.options[inventoryList.runesList.selection].userData;
				effect = new Effect(rune.name, 1);
				
				Item.revealName(rune.name, inventoryList.runesList);
				game.console.print(item.nameToString() + " enchanted with " + rune.nameToString());
				
				// items need to be unequipped and then equipped again to apply their new settings to a Character
				var user:Character = item.user;
				var originalType:int = item.type;
				throwing = false;
				if(user){
					throwing = user.throwable == item
					item = user.unequip(item);
				}
				
				item = effect.enchant(item, inventoryList, user ? user : game.player);
				
				// don't re-equip items that have changed function
				if(user && item.location == Item.INVENTORY && item.type == originalType) item = user.equip(item, throwing);
				
				rune = inventoryList.removeItem(rune);
			
			// searching
			} else if(option == searchOption){
				game.player.search();
				game.console.print("beginning search, please stay still...");
			
			// summoning
			} else if(option == summonOption){
				if(game.minion) game.minion.queueSummons = true;
			
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
				navigateToURL(new URLRequest("http://gallardosound.com"), "_blank");
				
			// changing race
			} else if(currentMenuList == changeRaceList){
				if(previousMenuList.options[previousMenuList.selection] == changeRogueRaceOption){
					if(game.player.armour && game.player.armour.name == Item.FACE){
						(game.player.armour as Face).previousName = currentMenuList.selection;
						game.console.print("changed rogue to " + Character.stats["names"][name]);
					} else {
						game.player.changeName(currentMenuList.selection);
						game.console.print("changed rogue to " + game.player.nameToString());
					}
				} else if(previousMenuList.options[previousMenuList.selection] == changeMinionRaceOption){
					if(!game.minion){
						game.console.print("resurrect the minion with the undead rune applied to a monster before using this option");
					} else {
						if(game.minion.armour && game.minion.armour.name == Item.FACE){
							(game.minion.armour as Face).previousName = currentMenuList.selection;
							game.console.print("changed minion to " + Character.stats["names"][name]);
						} else {
							game.minion.changeName(currentMenuList.selection);
							game.console.print("changed minion to " + game.minion.nameToString());
						}
					}
				}
				
			// sorting equipment
			} else if(option == inventoryList.sortOption){
				inventoryList.sortEquipment();
				
			// teleporting
			} else if(currentMenuList == portalTeleportList){
				if(option == stairsDownPortalOption) teleportToPortal(Portal.STAIRS, game.map.level + 1);
				else if(option == stairsUpPortalOption) teleportToPortal(Portal.STAIRS, game.map.level - 1);
				else if(option == overworldPortalOption) teleportToPortal(Portal.OVERWORLD);
				else if(option == underworldPortalOption) teleportToPortal(Portal.UNDERWORLD);
				
			// launching the test bed
			} else if(option == editorList.launchTestBedOption){
				game.launchTestBed();
				
			// remapping the ai graph
			} else if(option == editorList.remapAIGraphOption){
				Brain.initDungeonGraph(game.map.bitmap);
				for(i = 0; i < Brain.monsterCharacters.length; i++){
					character = Brain.monsterCharacters[i];
					character.brain.clear();
				}
				for(i = 0; i < Brain.playerCharacters.length; i++){
					character = Brain.playerCharacters[i];
					character.brain.clear();
				}
			}
			
			// if the menu is open, force a renderer update so the player can see the changes,
			// unless the dialog is open - they may be taking a screenshot
			if(parent && !Game.dialog) Game.renderer.main();
			
		}
		
		/* In the event of player death, we need to change the menu to deactivate the inventory,
		 * and maybe some other stuff in future
		 */
		public function death():void{
			if(listInBranch(inventoryList)) while(branch.length > 1) stepLeft();
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
		
		/* Callback for seed input */
		private function seedInputCallback(inputList:MenuInputList):void{
			Map.seed = uint(inputList.input);
			trace("new seed: " + Map.random.seed);
			game.console.print("create a new game to use seed");
		}
		
		/* Teleport the player to a given portal */
		private function teleportToPortal(type:int, targetLevel:int = 0):void{
			var i:int, portal:Portal;
			for(i = 0; i < game.portals.length; i++){
				portal = game.portals[i];
				if(
					portal.type == type &&
					!(portal.type == Portal.STAIRS && portal.targetLevel != targetLevel)
				){
					Effect.teleportCharacter(game.player, new Pixel(portal.mapX, portal.mapY));
					return;
				}
			}
			// if we are here, then the portal may be out of range or not exist on this level
			if(type == Portal.STAIRS){
				// scan the entity layer
				var r:int, c:int, entity:*;
				for(r = 0; r < game.map.height; r++){
					for(c = 0; c < game.map.width; c++){
						entity = game.mapTileManager.mapLayers[MapTileManager.ENTITY_LAYER][r][c];
						if(entity){
							if(entity is Portal){
								portal = entity as Portal;
								if(portal.targetLevel == targetLevel){
									Effect.teleportCharacter(game.player, new Pixel(c, r));
									return;
								}
							} else if(
								(entity == MapTileConverter.STAIRS_DOWN && targetLevel > game.map.level) ||
								(entity == MapTileConverter.STAIRS_UP && targetLevel < game.map.level)
							){
								Effect.teleportCharacter(game.player, new Pixel(c, r));
								return;
							}
						}
					}
				}
			} else {
				// the desired portal should be in the portalHash if it exists
				for(var key:String in game.portalHash){
					portal = game.portalHash[key];
					if(portal.type == type){
						Effect.teleportCharacter(game.player, new Pixel(portal.mapX, portal.mapY));
						return;
					}
				}
			}
		}
		
	}
}