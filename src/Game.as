package
{
	import com.robotacid.ai.Brain;
	import com.robotacid.ai.Node;
	import com.robotacid.dungeon.Content;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Minion;
	import com.robotacid.engine.Stairs;
	import com.robotacid.engine.Entity;
	import com.robotacid.engine.MapRenderer;
	import com.robotacid.engine.Player;
	import com.robotacid.engine.MapTileConverter;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.Stone;
	import com.robotacid.engine.Trap;
	import com.robotacid.geom.Dot;
	import com.robotacid.geom.Pixel;
	import com.robotacid.geom.Rect;
	import com.robotacid.geom.Trig;
	import com.robotacid.gfx.*;
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Collider;
	import com.robotacid.ui.Console;
	import com.robotacid.ui.menu.GameMenu;
	import com.robotacid.ui.ProgressBar;
	import com.robotacid.ui.QuickSave;
	import com.robotacid.ui.TextBox;
	import com.robotacid.ui.MiniMap;
	import com.robotacid.ui.Key;
	import com.robotacid.util.clips.stopClips;
	import com.robotacid.util.HiddenInt;
	import com.robotacid.util.misc.onScreen;
	import com.robotacid.util.LZW;
	import com.robotacid.util.RLE;
	import com.robotacid.dungeon.Map;
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
		
		public static var g:Game;
		public static var debug:Graphics;
		public static var debugStay:Graphics;
		
		// core engine objects
		public var player:Player;
		public var minion:Minion;
		public var library:Library;
		public var dungeon:Map;
		public var content:Content;
		public var entrance:Stairs;
		
		// graphics
		public var renderer:MapRenderer;
		public var camera:Camera;
		public var lightMap:LightMap;
		public var lightning:Lightning;
		
		// rendering surfaces
		public var shaker:Sprite;
		public var canvas:Sprite;
		public var tileImage:BitmapData;
		public var tileImageHolder:Bitmap;
		public var debrisMapHolder:Sprite;
		public var itemsHolder:Sprite;
		public var stairsHolder:Sprite;
		public var entitiesHolder:Sprite;
		public var playerHolder:Sprite;
		public var frontFxImage:BitmapData;
		public var frontFxImageHolder:Bitmap;
		public var backFxImage:BitmapData;
		public var backFxImageHolder:Bitmap;
		public var fxHolder:Sprite;
		public var foregroundHolder:Sprite;
		public var focusPrompt:Sprite;
		public var menuHolder:Sprite;
		public var miniMapHolder:Sprite;
		
		// blitting sprites
		public var sparkBr:BlitRect;
		public var twinkleBc:BlitClip;
		public var teleportSparkBigFadeFbr:FadingBlitRect;
		public var teleportSparkSmallFadeFbr:FadingBlitRect;
		
		public var smallDebrisBrs:Vector.<BlitRect>;
		public var bigDebrisBrs:Vector.<BlitRect>;
		public var smallFadeFbrs:Vector.<FadingBlitRect>;
		public var bigFadeFbrs:Vector.<FadingBlitRect>;
		
		// ui
		public var console:Console;
		public var menu:GameMenu;
		public var miniMap:MiniMap;
		public var playerHealthBar:ProgressBar;
		public var playerXpBar:ProgressBar;
		public var minionHealthBar:ProgressBar;
		public var enemyHealthBar:ProgressBar;
		
		public var info:TextField;
		
		// lists
		public var blockMap:Vector.<Vector.<int>>;
		public var entities:Vector.<Entity>;
		public var colliders:Vector.<Collider>;
		public var items:Array;
		public var effects:Vector.<Effect>;
		public var fx:Vector.<FX>;
		
		public var fxFilterCallBack:Function;
		
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
		public var konamiCode:Boolean = false;
		public var colossalCaveCode:Boolean = false;
		
		
		public var forceFocus:Boolean = true;
		
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
		
		public static const WIDTH:int = 320;
		public static const HEIGHT:int = 240;
		// game key properties
		public static const UP_KEY:int = 0;
		public static const DOWN_KEY:int = 1;
		public static const LEFT_KEY:int = 2;
		public static const RIGHT_KEY:int = 3;
		public static const MENU_KEY:int = 4;
		
		public static const MAX_LEVEL:int = 20;
		
		// debris types
		public static const BLOOD:int = 0;
		public static const BONE:int = 1;
		public static const STONE:int = 2;
		
		public function Game():void {
			g = this;
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		/* The initialisation is quite long, so I'm breaking it up with some comment lines */
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			library = new Library;
			
			// KEYS INIT
			Key.init(stage);
			Key.custom = [Key.W, Key.S, Key.A, Key.D, Keyboard.SPACE, Key.NUMBER_1, Key.NUMBER_2, Key.NUMBER_3, Key.NUMBER_4, Key.NUMBER_5, Key.NUMBER_6, Key.NUMBER_7, Key.NUMBER_8, Key.NUMBER_9, Key.NUMBER_0];
			Key.hotKeyTotal = 10;
			
			// GRAPHICS INIT
			TextBox.init();
			MapTileConverter.init();
			
			scaleX = scaleY = 2;
			stage.quality = StageQuality.LOW;
			shaker = new Sprite();
			addChild(shaker);
			canvas = new Sprite();
			shaker.addChild(canvas);
			tileImage = new BitmapData(WIDTH, HEIGHT, true, 0x00000000);
			tileImageHolder = new Bitmap(tileImage);
			itemsHolder = new Sprite();
			stairsHolder = new Sprite();
			entitiesHolder = new Sprite();
			backFxImage = new BitmapData(WIDTH, HEIGHT, true, 0x00000000);
			backFxImageHolder = new Bitmap(backFxImage);
			frontFxImage = new BitmapData(WIDTH, HEIGHT, true, 0x00000000);
			frontFxImageHolder = new Bitmap(frontFxImage);
			fxHolder = new Sprite();
			playerHolder = new Sprite();
			foregroundHolder = new Sprite();
			
			var debugShape:Shape = new Shape();
			var debugStayShape:Shape = new Shape();
			debug = debugShape.graphics;
			debugStay = debugStayShape.graphics;
			debugStay.lineStyle(1, 0xFF00FF);
			
			canvas.addChild(tileImageHolder);
			canvas.addChild(stairsHolder);
			canvas.addChild(itemsHolder);
			canvas.addChild(backFxImageHolder);
			canvas.addChild(entitiesHolder);
			canvas.addChild(playerHolder);
			canvas.addChild(frontFxImageHolder);
			canvas.addChild(fxHolder);
			canvas.addChild(foregroundHolder);
			canvas.addChild(debugShape);
			canvas.addChild(debugStayShape);
			
			// init debris particles
			smallDebrisBrs = new Vector.<BlitRect>();
			smallDebrisBrs.push(new BlitRect(0, 0, 1, 1, 0xffAA0000));
			smallDebrisBrs.push(new BlitRect(0, 0, 1, 1, 0xffffffff));
			smallDebrisBrs.push(new BlitRect(0, 0, 1, 1, 0xff000000));
			bigDebrisBrs = new Vector.<BlitRect>();
			bigDebrisBrs.push(new BlitRect(-1, -1, 2, 2, 0xffAA0000));
			bigDebrisBrs.push(new BlitRect(-1, -1, 2, 2, 0xFFFFFFFF));
			bigDebrisBrs.push(new BlitRect(-1, -1, 2, 2, 0xff000000));
			smallFadeFbrs = new Vector.<FadingBlitRect>();
			smallFadeFbrs.push(new FadingBlitRect(0, 0, 1, 1, 30, 0xffAA0000));
			smallFadeFbrs.push(new FadingBlitRect(0, 0, 1, 1, 30, 0xffffffff));
			smallFadeFbrs.push(new FadingBlitRect(0, 0, 1, 1, 30, 0xff000000));
			bigFadeFbrs = new Vector.<FadingBlitRect>();
			bigFadeFbrs.push(new FadingBlitRect( -1, -1, 2, 2, 30, 0xffAA0000));
			bigFadeFbrs.push(new FadingBlitRect( -1, -1, 2, 2, 30, 0xffffffff));
			bigFadeFbrs.push(new FadingBlitRect( -1, -1, 2, 2, 30, 0xff000000));
			
			sparkBr = smallDebrisBrs[BONE];
			teleportSparkSmallFadeFbr = smallFadeFbrs[BONE];
			teleportSparkBigFadeFbr = bigFadeFbrs[BONE];
			
			twinkleBc = new BlitClip(new library.TwinkleMC);
			twinkleBc.compress();
			
			lightning = new Lightning();
			
			// UI INIT
			
			console = new Console(320, 3);
			console.y = HEIGHT - (console.height);
			console.maxLines = 3;
			console.fixedHeight = true;
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
			
			playerHealthBar = new ProgressBar(5, console.y - 13, 54, 8);
			playerHealthBar.barCol = 0xCCCCCC;
			addChild(playerHealthBar);
			playerXpBar = new ProgressBar(5, playerHealthBar.y - 4, 54, 3);
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
				var focusText:TextBox = new TextBox(100, 1, 0x00000000, 0x00000000, 0xFFAA0000);
				focusText.text = "click to play";
				focusText.bitmapData.colorTransform(focusText.bitmapData.rect, new ColorTransform(1, 0, 0, 1, -85));
				focusPrompt.addChild(focusText);
				focusText.x = (WIDTH * 0.5) - 36;
				focusText.y = (HEIGHT * 0.5) + 10;
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
			
			shakeDirX = shakeDirY = 0;
			konamiCode = false;
			colossalCaveCode = false;
			
			// LISTS
			
			colliders = new Vector.<Collider>();
			entities = new Vector.<Entity>();
			items = [];
			effects = new Vector.<Effect>();
			fx = new Vector.<FX>();
			
			fxFilterCallBack = function(item:FX, index:int, array:Vector.<FX>):Boolean{
				//item.main();
				return item.active && onScreen(item.x, item.y, g, item.blit.width);
			};
			
			Item.runeNames = [];
			for(i = 0; i < Item.RUNE_NAMES.length; i++){
				Item.runeNames.push("?");
			}
			
			// LEVEL SPECIFIC INIT
			// This stuff that follows requires the bones of a level to initialise
			
			Brain.initCharacterLists();
			content = new Content();
			dungeon = new Map(1, this);
			Brain.initMaps(dungeon.bitmap);
			renderer = new MapRenderer(this, canvas, new Sprite(), SCALE, dungeon.width, dungeon.height, WIDTH, HEIGHT);
			renderer.setLayers(dungeon.layers, [null, null, entitiesHolder, foregroundHolder], [tileImage, tileImage, null, null], [tileImageHolder, tileImageHolder, null, null]);
			blockMap = createIdMap(renderer.mapArrayLayers[MapRenderer.BLOCK_LAYER]);
			lightMap = new LightMap(blockMap, this);
			canvas.addChild(lightMap.bitmap);
			renderer.init(dungeon.start.x, dungeon.start.y);
			// modify the mapRect to conceal secrets
			renderer.mapRect = dungeon.bitmap.adjustedMapRect;
			miniMap = new MiniMap(blockMap, this);
			miniMap.y = miniMap.x = 25;
			miniMapHolder.addChild(miniMap);
			frameCount = 1;
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
			renderer = null;
			camera = null;
			dungeon = null;
			Stairs.lastStairsUsedType = Stairs.DOWN;
			init();
		}
		
		/* Used to change to a new level in the dungeon
		 *
		 * This method tries to wipe all layers whilst leaving the gaming architecture in place
		 */
		public function changeLevel(n:int, loaded:Boolean = false):void{
			if(!loaded){
				// left over content needs to be pulled back into the content manager to be found
				// if the level is visited again
				content.recycleLevel(this);
				QuickSave.save(g, true);
			}
			
			// elements to update:
			
			// game_objects list needs to be emptied
			// items list needs to be emptied
			// colliders list needs to be emptied
			// new map
			// clear rendering layers
			
			// dismiss entity effects - leave player and minion alone
			var i:int;
			for(i = 0; i < entities.length; i++){
				if(entities[i] is Character && entities[i] != minion && (entities[i] as Character).effects){
					(entities[i] as Character).removeEffects();
				}
			}
			
			// clear lists
			entities = new Vector.<Entity>();
			colliders = new Vector.<Collider>();
			items = [];
			fx = new Vector.<FX>();
			
			// clear rendering layers
			while(stairsHolder.numChildren > 0) stairsHolder.removeChildAt(0);
			while(itemsHolder.numChildren > 0) itemsHolder.removeChildAt(0);
			while(entitiesHolder.numChildren > 0) entitiesHolder.removeChildAt(0);
			while(playerHolder.numChildren > 0) playerHolder.removeChildAt(0);
			while(fxHolder.numChildren > 0) fxHolder.removeChildAt(0);
			
			Brain.initCharacterLists();
			dungeon = new Map(n, this);
			Brain.initMaps(dungeon.bitmap);
			
			renderer.newMap(dungeon.width, dungeon.height, dungeon.layers);
			
			// modify the mapRect to conceal secrets
			if(n > 0){
				renderer.mapRect = dungeon.bitmap.adjustedMapRect;
				camera.mapRect = dungeon.bitmap.adjustedMapRect;
			} else {
				camera.mapRect = renderer.mapRect;
			}
			
			blockMap = createIdMap(renderer.mapArrayLayers[MapRenderer.BLOCK_LAYER]);
			lightMap.newMap(blockMap);
			lightMap.setLight(player, player.light);
			
			renderer.init(dungeon.start.x, dungeon.start.y);
			
			miniMap.newMap(blockMap);
			
			playerHolder.addChild(player.mc);
			player.x = (SCALE >> 1) + dungeon.start.x * SCALE;
			player.y = -8 + (dungeon.start.y + 1) * SCALE;
			player.mapX = player.x * INV_SCALE;
			player.mapY = player.y * INV_SCALE;
			player.updateRect();
			player.updateMC();
			colliders.push(player);
			camera.main();
			camera.skipScroll();
			if(minion){
				entities.push(minion);
				colliders.push(minion);
				entitiesHolder.addChild(minion.mc);
				if(minion.light) lightMap.setLight(minion, minion.light, 150);
				minion.teleportToPlayer();
			}
			
			// the overworld behaves differently to the rest of the game
			if(dungeon.level == 0){
				lightMap.bitmap.visible = false;
			} else {
				lightMap.bitmap.visible = true;
			}
			
			
			player.enterLevel(entrance);
			
		}
		
		private function initPlayer():void{
			var playerMc:MovieClip = new library.PlayerMC();
			playerHolder.addChild(playerMc);
			playerMc.x = (SCALE >> 1) + dungeon.start.x * SCALE;
			playerMc.y = -8 + (dungeon.start.y + 1) * SCALE;
			var minionMc:MovieClip = new library.SkeletonMC();
			minionMc.x = playerMc.x;
			minionMc.y =  -minionMc.height * 0.5 + (dungeon.start.y + 1) * SCALE;
			entitiesHolder.addChild(minionMc);
			player = new Player(playerMc, 6, 13, entrance, this);
			minion = new Minion(minionMc, Character.SKELETON, minionMc.width, minionMc.height, this);
			camera = new Camera(this, player, WIDTH, SCALE + HEIGHT - console.height);
			player.enterLevel(entrance);
		}
		
		private function addListeners():void{
			stage.addEventListener(Event.DEACTIVATE, onFocusLost);
			stage.addEventListener(Event.ACTIVATE, onFocus);
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			addEventListener(Event.ENTER_FRAME, main);
		}
		
		private function main(e:Event):void{
			
			// copy out these debug tools when needed
			//var t:int = getTimer();
			//info.text = g.player.mapX + " " + g.player.mapY;
			//info.appendText("pixels" + (getTimer() - t) + "\n"); t = getTimer();
			
			debug.clear();
			debug.lineStyle(1, 0x00ff00);
			fxHolder.graphics.clear();
			
			//Brain.dungeonGraph.drawGraph(debug, SCALE);
			//
			//var mouseMapX:int = INV_SCALE * canvas.mouseX;
			//var mouseMapY:int = INV_SCALE * canvas.mouseY;
			//if(Brain.dungeonGraph.nodes[mouseMapY][mouseMapX] && Brain.dungeonGraph.nodes[player.mapY][player.mapX]){
				//var path:Vector.<Node> = Brain.dungeonGraph.getPath(Brain.dungeonGraph.nodes[player.mapY][player.mapX], Brain.dungeonGraph.nodes[mouseMapY][mouseMapX], 100);
				//if(path){
					//if(path.length == 0) trace(g.frameCount);
					//Brain.dungeonGraph.drawPath(path, debug, SCALE);
				//}
			//}
			
			if(state == GAME){
				
				if(player.active && (player.awake)) player.move();
				for(i = 0; i < colliders.length; i++){
					if(colliders[i].active){
						if(colliders[i].awake && colliders[i].callMain) colliders[i].move();
						//colliders[i].draw(debug);
					} else {
						colliders[i].divorce();
						colliders.splice(i, 1);
						i--;
					}
				}
				
				// the camera MUST be updated before rendering commences -
				// bear in mind that rendering occurs even during GameObject.main()
				if(player.state != Character.EXIT && player.state != Character.ENTER) camera.main();
				
				if(player.active) miniMap.update();
					
				// position blitting bitmaps
				tileImageHolder.x = -canvas.x;
				tileImageHolder.y = -canvas.y;
				backFxImageHolder.x = -canvas.x;
				backFxImageHolder.y = -canvas.y;
				frontFxImageHolder.x = -canvas.x;
				frontFxImageHolder.y = -canvas.y;
				backFxImage.fillRect(frontFxImage.rect, 0x00000000);
				frontFxImage.fillRect(frontFxImage.rect, 0x00000000);
				
				// reset character weights before attacks
				for(i = 0; i < colliders.length; i++){
					if(colliders[i].block.type & Block.CHARACTER) colliders[i].weight = 1
				}
				// update player
				
				if(player.active) player.main();
				
				// update the rest of the game objects
				for(i = 0; i < entities.length; i++){
					if(entities[i].active){
						if(entities[i].callMain) entities[i].main();
					} else {
						// we remove entities from the playing field here, and remove the graphic
						if(entities[i].mc && entities[i].mc.parent) entities[i].mc.parent.removeChild(entities[i].mc);
						entities.splice(i, 1);
						i--;
					}
				}
				// apply effects
				for(i = 0; i < effects.length; i++){
					if(effects[i].active){
						effects[i].main();
					} else {
						effects.splice(i, 1);
						i--;
					}
				}
				
				// render blitters
				
				// I'm clearing the tileImage buffer here, because I need it full during the entities
				// cycle for the invisibility effect
				tileImage.fillRect(tileImage.rect, 0x00000000);
				renderer.main();
				lightMap.main();
				updateFX();
				updateShaker();
				
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
		/* Shake the screen in any direction */
		public function shake(x:int, y:int):void {
			// ignore lesser shakes
			if(Math.abs(x) < Math.abs(shaker.x)) return;
			if(Math.abs(y) < Math.abs(shaker.y)) return;
			shaker.x = x;
			shaker.y = y;
			shakeDirX = x > 0 ? 1 : -1;
			shakeDirY = y > 0 ? 1 : -1;
		}
		/* resolve the shake */
		private function updateShaker():void {
			// shake first
			if(shaker.y != 0) {
				shaker.y = -shaker.y;
				if(shakeDirY == 1 && shaker.y > 0) shaker.y--;
				if(shakeDirY == -1 && shaker.y < 0) shaker.y++;
			}
			if(shaker.x != 0) {
				shaker.x = -shaker.x;
				if(shakeDirX == 1 && shaker.x > 0) shaker.x--;
				if(shakeDirX == -1 && shaker.x < 0) shaker.x++;
			}
		}
		/* Maintain FX */
		private function updateFX():void{
			for(i = 0; i < fx.length; i++) fx[i].main();
			// since the fx list balloons and shrinks a lot, it's more efficient to filter it
			if(fx.length) fx = fx.filter(fxFilterCallBack);
		}
		/* Add to list */
		public function addFX(x:Number, y:Number, blit:BlitRect, image:BitmapData, imageHolder:Bitmap, dir:Dot = null, looped:Boolean = false):FX{
			var item:FX = new FX(x, y, blit, image, imageHolder, this, dir, 0, looped);
			fx.push(item);
			return item;
		}
		/* Add to list */
		public function addDebris(x:Number, y:Number, blit:BlitRect, vx:Number = 0, vy:Number = 0, print:BlitRect = null, smear:Boolean = false):DebrisFX{
			var item:DebrisFX = new DebrisFX(x, y, blit, frontFxImage, frontFxImageHolder, this, print, smear);
			item.addVelocity(vx, vy);
			fx.push(item);
			return item;
		}
		/* Fill a rect with fading teleport sparks that drift upwards */
		public function createTeleportSparkRect(rect:Rect, quantity:int):void{
			var x:Number, y:Number, spark:FadingBlitRect, item:FX;
			for(var i:int = 0; i < quantity; i++){
				x = rect.x + Math.random() * rect.width;
				y = rect.y + Math.random() * rect.height;
				spark = Math.random() > 0.5 ? teleportSparkSmallFadeFbr : teleportSparkBigFadeFbr;
				item = addFX(x, y, spark, frontFxImage, frontFxImageHolder, new Dot(0, -Math.random()));
				item.frame = Math.random() * spark.totalFrames;
			}
		}
		/* Fill a rect with particles and let them fly */
		public function createDebrisRect(rect:Rect, vx:Number, quantity:int, type:int):void{
			var x:Number, y:Number, blit:BlitRect, print:BlitRect;
			for(var i:int = 0; i < quantity; i++){
				x = rect.x + Math.random() * rect.width;
				y = rect.y + Math.random() * rect.height;
				if(Math.random() > 0.5){
					blit = smallDebrisBrs[type];
					print = smallFadeFbrs[type];
				} else {
					blit = bigDebrisBrs[type];
					print = bigFadeFbrs[type];
				}
				addDebris(x, y, blit, vx + vx * Math.random() , -Math.random() * 4.5, print, true);
			}
		}
		/* Throw some debris particles out */
		public function createDebrisSpurt(x:Number, y:Number, vx:Number, quantity:int, type:int):void{
			var blit:BlitRect, print:BlitRect;
			for(var i:int = 0; i < quantity; i++){
				if(Math.random() > 0.5){
					blit = smallDebrisBrs[type];
					print = smallFadeFbrs[type];
				} else {
					blit = bigDebrisBrs[type];
					print = bigFadeFbrs[type];
				}
				addDebris(x, y, blit, vx + vx * Math.random() , -Math.random() * 4.5, print, true);
			}
		}
		/* Throw some sparks out */
		public function createSparks(x:Number, y:Number, dx:Number, dy:Number, quantity:int):void{
			for(var i:int = 0; i < quantity; i++){
				addDebris(x, y, sparkBr,
					(dx + (-dy + Math.random() * (dy * 2))) * Math.random() * 5,
					(dy + ( -dx + Math.random() * (dx * 2))) * Math.random() * 5
				);
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
		private function createIdMap(map:Array):Vector.<Vector.<int>>{
			var idMap:Vector.<Vector.<int>> = new Vector.<Vector.<int>>(renderer.height, true), r:int, c:int;
			for(r = 0; r < renderer.height; r++){
				idMap[r] = new Vector.<int>(renderer.width, true);
				for(c = 0; c < renderer.width; c++){
					idMap[r][c] = MapTileConverter.getBlockId(map[r][c]);
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
		
		
		public var testCounter:int = 0;
		
		
		private function keyPressed(e:KeyboardEvent):void{
			if(Key.customDown(MENU_KEY)){
				pauseGame();
			}
			/*if(Key.isDown(Key.R)){
				reset();
			}
			if(Key.isDown(Key.T)){
				console.print("test\n"+(testCounter++));
			}
			if(Key.isDown(Key.P)){
				//minion.death("key");
				player.levelUp();
			}*/
		}
		
		private function onFocusLost(e:Event = null):void{
			if(state == UNFOCUSED) return;
			previousState = state;
			state = UNFOCUSED;
			Key.forceClearKeys();
			addChild(focusPrompt);
		}
		
		private function onFocus(e:Event = null):void{
			if(focusPrompt.parent) focusPrompt.parent.removeChild(focusPrompt);
			state = previousState;
		}
	}
	
}