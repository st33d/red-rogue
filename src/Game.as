package {
	import com.adobe.serialization.json.JSON;
	import com.robotacid.ai.Brain;
	import com.robotacid.ai.HorrorBrain;
	import com.robotacid.ai.Node;
	import com.robotacid.ai.PlayerBrain;
	import com.robotacid.level.Content;
	import com.robotacid.level.MapBitmap;
	import com.robotacid.level.Map;
	import com.robotacid.engine.*;
	import com.robotacid.geom.Pixel;
	import com.robotacid.geom.Trig;
	import com.robotacid.gfx.*;
	import com.robotacid.phys.Collider;
	import com.robotacid.phys.CollisionWorld;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.sound.SoundQueue;
	import com.robotacid.ui.Console;
	import com.robotacid.ui.Dialog;
	import com.robotacid.ui.Editor;
	import com.robotacid.ui.menu.DeathMenu;
	import com.robotacid.ui.menu.EditorMenuList;
	import com.robotacid.ui.menu.GameMenu;
	import com.robotacid.ui.menu.Menu;
	import com.robotacid.ui.menu.MenuCarousel;
	import com.robotacid.ui.menu.PlayerConsumedMenu;
	import com.robotacid.ui.menu.QuestMenuList;
	import com.robotacid.ui.menu.QuestMenuOption;
	import com.robotacid.ui.menu.TitleMenu;
	import com.robotacid.ui.ProgressBar;
	import com.robotacid.ui.TextBox;
	import com.robotacid.ui.MiniMap;
	import com.robotacid.ui.Key;
	import com.robotacid.ui.Transition;
	import com.robotacid.util.clips.stopClips;
	import com.robotacid.util.FPS;
	import com.robotacid.util.HiddenInt;
	import com.robotacid.util.misc.onScreen;
	import com.robotacid.util.LZW;
	import com.robotacid.util.RLE;
	import com.robotacid.util.XorRandom;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Sound;
	import flash.net.SharedObject;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	/**
	 * Red Rogue
	 *
	 * A roguelike platform game
	 * 
	 * This is the top level class that serves as a Controller to the rest of the code
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	
	[SWF(width = "640", height = "480", frameRate="30", backgroundColor = "#000000")]
	
	public class Game extends Sprite {
		
		public static const VERSION_NUM:Number = 1.03;
		
		public static const TEST_BED_INIT:Boolean = false;
		public static const ONLINE:Boolean = true;
		
		public static var game:Game;
		public static var renderer:Renderer;
		public static var debug:Graphics;
		public static var debugStay:Graphics;
		public static var dialog:Dialog;
		
		// core engine objects
		public var player:Player;
		public var minion:Minion;
		public var balrog:Balrog;
		public var library:Library;
		public var map:Map;
		public var content:Content;
		public var entrance:Portal;
		public var world:CollisionWorld;
		public var random:XorRandom;
		public var soundQueue:SoundQueue;
		public var sleep:Sleep;
		public var transition:Transition;
		public var editor:Editor;
		public var epilogue:Epilogue;
		
		// graphics
		public var mapTileManager:MapTileManager;
		public var lightMap:LightMap;
		public var lightning:Lightning;
		
		// ui
		public var gameMenu:GameMenu;
		public var deathMenu:DeathMenu;
		public var playerConsumedMenu:PlayerConsumedMenu;
		public var titleMenu:TitleMenu;
		
		public var focusPrompt:Sprite;
		public var titleGfx:Sprite;
		public var miniMapHolder:Sprite;
		public var console:Console;
		public var confusionOverlayHolder:Sprite;
		public var menuCarousel:MenuCarousel;
		public var miniMap:MiniMap;
		public var playerActionBar:ProgressBar;
		public var playerHealthBar:ProgressBar;
		public var playerXpBar:ProgressBar;
		public var levelNumGfx:MovieClip;
		public var minionHealthBar:ProgressBar;
		public var enemyHealthBar:ProgressBar;
		public var livesPanel:LivesPanel;
		public var keyItemStatus:Sprite;
		public var fpsText:TextBox;
		public var titlePressMenuText:TextBox
		public var instructions:MovieClip;
		public var instructionsHolder:Sprite;
		
		// debug
		public var info:TextField;
		
		// lists
		public var entities:Vector.<Entity>;
		public var items:Array;
		public var torches:Vector.<Torch>;
		public var effects:Vector.<Effect>;
		public var portals:Vector.<Portal>;
		public var chaosWalls:Vector.<ChaosWall>;
		public var explosions:Vector.<Explosion>;
		
		// states
		public var state:int;
		public var focusPreviousState:int;
		public var instructionsPreviousState:int;
		public var frameCount:int;
		public var mousePressedCount:int;
		public var mousePressed:Boolean;
		public var paused:Boolean;
		public var shakeDirX:int;
		public var shakeDirY:int;
		public var deepestLevelReached:int;
		public var forceFocus:Boolean = true;
		public var portalHash:Object;
		public var dogmaticMode:Boolean;
		public var lives:HiddenInt;
		public var livesAvailable:HiddenInt;
		public var multiplayer:Boolean;
		public var firstInstructions:Boolean;
		public var endGameEvent:Boolean;
		
		private var hideMouseFrames:int;
		
		// temp variables
		private var i:int;
		public static var point:Point = new Point();
		
		// CONSTANTS
		
		public static const SCALE:Number = 16;
		public static const INV_SCALE:Number = 1.0 / 16;
		
		// states
		public static const GAME:int = 0;
		public static const MENU:int = 1;
		public static const DIALOG:int = 2;
		public static const TITLE:int = 3;
		public static const INSTRUCTIONS:int = 4;
		public static const EPILOGUE:int = 5;
		public static const UNFOCUSED:int = 6;
		
		public static const WIDTH:Number = 320;
		public static const HEIGHT:Number = 240;
		
		// game key properties
		public static const UP_KEY:int = 0;
		public static const DOWN_KEY:int = 1;
		public static const LEFT_KEY:int = 2;
		public static const RIGHT_KEY:int = 3;
		public static const MENU_KEY:int = 4;
		
		public static const MAX_LEVEL:int = 20;
		
		public static const CONSOLE_Y:Number = HEIGHT - Console.HEIGHT;
		public static const HEALTH_GLOW_RATIO:Number = 0.3;
		public static const DEFAULT_BAR_COL:uint = 0xFFCCCCCC;
		public static const DISABLED_BAR_COL:uint = 0xFFAA0000;
		public static const GLOW_BAR_COL:uint = 0xAA0000;
		public static const RED_COL:ColorTransform = new ColorTransform(1, 0, 0, 1, -85);
		public static const HIDE_MOUSE_FRAMES:int = 45;
		
		public static const SOUND_DIST_MAX:int = 12;
		public static const INV_SOUND_DIST_MAX:Number = 1.0 / SOUND_DIST_MAX;
		public static const SOUND_HORIZ_DIST_MULTIPLIER:Number = 1.5;
		
		public static var fullscreenOn:Boolean;
		public static var allowScriptAccess:Boolean;
		
		public function Game():void {
			
			game = this;
			UserData.game = this;
			Entity.game = this;
			LightMap.game = this;
			Effect.game = this;
			FX.game = this;
			Map.game = this;
			Content.game = this;
			Brain.game = this;
			MapBitmap.game = this;
			Lightning.game = this;
			ItemMovieClip.game = this;
			SceneManager.game = this;
			QuestMenuList.game = this;
			QuestMenuOption.game = this;
			Dialog.game = this;
			EditorMenuList.game = this;
			Menu.game = this;
			
			// detect allowScriptAccess for tracking
			allowScriptAccess = ExternalInterface.available;
			if(allowScriptAccess){
				try{
					ExternalInterface.call("");
				} catch(e:Error){
					allowScriptAccess = false;
				}
			}
			
			random = new XorRandom();
			
			var byteArray:ByteArray;
			
			byteArray = new Character.statsData();
			Character.stats = JSON.decode(byteArray.readUTFBytes(byteArray.length));
			
			byteArray = new Item.statsData();
			Item.stats = JSON.decode(byteArray.readUTFBytes(byteArray.length));
			
			// init UserData
			UserData.initSettings();
			UserData.initGameState();
			UserData.pull();
			// check the game is alive
			if(UserData.gameState.dead) UserData.initGameState();
			
			// misc static settings
			Map.seed = UserData.settings.randomSeed;
			Menu.moveDelay = UserData.settings.menuMoveSpeed;
			dogmaticMode = UserData.settings.dogmaticMode;
			multiplayer = UserData.settings.multiplayer;
			endGameEvent = false;
			
			firstInstructions = ONLINE;
			state = (!ONLINE || UserData.settings.playerConsumed || TEST_BED_INIT) ? GAME : TITLE;
			
			library = new Library;
			
			renderer = new Renderer(this);
			renderer.init();
			
			DebrisFX.IGNORE_PROPERTIES = (
				Collider.CHARACTER | Collider.LEDGE | Collider.LADDER | Collider.HEAD | Collider.CORPSE
			);
			DripFX.IGNORE_PROPERTIES = (
				Collider.CHARACTER | Collider.LADDER | Collider.HEAD | Collider.CORPSE
			);
			
			Effect.BANNED_RANDOM_ENCHANTMENTS[Effect.PORTAL] = true;
			Effect.BANNED_RANDOM_ENCHANTMENTS[Effect.NULL] = true;
			Effect.BANNED_RANDOM_ENCHANTMENTS[Effect.CHAOS] = true;
			Effect.BANNED_RANDOM_ENCHANTMENTS[Effect.IDENTIFY] = true;
			Effect.BANNED_RANDOM_ENCHANTMENTS[Effect.HOLY] = true;
			
			TextBox.init();
			MapTileConverter.init();
			ProgressBar.initGlowTable();
			
			sleep = new Sleep(this, renderer);
			
			transition = new Transition();
			
			lightning = new Lightning();
			
			editor = new Editor(this, renderer);
			
			FPS.start();
			
			// SOUND INIT
			SoundManager.init();
			soundQueue = new SoundQueue();
			
			lives = new HiddenInt();
			livesAvailable = new HiddenInt(UserData.settings.livesAvailable);
			
			trackEvent("load complete");
			
			if (stage) addedToStage();
			else addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		
		private function addedToStage(e:Event = null):void{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			// KEYS INIT
			if(!Key.initialized){
				Key.init(stage);
				Key.custom = UserData.settings.customKeys.slice();
				Key.hotKeyTotal = 10;
			}
			
			// GRAPHICS INIT
			
			scaleX = scaleY = 2;
			stage.quality = StageQuality.LOW;
			
			// GAME INIT
			
			init();
		}
		
		/* The initialisation is quite long, so I'm breaking it up with some comment lines */
		private function init():void {
			
			// settings seed has priority over gameState
			var randomSeed:uint = Map.seed ? Map.seed : uint(UserData.gameState.randomSeed);
			
			Map.random = new XorRandom(randomSeed);
			
			// GAME GFX AND UI INIT
			if(state == GAME || state == MENU){
				renderer.createRenderLayers(this);
				
				addChild(editor.bitmap);
				
				addChild(sleep);
				
				if(!console){
					console = new Console();
					console.y = CONSOLE_Y;
				}
				addChild(console);
				
				miniMapHolder = new Sprite();
				addChild(miniMapHolder);
				if(miniMap) miniMapHolder.addChild(miniMap);
				
				keyItemStatus = new KeyUI();
				keyItemStatus.x = 5 + MiniMap.WIDTH + 2;
				keyItemStatus.y = 5 + (MiniMap.HEIGHT * 0.5 - keyItemStatus.height * 0.5) >> 0;
				addChild(keyItemStatus);
				keyItemStatus.visible = false;
				
				playerHealthBar = new ProgressBar(5, CONSOLE_Y - 22, 27, 17, HEALTH_GLOW_RATIO, 0xAA0000);
				playerHealthBar.barCol = 0xFFCCCCCC;
				addChild(playerHealthBar);
				var hpBitmap:Bitmap = new library.HPB;
				hpBitmap.x = 3;
				hpBitmap.y = 5;
				playerHealthBar.addChild(hpBitmap);
				playerHealthBar.update();
				
				livesPanel = new LivesPanel();
				livesPanel.y = -(livesPanel.height + 2);
				livesPanel.visible = false;
				playerHealthBar.addChild(livesPanel);
				
				minionHealthBar = new ProgressBar(playerHealthBar.x + playerHealthBar.bitmap.width + 1, playerHealthBar.y, 27, 5, HEALTH_GLOW_RATIO, 0xAA0000);
				minionHealthBar.barCol = 0xFFCCCCCC;
				addChild(minionHealthBar);
				var mhpBitmap:Bitmap = new library.MHPB;
				mhpBitmap.x = minionHealthBar.width + 1;
				minionHealthBar.addChild(mhpBitmap);
				minionHealthBar.visible = false;
				minionHealthBar.update();
				
				playerXpBar = new ProgressBar(playerHealthBar.x + playerHealthBar.bitmap.width + 1, minionHealthBar.y + minionHealthBar.height, 27, 5);
				playerXpBar.barCol = 0xFFCCCCCC;
				addChild(playerXpBar);
				levelNumGfx = new LevelNumMC();
				levelNumGfx.stop();
				levelNumGfx.x = playerXpBar.width + 1;
				playerXpBar.addChild(levelNumGfx);
				playerXpBar.update();
				
				playerActionBar = new ProgressBar(playerHealthBar.x + playerHealthBar.bitmap.width + 1, playerXpBar.y + playerXpBar.height, 27, 5);
				playerActionBar.barCol = 0xFFCCCCCC;
				var actBitmap:Bitmap = new library.ACT;
				actBitmap.x = playerActionBar.width + 1;
				playerActionBar.addChild(actBitmap);
				addChild(playerActionBar);
				playerActionBar.update();
				
				enemyHealthBar = new ProgressBar(WIDTH - 32, playerHealthBar.y, 27, 17, HEALTH_GLOW_RATIO, 0xAA0000);
				enemyHealthBar.barCol = 0xFFCCCCCC;
				addChild(enemyHealthBar);
				enemyHealthBar.active = false;
				enemyHealthBar.alpha = 0;
				
				confusionOverlayHolder = new Sprite();
				addChild(confusionOverlayHolder);
				
				instructionsHolder = new Sprite();
				addChild(instructionsHolder);
				
			} else if(state == TITLE){
				addChild(getTitleGfx());
				titlePressMenuText = new TextBox(Menu.LIST_WIDTH * 2, 12, Dialog.ROLL_OUT_COL);
				titlePressMenuText.align = "center";
				titlePressMenuText.text = "press menu key (" + Key.keyString(Key.custom[MENU_KEY]) + ") to begin";
				if(!UserData.settings.ascended) titlePressMenuText.bitmapData.colorTransform(titlePressMenuText.bitmapData.rect, RED_COL);
				titlePressMenuText.x = (WIDTH * 0.5 - titlePressMenuText.width * 0.5) >> 0;
				titlePressMenuText.y = (HEIGHT * 0.5) + 10;
				addChild(titlePressMenuText);
			}
			
			addChild(transition);
			
			// menu init
			
			if(!menuCarousel){
				menuCarousel = new MenuCarousel();
				gameMenu = new GameMenu(WIDTH, CONSOLE_Y, this);
				deathMenu = new DeathMenu(WIDTH, CONSOLE_Y, this);
				playerConsumedMenu = new PlayerConsumedMenu(WIDTH, CONSOLE_Y, this);
				titleMenu = new TitleMenu(gameMenu);
				menuCarousel.addMenu(gameMenu);
				menuCarousel.addMenu(deathMenu);
				menuCarousel.addMenu(playerConsumedMenu);
				menuCarousel.addMenu(titleMenu);
			} else {
				// update the rng seed
				if(Map.seed == 0) gameMenu.seedInputList.option.name = "" + Map.random.seed;
				titleMenu.continueOption.active = Boolean(UserData.gameState.player.xml);
				titleMenu.update();
				// load quests
				gameMenu.loreList.questsList.loadFromArray(UserData.gameState.quests);
			}
			addChild(menuCarousel);
			
			if(!focusPrompt){
				createFocusPrompt();
				stage.addEventListener(Event.DEACTIVATE, onFocusLost);
				stage.addEventListener(Event.ACTIVATE, onFocus);
			}
			
			// CREATE FIRST LEVEL =================================================================
			if(state == GAME || state == MENU){
				
				menuCarousel.setCurrentMenu(gameMenu);
				
				/**/	
				// debugging textfield
				info = new TextField();
				addChild(info);
				info.textColor = 0xFFFFFF;
				info.selectable = false;
				info.text = "";
				info.visible = true;
				
				// fps text box
				fpsText = new TextBox(35, 12);
				fpsText.x = WIDTH - (fpsText.width + 2);
				fpsText.y = HEIGHT - (fpsText.height + 2);
				fpsText.visible = gameMenu.debugOption.active;
				addChild(fpsText);
				
				// STATES
				
				frameCount = 1;
				deepestLevelReached = 1;
				livesAvailable = new HiddenInt(UserData.settings.livesAvailable);
				lives.value = 0;
				
				// LISTS
				
				entities = new Vector.<Entity>();
				items = [];
				effects = new Vector.<Effect>();
				torches = new Vector.<Torch>();
				portals = new Vector.<Portal>();
				chaosWalls = new Vector.<ChaosWall>();
				explosions = new Vector.<Explosion>();
				portalHash = {};
				
				// load identified rune names from areas
				Item.runeNames = UserData.gameState.runeNames;
				UserData.loadRuneNames();
				
				Brain.initCharacterLists();
				Brain.voiceCount = Brain.VOICE_DELAY + random.range(Brain.VOICE_DELAY);
				
				// ALL CONTENT FOR THE RANDOM SEED GENERATED FROM THIS POINT FORWARD
				content = new Content();
				Writing.createStoryCharCodes(Map.random);
				Sleep.initDreams();
				
				// LEVEL SPECIFIC INIT
				// This stuff that follows requires the bones of a level to initialise
				
				Player.previousLevel = UserData.gameState.player.previousLevel;
				Player.previousPortalType = UserData.gameState.player.previousPortalType;
				Player.previousMapType = UserData.gameState.player.previousMapType;
				setLevel(UserData.gameState.player.currentLevel, UserData.gameState.player.currentMapType);
				// init area visit notices
				var levelName:String = Map.getName(map.level, map.type);
				if(!UserData.gameState.visitedHash){
					UserData.gameState.visitedHash = {};
					UserData.gameState.visitedHash[levelName] = true;
				}
			} else if(state == TITLE){
				menuCarousel.setCurrentMenu(titleMenu);
				titlePressMenuText.visible = !menuCarousel.active;
			}
			
			// fire up listeners
			addListeners();
			
			if(TEST_BED_INIT) initTestBed();
			else if(ONLINE && !UserData.settings.playerConsumed){
				if(state == GAME || state == MENU){
					if(firstInstructions){
						transition.init(initInstructions, null, "", true);
					} else {
						transition.init(Dialog.emptyCallback, null, levelName, true);
					}
				}
			}
			
			// this is a hack to force clicking on the game when the browser first pulls in the swf
			if(forceFocus){
				onFocusLost();
				forceFocus = false;
			} else {
				changeMusic();
			}
		}
		
		/* Pedantically clear all memory and re-init the project */
		public function reset(newGame:Boolean = true):void{
			removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			removeEventListener(Event.ENTER_FRAME, main);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			stage.removeEventListener(Event.DEACTIVATE, onFocusLost);
			stage.removeEventListener(Event.ACTIVATE, onFocus);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			while(numChildren > 0){
				removeChildAt(0);
			}
			player = null;
			minion = null;
			balrog = null;
			mapTileManager = null;
			map = null;
			world = null;
			lightMap = null;
			mapTileManager = null;
			livesAvailable.value += lives.value;
			lives.value = 0;
			if(newGame){
				UserData.initGameState();
				UserData.push();
			}
			SoundManager.musicTimes = {};
			if(console){
				console.log = "";
				console.logLines = 0;
			}
			if(editor) editor.deactivate();
			init();
		}
		
		/* Enters the testing area */
		public function launchTestBed():void{
			UserData.disabled = true;
			setLevel( -1, Map.MAIN_DUNGEON);
			gameMenu.editorList.setLight(gameMenu.editorList.lightList.selection);
		}
		
		/* Enters the the testing area from game init */
		public function initTestBed():void{
			gameMenu.editorList.renderAIPathsList.selection = EditorMenuList.ON;
			gameMenu.editorList.renderAIGraphList.selection = EditorMenuList.ON;
			gameMenu.editorList.renderCollisionList.selection = EditorMenuList.ON;
			launchTestBed();
		}
		
		/* Used to change to a new level in the dungeon
		 *
		 * This method tries to wipe all layers whilst leaving the gaming architecture in place
		 */
		public function setLevel(level:int, type:int):void{
			var enchantment:XML, effect:Effect;
			
			editor.deactivate();
			// saving settings in an area would delete the content there
			gameMenu.saveSettingsOption.active = type != Map.AREA;
			
			// maintain debug state if present
			if(map && map.level == -1){
				level = -1;
				Player.previousLevel = -1;
				Player.previousMapType = Map.MAIN_DUNGEON;
				Player.previousPortalType = Portal.PORTAL;
			}
			
			if(map){
				// left over content needs to be pulled back into the content manager to be found
				// if the level is visited again
				content.recycleLevel(map.level, map.type);
			
				// capture gameState
				UserData.saveSettings();
				UserData.saveGameState(level, type);
				UserData.push();
			}
			
			var mapNameStr:String = Map.getName(level, type);
			if(type == Map.MAIN_DUNGEON) mapNameStr += ":" + level;
			
			// elements to update:
			
			// game objects list needs to be emptied
			// items list needs to be emptied
			// colliders list needs to be emptied
			// new map
			// clear rendering layers
			
			if(level > deepestLevelReached && deepestLevelReached < MAX_LEVEL) deepestLevelReached = level;
			
			// dismiss entity effects - leave player and minion alone
			var i:int;
			for(i = 0; i < entities.length; i++){
				if(entities[i] is Character && entities[i] != minion && (entities[i] as Character).effects){
					(entities[i] as Character).removeEffects();
				}
			}
			
			// clear lists
			entities.length = 0;
			items.length = 0;
			torches.length = 0;
			renderer.fx.length = 0;
			portals.length = 0;
			chaosWalls.length = 0;
			explosions.length = 0;
			portalHash = {};
			
			Brain.monsterCharacters.length = 0;
			Brain.playerCharacters.length = 0;
			if(player) Brain.playerCharacters.push(player);
			if(minion) Brain.playerCharacters.push(minion);
			
			Brain.voiceCount = Brain.VOICE_DELAY + random.range(Brain.VOICE_DELAY);
			
			map = new Map(level, type);
			
			Brain.initMapGraph(map.bitmap, map.stairsDown);
			
			if(!mapTileManager){
				mapTileManager = new MapTileManager(this, renderer.canvas, SCALE, map.width, map.height, WIDTH, HEIGHT);
				mapTileManager.setLayers(map.layers);
			} else {
				mapTileManager.newMap(map.width, map.height, map.layers);
			}
			renderer.backBitmapData = mapTileManager.layerToBitmapData(MapTileManager.BACKGROUND_LAYER);
			if(type == Map.MAIN_DUNGEON && level <= Writing.story.length){
				Writing.renderWritings();
			}
			renderer.blockBitmapData = renderer.backBitmapData.clone();
			if(type != Map.AREA){
				renderer.blockBitmapData = mapTileManager.layerToBitmapData(MapTileManager.BLOCK_LAYER, renderer.blockBitmapData);
			} else {
				mapTileManager.setLayerUpdate(MapTileManager.BLOCK_LAYER, false);
			}
			
			// modify the mapRect to conceal secrets
			mapTileManager.mapRect = map.bitmap.adjustedMapRect;
			renderer.camera.mapRect = map.bitmap.adjustedMapRect;
			
			world = new CollisionWorld(map.width, map.height, SCALE);
			world.map = createPropertyMap(mapTileManager.mapLayers[MapTileManager.BLOCK_LAYER]);
			
			Explosion.initMap(map.width, map.height);
			
			// collider debug
			//world.debug = debug;
			
			if(!lightMap) lightMap = new LightMap(world.map);
			else {
				lightMap.newMap(world.map);
				lightMap.setLight(player, player.light);
			}  
			
			mapTileManager.init(map.start.x, map.start.y);
			
			if(!miniMap){
				miniMap = new MiniMap(world.map, this, renderer);
				miniMapHolder.addChild(miniMap);;
				miniMap.y = miniMap.x = 5;
			} else {
				miniMap.newMap(world.map);
			}
			if(map.type != Map.AREA && map.cleared) miniMap.reveal();
			
			if(!player){
				var playerMc:MovieClip = new RogueMC();
				var startX:Number = (map.start.x + 0.5) * SCALE;
				var startY:Number = (map.start.y + 1) * SCALE;
				player = new Player(playerMc, startX, startY);
				var minionMc:MovieClip = new SkeletonMC();
				minion = new Minion(minionMc, startX, startY, Character.SKELETON);
				
				if(!UserData.settings.playerConsumed){
					// load the state of the player, if there is one
					if(UserData.gameState.player.xml){
						var playerXML:XML = UserData.gameState.player.xml
						player.level = int(playerXML.@level);
						player.xp = Number(playerXML.@xp);
						// the character may have been reskinned, so we just force a reskin anyway to set stats
						player.changeName(int(playerXML.@name));
						if(UserData.gameState.player.health) player.health = UserData.gameState.player.health;
						player.applyHealth(0);
						player.addXP(0);
						levelNumGfx.gotoAndStop(player.level);
						player.keyItem = UserData.gameState.player.keyItem;
						for each(enchantment in playerXML.effect){
							effect = new Effect(int(enchantment.@name), int(enchantment.@level), int(enchantment.@source), player, int(enchantment.@count), false, false);
						}
						gameMenu.inventoryList.loadFromObject(UserData.gameState.inventory);
						
						if(!UserData.gameState.minion || UserData.settings.minionConsumed) minion = null;
						// load the state of the minion, if there is one
						else if(UserData.gameState.minion.xml){
							var minionXML:XML = UserData.gameState.minion.xml
							minion.level = int(minionXML.@level);
							// the character may have been reskinned, so we just force a reskin anyway to set stats
							minion.changeName(int(minionXML.@name));
							if(UserData.gameState.minion.health) minion.health = UserData.gameState.minion.health;
							minion.applyHealth(0);
							for each(enchantment in minionXML.effect){
								effect = new Effect(int(enchantment.@name), int(enchantment.@level), int(enchantment.@source), minion, int(enchantment.@count), false, false);
							}
						}
						game.console.print("welcome back " + player.nameToString() + " (" + mapNameStr + ")");
					} else {
						game.console.print("welcome " + player.nameToString());
					}
					player.snapCamera();
				} else {
					player.active = false;
					minion = null;
					game.console.print("");
				}
			} else {
				player.collider.x = -player.collider.width * 0.5 + (map.start.x + 0.5) * SCALE;
				player.collider.y = -player.collider.height + (map.start.y + 1) * SCALE;
				player.mapX = (player.collider.x + player.collider.width * 0.5) * INV_SCALE;
				player.mapY = (player.collider.y + player.collider.height * 0.5) * INV_SCALE;
				player.snapCamera();
			}
			keyItemStatus.visible = player.keyItem;
			
			
			if(minion){
				minion.collider.x = -minion.collider.width * 0.5 + (map.start.x + 0.5) * SCALE;
				minion.collider.y = -minion.collider.height + (map.start.y + 1) * SCALE;
				minion.mapX = (minion.collider.x + minion.collider.width * 0.5) * INV_SCALE;
				minion.mapY = (minion.collider.y + minion.collider.height * 0.5) * INV_SCALE;
				entities.push(minion);
				if(minion.light) lightMap.setLight(minion, minion.light, 150);
				minion.prepareToEnter(entrance);
				minion.brain.clear();
				minion.addMinimapFeature();
			} else {
				minionHealthBar.visible = false;
				gameMenu.summonOption.active = false;
				gameMenu.update();
			}
			
			if(balrog){
				balrog.collider.x = -balrog.collider.width * 0.5 + (map.start.x + 0.5) * SCALE;
				balrog.collider.y = -balrog.collider.height + (map.start.y + 1) * SCALE;
				balrog.mapX = (balrog.collider.x + balrog.collider.width * 0.5) * INV_SCALE;
				balrog.mapY = (balrog.collider.y + balrog.collider.height * 0.5) * INV_SCALE;
				balrog.addMinimapFeature();
				balrog.consumedPlayer = UserData.settings.playerConsumed;
				if(balrog.consumedPlayer){
					balrog.snapCamera();
				}
			}
			
			// outside areas are set pieces, meant to give contrast to the dungeon and give the player
			// and minion a back-story
			if(type == Map.AREA){
				
				renderer.lightBitmap.visible = false;
				miniMap.visible = false;
				SoundManager.fadeMusic("music1", -SoundManager.DEFAULT_FADE_STEP);
				
				// the overworld changes the rogue to a colour version and reverts all polymorph effects
				if(level == Map.OVERWORLD){
					var skinMc:MovieClip;
					
					// unequip face armour if worn
					if(player.armour && player.armour.name == Item.FACE) player.unequip(player.armour);
					if(minion && minion.armour && minion.armour.name == Item.FACE) minion.unequip(minion.armour);
					// change the rogue to a colour version and revert the minion if changed
					skinMc = new RogueColMC();
					if(player.name != Character.ROGUE)
						console.print(player.nameToString() + " reverts to human form");
					player.changeName(Character.ROGUE, new RogueColMC);
					if(minion){
						if(UserData.gameState.husband){
							if(minion.name != Character.HUSBAND)
								console.print(minion.nameToString() + " reverts to human form");
							minion.changeName(Character.HUSBAND, new AtColMC);
							
						} else if(minion.name != Character.SKELETON){
							minion.changeName(Character.SKELETON);
							console.print(minion.nameToString() + " reverts to undead form");
						}
					}
					
				} else if(level == Map.UNDERWORLD){
					if(player.undead) player.applyHealth(player.totalHealth);
					if(minion && minion.undead) minion.applyHealth(minion.totalHealth);
				}
				
			} else if(level == -1){
				renderer.lightBitmap.visible = false;
				
			} else if(Player.previousMapType == Map.AREA){
				renderer.lightBitmap.visible = true;
				miniMap.visible = true;
				
				// revert to black and white rogue
				if(Player.previousLevel == Map.OVERWORLD){
					player.changeName(Character.ROGUE, new RogueMC);
					// technically we wouldn't get here because of the ending triggering,
					// this code is here to keep things consistent during debugging if the ending is disabled
					if(minion){
						if(minion.name == Character.HUSBAND){
							minion.changeName(Character.HUSBAND, new AtMC);
						}
					}
				}
			}
			
			// some levels/areas require constant graphical effects
			renderer.sceneManager = SceneManager.getSceneManager(level, type);
			
			// any targeted enemy is no longer on this level
			if(enemyHealthBar.active) enemyHealthBar.deactivate();
			
			// when chasing the balrog the player will enter the level after the balrog
			// emphasising the nature of the chase
			if(
				balrog &&
				balrog.levelState == Balrog.ENTER_STAIRS_UP &&
				entrance.type == Portal.STAIRS &&
				Player.previousLevel < level
			){
				player.prepareToEnter(entrance);
				if(minion) minion.enterCount *= 2;
				balrog.enterLevel(entrance);
			} else {
				player.enterLevel(entrance, Player.previousLevel < level ? Collider.RIGHT : Collider.LEFT);
			}
			
			endGameEvent = false;
			
			if(!player.active) consumedPlayerInit();
			/**/else {
				// end game checks
				if(map.type == Map.AREA){
					if(map.level == Map.UNDERWORLD){
						// check for yendor (and debugging), activate death
						if(
							gameMenu.inventoryList.getItem(Item.YENDOR, Item.ARMOUR) &&
							minion &&
							!UserData.settings.husband
						){
							endGameEvent = true;
							for(i = 0; i < entities.length; i++){
								if(entities[i] is Stone && (entities[i] as Stone).name == Stone.DEATH){
									(entities[i] as Stone).setEndGameEvent();
									break;
								}
							}
						}
					} else if(map.level == Map.OVERWORLD){
						// check for yendor or husband
						if(
							gameMenu.inventoryList.getItem(Item.YENDOR, Item.ARMOUR) ||
							(minion && UserData.settings.husband)
						){
							endGameEvent = true;
						}
					}
				}
			}
			
			changeMusic();
			
			trackEvent("set level", mapNameStr);
		}
		
		private function addListeners():void{
			stage.addEventListener(Event.DEACTIVATE, onFocusLost);
			stage.addEventListener(Event.ACTIVATE, onFocus);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			addEventListener(Event.ENTER_FRAME, main);
		}
		
		// =================================================================================================
		// MAIN LOOP
		// =================================================================================================
		
		private function main(e:Event):void {
			
			if(fpsText && fpsText.visible) fpsText.text = "fps:" + FPS.value;
			
			// copy out these debug tools when needed
			//var t:int = getTimer();
			//info.text = game.player.mapX + " " + game.player.mapY;
			//info.appendText("pixels" + (getTimer() - t) + "\n"); t = getTimer();
			
			if(state == GAME) {
				
				var advance:Boolean = true;
				if(dogmaticMode){
					if(!player.asleep && player.searchRadius == -1 && player.state == Character.WALKING && Key.keysPressed == 0) advance = false;
				}
				
				if(transition.active) transition.main();
				else if(advance){
					var collider:Collider;
					var entity:Entity;
					var character:Character;
					var effect:Effect;
					
					debug.clear();
					debug.lineStyle(1, 0x00FF00);
					// unfortunately lightning has to be drawn on the fly - so we clear it here
					renderer.lightningShape.graphics.clear();
					
					world.main();
					
					// update chaos walls
					for(i = chaosWalls.length - 1; i > -1; i--){
						entity = chaosWalls[i];
						if(entity.active)  entity.main();
						else chaosWalls.splice(i, 1);
					}
					
					// reset damping and update mapX/mapY before attacks
					for(i = 0; i < world.colliders.length; i++){
						collider = world.colliders[i];
						if((collider.properties & Collider.CHARACTER) && !(collider.properties & Collider.GATE)){
							collider.pushDamping = 0;
							character = collider.userData as Character;
							character.mapX = (collider.x + collider.width * 0.5) * INV_SCALE;
							character.mapY = (collider.y + collider.height * 0.5) * INV_SCALE;
							character.mapProperties = world.map[character.mapY][character.mapX];
						}
					}
					
					if(player.active){
						player.main();
						if(player.asleep){
							sleep.main();
							if(player.quickenQueued) player.setAsleep(false);
						}
						if(transition.active) return;
					}
					
					if(balrog && balrog.active){
						balrog.main();
					}
					
					// update items
					for(i = items.length - 1; i > -1; i--){
						entity = items[i];
						if(entity.active){
							if(entity.callMain) entity.main();
						} else {
							items.splice(i, 1);
						}
					}
					
					// update the rest of the game objects
					for(i = entities.length - 1; i > -1; i--){
						entity = entities[i];
						if(entity.active){
							if(entity.callMain) entity.main();
						} else {
							entities.splice(i, 1);
						}
					}
					
					// update explosions
					for(i = explosions.length - 1; i > -1; i--){
						entity = explosions[i];
						if(entity.active){
							entity.main();
						} else {
							explosions.splice(i, 1);
						}
					}
					
					// apply effects
					for(i = effects.length - 1; i > -1; i--){
						effect = effects[i];
						if(effect.active){
							effect.main();
						} else {
							effects.splice(i, 1);
						}
					}
					
					// update portals
					for(i = portals.length - 1; i > -1; i--){
						entity = portals[i];
						if(entity.active){
							if(entity.callMain) entity.main();
						} else {
							portals.splice(i, 1);
						}
					}
					
					soundQueue.play();
					
					if(player.active) miniMap.render();
					
					if(editor.active) editor.main();
					
					renderer.main();
					
					/*var mx:int = renderer.canvas.mouseX * INV_SCALE;
					var my:int = renderer.canvas.mouseY * INV_SCALE;
					if(mousePressedCount == frameCount){
						var explosion:Explosion = new Explosion(0, mx, my, 5, 0);
					}*/
					
					frameCount++;
					if(Brain.voiceCount) Brain.voiceCount--;
					if(HorrorBrain.horrorVoiceCount) HorrorBrain.horrorVoiceCount--;
					ProgressBar.glowCount = frameCount % ProgressBar.glowTable.length;
					
					// examine the key buffer for cheat codes
					if(Key.matchLog(Key.KONAMI_CODE)){
						addLife();
						Key.keyLogString = "";
					}
					
				}
			
				if(player.brain.confusedCount) (player.brain as PlayerBrain).renderConfusion();
				
			} else if(state == INSTRUCTIONS){
				if(transition.active) transition.main();
				
			} else if(state == MENU){
				if(transition.active && transition.forceComplete) transition.main();
				
			} else if(state == TITLE){
				if(transition.active) transition.main();
				
			} else if(state == EPILOGUE){
				if(transition.active) transition.main();
				if(epilogue) epilogue.main();
				
			}
			
			menuCarousel.currentMenu.main();
			
			// hide the mouse when not in use
			if(hideMouseFrames < HIDE_MOUSE_FRAMES){
				hideMouseFrames++;
				if(hideMouseFrames >= HIDE_MOUSE_FRAMES){
					Mouse.hide();
				}
			}
		}
		
		/* Pause the game and make the inventory screen visible */
		public function pauseGame():void{
			if(state == GAME){
				state = MENU;
				menuCarousel.activate();
			} else if(state == MENU){
				state = GAME;
				menuCarousel.deactivate();
			}
		}
		
		/*
		 * Creates a map of ints that represents properties of static blocks
		 * Any block to interact with is generated on the fly using this 2D array to determine its
		 * properties. 'id's of blocks are inferred by the tile numbers
		 */
		private function createPropertyMap(map:Array):Vector.<Vector.<int>>{
			var idMap:Vector.<Vector.<int>> = new Vector.<Vector.<int>>(mapTileManager.height, true), r:int, c:int;
			for(r = 0; r < mapTileManager.height; r++){
				idMap[r] = new Vector.<int>(mapTileManager.width, true);
				for(c = 0; c < mapTileManager.width; c++){
					idMap[r][c] = MapTileConverter.getMapProperties(map[r][c]);
					
					// mark out edges so wall walkers can't go into them
					if(c == 0 || r == 0 || c == mapTileManager.width - 1 || r == mapTileManager.height - 1){
						idMap[r][c] |= Collider.MAP_EDGE;
					}
				}
			}
			return idMap;
		}
		
		/* Play a sound at a volume based on the distance to the player */
		public function createDistSound(mapX:int, mapY:int, name:String, names:Array = null, volume:Number = 1):void{
			var dist:Number = Math.abs(player.mapX - mapX) * SOUND_HORIZ_DIST_MULTIPLIER + Math.abs(player.mapY - mapY);
			if(dist < SOUND_DIST_MAX){
				if(names) soundQueue.addRandom(name, names, (SOUND_DIST_MAX - dist) * INV_SOUND_DIST_MAX * volume);
				else if(name) soundQueue.add(name, (SOUND_DIST_MAX - dist) * INV_SOUND_DIST_MAX * volume);
			}
		}
		
		/* Switches to the appropriate music */
		public function changeMusic():void{
			var start:int;
			var name:String;
			if(SoundManager.soundLoops["underworldMusic2"]) SoundManager.fadeLoopSound("underworldMusic2", -SoundManager.DEFAULT_FADE_STEP);
			if(state == UNFOCUSED || state == INSTRUCTIONS || state == EPILOGUE){
				if(SoundManager.currentMusic){
					SoundManager.fadeMusic(SoundManager.currentMusic, -SoundManager.DEFAULT_FADE_STEP);
				}
			} else if(state == TITLE){
				if(SoundManager.music && SoundManager.currentMusic != "introMusic") SoundManager.fadeMusic("introMusic", SoundManager.DEFAULT_FADE_STEP, 0, true);
				
			} else {
				if(player && player.asleep){
					name = "sleepMusic";
					if(!SoundManager.currentMusic || SoundManager.currentMusic != name){
						start = int(SoundManager.musicTimes[name]);
						SoundManager.fadeMusic(name, 1.0 / 60, start);
					}
				} else {
					if(map.type == Map.AREA){
						if(map.level == Map.OVERWORLD) name = "overworldMusic";
						else if(map.level == Map.UNDERWORLD) name = "underworldMusic1";
						if(!SoundManager.currentMusic || SoundManager.currentMusic != name){
							if(map.level == Map.OVERWORLD){
								start = int(SoundManager.musicTimes[name]);
							} else if(map.level == Map.UNDERWORLD){
								start = (SoundManager.sounds["underworldMusic1"] as Sound).length * 0.5;
								if(SoundManager.music && !SoundManager.soundLoops["underworldMusic2"]) SoundManager.fadeLoopSound("underworldMusic2");
							}
							SoundManager.fadeMusic(name, SoundManager.DEFAULT_FADE_STEP, start);
						}
					} else {
						name = Map.ZONE_NAMES[map.zone] + "Music";
						if(!SoundManager.currentMusic || SoundManager.currentMusic != name){
							start = int(SoundManager.musicTimes[name]);
							SoundManager.fadeMusic(name, SoundManager.DEFAULT_FADE_STEP, start);
						}
					}
				}
			}
		}
		
		/* A cheat for adding lives */
		private function addLife():void{
			if(livesAvailable.value <= 0){
				console.print("3 is your limit cheater");
				return;
			}
			lives.value++;
			livesAvailable.value--;
			console.print("1up");
			soundQueue.add("jump");
			livesPanel.visible = true;
			livesPanel["_" + lives.value].gotoAndPlay("fadeIn");
		}
		
		/* Called only when lives are above 0 */
		public function loseLife():void{
			livesPanel["_" + lives.value].gotoAndStop("dead");
			lives.value--;
			if(lives.value == 0) livesPanel.visible = false;
			console.print("this is not how the game is meant to be played");
		}
		
		/* Called when all salient features in the dungeon level are dealt with */
		public function levelComplete():void{
			var nameStr:String;
			if(game.map.type == Map.MAIN_DUNGEON) nameStr = "level " + game.map.level;
			else nameStr = Map.getName(game.map.level, game.map.type);
			console.print(nameStr + " cleared");
			map.cleared = true;
			content.clearLevel(map.level, map.type);
			game.soundQueue.add("ping");
			miniMap.reveal();
		}
		
		/* Return a greedy match for an item on the ground (for areas) */
		public function getFloorItem(name:int, type:int):Item{
			var i:int, item:Item;
			for(i = 0; i < items.length; i++){
				item = items[i] as Item;
				if(item && item.name == name && item.type == type){
					return item;
				}
			}
			return null;
		}
		
		/* Creates the instructions splash screen and switches to INSTRUCTIONS state*/
		public function initInstructions():void{
			instructionsPreviousState = state;
			if(state == MENU){
				menuCarousel.deactivate();
			} else if(state == UNFOCUSED){
				instructionsPreviousState = focusPreviousState;
			}
			state = INSTRUCTIONS;
			
			// generate splash
			var mc:MovieClip = new InstructionsMC();
			var combatText:TextBox = new TextBox(215, 62, 0x0, 0x0);
			combatText.alignVert = "center";
			combatText.text = "walk into monsters to auto-attack";
			mc.addChild(combatText);
			combatText.x = mc.combat.x + mc.combat.width + 3;
			combatText.y = mc.combat.y;
			var collectText:TextBox = new TextBox(215, 62, 0x0, 0x0);
			collectText.alignVert = "center";
			collectText.text = "press up to collect and to read";
			mc.addChild(collectText);
			collectText.x = mc.collect.x + mc.collect.width + 3;
			collectText.y = mc.collect.y;
			var exitText:TextBox = new TextBox(215, 62, 0x0, 0x0);
			exitText.alignVert = "center";
			exitText.text = "press down to exit a level";
			mc.addChild(exitText);
			exitText.x = mc.exit.x + mc.exit.width + 3;
			exitText.y = mc.exit.y;
			var menuText:TextBox = new TextBox(WIDTH, 12, 0x0, 0x0);
			menuText.align = "center";
			menuText.text = "use the menu key (" + Key.keyString(Key.custom[MENU_KEY]) + ") for items and skills";
			mc.addChild(menuText);
			var pressMenuText:TextBox = new TextBox(Menu.LIST_WIDTH * 2, 12, Dialog.ROLL_OUT_COL);
			pressMenuText.align = "center";
			pressMenuText.text = "press menu key " + (firstInstructions ? "to play" : "to resume");
			mc.addChild(pressMenuText);
			pressMenuText.x = (WIDTH * 0.5 - pressMenuText.width * 0.5) >> 0;
			pressMenuText.y = HEIGHT - (pressMenuText.height + 2);
			menuText.y = pressMenuText.y - (menuText.height + 5);
			instructions = mc;
			instructionsHolder.addChild(instructions);
			
			changeMusic();
		}
		
		public function createFocusPrompt():void{
			focusPrompt = new Sprite();
			focusPrompt.addChild(getTitleGfx());
			
			var clickToPlayText:TextBox = new TextBox(320, 12, 0x0, 0x0);
			clickToPlayText.align = "center";
			clickToPlayText.text = "click to play";
			clickToPlayText.bitmapData.colorTransform(clickToPlayText.bitmapData.rect, RED_COL);
			focusPrompt.addChild(clickToPlayText);
			clickToPlayText.y = (HEIGHT * 0.5) + 10;
			
			if(UserData.settings.playerConsumed){
				clickToPlayText.text = "click to not play";
				clickToPlayText.bitmapData.colorTransform(clickToPlayText.bitmapData.rect, RED_COL);
			} else if(UserData.settings.ascended){
				clickToPlayText.text = "click to play again";
			}
		}
		
		public function getTitleGfx():Sprite{
			var sprite:Sprite = new Sprite();
			sprite.graphics.beginFill(0x0);
			sprite.graphics.drawRect(0, 0, WIDTH, HEIGHT);
			var titleB:Bitmap;
			if(UserData.settings.playerConsumed){
				titleB = new library.BannerFailB();
			} else if(UserData.settings.ascended){
				titleB = new library.BannerCompleteB();
			} else {
				titleB = new library.BannerB();
			}
			sprite.addChild(titleB);
			titleB.y = HEIGHT * 0.5 - titleB.height * 0.5;
			titleB.scaleX = titleB.scaleY = 0.5;
			return sprite;
		}
		
		public function epilogueInit():void{
			state = EPILOGUE;
			var type:int;
			var typeStr:String;
			if(UserData.gameState.husband && minion){
				type = Epilogue.HUSBAND;
				typeStr = "husband epilogue";
			} else if(gameMenu.inventoryList.getItem(Item.YENDOR, Item.ARMOUR)){
				type = Epilogue.YENDOR;
				typeStr = "yendor epilogue";
			} else {
				type = Epilogue.EMPTY_HANDED;
				typeStr = "empty handed epilogue";
			}
			trackEvent(typeStr);
			epilogue = new Epilogue(type, this, renderer);
			instructionsHolder.addChild(epilogue);
			changeMusic();
		}
		
		public function consumedPlayerInit():void{
			playerHealthBar.visible = false;
			minionHealthBar.visible = false;
			playerXpBar.visible = false;
			enemyHealthBar.visible = false;
			miniMap.visible = false;
			keyItemStatus.visible = false;
			playerActionBar.visible = false;
			playerConsumedMenu.select(0);
			menuCarousel.setCurrentMenu(playerConsumedMenu);
		}
		
		private function clearInstructions():void{
			var levelName:String = "";
			if(firstInstructions){
				levelName = Map.getName(map.level, map.type);
				firstInstructions = false;
			}
			transition.init(function():void{
				if(instructions.parent) instructions.parent.removeChild(instructions);
				instructions = null;
				state = instructionsPreviousState;
				if(state == MENU){
					menuCarousel.activate();
				}
				changeMusic();
			}, null, levelName, false, instructionsPreviousState == MENU);
		}
		
		private function mouseDown(e:MouseEvent):void{
			mousePressed = true;
			mousePressedCount = frameCount;
		}
		
		private function mouseUp(e:MouseEvent):void{
			mousePressed = false;
		}
		
		private function mouseMove(e:MouseEvent):void{
			if(hideMouseFrames >= HIDE_MOUSE_FRAMES) Mouse.show();
			hideMouseFrames = 0;
		}
		
		private function keyPressed(e:KeyboardEvent):void{
			if(Key.lockOut) return;
			if(Key.customDown(MENU_KEY) && !Game.dialog){
				if(state == INSTRUCTIONS){
					clearInstructions();
				} else if(state == TITLE){
					if(!menuCarousel.active){
						menuCarousel.activate();
						titlePressMenuText.visible = false;
					}
				} else if(state == EPILOGUE){
				} else {
					pauseGame();
				}
			}
			if(Key.isDown(Keyboard.CONTROL) && Key.isDown(Keyboard.SHIFT) && Key.isDown(Keyboard.ENTER)){
				gameMenu.addDebugOption();
				if(fpsText) fpsText.visible = true;
			}
			/*
			if(Key.isDown(Key.T)){
				var portal:Portal = Portal.createPortal(Portal.MINION, game.player.mapX, game.player.mapY);
				portal.setCloneTemplate();
			}
			if(Key.isDown(Key.T)){
				if(balrog) balrog.death();
			}
			if(Key.isDown(Key.K)){
				//player.jump();
				player.setAsleep(true);
			}
			if(Key.isDown(Key.T)){
				renderer.gifBuffer.save();
			}
			if(Key.isDown(Key.T)){
				miniMap.reveal();
			}
			if(Key.isDown(Key.R)){
				reset();
			}
			if(Key.isDown(Key.P)){
				//minion.death("key");
				player.levelUp();
			}*/
		}
		
		/* When the flash object loses focus we put up a splash screen to encourage players to click to play */
		private function onFocusLost(e:Event = null):void{
			if(state == UNFOCUSED) return;
			focusPreviousState = state;
			state = UNFOCUSED;
			Key.clearKeys();
			addChild(focusPrompt);
			changeMusic();
		}
		
		/* When focus returns we remove the splash screen -
		 * 
		 * WARNING: Activating fullscreen mode causes this method to be fired twice by the Flash Player
		 * for some unknown reason.
		 * 
		 * Any modification to this method should take this into account and protect against repeat calls
		 */
		private function onFocus(e:Event = null):void{
			if(focusPrompt.parent) focusPrompt.parent.removeChild(focusPrompt);
			if(state == UNFOCUSED) state = focusPreviousState;
			changeMusic();
		}
		
		/* Sends information to the Google Analytics tracking widget on the home page of redrogue.net */
		public function trackEvent(action:String, label:String = ""):void{
			var seconds:int = frameCount / 30;
			var params:Array = ["_trackEvent", "game_events_alpha", action, label, seconds];
			if(allowScriptAccess){
				ExternalInterface.call("_gaq.push", params);
			}
			trace(params);
		}
		
		public static function versionToString():String{
			var str:String = "" + VERSION_NUM;
			return str.substr(0, str.length - 1) + "." + str.charAt(str.length - 1);
		}
	}
	
}