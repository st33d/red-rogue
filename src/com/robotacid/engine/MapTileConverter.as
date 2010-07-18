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
		public static const STAIRS_UP:int = 58;
		public static const STAIRS_DOWN:int = 59;
		public static const SECRET_WALL:int = 54;
		
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
		
		public static const PIT:int = 55;
		public static const POISON_DART:int = 56;
		public static const TELEPORT_DART:int = 57;
		
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
			new BlitSprite(new Game.g.library.LedgeB),// 15
			new BlitSprite(new Game.g.library.LedgeSingleB),
			new BlitSprite(new Game.g.library.LedgeMiddleB),
			new BlitSprite(new Game.g.library.LedgeStartLeftB),
			new BlitSprite(new Game.g.library.LedgeStartRightB),
			new BlitSprite(new Game.g.library.LedgeEndLeftB),// 20
			new BlitSprite(new Game.g.library.LedgeEndRightB),
			new BlitSprite(new Game.g.library.LedgeStartLeftEndB),
			new BlitSprite(new Game.g.library.LedgeStartRightEndB),
			// ladder ledge combos - LadderB is painted over these next 9
			new BlitSprite(new Game.g.library.LedgeB),
			new BlitSprite(new Game.g.library.LedgeSingleB),// 25
			new BlitSprite(new Game.g.library.LedgeMiddleB),
			new BlitSprite(new Game.g.library.LedgeStartLeftB),
			new BlitSprite(new Game.g.library.LedgeStartRightB),
			new BlitSprite(new Game.g.library.LedgeEndLeftB),
			new BlitSprite(new Game.g.library.LedgeEndRightB),// 30
			new BlitSprite(new Game.g.library.LedgeStartLeftEndB),
			new BlitSprite(new Game.g.library.LedgeStartRightEndB),
			// ladder top ledge combos - LadderTopB is painted over these next 9
			new BlitSprite(new Game.g.library.LedgeB),
			new BlitSprite(new Game.g.library.LedgeSingleB),
			new BlitSprite(new Game.g.library.LedgeMiddleB),// 35
			new BlitSprite(new Game.g.library.LedgeStartLeftB),
			new BlitSprite(new Game.g.library.LedgeStartRightB),
			new BlitSprite(new Game.g.library.LedgeEndLeftB),
			new BlitSprite(new Game.g.library.LedgeEndRightB),
			new BlitSprite(new Game.g.library.LedgeStartLeftEndB),// 40
			new BlitSprite(new Game.g.library.LedgeStartRightEndB),
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
			Game.g.library.StairsUpB,
			Game.g.library.StairsDownB,
			Sprite,
			Sprite
		];
		
		public function MapTileConverter(g:Game, r:MapRenderer) {
			this.g = g;
			this.r = r;
			
		}
		
		/* Do any preprocessing needed on the BlitSprites */
		public static function init():void{
			var i:int;
			for(i = 24; i <= 32; i++){
				ID_TO_GRAPHIC[i].resize(0, 0, 16, 16);
				ID_TO_GRAPHIC[i].add(ID_TO_GRAPHIC[LADDER]);
			}
			for(i = 33; i <= 41; i++){
				ID_TO_GRAPHIC[i].resize(0, 0, 16, 16);
				ID_TO_GRAPHIC[i].add(ID_TO_GRAPHIC[LADDER_TOP]);
			}
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
					if(obj.contents) g.items.push(obj);
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
		
			if(n == LADDER) return Block.LADDER;
			if(n == LADDER_TOP) return 0;
			if(n >= 15 && n <= 23) return Rect.UP | Block.LEDGE;
			if(n >= 33 && n <= 41) return Rect.UP | Block.LEDGE;
			if(n >= 24 && n <= 32) return Block.LADDER | Block.LEDGE | Rect.UP;
			if(n > 0) return Block.SOLID | Block.WALL;
			
			return 0;
		}
		
	}
	
}