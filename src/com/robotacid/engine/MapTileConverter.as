package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.level.Map;
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.BlitSprite;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Entity;
	import com.robotacid.phys.Collider;
	import com.robotacid.util.array.getParams;
	import com.robotacid.util.array.protectedSplitArray;
	import com.robotacid.util.clips.startClips;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	* Converts indices into MapObjects and their derivatives
	*
	* More complex indices have data attached to them in parenthesis ()
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class MapTileConverter {
		
		// NOTE TO MAINTAINER
		//
		// These can't be made static due to some completely illegal references I'm getting away
		// with in ID_TO_GRAPHIC
		public var game:Game;
		public var renderer:Renderer;
		public var mapTileManager:MapTileManager;
		
		private var item:*;
		private var n:int;
		private var mc:DisplayObject;
		
		public var forced:Boolean;
		public var data:Array;
		public var params:String;
		private var i:int;
		private var j:int;
		private var id:int;
		private var dir:int;
		private var array:Array;
		private var tile:*;
		
		private static const UP:int = 1;
		private static const RIGHT:int = 2;
		private static const DOWN:int = 4;
		private static const LEFT:int = 8;
		
		public static const WALL:int = 1;
		public static const EMPTY:int = 0;
		
		public static const IN_PARENTHESIS:RegExp =/(?<=\().*(?=\))/;
		
		// these are just here to stop me writing a load of magic numbers down when map generating
		// awkwardly enough, at work I just use the strings of classes - but I'm gonna just stay
		// old school with this one and have a smidgin more speed from not raping getQualifiedClassName
		
		public static const LADDER:int = 13;
		public static const LADDER_TOP:int = 14;
		public static const LEDGE:int = 15;
		public static const LEDGE_SINGLE:int = 16;
		public static const LEDGE_MIDDLE:int = 17;
		public static const LEDGE_START_LEFT:int = 18;
		public static const LEDGE_START_RIGHT:int = 19;
		public static const LEDGE_END_LEFT:int = 20;
		public static const LEDGE_END_RIGHT:int = 21;
		public static const LEDGE_START_LEFT_END:int = 22;
		public static const LEDGE_START_RIGHT_END:int = 23;
		
		public static const LADDER_LEDGE:int = 24;
		public static const LADDER_LEDGE_SINGLE:int = 25;
		public static const LADDER_LEDGE_MIDDLE:int = 26;
		public static const LADDER_LEDGE_START_LEFT:int = 27;
		public static const LADDER_LEDGE_START_RIGHT:int = 28;
		public static const LADDER_LEDGE_END_LEFT:int = 29;
		public static const LADDER_LEDGE_END_RIGHT:int = 30;
		public static const LADDER_LEDGE_START_LEFT_END:int = 31;
		public static const LADDER_LEDGE_START_RIGHT_END:int = 32;
		
		public static const LADDER_TOP_LEDGE:int = 33;
		public static const LADDER_TOP_LEDGE_SINGLE:int = 34;
		public static const LADDER_TOP_LEDGE_MIDDLE:int = 35;
		public static const LADDER_TOP_LEDGE_START_LEFT:int = 36;
		public static const LADDER_TOP_LEDGE_START_RIGHT:int = 37;
		public static const LADDER_TOP_LEDGE_END_LEFT:int = 38;
		public static const LADDER_TOP_LEDGE_END_RIGHT:int = 39;
		public static const LADDER_TOP_LEDGE_START_LEFT_END:int = 40;
		public static const LADDER_TOP_LEDGE_START_RIGHT_END:int = 41;
		
		public static const PIPE_CORNER_RIGHT_DOWN:int = 42;
		public static const PIPE_HORIZ1:int = 43;
		public static const PIPE_CROSS:int = 44;
		public static const PIPE_T_LEFT_DOWN_RIGHT:int = 45;
		public static const PIPE_T_UP_RIGHT_DOWN:int = 46;
		public static const PIPE_HORIZ2:int = 47;
		public static const PIPE_CORNER_LEFT_UP:int = 48;
		public static const PIPE_VERT1:int = 49;
		public static const PIPE_T_LEFT_UP_DOWN:int = 50;
		public static const PIPE_VERT2:int = 51;
		public static const PIPE_T_RIGHT_UP_LEFT:int = 52;
		public static const PIPE_CORNER_LEFT_DOWN:int = 53;
		public static const PIPE_CORNER_UP_RIGHT:int = 54;
		
		public static const STAIRS_UP:int = 58;
		public static const STAIRS_DOWN:int = 59;
		public static const HEAL_STONE:int = 60;
		public static const GRIND_STONE:int = 61;
		
		public static const RAT:int = 62;
		public static const SPIDER:int = 63;
		public static const BAT:int = 64;
		public static const COG:int = 65;
		public static const COG_RAT:int = 66;
		public static const COG_SPIDER:int = 67;
		public static const COG_BAT:int = 68;
		
		public static const PILLAR_BOTTOM:int = 69;
		public static const PILLAR_MID1:int = 70;
		public static const PILLAR_MID2:int = 71;
		public static const PILLAR_TOP:int = 72;
		public static const PILLAR_SINGLE1:int = 73;
		public static const PILLAR_SINGLE2:int = 74;
		public static const CHAIN_MID:int = 75;
		public static const CHAIN_BOTTOM:int = 76;
		public static const CHAIN_TOP:int = 77;
		public static const RECESS:int = 78;
		public static const OUTLET:int = 79;
		public static const DRAIN:int = 80;
		public static const STALAGMITE1:int = 81;
		public static const STALAGMITE2:int = 82;
		public static const STALAGMITE3:int = 83;
		public static const STALAGMITE4:int = 84;
		public static const STALAGTITE1:int = 85;
		public static const STALAGTITE2:int = 86;
		public static const STALAGTITE3:int = 87;
		public static const STALAGTITE4:int = 88;
		public static const CRACK1:int = 89;
		public static const CRACK2:int = 90;
		public static const CRACK3:int = 91;
		public static const SKULL:int = 92;
		public static const GROWTH1:int = 93;
		public static const GROWTH2:int = 94;
		public static const GROWTH3:int = 95;
		public static const GROWTH4:int = 96;
		public static const GROWTH5:int = 97;
		public static const GROWTH6:int = 98;
		public static const GROWTH7:int = 99;
		public static const GROWTH8:int = 100;
		public static const GROWTH9:int = 101;
		public static const GROWTH10:int = 102;
		public static const GROWTH11:int = 103;
		public static const GROWTH12:int = 104;
		public static const STAIRS_UP_GFX:int = 105;
		public static const STAIRS_DOWN_GFX:int = 106;
		
		// These references are technically illegal. Game.game doesn't even exist yet, but some how the
		// compiler is letting the issue slide so long as I don't static reference Game
		public static var ID_TO_GRAPHIC:Array = [
			"",						// 0
			new BlitRect(0, 0, Game.SCALE, Game.SCALE, 0xFF000000),// wall
			,
			,
			,//test collider
			,// 5
			,
			,
			,
			new BlitSprite(new Game.game.library.BackB1),
			new BlitSprite(new Game.game.library.BackB2),// 10
			new BlitSprite(new Game.game.library.BackB3),
			new BlitSprite(new Game.game.library.BackB4),
			new BlitSprite(new Game.game.library.LadderB),
			new BlitSprite(new Game.game.library.LadderTopB),
			new BlitSprite(new LedgeMC9),// 15
			new BlitSprite(new LedgeMC4),
			new BlitSprite(new LedgeMC1),
			new BlitSprite(new LedgeMC6),
			new BlitSprite(new LedgeMC8),
			new BlitSprite(new LedgeMC2),//20
			new BlitSprite(new LedgeMC3),
			new BlitSprite(new LedgeMC5),
			new BlitSprite(new LedgeMC7),
			// ladder ledge combos - LadderB is painted over these next 9
			new BlitSprite(new LedgeMC9),
			new BlitSprite(new LedgeMC4),// 25
			new BlitSprite(new LedgeMC1),
			new BlitSprite(new LedgeMC6),
			new BlitSprite(new LedgeMC8),
			new BlitSprite(new LedgeMC2),
			new BlitSprite(new LedgeMC3),// 30
			new BlitSprite(new LedgeMC5),
			new BlitSprite(new LedgeMC7),
			// ladder top ledge combos - LadderTopB is painted over these next 9
			new BlitSprite(new LedgeMC9),
			new BlitSprite(new LedgeMC4),
			new BlitSprite(new LedgeMC1),// 35
			new BlitSprite(new LedgeMC6),
			new BlitSprite(new LedgeMC8),
			new BlitSprite(new LedgeMC2),
			new BlitSprite(new LedgeMC3),
			new BlitSprite(new LedgeMC5),// 40
			new BlitSprite(new LedgeMC7),
			new BlitSprite(new Game.game.library.PipeB1),
			new BlitSprite(new Game.game.library.PipeB2),
			new BlitSprite(new Game.game.library.PipeB3),
			new BlitSprite(new Game.game.library.PipeB4),// 45
			new BlitSprite(new Game.game.library.PipeB5),
			new BlitSprite(new Game.game.library.PipeB6),
			new BlitSprite(new Game.game.library.PipeB7),
			new BlitSprite(new Game.game.library.PipeB8),
			new BlitSprite(new Game.game.library.PipeB9),// 50
			new BlitSprite(new Game.game.library.PipeB10),
			new BlitSprite(new Game.game.library.PipeB11),
			new BlitSprite(new Game.game.library.PipeB12),
			new BlitSprite(new Game.game.library.PipeB13),
			,//55
			,
			,
			StairsUpMC,
			StairsDownMC,
			Sprite,//60
			Sprite,
			RatMC,
			SpiderMC,
			BatMC,
			CogMC,//65
			CogMC,
			CogMC,
			CogMC,
			,
			,//70
			,
			,
			,
			,
			,//75
			,
			,
			new BlitSprite(new RecessDecorMC),
			new BlitSprite(new OutletDecorMC),
			new BlitSprite(new DrainDecorMC),//80
			,
			,
			,
			,
			,//85
			,
			,
			,
			,
			,//90
			,
			new BlitSprite(new SkullDecorMC),
			,
			,
			,//95
			,
			,
			,
			,
			,//100
			,
			,
			,
			,
			new BlitSprite(new StairsUpMC),
			new BlitSprite(new StairsDownMC)
		];
		
		public function MapTileConverter(r:MapTileManager, game:Game, renderer:Renderer) {
			this.mapTileManager = r;
			this.game = game;
			this.renderer = renderer;
			
		}
		
		public static var preProcessed:Boolean = false;
		
		/* Do any preprocessing needed on the BlitSprites */
		public static function init():void{
			if(preProcessed) return;
			var i:int;
			var point:Point = new Point();
			for(i = 15; i <= 41; i++){
				ID_TO_GRAPHIC[i].resize(0, 0, 16, 16);
				(ID_TO_GRAPHIC[i].data as BitmapData).applyFilter(ID_TO_GRAPHIC[i].data, ID_TO_GRAPHIC[i].rect, point, new DropShadowFilter(1, 90, 0, 0.3, 0, 3, 1));
			}
			for(i = 24; i <= 32; i++){
				ID_TO_GRAPHIC[i].add(ID_TO_GRAPHIC[LADDER]);
			}
			for(i = 33; i <= 41; i++){
				ID_TO_GRAPHIC[i].add(ID_TO_GRAPHIC[LADDER_TOP]);
			}
			// create background graphics
			var mc:MovieClip;
			mc = new PillarDecorMC();
			for(i = 0; i < mc.totalFrames; i++){
				mc.gotoAndStop(i + 1);
				ID_TO_GRAPHIC[PILLAR_BOTTOM + i] = new BlitSprite(mc);
			}
			mc = new ChainDecorMC();
			for(i = 0; i < mc.totalFrames; i++){
				mc.gotoAndStop(i + 1);
				ID_TO_GRAPHIC[CHAIN_MID + i] = new BlitSprite(mc);
			}
			mc = new StalagmiteDecorMC();
			for(i = 0; i < mc.totalFrames; i++){
				mc.gotoAndStop(i + 1);
				ID_TO_GRAPHIC[STALAGMITE1 + i] = new BlitSprite(mc);
			}
			mc = new CrackDecorMC();
			for(i = 0; i < mc.totalFrames; i++){
				mc.gotoAndStop(i + 1);
				ID_TO_GRAPHIC[CRACK1 + i] = new BlitSprite(mc);
			}
			mc = new CrackDecorMC();
			for(i = 0; i < mc.totalFrames; i++){
				mc.gotoAndStop(i + 1);
				ID_TO_GRAPHIC[CRACK1 + i] = new BlitSprite(mc);
			}
			mc = new GrowthDecorMC();
			for(i = 0; i < mc.totalFrames; i++){
				mc.gotoAndStop(i + 1);
				ID_TO_GRAPHIC[GROWTH1 + i] = new BlitSprite(mc);
			}
			preProcessed = true;
		}
		
		/* Converts a number in one of the map layers into a MapObject or a MovieClip or Sprite
		 *
		 * When createTile finds an array of information to convert it will return a stacked array
		 */
		public function createTile(x:int, y:int):*{
			if(!mapTileManager.map[y]){
				trace("out of bounds y "+y+" "+mapTileManager.height);
			}
			if(!mapTileManager.map[y][x]) return null;
			
			if(mapTileManager.map[y][x] is Array){
				array = mapTileManager.map[y][x];
				tile = [];
				var temp:*;
				for(i = 0; i < array.length; i++){
					// some tiles convert without returning data, they manage converting themselves
					// back into map indices on their own - we don't give these to the renderer
					temp = convertIndicesToObjects(x, y, array[i]);
					if(temp) tile.push(temp);
				}
				if(tile.length == 0) tile = null;
			} else {
				tile = convertIndicesToObjects(x, y, mapTileManager.map[y][x])
			}
			// clear map position - the object is now roaming in the engine
			if(!mapTileManager.bitmapLayer) mapTileManager.map[y][x] = null;
			return tile;
			
		}
		
		public function convertIndicesToObjects(x:int, y:int, obj:*):*{
			if(obj is Entity){
				if(obj.addToEntities) game.entities.push(obj);
				obj.active = true;
				if(obj is Chest || obj is Altar){
					game.items.push(obj);
				} else if(obj is Portal){
					game.portals.push(obj);
				} else if(obj is Torch){
					obj.mapInit();
					game.torches.push(obj);
				} else if(obj is ColliderEntity){
					game.world.restoreCollider(obj.collider);
					if(obj is Character){
						obj.restoreEffects();
						if(obj is Monster){
							Brain.monsterCharacters.push(obj);
							if(!obj.mapInitialised) obj.mapInit();
						} else if(obj is MinionClone){
							Brain.playerCharacters.push(obj);
						}
					} else if(obj is Item){
						game.items.push(obj);
					} else if(obj is ChaosWall){
						game.chaosWalls.push(obj);
					}
				}
				
				if(!obj.free) return obj;
			}
			//trace(r.mapArray[y][x]);
			
			id = int(obj);
			if (!obj || id == 0) return null;
			
			// is this id a Blit object?
			if(mapTileManager.bitmapLayer){
				return ID_TO_GRAPHIC[id];
			}
			n = x + y * mapTileManager.width;
			// generate MovieClip
			if(id > 0 && ID_TO_GRAPHIC[id]){
				mc = new ID_TO_GRAPHIC[id];
			}
			if(mc != null){
				mc.x = x * mapTileManager.scale;
				mc.y = y * mapTileManager.scale;
			}
			
			// objects defined by index and created on the fly
			
			if(id == STAIRS_UP){
				// stairs up
				item = new Portal(mc, new Rectangle(x * Game.SCALE, y * Game.SCALE, Game.SCALE, Game.SCALE), Portal.STAIRS, game.map.level - 1, game.map.level == 1 ? Map.AREA : Map.MAIN_DUNGEON);
				if(Map.isPortalToPreviousLevel(x, y, Portal.STAIRS, item.targetLevel, item.targetType)) game.entrance = item;
			} else if(id == STAIRS_DOWN){
				// stairs down
				if(game.map.level == Map.OVERWORLD && game.map.type == Map.AREA){
					mc = new OverworldStairsMC();
					mc.x = x * mapTileManager.scale;
					mc.y = y * mapTileManager.scale;
				}
				item = new Portal(mc, new Rectangle(x * Game.SCALE, y * Game.SCALE, Game.SCALE, Game.SCALE), Portal.STAIRS, game.map.level + 1, Map.MAIN_DUNGEON);
				if(Map.isPortalToPreviousLevel(x, y, Portal.STAIRS, item.targetLevel, item.targetType)) game.entrance = item;
			} else if(id == HEAL_STONE){
				item = new Stone(x * Game.SCALE, y * Game.SCALE, Stone.HEAL);
			} else if(id == GRIND_STONE){
				item = new Stone(x * Game.SCALE, y * Game.SCALE, Stone.GRIND);
			} else if(id == RAT){
				item = new Critter(mc, (x + 0.5) * Game.SCALE, (y + 1) * Game.SCALE, Critter.RAT);
			} else if(id == SPIDER){
				item = new Critter(mc, (x + 0.5) * Game.SCALE, (y + 0.5) * Game.SCALE, Critter.SPIDER);
			} else if(id == BAT){
				item = new Critter(mc, (x + 0.5) * Game.SCALE, y * Game.SCALE, Critter.BAT);
			} else if(id == COG){
				item = new Critter(mc, (x + 0.5) * Game.SCALE, (y + 0.5) * Game.SCALE, Critter.COG);
			} else if(id == COG_RAT){
				item = new Critter(mc, (x + 0.5) * Game.SCALE, (y + 1) * Game.SCALE, Critter.COG | Critter.RAT);
			} else if(id == COG_SPIDER){
				item = new Critter(mc, (x + 0.5) * Game.SCALE, (y + 0.5) * Game.SCALE, Critter.COG | Critter.SPIDER);
			} else if(id == COG_BAT){
				item = new Critter(mc, (x + 0.5) * Game.SCALE, y * Game.SCALE, Critter.COG | Critter.BAT);
			}
			
			// just gfx?
			else {
				item = new Entity(mc);
			}
			
			if(item != null){
				item.mapX = item.initX = x;
				item.mapY = item.initY = y;
				item.mapZ = mapTileManager.currentLayer;
				item.tileId = mapTileManager.map[y][x];
				if(item is ColliderEntity){
					game.world.restoreCollider(item.collider);
				}
				if(!item.free){
					return item;
				}
			}
			return null;
		}
		
		/* Get block properties for a location */
		public static function getMapProperties(n:*):int {
			// map location has parameters
			if(!(n >= 0 || n <= 0) && n is String) {
				n = n.match(/\d+/)[0];
			}
			
			if(n == LADDER) return Collider.LADDER;
			if(n == LADDER_TOP) return 0;
			if(n >= 15 && n <= 23) return Collider.UP | Collider.LEDGE;
			if(n >= 33 && n <= 41) return Collider.UP | Collider.LEDGE;
			if(n >= 24 && n <= 32) return Collider.LADDER | Collider.LEDGE | Collider.UP;
			if(n > 0) return Collider.SOLID | Collider.WALL;
			
			return 0;
		}
		
		/* Get a tile index for a pipe graphic based on directions the pipes are supposed to lead out of a tile */
		public static function getPipeTileIndex(dirs:int):int{
			if(dirs == (UP | RIGHT)) return PIPE_CORNER_UP_RIGHT;
			else if(dirs == (UP | LEFT)) return PIPE_CORNER_LEFT_UP;
			else if(dirs == (DOWN | LEFT)) return PIPE_CORNER_LEFT_DOWN;
			else if(dirs == (DOWN | RIGHT)) return PIPE_CORNER_RIGHT_DOWN;
			else if(dirs == (UP | RIGHT | LEFT)) return PIPE_T_RIGHT_UP_LEFT;
			else if(dirs == (DOWN | RIGHT | LEFT)) return PIPE_T_LEFT_DOWN_RIGHT;
			else if(dirs == (UP | RIGHT | DOWN)) return PIPE_T_UP_RIGHT_DOWN;
			else if(dirs == (DOWN | UP | LEFT)) return PIPE_T_LEFT_UP_DOWN;
			else if(dirs == (DOWN | UP)) return Game.game.random.coinFlip() ? PIPE_VERT1 : PIPE_VERT2;
			else if(dirs == (LEFT | RIGHT)) return Game.game.random.coinFlip() ? PIPE_HORIZ1 : PIPE_HORIZ2;
			else if(dirs == (DOWN | UP | LEFT | RIGHT)) return PIPE_CROSS;
			return 0;
		}
		
	}
	
}