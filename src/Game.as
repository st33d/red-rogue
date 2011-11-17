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
	import com.robotacid.engine.MapRenderer;
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
	import com.robotacid.ui.menu.GameMenu;
	import com.robotacid.ui.ProgressBar;
	import com.robotacid.ui.QuickSave;
	import com.robotacid.ui.TextBox;
	import com.robotacid.ui.MiniMap;
	import com.robotacid.ui.Key;
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
	 * @author Aaron Steed, robotacid.com
	 */
	
	[SWF(width = "640", height = "480", frameRate="30", backgroundColor = "#000000")]
	
	public class Game extends Sprite {
		
		public static const BUILD_NUM:int = 243;
		
		public static var g:Game;
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
		
		// graphics
		public var mapRenderer:MapRenderer;
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
		public var mouseCount:int;
		public var mousePressed:Boolean;
		public var god_mode:Boolean;
		public var paused:Boolean;
		public var shakeDirX:int;
		public var shakeDirY:int;
		public var deepestLevelReached:int;
		public var konamiCode:Boolean = false;
		public var colossalCaveCode:Boolean = false;
		public var forceFocus:Boolean = true;
		public var portalHash:Object;
		
		// temp variables
		private var i:int;
		
		public static var point:Point = new Point();
		
		// CONSTANTS
		
		public static const SCALE:Number = 16;
		public static const INV_SCALE:Number = 1.0 / 16;
		
		public static const GAME:int = 0;
		public static const MENU:int = 1;
		public static const TITLE:int = 2;
		public static const UNFOCUSED:int = 3;
		
		public static const WIDTH:Number = 320;
		public static const HEIGHT:Number = 240;
		public static const CONSOLE_HEIGHT:Number = 35
		// game key properties
		public static const UP_KEY:int = 0;
		public static const DOWN_KEY:int = 1;
		public static const LEFT_KEY:int = 2;
		public static const RIGHT_KEY:int = 3;
		public static const MENU_KEY:int = 4;
		
		public static const MAX_LEVEL:int = 20;
		
		public function Game():void {
			
			library = new Library;
			
			renderer = new Renderer(this);
			renderer.init();
			
			g = this;
			Entity.g = this;
			LightMap.g = this;
			Effect.g = this;
			FX.g = this;
			Content.g = this;
			Brain.g = this;
			DungeonBitmap.g = this;
			Lightning.g = this;
			ItemMovieClip.g = this;
			
			Effect.BANNED_RANDOM_ENCHANTMENTS[Effect.PORTAL] = true;
			
			TextBox.init();
			MapTileConverter.init();
			
			random = new XorRandom();
			
			lightning = new Lightning();
			
			var statsByteArray:ByteArray;
			
			statsByteArray = new Character.statsData();
			Character.stats = JSON.decode(statsByteArray.readUTFBytes(statsByteArray.length));
			
			statsByteArray = new Item.statsData();
			Item.stats = JSON.decode(statsByteArray.readUTFBytes(statsByteArray.length));
			
			FPS.start();
			
			// SOUND INIT
			SoundManager.init();
			SoundManager.addSound(new JumpSound, "jump", 0.6);
			SoundManager.addSound(new StepsSound, "step", 0.4);
			SoundManager.addSound(new RogueDeathSound, "rogueDeath", 1.0);
			SoundManager.addSound(new MissSound, "miss", 0.8);
			SoundManager.addSound(new KillSound, "kill", 0.8);
			SoundManager.addSound(new ThudSound, "thud", 0.5);
			SoundManager.addSound(new BowShootSound, "bowShoot", 0.8);
			SoundManager.addSound(new ThrowSound, "throw", 0.8);
			SoundManager.addSound(new ChestOpenSound, "chestOpen", 0.6);
			SoundManager.addSound(new RuneHitSound, "runeHit", 0.8);
			SoundManager.addSound(new TeleportSound, "teleport", 0.8);
			SoundManager.addSound(new HitSound, "hit", 0.6);
			SoundManager.addSound(new MusicSound1, "music1", 1.0);
			soundQueue = new SoundQueue();
			
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		/* The initialisation is quite long, so I'm breaking it up with some comment lines */
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
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
			
			// UI INIT
			
			console = new Console(WIDTH, CONSOLE_HEIGHT, 3);
			console.y = HEIGHT - CONSOLE_HEIGHT;
			addChild(console);
			//Effect.hideNames();
			
			miniMapHolder = new Sprite();
			addChild(miniMapHolder);
			
			if(!menu){
				menu = new GameMenu(WIDTH, console.y, this);
			}
			menuHolder = new Sprite();
			addChild(menuHolder);
			menu.holder = menuHolder;
			if(state == MENU){
				menuHolder.addChild(menu);
			}
			
			playerHealthBar = new ProgressBar(5, console.y - 13, MiniMap.WIDTH, 8);
			playerHealthBar.barCol = 0xCCCCCC;
			addChild(playerHealthBar);
			playerXpBar = new ProgressBar(5, playerHealthBar.y - 4, MiniMap.WIDTH, 3);
			playerXpBar.barCol = 0xCCCCCC;
			addChild(playerXpBar);
			
			minionHealthBar = new ProgressBar(5, playerXpBar.y - 5, playerHealthBar.width * 0.5, 4);
			minionHealthBar.barCol = 0xCCCCCC;
			addChild(minionHealthBar);
			minionHealthBar.visible = false;
			
			enemyHealthBar = new ProgressBar(WIDTH - 59, console.y - 13, 54, 8);
			enemyHealthBar.barCol = 0xCCCCCC;
			addChild(enemyHealthBar);
			enemyHealthBar.active = false;
			enemyHealthBar.alpha = 0;
			
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
			portalHash = {};
			frameCount = 1;
			deepestLevelReached = 1;
			
			// LISTS
			
			entities = new Vector.<Entity>();
			items = [];
			effects = new Vector.<Effect>();
			portals = new Vector.<Portal>();
			chaosWalls = new Vector.<ChaosWall>();
			
			Item.runeNames = [];
			for(i = 0; i < Item.stats["rune names"].length; i++){
				Item.runeNames.push("?");
			}
			
			// LEVEL SPECIFIC INIT
			// This stuff that follows requires the bones of a level to initialise
			
			Brain.initCharacterLists();
			content = new Content();
			
			// DEBUG HERE ==========================================================================================
			
			dungeon = new Map(1, this, renderer);
			Brain.initDungeonGraph(dungeon.bitmap);
			mapRenderer = new MapRenderer(this, renderer.canvas, SCALE, dungeon.width, dungeon.height, WIDTH, HEIGHT);
			mapRenderer.setLayers(dungeon.layers, [renderer.bitmapData, renderer.bitmapData, null, null], [renderer.bitmap, renderer.bitmap, null, null]);
			renderer.blockBitmapData = mapRenderer.layerToBitmapData(MapRenderer.BLOCK_LAYER);
			world = new CollisionWorld(dungeon.width, dungeon.height, SCALE);
			world.map = createPropertyMap(mapRenderer.mapArrayLayers[MapRenderer.BLOCK_LAYER]);
			
			//world.debug = debug;
			
			lightMap = new LightMap(world.map);
			mapRenderer.init(dungeon.start.x, dungeon.start.y);
			
			//renderer.lightBitmap.visible = false;
			
			// modify the mapRect to conceal secrets
			mapRenderer.mapRect = renderer.camera.mapRect = dungeon.bitmap.adjustedMapRect;
			miniMap = new MiniMap(world.map, this);
			miniMap.y = miniMap.x = 5;
			miniMapHolder.addChild(miniMap);
			initPlayer();
			// fire up listeners
			addListeners();
			// this is a hack to force clicking on the game when the browser first pulls in the swf
			if(forceFocus){
				onFocusLost();
				forceFocus = false;
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
			mapRenderer = null;
			dungeon = null;
			world = null;
			Player.previousLevel = 0;
			
			init();
		}
		
		/* Used to change to a new level in the dungeon
		 *
		 * This method tries to wipe all layers whilst leaving the gaming architecture in place
		 */
		public function changeLevel(n:int, loaded:Boolean = false):void{
			
			// maintain debug state if present
			if(dungeon.level == -1){
				n = -1;
				loaded = true;
			}
			
			if(!loaded){
				// left over content needs to be pulled back into the content manager to be found
				// if the level is visited again
				content.recycleLevel();
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
			
			dungeon = new Map(n, this, renderer);
			
			Brain.initDungeonGraph(dungeon.bitmap);
			
			mapRenderer.newMap(dungeon.width, dungeon.height, dungeon.layers);
			if(dungeon.level > 0) renderer.blockBitmapData = mapRenderer.layerToBitmapData(MapRenderer.BLOCK_LAYER);
			else renderer.blockBitmapData = new BitmapData(dungeon.width * SCALE, dungeon.height * SCALE, true, 0x00000000);
			
			// modify the mapRect to conceal secrets
			mapRenderer.mapRect = dungeon.bitmap.adjustedMapRect;
			renderer.camera.mapRect = dungeon.bitmap.adjustedMapRect;
			
			world = new CollisionWorld(dungeon.width, dungeon.height, SCALE);
			world.map = createPropertyMap(mapRenderer.mapArrayLayers[MapRenderer.BLOCK_LAYER]);
			lightMap.newMap(world.map);
			lightMap.setLight(player, player.light);
			
			mapRenderer.init(dungeon.start.x, dungeon.start.y);
			
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
			
			var skinMc:MovieClip;
			// the overworld behaves differently to the rest of the game
			if(dungeon.level == 0){
				renderer.lightBitmap.visible = false;
				miniMap.visible = false;
				// change the rogue to a colour version and revert the minion if changed
				skinMc = new RogueColMC();
				if(player.name != Character.ROGUE){
					console.print("rogue reverts to human form");
				}
				player.changeName(Character.ROGUE, new RogueColMC());
				if(minion && minion.name != Character.SKELETON){
					skinMc = g.library.getCharacterGfx(Character.SKELETON);
					minion.changeName(Character.SKELETON, skinMc);
					console.print("minion reverts to undead form");
				}
				mapRenderer.setLayerUpdate(MapRenderer.BLOCK_LAYER, false);
				SoundManager.fadeMusic("music1", -SoundManager.DEFAULT_FADE_STEP);
				
			} else if(dungeon.level == -1){
				renderer.lightBitmap.visible = false;
				
			} else {
				if(dungeon.level == 1){
					// change to black and white rogue
					player.changeName(Character.ROGUE, new RogueMC);
					if(!SoundManager.currentMusic) SoundManager.fadeMusic("music1");
				}
				renderer.lightBitmap.visible = true;
				miniMap.visible = true;
			}
			
			player.enterLevel(entrance, Player.previousLevel < g.dungeon.level ? Collider.RIGHT : Collider.LEFT);
		}
		
		private function initPlayer():void{
			var playerMc:MovieClip = new RogueMC();
			var minionMc:MovieClip = new MinionMC();
			var startX:Number = (dungeon.start.x + 0.5) * SCALE;
			var startY:Number = (dungeon.start.y + 1) * SCALE;
			player = new Player(playerMc, startX, startY);
			minion = new Minion(minionMc, startX, startY, Character.SKELETON);
			minion.prepareToEnter(entrance);
			player.enterLevel(entrance);
			player.snapCamera();
			SoundManager.playMusic("music1");
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
			//info.text = g.player.mapX + " " + g.player.mapY;
			//info.appendText("pixels" + (getTimer() - t) + "\n"); t = getTimer();
			
			//var mouseMapX:int = INV_SCALE * canvas.mouseX;
			//var mouseMapY:int = INV_SCALE * canvas.mouseY;
			//if(Brain.dungeonGraph.nodes[mouseMapY][mouseMapX] && Brain.dungeonGraph.nodes[player.mapY][player.mapX]){
				//var path:Vector.<Node> = Brain.dungeonGraph.getPath(Brain.dungeonGraph.nodes[player.mapY][player.mapX], Brain.dungeonGraph.nodes[mouseMapY][mouseMapX], 100);
				//if(path){
					//if(path.length == 0) trace(g.frameCount);
					//Brain.dungeonGraph.drawPath(path, debug, SCALE);
				//}
			//}
			//Brain.dungeonGraph.drawGraph(debug, SCALE);
			
			if(state == GAME) {
				
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
				
				if(player.active) player.main();
				
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
				
				frameCount++;
				
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
		
		/* Pause the game and make the inventory screen visible */
		public function pauseGame():void{
			if(state == GAME){
				state = MENU;
				menu.holder.addChild(menu);
			} else if(state == MENU){
				state = GAME;
				if(menu.parent) menu.parent.removeChild(menu);
			}
		}
		
		/* Sets all traps and secrets to their revealed status */
		public function revealTrapsAndSecrets():void{
			var n:int = 0;
			for(var i:int = 0; i < entities.length; i++){
				if(entities[i] is Trap && !(entities[i] as Trap).revealed){
					(entities[i] as Trap).reveal();
					n++;
				}
				if(entities[i] is Stone && (entities[i] as Stone).name == Stone.SECRET_WALL && !(entities[i] as Stone).revealed){
					(entities[i] as Stone).reveal();
					n++;
				}
			}
			if(n == 0){
				console.print("found nothing");
			} else {
				console.print(n + " discover" + (n > 1 ? "ies" : "y"));
			}
		}
		
		/*
		 * Creates a map of ints that represents properties of static blocks
		 * Any block to interact with is generated on the fly using this 2D array to determine its
		 * properties. 'id's of blocks are inferred by the tile numbers
		 */
		private function createPropertyMap(map:Array):Vector.<Vector.<int>>{
			var idMap:Vector.<Vector.<int>> = new Vector.<Vector.<int>>(mapRenderer.height, true), r:int, c:int;
			for(r = 0; r < mapRenderer.height; r++){
				idMap[r] = new Vector.<int>(mapRenderer.width, true);
				for(c = 0; c < mapRenderer.width; c++){
					idMap[r][c] = MapTileConverter.getMapProperties(map[r][c]);
				}
			}
			return idMap;
		}
		
		private function mouseDown(e:MouseEvent):void{
			mousePressed = true;
			mouseCount = frameCount;
		}
		
		private function mouseUp(e:MouseEvent):void{
			mousePressed = false;
		}
		
		private function keyPressed(e:KeyboardEvent):void{
			if(Key.lockOut) return;
			if(Key.customDown(MENU_KEY)){
				pauseGame();
			}
			/*if(Key.isDown(Key.R)){
				reset();
			}
			if(Key.isDown(Key.T)){
				console.print("test\n"+(testCounter++));
			}*/
			if(Key.isDown(Key.P)){
				//minion.death("key");
				player.levelUp();
			}
		}
		
		/* When the flash object loses focus we put up a splash screen to encourage players to click to play */
		private function onFocusLost(e:Event = null):void{
			if(state == UNFOCUSED) return;
			previousState = state;
			state = UNFOCUSED;
			Key.forceClearKeys();
			addChild(focusPrompt);
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
		}
	}
	
}