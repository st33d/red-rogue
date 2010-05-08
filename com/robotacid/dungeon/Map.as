package com.robotacid.dungeon {
	import com.robotacid.engine.Character;
	import com.robotacid.engine.MapTileConverter;
	import com.robotacid.engine.Stairs;
	import com.robotacid.geom.Pixel;
	import com.robotacid.util.misc.randomiseArray;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * This is the random map generator
	 * 
	 * The layout for every dungeon is calculated in here
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Map {
		
		public var g:Game;
		public var level:int;
		public var width:int;
		public var height:int;
		public var start:Pixel;
		public var entrance:Pixel;
		public var exit:Pixel;
		
		public var bitmap:DungeonBitmap;
		
		private var i:int, j:int;
		
		public var layers:Array;
		
		public static const LAYER_NUM:int = 4;
		public static const BACKGROUND:int = 0;
		public static const BLOCKS:int = 1;
		public static const ENTITIES:int = 2;
		public static const FOREGROUND:int = 3;
		
		public static const ITEMS:Array = [38, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51];
		
		public function Map(level:int, g:Game) {
			this.g = g;
			this.level = level;
			layers = [];
			if(level){
				bitmap = new DungeonBitmap(level);
				width = bitmap.width;
				height = bitmap.height;
				convertDungeonBitmap(bitmap.bitmapData);
				//createTestBed();
				createBackground();
			} else {
				createOverworld();
			}
		}
		/* Create the test bed
		 * 
		 * This is a debugging playground for testing new content and trying to lure consistent
		 * bugs out into the open (which is nigh on fucking impossible in a procedural world)
		 */
		public function createTestBed():void{
			width = 50;
			height = 50;
			layers.push(createGrid(null, width, height));
			// blocks - start with a full grid
			layers.push(createGrid(1, width, height));
			// game objects
			layers.push(createGrid(null, width, height));
			// foreground
			layers.push(createGrid(null, width, height));
			fill(0, 5, 5, 40, 40, layers[BLOCKS]);
			
			// insert test code for items and such here
			//layers[ENTITIES][44][4] = 54;
			//layers[ENTITIES][44][6] = 22;
			layers[ENTITIES][44][8] = 22;
			
			// access points
			setEntrance(12, 44);
			setExit(10, 44);
			setStart();
			
			layers[BLOCKS][44][14] = 1;
			layers[ENTITIES][44][14] = 60;
			
			//createSecretWall(14, 44);
			
			
			layers[BLOCKS][40][10] = 1;
			//layers[BLOCKS][44][10] = 1;
		}
		
		
		
		/* This is where we convert our map template into a dungeon proper made of tile_ids and other
		 * information
		 */
		public function convertDungeonBitmap(bitmap_data:BitmapData):void{
			width = bitmap_data.width;
			height = bitmap_data.height;
			// background
			layers.push(createGrid(null, bitmap_data.width, bitmap_data.height));
			// blocks - start with a full grid
			layers.push(createGrid(1, bitmap_data.width, bitmap_data.height));
			// game objects
			layers.push(createGrid(null, bitmap_data.width, bitmap_data.height));
			// foreground
			layers.push(createGrid(null, bitmap_data.width, bitmap_data.height));
			
			var pixels:Vector.<uint> = bitmap_data.getVector(bitmap_data.rect);
			
			// create ladders and ledges
			var r:int, c:int;
			for(i = width; i < pixels.length - width; i++){
				c = i % width;
				r = i / width;
				if(pixels[i] == DungeonBitmap.EMPTY && pixels[i + width] == DungeonBitmap.LADDER_LEDGE){
					layers[BLOCKS][r][c] = MapTileConverter.LADDER_TOP_ID;
				} else if(pixels[i] == DungeonBitmap.LADDER_LEDGE){
					layers[BLOCKS][r][c] = MapTileConverter.LADDER_LEDGE_ID;
				} else if(pixels[i] == DungeonBitmap.LADDER){
					layers[BLOCKS][r][c] = MapTileConverter.LADDER_ID;
				} else if(pixels[i] == DungeonBitmap.LEDGE){
					layers[BLOCKS][r][c] = MapTileConverter.LEDGE_ID;
				} else if(pixels[i] == DungeonBitmap.EMPTY){
					layers[BLOCKS][r][c] = 0;
				}
			}
			
			// THESE ARE TEMPORARY CONTENT FILLING ROUTINES - A REAL DUNGEON SHOULD DUMP
			// THE LOOT ANY OLD WHERE
			
			// populate with monsters
			
			for(r = 0; r < height; r++){
				for(c = 0; c < width; c++){
					if(layers[BLOCKS][r][c] != 1 && (layers[BLOCKS][r+1][c] == MapTileConverter.LEDGE_ID || layers[BLOCKS][r+1][c] == 1) && Math.random() > 0.9){
						layers[ENTITIES][r][c] = Math.random() > 0.7 ? 22 : 21;
					}
				}
			}
			
			// populate with items
			
			for(r = 0; r < height; r++){
				for(c = 0; c < width; c++){
					if(layers[BLOCKS][r][c] != 1 && (layers[BLOCKS][r+1][c] == MapTileConverter.LEDGE_ID || layers[BLOCKS][r+1][c] == 1) && Math.random() > 0.9){
						layers[ENTITIES][r][c] = 52;// closed chest index
					}
				}
			}
			
			// create the access points
			
			createAccessPoints();
		}
		
		/* Create the overworld
		 *
		 * The overworld is present to create a contrast with the dungeon. It is in colour and so
		 * are you. You can wield no weapons here and your minion is unseen
		 * There is a health stone for restoring health and a grindstone -
		 * an allegory of improving yourself in the real world as opposed to a fantasy where
		 * you kill people to better yourself, that you can ironically destroy by levelling up next to
		 */
		public function createOverworld():void{
			width = 20;
			height = 17;
			layers.push(createGrid(null, width, height));
			// blocks - start with a full grid
			layers.push(createGrid(1, width, height));
			// game objects
			layers.push(createGrid(null, width, height));
			// foreground
			layers.push(createGrid(null, width, height));
			fill(0, 1, 0, width-2, height-1, layers[BLOCKS]);
			
			// create the grindstone and healstone
			layers[BLOCKS][height-2][3] = 1;
			layers[ENTITIES][height-2][3] = 60;
			layers[BLOCKS][height-2][17] = 1;
			layers[ENTITIES][height-2][17] = 61;
			
			setExit(10, height-2);
			setStart();
		}
		
		/* Creates the entrance and exit to the level.
		 * 
		 * The logic goes thus - stairs up somewhere at the top of the level,
		 * stairs down somewhere at the bottom of the level
		 */
		public function createAccessPoints():void{
			var highest:int = int.MAX_VALUE;
			var entrance_room:Room;
			var ex:int, ey:int;
			var breaker:int = 0;
			var rooms:Vector.<Room> = bitmap.rooms;
			for(i = 0; i < rooms.length; i++){
				if(rooms[i].y < highest){
					entrance_room = rooms[i];
					highest = rooms[i].y;
				}
			}
			// we start at the top of the rooms and work our way down
			ey = entrance_room.y;
			do{
				if(breaker++ > 1000){
					throw new Error("failed to create entrance");
					break;
				}
				ex = entrance_room.x + random(entrance_room.width);
				// the room dimensions may have extended below
				if(layers[BLOCKS][ey + 1][ex] == 0) ey++;
			} while(!goodStairsPosition(ex, ey));
			setEntrance(ex, ey);
			
			var lowest:int = int.MIN_VALUE;
			var exit_room:Room;
			for(i = 0; i < rooms.length; i++){
				if(rooms[i].y > lowest){
					exit_room = rooms[i];
					lowest = rooms[i].y;
				}
			}
			ey = exit_room.y;
			do{
				if(breaker++ > 1000){
					throw new Error("failed to create exit");
					break;
				}
				ex = exit_room.x + random(exit_room.width);
				// the room dimensions may have extended below
				if(layers[BLOCKS][ey + 1][ex] == 0) ey++;
			} while(!goodStairsPosition(ex, ey));
			setExit(ex, ey);
			
			setStart();
		}
		
		public function goodStairsPosition(x:int, y:int):Boolean{
			var pos:uint = bitmap.bitmapData.getPixel32(x, y);
			var pos_below:uint = bitmap.bitmapData.getPixel32(x, y + 1);
			return (pos_below == DungeonBitmap.WALL || pos_below == DungeonBitmap.LEDGE) && (pos == DungeonBitmap.EMPTY || pos == DungeonBitmap.LEDGE);
		}
		
		/* Creates a stairway up */
		public function setEntrance(x:int, y:int):void{
			layers[ENTITIES][y][x] = MapTileConverter.STAIRS_UP_ID;
			entrance = new Pixel(x, y);
		}
		
		/* Creates a stairway down */
		public function setExit(x:int, y:int):void{
			layers[ENTITIES][y][x] = MapTileConverter.STAIRS_DOWN_ID;
			exit = new Pixel(x, y);
		}
		
		/* Creates a secret wall that can be broken through */
		public function createSecretWall(x:int, y:int):void{
			layers[ENTITIES][y][x] = MapTileConverter.SECRET_WALL_ID;
			layers[BLOCKS][y][x] = 1;
		}
		
		/* Lines up the start position with where the player should logically be entering this level */
		public function setStart():void{
			if(Stairs.last_stairs_used_type == Stairs.DOWN){
				start = entrance;
			} else if(Stairs.last_stairs_used_type == Stairs.UP){
				start = exit;
			}
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
		public function pillar(type:String, x:int, y0:int, y1:int):void{
			for(var i:int = y0; i <= y1; i++){
				if(type == "normal"){
					if(i == y0) layers[FOREGROUND][i][x] = 6;
					else if(i == y1) layers[FOREGROUND][i][x] = 8;
					else layers[FOREGROUND][i][x] = 7;
				}
			}
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
		
		public function createBackground():void{
			var r:int, c:int;
			for(r = 0; r < height; r++){
				for(c = 0; c < width; c++){
					if((r & 1) == 0 && (c & 1) == 0){
						layers[BACKGROUND][r][c] = 9 + random(4);
					}
				}
			}
		}
		/* integer random method - seeing as I'm going to be caning this sort of stuff */
		public static function random(n:int):int{
			return Math.random() * n;
		}
		/* is this pixel sitting on the edge of the map? it will likely cause me trouble if it is... */
		public static function onEdge(pixel:Pixel, width:int, height:int):Boolean{
			return pixel.x<= 0 || pixel.x >= width-1 || pixel.y <= 0 || pixel.y >= height-1;
		}
	}
	
}