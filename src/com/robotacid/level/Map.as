package com.robotacid.level {
	import com.robotacid.engine.Altar;
	import com.robotacid.engine.ChaosWall;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.ColliderEntity;
	import com.robotacid.engine.ColliderEntitySensor;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.FadeLight;
	import com.robotacid.engine.Gate;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.MapTileConverter;
	import com.robotacid.engine.MapTileManager;
	import com.robotacid.engine.Player;
	import com.robotacid.engine.Portal;
	import com.robotacid.engine.Stone;
	import com.robotacid.engine.Torch;
	import com.robotacid.engine.Trap;
	import com.robotacid.engine.Writing;
	import com.robotacid.geom.Pixel;
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.BlitSprite;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.phys.Collider;
	import com.robotacid.util.array.randomiseArray;
	import com.robotacid.util.XorRandom;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * This is the random map generator
	 *
	 * The layout for every level is calculated in here.
	 * 
	 * MapBitmap creates the passage ways and creates a connectivity graph to place ladders and ledges
	 * the convertMapBitmap method converts that data into references to graphics and entities
	 * within that method Content.populateLevel distributes monsters and treasure
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Map {
		
		public static var game:Game;
		public static var renderer:Renderer;
		public static var random:XorRandom;
		public static var seed:uint = 0;
		
		public var level:int;
		public var type:int;
		public var width:int;
		public var height:int;
		public var start:Pixel;
		public var stairsUp:Pixel;
		public var stairsDown:Pixel;
		public var portals:Vector.<Pixel>;
		public var zone:int;
		public var completionCount:int;
		public var completionTotal:int;
		public var cleared:Boolean;
		
		public var bitmap:MapBitmap;
		
		private var i:int, j:int;
		
		public var layers:Array;
		
		// types
		public static const MAIN_DUNGEON:int = 0;
		public static const ITEM_DUNGEON:int = 1;
		public static const AREA:int = 2;
		
		// zones
		public static const DUNGEONS:int = 0;
		public static const SEWERS:int = 1;
		public static const CAVES:int = 2;
		public static const CHAOS:int = 3;
		
		// layers
		public static const BACKGROUND:int = 0;
		public static const BLOCKS:int = 1;
		public static const ENTITIES:int = 2;
		
		// outside area levels
		public static const OVERWORLD:int = 0;
		public static const UNDERWORLD:int = 1;
		
		public static const LAYER_NUM:int = 3;
		
		public static const BACKGROUND_WIDTH:int = 8;
		public static const BACKGROUND_HEIGHT:int = 8;
		
		public static const UNDERWORLD_BOAT_MIN:int = 8;
		public static const UNDERWORLD_BOAT_MAX:int = 17;
		public static const UNDERWORLD_PORTAL_X:int = 13;
		public static const OVERWORLD_STAIRS_X:int = 12;
		public static const OVERWORLD_PORTAL_X:int = 17;
		
		public static const LEVELS_PER_ZONE:int = 3;
		public static const ZONE_TOTAL:int = 4;
		
		public static const ZONE_NAMES:Vector.<String> = Vector.<String>(["dungeons", "sewers", "caves", "chaos"]);
		
		public function Map(level:int, type:int = MAIN_DUNGEON) {
			this.level = level;
			this.type = type;
			completionCount = completionTotal = 0;
			layers = [];
			portals = new Vector.<Pixel>();
			if(type == MAIN_DUNGEON || type == ITEM_DUNGEON){
				zone = game.content.getLevelZone(level);
			} else {
				zone = 0;
			}
			
			if(type == MAIN_DUNGEON){
				if(level > 0){
					random.r = game.content.getSeed(level, type);
					bitmap = new MapBitmap(level, type, zone);
					width = bitmap.width;
					height = bitmap.height;
					convertMapBitmap(bitmap.bitmapData);
				} else {
					createTestBed();
				}
				
			} else if(type == ITEM_DUNGEON){
				random.r = game.content.getSeed(level, type);
				var sideDungeonSize:int = 1 + (Number(level) / 10);
				bitmap = new MapBitmap(sideDungeonSize, type, zone);
				width = bitmap.width;
				height = bitmap.height;
				convertMapBitmap(bitmap.bitmapData);
				
			} else if(type == AREA){
				if(level == OVERWORLD){
					createOverworld();
				} else if(level == UNDERWORLD){
					createUnderworld();
				}
			}
			createBackground();
			
			// remove gate pixels over exits for ai graph
			if(stairsDown && bitmap.bitmapData.getPixel32(stairsDown.x, stairsDown.y) == MapBitmap.GATE) bitmap.bitmapData.setPixel32(stairsDown.x, stairsDown.y, MapBitmap.EMPTY);
			if(stairsUp && bitmap.bitmapData.getPixel32(stairsUp.x, stairsUp.y) == MapBitmap.GATE) bitmap.bitmapData.setPixel32(stairsUp.x, stairsUp.y, MapBitmap.EMPTY);
			for(i = 0; i < portals.length; i++){
				if(bitmap.bitmapData.getPixel32(portals[i].x, portals[i].y) == MapBitmap.GATE) bitmap.bitmapData.setPixel32(portals[i].x, portals[i].y, MapBitmap.EMPTY);
			}
			
			//bitmap.scaleX = bitmap.scaleY = 2;
			//game.addChild(bitmap);
			
		}
		
		/* Create the test bed
		 *
		 * This is a debugging playground for testing new content and trying to lure consistent
		 * bugs out into the open (which is nigh on fucking impossible in a procedural world)
		 */
		public function createTestBed():void{
			
			bitmap = new MapBitmap(0, AREA);
			
			width = bitmap.width;
			height = bitmap.height;
			// background
			layers.push(createGrid(null, width, height));
			// blocks - start with a full grid
			layers.push(createGrid(MapTileConverter.WALL, width, height));
			// game objects
			layers.push(createGrid(null, width, height));
			
			fill(0, 1, 1, width-2, height-2, layers[BLOCKS]);
			
			// access point
			setPortal((width * 0.5) >> 0, height - 2, <portal type={Portal.PORTAL} targetLevel={-1} targetType={Map.MAIN_DUNGEON} />);
			start = portals[0];
			
			// set zone for background debugging
			zone = (game.gameMenu.editorList.dungeonLevelList.selection) / LEVELS_PER_ZONE;
			if(zone >= 4) zone = CHAOS;
		}
		
		/* This is where we convert our map template into a level proper made of tileIds and other
		 * information
		 */
		public function convertMapBitmap(bitmapData:BitmapData):void{
			width = bitmapData.width;
			height = bitmapData.height;
			// background
			layers.push(createGrid(null, bitmapData.width, bitmapData.height));
			// blocks - start with a full grid
			layers.push(createGrid(MapTileConverter.WALL, bitmapData.width, bitmapData.height));
			// game objects
			layers.push(createGrid(null, bitmapData.width, bitmapData.height));
			
			var pixels:Vector.<uint> = bitmapData.getVector(bitmapData.rect);
			
			// create ladders, ledges and features
			
			// do a first pass to set up pit-traps and secrets and remove them from pixels[]
			// it makes the convoluted ledge/ladder checks simpler
			var r:int, c:int;
			for(i = width; i < pixels.length - width; i++){
				c = i % width;
				r = i / width;
				if(pixels[i] == MapBitmap.PIT){
					createPitTrap(c, r);
					pixels[i] = MapBitmap.WALL;
				} else if(pixels[i] == MapBitmap.SECRET){
					createSecretWall(c, r);
					pixels[i] = MapBitmap.WALL;
				} else if(pixels[i] == MapBitmap.GATE){
					// gates are created later
					pixels[i] = MapBitmap.EMPTY;
				}
			}
			// now for ladders, ledges and empty spaces
			for(i = width; i < pixels.length - width; i++){
				c = i % width;
				r = i / width;
				if(pixels[i] == MapBitmap.EMPTY && pixels[i + width] == MapBitmap.LADDER_LEDGE){
					layers[BLOCKS][r][c] = MapTileConverter.LADDER_TOP;
				} else if(pixels[i] == MapBitmap.LEDGE && pixels[i + width] == MapBitmap.LADDER_LEDGE){
					
					
					if((pixels[i - 1] == MapBitmap.EMPTY || pixels[i - 1] == MapBitmap.LADDER) && (pixels[i + 1] == MapBitmap.EMPTY || pixels[i + 1] == MapBitmap.LADDER)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_TOP_LEDGE;
						
					} else if((pixels[i - 1] == MapBitmap.EMPTY || pixels[i - 1] == MapBitmap.LADDER) && (pixels[i + 1] == MapBitmap.LEDGE || pixels[i + 1] == MapBitmap.LADDER_LEDGE)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_TOP_LEDGE_END_LEFT;
						
					} else if((pixels[i - 1] == MapBitmap.EMPTY || pixels[i - 1] == MapBitmap.LADDER) && pixels[i + 1] == MapBitmap.WALL){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_TOP_LEDGE_START_RIGHT_END;
						
					} else if(pixels[i - 1] == MapBitmap.WALL && (pixels[i + 1] == MapBitmap.LEDGE || pixels[i + 1] == MapBitmap.LADDER_LEDGE)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_TOP_LEDGE_START_LEFT;
						
					} else if(pixels[i - 1] == MapBitmap.WALL && pixels[i + 1] == MapBitmap.WALL){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_TOP_LEDGE_SINGLE;
						
					} else if((pixels[i - 1] == MapBitmap.LEDGE || pixels[i - 1] == MapBitmap.LADDER_LEDGE) && pixels[i + 1] == MapBitmap.WALL){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_TOP_LEDGE_START_RIGHT;
						
					} else if((pixels[i - 1] == MapBitmap.LEDGE || pixels[i - 1] == MapBitmap.LADDER_LEDGE) && (pixels[i + 1] == MapBitmap.EMPTY || pixels[i + 1] == MapBitmap.LADDER)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_TOP_LEDGE_END_RIGHT;
						
					} else if(pixels[i - 1] == MapBitmap.WALL && (pixels[i + 1] == MapBitmap.EMPTY || pixels[i + 1] == MapBitmap.LADDER)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_TOP_LEDGE_START_LEFT_END;
						
					} else if((pixels[i - 1] == MapBitmap.LEDGE || pixels[i - 1] == MapBitmap.LADDER_LEDGE) && (pixels[i + 1] == MapBitmap.LEDGE || pixels[i + 1] == MapBitmap.LADDER_LEDGE)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_TOP_LEDGE_MIDDLE;
					}
					
					
					
				} else if(pixels[i] == MapBitmap.LADDER_LEDGE){
					
					if((pixels[i - 1] == MapBitmap.EMPTY || pixels[i - 1] == MapBitmap.LADDER) && (pixels[i + 1] == MapBitmap.EMPTY || pixels[i + 1] == MapBitmap.LADDER)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_LEDGE;
						
					} else if((pixels[i - 1] == MapBitmap.EMPTY || pixels[i - 1] == MapBitmap.LADDER) && (pixels[i + 1] == MapBitmap.LEDGE || pixels[i + 1] == MapBitmap.LADDER_LEDGE)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_LEDGE_END_LEFT;
						
					} else if((pixels[i - 1] == MapBitmap.EMPTY || pixels[i - 1] == MapBitmap.LADDER) && pixels[i + 1] == MapBitmap.WALL){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_LEDGE_START_RIGHT_END;
						
					} else if(pixels[i - 1] == MapBitmap.WALL && (pixels[i + 1] == MapBitmap.LEDGE || pixels[i + 1] == MapBitmap.LADDER_LEDGE)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_LEDGE_START_LEFT;
						
					} else if(pixels[i - 1] == MapBitmap.WALL && pixels[i + 1] == MapBitmap.WALL){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_LEDGE_SINGLE;
						
					} else if((pixels[i - 1] == MapBitmap.LEDGE || pixels[i - 1] == MapBitmap.LADDER_LEDGE) && pixels[i + 1] == MapBitmap.WALL){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_LEDGE_START_RIGHT;
						
					} else if((pixels[i - 1] == MapBitmap.LEDGE || pixels[i - 1] == MapBitmap.LADDER_LEDGE) && (pixels[i + 1] == MapBitmap.EMPTY || pixels[i + 1] == MapBitmap.LADDER)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_LEDGE_END_RIGHT;
						
					} else if(pixels[i - 1] == MapBitmap.WALL && (pixels[i + 1] == MapBitmap.EMPTY || pixels[i + 1] == MapBitmap.LADDER)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_LEDGE_START_LEFT_END;
						
					} else if((pixels[i - 1] == MapBitmap.LEDGE || pixels[i - 1] == MapBitmap.LADDER_LEDGE) && (pixels[i + 1] == MapBitmap.LEDGE || pixels[i + 1] == MapBitmap.LADDER_LEDGE)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LADDER_LEDGE_MIDDLE;
					}
					
				} else if(pixels[i] == MapBitmap.LADDER){
					layers[BLOCKS][r][c] = MapTileConverter.LADDER;
				} else if(pixels[i] == MapBitmap.LEDGE){
					
					if((pixels[i - 1] == MapBitmap.EMPTY || pixels[i - 1] == MapBitmap.LADDER) && (pixels[i + 1] == MapBitmap.EMPTY || pixels[i + 1] == MapBitmap.LADDER)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LEDGE;
						
					} else if((pixels[i - 1] == MapBitmap.EMPTY || pixels[i - 1] == MapBitmap.LADDER) && (pixels[i + 1] == MapBitmap.LEDGE || pixels[i + 1] == MapBitmap.LADDER_LEDGE)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LEDGE_END_LEFT;
						
					} else if((pixels[i - 1] == MapBitmap.EMPTY || pixels[i - 1] == MapBitmap.LADDER) && pixels[i + 1] == MapBitmap.WALL){
						
						layers[BLOCKS][r][c] = MapTileConverter.LEDGE_START_RIGHT_END;
						
					} else if(pixels[i - 1] == MapBitmap.WALL && (pixels[i + 1] == MapBitmap.LEDGE || pixels[i + 1] == MapBitmap.LADDER_LEDGE)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LEDGE_START_LEFT;
						
					} else if(pixels[i - 1] == MapBitmap.WALL && pixels[i + 1] == MapBitmap.WALL){
						
						layers[BLOCKS][r][c] = MapTileConverter.LEDGE_SINGLE;
						
					} else if((pixels[i - 1] == MapBitmap.LEDGE || pixels[i - 1] == MapBitmap.LADDER_LEDGE) && pixels[i + 1] == MapBitmap.WALL){
						
						layers[BLOCKS][r][c] = MapTileConverter.LEDGE_START_RIGHT;
						
					} else if((pixels[i - 1] == MapBitmap.LEDGE || pixels[i - 1] == MapBitmap.LADDER_LEDGE) && (pixels[i + 1] == MapBitmap.EMPTY || pixels[i + 1] == MapBitmap.LADDER)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LEDGE_END_RIGHT;
						
					} else if(pixels[i - 1] == MapBitmap.WALL && (pixels[i + 1] == MapBitmap.EMPTY || pixels[i + 1] == MapBitmap.LADDER)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LEDGE_START_LEFT_END;
						
					} else if((pixels[i - 1] == MapBitmap.LEDGE || pixels[i - 1] == MapBitmap.LADDER_LEDGE) && (pixels[i + 1] == MapBitmap.LEDGE || pixels[i + 1] == MapBitmap.LADDER_LEDGE)){
						
						layers[BLOCKS][r][c] = MapTileConverter.LEDGE_MIDDLE;
					}
					
				} else if(pixels[i] == MapBitmap.EMPTY){
					layers[BLOCKS][r][c] = 0;
				}
			}
			
			// create access points
			var portalXMLs:Array = game.content.getPortals(level, type);
			var portalType:int;
			if(type == MAIN_DUNGEON){
				
				createAccessPoint(Portal.STAIRS, sortRoomsTopWards);
				for(i = 0; i < portalXMLs.length; i++){
					portalType = portalXMLs[i].@type;
					createAccessPoint(portalType, null, portalXMLs[i]);
				}
				createAccessPoint(Portal.STAIRS, sortRoomsBottomWards);
			
				
			} else if(type == ITEM_DUNGEON){
				for(i = 0; i < portalXMLs.length; i++){
					portalType = portalXMLs[i].@type;
					createAccessPoint(portalType, i == 0 ? sortRoomsTopWards : null, portalXMLs[i]);
				}
			}
			
			// reload pixels - access point creation altered the bitmap
			pixels = bitmapData.getVector(bitmapData.rect);
			
			// gates may fragment the level, so we need as many options for placing a key as possible
			if(bitmap.gates.length) createGates();
			
			// a good dungeon needs to be full of loot and monsters
			// in comes the content manager to mete out a decent amount of action and reward per level
			// content manager stocks are limited to avoid scumming
			completionCount += game.content.populateLevel(type, level, bitmap, layers, random);
			
			// now add some extra flavour
			createOtherTraps(pixels);
			// beyond the starting position of the underworld portal, the minion cannot have written anything
			if(level <= Writing.story.length && type == MAIN_DUNGEON) createWritings(pixels);
			createAltars(pixels);
			if(zone == DUNGEONS) createTorches(pixels);
			createDecor(pixels);
			createChaosWalls(pixels);
			createCritters();
			
			completionTotal = completionCount;
			cleared = game.content.getCleared(level, type);
			if(cleared) completionTotal = completionCount = 0;
		}
		
		/* Create the overworld
		 *
		 * The overworld is present to create a contrast with the dungeon. It is in colour and so
		 * are you. There is a health stone for restoring health and a grindstone -
		 * an allegory of improving yourself in the real world as opposed to a fantasy where
		 * you kill people to better yourself
		 */
		public function createOverworld():void{
			
			bitmap = new MapBitmap(OVERWORLD, AREA);
			
			width = bitmap.width;
			height = bitmap.height;
			layers.push(createGrid(null, width, height));
			// blocks - start with a full grid
			layers.push(createGrid(1, width, height));
			// game objects
			layers.push(createGrid(null, width, height));
			
			fill(0, 1, 0, width-2, height-1, layers[BLOCKS]);
			
			// create the grindstone and healstone
			layers[BLOCKS][height - 2][1] = MapTileConverter.WALL;
			layers[ENTITIES][height - 2][1] = MapTileConverter.HEAL_STONE;
			layers[BLOCKS][height - 2][width - 2] = MapTileConverter.WALL;
			layers[ENTITIES][height - 2][width - 2] = MapTileConverter.GRIND_STONE;
			
			var portalXMLs:Array = game.content.getPortals(level, type);
			if(portalXMLs.length){
				// given that there can only be one type of portal on the overworld - the rogue's portal
				// we create the rogue's portal here
				setPortal(OVERWORLD_PORTAL_X, height - 2, portalXMLs[0]);
			}
			
			setStairsDown(OVERWORLD_STAIRS_X, height - 2);
			
			// the player may have left content on the overworld as a sort of bank
			game.content.populateLevel(type, OVERWORLD, bitmap, layers, random);
		}
		
		/* Create the underworld
		 *
		 * The underworld is where the minion came from. It consists of a boat on the river Styx under a black
		 * sky where stars are exploding. Death (an NPC) is there.
		 */
		public function createUnderworld():void{
			
			bitmap = new MapBitmap(UNDERWORLD, AREA);
			
			width = bitmap.width;
			height = bitmap.height;
			layers.push(createGrid(null, width, height));
			// blocks - start with a full grid
			layers.push(createGrid(1, width, height));
			// game objects
			layers.push(createGrid(null, width, height));
			
			fill(0, 1, 0, width-2, height-1, layers[BLOCKS]);
			
			// create the boat
			fill(MapTileConverter.WALL, UNDERWORLD_BOAT_MIN, height - 2, UNDERWORLD_BOAT_MAX - UNDERWORLD_BOAT_MIN, 1, layers[BLOCKS]);
			setValue(UNDERWORLD_BOAT_MIN, height - 3, BLOCKS, MapTileConverter.WALL);
			setValue(UNDERWORLD_BOAT_MAX - 1, height - 3, BLOCKS, MapTileConverter.WALL);
			
			var portalXMLs:Array = game.content.getPortals(level, type);
			if(portalXMLs.length){
				setPortal(UNDERWORLD_PORTAL_X, height - 3, portalXMLs[0]);
			}
			
			// the player may have left content on the underworld as a sort of bank
			game.content.populateLevel(type, UNDERWORLD, bitmap, layers, random);
			
			// create sensors to resolve any contact with the waters
			var waterSensor:ColliderEntitySensor = new ColliderEntitySensor(
				new Rectangle(Game.SCALE, -3 + (height - 1) * Game.SCALE, (width - 2) * Game.SCALE, 3),
				underworldWaterCallback
			)
			
			// create death
			var deathCharacter:Stone = new Stone((UNDERWORLD_PORTAL_X - 3) * Game.SCALE, (height - 2) * Game.SCALE, Stone.DEATH);
			layers[ENTITIES][height - 2][UNDERWORLD_PORTAL_X - 3] = deathCharacter;
		}
		
		/* Resolves what happens to entities that fall in the water in the Underworld */
		public static function underworldWaterCallback(colliderEntity:ColliderEntity):void{
			if(colliderEntity is Item){
				renderer.createSparkRect(colliderEntity.collider, 20, 0, -1);
				colliderEntity.active = false;
			} else if(colliderEntity is Character){
				Effect.teleportCharacter(colliderEntity as Character, new Pixel(UNDERWORLD_PORTAL_X + 1, MapBitmap.UNDERWORLD_HEIGHT - 3));
			}
		}
		
		/* Creates an entry/exit point for the level - used to set stairs and portals generated by the portal rune */
		public function createAccessPoint(type:int, sort:Function = null, xml:XML = null):void{
			var index:int = 0;
			var rooms:Vector.<Room> = bitmap.rooms;
			if(Boolean(sort)) rooms.sort(sort);
			var portalRoom:Room = rooms[index];
			
			var r:int, c:int, pos:uint;
			var candidates:Vector.<Surface> = new Vector.<Surface>();
			var choice:Surface;
			var surface:Surface;
			var i:int;
			
			do{
				candidates.length = 0;
				for(i = 0; i < portalRoom.surfaces.length; i++){
					surface = portalRoom.surfaces[i];
					if(goodPortalPosition(surface.x, surface.y, random.value() < 0.2)){
						candidates.push(surface);
					}
				}
				if(candidates.length){
					choice = candidates[random.rangeInt(candidates.length)];
				} else {
					if(index == rooms.length - 1) throw new Error("failed to create portal");
					else {
						index++;
						portalRoom = rooms[index];
					}
				}
				
			} while(candidates.length == 0);
			
			if(type == Portal.STAIRS){
				if(sort == sortRoomsTopWards) setStairsUp(choice.x, choice.y);
				else if(sort == sortRoomsBottomWards) setStairsDown(choice.x, choice.y);
			} else {
				setPortal(choice.x, choice.y, xml);
			}
			
			Surface.removeSurface(choice.x, choice.y);
			
		}
		
		// room sorting callbacks
		public static function sortRoomsTopWards(a:Room, b:Room):Number{
			if(a.y < b.y) return -1;
			else if(a.y > b.y) return 1;
			return 0;
		}
		public static function sortRoomsBottomWards(a:Room, b:Room):Number{
			if(a.y > b.y) return -1;
			else if(a.y < b.y) return 1;
			return 0;
		}
		
		/* Creates a stairway up */
		public function setStairsUp(x:int, y:int):void{
			layers[ENTITIES][y][x] = MapTileConverter.STAIRS_UP;
			// prevent background decorator from creating graphics covering portals
			if(bitmap.bitmapData.getPixel32(x, y) == MapBitmap.EMPTY) bitmap.bitmapData.setPixel32(x, y, MapBitmap.GATE);
			stairsUp = new Pixel(x, y);
			if(isPortalToPreviousLevel(x, y, Portal.STAIRS, level - 1, level > 1 ? MAIN_DUNGEON : AREA)){
				start = stairsUp;
				if(Surface.map[y][x] && Surface.map[y][x].room) Surface.map[y][x].room.start = true;
			}
		}
		
		/* Creates a stairway down */
		public function setStairsDown(x:int, y:int):void{
			layers[ENTITIES][y][x] = MapTileConverter.STAIRS_DOWN;
			// prevent background decorator from creating graphics covering portals
			if(bitmap.bitmapData.getPixel32(x, y) == MapBitmap.EMPTY) bitmap.bitmapData.setPixel32(x, y, MapBitmap.GATE);
			stairsDown = new Pixel(x, y);
			if(isPortalToPreviousLevel(x, y, Portal.STAIRS, level + 1, MAIN_DUNGEON)){
				start = stairsDown;
				if(Surface.map[y][x] && Surface.map[y][x].room) Surface.map[y][x].room.start = true;
			}
		}
		
		/* Creates a portal */
		public function setPortal(x:int, y:int, xml:XML):void{
			var p:Pixel = new Pixel(x, y);
			var portal:Portal = Content.XMLToEntity(x, y, xml, level, type);
			game.portalHash[portal.hashKey] = portal;
			if(type == AREA){
				portal.maskPortalBase(level);
			}
			layers[ENTITIES][y][x] = portal;
			// prevent background decorator from creating graphics covering portals
			if(bitmap.bitmapData.getPixel32(x, y) == MapBitmap.EMPTY) bitmap.bitmapData.setPixel32(x, y, MapBitmap.GATE);
			if(isPortalToPreviousLevel(x, y, int(xml.@type), int(xml.@targetLevel), int(xml.@targetType))){
				start = p;
				if(Surface.map[y][x] && Surface.map[y][x].room) Surface.map[y][x].room.start = true;
			}
			portals.push(p);
		}
		
		/* Is this portal going to be the entry point for the level?
		 * 
		 * Map.start and Game.entrance are used by the game engine to set the camera and entry point for the level
		 * which is why this query belongs in a function to be called by various elements
		 * 
		 * The logic follows: does this portal lead to the last level you were on
		 * 
		 * This used to be a lot more complicated till I refactored portals */
		public static function isPortalToPreviousLevel(x:int, y:int, type:int, targetLevel:int, targetType:int):Boolean{
			return Player.previousPortalType == type && Player.previousLevel == targetLevel && Player.previousMapType == targetType;
		}
		
		/* Getting a good position for the portals is complex.
		 * We want clear spaces to each side and solid floor below - preferably walls below on stairs down
		 * we also don't want to appear next to another portal - portals have frilly edges
		 * - hence the mess in this method */
		public function goodPortalPosition(x:int, y:int, ledgeAllowed:Boolean = true):Boolean{
			var p:Pixel;
			for(var i:int = 0; i < portals.length; i++){
				p = portals[i];
				if(
					(p.x == x && (p.y == y || p.y == y - 1 || p.y == y + 1)) ||
					(p.y == y && (p.x == x || p.x == x - 1 || p.x == x + 1))
				){
					return false;
				}
			}
			if(stairsUp){
				p = stairsUp;
				if(
					(p.x == x && (p.y == y || p.y == y - 1 || p.y == y + 1)) ||
					(p.y == y && (p.x == x || p.x == x - 1 || p.x == x + 1))
				){
					return false;
				}
			}
			if(stairsDown){
				p = stairsDown;
				if(
					(p.x == x && (p.y == y || p.y == y - 1 || p.y == y + 1)) ||
					(p.y == y && (p.x == x || p.x == x - 1 || p.x == x + 1))
				){
					return false;
				}
			}
			var pos:uint = bitmap.bitmapData.getPixel32(x, y);
			var posAbove:uint = bitmap.bitmapData.getPixel32(x, y - 1);
			var posBelow:uint = bitmap.bitmapData.getPixel32(x, y + 1);
			var posLeft:uint =  bitmap.bitmapData.getPixel32(x - 1, y);
			var posRight:uint =  bitmap.bitmapData.getPixel32(x + 1, y);
			if(bitmap.leftSecretRoom && bitmap.leftSecretRoom.contains(x, y)) return false;
			if(bitmap.rightSecretRoom && bitmap.rightSecretRoom.contains(x, y)) return false;
			return (
				(posAbove != MapBitmap.WALL && posAbove != MapBitmap.GATE) &&
				(posLeft != MapBitmap.WALL && posRight != MapBitmap.WALL) &&
				(posLeft != MapBitmap.GATE && posRight != MapBitmap.GATE) &&
				(posLeft != MapBitmap.SECRET && posRight != MapBitmap.SECRET) &&
				(posBelow == MapBitmap.WALL || (posBelow == MapBitmap.LEDGE && ledgeAllowed)) &&
				(pos == MapBitmap.EMPTY || pos == MapBitmap.LEDGE)
			);
		}
		
		/* Adds critters to the level - decorative entites that squish on contact */
		public function createCritters():void{
			
			// the compiler won't let me create this as a constant so I have to drop it in here
			// better than resorting to magic numbers I suppose
			var ZONE_CRITTERS:Array = [
				[MapTileConverter.SPIDER, MapTileConverter.SPIDER, MapTileConverter.BAT, MapTileConverter.RAT],
				[MapTileConverter.RAT, MapTileConverter.RAT, MapTileConverter.RAT, MapTileConverter.RAT, MapTileConverter.SPIDER],
				[MapTileConverter.BAT, MapTileConverter.BAT, MapTileConverter.BAT, MapTileConverter.BAT, MapTileConverter.RAT, MapTileConverter.SPIDER],
				[MapTileConverter.COG, MapTileConverter.COG_RAT, MapTileConverter.COG_SPIDER, MapTileConverter.COG_BAT]
			];
			
			var critterPalette:Array = ZONE_CRITTERS[zone];
			var r:int, c:int, critterId:int;
			var critterNum:int = Math.sqrt(width * height) * 1.25;
			var breaker:int = 0;
			
			while(critterNum){
				
				r = 1 + random.range(bitmap.height - 1);
				c = 1 + random.range(bitmap.width - 1);
				critterId = critterPalette[random.rangeInt(critterPalette.length)];
				
				// may god forgive me for this if statement:
				if(
					!layers[ENTITIES][r][c] &&
					layers[BLOCKS][r][c] != 1 &&
					(
						(
							(
								critterId == MapTileConverter.RAT ||
								critterId == MapTileConverter.COG_RAT
							)&&
							(
								bitmap.bitmapData.getPixel32(c, r + 1) == MapBitmap.LEDGE ||
								bitmap.bitmapData.getPixel32(c, r + 1) == MapBitmap.LADDER_LEDGE ||
								layers[BLOCKS][r + 1][c] == MapTileConverter.WALL
							)
						) ||
						(
							(
								critterId == MapTileConverter.SPIDER ||
								critterId == MapTileConverter.BAT ||
								critterId == MapTileConverter.COG_SPIDER ||
								critterId == MapTileConverter.COG_BAT
							) &&
							(
								layers[BLOCKS][r - 1][c] == MapTileConverter.WALL &&
								bitmap.bitmapData.getPixel32(c, r - 1) != MapBitmap.PIT
							)
						) ||
						(
							critterId == MapTileConverter.COG &&
							(
								(
									layers[BLOCKS][r - 1][c] == MapTileConverter.WALL &&
									bitmap.bitmapData.getPixel32(c, r - 1) != MapBitmap.PIT
								) ||
								layers[BLOCKS][r + 1][c] == MapTileConverter.WALL ||
								layers[BLOCKS][r][c - 1] == MapTileConverter.WALL ||
								layers[BLOCKS][r][c + 1] == MapTileConverter.WALL
							)
						)
					)
				){
					layers[ENTITIES][r][c] = critterId;
					critterNum--;
				}
				if((breaker++) > 1000) break;
			}
		}
		
		/* Create barriers in the dungeon */
		public function createGates():void{
			
			// debug for repeating levels
			//trace(random.seed);
			
			var i:int, j:int, site:Pixel, n:int, entranceCol:uint, surface:Surface, gate:Gate, item:Item;
			var connections:BitmapData = bitmap.bitmapData.clone();
			connections.threshold(connections, connections.rect, new Point(), "!=", MapBitmap.WALL, 0xFF000000);
			var connectionsBuffer:BitmapData = connections.clone();
			var fragmented:Boolean = false;
			var connectionPixels:Vector.<uint>;
			var gateType:int;
			var checkCol:uint;
			var fragmentationSites:Vector.<Pixel> = new Vector.<Pixel>();
			
			// scrape for fragmentation sites
			for(i = bitmap.gates.length - 1; i > -1; i--){
				site = bitmap.gates[i];
				
				// nanny-condition, in a perfect world I won't have put an entity here
				if(!layers[ENTITIES][site.y][site.x]){
					
					// do a connectivity test
					connections.setPixel32(site.x, site.y, 0xFFFFFFFF);
					connections.floodFill(site.x + 1, site.y, 0xFF0000FF);
					connections.floodFill(site.x - 1, site.y, 0xFF00FF00);
					
					// fragmentation means a section of the dungeon will be hermetically
					// sealed from all manner of access (no dropping in, no teleport)
					if(connections.getColorBoundsRect(0xFFFFFFFF, 0xFF0000FF).width){
						fragmentationSites.push(site);
						bitmap.gates.splice(i, 1);
						
						//trace("fragmentation", site);
					}
					// revert to buffer
					connections = connectionsBuffer.clone();
				} else {
					bitmap.gates.splice(i, 1);
				}
			}
			
			if(fragmentationSites.length){
				site = fragmentationSites[random.rangeInt(fragmentationSites.length)];
				connections.setPixel32(site.x, site.y, 0xFFFFFFFF);
				connections.floodFill(site.x + 1, site.y, 0xFF0000FF);
				connections.floodFill(site.x - 1, site.y, 0xFF00FF00);
				
				// fragmentation debugging
				//var temp:Bitmap = new Bitmap(connections);
				//game.addChild(temp);
				
				// iterate through surfaces and mark them as connected to the entrance or not
				entranceCol = connections.getPixel32(start.x, start.y);
				connectionPixels = connections.getVector(connections.rect);
				for(j = 0; j < Surface.surfaces.length; j++){
					surface = Surface.surfaces[j];
					n = surface.x + surface.y * width;
					checkCol = connectionPixels[n];
					if(checkCol == entranceCol){
						surface.nearEntrance = true;
					}
				}
				
				// create a location for the key to the gate,
				// try not to put it next to the entrance or the gate
				var minDist:int = 10;
				var collapseMinDist:int = 100;
				do{
					surface = Surface.surfaces[random.rangeInt(Surface.surfaces.length)];
					if(collapseMinDist-- <= 0){
						collapseMinDist = 100;
						minDist--;
					}
				} while(
					!surface.nearEntrance ||
					layers[ENTITIES][surface.y][surface.x] ||
					(
						Math.abs(start.x - surface.x) < minDist &&
						Math.abs(start.y - surface.y) < minDist
					) ||
					(
						Math.abs(site.x - surface.x) < minDist &&
						Math.abs(site.y - surface.y) < minDist
					) ||
					!bitmap.adjustedMapRect.contains((surface.x + 0.5) * Game.SCALE, (surface.y + 0.5) * Game.SCALE)
				);
				
				// key
				var xml:XML =<item name={0} type={Item.KEY} level={0} />;
				item = Content.XMLToEntity(surface.x, surface.y, xml);
				item.dropToMap(surface.x, surface.y, false);
				layers[ENTITIES][surface.y][surface.x] = item;
				gateType = Gate.LOCK;
				Surface.removeSurface(surface.x, surface.y);
				
				// pressure pad
				
				// to do
				
				// an illustration of fragmentation needs to be saved for Effect.teleportCharacter
				// and for wall walkers that change race inside a locked area
				Surface.fragmentationMap = connections;
				Surface.entranceCol = entranceCol;
				
				gateType = Gate.LOCK;
				gate = new Gate(site.x * Game.SCALE, site.y * Game.SCALE, gateType);
				gate.mapX = site.x;
				gate.mapY = site.y;
				gate.mapZ = MapTileManager.ENTITY_LAYER;
				layers[ENTITIES][site.y][site.x] = gate;
				Surface.removeSurface(site.x, site.y);
			}
			
			// pick a random normal site for a raise gate or chaos gate
			if(bitmap.gates.length){
				i = -1 + random.rangeInt(4);
				while(i-- > 0){
					site = bitmap.gates[random.rangeInt(bitmap.gates.length)];
					if(layers[ENTITIES][site.y][site.x]) continue;
					if(zone == CHAOS) gateType = random.coinFlip() ? Gate.CHAOS : Gate.RAISE;
					else gateType = Gate.RAISE;
					gate = new Gate(site.x * Game.SCALE, site.y * Game.SCALE, gateType);
					gate.mapX = site.x;
					gate.mapY = site.y;
					gate.mapZ = MapTileManager.ENTITY_LAYER;
					layers[ENTITIES][site.y][site.x] = gate;
					Surface.removeSurface(site.x, site.y);
				}
			}
		}
		
		/* Generate patches of readable text */
		public function createWritings(pixels:Vector.<uint>):void{
			
			Writing.writings = new Vector.<Writing>();
			
			var i:int, n:int;
			var surface:Surface, writing:Writing;
			
			var range:int = (height - 1) * width - 1;
			var candidates:Vector.<Surface> = new Vector.<Surface>();
			
			for(i = 0; i < Surface.surfaces.length; i++){
				surface = Surface.surfaces[i];
				if(surface.properties == (Collider.SOLID | Collider.WALL)){
					n = surface.x + surface.y * width;
					if(
						n > width + 1 && n < range &&
						(pixels[n + (width + 1)] == MapBitmap.WALL || pixels[n + (width + 1)] == MapBitmap.LEDGE) &&
						(pixels[n + width] == MapBitmap.WALL || pixels[n + width] == MapBitmap.LEDGE) &&
						(pixels[n + (width - 1)] == MapBitmap.WALL || pixels[n + (width - 1)] == MapBitmap.LEDGE) &&
						pixels[n] == MapBitmap.EMPTY &&
						pixels[n - 1] == MapBitmap.EMPTY &&
						pixels[n + 1] == MapBitmap.EMPTY &&
						Surface.map[surface.y][surface.x - 1] &&
						Surface.map[surface.y][surface.x + 1]
					){
						candidates.push(surface);
					}	
				}
			}
			//trace("candidates", candidates.length);
			if(candidates.length){
				
				var index:int;
				var writings:int = 1 + random.rangeInt(3);
				//trace("writings", writings);
				var level:int = this.level - 1;
				
				// randomise selections
				var selection:Array = [];
				var levelArray:Array = Writing.story[level];
				for(i = 0; i < levelArray.length; i++){
					selection.push(i);
				}
				randomiseArray(selection, random);
				while((writings--) && selection.length && candidates.length){
					n = random.rangeInt(candidates.length);
					surface = candidates[n];
					candidates.splice(n, 1);
					i = surface.x + surface.y * width;
					if(
						pixels[i] == MapBitmap.EMPTY &&
						pixels[i + 1] == MapBitmap.EMPTY &&
						pixels[i - 1] == MapBitmap.EMPTY
					){
						index = selection.pop();
						writing = new Writing(surface.x, surface.y, levelArray[index], level, index);
						writing.mapZ = MapTileManager.ENTITY_LAYER;
						layers[ENTITIES][surface.y][surface.x] = writing;
						Surface.removeSurface(surface.x, surface.y);
						// hack to avoid over writing
						pixels[i] = MapBitmap.GATE;
						pixels[i + 1] = MapBitmap.GATE;
						pixels[i - 1] = MapBitmap.GATE;
					}
				}
			}
		}
		
		/* Generate slot machines */
		public function createAltars(pixels:Vector.<uint>):void{
			
			var totalAltars:int = game.content.getAltars(level, type);
			if(totalAltars <= 0) return;
			
			var i:int, n:int;
			var surface:Surface, altar:Altar;
			
			var range:int = (height - 1) * width - 1;
			var candidates:Vector.<Surface> = new Vector.<Surface>();
			
			for(i = 0; i < Surface.surfaces.length; i++){
				surface = Surface.surfaces[i];
				if(surface.properties == (Collider.SOLID | Collider.WALL)){
					n = surface.x + surface.y * width;
					if(
						n > width + 1 && n < range &&
						(pixels[n + (width + 1)] == MapBitmap.WALL || pixels[n + (width + 1)] == MapBitmap.LEDGE) &&
						(pixels[n + width] == MapBitmap.WALL || pixels[n + width] == MapBitmap.LEDGE) &&
						(pixels[n + (width - 1)] == MapBitmap.WALL || pixels[n + (width - 1)] == MapBitmap.LEDGE) &&
						pixels[n] == MapBitmap.EMPTY &&
						pixels[n - 1] == MapBitmap.EMPTY &&
						pixels[n + 1] == MapBitmap.EMPTY &&
						Surface.map[surface.y][surface.x - 1] &&
						Surface.map[surface.y][surface.x + 1]
					){
						candidates.push(surface);
					}	
				}
			}
			//trace("candidates", candidates.length);
			if(candidates.length){
				
				while((totalAltars--) &&  candidates.length){
					n = random.rangeInt(candidates.length);
					surface = candidates[n];
					candidates.splice(n, 1);
					i = surface.x + surface.y * width;
					if(
						pixels[i] == MapBitmap.EMPTY &&
						pixels[i + 1] == MapBitmap.EMPTY &&
						pixels[i - 1] == MapBitmap.EMPTY &&
						!layers[ENTITIES][surface.y][surface.x + 1] &&
						!layers[ENTITIES][surface.y][surface.x - 1]
					){
						altar = new Altar(new AltarMC, surface.x, surface.y);
						layers[ENTITIES][surface.y][surface.x] = altar;
						Surface.removeSurface(surface.x, surface.y);
					}
				}
			}
		}
		
		/* Create lights in the dungeon */
		public function createTorches(pixels:Vector.<uint>):void{
			var i:int, n:int, room:Room, surface:Surface, torch:Torch;
			for(i = 0; i < bitmap.rooms.length; i++){
				room = bitmap.rooms[i];
				if(room.surfaces.length){
					surface = room.surfaces[random.rangeInt(room.surfaces.length)];
					n = surface.x + surface.y * width;
					if(
						pixels[n] == MapBitmap.EMPTY &&
						!layers[ENTITIES][surface.y][surface.x]
					){
						torch = new Torch(new TorchMC, surface.x, surface.y);
						layers[ENTITIES][surface.y][surface.x] = torch;
						Surface.removeSurface(surface.x, surface.y);
					}
				}
			}
		}
		
		/* Generate decorative background graphics */
		public function createDecor(pixels:Vector.<uint>):void{
			
			var pixel:uint, i:int, n:int, r:int, c:int, good:Boolean, type:String;
			
			for(i = width; i < pixels.length - width; i++){
				pixel = pixels[i];
				if(pixel == MapBitmap.EMPTY){
					r = i / width;
					c = i % width;
					// pillar, chain, recess
					if(zone == DUNGEONS){
						// pillar / chain
						if(pixels[i - width] == MapBitmap.WALL && random.value() < 0.4){
							// single pillars spawn very easily, so they need to be reduced in popularity
							if(pixels[i + width] == MapBitmap.WALL && random.value() < 0.4){
								layers[BACKGROUND][r][c] = random.coinFlip() ? MapTileConverter.PILLAR_SINGLE1 : MapTileConverter.PILLAR_SINGLE2;
							} else if(pixels[i + width] == MapBitmap.EMPTY){
								// test for pillar or chain
								good = true;
								for(n = i + width; n < pixels.length; n += width){
									if(pixels[n] != MapBitmap.EMPTY){
										if(pixels[n] == MapBitmap.WALL || pixels[n] == MapBitmap.LEDGE){
											if(pixels[n] == MapBitmap.WALL) type = "pillar";
											else if(pixels[n] == MapBitmap.LEDGE) type = "chain";
											n -= width;
										} else {
											good = false;
										}
										break;
									}
								}
								if(good){
									// choose pillar or chain
									if(type == "pillar"){
										layers[BACKGROUND][r][c] = MapTileConverter.PILLAR_TOP;
										r = n / width;
										c = n % width;
										layers[BACKGROUND][r][c] = MapTileConverter.PILLAR_BOTTOM;
										for(n -= width; n > i; n -= width){
											r = n / width;
											c = n % width;
											layers[BACKGROUND][r][c] = random.coinFlip() ? MapTileConverter.PILLAR_MID1 : MapTileConverter.PILLAR_MID2;
										}
									} else if(type == "chain"){
										layers[BACKGROUND][r][c] = MapTileConverter.CHAIN_TOP;
										r = n / width;
										c = n % width;
										layers[BACKGROUND][r][c] = MapTileConverter.CHAIN_BOTTOM;
										for(n -= width; n > i; n -= width){
											r = n / width;
											c = n % width;
											layers[BACKGROUND][r][c] = MapTileConverter.CHAIN_MID;
										}
									}
								}
							}
						// skull
						} else if((pixels[i + width] == MapBitmap.WALL || pixels[i + width] == MapBitmap.LEDGE) && random.value() < 0.01 && !layers[BACKGROUND][r][c]){
							layers[BACKGROUND][r][c] = MapTileConverter.SKULL;
							
						// recess (avoid putting a recess above a portal)
						} else if(random.value() < 0.05 && !layers[BACKGROUND][r][c] && pixels[i + width] != MapBitmap.GATE){
							layers[BACKGROUND][r][c] = MapTileConverter.RECESS;
						}
						
					// outlet, drain
					} else if(zone == SEWERS){
						// skull
						if((pixels[i + width] == MapBitmap.WALL || pixels[i + width] == MapBitmap.LEDGE) && random.value() < 0.01){
							layers[BACKGROUND][r][c] = MapTileConverter.SKULL;
							
						// drain
						} else if(pixels[i + width] == MapBitmap.WALL && random.value() < 0.05){
							layers[BACKGROUND][r][c] = MapTileConverter.DRAIN;
							
						// outlet
						} else if(pixels[i - width] == MapBitmap.WALL && random.value() < 0.05){
							layers[BACKGROUND][r][c] = MapTileConverter.OUTLET;
						}
					// stalagmite, crack
					} else if(zone == CAVES){
						// crack
						if(random.value() < 0.01 && !layers[BACKGROUND][r][c]){
							layers[BACKGROUND][r][c] = [MapTileConverter.CRACK1, MapTileConverter.CRACK2, MapTileConverter.CRACK3][game.random.rangeInt(3)];
							
						// skull
						} else if((pixels[i + width] == MapBitmap.WALL || pixels[i + width] == MapBitmap.LEDGE) && random.value() < 0.01){
							layers[BACKGROUND][r][c] = MapTileConverter.SKULL;
							
						// stalagmite
						} else if(pixels[i + width] == MapBitmap.WALL && random.value() < 0.4){
							layers[BACKGROUND][r][c] = [MapTileConverter.STALAGMITE1, MapTileConverter.STALAGMITE2, MapTileConverter.STALAGMITE3, MapTileConverter.STALAGMITE4][game.random.rangeInt(4)];
							
						// stalagtite
						} else if(pixels[i - width] == MapBitmap.WALL && random.value() < 0.4){
							layers[BACKGROUND][r][c] = [MapTileConverter.STALAGTITE1, MapTileConverter.STALAGTITE2, MapTileConverter.STALAGTITE3, MapTileConverter.STALAGTITE4][game.random.rangeInt(4)];
						}
						
					// growth
					} else if(zone == CHAOS){
						// skull
						if((pixels[i + width] == MapBitmap.WALL || pixels[i + width] == MapBitmap.LEDGE) && random.value() < 0.01){
							layers[BACKGROUND][r][c] = MapTileConverter.SKULL;
							
						// growth up
						} else if(pixels[i + width] == MapBitmap.WALL && random.value() < 0.5){
							layers[BACKGROUND][r][c] = [MapTileConverter.GROWTH1, MapTileConverter.GROWTH2, MapTileConverter.GROWTH3, MapTileConverter.GROWTH4, MapTileConverter.GROWTH5, MapTileConverter.GROWTH6][game.random.rangeInt(6)];
							
						// growth down
						} else if(pixels[i - width] == MapBitmap.WALL && random.value() < 0.5){
							layers[BACKGROUND][r][c] = [MapTileConverter.GROWTH7, MapTileConverter.GROWTH8, MapTileConverter.GROWTH9, MapTileConverter.GROWTH10, MapTileConverter.GROWTH11, MapTileConverter.GROWTH12][game.random.rangeInt(6)];
						}
					}
				}
			}
			// put stairs in background to over print decor
			if(stairsUp) layers[BACKGROUND][stairsUp.y][stairsUp.x] = MapTileConverter.STAIRS_UP_GFX;
			if(stairsDown) layers[BACKGROUND][stairsDown.y][stairsDown.x] = MapTileConverter.STAIRS_DOWN_GFX;
		}
		
		/* Sprinkle on some chaos walls to make exploring weirder */
		public function createChaosWalls(pixels:Vector.<uint>):void{
			ChaosWall.init(width, height);
			
			// we only put chaos walls in corridors, so we need a stretch of three wall blocks to
			// either side of the chaos wall
			var i:int, r:int, c:int, n:int;
			for(i = width; i < pixels.length - width; i++){
				c = i % width;
				r = i / width;
				if(c > 0 && c < width - 1 && pixels[i] == MapBitmap.EMPTY){
					if(zone == CHAOS && !layers[ENTITIES][r][c] && !layers[BLOCKS][r][c] && random.value() < 0.4){
						if(pixels[i + width] == MapBitmap.WALL){
							n = i;
							while(n > width && pixels[n] == MapBitmap.EMPTY && !layers[ENTITIES][r][c] && !layers[BLOCKS][r][c]){
								layers[ENTITIES][r][c] = new ChaosWall(c, r);
								layers[BLOCKS][r][c] = MapTileConverter.WALL;
								n -= width;
								r = n / width;
							}
						}
						if(pixels[i - width] == MapBitmap.WALL){
							n = i;
							while(n < pixels.length - width && pixels[n] == MapBitmap.EMPTY && !layers[ENTITIES][r][c] && !layers[BLOCKS][r][c]){
								layers[ENTITIES][r][c] = new ChaosWall(c, r);
								layers[BLOCKS][r][c] = MapTileConverter.WALL;
								n += width;
								r = n / width;
							}
						}
						if(pixels[i - 1] == MapBitmap.WALL){
							n = i;
							while(n < pixels.length - width && pixels[n] == MapBitmap.EMPTY && !layers[ENTITIES][r][c] && !layers[BLOCKS][r][c]){
								layers[ENTITIES][r][c] = new ChaosWall(c, r);
								layers[BLOCKS][r][c] = MapTileConverter.WALL;
								n++;
								c = n % width;
							}
						}
						if(pixels[i + 1] == MapBitmap.WALL){
							n = i;
							while(n > width && pixels[n] == MapBitmap.EMPTY && !layers[ENTITIES][r][c] && !layers[BLOCKS][r][c]){
								layers[ENTITIES][r][c] = new ChaosWall(c, r);
								layers[BLOCKS][r][c] = MapTileConverter.WALL;
								n--;
								c = n % width;
							}
						}
					} else {
						if(
							// horizontal corridor
							(
								pixels[(i - width) - 1] == MapBitmap.WALL && 
								pixels[i - width] == MapBitmap.WALL && 
								pixels[(i - width) + 1] == MapBitmap.WALL && 
								pixels[(i + width) - 1] == MapBitmap.WALL && 
								pixels[i + width] == MapBitmap.WALL && 
								pixels[(i + width) + 1] == MapBitmap.WALL
							) ||
							// vertical corridor
							(
								pixels[(i - width) - 1] == MapBitmap.WALL && 
								pixels[i - 1] == MapBitmap.WALL && 
								pixels[(i + width) - 1] == MapBitmap.WALL && 
								pixels[(i - width) + 1] == MapBitmap.WALL && 
								pixels[i + 1] == MapBitmap.WALL && 
								pixels[(i + width) + 1] == MapBitmap.WALL
							)
						){
							if(random.value() < 0.4 && !layers[ENTITIES][r][c] && !layers[BLOCKS][r][c]){
							//if(!layers[ENTITIES][r][c]){
								layers[ENTITIES][r][c] = new ChaosWall(c, r);
								layers[BLOCKS][r][c] = MapTileConverter.WALL;
							}
						}
					}
				}
			}
		}
		
		/* This adds traps other than pit traps to the level */
		public function createOtherTraps(pixels:Vector.<uint>):void{
			
			// TRAPS BY ZONE
			
			// All zones have pit traps
			
			// the compiler won't let me create this as a constant so I have to drop it in here
			// better than resorting to magic numbers I suppose
			var ZONE_TRAPS:Array = [
				[Trap.TELEPORT_DART],
				[Trap.STUN_MUSHROOM, Trap.TELEPORT_DART, Trap.CONFUSION_MUSHROOM],
				[Trap.STUN_MUSHROOM, Trap.BLEED_DART, Trap.CONFUSION_MUSHROOM, Trap.FEAR_MUSHROOM],
				[Trap.MONSTER_PORTAL, Trap.STUN_MUSHROOM, Trap.BLEED_DART, Trap.TELEPORT_DART, Trap.CONFUSION_MUSHROOM, Trap.FEAR_MUSHROOM]
			];
			
			var totalTraps:int = game.content.getTraps(level, type) - bitmap.pitTraps;
			completionCount += totalTraps;
			if(totalTraps == 0) return;
			
			var dartPos:Pixel;
			var trapPositions:Vector.<Surface> = new Vector.<Surface>();
			var surface:Surface;
			var mapWidth:int = bitmap.bitmapData.width;
			var n:int;
			
			for(i = 0; i < Surface.surfaces.length; i++){
				surface = Surface.surfaces[i];
				if(surface.properties == (Collider.SOLID | Collider.WALL)){
					if(layers[ENTITIES][surface.y][surface.x]) continue;
					for(j = surface.x + surface.y * mapWidth; j > mapWidth; j -= mapWidth){
						// no combining ladders or pit traps with dart traps
						// it confuses the trap and it's unfair to have to climb a ladder into a dart
						if(pixels[j] == MapBitmap.LADDER || pixels[j] == MapBitmap.LADDER_LEDGE || pixels[j] == MapBitmap.PIT){
							break;
						} else if(pixels[j] == MapBitmap.WALL){
							trapPositions.push(surface);
							break;
						}
					}
				}
			}
			
			var trapIndex:int, trapPos:Surface, trapType:int, sprite:Sprite, trap:Trap;
			
			while(totalTraps > 0 && trapPositions.length > 0){
				trapIndex = random.range(trapPositions.length);
				trapPos = trapPositions[trapIndex];
				trapType = ZONE_TRAPS[zone][random.rangeInt(ZONE_TRAPS[zone].length)];
				sprite = new Sprite();
				sprite.x = trapPos.x * Game.SCALE;
				sprite.y = (trapPos.y + 1) * Game.SCALE;
				if(trapType != Trap.MONSTER_PORTAL){
					// get dart gun position
					dartPos = trapPos.copy();
					while(pixels[dartPos.x + dartPos.y * width] != MapBitmap.WALL){
						dartPos.y--;
					}
				} else {
					dartPos = null;
				}
				trap = new Trap(sprite, trapPos.x, trapPos.y + 1, trapType, dartPos);
				trap.mapX = trapPos.x;
				trap.mapY = trapPos.y + 1;
				trap.mapZ = MapTileManager.ENTITY_LAYER;
				layers[ENTITIES][trapPos.y + 1][trapPos.x] = trap;
				trapPositions.splice(trapIndex, 1);
				Surface.removeSurface(trapPos.x, trapPos.y);
				totalTraps--;
			}
		}
		
		/* Debugging or set-piece method */
		public function createCharacter(x:int, y:int, name:int, level:int):void{
			var characterXML:XML = <character />;
			characterXML.@name = name;
			characterXML.@type = Character.MONSTER;
			characterXML.@level = level;
			layers[ENTITIES][y][x] = Content.XMLToEntity(x, y, characterXML);
		}
		
		public function setValue(x:int, y:int, z:int, value:*):void{
			layers[z][y][x] = value;
		}
		
		public function getValue(x:int, y:int, z:int):*{
			return layers[z][y][x];
		}
		
		/* Creates a secret wall that can be broken through */
		public function createSecretWall(x:int, y:int):void{
			var side:int;
			if(x > width * 0.5) side = Collider.RIGHT;
			else side = Collider.LEFT;
			var wall:Stone = new Stone(x * Game.SCALE, y * Game.SCALE, Stone.SECRET_WALL, side);
			wall.mapX = x;
			wall.mapY = y;
			wall.mapZ = MapTileManager.ENTITY_LAYER;
			layers[ENTITIES][y][x] = wall;
			completionCount++;
		}
		
		/* Creates a pit trap */
		public function createPitTrap(x:int, y:int):void{
			var sprite:Sprite = new Sprite();
			sprite.x = x * Game.SCALE;
			sprite.y = y * Game.SCALE;
			var trap:Trap = new Trap(sprite, x, y, Trap.PIT);
			trap.mapX = x;
			trap.mapY = y;
			trap.mapZ = MapTileManager.ENTITY_LAYER;
			layers[ENTITIES][y][x] = trap;
			completionCount++;
		}
		
		/* Used to clear out a section of a grid or flood it with a particular tile type */
		public function fill(index:int, x:int, y:int, width:int, height:int, grid:Array):void{
			var r:int, c:int;
			for(r = y; r < y + height; r++){
				for(c = x; c < x + width; c++){
					grid[r][c] = index;
				}
			}
		}
		
		/* Creates a random parallax background */
		public function createBackground():void{
			var bitmapData:BitmapData;
			if(type == AREA){
				var bitmap:Bitmap;
				if(level == OVERWORLD){
					bitmap = new game.library.OverworldB;
					bitmapData = bitmap.bitmapData;
				} else if(level == UNDERWORLD){
					bitmap = new game.library.UnderworldB;
					bitmapData = bitmap.bitmapData;
				}
			} else {
				bitmapData = new BitmapData(Game.SCALE * BACKGROUND_WIDTH, Game.SCALE * BACKGROUND_HEIGHT, true, 0x0);
				var source:BitmapData;
				var point:Point = new Point();
				var x:int, y:int;
				for(y = 0; y < BACKGROUND_HEIGHT * 0.5; y ++){
					for(x = 0; x < BACKGROUND_WIDTH * 0.5; x ++){
						source = renderer.zoneBackgroundBitmaps[zone][random.rangeInt(renderer.zoneBackgroundBitmaps[zone].length)].bitmapData;
						point.x = x * Game.SCALE * 2;
						point.y = y * Game.SCALE * 2;
						bitmapData.copyPixels(source, source.rect, point);
						
						//debugging
						//bitmapData.fillRect(new Rectangle(point.x, point.y, Game.SCALE, Game.SCALE), 0xFF000000 + game.random.rangeInt(uint.MAX_VALUE - 0xFF000000));
						//bitmapData.fillRect(new Rectangle(point.x + Game.SCALE, point.y, Game.SCALE, Game.SCALE), 0xFF000000 + game.random.rangeInt(uint.MAX_VALUE - 0xFF000000));
						//bitmapData.fillRect(new Rectangle(point.x, point.y + Game.SCALE, Game.SCALE, Game.SCALE), 0xFF000000 + game.random.rangeInt(uint.MAX_VALUE - 0xFF000000));
						//bitmapData.fillRect(new Rectangle(point.x + Game.SCALE, point.y + Game.SCALE, Game.SCALE, Game.SCALE), 0xFF000000 + game.random.rangeInt(uint.MAX_VALUE - 0xFF000000));
					}
				}
				if(zone == SEWERS) createPipes(bitmapData);
			}
			renderer.backgroundBitmapData = bitmapData;
		}
		
		/* Create a maze of pipes on the background tiled image */
		public function createPipes(bitmapData:BitmapData):void{
			var pipeMap:Vector.<Vector.<int>> = new Vector.<Vector.<int>>();
			var r:int, c:int, x:int, y:int;
			for(r = 0; r < BACKGROUND_WIDTH; r++){
				pipeMap[r] = new Vector.<int>();
				for(c = 0; c < BACKGROUND_HEIGHT; c++){
					pipeMap[r][c] = 0;
				}
			}
			var i:int, dir:int, turnDelay:int, newDir:int;
			for(i = 0; i < 3; i++){
				dir = 1 << random.rangeInt(4);
				turnDelay = random.range(4) + 2;
				if(dir == Collider.UP){
					x = random.range(BACKGROUND_WIDTH);
					y = BACKGROUND_HEIGHT - 1;
				} else if(dir == Collider.RIGHT) {
					x = 0;
					y = random.range(BACKGROUND_HEIGHT);
				} else if(dir == Collider.DOWN){
					x = random.range(BACKGROUND_WIDTH);
					y = 0;
				} else if(dir == Collider.LEFT){
					x = BACKGROUND_WIDTH - 1;
					y = random.range(BACKGROUND_HEIGHT);
				}
				while(true){
					// lay pipe
					if(!pipeMap[y][x]){
						if(dir & (Collider.RIGHT | Collider.LEFT)){
							pipeMap[y][x] |= Collider.RIGHT | Collider.LEFT;
						} else if(dir & (Collider.DOWN | Collider.UP)){
							pipeMap[y][x] |= Collider.DOWN | Collider.UP;
						}
					} else {
						if(dir == Collider.UP) pipeMap[y][x] |= Collider.DOWN;
						else if(dir == Collider.RIGHT) pipeMap[y][x] |= Collider.LEFT;
						else if(dir == Collider.DOWN) pipeMap[y][x] |= Collider.UP;
						else if(dir == Collider.LEFT) pipeMap[y][x] |= Collider.RIGHT;
						break;
					}
					// move agent
					if(turnDelay-- <= 0){
						turnDelay = random.range(4) + 2;
						if(dir & (Collider.LEFT | Collider.RIGHT)) newDir = random.coinFlip() ? Collider.UP : Collider.DOWN;
						else if(dir & (Collider.UP | Collider.DOWN)) newDir = random.coinFlip() ? Collider.RIGHT : Collider.LEFT;
						// bend current pipe tile
						pipeMap[y][x] &= ~dir;
						pipeMap[y][x] |= newDir;
						dir = newDir;
					}
					if(dir == Collider.UP){
						y--;
						if(y < 0) y = BACKGROUND_HEIGHT - 1;
					} else if(dir == Collider.RIGHT){
						x++;
						if(x >= BACKGROUND_WIDTH) x = 0;
					} else if(dir == Collider.DOWN){
						y++;
						if(y >= BACKGROUND_HEIGHT) y = 0;
					} else if(dir == Collider.LEFT){
						x--;
						if(x < 0) x = BACKGROUND_WIDTH - 1;
					}
				}
			}
			// tidy up disconnected pipes
			for(r = 0; r < BACKGROUND_HEIGHT; r++){
				if(pipeMap[r][0] & Collider.LEFT){
					c = BACKGROUND_WIDTH - 1;
					while(c > -1){
						if(pipeMap[r][c]){
							pipeMap[r][c] |= Collider.RIGHT;
							break;
						} else {
							pipeMap[r][c] |= Collider.LEFT | Collider.RIGHT;
						}
						c--;
					}
				}
				if(pipeMap[r][BACKGROUND_WIDTH - 1] & Collider.RIGHT){
					c = 0;
					while(c < BACKGROUND_WIDTH){
						if(pipeMap[r][c]){
							pipeMap[r][c] |= Collider.LEFT;
							break;
						} else {
							pipeMap[r][c] |= Collider.LEFT | Collider.RIGHT;
						}
						c++;
					}
				}
			}
			for(c = 0; c < BACKGROUND_WIDTH; c++){
				if(pipeMap[0][c] & Collider.UP){
					r = BACKGROUND_HEIGHT - 1;
					while(r > -1){
						if(pipeMap[r][c]){
							pipeMap[r][c] |= Collider.DOWN;
							break;
						} else {
							pipeMap[r][c] |= Collider.UP | Collider.DOWN;
						}
						r--;
					}
				}
				if(pipeMap[BACKGROUND_HEIGHT - 1][c] & Collider.DOWN){
					r = 0;
					while(r < BACKGROUND_HEIGHT){
						if(pipeMap[r][c]){
							pipeMap[r][c] |= Collider.UP;
							break;
						} else {
							pipeMap[r][c] |= Collider.UP | Collider.DOWN;
						}
						r++;
					}
				}
			}
			
			var blit:BlitSprite;
			for(r = 0; r < BACKGROUND_HEIGHT; r++){
				for(c = 0; c < BACKGROUND_WIDTH; c++){
					if(pipeMap[r][c]){
						i = MapTileConverter.getPipeTileIndex(pipeMap[r][c]);
						blit = MapTileConverter.ID_TO_GRAPHIC[i];
						blit.x = c * Game.SCALE;
						blit.y = r * Game.SCALE;
						blit.render(bitmapData);
					}
				}
			}
			
			//var bitmap:Bitmap = new Bitmap(bitmapData);
			//game.addChild(bitmap);
		}
		
		public static function createGrid(base:*, width:int, height:int):Array {
			var r:int, c:int, a:Array = [];
			for(r = 0; r < height; r++) {
				a.push([]);
				for(c = 0; c < width; c++) {
					a[r].push(base);
				}
			}
			return a;
		}
		
		/* is this pixel sitting on the edge of the map? it will likely cause me trouble if it is... */
		public static function onEdge(pixel:Pixel, width:int, height:int):Boolean{
			return pixel.x<= 0 || pixel.x >= width-1 || pixel.y <= 0 || pixel.y >= height-1;
		}
		
		/* All of the levels have names, either being a subset of a zone or a specific area */
		public static function getName(level:int, type:int):String{
			if(type == MAIN_DUNGEON){
				var zone:int = game.content.getLevelZone(level);
				return ZONE_NAMES[zone];
			} else if(type == AREA){
				if(level == OVERWORLD) return "overworld";
				else if(level == UNDERWORLD) return "underworld";
			} else if(type == ITEM_DUNGEON){
				return "pocket";
			}
			return "";
		}
	}
	
}