package {
	import com.adobe.serialization.json.JSON;
	import com.robotacid.ai.Brain;
	import com.robotacid.ai.HorrorBrain;
	import com.robotacid.ai.Node;
	import com.robotacid.ai.PlayerBrain;
	import com.robotacid.engine.FadeLight;
	import com.robotacid.engine.Sleep;
	import com.robotacid.engine.Writing;
	import com.robotacid.level.Content;
	import com.robotacid.level.MapBitmap;
	import com.robotacid.level.Map;
	import com.robotacid.engine.ChaosWall;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Explosion;
	import com.robotacid.engine.Minion;
	import com.robotacid.engine.Portal;
	import com.robotacid.engine.Entity;
	import com.robotacid.engine.MapTileManager;
	import com.robotacid.engine.Player;
	import com.robotacid.engine.MapTileConverter;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.Stone;
	import com.robotacid.engine.Trap;
	import com.robotacid.geom.Pixel;
	import com.robotacid.geom.Trig;
	import com.robotacid.gfx.*;
	import com.robotacid.phys.Collider;
	import com.robotacid.phys.CollisionWorld;
	import com.robotacid.sound.gameSoundsInit;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.sound.SoundQueue;
	import com.robotacid.ui.Console;
	import com.robotacid.ui.Dialog;
	import com.robotacid.ui.Editor;
	import com.robotacid.ui.menu.EditorMenuList;
	import com.robotacid.ui.menu.GameMenu;
	import com.robotacid.ui.menu.QuestMenuList;
	import com.robotacid.ui.menu.QuestMenuOption;
	import com.robotacid.ui.ProgressBar;
	import com.robotacid.ui.QuickSave;
	import com.robotacid.ui.Suggestion;
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
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
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
		
		public static const BUILD_NUM:int = 379;
		
		public static const TEST_BED_INIT:Boolean = true;
		
		public static var game:Game;
		public static var renderer:Renderer;
		public static var debug:Graphics;
		public static var debugStay:Graphics;
		public static var dialog:Dialog;
		
		// core engine objects
		public var player:Player;
		public var minion:Minion;
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
		
		// graphics
		public var mapTileManager:MapTileManager;
		public var lightMap:LightMap;
		public var lightning:Lightning;
		
		// ui
		public var focusPrompt:Sprite;
		public var menuHolder:Sprite;
		public var miniMapHolder:Sprite;
		public var console:Console;
		public var confusionOverlayHolder:Sprite;
		public var menu:GameMenu;
		public var miniMap:MiniMap;
		public var playerActionBar:ProgressBar;
		public var playerHealthBar:ProgressBar;
		public var playerXpBar:ProgressBar;
		public var levelNumGfx:MovieClip;
		public var minionHealthBar:ProgressBar;
		public var enemyHealthBar:ProgressBar;
		public var livesPanel:LivesPanel;
		public var keyItemStatus:Sprite;
		public var suggestion:Suggestion;
		public var fpsText:TextBox;
		
		// debug
		public var info:TextField;
		
		// lists
		public var entities:Vector.<Entity>;
		public var items:Array;
		public var effects:Vector.<Effect>;
		public var portals:Vector.<Portal>;
		public var chaosWalls:Vector.<ChaosWall>;
		public var explosions:Vector.<Explosion>;
		
		// states
		public var state:int;
		public var previousState:int;
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
		public var lives:int;
		public var visitedHash:Object;
		
		// temp variables
		private var i:int;
		
		public static var point:Point = new Point();
		
		// CONSTANTS
		
		public static const SCALE:Number = 16;
		public static const INV_SCALE:Number = 1.0 / 16;
		
		public static const GAME:int = 0;
		public static const MENU:int = 1;
		public static const DIALOG:int = 2;
		public static const TITLE:int = 3;
		public static const UNFOCUSED:int = 4;
		
		public static const WIDTH:Number = 320;
		public static const HEIGHT:Number = 240;
		
		// game key properties
		public static const UP_KEY:int = 0;
		public static const DOWN_KEY:int = 1;
		public static const LEFT_KEY:int = 2;
		public static const RIGHT_KEY:int = 3;
		public static const MENU_KEY:int = 4;
		
		public static const MAX_LEVEL:int = 20;
		
		public static const HEALTH_GLOW_RATIO:Number = 0.25;
		public static const DEFAULT_BAR_COL:uint = 0xFFCCCCCC;
		public static const DISABLED_BAR_COL:uint = 0xFFAA0000;
		public static const GLOW_BAR_COL:uint = 0xAA0000;
		
		public static const SOUND_DIST_MAX:int = 12;
		public static const INV_SOUND_DIST_MAX:Number = 1.0 / SOUND_DIST_MAX;
		public static const SOUND_HORIZ_DIST_MULTIPLIER:Number = 1.5;
		
		public function Game():void {
			
			library = new Library;
			
			renderer = new Renderer(this);
			renderer.init();
			
			game = this;
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
			Suggestion.game = this;
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
			
			random = new XorRandom();
			
			sleep = new Sleep(this, renderer);
			
			transition = new Transition();
			
			lightning = new Lightning();
			
			suggestion = new Suggestion();
			
			editor = new Editor(this, renderer);
			
			var byteArray:ByteArray;
			
			byteArray = new Character.statsData();
			Character.stats = JSON.decode(byteArray.readUTFBytes(byteArray.length));
			
			byteArray = new Item.statsData();
			Item.stats = JSON.decode(byteArray.readUTFBytes(byteArray.length));
			
			FPS.start();
			
			// SOUND INIT
			gameSoundsInit();
			soundQueue = new SoundQueue();
			
			dogmaticMode = false;
			
			if (stage) addedToStage();
			else addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		
		private function addedToStage(e:Event = null):void{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			// KEYS INIT
			if(!Key.initialized){
				Key.init(stage);
				Key.custom = [Key.W, Key.S, Key.A, Key.D, Keyboard.SPACE, Key.F, Key.Z, Key.X, Key.C, Key.V, Key.NUMBER_1, Key.NUMBER_2, Key.NUMBER_3, Key.NUMBER_4];
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
			
			Map.random = new XorRandom(Map.seed);
			
			renderer.createRenderLayers(this);
			
			addChild(editor.bitmap);
			
			addChild(sleep);
			
			// UI INIT
			
			if(!console){
				console = new Console();
				console.y = HEIGHT - Console.HEIGHT;
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
			
			playerHealthBar = new ProgressBar(5, console.y - 22, 27, 17, HEALTH_GLOW_RATIO, 0xAA0000);
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
			
			addChild(transition);
			
			if(!menu){
				menu = new GameMenu(WIDTH, console.y, this);
			} else {
				// update the rng seed
				if(Map.seed == 0) menu.seedInputList.option.name = "" + Map.random.seed;
			}
			menuHolder = new Sprite();
			addChild(menuHolder);
			menu.holder = menuHolder;
			if(state == MENU){
				menuHolder.addChild(menu);
			}
			
			if(!focusPrompt){
				focusPrompt = new Sprite();
				focusPrompt.graphics.beginFill(0x000000);
				focusPrompt.graphics.drawRect(0, 0, WIDTH, HEIGHT);
				var clickToPlayText:TextBox = new TextBox(100, 12, 0x0, 0x0);
				clickToPlayText.align = "center";
				clickToPlayText.text = "click to play";
				clickToPlayText.bitmapData.colorTransform(clickToPlayText.bitmapData.rect, new ColorTransform(1, 0, 0, 1, -85));
				focusPrompt.addChild(clickToPlayText);
				clickToPlayText.x = (WIDTH * 0.5) - 50;
				clickToPlayText.y = (HEIGHT * 0.5) + 10;
				var buildText:TextBox = new TextBox(100, 12, 0x0, 0x0);
				buildText.align = "center";
				buildText.text = "build " + BUILD_NUM;
				buildText.bitmapData.colorTransform(buildText.bitmapData.rect, new ColorTransform(1, 0, 0, 1, -85));
				focusPrompt.addChild(buildText);
				buildText.x = (WIDTH * 0.5) - 50;
				buildText.y = HEIGHT - 14;
				var title_b:Bitmap = new library.BannerB();
				focusPrompt.addChild(title_b);
				title_b.y = HEIGHT * 0.5 - title_b.height * 0.5;
				title_b.scaleX = title_b.scaleY = 0.5;
				stage.addEventListener(Event.DEACTIVATE, onFocusLost);
				stage.addEventListener(Event.ACTIVATE, onFocus);
			}
			
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
			addChild(fpsText);
			
			// STATES
			
			frameCount = 1;
			deepestLevelReached = 1;
			lives = 0;
			
			// LISTS
			
			entities = new Vector.<Entity>();
			items = [];
			effects = new Vector.<Effect>();
			portals = new Vector.<Portal>();
			chaosWalls = new Vector.<ChaosWall>();
			explosions = new Vector.<Explosion>();
			portalHash = {};
			
			Item.runeNames = [];
			for(i = 0; i < MAX_LEVEL; i++){
				Item.runeNames.push("?");
			}
			// the identify rune's name is already known (obviously)
			Item.runeNames[Item.IDENTIFY] = Item.stats["rune names"][Item.IDENTIFY];
			
			Brain.initCharacterLists();
			Brain.voiceCount = Brain.VOICE_DELAY + random.range(Brain.VOICE_DELAY);
			
			// ALL CONTENT FOR THE RANDOM SEED GENERATED FROM THIS POINT FORWARD
			content = new Content();
			Writing.createStoryCharCodes(Map.random);
			Sleep.initDreams();
			
			// LEVEL SPECIFIC INIT
			// This stuff that follows requires the bones of a level to initialise
			
			Player.previousLevel = Map.OVERWORLD;
			Player.previousPortalType = Portal.STAIRS;
			Player.previousMapType = Map.AREA;
			
			// CREATE FIRST LEVEL =================================================================
			setLevel(1, Portal.STAIRS);
			
			// fire up listeners
			addListeners();
			
			// init area visit notices
			var levelName:String = Map.getName(map.type, map.level);
			visitedHash = {};
			visitedHash[levelName] = true;
			
			// this is a hack to force clicking on the game when the browser first pulls in the swf
			if(forceFocus){
				onFocusLost();
				forceFocus = false;
			} else {
				changeMusic();
			}
			
			if(TEST_BED_INIT) initTestBed();
			else transition.init(function():void{}, null, levelName, true);
		}
		
		/* Pedantically clear all memory and re-init the project */
		public function reset():void{
			removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			removeEventListener(Event.ENTER_FRAME, main);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			stage.removeEventListener(Event.DEACTIVATE, onFocusLost);
			stage.removeEventListener(Event.ACTIVATE, onFocus);
			while(numChildren > 0){
				removeChildAt(0);
			}
			player = null;
			minion = null;
			mapTileManager = null;
			map = null;
			world = null;
			lightMap = null;
			mapTileManager = null;
			Player.previousLevel = Map.OVERWORLD;
			Player.previousPortalType = Portal.STAIRS;
			Player.previousMapType = Map.AREA;
			SoundManager.musicTimes = {};
			console.log = "";
			console.logLines = 0;
			editor.deactivate();
			init();
		}
		
		/* Enters the testing area */
		public function launchTestBed():void{
			setLevel( -1, Portal.STAIRS);
			menu.editorList.setLight(menu.editorList.lightList.selection);
		}
		
		/* Enters the the testing area from game init */
		public function initTestBed():void{
			menu.editorList.renderAIPathsList.selection = EditorMenuList.ON;
			menu.editorList.renderAIGraphList.selection = EditorMenuList.ON;
			menu.editorList.renderCollisionList.selection = EditorMenuList.ON;
			launchTestBed();
		}
		
		/* Used to change to a new level in the dungeon
		 *
		 * This method tries to wipe all layers whilst leaving the gaming architecture in place
		 */
		public function setLevel(n:int, portalType:int, loaded:Boolean = false):void{
			
			editor.deactivate();
			
			// maintain debug state if present
			if(map && map.level == -1){
				n = -1;
				Player.previousLevel = -1;
				Player.previousPortalType = Portal.ITEM;
				Player.previousMapType = Map.MAIN_DUNGEON;
				loaded = true;
			}
			
			if(!loaded && map){
				// left over content needs to be pulled back into the content manager to be found
				// if the level is visited again
				content.recycleLevel(map.type);
				//QuickSave.save(this, true);
			}
			
			// elements to update:
			
			// game objects list needs to be emptied
			// items list needs to be emptied
			// colliders list needs to be emptied
			// new map
			// clear rendering layers
			
			if(n > deepestLevelReached && deepestLevelReached < MAX_LEVEL) deepestLevelReached = n;
			
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
			renderer.fx.length = 0;
			portals.length = 0;
			chaosWalls.length = 0;
			explosions.length = 0;
			portalHash = {};
			
			Brain.monsterCharacters.length = 0;
			Brain.voiceCount = Brain.VOICE_DELAY + random.range(Brain.VOICE_DELAY);
			
			// figure out where in hell's name we're going
			var mapType:int = Map.MAIN_DUNGEON;
			if(portalType == Portal.STAIRS){
				if(n == 0) mapType = Map.AREA;
			} else if(portalType == Portal.ITEM){
				mapType = Map.ITEM_DUNGEON;
			} else if(portalType == Portal.UNDERWORLD){
				mapType = Map.AREA;
			} else if(portalType == Portal.OVERWORLD){
				mapType = Map.AREA;
			}
			
			map = new Map(n, mapType);
			
			Brain.initMapGraph(map.bitmap);
			
			if(!mapTileManager){
				mapTileManager = new MapTileManager(this, renderer.canvas, SCALE, map.width, map.height, WIDTH, HEIGHT);
				mapTileManager.setLayers(map.layers);
			} else {
				mapTileManager.newMap(map.width, map.height, map.layers);
			}
			renderer.blockBitmapData = mapTileManager.layerToBitmapData(MapTileManager.BACKGROUND_LAYER);
			if(map.type != Map.AREA){
				renderer.blockBitmapData = mapTileManager.layerToBitmapData(MapTileManager.BLOCK_LAYER, renderer.blockBitmapData);
				Writing.renderWritings();
			}
			
			// modify the mapRect to conceal secrets
			mapTileManager.mapRect = map.bitmap.adjustedMapRect;
			renderer.camera.mapRect = map.bitmap.adjustedMapRect;
			
			world = new CollisionWorld(map.width, map.height, SCALE);
			world.map = createPropertyMap(mapTileManager.mapLayers[MapTileManager.BLOCK_LAYER]);
			
			Explosion.initMap(map.width, map.height);
			
			// collider debug
			//world.debug = debug;
			
			renderer.sceneManager = SceneManager.getSceneManager(map.level, map.type);
			
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
			
			if(!player){
				var playerMc:MovieClip = new RogueMC();
				var minionMc:MovieClip = new SkeletonMC();
				var startX:Number = (map.start.x + 0.5) * SCALE;
				var startY:Number = (map.start.y + 1) * SCALE;
				player = new Player(playerMc, startX, startY);
				minion = new Minion(minionMc, startX, startY, Character.SKELETON);
				player.snapCamera();
			} else {
				player.collider.x = -player.collider.width * 0.5 + (map.start.x + 0.5) * SCALE;
				player.collider.y = -player.collider.height + (map.start.y + 1) * SCALE;
				player.mapX = (player.collider.x + player.collider.width * 0.5) * INV_SCALE;
				player.mapY = (player.collider.y + player.collider.height * 0.5) * INV_SCALE;
				player.snapCamera();
			}
			
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
			}
			
			// outside areas are set pieces, meant to give contrast to the dungeon and give the player
			// and minion a back-story
			if(mapType == Map.AREA){
				
				renderer.lightBitmap.visible = false;
				miniMap.visible = false;
				mapTileManager.setLayerUpdate(MapTileManager.BLOCK_LAYER, false);
				SoundManager.fadeMusic("music1", -SoundManager.DEFAULT_FADE_STEP);
				
				// the overworld changes the rogue to a colour version and reverts all polymorph effects
				if(map.level == Map.OVERWORLD){
					var skinMc:MovieClip;
					
					// unequip face armour if worn
					if(player.armour && player.armour.name == Item.FACE) player.unequip(player.armour);
					if(minion && minion.armour && minion.armour.name == Item.FACE) minion.unequip(minion.armour);
					// change the rogue to a colour version and revert the minion if changed
					skinMc = new RogueColMC();
					if(player.name != Character.ROGUE){
						console.print("rogue reverts to human form");
					}
					player.changeName(Character.ROGUE, new RogueColMC());
					if(minion && minion.name != Character.SKELETON){
						skinMc = game.library.getCharacterGfx(Character.SKELETON);
						minion.changeName(Character.SKELETON, skinMc);
						console.print("minion reverts to undead form");
					}
					
				} else if(map.level == Map.UNDERWORLD){
					if(player.undead) player.applyHealth(player.totalHealth);
					if(minion && minion.undead) minion.applyHealth(minion.totalHealth);
				}
				
			} else if(map.level == -1){
				renderer.lightBitmap.visible = false;
				
			} else if(Player.previousMapType == Map.AREA){
				if(!SoundManager.currentMusic) SoundManager.fadeMusic("music1");
				renderer.lightBitmap.visible = true;
				miniMap.visible = true;
				
				// revert to black and white rogue
				if(Player.previousLevel == Map.OVERWORLD){
					player.changeName(Character.ROGUE, new RogueMC);
				}
			}
			player.enterLevel(entrance, Player.previousLevel < game.map.level ? Collider.RIGHT : Collider.LEFT);
			changeMusic();
		}
		
		private function addListeners():void{
			stage.addEventListener(Event.DEACTIVATE, onFocusLost);
			stage.addEventListener(Event.ACTIVATE, onFocus);
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			addEventListener(Event.ENTER_FRAME, main);
		}
		
		// =================================================================================================
		// MAIN LOOP
		// =================================================================================================
		
		private function main(e:Event):void {
			
			fpsText.text = "fps:" + FPS.value;
			
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
						if(collider.properties & Collider.CHARACTER){
							collider.pushDamping = 0;
							character = collider.userData as Character;
							character.mapX = (collider.x + collider.width * 0.5) * INV_SCALE;
							character.mapY = (collider.y + collider.height * 0.5) * INV_SCALE;
							character.mapProperties = world.map[character.mapY][character.mapX];
						}
					}
					
					if(player.active){
						player.main();
						if(player.asleep) sleep.main();
						if(transition.active) return;
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
					
					renderer.main();
					
					if(editor.active) editor.main();
					
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
				
			}
			
			menu.main();
			
			if(player.brain.confusedCount) (player.brain as PlayerBrain).renderConfusion();
		}
		
		/* Pause the game and make the inventory screen visible */
		public function pauseGame():void{
			if(state == GAME){
				state = MENU;
				menu.activate();
			} else if(state == MENU){
				state = GAME;
				menu.deactivate();
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
		public function createDistSound(mapX:int, mapY:int, name:String, names:Array = null):void{
			var dist:Number = Math.abs(player.mapX - mapX) * SOUND_HORIZ_DIST_MULTIPLIER + Math.abs(player.mapY - mapY);
			if(dist < SOUND_DIST_MAX){
				if(names) soundQueue.addRandom(name, names, (SOUND_DIST_MAX - dist) * INV_SOUND_DIST_MAX);
				else if(name) soundQueue.add(name, (SOUND_DIST_MAX - dist) * INV_SOUND_DIST_MAX);
			}
		}
		
		/* Switches to the appropriate music */
		public function changeMusic():void{
			
			var start:int;
			var name:String;
			if(SoundManager.soundLoops["underworldMusic2"]) SoundManager.fadeLoopSound("underworldMusic2", -SoundManager.DEFAULT_FADE_STEP)
			if(state == UNFOCUSED){
				if(SoundManager.currentMusic){
					SoundManager.fadeMusic(SoundManager.currentMusic, -SoundManager.DEFAULT_FADE_STEP);
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
		
		/* A cheat for adding lives */
		private function addLife():void{
			if(lives >= 3){
				console.print("3 is your limit cheater");
				return;
			}
			lives++;
			console.print("1up");
			soundQueue.add("jump");
			livesPanel.visible = true;
			livesPanel["_" + lives].gotoAndPlay("fadeIn");
		}
		
		/* Called only when lives are above 0 */
		public function loseLife():void{
			livesPanel["_" + lives].gotoAndStop("dead");
			lives--;
			if(lives == 0) livesPanel.visible = false;
			console.print("this is not how the game is meant to be played");
		}
		
		public function levelCompleteMsg():void{
			var nameStr:String;
			if(game.map.type == Map.MAIN_DUNGEON) nameStr = "level " + game.map.level;
			else nameStr = Map.getName(game.map.type, game.map.level);
			console.print(nameStr + " cleared");
		}
		
		private function mouseDown(e:MouseEvent):void{
			mousePressed = true;
			mousePressedCount = frameCount;
		}
		
		private function mouseUp(e:MouseEvent):void{
			mousePressed = false;
		}
		
		private function keyPressed(e:KeyboardEvent):void{
			if(Key.lockOut) return;
			if(Key.customDown(MENU_KEY) && !Game.dialog){
				pauseGame();
			}
			/*if(Key.isDown(Key.K)){
				//player.jump();
				player.setAsleep(true);
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
			previousState = state;
			state = UNFOCUSED;
			Key.forceClearKeys();
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
			if(state == UNFOCUSED) state = previousState;
			changeMusic();
		}
	}
	
}