package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.gfx.BlitBackgroundClip;
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.BlitSprite;
	import com.robotacid.gfx.BloodClip;
	import com.robotacid.phys.Block;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Entity;
	import com.robotacid.geom.Rect;
	import com.robotacid.phys.Collider;
	import com.robotacid.util.array.getParams;
	import com.robotacid.util.array.protectedSplitArray;
	import com.robotacid.util.clips.startClips;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.MovieClip;
	
	/**
	* Converts indices into MapObjects and their derivatives
	*
	* More complex indices have data attached to them in parenthesis ()
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class MapTileConverter {
		
		public var g:Game;
		public var r:MapRenderer;
		
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
		
		public static const EMPTY:int = 0;
		
		public static const IN_PARENTHESIS:RegExp =/(?<=\().*(?=\))/;
		
		// these are just here to stop me writing a load of magic numbers down when map generating
		public static const STAIRS_UP_ID:int = 58;
		public static const STAIRS_DOWN_ID:int = 59;
		public static const SECRET_WALL_ID:int = 54;
		public static const LADDER_TOP_ID:int = 16;
		public static const LADDER_LEDGE_ID:int = 19;
		public static const LADDER_ID:int = 17;
		public static const LEDGE_ID:int = 14;
		public static const PIT_ID:int = 55;
		
		public static const ID_TO_GRAPHIC:Array = [
			"",						// 0
			new BlitRect(0, 0, Game.SCALE, Game.SCALE, 0xFF000000),
			,
			,
			,
			Game.g.library.BackMC1,		// 5
			Game.g.library.PillarTopB,
			Game.g.library.PillarMiddleB,
			Game.g.library.PillarBottomB,
			new BlitSprite(new Game.g.library.BackB1),
			new BlitSprite(new Game.g.library.BackB2),			// 10
			new BlitSprite(new Game.g.library.BackB3),
			new BlitSprite(new Game.g.library.BackB4),
			new BlitSprite(new Game.g.library.LedgeLeftB),
			new BlitSprite(new Game.g.library.LedgeMiddleB),
			new BlitSprite(new Game.g.library.LedgeRightB),	// 15
			new BlitSprite(new Game.g.library.LadderTopB),
			new BlitSprite(new Game.g.library.LadderMiddleB),
			// ladder / ledge combinations
			Sprite, // Game.g.library.LedgeLeftB / Game.g.library.LadderMiddleB
			new BlitSprite(new Game.g.library.LedgeLadderMiddleB), // Game.g.library.LedgeMiddleB / Game.g.library.LadderMiddleB
			Sprite,// Game.g.library.LedgeRightB / Game.g.library.LadderMiddleB		// 20
			,
			,
			Game.g.library.WallCenterB,
			Game.g.library.WallTopB,
			Game.g.library.WallRightB,	// 25
			Game.g.library.WallBottomB,
			Game.g.library.WallLeftB,
			Game.g.library.WallTopLeftB,
			Game.g.library.WallTopRightB,
			Game.g.library.WallBottomRightB,// 30
			Game.g.library.WallBottomLeftB,
			Game.g.library.WallTopBottomB,
			Game.g.library.WallLeftRightB,
			Game.g.library.WallTopRightBottomB,
			Game.g.library.WallRightBottomLeftB,// 35
			Game.g.library.WallBottomLeftTopB,
			Game.g.library.WallLeftTopRightB,
			,
			,
			,		// 40
			,
			,
			,
			,
			,	// 45
			,
			,
			,
			,
			,	// 50
			,
			,
			,
			Sprite,
			Sprite,//55
			Sprite,
			Sprite,
			Game.g.library.StairsUpB,
			Game.g.library.StairsDownB,
			Sprite,
			Sprite
		];
		
		public function MapTileConverter(g:Game, r:MapRenderer) {
			this.g = g;
			this.r = r;
			
		}
		/* Converts a number in one of the map layers into a MapObject or a MovieClip or Sprite
		 *
		 * When createTile finds an array of information to convert it will return a stacked array
		 */
		public function createTile(x:int, y:int):*{
			if(!r.mapArray[y]){
				trace("out of bounds y "+y+" "+r.height);
			}
			if(!r.mapArray[y][x]) return null;
			
			if(r.mapArray[y][x] is Array){
				array = r.mapArray[y][x];
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
				tile = convertIndicesToObjects(x, y, r.mapArray[y][x])
			}
			// clear map position - the object is now roaming in the engine
			if(!r.image) r.mapArray[y][x] = null;
			return tile;
			
		}
		
		public function convertIndicesToObjects(x:int, y:int, obj:*):*{
			if(obj is Entity){
				obj.holder.addChild(obj.mc);
				g.entities.push(obj);
				obj.active = true;
				if(obj is Item){
					g.items.push(obj);
					//if(obj.mc is MovieClip){
						//startClips(obj.mc);
					//}
				} else if(obj is Chest){
					g.items.push(obj);
				} else if(obj is Collider){
					g.colliders.push(obj);
					if(obj is Character){
						obj.restoreEffects();
						if(obj is Monster){
							Brain.monsterCharacters.push(obj);
						}
						//if(obj.armour && obj.armour.mc is MovieClip){
							//startClips(obj.armour.mc);
						//}
					}
				}
				
				if(!obj.free) return obj;
			}
			//trace(r.mapArray[y][x]);
			
			id = parseInt(obj);
			if (!obj || id == 0) return null;
			
			// is this id a Blit object?
			if(r.image){
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
				if(mc.parent == null) r.tiles.addChild(mc);
			}
			
			
			// build tiles
			
			if(id == 4) {
				item = new Collider(mc, 16, 16, g);
				item.weight = 0;
			} else if(id == 54) {
				mc.x -= 1;
				item = new Stone(mc, Stone.SECRET_WALL, Game.SCALE + 2, Game.SCALE, g);
			} else if(id == 55) {
				item = new Trap(mc, Trap.PIT, g);
			} else if(id == 56) {
				item = new Trap(mc, Trap.POISON_DART, g);
			} else if(id == 57) {
				item = new Trap(mc, Trap.TELEPORT_DART, g);
			} else if(id == 58) {
				g.stairsHolder.addChild(mc);
				item = new Stairs(mc, Stairs.UP, g);
			} else if(id == 59) {
				g.stairsHolder.addChild(mc);
				item = new Stairs(mc, Stairs.DOWN, g);
			} else if(id == 60) {
				mc.x -= 1;
				item = new Stone(mc, Stone.HEALTH, Game.SCALE + 2, Game.SCALE, g);
			} else if(id == 61) {
				mc.x -= 1;
				item = new Stone(mc, Stone.GRIND, Game.SCALE + 2, Game.SCALE, g);
			}
			
			
			// just gfx?
			else {
				item = new Entity(mc, g);
			}
			
			if(item != null){
				item.mapX = item.initX = x;
				item.mapY = item.initY = y;
				item.tileId = r.mapArray[y][x];
				item.layer = r.currentLayer;
				item.holder = mc.parent;
				if(!item.free){
					return item;
				}
			}
			return null;
		}
		/* get block properties for a location */
		public static function getBlockId(n:*):int {
			// map location has parameters
			if(!(n >= 0 || n <= 0) && n is String) {
				n = n.match(/\d+/)[0];
			}
			if(n == 16) return 0;
			if(n == 17) return Block.LADDER;
			if(n >= 18 && n <= 20) return Block.LADDER | Block.LEDGE | Rect.UP;
			if(n >= 13 && n <= 15) return Rect.UP | Block.LEDGE;
			if(n > 0) return Block.SOLID | Block.WALL;
			// no block
			/*if(!(n >= 0 || n <= 0)) return -1;
			// solid block
			if(n == 10) return Block.SOLID | Block.STATIC;
			if(n == 45) return Block.SOLID | Block.STATIC | Block.LIMIT;
			if(n == 63) return Rect.UP | Block.LEDGE;
			if(n >= 64 && n <= 67) return Block.SOLID | Block.STATIC | Block.LIMIT;
			if(n >= 80 && n <= 108) return Block.SOLID | Block.STATIC;
			if(n >= 109 && n <= 113) return Rect.UP | Block.LEDGE;
			return (!(n >= 0 || n <= 0) && n.block) || ((n >= 0 || n <= 0) && (
				n == 10//(n >= 2 && n <= 4) || (n >= 779 && n <= 784) || (n >= 768 && n <= 772) || (n >= 48 && n <= 56) || (n >= 117 && n <= 122)  || (n >= 158 && n <= 375) || (n >= 737 && n <= 740)|| (n >= 753 && n <= 761) || (n >= 376 && n <= 384) || (n >= 385 && n <= 414)
			));*/
			return 0;
		}
		
	}
	
}