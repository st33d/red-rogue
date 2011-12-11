package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.dungeon.Map;
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
		// with below
		public var g:Game;
		public var renderer:Renderer;
		public var r:MapTileManager;
		
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
		
		public static const SECRET_WALL:int = 54;
		public static const PIT:int = 55;
		public static const POISON_DART:int = 56;
		public static const TELEPORT_DART:int = 57;
		public static const STAIRS_UP:int = 58;
		public static const STAIRS_DOWN:int = 59;
		public static const HEAL_STONE:int = 60;
		public static const GRIND_STONE:int = 61;
		
		public static const RAT:int = 62;
		public static const SPIDER:int = 63;
		public static const BAT:int = 64;
		
		// These references are technically illegal. Game.g doesn't even exist yet, but some how the
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
			new BlitSprite(new Game.g.library.BackB1),
			new BlitSprite(new Game.g.library.BackB2),// 10
			new BlitSprite(new Game.g.library.BackB3),
			new BlitSprite(new Game.g.library.BackB4),
			new BlitSprite(new Game.g.library.LadderB),
			new BlitSprite(new Game.g.library.LadderTopB),
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
			,
			,
			,
			,// 45
			,
			,
			,
			,
			,// 50
			,
			,
			,
			Sprite,// secret wall
			Sprite,//55
			Sprite,
			Sprite,
			StairsUpMC,
			StairsDownMC,
			Sprite,//60
			Sprite,
			RatMC,
			SpiderMC,
			BatMC
		];
		
		public function MapTileConverter(r:MapTileManager, g:Game, renderer:Renderer) {
			this.r = r;
			this.g = g;
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
			preProcessed = true;
		}
		
		/* Converts a number in one of the map layers into a MapObject or a MovieClip or Sprite
		 *
		 * When createTile finds an array of information to convert it will return a stacked array
		 */
		public function createTile(x:int, y:int):*{
			if(!r.map[y]){
				trace("out of bounds y "+y+" "+r.height);
			}
			if(!r.map[y][x]) return null;
			
			if(r.map[y][x] is Array){
				array = r.map[y][x];
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
				tile = convertIndicesToObjects(x, y, r.map[y][x])
			}
			// clear map position - the object is now roaming in the engine
			if(!r.bitmapLayer) r.map[y][x] = null;
			return tile;
			
		}
		
		public function convertIndicesToObjects(x:int, y:int, obj:*):*{
			if(obj is Entity){
				if(obj.addToEntities) g.entities.push(obj);
				obj.active = true;
				if(obj is Chest){
					g.items.push(obj);
				} else if(obj is Portal){
					if(obj.seen) obj.callMain = false;
					g.portals.push(obj);
				} else if(obj is ColliderEntity){
					g.world.restoreCollider(obj.collider);
					if(obj is Character){
						obj.restoreEffects();
						if(obj is Monster){
							Brain.monsterCharacters.push(obj);
							if(!obj.mapInitialised) obj.mapInit();
						}
					} else if(obj is Item){
						g.items.push(obj);
					} else if(obj is ChaosWall){
						g.chaosWalls.push(obj);
					}
				}
				
				if(!obj.free) return obj;
			}
			//trace(r.mapArray[y][x]);
			
			id = int(obj);
			if (!obj || id == 0) return null;
			
			// is this id a Blit object?
			if(r.bitmapLayer){
				return ID_TO_GRAPHIC[id];
			}
			n = x + y * r.width;
			// generate MovieClip
			if(id > 0 && ID_TO_GRAPHIC[id]){
				mc = new ID_TO_GRAPHIC[id];
			}
			if(mc != null){
				mc.x = x * r.scale;
				mc.y = y * r.scale;
			}
			
			
			// build tiles
			
			if(id == 4){
				
			} else if(id == SECRET_WALL){
				item = new Stone(x * Game.SCALE, y * Game.SCALE, Stone.SECRET_WALL);
			} else if(id == PIT){
				item = new Trap(mc, x, y, Trap.PIT);
			} else if(id == POISON_DART){
				item = new Trap(mc, x, y, Trap.POISON_DART);
			} else if(id == TELEPORT_DART){
				item = new Trap(mc, x, y, Trap.TELEPORT_DART);
			} else if(id == STAIRS_UP){
				// stairs up
				item = new Portal(mc, new Rectangle(x * Game.SCALE, y * Game.SCALE, Game.SCALE, Game.SCALE), Portal.STAIRS, g.dungeon.level - 1);
				if(Map.isPortalToPreviousLevel(x, y, Portal.STAIRS, g.dungeon.level - 1)) g.entrance = item;
			} else if(id == STAIRS_DOWN){
				// stairs down
				if(g.dungeon.level == Map.OVERWORLD && g.dungeon.type == Map.AREA) mc = new Sprite();
				item = new Portal(mc, new Rectangle(x * Game.SCALE, y * Game.SCALE, Game.SCALE, Game.SCALE), Portal.STAIRS, g.dungeon.level + 1);
				if(Map.isPortalToPreviousLevel(x, y, Portal.STAIRS, g.dungeon.level + 1)) g.entrance = item;
			} else if(id == HEAL_STONE){
				item = new Stone(x * Game.SCALE, y * Game.SCALE, Stone.HEALTH);
			} else if(id == GRIND_STONE){
				item = new Stone(x * Game.SCALE, y * Game.SCALE, Stone.GRIND);
			} else if(id == RAT){
				item = new Critter(mc, (x + 0.5) * Game.SCALE, (y + 1) * Game.SCALE, Critter.RAT);
			} else if(id == SPIDER){
				item = new Critter(mc, (x + 0.5) * Game.SCALE, (y + 0.5) * Game.SCALE, Critter.SPIDER);
			} else if(id == BAT){
				item = new Critter(mc, (x + 0.5) * Game.SCALE, y * Game.SCALE, Critter.BAT);
			}
			
			
			// just gfx?
			else {
				item = new Entity(mc);
			}
			
			if(item != null){
				item.mapX = item.initX = x;
				item.mapY = item.initY = y;
				item.mapZ = r.currentLayer;
				item.tileId = r.map[y][x];
				if(item is ColliderEntity){
					g.world.restoreCollider(item.collider);
				}
				if(!item.free){
					return item;
				}
			}
			return null;
		}
		/* get block properties for a location */
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
		
	}
	
}