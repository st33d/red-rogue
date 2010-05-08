package
{
	import com.robotacid.ai.Brain;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Minion;
	import com.robotacid.engine.Stairs;
	import com.robotacid.ui.MiniMap;
	import com.robotacid.geom.Dot;
	import com.robotacid.geom.Pixel;
	import com.robotacid.engine.Entity;
	import com.robotacid.geom.Rect;
	import com.robotacid.engine.MapRenderer;
	import com.robotacid.geom.Trig;
	import com.robotacid.gfx.*;
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Collider;
	import com.robotacid.ui.Console;
	import com.robotacid.ui.menu.GameMenu;
	import com.robotacid.ui.ProgressBar;
	import com.robotacid.ui.TextBox;
	import com.robotacid.util.clips.stopClips;
	import com.robotacid.util.HiddenInt;
	import com.robotacid.util.misc.onScreen;
	import com.robotacid.engine.Item;
	import com.robotacid.gfx.LightMap;
	import com.robotacid.dungeon.Map;
	import com.robotacid.engine.Player;
	import com.robotacid.gfx.Camera;
	import com.robotacid.engine.MapTileConverter;
	import com.robotacid.ui.Key;
	import com.robotacid.util.LZW;
	import com.robotacid.util.RLE;
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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	
	[SWF(width = "640", height = "480", frameRate="30", backgroundColor = "#000000")]
	
	/**
	 * Red Rogue
	 *
	 * A roguelike platform game
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	
	public class Game extends Sprite {
		
		public static var g:Game;
		public static var debug:Graphics;
		public static var debug_stay:Graphics;
		
		// core engine objects
		public var player:Player;
		public var minion:Minion;
		public var library:Library;
		public var dungeon:Map;
		public var entrance:Stairs;
		
		// graphics
		public var renderer:MapRenderer;
		public var camera:Camera;
		public var light_map:LightMap;
		public var lightning:Lightning;
		
		// rendering surfaces
		public var shaker:Sprite;
		public var canvas:Sprite;
		public var tile_image:BitmapData;
		public var tile_image_holder:Bitmap;
		public var debris_map_holder:Sprite;
		public var items_holder:Sprite;
		public var stairs_holder:Sprite;
		public var entities_holder:Sprite;
		public var player_holder:Sprite;
		public var front_fx_image:BitmapData;
		public var front_fx_image_holder:Bitmap;
		public var back_fx_image:BitmapData;
		public var back_fx_image_holder:Bitmap;
		public var fx_holder:Sprite;
		public var foreground_holder:Sprite;
		public var focus_prompt:Sprite;
		public var menu_holder:Sprite;
		public var mini_map_holder:Sprite;
		
		// blitting sprites
		public var spark_br:BlitRect;
		public var twinkle_bc:BlitClip;
		public var teleport_spark_big_fade_fbr:FadingBlitRect;
		public var teleport_spark_small_fade_fbr:FadingBlitRect;
		
		public var small_debris_brs:Vector.<BlitRect>;
		public var big_debris_brs:Vector.<BlitRect>;
		public var small_fade_fbrs:Vector.<FadingBlitRect>;
		public var big_fade_fbrs:Vector.<FadingBlitRect>;
		
		// ui
		public var console:Console;
		public var menu:GameMenu;
		public var mini_map:MiniMap;
		public var player_health_bar:ProgressBar;
		public var player_xp_bar:ProgressBar;
		public var minion_health_bar:ProgressBar;
		public var enemy_health_bar:ProgressBar;
		
		public var info:TextField;
		
		// lists
		public var block_map:Vector.<Vector.<int>>;
		public var entities:Vector.<Entity>;
		public var colliders:Vector.<Collider>;
		public var items:Array;
		public var effects:Vector.<Effect>;
		public var fx:Vector.<FX>;
		
		// states
		public var state:int;
		public var previous_state:int;
		public var frame_count:int;
		public var mouse_count:int;
		public var mouse_pressed:Boolean;
		public var god_mode:Boolean;
		public var paused:Boolean;
		public var shake_dir_x:int;
		public var shake_dir_y:int;
		public var konami_code:Boolean = false;
		public var colossal_cave_code:Boolean = false;
		public var force_focus:Boolean = true;
		
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
		
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			Key.init(stage);
			Key.custom = [Key.W, Key.S, Key.A, Key.D, Keyboard.SPACE, Key.NUMBER_1, Key.NUMBER_2, Key.NUMBER_3, Key.NUMBER_4, Key.NUMBER_5, Key.NUMBER_6, Key.NUMBER_7, Key.NUMBER_8, Key.NUMBER_9, Key.NUMBER_0];
			Key.hot_key_total = 10;
			
			library = new Library;
			scaleX = scaleY = 2;
			stage.quality = StageQuality.LOW;
			shaker = new Sprite();
			addChild(shaker);
			canvas = new Sprite();
			shaker.addChild(canvas);
			tile_image = new BitmapData(WIDTH, HEIGHT, true, 0x00000000);
			tile_image_holder = new Bitmap(tile_image);
			items_holder = new Sprite();
			stairs_holder = new Sprite();
			entities_holder = new Sprite();
			back_fx_image = new BitmapData(WIDTH, HEIGHT, true, 0x00000000);
			back_fx_image_holder = new Bitmap(back_fx_image);
			front_fx_image = new BitmapData(WIDTH, HEIGHT, true, 0x00000000);
			front_fx_image_holder = new Bitmap(front_fx_image);
			fx_holder = new Sprite();
			player_holder = new Sprite();
			foreground_holder = new Sprite();
			
			var debug_shape:Shape = new Shape();
			var debug_stay_shape:Shape = new Shape();
			debug = debug_shape.graphics;
			debug_stay = debug_stay_shape.graphics;
			debug_stay.lineStyle(1, 0xFF00FF);
			
			canvas.addChild(tile_image_holder);
			canvas.addChild(stairs_holder);
			canvas.addChild(items_holder);
			canvas.addChild(back_fx_image_holder);
			canvas.addChild(entities_holder);
			canvas.addChild(player_holder);
			canvas.addChild(front_fx_image_holder);
			canvas.addChild(fx_holder);
			canvas.addChild(foreground_holder);
			canvas.addChild(debug_shape);
			canvas.addChild(debug_stay_shape);
			
			// init debris particles
			small_debris_brs = new Vector.<BlitRect>();
			small_debris_brs.push(new BlitRect(0, 0, 1, 1, 0xffAA0000));
			small_debris_brs.push(new BlitRect(0, 0, 1, 1, 0xffffffff));
			small_debris_brs.push(new BlitRect(0, 0, 1, 1, 0xff000000));
			big_debris_brs = new Vector.<BlitRect>();
			big_debris_brs.push(new BlitRect(-1, -1, 2, 2, 0xffAA0000));
			big_debris_brs.push(new BlitRect(-1, -1, 2, 2, 0xFFFFFFFF));
			big_debris_brs.push(new BlitRect(-1, -1, 2, 2, 0xff000000));
			small_fade_fbrs = new Vector.<FadingBlitRect>();
			small_fade_fbrs.push(new FadingBlitRect(0, 0, 1, 1, 30, 0xffAA0000));
			small_fade_fbrs.push(new FadingBlitRect(0, 0, 1, 1, 30, 0xffffffff));
			small_fade_fbrs.push(new FadingBlitRect(0, 0, 1, 1, 30, 0xff000000));
			big_fade_fbrs = new Vector.<FadingBlitRect>();
			big_fade_fbrs.push(new FadingBlitRect( -1, -1, 2, 2, 30, 0xffAA0000));
			big_fade_fbrs.push(new FadingBlitRect( -1, -1, 2, 2, 30, 0xffffffff));
			big_fade_fbrs.push(new FadingBlitRect( -1, -1, 2, 2, 30, 0xff000000));
			
			spark_br = small_debris_brs[BONE];
			teleport_spark_small_fade_fbr = small_fade_fbrs[BONE];
			teleport_spark_big_fade_fbr = big_fade_fbrs[BONE];
			
			twinkle_bc = new BlitClip(new library.TwinkleMC);
			twinkle_bc.compress();
			
			lightning = new Lightning();
			
			// user interface:
			console = new Console(320, 3);
			console.y = HEIGHT - (console._height);
			console.max_lines = 3;
			addChild(console);
			//Effect.hideNames();
			
			mini_map_holder = new Sprite();
			addChild(mini_map_holder);
			
			if(!menu){
				menu = new GameMenu(WIDTH, console.y, this);
			}
			menu_holder = new Sprite();
			addChild(menu_holder);
			menu.holder = menu_holder;
			if(state == MENU){
				menu_holder.addChild(menu);
			}
			
			player_health_bar = new ProgressBar(5, console.y - 13, 54, 8);
			player_health_bar.bar_col = 0xCCCCCC;
			addChild(player_health_bar);
			player_xp_bar = new ProgressBar(5, player_health_bar.y - 4, 54, 3);
			player_xp_bar.bar_col = 0xCCCCCC;
			addChild(player_xp_bar);
			
			minion_health_bar = new ProgressBar(5, player_xp_bar.y - 5, player_health_bar.width * 0.5, 4);
			minion_health_bar.bar_col = 0xCCCCCC;
			addChild(minion_health_bar);
			minion_health_bar.visible = false;
			
			enemy_health_bar = new ProgressBar(WIDTH - 59, console.y - 13, 54, 8);
			enemy_health_bar.bar_col = 0xCCCCCC;
			addChild(enemy_health_bar);
			enemy_health_bar.active = false;
			enemy_health_bar.alpha = 0;
			
			if(!focus_prompt){
				focus_prompt = new Sprite();
				focus_prompt.graphics.beginFill(0x000000);
				focus_prompt.graphics.drawRect(0, 0, WIDTH, HEIGHT);
				var focus_text:TextField = new TextField();
				focus_prompt.addChild(focus_text);
				focus_text.embedFonts = true;
				focus_text.antiAliasType = AntiAliasType.NORMAL;
				focus_text.gridFitType = GridFitType.PIXEL;
				var tf:TextFormat = new TextFormat("quadratis", 8, 0xAA0000);
				//tf.letterSpacing = -1;
				focus_text.defaultTextFormat = tf;
				focus_text.selectable = false;
				focus_text.text = "click to play";
				focus_text.x = (WIDTH * 0.5) - 35;
				focus_text.y = (HEIGHT * 0.5) + 10;
				var title_b:Bitmap = new library.BannerB();
				focus_prompt.addChild(title_b);
				title_b.y = HEIGHT * 0.5 - title_b.height * 0.5;
				title_b.scaleX = title_b.scaleY = 0.5;
				stage.addEventListener(Event.DEACTIVATE, onFocusLost);
				stage.addEventListener(Event.ACTIVATE, onFocus);
			}
			
			
			/**/
			// debugging textfield
			info = new TextField();
			addChild(info);
			info.embedFonts = true;
			info.antiAliasType = AntiAliasType.NORMAL;
			info.gridFitType = GridFitType.PIXEL;
			info.defaultTextFormat = new TextFormat("quadratis", 8, 0xFFFFFF);
			info.selectable = false;
			info.autoSize = TextFieldAutoSize.LEFT;
			info.text = "";
			
			info.visible = true;
			
			shake_dir_x = shake_dir_y = 0;
			konami_code = false;
			colossal_cave_code = false;
			
			
			//lists
			colliders = new Vector.<Collider>();
			entities = new Vector.<Entity>();
			items = [];
			effects = new Vector.<Effect>();
			fx = new Vector.<FX>();
			Item.rune_names = [];
			for(i = 0; i < Item.RUNE_NAMES.length; i++){
				Item.rune_names.push("?");
			}
			
			createDungeon();
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
			Stairs.last_stairs_used_type = Stairs.DOWN;
			init();
		}
		
		/* Used to change to a new level in the dungeon 
		 * 
		 * This method tries to wipe all layers whilst leaving the gaming architecture in place
		 */
		public function changeLevel(n:int):void{
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
			while(stairs_holder.numChildren > 0) stairs_holder.removeChildAt(0);
			while(items_holder.numChildren > 0) items_holder.removeChildAt(0);
			while(entities_holder.numChildren > 0) entities_holder.removeChildAt(0);
			while(player_holder.numChildren > 0) player_holder.removeChildAt(0);
			while(fx_holder.numChildren > 0) fx_holder.removeChildAt(0);
			
			dungeon = new Map(n, this);
			renderer.newMap(dungeon.width, dungeon.height, dungeon.layers);
			
			block_map = createIdMap(renderer.map_array_layers[MapRenderer.BLOCK_LAYER]);
			light_map.newMap(block_map);
			light_map.setLight(player, player.light);
			
			renderer.init(dungeon.start.x, dungeon.start.y);
			
			mini_map.newMap(block_map);
			
			player_holder.addChild(player.mc);
			player.x = (SCALE >> 1) + dungeon.start.x * SCALE;
			player.y = -8 + (dungeon.start.y + 1) * SCALE;
			player.map_x = player.x * INV_SCALE;
			player.map_y = player.y * INV_SCALE;
			player.updateRect();
			player.updateMC();
			colliders.push(player);
			camera.main();
			camera.skipScroll();
			if(minion){
				entities.push(minion);
				colliders.push(minion);
				entities_holder.addChild(minion.mc);
				if(minion.light) light_map.setLight(minion, minion.light, 150);
				minion.teleportToPlayer();
			}
			
			// the overworld behaves differently to the rest of the game
			if(dungeon.level == 0){
				light_map.bitmap.visible = false;
			} else {
				light_map.bitmap.visible = true;
			}
			
			
			player.enterLevel(entrance);
			
		}
		
		private function initPlayer():void{
			var temp:MovieClip = new library.PlayerMC();
			player_holder.addChild(temp);
			temp.x = (SCALE >> 1) + dungeon.start.x * SCALE;
			temp.y = -8 + (dungeon.start.y + 1) * SCALE;
			player = new Player(temp, 6, 13, entrance, this);
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
			//info.text = ""
			//info.appendText("pixels" + (getTimer() - t) + "\n"); t = getTimer();
				
			debug.clear();
			debug.lineStyle(1, 0x00ff00);
			fx_holder.graphics.clear();
			
			if(state == GAME){
				
				if(player.active && (player.awake)) player.move();
				for(i = 0; i < colliders.length; i++){
					if(colliders[i].active){
						if(colliders[i].awake && colliders[i].call_main) colliders[i].move();
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
				
				if(player.active) mini_map.update();
					
				// position blitting bitmaps
				tile_image_holder.x = -canvas.x;
				tile_image_holder.y = -canvas.y;
				back_fx_image_holder.x = -canvas.x;
				back_fx_image_holder.y = -canvas.y;
				front_fx_image_holder.x = -canvas.x;
				front_fx_image_holder.y = -canvas.y;
				back_fx_image.fillRect(front_fx_image.rect, 0x00000000);
				front_fx_image.fillRect(front_fx_image.rect, 0x00000000);
				
				// reset character weights before attacks
				for(i = 0; i < colliders.length; i++){
					if(colliders[i].block.type & Block.CHARACTER) colliders[i].weight = 1
				}
				// update player
				
				if(player.active) player.main();
				
				// update the rest of the game objects
				for(i = 0; i < entities.length; i++){
					if(entities[i].active){
						if(entities[i].call_main) entities[i].main();
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
				
				// I'm clearing the tile_image buffer here, because I need it full during the entities
				// cycle for the invisibility effect
				tile_image.fillRect(tile_image.rect, 0x00000000);
				renderer.main();
				light_map.main();
				updateFX();
				updateShaker();
				
				frame_count++;
				
				// examine the key buffer for cheat codes
				if(!konami_code && Key.matchLog(Key.KONAMI_CODE)){
					konami_code = true;
					console.print("konami");
				}
				if(!colossal_cave_code && Key.matchLog(Key.COLOSSAL_CAVE_CODE)){
					colossal_cave_code = true;
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
			shake_dir_x = x > 0 ? 1 : -1;
			shake_dir_y = y > 0 ? 1 : -1;
		}
		/* resolve the shake */
		private function updateShaker():void {
			// shake first
			if(shaker.y != 0) {
				shaker.y = -shaker.y;
				if(shake_dir_y == 1 && shaker.y > 0) shaker.y--;
				if(shake_dir_y == -1 && shaker.y < 0) shaker.y++;
			}
			if(shaker.x != 0) {
				shaker.x = -shaker.x;
				if(shake_dir_x == 1 && shaker.x > 0) shaker.x--;
				if(shake_dir_x == -1 && shaker.x < 0) shaker.x++;
			}
		}
		/* Maintain FX */
		private function updateFX():void{
			for(i = 0; i < fx.length; i++){
				fx[i].main();
				if(!fx[i].active || !onScreen(fx[i].x, fx[i].y, this, fx[i].blit.width)){
					fx.splice(i, 1);
					i--;
				}
			}
		}
		/* Add to list */
		public function addFX(x:Number, y:Number, blit:BlitRect, image:BitmapData, image_holder:Bitmap, dir:Dot = null, looped:Boolean = false):FX{
			var item:FX = new FX(x, y, blit, image, image_holder, this, dir, 0, looped);
			fx.push(item);
			return item;
		}
		/* Add to list */
		public function addDebris(x:Number, y:Number, blit:BlitRect, vx:Number = 0, vy:Number = 0, print:BlitRect = null, smear:Boolean = false):DebrisFX{
			var item:DebrisFX = new DebrisFX(x, y, blit, front_fx_image, front_fx_image_holder, this, print, smear);
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
				spark = Math.random() > 0.5 ? teleport_spark_small_fade_fbr : teleport_spark_big_fade_fbr;
				item = addFX(x, y, spark, front_fx_image, front_fx_image_holder, new Dot(0, -Math.random()));
				item.frame = Math.random() * spark.total_frames;
			}
		}
		/* Fill a rect with particles and let them fly */
		public function createDebrisRect(rect:Rect, vx:Number, quantity:int, type:int):void{
			var x:Number, y:Number, blit:BlitRect, print:BlitRect;
			for(var i:int = 0; i < quantity; i++){
				x = rect.x + Math.random() * rect.width;
				y = rect.y + Math.random() * rect.height;
				if(Math.random() > 0.5){
					blit = small_debris_brs[type];
					print = small_fade_fbrs[type];
				} else {
					blit = big_debris_brs[type];
					print = big_fade_fbrs[type];
				}
				addDebris(x, y, blit, vx + vx * Math.random() , -Math.random() * 4.5, print, true);
			}
		}
		/* Throw some debris particles out */
		public function createDebrisSpurt(x:Number, y:Number, vx:Number, quantity:int, type:int):void{
			var blit:BlitRect, print:BlitRect;
			for(var i:int = 0; i < quantity; i++){
				if(Math.random() > 0.5){
					blit = small_debris_brs[type];
					print = small_fade_fbrs[type];
				} else {
					blit = big_debris_brs[type];
					print = big_fade_fbrs[type];
				}
				addDebris(x, y, blit, vx + vx * Math.random() , -Math.random() * 4.5, print, true);
			}
		}
		/* Throw some blood particles out */
		public function createSparks(x:Number, y:Number, dx:Number, dy:Number, quantity:int):void{
			for(var i:int = 0; i < quantity; i++){
				addDebris(x, y, spark_br,
					(dx + (-dy + Math.random() * (dy * 2))) * Math.random() * 5,
					(dy + ( -dx + Math.random() * (dx * 2))) * Math.random() * 5
				);
			}
		}
		/* Procedurally generate a dungeon */
		public function createDungeon():void{
			dungeon = new Map(1, this);
			renderer = new MapRenderer(this, canvas, new Sprite(), SCALE, dungeon.width, dungeon.height, WIDTH, HEIGHT);
			Brain.init();
			/*for(var i:int = 0; i < dungeon.layers.length; i++){
				var gfx:Boolean = false;
				var image:BitmapData = null;
				var image_holder:Bitmap = null;
				if(i == 0) {
					image = tile_image;
					image_holder = tile_image_holder;
				} else if(i == 1) {
					image = tile_image;
					image_holder = tile_image_holder;
				} else if(i == 2) {
					renderer.addTileLayer(entities_holder);
				} else if(i == 3) {
					renderer.addTileLayer(foreground_holder);
					gfx = true;
				}
				if(renderer.layers < 4) renderer.addLayer(dungeon.layers[i], image, image_holder);
			}*/
			renderer.setLayers(dungeon.layers, [null, null, entities_holder, foreground_holder], [tile_image, tile_image, null, null], [tile_image_holder, tile_image_holder, null, null]);
			block_map = createIdMap(renderer.map_array_layers[MapRenderer.BLOCK_LAYER]);
			light_map = new LightMap(block_map, this);
			canvas.addChild(light_map.bitmap);
			//changeMapValue(1, 0, renderer.map_array_layers[MapRenderer.BLOCK_LAYER]);
			renderer.init(dungeon.start.x, dungeon.start.y);
			mini_map = new MiniMap(block_map, this);
			mini_map.y = mini_map.x = 25;
			mini_map_holder.addChild(mini_map);
			frame_count = 1;
			initPlayer();
			// fire up listeners
			addListeners();
			// this is a hack to force clicking on the game when the browser first pulls in the swf
			if(force_focus){
				onFocusLost();
				force_focus = false;
			}
		}
		
		/*
		 * Creates a map of ints that represents properties of static blocks
		 * Any block to interact with is generated on the fly using this 2D array to determine its
		 * properties. 'id's of blocks are inferred by the tile numbers
		 */
		private function createIdMap(map:Array):Vector.<Vector.<int>>{
			var id_map:Vector.<Vector.<int>> = new Vector.<Vector.<int>>(renderer.height, true), r:int, c:int;
			for(r = 0; r < renderer.height; r++){
				id_map[r] = new Vector.<int>(renderer.width, true);
				for(c = 0; c < renderer.width; c++){
					id_map[r][c] = MapTileConverter.getBlockId(map[r][c]);
				}
			}
			return id_map;
		}
		private function mouseDown(e:MouseEvent):void{
			mouse_pressed = true;
			mouse_count = frame_count;
		}
		
		private function mouseUp(e:MouseEvent):void{
			mouse_pressed = false;
		}
		
		private function keyPressed(e:KeyboardEvent):void{
			/*if(Key.isDown(Key.R)){
				reset();
			}*/
			if(Key.customDown(MENU_KEY)){
				pauseGame();
			}
			if(Key.isDown(Key.P)){
				//minion.death("key");
				player.levelUp();
			}
		}
		
		private function onFocusLost(e:Event = null):void{
			previous_state = state;
			state = UNFOCUSED;
			Key.forceClearKeys();
			addChild(focus_prompt);
		}
		
		private function onFocus(e:Event = null):void{
			if(focus_prompt.parent) focus_prompt.parent.removeChild(focus_prompt);
			state = previous_state;
		}
	}
	
}