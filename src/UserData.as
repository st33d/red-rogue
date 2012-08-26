package {
	import com.robotacid.engine.Item;
	import com.robotacid.engine.Player;
	import com.robotacid.engine.Portal;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.level.Content;
	import com.robotacid.level.Map;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.Key;
	import com.robotacid.ui.menu.Menu;
	import com.robotacid.ui.menu.MenuOption;
	import com.robotacid.util.XorRandom;
	import flash.ui.Keyboard;
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	/**
	 * Provides an interface for storing game data in a shared object and restoring the game from
	 * the shared object
	 *
	 * Games are saved when going down stairs and through the menu. The difference being that
	 * a menu save will only capture the current state of the menu - not the player.
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class UserData {
		
		public static var game:Game
		public static var renderer:Renderer;
		
		public static var settings:Object;
		public static var gameState:Object;
		
		public static var settingsBytes:ByteArray;
		public static var gameStateBytes:ByteArray;
		
		public static var disabled:Boolean = false;
		
		private static var i:int;
		
		public function UserData() {
			
		}
		
		public static function push(settingsOnly:Boolean = false):void{
			if(disabled) return;
			
			var sharedObject:SharedObject = SharedObject.getLocal("red_rogue");
			// SharedObject.data has a nasty habit of writing direct to the file
			// even when you're not asking it to. So we offload into a ByteArray instead.
			settingsBytes = new ByteArray();
			settingsBytes.writeObject(settings);
			sharedObject.data.settingsBytes = settingsBytes;
			if(!settingsOnly){
				gameStateBytes = new ByteArray();
				gameStateBytes.writeObject(gameState);
				sharedObject.data.gameStateBytes = gameStateBytes;
			}
			settingsBytes = null;
			gameStateBytes = null;
			sharedObject.flush();
			sharedObject.close();
		}
		
		public static function pull():void{
			if(disabled) return;
			
			var sharedObject:SharedObject = SharedObject.getLocal("red_rogue");
			
			// comment out the following blocks to flush save state bugs
			
			// the overwrite method is used to ensure older save data does not delete new features
			if(sharedObject.data.settingsBytes){
				settingsBytes = sharedObject.data.settingsBytes;
				overwrite(settings, settingsBytes.readObject());
			}
			if(sharedObject.data.gameStateBytes){
				gameStateBytes = sharedObject.data.gameStateBytes;
				overwrite(gameState, gameStateBytes.readObject());
			}/**/
			settingsBytes = null;
			gameStateBytes = null;
			sharedObject.flush();
			sharedObject.close();
		}
		
		public static function reset():void{
			initSettings();
			initGameState();
			push();
		}
		
		/* Overwrites matching variable names with source to target */
		public static function overwrite(target:Object, source:Object):void{
			for(var key:String in source){
				target[key] = source[key];
			}
		}
		
		/* This is populated on the fly by com.robotacid.level.Content */
		public static function initGameState():void{
			var i:int, j:int, xml:XML;
			
			gameState = {
				player:{
					previousLevel:Map.OVERWORLD,
					previousPortalType:Portal.STAIRS,
					previousMapType:Map.AREA,
					currentLevel:1,
					currentMapType:Map.MAIN_DUNGEON,
					xml:null,
					health:0,
					xp:0,
					keyItem:false
				},
				inventory:{
					weapons:[],
					armour:[],
					runes:[],
					hearts:[]
				},
				runeNames:[],
				storyCharCodes:[],
				quests:[],
				randomSeed:XorRandom.seedFromDate()
			};
			
			initMinion();
			
			for(i = 0; i < Game.MAX_LEVEL; i++){
				gameState.runeNames.push("?");
			}
			// the identify rune's name is already known (obviously)
			gameState.runeNames[Item.IDENTIFY] = Item.stats["rune names"][Item.IDENTIFY];
		}
		
		public static function initMinion():void{
			gameState.minion = {
				xml:null,
				health:0
			};
		}
		
		public static function saveGameState(currentLevel:int, currentMapType:int):void{
			gameState.player.previousLevel = Player.previousLevel;
			gameState.player.previousPortalType = Player.previousPortalType;
			gameState.player.previousMapType = Player.previousMapType;
			gameState.player.currentLevel = currentLevel;
			gameState.player.currentMapType = currentMapType;
			gameState.player.xml = game.player.toXML();
			gameState.player.health = game.player.health;
			gameState.player.xp = game.player.xp;
			gameState.player.keyItem = game.player.keyItem;
			if(gameState.minion){
				gameState.minion.xml = game.minion.toXML();
				gameState.minion.health = game.minion.health;
			}
			gameState.inventory = game.gameMenu.inventoryList.saveToObject();
			gameState.quests = game.gameMenu.loreList.questsList.saveToArray();
		}
		
		/* Create the default settings object to initialise the game from */
		public static function initSettings():void{
			settings = {
				customKeys:[Key.W, Key.S, Key.A, Key.D, Keyboard.SPACE, Key.F, Key.Z, Key.X, Key.C, Key.V, Key.M, Key.NUMBER_1, Key.NUMBER_2, Key.NUMBER_3, Key.NUMBER_4],
				sfx:true,
				music:true,
				autoSortInventory:true,
				menuMoveSpeed:4,
				consoleScrollDir: -1,
				randomSeed:0,
				dogmaticMode:false,
				multiplayer:false,
				livesAvailable:3,
				hotKeyMaps:[
					<hotKey>
					  <branch selection="0" name="actions" context="null"/>
					  <branch selection="3" name="shoot" context="missile"/>
					</hotKey>,
					<hotKey>
					  <branch selection="0" name="actions" context="null"/>
					  <branch selection="0" name="search" context="null"/>
					</hotKey>,
					<hotKey>
					  <branch selection="0" name="actions" context="null"/>
					  <branch selection="2" name="disarm trap" context="null"/>
					</hotKey>,
					<hotKey>
					  <branch selection="0" name="actions" context="null"/>
					  <branch selection="1" name="summon" context="null"/>
					</hotKey>,
					<hotKey>
					  <branch selection="0" name="actions" context="null"/>
					  <branch selection="4" name="jump" context="null"/>
					</hotKey>,
					<hotKey>
					  <branch selection="3" name="options" context="null"/>
					  <branch selection="14" name="multiplayer" context="null"/>
					  <branch selection="1" name="minion shoot" context="minion missile"/>
					</hotKey>
				],
				loreUnlocked:{
					races:[],
					weapons:[],
					armour:[]
				},
				areaContent:[]
			};
			
			settings.areaContent = [];
			for(var level:int = 0; level < Content.TOTAL_AREAS; level++){
				settings.areaContent.push({
					chests:[],
					monsters:[],
					portals:[]
				});
			}
			var specialItemChest:XML = <chest />;
			settings.specialItemChest = specialItemChest;
			specialItemChest.appendChild(Content.SPECIAL_ITEMS[game.random.rangeInt(Content.SPECIAL_ITEMS.length)]);
			if(settings.areaContent[Map.UNDERWORLD].portals.length == 0){
				Content.setUnderworldPortal(15, Map.MAIN_DUNGEON);
			}
		}
		
		/* Push settings data to the shared object */
		public static function saveSettings():void{
			settings.customKeys = Key.custom.slice();
			settings.sfx = SoundManager.sfx;
			settings.music = SoundManager.music;
			settings.autoSortInventory = game.gameMenu.inventoryList.autoSort;
			settings.menuMoveSpeed = Menu.moveDelay;
			settings.consoleScrollDir = game.console.targetScrollDir;
			settings.randomSeed = Map.seed;
			settings.dogmaticMode = game.dogmaticMode;
			settings.multiplayer = game.multiplayer;
			settings.livesAvailable = game.livesAvailable.value + game.lives.value;
			settings.hotKeyMaps = [];
			settings.loreUnlocked = {
				races:[],
				weapons:[],
				armour:[]
			};
			
			// save the hotkeymaps
			for(i = 0; i < game.gameMenu.hotKeyMaps.length; i++){
				if(game.gameMenu.hotKeyMaps[i]) settings.hotKeyMaps.push(game.gameMenu.hotKeyMaps[i].toXML());
				else settings.hotKeyMaps.push(null);
			}
			// save lore
			var options:Vector.<MenuOption>;
			var record:Array;
			options = game.gameMenu.loreList.racesList.options;
			record = settings.loreUnlocked.races;
			for(i = 0; i < options.length; i++){
				record[i] = options[i].active;
			}
			options = game.gameMenu.loreList.weaponsList.options;
			record = settings.loreUnlocked.weapons;
			for(i = 0; i < options.length; i++){
				record[i] = options[i].active;
			}
			options = game.gameMenu.loreList.armourList.options;
			record = settings.loreUnlocked.armour;
			for(i = 0; i < options.length; i++){
				record[i] = options[i].active;
			}
		}
		
	}

}