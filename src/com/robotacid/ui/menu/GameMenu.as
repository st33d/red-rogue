package com.robotacid.ui.menu {
	import com.adobe.serialization.json.JSON;
	import com.robotacid.ai.Brain;
	import com.robotacid.ai.PlayerBrain;
	import com.robotacid.engine.Balrog;
	import com.robotacid.level.Map;
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
	import com.robotacid.level.Surface;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.Dialog;
	import com.robotacid.ui.Editor;
	import com.robotacid.ui.FileManager;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.system.System;
	
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
		
		public var editorList:EditorMenuList;
		public var giveItemList:GiveItemMenuList;
		public var changeRaceList:MenuList;
		public var portalTeleportList:MenuList;
		
		public var sureList:MenuList;
		public var soundList:MenuList;
		public var menuMoveList:MenuList;
		public var rngSeedList:MenuList;
		public var seedInputList:MenuInputList;
		public var upDownList:MenuList;
		public var onOffList:MenuList;
		public var multiplayerList:MenuList;
		public var recordGifList:MenuList;
		public var creditsList:MenuList;
		
		public var inventoryOption:MenuOption;
		public var actionsOption:MenuOption;
		public var debugOption:MenuOption;
		
		public var summonOption:MenuOption;
		public var searchOption:MenuOption;
		public var disarmTrapOption:MenuOption;
		public var missileOption:ToggleMenuOption;
		public var jumpOption:MenuOption;
		public var sleepOption:ToggleMenuOption;
		public var minionMissileOption:ToggleMenuOption;
		public var minionJumpOption:MenuOption;
		public var saveGifOption:MenuOption;
		public var creditsOption:MenuOption
		public var steedOption:MenuOption;
		public var nateOption:MenuOption;
		public var redRogueOption:MenuOption;
		public var copySeedOption:MenuOption;
		
		public var instructionsOption:MenuOption;
		public var saveSettingsOption:MenuOption;
		public var quitOption:MenuOption;
		public var screenshotOption:MenuOption;
		public var saveLogOption:MenuOption;
		public var editorOption:MenuOption;
		public var giveItemOption:MenuOption;
		public var changeRogueRaceOption:MenuOption;
		public var changeMinionRaceOption:MenuOption;
		public var portalTeleportOption:MenuOption;
		public var giveDebugEquipmentOption:MenuOption;
		public var saveSettingsFileOption:MenuOption;
		public var loadSettingsFileOption:MenuOption;
		
		public var newGameOption:MenuOption;
		public var resetOption:MenuOption;
		public var seedOption:MenuOption;
		public var dogmaticOption:MenuOption;
		public var consoleDirOption:MenuOption;
		public var soundOption:MenuOption;
		public var fullScreenOption:MenuOption;
		public var menuMoveOption:MenuOption;
		public var rngSeedOption:MenuOption;
		
		public var stairsUpPortalOption:MenuOption;
		public var stairsDownPortalOption:MenuOption;
		public var overworldPortalOption:MenuOption;
		public var underworldPortalOption:MenuOption;
		
		public var onOffOption:ToggleMenuOption;
		public var upDownOption:ToggleMenuOption;
		
		// temp
		public var url:String;
		
		public static const SHOOT:int = 0;
		public static const THROW:int = 1;
		
		public static const NO:int = 0;
		public static const YES:int = 1;
		
		public function GameMenu(width:Number, height:Number, game:Game) {
			this.game = game;
			super(width, height);
			
			// used by inventoryList
			onOffList = new MenuList();
			
			var i:int;
			
			// MENU LISTS
			
			var trunk:MenuList = new MenuList();
			
			inventoryList = new InventoryMenuList(this, game);
			actionsList = new MenuList();
			loreList = new LoreMenuList(infoTextBox, this, game);
			optionsList = new MenuList();
			debugList = new MenuList();
			
			sureList = new MenuList(Vector.<MenuOption>([
				new MenuOption("no", null, false),
				new MenuOption("yes")
			]));
			sureList.options[YES].selectionStep = MenuOption.EXIT_MENU;
			upDownList = new MenuList();
			rngSeedList = new MenuList();
			seedInputList = new MenuInputList("" + Map.random.seed,/[0-9]/, String(uint.MAX_VALUE).length, seedInputCallback);
			seedInputList.promptName = "enter number";
			multiplayerList = new MenuList();
			recordGifList = new MenuList();
			creditsList = new MenuList();
			
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
			menuMoveList.selection = Menu.moveDelay - 1;
			
			// MENU OPTIONS
			
			inventoryOption = new MenuOption("inventory", inventoryList);
			inventoryOption.help = "a list of items the rogue currently possesses in her handbag of holding";
			var optionsOption:MenuOption = new MenuOption("options", optionsList);
			optionsOption.help = "change game settings";
			actionsOption = new MenuOption("actions", actionsList, false);
			actionsOption.help = "perform actions like searching for traps and summoning the minion";
			var loreOption:MenuOption = new MenuOption("lore", loreList);
			loreOption.help = "information that has been gathered about the world.";
			debugOption = new MenuOption("debug", debugList, false);
			debugOption.help = "debug tools for allowing access to game elements that are hard to find in a procedurally generated world"
			
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
			giveDebugEquipmentOption = new MenuOption("give debug equipment");
			giveDebugEquipmentOption.help = "gives items for investigating bugs.";
			saveSettingsFileOption = new MenuOption("save settings to file");
			saveSettingsFileOption.help = "save settings to file.";
			loadSettingsFileOption = new MenuOption("load settings from file");
			loadSettingsFileOption.help = "load settings from file. requires restarting the whole game.";
			
			stairsUpPortalOption = new MenuOption("stairs up");
			stairsDownPortalOption = new MenuOption("stairs down");
			overworldPortalOption = new MenuOption("overworld");
			underworldPortalOption = new MenuOption("underworld");
			
			summonOption = new MenuOption("summon");
			summonOption.help = "teleport the minion to your location";
			searchOption = new MenuOption("search");
			searchOption.help = "search immediate area for traps and secret areas. the player must not move till the search is over, or it will be aborted";
			disarmTrapOption = new MenuOption("disarm trap");
			disarmTrapOption.help = "disarms any revealed traps that the rogue is standing next to";
			missileOption = new ToggleMenuOption(["shoot", "throw"], null, false);
			missileOption.help = "shoot an equipped main missile weapon / throw a throwing weapon";
			missileOption.context = "missile";
			jumpOption = new MenuOption("jump", null, false);
			jumpOption.help = "makes the player leap into the air";
			sleepOption = new ToggleMenuOption(["sleep", "wake up"]);
			sleepOption.help = "sleep recovers health after a short pause";
			minionMissileOption = new ToggleMenuOption(["minion shoot", "minion throw"], null, false);
			minionMissileOption.help = "minion: shoot an equipped main missile weapon / throw a throwing weapon";
			minionMissileOption.context = "minion missile";
			minionJumpOption = new MenuOption("minion jump", null, false);
			minionJumpOption.help = "makes the minion leap into the air";
			saveGifOption = new MenuOption("save gif", null, false);
			saveGifOption.help = "save out the last 4 seconds of action around the player. may crash the game.";
			creditsOption = new MenuOption("credits", creditsList);
			creditsOption.help = "those involved with making the game.";
			steedOption = new MenuOption("aaron steed - code/art/design");
			steedOption.help = "opens a window to aaron steed's site - robotacid.com";
			nateOption = new MenuOption("nathan gallardo - sound/music");
			nateOption.help = "opens a window to nathan gallardo's site (where this game's OST is available)";
			redRogueOption = new MenuOption("red rogue website");
			redRogueOption.help = "opens a window to redrogue.net, where the game can be downloaded.";
			
			initChangeKeysMenuOption();
			changeKeysOption.help = "change the movement keys, menu key and hot keys"
			initHotKeyMenuOption(trunk);
			hotKeyOption.help = "set up a key to perform a menu action. the hot key will work even if the menu is hidden, the hot key will also adapt to menu changes";
			
			instructionsOption = new MenuOption("instructions");
			instructionsOption.help = "view the basic instructions screen";
			saveSettingsOption = new MenuOption("save settings");
			saveSettingsOption.help = "save only menu settings. you cannot save settings in the underworld or overworld. a technical limitation.";
			quitOption = new MenuOption("quit", sureList);
			quitOption.help = "the game saves state and settings automatically before you enter any area. current level progress will be lost.";
			soundOption = new MenuOption("sound", soundList);
			soundOption.help = "toggle sound";
			var sfxOption:MenuOption = new MenuOption("sfx", onOffList);
			var musicOption:MenuOption = new MenuOption("music", onOffList);
			fullScreenOption = new MenuOption("fullscreen", onOffList);
			fullScreenOption.help = "toggle fullscreen.\nthe flash player only allows use of the cursor keys and space when fullscreen in a browser.";
			screenshotOption = new MenuOption("screenshot");
			screenshotOption.help = "take a screen shot of the game (making the menu temporarily invisible) and open a filebrowser to save the screenshot to the desktop.";
			var recordGifOption:MenuOption = new MenuOption("record gif animation", recordGifList);
			recordGifOption.help = "record a 4 second animation of action around the player.";
			saveLogOption = new MenuOption("save log");
			saveLogOption.help = "open a filebrowser to save this game's log to the desktop.";
			rngSeedOption = new MenuOption("rng seed", rngSeedList);
			rngSeedOption.help = "copying and setting the magic number that generates all of a single play's content.";
			copySeedOption = new MenuOption("copy rng seed");
			copySeedOption.help = "copies the rng seed to the system clipboard as text";
			seedOption = new MenuOption("set rng seed", seedInputList);
			seedOption.help = "set the current random seed value used to generate levels and content.\nenter no value for a random seed value.";
			dogmaticOption = new MenuOption("dogmatic mode", onOffList);
			dogmaticOption.help = "in dogmatic mode time will only pass when the player is performing an action.";
			menuMoveOption = new MenuOption("menu move speed", menuMoveList);
			menuMoveOption.help = "change the speed that the menu moves. lower values move the menu faster. simply move the selection to change the speed.";
			consoleDirOption = new MenuOption("console scroll direction", upDownList);
			consoleDirOption.help = "change the direction the console at the bottom of the screen scrolls";
			var multiplayerOption:MenuOption = new MenuOption("multiplayer", multiplayerList);
			multiplayerOption.help = "allow the minion to be controlled with the arrow keys. the rogue is controlled by the alternative direction keys."
			newGameOption = new MenuOption("new game", sureList);
			newGameOption.recordable = false;
			newGameOption.help = "start a new game";
			resetOption = new MenuOption("reset saved data", sureList);
			resetOption.recordable = false;
			resetOption.help = "erases all saved data. this cannot be undone.";
			
			onOffOption = new ToggleMenuOption(["turn off", "turn on"]);
			onOffOption.selectionStep = 1;
			upDownOption = new ToggleMenuOption(["up", "down"]);
			upDownOption.selectionStep = 1;
			
			// OPTION ARRAYS
			
			trunk.options.push(actionsOption);
			trunk.options.push(inventoryOption);
			trunk.options.push(loreOption);
			trunk.options.push(optionsOption);
			//trunk.options.push(debugOption);
			
			actionsList.options.push(searchOption);
			actionsList.options.push(summonOption);
			actionsList.options.push(disarmTrapOption);
			actionsList.options.push(missileOption);
			actionsList.options.push(jumpOption);
			actionsList.options.push(sleepOption);
			
			optionsList.options.push(instructionsOption);
			optionsList.options.push(fullScreenOption);
			optionsList.options.push(saveSettingsOption);
			optionsList.options.push(soundOption);
			optionsList.options.push(screenshotOption);
			optionsList.options.push(recordGifOption);
			optionsList.options.push(saveLogOption);
			optionsList.options.push(menuMoveOption);
			optionsList.options.push(consoleDirOption);
			optionsList.options.push(changeKeysOption);
			optionsList.options.push(hotKeyOption);
			optionsList.options.push(rngSeedOption);
			optionsList.options.push(dogmaticOption);
			optionsList.options.push(multiplayerOption);
			optionsList.options.push(newGameOption);
			optionsList.options.push(resetOption);
			optionsList.options.push(quitOption);
			optionsList.options.push(creditsOption);
			
			debugList.options.push(editorOption);
			debugList.options.push(giveItemOption);
			debugList.options.push(changeRogueRaceOption);
			debugList.options.push(changeMinionRaceOption);
			debugList.options.push(portalTeleportOption);
			debugList.options.push(saveSettingsFileOption);
			debugList.options.push(loadSettingsFileOption);
			debugList.options.push(giveDebugEquipmentOption);
			
			for(i = 0; i < Character.stats["names"].length; i++){
				changeRaceList.options.push(new MenuOption(Character.stats["names"][i]));
			}
			
			portalTeleportList.options.push(stairsDownPortalOption);
			portalTeleportList.options.push(stairsUpPortalOption);
			portalTeleportList.options.push(overworldPortalOption);
			portalTeleportList.options.push(underworldPortalOption);
			
			soundList.options.push(sfxOption);
			soundList.options.push(musicOption);
			
			rngSeedList.options.push(copySeedOption);
			rngSeedList.options.push(seedOption);
			
			multiplayerList.options.push(onOffOption);
			multiplayerList.options.push(minionMissileOption);
			multiplayerList.options.push(minionJumpOption);
			
			recordGifList.options.push(onOffOption);
			recordGifList.options.push(saveGifOption);
			
			creditsList.options.push(steedOption);
			creditsList.options.push(nateOption);
			creditsList.options.push(redRogueOption);
			
			onOffList.options.push(onOffOption);
			
			upDownList.options.push(upDownOption);
			
			setTrunk(trunk);
			
			var option:MenuOption = currentMenuList.options[selection];
			help.text = option.help;
			
			// load the hot-key maps
			var hotKeyXMLs:Array = UserData.settings.hotKeyMaps;
			var hotKeyMap:HotKeyMap;
			for(i = 0; i < hotKeyXMLs.length; i++){
				if(hotKeyXMLs[i]){
					hotKeyMap = new HotKeyMap(i, this);
					hotKeyMap.init(hotKeyXMLs[i]);
					hotKeyMaps[i] = hotKeyMap;
				}
			}
			
			// this boolean allows the fullscreen option to "bounce"
			Game.fullscreenOn = false;
			
		}
		
		override public function changeSelection():void{
			
			if(currentMenuList.options.length == 0) return;
			
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
						(item.range & (Item.MELEE | Item.MISSILE)) &&
						!(item.user && item.holyState == Item.CURSE_REVEALED && !item.user.undead) &&
						!(game.player.weapon && game.player.weapon.holyState == Item.CURSE_REVEALED && !game.player.undead) &&
						!(game.player.throwable && game.player.throwable.holyState == Item.CURSE_REVEALED && item.range == Item.MISSILE && !game.player.undead)
					);
					inventoryList.equipThrowOption.active = (
						(item.range & Item.THROWN) &&
						!(item.user && item.holyState == Item.CURSE_REVEALED && !item.user.undead) &&
						!(game.player.throwable && game.player.throwable.holyState == Item.CURSE_REVEALED && !game.player.undead) &&
						!(game.player.weapon && game.player.weapon.range == Item.MISSILE && game.player.weapon.holyState == Item.CURSE_REVEALED && !game.player.undead)
					);
					inventoryList.equipMinionMainOption.active = (
						game.minion &&
						(item.range & (Item.MELEE | Item.MISSILE)) &&
						!(item.user && item.holyState == Item.CURSE_REVEALED && !item.user.undead) &&
						!(game.minion.weapon && game.minion.weapon.holyState == Item.CURSE_REVEALED && !game.minion.undead) &&
						!(game.minion.throwable && game.minion.throwable.holyState == Item.CURSE_REVEALED && item.range == Item.MISSILE && !game.minion.undead)
					);
					inventoryList.equipMinionThrowOption.active = (
						game.minion &&
						(item.range & Item.THROWN) &&
						!(item.user && item.holyState == Item.CURSE_REVEALED && !item.user.undead) &&
						!(game.minion.throwable && game.minion.throwable.holyState == Item.CURSE_REVEALED && !game.minion.undead) &&
						!(game.minion.weapon && game.minion.weapon.range == Item.MISSILE && game.minion.weapon.holyState == Item.CURSE_REVEALED && !game.minion.undead)
						
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
					inventoryList.dropOption.active = true;
					
				} else if(item.type == Item.RUNE){
					inventoryList.throwRuneOption.active = game.player.canMenuAction;
					inventoryList.eatOption.active = true;
					inventoryList.feedMinionOption.active = Boolean(game.minion);
					inventoryList.dropOption.active = true;
					if(item.name == Effect.PORTAL || item.name == Effect.POLYMORPH || item.name == Effect.IDENTIFY || item.name == Effect.CHAOS){
						inventoryList.eatOption.active = game.map.type != Map.AREA;
						if(game.minion) inventoryList.feedMinionOption.active = inventoryList.eatOption.active;
					}
				}
				
				renderMenu();
				
			} else if(option == inventoryList.autoSortOption){
				onOffOption.state = inventoryList.autoSort ? 0 : 1;
				renderMenu();
				
			} else if(option.name == "sfx"){
				onOffOption.state = SoundManager.sfx ? 0 : 1;
				renderMenu();
				
			} else if(option.name == "music"){
				onOffOption.state = SoundManager.music ? 0 : 1;
				renderMenu();
				
			} else if(nextMenuList && nextMenuList == sureList){
				// make sure that visiting the sure list always defaults to NO
				sureList.selection = NO;
				renderMenu();
				
			} else if(option.name == "fullscreen"){
				//onOffOption.state = game.stage.displayState == "normal" ? 1 : 0;
				onOffOption.state = Game.fullscreenOn ? 0 : 1;
				renderMenu();
				
			} else if(option.name == "multiplayer"){
				onOffOption.state = game.multiplayer ? 0 : 1;
				renderMenu();
				
			} else if(option.name == "record gif animation"){
				onOffOption.state = Game.renderer.gifBuffer.active ? 0 : 1;
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
		
		override public function executeSelection():void{
			var option:MenuOption = currentMenuList.options[selection];
			var item:Item, n:int, i:int, effect:Effect, prevItem:Item, character:Character, throwing:Boolean;
			var targetLevel:int, targetType:int;
			var health:Number;
			
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
					// balrog face?
					if(item == character.armour && item is Face && (item as Face).theBalrog){
						balrogFaceCheck();
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
				game.console.print(game.player.nameToString() + " eats " + item.nameToString());
				
				if(item.type == Item.HEART){
					health = Character.stats["healths"][item.name] + Character.stats["health levels"][item.name] * game.player.level;
					if(item.name == Character.KOBOLD) health += Character.stats["health levels"][item.name] * game.player.level * game.random.value();
					health *= Item.HEALTH_PER_HEART;
					game.player.applyHealth(health);
					Game.renderer.createSparkRect(game.player.collider, 20, 0, -1, game.player.debrisType);
					game.soundQueue.playRandom(["Munch01", "Munch02", "Munch03"]);
					
				} else if(item.type == Item.RUNE){
					effect = new Effect(item.name, 20, Effect.EATEN, game.player);
					game.soundQueue.playRandom(["Swallow01", "Swallow02", "Swallow03"]);
				}
				inventoryList.removeItem(item);
			
			// feeding the minion
			} else if(option == inventoryList.feedMinionOption){
				item = previousMenuList.options[previousMenuList.selection].userData;
				if(item.type == Item.RUNE) Item.revealName(item.name, inventoryList.runesList);
				game.console.print(game.minion.nameToString() + " eats " + item.nameToString());
				
				if(item.type == Item.HEART){
					health = Character.stats["healths"][item.name] + Character.stats["health levels"][item.name] * game.minion.level;
					if(item.name == Character.KOBOLD) health += Character.stats["health levels"][item.name] * game.minion.level * game.random.value();
					health *= Item.HEALTH_PER_HEART;
					game.minion.applyHealth(health);
					Game.renderer.createSparkRect(game.minion.collider, 20, 0, -1, game.minion.debrisType);
					game.soundQueue.playRandom(["Munch01", "Munch02", "Munch03"]);
					
				} else if(item.type == Item.RUNE){
					effect = new Effect(item.name, 20, Effect.EATEN, game.minion);
					game.soundQueue.playRandom(["Swallow01", "Swallow02", "Swallow03"]);
				}
				inventoryList.removeItem(item);
			
			// sure list options
			} else if(currentMenuList == sureList && currentMenuList.selection == YES){
				
				// erasing the shared object
				if(previousMenuList.options[previousMenuList.selection] == resetOption){
					if(!Game.dialog){
						Game.dialog = new Dialog(
							"reset",
							"are you sure you want to reset all of your settings? this cannot be undone.",
							function():void{reset(true)},
							Dialog.emptyCallback
						);
					}
				// erasing the shared object
				} else if(previousMenuList.options[previousMenuList.selection] == quitOption){
					if(!Game.dialog){
						Game.dialog = new Dialog(
							"quit",
							"you will lose all progress since you entered the level. are you sure.",
							function():void{
								game.state = Game.TITLE;
								reset(false, false);
							},
							Dialog.emptyCallback
						);
					}
				// new game
				} else if(previousMenuList.options[previousMenuList.selection] == newGameOption){
					reset();
				}
			
			} else if(option == onOffOption){
				
				// toggle dogmatic mode
				if(previousMenuList.options[previousMenuList.selection] == dogmaticOption){
					game.dogmaticMode = onOffOption.state == 1;
					if(game.multiplayer){
						game.multiplayer = false;
						if(game.minion) game.minion.setMultiplayer();
					}
				
				// toggle sorting equipment
				} else if(previousMenuList.options[previousMenuList.selection] == inventoryList.autoSortOption){
					inventoryList.autoSort = onOffOption.state == 1;
					
				// toggle multiplayer mode
				} else if(previousMenuList.options[previousMenuList.selection].name == "multiplayer"){
					game.multiplayer = onOffOption.state == 1;
					if(game.minion) game.minion.setMultiplayer();
					game.dogmaticMode = false;
				
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
						Game.fullscreenOn = true;
						if(Capabilities.playerType == "StandAlone"){
							fullscreen();
						} else {
							if(!Game.dialog){
								Game.dialog = new Dialog(
									"activate fullscreen",
									"flash's security restrictions require you to press the menu key to continue\n\nThese restrictions also limit keyboard input to cursor keys and space. Press Esc to exit fullscreen.",
									fullscreen
								);
							}
						}
					} else {
						Game.fullscreenOn = false;
						stage.displayState = "normal";
						stage.scaleMode = StageScaleMode.NO_SCALE;
					}
					
				// toggle gif recording
				} else if(previousMenuList.options[previousMenuList.selection].name == "record gif animation"){
					if(onOffOption.state == 1){
						Game.renderer.gifBuffer.activate();
						saveGifOption.active = true;
					} else {
						Game.renderer.gifBuffer.deactivate();
						saveGifOption.active = false;
					}
				}
			
			// showing the instructions
			} else if(option == instructionsOption){
				game.transition.init(game.initInstructions, null, "", true);
			
			// saving settings
			} else if(option == saveSettingsOption){
				UserData.saveSettings();
				UserData.push(true);
			
			// taking a screenshot
			} else if(option == screenshotOption){
				if(Capabilities.playerType == "StandAlone"){
					screenshot();
				} else {
					if(!Game.dialog){
						Game.dialog = new Dialog(
							"screenshot",
							"flash's security restrictions require you to press the menu key to continue\n",
							screenshot
						);
					}
				}
			
			// saving a gif
			} else if(option == saveGifOption){
				if(!Game.dialog){
					Game.dialog = new Dialog(
						"warning",
						"this will cause the game to freeze for a long time and may crash the game entirely.\nare you sure you want to do this?",
						Game.renderer.gifBuffer.save,
						Dialog.emptyCallback
					);
				}
			
			// taking a screenshot
			} else if(option == saveLogOption){
				if(Capabilities.playerType == "StandAlone"){
					saveLog();
				} else {
					if(!Game.dialog){
						Game.dialog = new Dialog(
							"save log",
							"flash's security restrictions require you to press the menu key to continue\n",
							saveLog
						);
					}
				}
			
			// changing the scrolling behaviour of the console
			} else if(option == upDownOption){
				if(previousMenuList.options[previousMenuList.selection] == consoleDirOption){
					game.console.toggleScrollDir();
				}
			
			// throwing runes
			} else if(option == inventoryList.throwRuneOption){
				if(game.player.mapProperties & Collider.WALL) game.console.print("the stone around you resists...");
				else {
					item = previousMenuList.options[previousMenuList.selection].userData;
					item = inventoryList.removeItem(item);
					game.player.shoot(Missile.RUNE, new Effect(item.name, 20, Effect.THROWN), item);
				}
			
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
				game.player.disarmTraps();
			
			// missile weapons
			} else if(option == missileOption){
				if(game.player.mapProperties & Collider.WALL) game.console.print("the stone around you resists...");
				else game.player.shoot(Missile.ITEM);
			
			// minion missile weapons
			} else if(option == minionMissileOption){
				if(game.minion){
					if(game.minion.mapProperties & Collider.WALL) game.console.print("the stone around the minion resists...");
					else game.minion.shoot(Missile.ITEM);
				}
			
			// minion jump
			} else if(option == minionJumpOption){
				if(game.minion){
					game.minion.jump();
				}
			
			// jumping
			} else if(option == jumpOption){
				game.player.jump();
			
			// sleeping / waking up
			} else if(option == sleepOption){
				// i can't let you do that dave
				if(game.player.state == Character.QUICKENING) game.console.print("you cannot sleep during the quickening");
				else if(game.player.state == Character.EXITING || game.player.state == Character.ENTERING) game.console.print("you cannot sleep in stairs or portals");
				else if(game.player.state == Character.LUNGING) game.console.print("you cannot sleep whilst fighting");
				else if(game.player.state == Character.STUNNED) game.console.print("you cannot sleep whilst stunned");
				else if(game.player.state == Character.SMITED) game.console.print("do you honestly think you can sleep right now?");
				else if(game.player.state == Character.WALKING){
					if(game.player.collider.parent){
						if(game.player.collider.properties & Collider.CHAOS) game.console.print("you cannot sleep on ?");
						else if(
							game.player.name == Character.WRAITH &&
							(game.world.map[game.player.mapY][game.player.mapX] & Collider.WALL)
						) game.console.print("you cannot sleep inside a wall");
						else game.player.setAsleep(!game.player.asleep);
						
					} else game.console.print("you must sleep on the floor");
				}
			
			// creating an item
			} else if(option == giveItemList.createOption){
				giveItemList.createItem();
			
			// giving debug equipment
			} else if(option == giveDebugEquipmentOption){
				giveDebugEquipment();
			
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
				
			// teleporting
			} else if(currentMenuList == portalTeleportList){
				if(option == stairsDownPortalOption) teleportToPortal(Portal.STAIRS, game.map.level + 1, Map.MAIN_DUNGEON);
				else if(option == stairsUpPortalOption){
					targetType = game.map.level == 1 ? Map.AREA : Map.MAIN_DUNGEON;
					teleportToPortal(Portal.STAIRS, game.map.level - 1, targetType);
				} else if(option == overworldPortalOption) teleportToPortal(Portal.PORTAL, Map.OVERWORLD, Map.AREA);
				else if(option == underworldPortalOption) teleportToPortal(Portal.PORTAL, Map.UNDERWORLD, Map.AREA);
				
			// launching the test bed
			} else if(option == editorList.launchTestBedOption){
				game.launchTestBed();
				
			// entering a given dungeon level
			} else if(option == editorList.enterDungeonLevelOption){
				if(game.player.collider.world) game.world.removeCollider(game.player.collider);
				// the player must be denied the opportunity to dick about whilst exiting a level
				game.gameMenu.actionsOption.active = false;
				game.gameMenu.inventoryOption.active = false;
				game.gameMenu.update();
				Player.previousLevel = editorList.dungeonLevelList.selection;
				Player.previousPortalType = Portal.STAIRS;
				Player.previousMapType = Map.MAIN_DUNGEON;
				if(editorList.dungeonLevelList.selection == 0) Player.previousMapType = Map.AREA;
				game.editor.deactivate();
				game.setLevel(editorList.dungeonLevelList.selection + 1, Portal.STAIRS);;
				
			// remapping the ai graph
			} else if(option == editorList.remapAIGraphOption){
				Brain.initMapGraph(game.map.bitmap, game.map.stairsDown);
				for(i = 0; i < Brain.monsterCharacters.length; i++){
					character = Brain.monsterCharacters[i];
					character.brain.clear();
				}
				for(i = 0; i < Brain.playerCharacters.length; i++){
					character = Brain.playerCharacters[i];
					character.brain.clear();
				}
				
			} else if(option == steedOption){
				url = "http://robotacid.com";
				openURL();
				
			} else if(option == nateOption){
				url = "http://gallardosound.com";
				openURL();
				
			} else if(option == redRogueOption){
				url = "http://redrogue.net";
				openURL();
				
			} else if(option == saveSettingsFileOption){
				if(Capabilities.playerType == "StandAlone"){
					UserData.saveSettingsFile();
				} else {
					if(!Game.dialog){
						Game.dialog = new Dialog(
							"save settings",
							"flash's security restrictions require you to press the menu key to continue\n",
							UserData.saveSettingsFile
						);
					}
				}
				
				
			} else if(option == loadSettingsFileOption){
				if(!Game.dialog){
					Game.dialog = new Dialog(
						"warning",
						"this will overwrite you current settings\nare you sure?",
						loadSettings,
						Dialog.emptyCallback
					);
				}
			} else if(option == copySeedOption){
				copyRngSeed();
				
			} 
			
			// if the menu is open, force a renderer update so the player can see the changes,
			// unless the dialog is open - they may be taking a screenshot
			if(parent && !Game.dialog) Game.renderer.main();
			
		}
		
		/* In the event of player death, we need to change the menu to deactivate some options
		 * and switch over to the DeathMenu
		 */
		public function death():void{
			if(listInBranch(inventoryList)) while(branch.length > 1) stepLeft();
			inventoryOption.active = false;
			missileOption.active = false;
			update();
			game.deathMenu.select(0);
			game.menuCarousel.setCurrentMenu(game.deathMenu);
		}
		
		/* Activates fullscreen mode */
		public function fullscreen():void{
			try{
				game.stage.fullScreenSourceRect = new Rectangle(0, 0, Game.WIDTH * 2, Game.HEIGHT * 2);
				game.stage.scaleMode = StageScaleMode.SHOW_ALL;
				game.stage.displayState = "fullScreen";
			} catch(e:Error){
				if(!Game.dialog){
					Game.dialog = new Dialog(
						"nope",
						"well whoever runs this site doesn't want you to run the game fullscreen.\n\nthey've locked the flash player out of that option.\n\nwhat a dick."
					);
				}
				Game.fullscreenOn = false;
			}
		}
		
		/* Takes a screen shot of the game (sans menu) and opens a file browser to save it as a png */
		private function screenshot():void{
			visible = false;
			if(Game.dialog) Game.dialog.visible = false;
			var bitmapData:BitmapData = new BitmapData(Game.WIDTH * 2, Game.HEIGHT * 2, true, 0x0);
			bitmapData.draw(game, game.transform.matrix);
			FileManager.save(PNGEncoder.encode(bitmapData, {"creator":"red-rogue"}), "screenshot.png");
			if(Game.dialog) Game.dialog.visible = true;
			visible = true;
		}
		
		/* Takes a screen shot of the game (sans menu) and opens a file browser to save it as a png */
		private function saveLog():void{
			FileManager.save(game.console.log, "log.txt");
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
			trace("new seed: " + Map.seed);
			if(game.console) game.console.print("create a new game to use seed");
			inputList.option.name = "" + Map.seed;
		}
		
		/* Copying seed to clipboard */
		public function copyRngSeed():void{
			if(Capabilities.playerType == "StandAlone"){
				seedCopyCallback();
			} else {
				Game.dialog = new Dialog(
					"copy the seed",
					"accept to copy the rng seed\nto the clipboard",
					seedCopyCallback,
					Dialog.emptyCallback
				);
			}
		}
		private function seedCopyCallback():void{
			System.setClipboard(String(Map.random.seed));
			if(game.console) game.console.print("copied seed " + String(Map.random.seed));
		}
		
		/* Teleport the player to a given portal */
		private function teleportToPortal(type:int, targetLevel:int, targetType:int):void{
			var i:int, portal:Portal;
			for(i = 0; i < game.portals.length; i++){
				portal = game.portals[i];
				if(
					portal.type == type && portal.targetLevel == targetLevel && portal.targetType == targetType
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
					if(portal.type == type && portal.targetLevel == targetLevel && portal.targetType == targetType){
						Effect.teleportCharacter(game.player, new Pixel(portal.mapX, portal.mapY));
						return;
					}
				}
			}
		}
		
		private function giveDebugEquipment():void{
			var xmls:Array = [
				<item type={Item.ARMOUR} name={Item.INDIFFERENCE} level={20}>
					<effect name={Effect.LIGHT} level={20} />
				</item>,
				<item type={Item.ARMOUR} name={Item.INDIFFERENCE} level={20}>
					<effect name={Effect.LIGHT} level={20} />
				</item>,
				<item type={Item.ARMOUR} name={Item.HELMET} level={20}>
					<effect name={Effect.LIGHT} level={20} />
					<effect name={Effect.HEAL} level={20} />
					<effect name={Effect.UNDEAD} level={20} />
				</item>,
				<item type={Item.ARMOUR} name={Item.HELMET} level={20}>
					<effect name={Effect.LIGHT} level={20} />
					<effect name={Effect.HEAL} level={20} />
					<effect name={Effect.UNDEAD} level={20} />
				</item>
			];
			for(var i:int = 0; i < xmls.length; i++){
				inventoryList.addItemFromXML(xmls[i]);
			}
		}
		
		/* Open a dialog to see if the player want's to equip the balrog mask */
		private function balrogFaceCheck():void{
			if(!Game.dialog){
				Game.dialog = new Dialog(
					"stop!",
					"you sense a great evil in this item\ndo you really want to equip it?",
					consumeCharacter,
					function():void{
						var character:Character;
						if(game.player.armour is Face && (game.player.armour as Face).theBalrog){
							character = game.player;
						} else {
							character = game.minion;
						}
						character.unequip(character.armour);
					}
				);
			}
		}
		
		/* Called when a character equips the balrog's face */
		private function consumeCharacter():void{
			// determine who equipped the item
			var character:Character;
			if(game.player.armour is Face && (game.player.armour as Face).theBalrog){
				character = game.player;
			} else {
				character = game.minion;
			}
			if(character){
				var face:Face = character.unequip(character.armour) as Face;
				inventoryList.removeItem(face);
				// resurrect the balrog at the location of the face wearer
				UserData.initBalrog();
				var mc:MovieClip = new BalrogMC();
				game.balrog = new Balrog(mc, null, Balrog.RESURRECT);
				game.balrog.collider.x = (character.collider.x + character.collider.width * 0.5) - game.balrog.collider.width * 0.5;
				game.balrog.collider.y = (character.collider.y + character.collider.height) - game.balrog.collider.height;
				game.balrog.mapX = (game.balrog.collider.x + game.balrog.collider.width * 0.5) * Game.INV_SCALE;
				game.balrog.mapY = (game.balrog.collider.y + game.balrog.collider.height * 0.5) * Game.INV_SCALE;
				game.balrog.addMinimapFeature();
				
				// brick the appropriate character
				if(character == game.player){
					UserData.settings.playerConsumed = true;
					if(game.lives.value) game.lives.value = 0;
					var focusPromptParent:DisplayObjectContainer = game.focusPrompt.parent;
					if(focusPromptParent) focusPromptParent.removeChild(game.focusPrompt);
					game.createFocusPrompt();
					if(focusPromptParent) focusPromptParent.addChild(game.focusPrompt);
					game.balrog.consumedPlayer = true;
				} else if(character == game.minion){
					UserData.settings.minionConsumed = true;
				}
				character.undead = true;
				character.death("possession", false, game.balrog);
				game.console.print(character.nameToString() + "'s soul has been consumed");
				if(character == game.player){
					game.consumedPlayerInit();
				}
				game.soundQueue.playRandom(["Munch01", "Munch02", "Munch03"]);
			} else {
				// sanity check - will remove this line when confirmed stable
				throw new Error("wearer of balrog face not determined");
			}
		}
		
		/* Add the debugging menu */
		public function addDebugOption():void{
			if(!debugOption.active){
				branch[0].options.push(debugOption);
				game.deathMenu.branch[0].options.push(debugOption);
				game.playerConsumedMenu.branch[0].options.push(debugOption);
				debugOption.active = true;
				update();
				game.deathMenu.update();
				game.playerConsumedMenu.update();
				if(game.console){
					game.console.print("debug menu active");
				}
			}
		}
		
		public function loadSettings():void{
			UserData.loadSettingsFile(restartPrompt);
		}
		
		/* The menu needs to be completely loaded from scratch for the new settings to take hold */
		private function restartPrompt():void{
			UserData.push(true);
			if(!Game.dialog){
				Game.dialog = new Dialog(
					"restart",
					"please close the application and\nrun it again to properly load\nnew settings"
				);
			}
		}
		
		/* Resets the game and the GameMenu for a new play session */
		public function reset(hard:Boolean = false, newGame:Boolean = true):void{
			if(hard) {
				loreList.reset();
				UserData.reset();
			}
			game.trackEvent("reset game");
			if(listInBranch(inventoryList)){
				while(branch.length > 1) stepLeft();
				selectText.alpha = 0;
			}
			inventoryOption.active = false;
			missileOption.active = false;
			inventoryList.reset();
			loreList.questsList.reset();
			actionsOption.active = false;
			game.reset(newGame);
		}
		
		/* Requires public variable "url" to be set before calling */
		public function openURL():void{
			try{
				navigateToURL(new URLRequest(url), "_blank");
			} catch(e:Error){
				if(!Game.dialog){
					Game.dialog = new Dialog(
						"marvelous",
						"can't open a bloody link.\n\naccept to copy the url.",
						function():void{System.setClipboard(url);},
						Dialog.emptyCallback
					);
				}
			}
		}
		
	}
}