package {
	import com.adobe.serialization.json.JSON;
	import com.robotacid.ai.Brain;
	import com.robotacid.ai.Node;
	import com.robotacid.dungeon.Content;
	import com.robotacid.dungeon.DungeonBitmap;
	import com.robotacid.engine.ChaosWall;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Effect;
	import com.robotacid.gfx.ItemMovieClip;
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
	import com.robotacid.dungeon.Map;
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
		
		public static const BUILD_NUM:int = 310;
		
		public static var game:Game;
		public static var renderer:Renderer;
		public static var debug:Graphics;
		public static var debugStay:Graphics;
		public static var dialog:Dialog;
		
		// core engine objects
		public var player:Player;
		public var minion:Minion;
		public var library:Library;
		public var dungeon:Map;
		public var content:Content;
		public var entrance:Portal;
		public var world:CollisionWorld;
		public var random:XorRandom;
		public var soundQueue:SoundQueue;
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
		public var menu:GameMenu;
		public var miniMap:MiniMap;
		public var playerHealthBar:ProgressBar;
		public var playerXpBar:ProgressBar;
		public var levelNumGfx:MovieClip;
		public var minionHealthBar:ProgressBar;
		public var enemyHealthBar:ProgressBar;
		public var fpsText:TextBox;
		
		// debug
		public var info:TextField;
		
		// lists
		public var entities:Vector.<Entity>;
		public var items:Array;
		public var effects:Vector.<Effect>;
		public var portals:Vector.<Portal>;
		public var chaosWalls:Vector.<ChaosWall>;
		
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
		public var konamiCode:Boolean = false;
		public var colossalCaveCode:Boolean = false;
		public var forceFocus:Boolean = true;
		public var portalHash:Object;
		public var dogmaticMode:Boolean;
		
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
			DungeonBitmap.game = this;
			Lightning.game = this;
			ItemMovieClip.game = this;
			SceneManager.game = this;
			QuestMenuList.game = this;
			QuestMenuOption.game = this;
			Dialog.game = this;
			EditorMenuList.game = this;
			
			Effect.BANNED_RANDOM_ENCHANTMENTS[Effect.PORTAL] = true;
			Effect.BANNED_RANDOM_ENCHANTMENTS[Effect.NULL] = true;
			Effect.BANNED_RANDOM_ENCHANTMENTS[Effect.CHAOS] = true;
			Effect.BANNED_RANDOM_ENCHANTMENTS[Effect.IDENTIFY] = true;
			
			TextBox.init();
			MapTileConverter.init();
			ProgressBar.initGlowTable();
			
			random = new XorRandom();
			
			transition = new Transition();
			
			lightning = new Lightning();
			
			editor = new Editor(this, renderer);
			
			var statsByteArray:ByteArray;
			
			statsByteArray = new Character.statsData();
			Character.stats = JSON.decode(statsByteArray.readUTFBytes(statsByteArray.length));
			
			statsByteArray = new Item.statsData();
			Item.stats = JSON.decode(statsByteArray.readUTFBytes(statsByteArray.length));
			
			FPS.start();
			
			// SOUND INIT
			SoundManager.init();
			SoundManager.addSound(new JumpSound, "jump", 0.6);
			SoundManager.addSound(new StepsSound, "step", 0.6);
			SoundManager.addSound(new ClickSound, "click", 0.7);
			SoundManager.addSound(new RogueDeathSound, "rogueDeath", 1.0);
			SoundManager.addSound(new MissSound, "miss", 0.6);
			SoundManager.addSound(new KillSound, "kill", 0.6);
			SoundManager.addSound(new ThudSound, "thud", 0.5);
			SoundManager.addSound(new BowShootSound, "bowShoot", 0.8);
			SoundManager.addSound(new ThrowSound, "throw", 0.8);
			SoundManager.addSound(new ChestOpenSound, "chestOpen", 0.4);
			SoundManager.addSound(new RuneHitSound, "runeHit", 0.8);
			SoundManager.addSound(new TeleportSound, "teleport", 0.8);
			SoundManager.addSound(new HitSound, "hit", 0.6);
			SoundManager.addSound(new BatDeathSound1, "batDeath1", 0.2);
			SoundManager.addSound(new BatDeathSound2, "batDeath2", 0.2);
			SoundManager.addSound(new BatDeathSound3, "batDeath3", 0.2);
			SoundManager.addSound(new BatDeathSound4, "batDeath4", 0.2);
			SoundManager.addSound(new BloodHitSound1, "bloodHit1", 0.7);
			SoundManager.addSound(new BloodHitSound2, "bloodHit2", 0.7);
			SoundManager.addSound(new BloodHitSound3, "bloodHit3", 0.7);
			SoundManager.addSound(new BloodHitSound4, "bloodHit4", 0.7);
			SoundManager.addSound(new BoneHitSound1, "boneHit1", 0.8);
			SoundManager.addSound(new BoneHitSound2, "boneHit2", 0.8);
			SoundManager.addSound(new BoneHitSound3, "boneHit3", 0.8);
			SoundManager.addSound(new BoneHitSound4, "boneHit4", 0.8);
			SoundManager.addSound(new ChaosWallMovingSound, "chaosWallMoving", 0.5);
			SoundManager.addSound(new ChaosWallReadySound, "chaosWallReady", 0.5);
			SoundManager.addSound(new ChaosWallStopSound, "chaosWallStop", 0.5);
			SoundManager.addSound(new CogDeathSound1, "cogDeath1", 0.3);
			SoundManager.addSound(new CogDeathSound2, "cogDeath2", 0.3);
			SoundManager.addSound(new CogDeathSound3, "cogDeath3", 0.3);
			SoundManager.addSound(new CogDeathSound4, "cogDeath4", 0.3);
			SoundManager.addSound(new FloorStepSound1, "floorStep1", 0.15);
			SoundManager.addSound(new FloorStepSound2, "floorStep2", 0.15);
			SoundManager.addSound(new LadderStepSound1, "ladderStep1", 0.15);
			SoundManager.addSound(new LadderStepSound2, "ladderStep2", 0.15);
			SoundManager.addSound(new HealStoneHitSound1, "healStoneHit1", 0.8);
			SoundManager.addSound(new HealStoneHitSound2, "healStoneHit2", 0.8);
			SoundManager.addSound(new HealStoneHitSound3, "healStoneHit3", 0.8);
			SoundManager.addSound(new HealStoneHitSound4, "healStoneHit4", 0.8);
			SoundManager.addSound(new PickUpSound, "pickUp", 0.3);
			SoundManager.addSound(new PortalCloseSound, "portalClose", 0.8);
			SoundManager.addSound(new PortalOpenSound, "portalOpen", 0.8);
			SoundManager.addSound(new QuickeningSound1, "quickening1", 0.8);
			SoundManager.addSound(new QuickeningSound2, "quickening2", 0.8);
			SoundManager.addSound(new QuickeningSound3, "quickening3", 0.6);
			SoundManager.addSound(new RatDeathSound1, "ratDeath1", 0.2);
			SoundManager.addSound(new RatDeathSound2, "ratDeath2", 0.2);
			SoundManager.addSound(new RatDeathSound3, "ratDeath3", 0.2);
			SoundManager.addSound(new RatDeathSound4, "ratDeath4", 0.2);
			SoundManager.addSound(new SpiderDeathSound1, "spiderDeath1", 0.2);
			SoundManager.addSound(new SpiderDeathSound2, "spiderDeath2", 0.2);
			SoundManager.addSound(new SpiderDeathSound3, "spiderDeath3", 0.2);
			SoundManager.addSound(new SpiderDeathSound4, "spiderDeath4", 0.2);
			SoundManager.addSound(new StoneDeathSound1, "stoneDeath1", 0.7);
			SoundManager.addSound(new StoneDeathSound2, "stoneDeath2", 0.7);
			SoundManager.addSound(new StoneDeathSound3, "stoneDeath3", 0.7);
			SoundManager.addSound(new StoneDeathSound4, "stoneDeath4", 0.7);
			SoundManager.addSound(new StoneHitSound1, "stoneHit1", 0.7);
			SoundManager.addSound(new StoneHitSound2, "stoneHit2", 0.7);
			SoundManager.addSound(new StoneHitSound3, "stoneHit3", 0.7);
			SoundManager.addSound(new StoneHitSound4, "stoneHit4", 0.7);
			SoundManager.addSound(new StarSound1, "star1", 0.05);
			SoundManager.addSound(new StarSound2, "star2", 0.05);
			SoundManager.addSound(new StarSound3, "star3", 0.05);
			SoundManager.addSound(new StarSound4, "star4", 0.05);
			
			// voices
			SoundManager.addSound(new BansheeSound01, "Balrog1", 0.4);
			SoundManager.addSound(new BansheeSound02, "Balrog2", 0.4);
			SoundManager.addSound(new BansheeSound03, "Balrog3", 0.4);
			SoundManager.addSound(new BansheeSound01, "Banshee1", 0.4);
			SoundManager.addSound(new BansheeSound02, "Banshee2", 0.4);
			SoundManager.addSound(new BansheeSound03, "Banshee3", 0.4);
			SoundManager.addSound(new CactuarSound01, "Cactuar1", 1.5);
			SoundManager.addSound(new CactuarSound02, "Cactuar2", 1.5);
			SoundManager.addSound(new CactuarSound03, "Cactuar3", 1.5);
			SoundManager.addSound(new DrowSound01, "Drow1", 0.4);
			SoundManager.addSound(new DrowSound02, "Drow2", 0.4);
			SoundManager.addSound(new DrowSound03, "Drow3", 0.4);
			SoundManager.addSound(new DrowSound04, "Drow4", 0.4);
			SoundManager.addSound(new GnollSound01, "Gnoll1", 0.4);
			SoundManager.addSound(new GnollSound02, "Gnoll2", 0.4);
			SoundManager.addSound(new GnollSound03, "Gnoll3", 0.4);
			SoundManager.addSound(new GoblinSound01, "Goblin1", 0.4);
			SoundManager.addSound(new GoblinSound02, "Goblin2", 0.4);
			SoundManager.addSound(new GoblinSound03, "Goblin3", 0.4);
			SoundManager.addSound(new GolemSound01, "Golem1", 0.4);
			SoundManager.addSound(new GolemSound02, "Golem2", 0.4);
			SoundManager.addSound(new GolemSound03, "Golem3", 0.4);
			SoundManager.addSound(new KoboldSound01, "Kobold1", 0.4);
			SoundManager.addSound(new KoboldSound02, "Kobold2", 0.4);
			SoundManager.addSound(new KoboldSound03, "Kobold3", 0.4);
			SoundManager.addSound(new GorgonSound01, "Gorgon1", 0.4);
			SoundManager.addSound(new GorgonSound02, "Gorgon2", 0.4);
			SoundManager.addSound(new GorgonSound03, "Gorgon3", 0.4);
			SoundManager.addSound(new MindflayerSound01, "Mindflayer1", 0.4);
			SoundManager.addSound(new MindflayerSound02, "Mindflayer2", 0.4);
			SoundManager.addSound(new MindflayerSound03, "Mindflayer3", 0.4);
			SoundManager.addSound(new NagaSound01, "Naga1", 0.4);
			SoundManager.addSound(new NagaSound02, "Naga2", 0.4);
			SoundManager.addSound(new NagaSound03, "Naga3", 0.4);
			SoundManager.addSound(new NymphSound01, "Nymph1", 0.2);
			SoundManager.addSound(new NymphSound02, "Nymph2", 0.2);
			SoundManager.addSound(new NymphSound03, "Nymph3", 0.2);
			SoundManager.addSound(new OrcSound01, "Orc1", 0.4);
			SoundManager.addSound(new OrcSound02, "Orc2", 0.4);
			SoundManager.addSound(new OrcSound03, "Orc3", 0.4);
			SoundManager.addSound(new RakshasaSound01, "Rakshasa1", 0.4);
			SoundManager.addSound(new RakshasaSound02, "Rakshasa2", 0.4);
			SoundManager.addSound(new RakshasaSound03, "Rakshasa3", 0.4);
			SoundManager.addSound(new TrollSound01, "Troll1", 0.4);
			SoundManager.addSound(new TrollSound02, "Troll2", 0.4);
			SoundManager.addSound(new TrollSound03, "Troll3", 0.4);
			SoundManager.addSound(new UmberHulkSound01, "UmberHulk1", 0.4);
			SoundManager.addSound(new UmberHulkSound02, "UmberHulk2", 0.4);
			SoundManager.addSound(new UmberHulkSound03, "UmberHulk3", 0.4);
			SoundManager.addSound(new UmberHulkSound04, "UmberHulk4", 0.4);
			SoundManager.addSound(new VampireSound01, "Vampire1", 0.4);
			SoundManager.addSound(new VampireSound02, "Vampire2", 0.4);
			SoundManager.addSound(new VampireSound03, "Vampire3", 0.4);
			SoundManager.addSound(new WerewolfSound01, "Werewolf1", 0.4);
			SoundManager.addSound(new WerewolfSound02, "Werewolf2", 0.4);
			SoundManager.addSound(new WerewolfSound03, "Werewolf3", 0.4);
			SoundManager.addSound(new WraithSound01, "Wraith1", 0.4);
			SoundManager.addSound(new WraithSound02, "Wraith2", 0.4);
			SoundManager.addSound(new WraithSound03, "Wraith3", 0.4);
			
			// music
			SoundManager.addSound(new IntroMusicSound, "introMusic", 1.0);
			SoundManager.addSound(new DungeonsMusicSound, "dungeonsMusic", 1.0);
			SoundManager.addSound(new SewersMusicSound, "sewersMusic", 1.0);
			SoundManager.addSound(new CavesMusicSound, "cavesMusic", 0.7);
			SoundManager.addSound(new ChaosMusicSound, "chaosMusic", 1.0);
			SoundManager.addSound(new OverworldMusicSound, "overworldMusic", 0.4);
			SoundManager.addSound(new UnderworldMusicSound1, "underworldMusic1", 1.0);
			SoundManager.addSound(new UnderworldMusicSound2, "underworldMusic2", 1.0);
			soundQueue = new SoundQueue();
			
			dogmaticMode = false;
			
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		/* The initialisation is quite long, so I'm breaking it up with some comment lines */
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			Map.random = new XorRandom(Map.seed);
			
			// KEYS INIT
			if(!Key.initialized){
				Key.init(stage);
				Key.custom = [Key.W, Key.S, Key.A, Key.D, Keyboard.SPACE, Key.E, Key.F, Key.Z, Key.X, Key.C, Key.NUMBER_1, Key.NUMBER_2, Key.NUMBER_3, Key.NUMBER_4, Key.NUMBER_5];
				Key.hotKeyTotal = 10;
			}
			
			// GRAPHICS INIT
			
			scaleX = scaleY = 2;
			stage.quality = StageQuality.LOW;
			
			renderer.createRenderLayers(this);
			
			addChild(editor.bitmap);
			
			// UI INIT
			
			if(!console){
				console = new Console();
				console.y = HEIGHT - Console.HEIGHT;
			}
			addChild(console);
			
			miniMapHolder = new Sprite();
			addChild(miniMapHolder);
			
			playerHealthBar = new ProgressBar(5, console.y - 13, MiniMap.WIDTH, 8, HEALTH_GLOW_RATIO, 0xAA0000);
			playerHealthBar.barCol = 0xFFCCCCCC;
			addChild(playerHealthBar);
			var hpBitmap:Bitmap = new library.HPB;
			hpBitmap.x = playerHealthBar.width + 1;
			hpBitmap.y = 1;
			playerHealthBar.addChild(hpBitmap);
			playerHealthBar.update();
			
			playerXpBar = new ProgressBar(5, playerHealthBar.y - 7, MiniMap.WIDTH, 6);
			playerXpBar.barCol = 0xFFCCCCCC;
			addChild(playerXpBar);
			levelNumGfx = new LevelNumMC();
			levelNumGfx.stop();
			levelNumGfx.x = playerXpBar.width + 1;
			playerXpBar.addChild(levelNumGfx);
			playerXpBar.update();
			
			minionHealthBar = new ProgressBar(5, playerXpBar.y - 7, MiniMap.WIDTH, 6, HEALTH_GLOW_RATIO, 0xAA0000);
			minionHealthBar.barCol = 0xFFCCCCCC;
			addChild(minionHealthBar);
			var mhpBitmap:Bitmap = new library.MHPB;
			mhpBitmap.x = minionHealthBar.width + 1;
			mhpBitmap.y = 1;
			minionHealthBar.addChild(mhpBitmap);
			minionHealthBar.visible = false;
			minionHealthBar.update();
			
			enemyHealthBar = new ProgressBar(WIDTH - 59, console.y - 13, 54, 8, HEALTH_GLOW_RATIO, 0xAA0000);
			enemyHealthBar.barCol = 0xFFCCCCCC;
			addChild(enemyHealthBar);
			enemyHealthBar.active = false;
			enemyHealthBar.alpha = 0;
			
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
				var clickToPlayText:TextBox = new TextBox(100, 12, 0x00000000, 0x00000000, 0xFFAA0000);
				clickToPlayText.align = "center";
				clickToPlayText.text = "click to play";
				clickToPlayText.bitmapData.colorTransform(clickToPlayText.bitmapData.rect, new ColorTransform(1, 0, 0, 1, -85));
				focusPrompt.addChild(clickToPlayText);
				clickToPlayText.x = (WIDTH * 0.5) - 50;
				clickToPlayText.y = (HEIGHT * 0.5) + 10;
				var buildText:TextBox = new TextBox(100, 12, 0x00000000, 0x00000000, 0xFFAA0000);
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
			
			konamiCode = false;
			colossalCaveCode = false;
			frameCount = 1;
			deepestLevelReached = 1;
			
			// LISTS
			
			entities = new Vector.<Entity>();
			items = [];
			effects = new Vector.<Effect>();
			portals = new Vector.<Portal>();
			chaosWalls = new Vector.<ChaosWall>();
			portalHash = {};
			
			Item.runeNames = [];
			for(i = 0; i < Item.stats["rune names"].length; i++){
				Item.runeNames.push("?");
			}
			// the identify rune's name is already known (obviously)
			Item.runeNames[Item.IDENTIFY] = Item.stats["rune names"][Item.IDENTIFY];
			
			// LEVEL SPECIFIC INIT
			// This stuff that follows requires the bones of a level to initialise
			
			Brain.initCharacterLists();
			Brain.voiceCount = Brain.VOICE_DELAY + random.range(Brain.VOICE_DELAY);
			
			content = new Content();
			
			// DEBUG HERE ==========================================================================================
			dungeon = new Map(1);
			Brain.initDungeonGraph(dungeon.bitmap);
			mapTileManager = new MapTileManager(this, renderer.canvas, SCALE, dungeon.width, dungeon.height, WIDTH, HEIGHT);
			mapTileManager.setLayers(dungeon.layers);
			renderer.blockBitmapData = mapTileManager.layerToBitmapData(MapTileManager.BACKGROUND_LAYER);
			renderer.blockBitmapData = mapTileManager.layerToBitmapData(MapTileManager.BLOCK_LAYER, renderer.blockBitmapData);
			world = new CollisionWorld(dungeon.width, dungeon.height, SCALE);
			world.map = createPropertyMap(mapTileManager.mapLayers[MapTileManager.BLOCK_LAYER]);
			
			//world.debug = debug;
			
			renderer.sceneManager = SceneManager.getSceneManager(dungeon.level, dungeon.type);
			
			lightMap = new LightMap(world.map);
			
			mapTileManager.init(dungeon.start.x, dungeon.start.y);
			
			//renderer.lightBitmap.visible = false;
			
			// modify the mapRect to conceal secrets
			mapTileManager.mapRect = renderer.camera.mapRect = dungeon.bitmap.adjustedMapRect;
			miniMap = new MiniMap(world.map, this, renderer);
			miniMap.y = miniMap.x = 5;
			miniMapHolder.addChild(miniMap);
			initPlayer();
			// fire up listeners
			addListeners();
			// this is a hack to force clicking on the game when the browser first pulls in the swf
			if(forceFocus){
				onFocusLost();
				forceFocus = false;
			} else {
				changeMusic();
			}
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
			dungeon = null;
			world = null;
			Player.previousLevel = Map.OVERWORLD;
			Player.previousPortalType = Portal.STAIRS;
			Player.previousMapType = Map.AREA;
			SoundManager.musicTimes = {};
			
			init();
		}
		
		/* Used to change to a new level in the dungeon
		 *
		 * This method tries to wipe all layers whilst leaving the gaming architecture in place
		 */
		public function changeLevel(n:int, portalType:int, loaded:Boolean = false):void{
			
			// maintain debug state if present
			if(dungeon.level == -1){
				n = -1;
				loaded = true;
			}
			
			if(!loaded){
				// left over content needs to be pulled back into the content manager to be found
				// if the level is visited again
				content.recycleLevel(dungeon.type);
				QuickSave.save(this, true);
			}
			
			// elements to update:
			
			// game_objects list needs to be emptied
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
			portalHash = {};
			
			Brain.monsterCharacters = new Vector.<Character>();
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
			
			dungeon = new Map(n, mapType);
			
			Brain.initDungeonGraph(dungeon.bitmap);
			
			mapTileManager.newMap(dungeon.width, dungeon.height, dungeon.layers);
			renderer.blockBitmapData = mapTileManager.layerToBitmapData(MapTileManager.BACKGROUND_LAYER);
			if(dungeon.type != Map.AREA) renderer.blockBitmapData = mapTileManager.layerToBitmapData(MapTileManager.BLOCK_LAYER, renderer.blockBitmapData);
			
			// modify the mapRect to conceal secrets
			mapTileManager.mapRect = dungeon.bitmap.adjustedMapRect;
			renderer.camera.mapRect = dungeon.bitmap.adjustedMapRect;
			
			world = new CollisionWorld(dungeon.width, dungeon.height, SCALE);
			world.map = createPropertyMap(mapTileManager.mapLayers[MapTileManager.BLOCK_LAYER]);
			
			renderer.sceneManager = SceneManager.getSceneManager(dungeon.level, dungeon.type);
			
			lightMap.newMap(world.map);
			lightMap.setLight(player, player.light);
			
			mapTileManager.init(dungeon.start.x, dungeon.start.y);
			
			miniMap.newMap(world.map);
			
			player.collider.x = -player.collider.width * 0.5 + (dungeon.start.x + 0.5) * SCALE;
			player.collider.y = -player.collider.height + (dungeon.start.y + 1) * SCALE;
			player.mapX = (player.collider.x + player.collider.width * 0.5) * INV_SCALE;
			player.mapY = (player.collider.y + player.collider.height * 0.5) * INV_SCALE;
			player.snapCamera();
			
			if(minion){
				minion.collider.x = -minion.collider.width * 0.5 + (dungeon.start.x + 0.5) * SCALE;
				minion.collider.y = -minion.collider.height + (dungeon.start.y + 1) * SCALE;
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
				if(dungeon.level == Map.OVERWORLD){
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
					
				} else if(dungeon.level == Map.UNDERWORLD){
					if(player.undead) player.applyHealth(player.totalHealth);
					if(minion && minion.undead) minion.applyHealth(minion.totalHealth);
				}
				
			} else if(dungeon.level == -1){
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
			
			player.enterLevel(entrance, Player.previousLevel < game.dungeon.level ? Collider.RIGHT : Collider.LEFT);
			changeMusic();
		}
		
		private function initPlayer():void{
			var playerMc:MovieClip = new RogueMC();
			var minionMc:MovieClip = new SkeletonMC();
			var startX:Number = (dungeon.start.x + 0.5) * SCALE;
			var startY:Number = (dungeon.start.y + 1) * SCALE;
			player = new Player(playerMc, startX, startY);
			minion = new Minion(minionMc, startX, startY, Character.SKELETON);
			minion.prepareToEnter(entrance);
			player.enterLevel(entrance);
			player.snapCamera();
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
			
			//var mouseMapX:int = INV_SCALE * canvas.mouseX;
			//var mouseMapY:int = INV_SCALE * canvas.mouseY;
			//if(Brain.dungeonGraph.nodes[mouseMapY][mouseMapX] && Brain.dungeonGraph.nodes[player.mapY][player.mapX]){
				//var path:Vector.<Node> = Brain.dungeonGraph.getPath(Brain.dungeonGraph.nodes[player.mapY][player.mapX], Brain.dungeonGraph.nodes[mouseMapY][mouseMapX], 100);
				//if(path){
					//if(path.length == 0) trace(game.frameCount);
					//Brain.dungeonGraph.drawPath(path, debug, SCALE);
				//}
			//}
			//Brain.dungeonGraph.drawGraph(debug, SCALE);
			
			if(state == GAME) {
				
				var advance:Boolean = true;
				if(dogmaticMode){
					if(player.searchRadius == -1 && player.state == Character.WALKING && Key.keysPressed == 0) advance = false;
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
					
					frameCount++;
					if(Brain.voiceCount) Brain.voiceCount--;
					ProgressBar.glowCount = frameCount % ProgressBar.glowTable.length;
					
					// examine the key buffer for cheat codes
					if(!konamiCode && Key.matchLog(Key.KONAMI_CODE)){
						konamiCode = true;
						console.print("konami");
					}
					if(!colossalCaveCode && Key.matchLog(Key.COLOSSAL_CAVE_CODE)){
						colossalCaveCode = true;
						console.print("xyzzy");
					}
					
					var mx:int = renderer.canvas.mouseX * INV_SCALE;
					var my:int = renderer.canvas.mouseY * INV_SCALE;
					
					//if(mx >= 0 && my >= 0 && mx < Brain.dungeonGraph.width && my < Brain.dungeonGraph.height){
					//var path:Vector.<Node> = Brain.dungeonGraph.getEscapePath(Brain.dungeonGraph.nodes[my][mx], Brain.dungeonGraph.nodes[player.mapY][player.mapX], 50);
					//if(path) Brain.dungeonGraph.drawPath(path, debug, SCALE);
					//}
				
				}
				
			}
			
			menu.main();
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
				}
			}
			return idMap;
		}
		
		/* Switches to the appropriate music */
		public function changeMusic():void{
			var start:int;
			var name:String;
			if(SoundManager.soundLoops["underworldMusic2"]) SoundManager.fadeLoopSound("underworldMusic2", -SoundManager.DEFAULT_FADE_STEP)
			if(state == UNFOCUSED){
				if(!SoundManager.currentMusic || SoundManager.currentMusic != "introMusic"){
					SoundManager.fadeMusic("introMusic");
				}
			} else {
				if(dungeon.type == Map.AREA){
					if(dungeon.level == Map.OVERWORLD) name = "overworldMusic";
					else if(dungeon.level == Map.UNDERWORLD) name = "underworldMusic1";
					if(!SoundManager.currentMusic || SoundManager.currentMusic != name){
						if(dungeon.level == Map.OVERWORLD){
							start = int(SoundManager.musicTimes[name]);
						} else if(dungeon.level == Map.UNDERWORLD){
							start = (SoundManager.sounds["underworldMusic1"] as Sound).length * 0.5;
							if(SoundManager.music && !SoundManager.soundLoops["underworldMusic2"]) SoundManager.fadeLoopSound("underworldMusic2");
						}
						SoundManager.fadeMusic(name, SoundManager.DEFAULT_FADE_STEP, start);
					}
				} else {
					name = Map.ZONE_NAMES[dungeon.zone] + "Music";
					if(!SoundManager.currentMusic || SoundManager.currentMusic != name){
						start = int(SoundManager.musicTimes[name]);
						SoundManager.fadeMusic(name, SoundManager.DEFAULT_FADE_STEP, start);
					}
				}
			}
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
			/*if(Key.isDown(Key.T)){
				throw new Error("");
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