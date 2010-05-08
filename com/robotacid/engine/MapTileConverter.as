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
		private var i:int;
		private var index:int;
		private var dir:int;
		private var array:Array;
		private var tile:*;
		
		private static const UP:int = 1;
		private static const RIGHT:int = 2;
		private static const DOWN:int = 4;
		private static const LEFT:int = 8;
		
		public static const EMPTY:int = 0;
		
		// these are just here to stop me writing a load of magic numbers down when map generating
		public static const STAIRS_UP_ID:int = 58;
		public static const STAIRS_DOWN_ID:int = 59;
		public static const SECRET_WALL_ID:int = 54;
		public static const LADDER_TOP_ID:int = 16;
		public static const LADDER_LEDGE_ID:int = 19;
		public static const LADDER_ID:int = 17;
		public static const LEDGE_ID:int = 14;
		
		public static const class_names:Array = [
			"",						// 0
			new BlitRect(0, 0, Game.SCALE, Game.SCALE, 0xFF000000),
			Game.g.library.SkeletonMC,
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
			Game.g.library.GoblinMC,
			Game.g.library.OrcMC,
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
			Game.g.library.RuneMC,
			Game.g.library.ChestMC,
			Game.g.library.DaggerMC,		// 40
			Game.g.library.MaceMC,
			Game.g.library.SwordMC,
			Game.g.library.StaffMC,
			Game.g.library.BowMC,
			Game.g.library.HammerMC,	// 45
			Game.g.library.FliesMC,
			Game.g.library.SkullMC,
			Game.g.library.FedoraMC,
			BloodClip,
			BlitBackgroundClip,	// 50
			Game.g.library.VikingHelmMC,
			Game.g.library.ChestMC,
			Game.g.library.ChestMC,
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
			if(!r.map_array[y]){
				trace("out of bounds y "+y+" "+r.height);
			}
			if(!r.map_array[y][x]) return null;
			
			if(r.map_array[y][x] is Array){
				array = r.map_array[y][x];
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
				tile = convertIndicesToObjects(x, y, r.map_array[y][x])
			}
			// clear map position - the object is now roaming in the engine
			if(!r.image) r.map_array[y][x] = null;
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
				} else if(obj is Collider){
					g.colliders.push(obj);
					if(obj is Character){
						obj.restoreEffects();
						if(obj is Monster){
							Brain.monster_characters.push(obj);
						}
						//if(obj.armour && obj.armour.mc is MovieClip){
							//startClips(obj.armour.mc);
						//}
					}
				}
				if(!obj.free) return obj;
			}
			//trace(r.map_array[y][x]);
			
			index = parseInt(obj);
			if (!obj || index == 0) return null;
			// detect a object data - object data follows the tile index in brackets
			// eg: 14(3, 16)
			if(!(obj >= 0 || obj <= 0)) {
				// pull the data out from in between the brackets
				data = obj.match(/(?<=\()[^\(\)]*/)[0].split(",");
				// get the index
				index = parseInt(obj.match(/\d+/)[0]);
			}
			// is this index a Blit object?
			if(r.image){
				return class_names[index];
			}
			n = x + y * r.width;
			// generate MovieClip
			if(index > 0){
				mc = new class_names[index];//(getDefinitionByName(class_names[index]) as Class);////
			}
			if(mc != null){
				mc.x = x * r.scale;
				mc.y = y * r.scale;
				if(mc.parent == null) r.tiles.addChild(mc);
			}
			// ladder / ledge combos
			//if(index == 18){
				//(mc as Sprite).addChild(new g.library.LedgeLeftB);
				//(mc as Sprite).addChild(new g.library.LadderMiddleB);
			//} else if(index == 19){
				//(mc as Sprite).addChild(new g.library.LedgeMiddleB);
				//(mc as Sprite).addChild(new g.library.LadderMiddleB);
			//} else if(index == 20){
				//(mc as Sprite).addChild(new g.library.LedgeRightB);
				//(mc as Sprite).addChild(new g.library.LadderMiddleB);
			//}
			
			// need synchronise some items
			/*if(index >= 64 && index <= 67){
				synchro(mc as MovieClip);
			}*/
			// generate Container
			
			// build tiles
			
			if(index == 2) {
				mc.x += Game.SCALE * 0.5;
				mc.y += Game.SCALE - mc.height * 0.5;
				item = new Monster(mc, Character.SKELETON, 0, mc.width, mc.height, g);
			} else if(index == 3) {
				//item = new Crusher(Rect.DOWN, 1, data[0], mc, 16, 32, g);
			} else if(index == 4) {
				item = new Collider(mc, 16, 16, g);
				item.weight = 0;
			} else if(index == 21) {
				mc.x += Game.SCALE * 0.5;
				mc.y += Game.SCALE - mc.height * 0.5;
				item = new Monster(mc, Character.GOBLIN, g.dungeon.level-2, mc.width, mc.height, g);
			} else if(index == 22) {
				mc.x += Game.SCALE * 0.5;
				mc.y += Game.SCALE - mc.height * 0.5;
				item = new Monster(mc, Character.ORC, g.dungeon.level-2, mc.width, mc.height, g);
			} else if(index == 38) {
				item = new Item(mc, 0, Item.RUNE, 1, g);
				item.dropToMap(x, y);
			} else if(index == 39) {
				
			} else if(index == 40) {
				item = new Item(mc, Item.DAGGER, Item.WEAPON, 1, g);
				item.dropToMap(x, y);
			} else if(index == 41) {
				item = new Item(mc, Item.MACE, Item.WEAPON, 1, g);
				item.dropToMap(x, y);
			} else if(index == 42) {
				item = new Item(mc, Item.SWORD, Item.WEAPON, 1, g);
				item.dropToMap(x, y);
			} else if(index == 43) {
				item = new Item(mc, Item.STAFF, Item.WEAPON, 1, g);
				item.dropToMap(x, y);
			} else if(index == 44) {
				item = new Item(mc, Item.BOW, Item.WEAPON, 1, g);
				item.dropToMap(x, y);
			} else if(index == 45) {
				item = new Item(mc, Item.HAMMER, Item.WEAPON, 1, g);
				item.dropToMap(x, y);
			} else if(index == 46) {
				item = new Item(mc, Item.FLIES, Item.ARMOUR, 1, g);
				item.dropToMap(x, y);
			} else if(index == 47) {
				item = new Item(mc, Item.SKULL, Item.ARMOUR, 1, g);
				item.dropToMap(x, y);
			} else if(index == 48) {
				item = new Item(mc, Item.FEDORA, Item.ARMOUR, 1, g);
				item.dropToMap(x, y);
			} else if(index == 49) {
				item = new Item(mc, Item.BLOOD, Item.ARMOUR, 1, g);
				item.dropToMap(x, y);
			} else if(index == 50) {
				item = new Item(mc, Item.INVISIBILITY, Item.ARMOUR, 1, g);
				item.dropToMap(x, y);
			} else if(index == 51) {
				item = new Item(mc, Item.VIKING_HELM, Item.ARMOUR, 1, g);
				item.dropToMap(x, y);
			} else if(index == 52) {
				mc.x += Game.SCALE * 0.5;
				mc.y += Game.SCALE;
				item = new Chest(mc, g);
				g.items_holder.addChild(mc);
			} else if(index == 53) {
				mc.x += Game.SCALE * 0.5;
				mc.y += Game.SCALE;
				item = new Chest(mc, g, true);
				g.items_holder.addChild(mc);
			} else if(index == 54) {
				mc.x -= 1;
				item = new Stone(mc, Stone.SECRET_WALL, Game.SCALE + 2, Game.SCALE, g);
			} else if(index == 55) {
				item = new Trap(mc, Trap.PIT, g);
			} else if(index == 56) {
				item = new Trap(mc, Trap.POISON_DART, g);
			} else if(index == 57) {
				item = new Trap(mc, Trap.TELEPORT_DART, g);
			} else if(index == 58) {
				g.stairs_holder.addChild(mc);
				item = new Stairs(mc, Stairs.UP, g);
			} else if(index == 59) {
				g.stairs_holder.addChild(mc);
				item = new Stairs(mc, Stairs.DOWN, g);
			} else if(index == 60) {
				mc.x -= 1;
				item = new Stone(mc, Stone.HEALTH, Game.SCALE + 2, Game.SCALE, g);
			} else if(index == 61) {
				mc.x -= 1;
				item = new Stone(mc, Stone.GRIND, Game.SCALE + 2, Game.SCALE, g);
			}
			
			
			// just gfx?
			else {
				item = new Entity(mc, g);
			}
			
			if(item != null){
				item.map_x = item.init_x = x;
				item.map_y = item.init_y = y;
				item.tile_id = r.map_array[y][x];
				item.layer = r.current_layer;
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