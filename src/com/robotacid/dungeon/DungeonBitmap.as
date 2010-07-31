package com.robotacid.dungeon {
	import com.robotacid.geom.Pixel;
	import com.robotacid.util.array.randomiseArray;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	
	/**
	 * This class creates the dungeon layout as a bitmap
	 *
	 * This gives us the advantage of testing connectivity using the floodFill method and it
	 * means in the event of debugging, it's a simple task to see what state the level is in
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class DungeonBitmap extends Bitmap{
		
		public var level:int;
		
		public var rooms:Vector.<Room>;
		
		public var leftSecretRoom:Room;
		public var rightSecretRoom:Room;
		public var leftSecretWidth:Number;
		public var rightSecretWidth:Number;
		
		public var adjustedMapRect:Rectangle;
		
		// temp variables
		private var i:int, j:int, k:int, n:int, r:int, c:int, node:Node, room:Room;
		
		// pacing variables - these keep a consistent scale for the dungeon
		public var vertPace:int;
		public var horizPace:int;
		public var roominess:int;
		
		public static var directions:Array = [new Pixel(0, -1), new Pixel(1, 0), new Pixel(0, 1), new Pixel( -1, 0)];
		
		public static const MIN_ROOM_WIDTH:int = 4;
		public static const MIN_ROOM_HEIGHT:int = 3;
		
		public static const LEDGE_LENGTH:int = 4;
		public static const LEDGINESS:Number = 0.3;
		public static const LADDERINESS:Number = 0.3;
		
		// All features in the dungeon are represented by colours
		public static const PATH:uint = 0xFFFFFF88;
		public static const NODE:uint = 0xFFFF00FF;
		public static const WALL:uint = 0xFFFF0000;
		public static const EMPTY:uint = 0xFFFFFF00;
		public static const DIGGING:uint = 0xFF00FF00;
		public static const TUNNELLING:uint = 0xFF00CC00;
		public static const LADDER:uint = 0xFF0000FF;
		public static const LEDGE:uint = 0xFF00FF00;
		public static const LADDER_LEDGE:uint = 0xFF00FFFF;
		
		public static const PIT:uint = 0xFFFFFFFF;
		public static const SECRET:uint = 0xFFCCCCCC;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 1 << 1;
		public static const DOWN:int = 1 << 2;
		public static const LEFT:int = 1 << 3;
		
		public static const MAX_LEVEL:int = 7;
		public static const MIN_LEVEL:int = 3;
		
		public static const SECRET_FREQ:Number = 0.5;
		
		public function DungeonBitmap(level:int) {
			
			var bitmapData:BitmapData;
			
			if(level == 0){
				bitmapData = createOverWorld();
			} else {
				if(level > MIN_LEVEL){
					// the level parameter seems to fail at dishing out cool levels at about 8
					// so I'm capping it at 7
					level = level > MAX_LEVEL ? MAX_LEVEL : level;
					// but we also get some cool levels earlier, so let's randomise
					level = 1 + level * Math.random();
					level = level < MIN_LEVEL ? MIN_LEVEL : level;
				}
				
				this.level = level;
				
				// create pacing standard for this level
				horizPace = Math.ceil(level * 0.5) * 3;
				vertPace = Math.ceil(level * 0.5) * 2;
				roominess = 5;
				bitmapData = createRoomsAndTunnels();
			}
			
			super(bitmapData, "auto", false);
			
			if(level > 0){
				createRoutes();
				createPits();
				createSecrets();
			}
		}
		
		public function createOverWorld():BitmapData{
			var overworldMap:BitmapData = new BitmapData(20, 17, true, WALL);
			overworldMap.fillRect(new Rectangle(1, 1, overworldMap.width - 2, overworldMap.height - 2), EMPTY);
			return overworldMap;
		}
		
		
		/* This plots the size, number of rooms and how those rooms are connected */
		public function createRoomsAndTunnels():BitmapData{
			
			// sometimes the generator will fail - then we recreate the dungeon
			
			do{
				var goodLevel:Boolean = true;
			
				// create a list of rooms, then randomly assign a sibling
				rooms = new Vector.<Room>();
				for(i = 0; i < (roominess * level) + random(level * roominess); i++){
					rooms.push(new Room());
				}
				for(i = 0; i < rooms.length; i++){
					//for(j = 0; j < 1 + random(1); j++){
						do{
							var pick:int = random(rooms.length);
						} while(pick == i);
						rooms[i].siblings.push(rooms[pick]);
					//}
				}
				
				// now the hard part, positioning and then connecting them:
				
				// size each room and get a ball park size for each cell in the grid
				
				var cellHeight:int = 0;
				var cellWidth:int = 0;
				
				for(i = 0; i < rooms.length; i++){
					rooms[i].width = MIN_ROOM_WIDTH + random(horizPace);
					if(rooms[i].width > cellWidth) cellWidth = rooms[i].width;
					rooms[i].height = MIN_ROOM_HEIGHT + random(vertPace);
					if(rooms[i].height > cellHeight) cellHeight = rooms[i].height;
				}
				
				cellHeight += 2;
				cellWidth += 2;
				
				// get a grid size for the cells
				// we basically create a minimum of 2 or a maximum of half the number of cells either way
				var gridHeight:int = 2 + random((rooms.length / 2) - 2);
				var gridWidth:int = Math.ceil((1.0 * rooms.length) / gridHeight);
				
				// let's assign grid numbers
				var nums:Array = [];
				for(i = 0; i < gridHeight * gridWidth; i++) nums.push(i);
				for(i = 0; i < rooms.length; i++){
					var n:int = random(nums.length);
					rooms[i].gridNum = nums[n];
					nums.splice(n, 1);
				}
				
				// we use a bitmap for digging, we can use floodFill to verify connectivity later:
				var data:BitmapData = new BitmapData(gridWidth * cellWidth, gridHeight * cellHeight, true, WALL);
				
				// place the rooms in their cells
				for(i = 0; i < rooms.length; i++){
					rooms[i].x = (rooms[i].gridNum % gridWidth) * cellWidth;
					rooms[i].y = (rooms[i].gridNum / gridWidth);
					rooms[i].y *= cellHeight;
					// random offset the rooms
					rooms[i].x += 1 + random((cellWidth - 1) - rooms[i].width);
					rooms[i].y += 1 + random((cellHeight - 1) - rooms[i].height);
					// draw the room:
					data.fillRect(new Rectangle(
						rooms[i].x, rooms[i].y, rooms[i].width, rooms[i].height
					), DIGGING);
				}
				
				// now we have to connect the rooms to their siblings
				
				var side:int;
				for(i = 0; i < rooms.length; i++){
					for(j = 0; j < rooms[i].siblings.length; j++){
						// pick an exit
						var exit:Pixel = new Pixel();
						room = rooms[i];
						do{
							side = 1 << random(4);
							if(side & UP){
								exit.x = room.x + random(room.width);
								exit.y = room.y;
							} else if(side & RIGHT){
								exit.x = room.x + room.width - 1;
								exit.y = room.y + random(room.height);
							} else if(side & DOWN){
								exit.x = room.x + random(room.width);
								exit.y = room.y + room.height - 1;
							} else if(side & LEFT){
								exit.x = room.x;
								exit.y = room.y + random(room.height);
							}
						} while(room.touchesDoors(exit) || onEdge(exit, data.width, data.height));
						room.doors.push(exit);
						// now pick an entrance
						var entrance:Pixel = new Pixel();
						room = rooms[i].siblings[j];
						do{
							side = 1 << random(4);
							if(side & UP){
								entrance.x = room.x + random(room.width);
								entrance.y = room.y - 1;
							} else if(side & RIGHT){
								entrance.x = room.x + room.width;
								entrance.y = room.y + random(room.height);
							} else if(side & DOWN){
								entrance.x = room.x + random(room.width);
								entrance.y = room.y + room.height;
							} else if(side & LEFT){
								entrance.x = room.x - 1;
								entrance.y = room.y + random(room.height);
							}
						} while(room.touchesDoors(entrance) || onEdge(entrance, data.width, data.height));
						room.doors.push(entrance);
						
						// try getting there, favour pre-existing routes
						
						var neighbours:Vector.<Pixel> = new Vector.<Pixel>(4, true);
						// this randomisation keeps the search from being weighted
						randomiseArray(directions);
						var m:int = 0;
						do{
							data.setPixel32(exit.x, exit.y, TUNNELLING);
							neighbours[0] = new Pixel(exit.x + directions[0].x, exit.y + directions[0].y);
							neighbours[1] = new Pixel(exit.x + directions[1].x, exit.y + directions[1].y);
							neighbours[2] = new Pixel(exit.x + directions[2].x, exit.y + directions[2].y);
							neighbours[3] = new Pixel(exit.x + directions[3].x, exit.y + directions[3].y);
							var best:int = int.MAX_VALUE;
							var choice:Pixel = null;
							for(k = 0; k < neighbours.length; k++){
								var dist:int = entrance.mDist(neighbours[k]);
								if(data.getPixel32(neighbours[k].x, neighbours[k].y) != DIGGING){
									dist+=3;
								}
								if(dist < best){
									best = dist;
									choice = neighbours[k];
								}
							}
							if(choice){
								exit.x = choice.x;
								exit.y = choice.y;
							} else {
								break;
							}
							// it does not pay to dig forever
							m++;
							if(m > 200){
								break;
							}
						} while(exit.x != entrance.x || exit.y != entrance.y);
						
						data.setPixel32(exit.x, exit.y, TUNNELLING);
						data.floodFill(exit.x, exit.y, DIGGING);
					}
				}
				
				// did the room generation create two separate networks?
				data.floodFill(rooms[0].x, rooms[0].y, EMPTY);
				
				for(i = 0; i < rooms.length; i++){
					if(data.getPixel32(rooms[i].x, rooms[i].y) != EMPTY){
						trace("failed");
						goodLevel = false;
					}
				}
			
			} while(!goodLevel);
			
			// trim the map, we may have a large portion of unused rock
			var mapBounds:Rectangle = data.getColorBoundsRect(0xFFFFFFFF, EMPTY);
			// the rooms will have to be moved!
			var moveX:int = 1 - mapBounds.x;
			var moveY:int = 1 - mapBounds.y;
			for(i = 0; i < rooms.length; i++){
				rooms[i].x += moveX;
				rooms[i].y += moveY;
			}
			var trimmedData:BitmapData = new BitmapData(mapBounds.width + 2, mapBounds.height + 2, true, 0xFFFF0000);
			
			trimmedData.copyPixels(data, mapBounds, new Point(1, 1));
			
			return trimmedData;
		}
		
		/* Given a network of rooms and tunnels, a platform game character requires ledges and
		 * ladders to navigate that network and be able to visit every corner of it */
		public function createRoutes():void{
			
			// count all the cliffs that are in the level. A cliff is an L-shaped area where the
			// character can fall off
			
			// cliffs form the basis for the graph we will generate to create a route around the map
			// every cliff is two nodes (the ledge where you step off, and the bottom) in the graph
			
			// first we get the bitmap as a vector, this makes iterating over it faster
			
			var pixels:Vector.<uint> = bitmapData.getVector(bitmapData.rect);
			var mapWidth:int = bitmapData.width;
			var cliffs:Vector.<int> = new Vector.<int>;
			
			// there is a border around the map - we don't need to count it
			for(i = mapWidth; i < pixels.length - mapWidth; i++){
				c = i % mapWidth;
				if(c > 0 && c < mapWidth - 1){
					if(pixels[i] != WALL && pixels[i - mapWidth] != WALL){
						// we have a gap, now we look for the cliffs
						if(pixels[i - 1] == WALL && pixels[i - 1 - mapWidth] != WALL){
							cliffs.push(i - mapWidth);
							pixels[i - mapWidth] = NODE;
						} else if(pixels[i + 1] == WALL && pixels[(i + 1) - mapWidth] != WALL){
							cliffs.push(i - mapWidth);
							pixels[i - mapWidth] = NODE;
						}
					}
					// we can use this sweep to mark out horizontal paths as we go, saving time
					if(pixels[i] == EMPTY && pixels[i + mapWidth] == WALL){
						pixels[i] = PATH;
					}
				}
			}
			
			// we've marked out the top nodes, now we'll get the bottom nodes and mark out paths as we do
			for(i = 0; i < cliffs.length; i++){
				n = cliffs[i] + mapWidth;
				while(pixels[n] != NODE && pixels[n] != WALL){
					if(pixels[n] != NODE) pixels[n] = pixels[n + mapWidth] == WALL ? NODE : PATH;
					n += mapWidth;
				}
			}
			
			// here's comes the graph to reduce the number of routes and give us a more
			// tricky dungeon to navigate
			
			var graph:Vector.<Node> = new Vector.<Node>();
			
			// create an empty grid so that locating graph nodes is fast
			var graphGrid:Vector.<Vector.<Node>> = new Vector.<Vector.<Node>>(bitmapData.height, true);
			for(r = 0; r < bitmapData.height; r++){
				graphGrid[r] = new Vector.<Node>(mapWidth, true);
			}
			for(i = mapWidth; i < pixels.length - mapWidth; i++){
				if(pixels[i] == NODE){
					c = i % mapWidth;
					r = i / mapWidth;
					node = new Node(c, r);
					graph.push(node);
					graphGrid[r][c] = node;
				}
			}
			// now search for connections
			var dirs:Vector.<int> = new Vector.<int>(4, true);
			dirs[0] = 1;
			dirs[1] = -1;
			dirs[3] = -mapWidth;
			dirs[2] = mapWidth;
			
			var pos:int;
			
			for(i = 0; i < graph.length; i++){
				
				// only 4 directions to look in
				pos = graph[i].x + graph[i].y * mapWidth;
				
				for(j = 0; j < dirs.length; j++){
					if(pixels[pos + dirs[j]] == PATH || pixels[pos + dirs[j]] == NODE){
						n = pos + dirs[j];
						do{
							if(pixels[n] == NODE){
								c = n % mapWidth;
								r = n / mapWidth;
								graph[i].connections.push(graphGrid[r][c]);
								graph[i].connectionsActive.push(false);
								graphGrid[r][c].connections.push(graph[i]);
								graphGrid[r][c].connectionsActive.push(false);
								// mark out where drops are - it can lead to broken maps
								if(j == 2){
									graph[i].drop = true;
								}
								break;
							}
							n += dirs[j];
						} while(pixels[n] == PATH || pixels[n] == NODE);
					}
				}
			}
			
			// so lets visit all points on the graph now and mark our good connections
			// whilst we're at it we'll delete our node pixels to clean up
			
			var visitedNodes:Vector.<Node> = new Vector.<Node>();
			node = graph[(Math.random() * graph.length) >> 0];
			node.visited = true;
			visitedNodes.push(node);
			pixels[node.x + node.y * mapWidth] = PATH;
			
			i = 0;
			while(i < graph.length){
				search:
				for(i = 0; i < visitedNodes.length; i++){
					for(j = 0; j < visitedNodes[i].connections.length; j++){
						if(!visitedNodes[i].connectionsActive[j] && !visitedNodes[i].connections[j].visited){
							visitedNodes[i].connectionsActive[j] = true;
							visitedNodes[i].connections[j].visited = true;
							pixels[visitedNodes[i].connections[j].x + visitedNodes[i].connections[j].y * mapWidth] = PATH;
							visitedNodes[i].connections[j].connectionsActive[visitedNodes[i].connections[j].connections.indexOf(visitedNodes[i])] = true;
							visitedNodes.push(visitedNodes[i].connections[j]);
							break search;
						}
					}
				}
			}
			
			// we load the pixels back in to flood out the paths
			bitmapData.setVector(bitmapData.rect, pixels);
			bitmapData.floodFill(graph[0].x, graph[0].y, EMPTY);
			pixels = bitmapData.getVector(bitmapData.rect);
			
			// DEBUG! ---------------------------------------------------------------
			// did I fuck up?
			// let's draw it and find out
			/*var gfx:Graphics = Game.debug.graphics;
			gfx.lineStyle(2, 0);
			for(i = 0; i < graph.length; i++){
				for(j = 0; j < graph[i].connections.length; j++){
					if(graph[i].connectionsActive[j]){
						gfx.moveTo((graph[i].x + 0.5) * Game.SCALE, (graph[i].y + 0.5) * Game.SCALE);
						gfx.lineTo((graph[i].connections[j].x + 0.5) * Game.SCALE, (graph[i].connections[j].y + 0.5) * Game.SCALE);
					}
				}
			}*/
			
			// Now lets put in ladders and ledges
			
			var dest:int;
			
			// wherever there's a vertical node connection, we slap a ladder in there
			// except that for now we mark out the tops of ladders, and cap a ledge in where a ladder
			// would normally stop and drop the player into open space
			for(i = 0; i < graph.length; i++){
				for(j = 0; j < graph[i].connections.length; j++){
					if(graph[i].connectionsActive[j]){
						if(graph[i].connections[j].x == graph[i].x){
							n = graph[i].x + graph[i].y * mapWidth;
							dest = graph[i].connections[j].x + graph[i].connections[j].y * mapWidth;
							// xor swap so we get end the job with a ladder at the top
							if(dest > n){
								n ^= dest
								dest ^= n;
								n ^= dest;
							}
							if(pixels[n + mapWidth] != WALL){
								pixels[n + mapWidth] = LEDGE;
							}
							pixels[dest + mapWidth] = LADDER_LEDGE;
						}
						// after we query a connection, we deactivate at both ends, we don't need it anymore
						graph[i].connectionsActive[j] = false;
						graph[i].connections[j].connectionsActive[graph[i].connections[j].connections.indexOf(graph[i])] = false;
					}
				}
				// also we slap a ledge in under any drop node (a node with a downwards link) - they can cause broken maps
				if(graph[i].drop){
					if(pixels[graph[i].x + (graph[i].y + 1) * mapWidth] == EMPTY){
						pixels[graph[i].x + (graph[i].y + 1) * mapWidth] = LEDGE;
					}
				}
			}
			
			// sprinkle some extra ladders in
			for(i = mapWidth; i < pixels.length - mapWidth; i++){
				if(pixels[i] == EMPTY && pixels[i - mapWidth] == EMPTY){
					if(pixels[i - 1] == WALL && pixels[i + 1] == EMPTY && Math.random() < LADDERINESS){
						pixels[i] = LADDER_LEDGE;
					} else if(pixels[i + 1] == WALL && pixels[i - 1] == EMPTY && Math.random() < LADDERINESS){
						pixels[i] = LADDER_LEDGE;
					}
				}
			}
			
			// all of our ladders are slap-bang next to walls, how about we see if we can move them into the
			// room a little and extend the ledge that reaches to them
			
			// note to self - a ledge with a wall on top of it looks fucking stupid
			
			for(i = mapWidth; i < pixels.length - mapWidth; i++){
				if(pixels[i] == LADDER_LEDGE){
					if(pixels[i - 1] == EMPTY){
						// pull out the ladder ledge
						j = i;
						for(n = Math.random() * LEDGE_LENGTH; n; n--){
							if(pixels[j - 1] == EMPTY && pixels[j - 1 - mapWidth] != WALL){
								pixels[j] = LEDGE;
								pixels[j - 1] = LADDER_LEDGE;
							} else break;
							j--;
						}
						// add a bit of extension past it
						for(n = Math.random() * LEDGE_LENGTH; n; n--){
							if(pixels[j - 1] == EMPTY && pixels[j - 1 - mapWidth] != WALL){
								pixels[j - 1] = LEDGE;
							} else break;
							j--;
						}
					} else if(pixels[i + 1] == EMPTY){
						// push out the ladder ledge
						for(n = Math.random() * LEDGE_LENGTH; n; n--){
							if(pixels[i + 1] == EMPTY && pixels[i + 1 - mapWidth] != WALL){
								pixels[i] = LEDGE;
								pixels[i + 1] = LADDER_LEDGE;
							} else break;
							i++;
						}
						// add a bit of extension past it
						j = i;
						for(n = Math.random() * LEDGE_LENGTH; n; n--){
							if(pixels[j + 1] == EMPTY && pixels[j + 1 - mapWidth] != WALL){
								pixels[j + 1] = LEDGE;
							} else break;
							j++;
						}
					}
				}
			}
			
			// cast ladders down from all the ladder ledges
			for(i = mapWidth; i < pixels.length - mapWidth; i++){
				if(pixels[i] == LADDER_LEDGE){
					n = i + mapWidth;
					while(pixels[n] == EMPTY){
						pixels[n] = LADDER;
						n += mapWidth;
					}
				}
			}
			
			// sprinkle a few more ledges in
			for(i = mapWidth; i < pixels.length - mapWidth; i++){
				if(pixels[i] == LADDER && Math.random() < LEDGINESS){
					if(pixels[i - 1] == EMPTY){
						j = i;
						for(n = Math.random() * LEDGE_LENGTH; n; n--){
							if(pixels[j - 1] == EMPTY && pixels[j - 1 - mapWidth] != WALL){
								pixels[j - 1] = LEDGE;
							} else if(pixels[j - 1] == LADDER){
								pixels[j - 1] = LADDER_LEDGE;
							}
							else break;
							j--;
							pixels[i] = LADDER_LEDGE;
						}
					}
					if(pixels[i + 1] == EMPTY){
						j = i;
						for(n = Math.random() * LEDGE_LENGTH; n; n--){
							if(pixels[j + 1] == EMPTY && pixels[j + 1 - mapWidth] != WALL){
								pixels[j + 1] = LEDGE;
							} else if(pixels[j + 1] == LADDER){
								pixels[j + 1] = LADDER_LEDGE;
							} else break;
							j++;
							pixels[i] = LADDER_LEDGE;
						}
					}
				}
			}
			
			bitmapData.setVector(bitmapData.rect, pixels);
		}
		
		/* This finds suitable locations for pits and digs them, leaving a trap marker for the Map class
		 * to turn into a Trap Entity */
		public function createPits():void{
			var mapWidth:int = bitmapData.width;
			var pits:Vector.<int> = new Vector.<int>();
			var pixels:Vector.<uint> = bitmapData.getVector(bitmapData.rect);
			
			// any bottom corner can serve as a location for a pit, as there always seems to be a
			// route around
			
			// - just added a mod to the pits so they cap with a ledge above them after triggering
			for(i = mapWidth; i < pixels.length - mapWidth * 2; i++){
				if(pixels[i] != WALL && pixels[i] != LADDER && pixels[i] != LADDER_LEDGE && pixels[i + mapWidth] == WALL){// && (pixels[i - 1] == WALL || pixels[i + 1] == WALL)){
					// we need to verify the pit can tunnel down to a new area
					for(j = i + mapWidth * 2; j < pixels.length - mapWidth * 2; j += mapWidth){
						if(pixels[j] == EMPTY){
							pits.push(i + mapWidth);
							break;
						}
					}
				}
			}
			
			// we have a selection of locations, it remains to select from them and dig
			var num:int = level;
			while(num > 0 && pits.length > 0){
				var r:int = Math.random() * pits.length;
				pixels[pits[r]] = PIT;
				for(i = pits[r] + mapWidth; i < pixels.length - mapWidth * 2; i += mapWidth){
					if(pixels[i] == EMPTY){
						break;
					} else {
						pixels[i] = EMPTY;
					}
				}
				pits.splice(r, 1);
				num--;
			}
			
			bitmapData.setVector(bitmapData.rect, pixels);
		}
		
		/* This creates extra rooms on the edges of the map, hidden by a destructible wall */
		public function createSecrets():void{
			adjustedMapRect = new Rectangle(0, 0, bitmapData.width * Game.SCALE, bitmapData.height * Game.SCALE);
			
			var mapWidth:int = bitmapData.width;
			var secretsLeft:Vector.<int> = new Vector.<int>();
			var secretsRight:Vector.<int> = new Vector.<int>();
			var pixels:Vector.<uint> = bitmapData.getVector(bitmapData.rect);
			
			// we check the edges of the map for locations where a secret room would be acceptable
			
			// to avoid any overlap and need to recalculate routes, only one secret per side maximum
			
			var room:Room, pos:int, posY:int, corridorLength:int, temp:BitmapData, ladderPos:int, ledgePos:int;
			
			// left edge:
			for(i = mapWidth; i < pixels.length - mapWidth; i += mapWidth){
				if(pixels[i+1] != WALL && pixels[i+1+mapWidth] != LADDER && pixels[i+1+mapWidth] != EMPTY && pixels[i+1+mapWidth] != PIT){
					secretsLeft.push(i);
				}
			}
			
			if(secretsLeft.length && Math.random() < SECRET_FREQ){
				pos = secretsLeft[(Math.random() * secretsLeft.length) >> 0];
				posY = pos / mapWidth;
				room = new Room();
				room.width = MIN_ROOM_WIDTH + random(horizPace * 0.5);
				room.height = MIN_ROOM_HEIGHT + random(vertPace * 0.5);
				if(room.height > bitmapData.height - 2) room.height = bitmapData.height - 2;
				corridorLength = 1 + random(5);
				// recreate bitmap
				temp = new BitmapData(1 + mapWidth + corridorLength + room.width, bitmapData.height, true, WALL);
				temp.copyPixels(bitmapData, bitmapData.rect, new Point(1 + room.width + corridorLength, 0));
				bitmapData = temp;
				pixels = bitmapData.getVector(bitmapData.rect);
				pixels[1 + room.width + corridorLength + posY * bitmapData.width] = SECRET;
				for(i = 0; i < corridorLength; i++){
					pixels[-i + room.width + corridorLength + posY * bitmapData.width] = EMPTY
				}
				room.x = 1;
				room.y = posY - random(room.height);
				if(room.y + room.height > bitmapData.height - 1) room.y = bitmapData.height - 1 - room.height;
				if(room.y < 1) room.y = 1;
				bitmapData.setVector(bitmapData.rect, pixels);
				bitmapData.fillRect(new Rectangle(1, room.y, room.width, room.height), EMPTY);
				// enable access:
				// I like the idea of the secret rooms being spartan in function
				// they should feel like a cubby hole
				pixels = bitmapData.getVector(bitmapData.rect);
				if(posY < room.y + room.height - 1){
					ladderPos = 1 + random(room.width) + (posY + 1) * bitmapData.width;
					pixels[ladderPos] = LADDER_LEDGE;
					ledgePos = ladderPos + 1;
					while(pixels[ledgePos] != WALL){
						pixels[ledgePos] = LEDGE;
						ledgePos++;
					}
					ledgePos = ladderPos - 1;
					while(pixels[ledgePos] != WALL && Math.random() < 0.5){
						pixels[ledgePos] = LEDGE;
						ledgePos--;
					}
					ladderPos += bitmapData.width;
					while(pixels[ladderPos] != WALL){
						pixels[ladderPos] = LADDER;
						ladderPos += bitmapData.width;
					}
				}
				bitmapData.setVector(bitmapData.rect, pixels);
				leftSecretRoom = room;
				leftSecretWidth = (1 + room.width + corridorLength) * Game.SCALE;
				adjustedMapRect.x += leftSecretWidth;
				for(i = 0; i < rooms.length; i++){
					rooms[i].x += 1 + room.width + corridorLength;
				}
			}
			
			mapWidth = bitmapData.width;
			
			// right edge:
			for(i = mapWidth + mapWidth - 1; i < pixels.length - mapWidth; i += mapWidth){
				if(pixels[i-1] != WALL && pixels[i-1+mapWidth] != LADDER && pixels[i-1+mapWidth] != EMPTY && pixels[i-1+mapWidth] != PIT){
					secretsRight.push(i);
				}
			}
			
			if(secretsRight.length && Math.random() < SECRET_FREQ){
				pos = secretsRight[(Math.random() * secretsRight.length) >> 0];
				posY = pos / mapWidth;
				room = new Room();
				room.width = MIN_ROOM_WIDTH + random(horizPace * 0.5);
				room.height = MIN_ROOM_HEIGHT + random(vertPace * 0.5);
				if(room.height > bitmapData.height - 2) room.height = bitmapData.height - 2;
				corridorLength = 1 + random(5);
				// recreate bitmap
				temp = new BitmapData(1 + bitmapData.width + corridorLength + room.width, bitmapData.height, true, WALL);
				temp.copyPixels(bitmapData, bitmapData.rect, new Point());
				bitmapData = temp;
				pixels = bitmapData.getVector(bitmapData.rect);
				pixels[mapWidth - 1 + posY * bitmapData.width] = SECRET;
				for(i = 0; i < corridorLength; i++){
					pixels[mapWidth + i + posY * bitmapData.width] = EMPTY
				}
				room.x = mapWidth + corridorLength;
				room.y = posY - random(room.height);
				if(room.y + room.height > bitmapData.height - 1) room.y = bitmapData.height - 1 - room.height;
				if(room.y < 1) room.y = 1;
				bitmapData.setVector(bitmapData.rect, pixels);
				bitmapData.fillRect(new Rectangle(room.x, room.y, room.width, room.height), EMPTY);
				// enable access:
				// I like the idea of the secret rooms being spartan in function
				// they should feel like a cubby hole
				pixels = bitmapData.getVector(bitmapData.rect);
				if(posY < room.y + room.height - 1){
					ladderPos = room.x + random(room.width) + (posY + 1) * bitmapData.width;
					pixels[ladderPos] = LADDER_LEDGE;
					ledgePos = ladderPos - 1;
					while(pixels[ledgePos] != WALL){
						pixels[ledgePos] = LEDGE;
						ledgePos--;
					}
					ledgePos = ladderPos + 1;
					while(pixels[ledgePos] != WALL && Math.random() < 0.5){
						pixels[ledgePos] = LEDGE;
						ledgePos++;
					}
					ladderPos += bitmapData.width;
					while(pixels[ladderPos] != WALL){
						pixels[ladderPos] = LADDER;
						ladderPos += bitmapData.width;
					}
				}
				bitmapData.setVector(bitmapData.rect, pixels);
				rightSecretWidth = (1 + room.width + corridorLength) * Game.SCALE;
				rightSecretRoom = room;
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