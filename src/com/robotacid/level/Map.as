package com.robotacid.level {
	import com.robotacid.engine.ChaosWall;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.ColliderEntity;
	import com.robotacid.engine.ColliderEntitySensor;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Gate;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.MapTileConverter;
	import com.robotacid.engine.MapTileManager;
	import com.robotacid.engine.Player;
	import com.robotacid.engine.Portal;
	import com.robotacid.engine.Stone;
	import com.robotacid.engine.Trap;
	import com.robotacid.geom.Pixel;
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
		
		public static const LEVELS_PER_ZONE:int = 5;
		public static const ZONE_TOTAL:int = 4;
		
		public static const ZONE_NAMES:Vector.<String> = Vector.<String>(["dungeons", "sewers", "caves", "chaos"]);
		
		public function Map(level:int, type:int = MAIN_DUNGEON) {
			this.level = level;
			this.type = type;
			completionCount = completionTotal = 0;
			layers = [];
			portals = new Vector.<Pixel>();
			if(type == MAIN_DUNGEON || type == ITEM_DUNGEON){
				zone = (level - 1) / LEVELS_PER_ZONE;
				if(zone >= ZONE_TOTAL) zone = ZONE_TOTAL - 1;
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
			setPortal((width * 0.5) >> 0, height - 2, <portal type={Portal.ITEM_RETURN} targetLevel={-1} />);
			start = portals[0];
			
			// set zone for background debugging
			zone = (game.menu.editorList.dungeonLevelList.selection) / LEVELS_PER_ZONE;
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
			var portalXMLs:Vector.<XML> = game.content.getPortals(level, type);
			var portalType:int;
			if(type == MAIN_DUNGEON){
				createAccessPoint(Portal.STAIRS, sortRoomsTopWards);
				for(i = 0; i < portalXMLs.length; i++){
					portalType = portalXMLs[i].@type;
					createAccessPoint(portalType, null, portalXMLs[i]);
				}
				createAccessPoint(Portal.STAIRS, sortRoomsBottomWards);
			
				// a good dungeon needs to be full of loot and monsters
				// in comes the content manager to mete out a decent amount of action and reward per level
				// content manager stocks are limited to avoid scumming
				completionCount += game.content.populateLevel(type, level, bitmap, layers);
				
			} else if(type == ITEM_DUNGEON){
				portalType = portalXMLs[0].@type;
				createAccessPoint(portalType, sortRoomsTopWards, portalXMLs[0]);
				completionCount += game.content.populateLevel(type, level, bitmap, layers);
			}
			
			// now add some flavour
			if(bitmap.gates.length) createGates();
			createChaosWalls(pixels);
			createOtherTraps();
			createCritters();
			
			completionTotal = completionCount;
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
			
			var portalXMLs:Vector.<XML> = game.content.getPortals(level, type);
			if(portalXMLs.length){
				// given that there can only be one type of portal on the overworld - the rogue's portal
				// we create the rogue's portal here
				setPortal(17, height - 2, portalXMLs[0]);
			}
			
			setStairsDown(12, height - 2);
			
			// the player may have left content on the overworld as a sort of bank
			game.content.populateLevel(type, 0, bitmap, layers);
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
			
			var portalXMLs:Vector.<XML> = game.content.getPortals(level, type);
			if(portalXMLs.length){
				setPortal(UNDERWORLD_PORTAL_X, height - 3, portalXMLs[0]);
			}
			
			// the player may have left content on the underworld as a sort of bank
			game.content.populateLevel(type, 0, bitmap, layers);
			
			// create sensors to resolve any contact with the waters
			var waterSensor:ColliderEntitySensor = new ColliderEntitySensor(
				new Rectangle(Game.SCALE, -3 + (height - 1) * Game.SCALE, (width - 2) * Game.SCALE, 3),
				underworldWaterCallback
			)
			
			// create death
			layers[ENTITIES][height - 2][UNDERWORLD_PORTAL_X - 3] = new Stone((UNDERWORLD_PORTAL_X - 3) * Game.SCALE, (height - 2) * Game.SCALE, Stone.DEATH);
		}
		
		/* Resolves what happens to entities that fall in the water in the Underworld */
		public static function underworldWaterCallback(colliderEntity:ColliderEntity):void{
			if(colliderEntity is Item){
				renderer.createTeleportSparkRect(colliderEntity.collider, 20);
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
			var candidates:Vector.<Pixel> = new Vector.<Pixel>();
			var choice:Pixel;
			
			do{
				candidates.length = 0;
				for(c = portalRoom.x; c < portalRoom.x + portalRoom.width; c++){
					r = portalRoom.y - 1;
					do{
						r++;
						pos = bitmap.bitmapData.getPixel32(c, r);
					} while(pos != MapBitmap.WALL && r < portalRoom.y + portalRoom.height * 2);
					r--;
					if(goodPortalPosition(c, r, random.value() < 0.3)) candidates.push(new Pixel(c, r));
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
		}
		
		// room sorting callbacks
		private function sortRoomsTopWards(a:Room, b:Room):Number{
			if(a.y < b.y) return -1;
			else if(a.y > b.y) return 1;
			return 0;
		}
		private function sortRoomsBottomWards(a:Room, b:Room):Number{
			if(a.y > b.y) return -1;
			else if(a.y < b.y) return 1;
			return 0;
		}
		
		/* Creates a stairway up */
		public function setStairsUp(x:int, y:int):void{
			layers[ENTITIES][y][x] = MapTileConverter.STAIRS_UP;
			stairsUp = new Pixel(x, y);
			if(isPortalToPreviousLevel(x, y, Portal.STAIRS, level - 1)) start = stairsUp;
		}
		
		/* Creates a stairway down */
		public function setStairsDown(x:int, y:int):void{
			layers[ENTITIES][y][x] = MapTileConverter.STAIRS_DOWN;
			stairsDown = new Pixel(x, y);
			if(isPortalToPreviousLevel(x, y, Portal.STAIRS, level + 1)) start = stairsDown;
		}
		
		/* Creates a portal */
		public function setPortal(x:int, y:int, xml:XML):void{
			var p:Pixel = new Pixel(x, y);
			var portal:Portal = Content.XMLToEntity(x, y, xml);
			game.portalHash[portal.type] = portal;
			if(type == AREA){
				if(portal.type == Portal.OVERWORLD_RETURN || portal.type == Portal.UNDERWORLD_RETURN){
					portal.maskPortalBase();
				}
			}
			layers[ENTITIES][y][x] = portal;
			if(isPortalToPreviousLevel(x, y, int(xml.@type), int(xml.@targetLevel))) start = p;
			portals.push(p);
		}
		
		/* Is this portal going to be the entry point for the level?
		 * 
		 * Map.start and Game.entrance are used by the game engine to set the camera and entry point for the level
		 * which is why this query belongs in a function to be called by various elements
		 * 
		 * The logic follows: does this portal lead to the last level you were on */
		public static function isPortalToPreviousLevel(x:int, y:int, type:int, targetLevel:int):Boolean{
			if(type == Portal.STAIRS){
				if(Player.previousPortalType == Portal.STAIRS){
					if(Player.previousMapType == AREA && targetLevel == OVERWORLD) return true;
					else if(Player.previousMapType == MAIN_DUNGEON && Player.previousLevel == targetLevel) return true;
				}
			} else if(type == Portal.OVERWORLD ){
				if(Player.previousPortalType == Portal.OVERWORLD_RETURN) return true;
			} else if(type == Portal.OVERWORLD_RETURN){
				if(Player.previousPortalType == Portal.OVERWORLD) return true;
			} else if(type == Portal.ITEM){
				if(Player.previousPortalType == Portal.ITEM_RETURN) return true;
			} else if(type == Portal.ITEM_RETURN){
				if(Player.previousPortalType == Portal.ITEM) return true;
			} else if(type == Portal.UNDERWORLD){
				if(Player.previousPortalType == Portal.UNDERWORLD_RETURN) return true;
			} else if(type == Portal.UNDERWORLD_RETURN){
				if(Player.previousPortalType == Portal.UNDERWORLD) return true;
			}
			return false;
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
			var posBelow:uint = bitmap.bitmapData.getPixel32(x, y + 1);
			var posLeft:uint =  bitmap.bitmapData.getPixel32(x - 1, y);
			var posRight:uint =  bitmap.bitmapData.getPixel32(x + 1, y);
			if(bitmap.leftSecretRoom && bitmap.leftSecretRoom.contains(x, y)) return false;
			if(bitmap.rightSecretRoom && bitmap.rightSecretRoom.contains(x, y)) return false;
			return (
				(posLeft != MapBitmap.WALL && posRight != MapBitmap.WALL) &&
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
			var i:int, site:Pixel, gate:Gate;
			for(i = 0; i < bitmap.gates.length; i++){
				site = bitmap.gates[i];
				if(!layers[ENTITIES][site.y][site.x]){
					gate = new Gate(site.x * Game.SCALE, site.y * Game.SCALE, Gate.GATES_BY_ZONE[zone][random.rangeInt(Gate.GATES_BY_ZONE.length)]);
					gate.mapX = site.x;
					gate.mapY = site.y;
					gate.mapZ = MapTileManager.ENTITY_LAYER;
					layers[ENTITIES][site.y][site.x] = gate;
				}
			}
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
							//if(random.value() < 1 && !layers[ENTITIES][r][c]){
								layers[ENTITIES][r][c] = new ChaosWall(c, r);
								layers[BLOCKS][r][c] = MapTileConverter.WALL;
							}
						}
					}
				}
			}
		}
		
		/* This adds traps other than pit traps to the level */
		public function createOtherTraps():void{
			
			// the compiler won't let me create this as a constant so I have to drop it in here
			// better than resorting to magic numbers I suppose
			var ZONE_TRAPS:Array = [
				[Trap.TELEPORT_DART],
				[Trap.STUN_DART, Trap.TELEPORT_DART],
				[Trap.STUN_DART, Trap.POISON_DART, Trap.TELEPORT_DART, Trap.CONFUSION_DART],
				[Trap.MONSTER_PORTAL, Trap.STUN_DART, Trap.POISON_DART, Trap.TELEPORT_DART, Trap.CONFUSION_DART, Trap.FEAR_DART]
			];
			
			var totalTraps:int = game.content.getTraps(level, type) - bitmap.pitTraps;
			completionCount += totalTraps;
			if(totalTraps == 0) return;
			
			var dartPos:Pixel;
			var trapPositions:Vector.<Pixel> = new Vector.<Pixel>();
			var pixels:Vector.<uint> = bitmap.bitmapData.getVector(bitmap.bitmapData.rect);
			var mapWidth:int = bitmap.bitmapData.width;
			var r:int, c:int;
			for(i = mapWidth; i < pixels.length - mapWidth; i++){
				if((pixels[i] == MapBitmap.WALL) && (pixels[i - mapWidth] == MapBitmap.EMPTY || pixels[i - mapWidth] == MapBitmap.LEDGE)){
					// check there isn't an entity already here such as a gate
					c = i % width;
					r = i / width;
					if(layers[ENTITIES][r][c]) continue;
					for(j = i - mapWidth; j > mapWidth; j -= mapWidth){
						// no combining ladders or pit traps with dart traps
						// it confuses the trap and it's unfair to have to climb a ladder into a dart
						if(pixels[j] == MapBitmap.LADDER || pixels[j] == MapBitmap.LADDER_LEDGE || pixels[j] == MapBitmap.PIT){
							break;
						} else if(pixels[j] == MapBitmap.WALL){
							trapPositions.push(new Pixel(i % mapWidth, i / mapWidth));
							break;
						}
					}
				}
			}
			
			var trapIndex:int, trapPos:Pixel, trapType:int, sprite:Sprite, trap:Trap;
			
			while(totalTraps > 0 && trapPositions.length > 0){
				trapIndex = random.range(trapPositions.length);
				trapPos = trapPositions[trapIndex];
				trapType = ZONE_TRAPS[zone][random.rangeInt(ZONE_TRAPS[zone].length)];
				sprite = new Sprite();
				sprite.x = trapPos.x * Game.SCALE;
				sprite.y = trapPos.y * Game.SCALE;
				if(trapType != Trap.MONSTER_PORTAL){
					// get dart gun position
					dartPos = trapPos.copy();
					do{
						dartPos.y--;
					} while(pixels[dartPos.x + dartPos.y * width] != MapBitmap.WALL);
				} else {
					dartPos = null;
				}
				trap = new Trap(sprite, trapPos.x, trapPos.y, trapType, dartPos);
				trap.mapX = trapPos.x;
				trap.mapY = trapPos.y;
				trap.mapZ = MapTileManager.ENTITY_LAYER;
				layers[ENTITIES][trapPos.y][trapPos.x] = trap;
				trapPositions.splice(trapIndex, 1);
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
				bitmapData = new BitmapData(Game.SCALE * BACKGROUND_WIDTH, Game.SCALE * BACKGROUND_HEIGHT, true, 0x00000000);
				var source:BitmapData;
				var point:Point = new Point();
				var x:int, y:int;
				for(y = 0; y < BACKGROUND_HEIGHT * 0.5; y ++){
					for(x = 0; x < BACKGROUND_WIDTH * 0.5; x ++){
						source = renderer.zoneBackgroundBitmaps[zone][random.rangeInt(renderer.zoneBackgroundBitmaps[zone].length)].bitmapData;
						point.x = x * Game.SCALE * 2;
						point.y = y * Game.SCALE * 2;
						bitmapData.copyPixels(source, source.rect, point);
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
		public static function getName(type:int, level:int):String{
			if(type == MAIN_DUNGEON){
				var zone:int = (level - 1) / LEVELS_PER_ZONE;
				if(zone >= ZONE_TOTAL) zone = ZONE_TOTAL - 1;
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