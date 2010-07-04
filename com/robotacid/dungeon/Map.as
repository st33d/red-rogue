package com.robotacid.dungeon {
	import com.robotacid.engine.Character;
	import com.robotacid.engine.MapTileConverter;
	import com.robotacid.engine.Stairs;
	import com.robotacid.geom.Pixel;
	import com.robotacid.util.array.randomiseArray;
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
			//bitmap.scaleX = bitmap.scaleY = 4;
			//g.addChild(bitmap);
			
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
			//layers[ENTITIES][44][8] = 22;
			
			// access points
			setEntrance(12, 44);
			setExit(10, 44);
			setStart();
			
			//layers[BLOCKS][44][14] = 1;
			//layers[ENTITIES][44][14] = 60;
			
			createSecretWall(14, 44);
			
			
			//layers[BLOCKS][40][10] = 1;
			//layers[BLOCKS][44][10] = 1;
		}
		
		
		
		/* This is where we convert our map template into a dungeon proper made of tileIds and other
		 * information
		 */
		public function convertDungeonBitmap(bitmapData:BitmapData):void{
			width = bitmapData.width;
			height = bitmapData.height;
			// background
			layers.push(createGrid(null, bitmapData.width, bitmapData.height));
			// blocks - start with a full grid
			layers.push(createGrid(1, bitmapData.width, bitmapData.height));
			// game objects
			layers.push(createGrid(null, bitmapData.width, bitmapData.height));
			// foreground
			layers.push(createGrid(null, bitmapData.width, bitmapData.height));
			
			var pixels:Vector.<uint> = bitmapData.getVector(bitmapData.rect);
			
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
				} else if(pixels[i] == DungeonBitmap.PIT){
					layers[ENTITIES][r][c] = MapTileConverter.PIT_ID;
				} else if(pixels[i] == DungeonBitmap.SECRET){
					layers[ENTITIES][r][c] = MapTileConverter.SECRET_WALL_ID;
				}
			}
			
			// a good dungeon needs to be full of loot and monsters
			// in comes the content manager
			
			var content:Content = new Content();
			
			content.populateLevel(level, bitmap, layers);
			
			// create the access points
			
			createAccessPoints();
			setDartTraps();
		}
		
		/* Create the overworld
		 *
		 * The overworld is present to create a contrast with the dungeon. It is in colour and so
		 * are you. You can wield no weapons here and your minion is unseen
		 * There is a health stone for restoring health and a grindstone -
		 * an allegory of improving yourself in the real world as opposed to a fantasy where
		 * you kill people to better yourself, that you can ironically destroy by levelling up next to
		 *
		 * This bit I haven't finished yet :P
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
			var entranceRoom:Room;
			var ex:int, ey:int;
			var breaker:int = 0;
			var rooms:Vector.<Room> = bitmap.rooms;
			for(i = 0; i < rooms.length; i++){
				if(rooms[i].y < highest){
					entranceRoom = rooms[i];
					highest = rooms[i].y;
				}
			}
			// we start at the top of the rooms and work our way down
			ey = entranceRoom.y;
			do{
				if(breaker++ > 1000){
					throw new Error("failed to create entrance");
					break;
				}
				ex = entranceRoom.x + random(entranceRoom.width);
				// the room dimensions may have extended below
				if(layers[BLOCKS][ey + 1][ex] == 0) ey++;
				if(layers[BLOCKS][ey][ex] == 1) ey = entranceRoom.y;
			} while(!goodStairsPosition(ex, ey));
			setEntrance(ex, ey);
			
			var lowest:int = int.MIN_VALUE;
			var exitRoom:Room;
			for(i = 0; i < rooms.length; i++){
				if(rooms[i].y > lowest){
					exitRoom = rooms[i];
					lowest = rooms[i].y;
				}
			}
			ey = exitRoom.y;
			do{
				if(breaker++ > 1000){
					throw new Error("failed to create exit");
					break;
				}
				ex = exitRoom.x + random(exitRoom.width);
				// the room dimensions may have extended below
				if(layers[BLOCKS][ey + 1][ex] == 0) ey++;
				if(layers[BLOCKS][ey][ex] == 1) ey = exitRoom.y;
			} while(!goodStairsPosition(ex, ey));
			setExit(ex, ey);
			
			setStart();
		}
		
		public function goodStairsPosition(x:int, y:int):Boolean{
			var pos:uint = bitmap.bitmapData.getPixel32(x, y);
			var pos_below:uint = bitmap.bitmapData.getPixel32(x, y + 1);
			if(bitmap.leftSecretRoom && bitmap.leftSecretRoom.contains(x, y)) return false;
			if(bitmap.rightSecretRoom && bitmap.rightSecretRoom.contains(x, y)) return false;
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
			if(Stairs.lastStairsUsedType == Stairs.DOWN){
				start = entrance;
			} else if(Stairs.lastStairsUsedType == Stairs.UP){
				start = exit;
			}
		}
		
		/* This adds dart traps to the level */
		public function setDartTraps():void{
			var numTraps:int = level;
			var trapPositions:Vector.<Pixel> = new Vector.<Pixel>();
			var pixels:Vector.<uint> = bitmap.bitmapData.getVector(bitmap.bitmapData.rect);
			var mapWidth:int = bitmap.bitmapData.width;
			for(i = mapWidth; i < pixels.length - mapWidth; i++){
				if((pixels[i] == DungeonBitmap.WALL) && pixels[i - mapWidth] == DungeonBitmap.EMPTY){
					for(j = i - mapWidth; j > mapWidth; j -= mapWidth){
						if(pixels[j] == DungeonBitmap.LEDGE || pixels[j] == DungeonBitmap.PIT){
							break;
						} else if(pixels[j] == DungeonBitmap.WALL){
							trapPositions.push(new Pixel(i % mapWidth, i / mapWidth));
							break;
						}
					}
				}
			}
			
			while(numTraps > 0 && trapPositions.length > 0){
				var trapIndex:int = trapPositions.length * Math.random();
				var trapPos:Pixel = trapPositions[trapIndex];
				layers[ENTITIES][trapPos.y][trapPos.x] = Math.random() < 0.5 ? MapTileConverter.POISON_DART_ID : MapTileConverter.TELEPORT_DART_ID;
				numTraps--;
				trapPositions.splice(trapIndex, 1);
				
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