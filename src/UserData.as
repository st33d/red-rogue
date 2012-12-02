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
	import com.robotacid.ui.menu.QuestMenuOption;
	import com.robotacid.util.XorRandom;
	import com.robotacid.ui.FileManager;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
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
		
		private static var loadSettingsCallback:Function;
		
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
			// wrapper to send users to manage their shared object settings if blocked
			try{
				sharedObject.flush();
				sharedObject.close();
			} catch(e:Error){
				navigateToURL(new URLRequest("http://www.macromedia.com/support/documentation/en/flashplayer/help/settings_manager03.html"));
			}
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
			// wrapper to send users to manage their shared object settings if blocked
			try{
				sharedObject.flush();
				sharedObject.close();
			} catch(e:Error){
				navigateToURL(new URLRequest("http://www.macromedia.com/support/documentation/en/flashplayer/help/settings_manager03.html"));
			}
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
			
			var runeNameBuffer:Array;
			if(gameState) runeNameBuffer = gameState.runeNames.slice();
			
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
				quests:[<quest name={"get the amulet of yendor"} type={QuestMenuOption.MACGUFFIN} num={0} commissioner={"@"} xpReward={0} />],
				randomSeed:XorRandom.seedFromDate(),
				husband:false
			};
			
			initMinion();
			initBalrog();
			
			var total:int = Item.stats["rune names"].length;
			for(i = 0; i < total; i++){
				gameState.runeNames.push(Item.UNIDENTIFIED);
			}
			// the identify rune's name is already known (obviously)
			gameState.runeNames[Item.IDENTIFY] = Item.stats["rune names"][Item.IDENTIFY];
		}
		
		/* Save the state of the identification game when identified runes are left in areas */
		public static function saveRuneNamesFromFloor():void{
			var i:int, j:int, k:int, children:XMLList, xml:XML, chests:Array;
			var name:int, type:int;
			var total:int = Item.stats["rune names"].length;
			settings.savedRuneNames.length = 0.
			for(i = 0; i < total; i++){
				settings.savedRuneNames.push(Item.UNIDENTIFIED);
			}
			for(i = 0; i < settings.areaContent.length; i++){
				chests = settings.areaContent[i].chests;
				for(j = 0; j < chests.length; j++){
					children = chests[j].children();
					for each(xml in children){
						name = xml.@name;
						type = xml.@type;
						if(type == Item.RUNE && gameState.runeNames[name] != Item.UNIDENTIFIED){
							settings.savedRuneNames[name] = gameState.runeNames[name];
						}
					}
				}
			}
		}
		
		/* Load the state of the identification game from the save */
		public static function loadRuneNames():void{
			var i:int, str:String;
			var total:int = settings.savedRuneNames.length;
			for(i = 0; i < total; i++){
				str = settings.savedRuneNames[i];
				if(str != Item.UNIDENTIFIED && gameState.runeNames[i] == Item.UNIDENTIFIED){
					Item.revealName(i, game.gameMenu.inventoryList.runesList);
				}
			}
		}
		
		public static function initMinion():void{
			gameState.minion = {
				xml:null,
				health:0
			};
		}
		
		public static function initBalrog():void{
			gameState.balrog = {
				xml:null,
				health:0,
				mapLevel:int.MAX_VALUE
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
			if(game.map.type == Map.AREA) saveRuneNamesFromFloor();
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
					  <branch selection="13" name="multiplayer" context="null"/>
					  <branch selection="1" name="minion shoot" context="minion missile"/>
					</hotKey>
				],
				loreUnlocked:{
					races:[],
					weapons:[],
					armour:[]
				},
				playerConsumed:false,
				minionConsumed:false,
				ascended:false,
				areaContent:[],
				savedRuneNames:[]
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
				Content.setUnderworldPortal(Content.UNDERWORLD_PORTAL_LEVEL, Map.MAIN_DUNGEON);
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
			// fix for previous error in livesAvailable code
			if(settings.livesAvailable > 3) settings.livesAvailable = 3;
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
		
		/* Saves the settings to a file */
		public static function saveSettingsFile():void{
			settingsBytes = new ByteArray();
			settingsBytes.writeObject(settings);
			FileManager.save(settingsBytes, "settings.dat");
			settingsBytes = null;
		}
		
		/* Loads settings and executes a callback when finished */
		public static function loadSettingsFile(callback:Function = null):void{
			loadSettingsCallback = callback;
			FileManager.load(loadSettingsFileComplete, null, [FileManager.DAT_FILTER]);
		}
		private static function loadSettingsFileComplete():void{
			settingsBytes = FileManager.data;
			overwrite(settings, settingsBytes.readObject());
			if(Boolean(loadSettingsCallback)) loadSettingsCallback();
			loadSettingsCallback = null;
		}
		
	}

}