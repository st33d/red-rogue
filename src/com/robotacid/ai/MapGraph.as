package com.robotacid.ai {
	import com.robotacid.level.MapBitmap;
	import com.robotacid.geom.Pixel;
	import com.robotacid.util.XorRandom;
	import flash.display.Graphics;
	/**
	 * Provides a searchable graph for the Brain object
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class MapGraph{
		
		public var width:int;
		public var height:int;
		public var nodes:Vector.<Vector.<Node>>;
		public var escapeNodes:Vector.<Vector.<Node>>;
		
		// A* vars
		private var searchId:int;
		private var open:Vector.<Node>;
		
		// temp vars
		private var node:Node;
		
		public function MapGraph(bitmap:MapBitmap, exitPos:Pixel) {
			searchId = 0;
			nodes = new Vector.<Vector.<Node>>();
			escapeNodes = new Vector.<Vector.<Node>>();
			width = bitmap.bitmapData.width;
			height = bitmap.bitmapData.height;
			var r:int, c:int, i:int;
			for(r = 0; r < height; r++){
				nodes.push(new Vector.<Node>());
				escapeNodes.push(new Vector.<Node>());
				for(c = 0; c < width; c++){
					nodes[r].push(null);
					escapeNodes[r].push(null);
				}
			}
			// there is a node on every surface and ladder, and on nodes in space adjacent to surfaces
			var pixels:Vector.<uint> = bitmap.bitmapData.getVector(bitmap.bitmapData.rect);
			for(i = width; i < pixels.length - width; i++){
				if(
					(
						(pixels[i] != MapBitmap.WALL && pixels[i] != MapBitmap.PIT) &&
						(
							(
								pixels[i + width] == MapBitmap.PIT ||
								pixels[i + width] == MapBitmap.LEDGE ||
								pixels[i + width] == MapBitmap.LADDER_LEDGE ||
								pixels[i + width] == MapBitmap.WALL
							) ||
							(
								i < pixels.length - (width + 1) &&  pixels[i + 1] != MapBitmap.WALL && (
									pixels[i + width + 1] == MapBitmap.PIT ||
									pixels[i + width + 1] == MapBitmap.LEDGE ||
									pixels[i + width + 1] == MapBitmap.LADDER_LEDGE ||
									pixels[i + width + 1] == MapBitmap.WALL
								)
							) ||
							(
								pixels[i - 1] != MapBitmap.WALL && (
									pixels[i + width - 1] == MapBitmap.PIT ||
									pixels[i + width - 1] == MapBitmap.LEDGE ||
									pixels[i + width - 1] == MapBitmap.LADDER_LEDGE ||
									pixels[i + width - 1] == MapBitmap.WALL
								)
							)
						)
					) ||
					pixels[i] == MapBitmap.LADDER || pixels[i] == MapBitmap.LADDER_LEDGE
				){
					r = i / width;
					c = i % width;
					nodes[r][c] = new Node(c, r);
					escapeNodes[r][c] = new Node(c, r);
				}
			}
			connectNodes(pixels);
			if(exitPos) connectEscapeNodes(escapeNodes[exitPos.y][exitPos.x]);
		}
		
		/* Create connections between the nodes based on the navigation behaviour desired */
		public function connectNodes(pixels:Vector.<uint>):void{
			// connect the nodes
			var r:int, c:int, n:int, i:int;
			var node:Node, escapeNode:Node, connection:Node, escapeConnection:Node;
			for(r = 1; r < height - 1; r++){
				for(c = 1; c < width - 1; c++){
					node = nodes[r][c];
					if(node){
						n = c + r * width;
						escapeNode = escapeNodes[r][c];
						// because we are walking top to bottom, left to right
						// we only look right and down
						connection = nodes[r][c + 1];
						escapeConnection = escapeNodes[r][c + 1];
						if(connection){
							// check for cliff nodes, they are one way only
							if(pixels[n + width] != MapBitmap.EMPTY){
								node.connections.push(connection);
								// reverse the connection for the escape node - we need to search backwards
								escapeConnection.connections.push(escapeNode);
							}
							if(pixels[n + 1 + width] != MapBitmap.EMPTY){
								connection.connections.push(node);
								// reverse the connection for the escape node - we need to search backwards
								escapeNode.connections.push(escapeConnection);
							}
						}
						// create a drop node
						if(
							pixels[n + width] == MapBitmap.LEDGE || pixels[n + width] == MapBitmap.EMPTY
						){
							for(i = r + 1; i < height; i++){
								if(nodes[i][c]){
									node.connections.push(nodes[i][c]);
									// reverse the connection for the escape node - we need to search backwards
									escapeNodes[i][c].connections.push(escapeNode);
									break;
								}
							}
						// create a climbing node
						} else if(
							pixels[n + width] == MapBitmap.LADDER_LEDGE ||
							pixels[n + width] == MapBitmap.LADDER
						){
							node.connections.push(nodes[r + 1][c]);
							nodes[r + 1][c].connections.push(node);
							escapeNode.connections.push(escapeNodes[r + 1][c]);
							escapeNodes[r + 1][c].connections.push(escapeNode);
						}
					}
				}
			}
			
			// dive connections - descending upon the enemy is a popular tactic,
			// so we cast down diagonally for combat drops
			var walkC:int, walkR:int;
			for(r = 1; r < height - 1; r++){
				for(c = 1; c < width - 1; c++){
					n = c + r * width;
					node = nodes[r][c];
					if(
						node &&
						pixels[n] != MapBitmap.WALL && pixels[n] != MapBitmap.PIT &&
						pixels[n + width] != MapBitmap.WALL && pixels[n + width] != MapBitmap.PIT &&
						pixels[n - width] != MapBitmap.WALL && pixels[n - width] != MapBitmap.PIT
					){
						// walk down right
						walkC = c + 1;
						walkR = r + 1;
						while(walkC < width - 1 && walkR < height - 1){
							n = walkC + walkR * width;
							if(
								pixels[n] == MapBitmap.WALL || pixels[n] == MapBitmap.PIT ||
								pixels[n - width] == MapBitmap.WALL || pixels[n - width] == MapBitmap.PIT
							) break;
							if(nodes[walkR][walkC]){
								node.connections.push(nodes[walkR][walkC]);
								break;
							}
							walkC++;
							walkR++;
						}
						// walk down left
						walkC = c - 1;
						walkR = r + 1;
						while(walkC > 0 && walkR < height - 1){
							n = walkC + walkR * width;
							if(
								pixels[n] == MapBitmap.WALL || pixels[n] == MapBitmap.PIT ||
								pixels[n - width] == MapBitmap.WALL || pixels[n - width] == MapBitmap.PIT
							) break;
							if(nodes[walkR][walkC]){
								node.connections.push(nodes[walkR][walkC]);
								break;
							}
							walkC--;
							walkR++;
						}
					}
				}
			}
		}
		
		/* Creates a directed graph leading towards the level's exit */
		public function connectEscapeNodes(exit:Node):void{
			
			var i:int, j:int, r:int, c:int, lowest:int, escapeNode:Node;
			var current:Node, adjacentNode:Node;
			
			// iterate through the entire graph, creating a one way flow to the exit
			
			exit.h = exit.g = exit.f = 0
			open = new Vector.<Node>();
			open.push(exit);
			
			while(open.length){
				
				// get lowest cost open node
				lowest = int.MAX_VALUE;
				c = -1;
				for(j = 0; j < open.length; j++) {
					if(open[j].g < lowest) {
						lowest = open[j].g;
						c = j;
					}
				}
				current = open.splice(c, 1)[0];
				//current = open.shift();
				current.closedId = searchId;
				current.openId = 0;
				for(j = 0; j < current.connections.length; j++){
					adjacentNode = current.connections[j];
					if(adjacentNode.closedId != searchId){
						if(adjacentNode.openId != searchId){
							open.push(adjacentNode);
							adjacentNode.openId = searchId;
							adjacentNode.closedId = 0;
							adjacentNode.parent = current;
							adjacentNode.setG();
						} else if(adjacentNode.g < current.parent.g){
							current.parent = adjacentNode;
							current.setG();
						}
					}
				}
			}
			
			// only the connections that were significant (parents) during the search are used
			for(r = 0; r < height; r++){
				for(c = 0; c < width; c++){
					escapeNode = escapeNodes[r][c];
					if(escapeNode){
						escapeNode.connections.length = 0;
						if(escapeNode.parent){
							escapeNode.connections.push(escapeNode.parent);
						}
					}
				}
			}
		}
		
		/* Returns a vector of nodes describing a route from the start Node to the finish Node
		 *
		 * This algorithm is an implementation of A* with tagging optimisations and a cut off
		 * defined by the variable steps - limiting the search duration eases cpu load */
		public function getPathTo(start:Node, finish:Node, steps:int = 10, allowDiagonals:Boolean = true):Vector.<Node> {
			
			// the searchId allows the algorithm to mark Nodes as closed or open instead
			// of adding them to arrays and sifting through those arrays all the time
			searchId++;
			
			if(start == finish || !start || !finish) return null;
			
			var i:int, j:int, c:int, lowest:int;
			var current:Node, adjacentNode:Node;
			
			start.setH(finish);
			start.g = 0;
			open = new Vector.<Node>();
			open.push(start);
			
			var found:Boolean = false;
			// storing the next best option to a complete path allows the search to
			// be aborted early (for difficult or impossible paths)
			var closestGoodNode:Node = start;
			
			for(i = 0; i < steps; i++){
				
				if(open.length == 0) break;
				
				// get nearest open node
				lowest = int.MAX_VALUE;
				c = -1;
				for(j = 0; j < open.length; j++) {
					if(open[j].f < lowest) {
						lowest = open[j].f;
						c = j;
					}
				}
				current = open.splice(c, 1)[0];
				
				if(current.h < closestGoodNode.h) closestGoodNode = current;
				current.closedId = searchId;
				current.openId = 0;
				if(current == finish) {
					found = true;
					break;
				}
				for(j = 0; j < current.connections.length; j++){
					adjacentNode = current.connections[j];
					if(adjacentNode.closedId != searchId){
						if(!allowDiagonals && adjacentNode.x != current.x && adjacentNode.y != current.y) adjacentNode.closedId = searchId;
						else if(adjacentNode.openId != searchId) {
							open.push(adjacentNode);
							adjacentNode.openId = searchId;
							adjacentNode.closedId = 0;
							adjacentNode.parent = current;
							adjacentNode.setF(finish);
						} else {
							// double check open nodes for a shorter route
							if(adjacentNode.g > current.g + current.mDist(adjacentNode)){
								adjacentNode.parent = current;
								adjacentNode.setF(finish);
							}
						}
					}
				}
			}
			
			// construct a path
			var path:Vector.<Node> = new Vector.<Node>();
			var pathNode:Node = finish;
			if(!found) pathNode = closestGoodNode;
			
			while(pathNode != start){
				path.push(pathNode);
				pathNode = pathNode.parent;
			}
			
			// it is possible that when no route is found, the start node is the closest
			// node to the target, and so the start node is returned for the Brain to work with
			if(path.length == 0){
				path.push(start);
			}
			
			return path;
		}
		
		/* Returns a vector of nodes describing a route from the start Node away from the target Node
		 *
		 * This algorithm, we'll call Brown*, is simply A* but with the heuristic rearranged to send
		 * the path efficiently away from the target. Because the goal is unknown, it would require
		 * a search of the entire map to satisfy a Brown* search.
		 * 
		 * For this reason, KEEP THE SEARCH STEPS LOW, it will use all of them, unlike A* */
		public function getPathAway(start:Node, target:Node, steps:int = 10, allowDiagonals:Boolean = true):Vector.<Node> {
			
			// the searchId allows the algorithm to mark Nodes as closed or open instead
			// of adding them to arrays and sifting through those arrays all the time
			searchId++;
			
			if(!start || !target) return null;
			
			var i:int, j:int, c:int, lowest:int;
			var current:Node, adjacentNode:Node;
			
			start.setH(target);
			start.h = -start.h;
			start.g = 0;
			open = new Vector.<Node>();
			open.push(start);
			
			// blacklist the target node
			target.closedId = searchId;
			target.openId = 0;
			
			var farthestGoodNode:Node = start;
			
			for(i = 0; i < steps; i++){
				
				if(open.length == 0) break;
				
				// get nearest open node
				lowest = int.MAX_VALUE;
				c = -1;
				for(j = 0; j < open.length; j++) {
					if(open[j].w < lowest) {
						lowest = open[j].w;
						c = j;
					}
				}
				current = open.splice(c, 1)[0];
				
				if(current.h > farthestGoodNode.h) farthestGoodNode = current;
				current.closedId = searchId;
				current.openId = 0;
				for(j = 0; j < current.connections.length; j++){
					adjacentNode = current.connections[j];
					if(adjacentNode.closedId != searchId){
						if(!allowDiagonals && adjacentNode.x != current.x && adjacentNode.y != current.y) adjacentNode.closedId = searchId;
						else if(adjacentNode.openId != searchId) {
							open.push(adjacentNode);
							adjacentNode.openId = searchId;
							adjacentNode.closedId = 0;
							adjacentNode.parent = current;
							adjacentNode.setW(target);
						} else {
							// double check open nodes for a farther route
							if(adjacentNode.g > current.g - current.mDist(adjacentNode)){
								adjacentNode.parent = current;
								adjacentNode.setW(target);
							}
						}
					}
				}
			}
			
			// construct a path
			var path:Vector.<Node> = new Vector.<Node>();
			var pathNode:Node = farthestGoodNode;
			
			while(pathNode != start){
				path.push(pathNode);
				pathNode = pathNode.parent;
			}
			
			// it is possible that when no route is found, the start node is the closest
			// node to the target, and so the start node is returned for the Brain to work with
			if(path.length == 0){
				path.push(start);
			}
			
			return path;
		}
		
		/* Chooses a node at random in the hope that it might lead somewhere */
		public function getRandomNode(start:Node, random:XorRandom):Node{
			if(start.connections.length == 1) return start.connections[0];
			else if(start.connections.length == 0) return null;
			return start.connections[random.rangeInt(start.connections.length)];
		}
		
		/* Chooses the next node in the escape graph (leading towards the exit)
		 * "start" is a node in the escapeNodes */
		public function getEscapeNode(start:Node):Node{
			if(start.connections.length) return start.connections[0];
			return null;
		}
		
		/* Diagnositic illustration of the AI graph for the map */
		public function drawGraph(nodes:Vector.<Vector.<Node>>, gfx:Graphics, scale:Number, topLeft:Pixel, bottomRight:Pixel):void{
			var r:int, c:int, i:int;
			for(r = topLeft.y; r <= bottomRight.y; r++){
				for(c = topLeft.x; c <= bottomRight.x; c++){
					node = nodes[r][c];
					if(node){
						//if(Game.game.editor.mapX == node.x && Game.game.editor.mapY == node.y) trace(node.g);
						gfx.drawCircle((node.x + 0.5) * scale, (node.y + 0.5) * scale, scale * 0.1);
						for(i = 0; i < node.connections.length; i++){
							gfx.moveTo((node.x + 0.5) * scale, (node.y + 0.5) * scale);
							gfx.lineTo((node.connections[i].x + 0.5) * scale, (node.connections[i].y + 0.5) * scale);
							// arrows
							if(node.connections[i].x == node.x){
								if(node.connections[i].y > node.y){
									gfx.moveTo((node.x + 0.3) * scale, (node.y + 0.7) * scale);
									gfx.lineTo((node.x + 0.5) * scale, (node.y + 0.8) * scale);
									gfx.lineTo((node.x + 0.7) * scale, (node.y + 0.7) * scale);
								} else if(node.connections[i].y < node.y){
									gfx.moveTo((node.x + 0.3) * scale, (node.y + 0.3) * scale);
									gfx.lineTo((node.x + 0.5) * scale, (node.y + 0.2) * scale);
									gfx.lineTo((node.x + 0.7) * scale, (node.y + 0.3) * scale);
								}
							} else if(node.connections[i].y == node.y){
								if(node.connections[i].x > node.x){
									gfx.moveTo((node.x + 0.7) * scale, (node.y + 0.3) * scale);
									gfx.lineTo((node.x + 0.8) * scale, (node.y + 0.5) * scale);
									gfx.lineTo((node.x + 0.7) * scale, (node.y + 0.7) * scale);
								} else if(node.connections[i].x < node.x){
									gfx.moveTo((node.x + 0.3) * scale, (node.y + 0.3) * scale);
									gfx.lineTo((node.x + 0.2) * scale, (node.y + 0.5) * scale);
									gfx.lineTo((node.x + 0.3) * scale, (node.y + 0.7) * scale);
								}
							}
						}
					}
				}
			}
		}
		
		/* Diagnostic illustration of a path of nodes */
		public function drawPath(path:Vector.<Node>, gfx:Graphics, scale:Number):void{
			var i:int, a:Node, b:Node;
			for(i = 0; i < path.length; i++){
				a = path[i];
				gfx.drawCircle((a.x + 0.5) * scale, (a.y + 0.5) * scale, scale * 0.1);
				if(i > 0){
					b = path[i - 1];
					gfx.moveTo((a.x + 0.5) * scale, (a.y + 0.5) * scale);
					gfx.lineTo((b.x + 0.5) * scale, (b.y + 0.5) * scale);
					// arrows
					if(a.x == b.x){
						if(b.y > a.y){
							gfx.moveTo((a.x + 0.3) * scale, (a.y + 0.7) * scale);
							gfx.lineTo((a.x + 0.5) * scale, (a.y + 0.8) * scale);
							gfx.lineTo((a.x + 0.7) * scale, (a.y + 0.7) * scale);
						} else if(b.y < a.y){
							gfx.moveTo((a.x + 0.3) * scale, (a.y + 0.3) * scale);
							gfx.lineTo((a.x + 0.5) * scale, (a.y + 0.2) * scale);
							gfx.lineTo((a.x + 0.7) * scale, (a.y + 0.3) * scale);
						}
					} else if(a.y == b.y){
						if(b.x > a.x){
							gfx.moveTo((a.x + 0.7) * scale, (a.y + 0.3) * scale);
							gfx.lineTo((a.x + 0.8) * scale, (a.y + 0.5) * scale);
							gfx.lineTo((a.x + 0.7) * scale, (a.y + 0.7) * scale);
						} else if(b.x < a.x){
							gfx.moveTo((a.x + 0.3) * scale, (a.y + 0.3) * scale);
							gfx.lineTo((a.x + 0.2) * scale, (a.y + 0.5) * scale);
							gfx.lineTo((a.x + 0.3) * scale, (a.y + 0.7) * scale);
						}
					}
				}
			}
		}
		
	}

}