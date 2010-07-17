package com.robotacid.ai {
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class AStar {
		
		public var searchId:Number = 0;
		public var g:Game;
		public var open:Vector.<SearchNode>;
		public var adjacentTile:SearchNode;
		public var adjacentEntity:SearchNode
		public var SEARCH_STEPS:Number = 20;
	
		public function AStar(g:Game) {
			this.g = g;
		}
		// Returns an Array of Nodes defining the shortest distance between x0,y0 & x1,y1
		// Note that the A* map is a scale version of your game map - it locates the grid
		// node in a linear array.
		public function getPath(start:SearchNode, finish:SearchNode, steps:int = 20):Array {
			searchId++;
			if (start == finish || !finish.walkable || start == undefined || finish == undefined) {
				return new Array();
			}
			start.setH(finish);
			open = new Array();
			open.push(start);
			var found:Boolean = false;
			var closestGoodNode:Object = start;
			for(var k:Number = 0; k < steps; k++){
				if(open.length == 0) break;
				var lowest = Number.MAX_VALUE;
				var c = -1;
				for (var i = 0; i < open.length; i++) {
					if (open[i]._f < lowest) {
						lowest = open[i]._f;
						c = i;
					}
				}
				var current:Object = open.splice(c, 1)[0];
				if(current._h < closestGoodNode._h) closestGoodNode = current;
				current.closedId = searchId;
				current.openId = 0;
				if (current == finish) {
					found = true;
					break;
				}
				// Check all directions
				// UP
				if(current.y > 0){
					adjacentTile = g.tileMap[current.y-1][current.x];
					adjacentEntity = g.entityMap[current.y-1][current.x];
					if (adjacentEntity == undefined && adjacentTile.walkable && adjacentTile.closedId != searchId) {
						if (adjacentTile.openId != searchId) {
							open.push(adjacentTile);
							adjacentTile.openId = searchId;
							adjacentTile.closedId = 0;
							adjacentTile.parent = current;
							adjacentTile.setF(finish);
						} else {
							if (adjacentTile._g > current._g + 1){
								adjacentTile.parent = current;
								adjacentTile.setF(finish);
							}
						}
					}
				}
				// RIGHT
				if(current.x < g.map_width){
					adjacentTile = g.tileMap[current.y][current.x+1];
					adjacentEntity = g.entityMap[current.y][current.x+1];
					if (adjacentEntity == undefined && adjacentTile.walkable && adjacentTile.closedId != searchId) {
						if (adjacentTile.openId != searchId) {
							open.push(adjacentTile);
							adjacentTile.openId = searchId;
							adjacentTile.closedId = 0;
							adjacentTile.parent = current;
							adjacentTile.setF(finish);
						} else {
							if (adjacentTile._g > current._g + 1){
								adjacentTile.parent = current;
								adjacentTile.setF(finish);
							}
						}
					}
				}
				// DOWN
				if(current.y < g.map_height){
					adjacentTile = g.tileMap[current.y+1][current.x];
					adjacentEntity = g.entityMap[current.y+1][current.x];
					if (adjacentEntity == undefined && adjacentTile.walkable && adjacentTile.closedId != searchId) {
						if (adjacentTile.openId != searchId) {
							open.push(adjacentTile);
							adjacentTile.openId = searchId;
							adjacentTile.closedId = 0;
							adjacentTile.parent = current;
							adjacentTile.setF(finish);
						} else {
							if (adjacentTile._g > current._g + 1){
								adjacentTile.parent = current;
								adjacentTile.setF(finish);
							}
						}
					}
				}
				// LEFT
				if(current.x > 0){
					adjacentTile = g.tileMap[current.y][current.x-1];
					adjacentEntity = g.entityMap[current.y][current.x-1];
					if (adjacentEntity == undefined && adjacentTile.walkable && adjacentTile.closedId != searchId) {
						if (adjacentTile.openId != searchId) {
							open.push(adjacentTile);
							adjacentTile.openId = searchId;
							adjacentTile.closedId = 0;
							adjacentTile.parent = current;
							adjacentTile.setF(finish);
						} else {
							if (adjacentTile._g > current._g + 1){
								adjacentTile.parent = current;
								adjacentTile.setF(finish);
							}
						}
					}
				}
			}
			var path = new Array();
			var pathNode:Object = finish;
			if(!found) pathNode = closestGoodNode;
			for(var k:Number = 0; k < 1000;k++){
			if(pathNode == start) break;
				path.push(pathNode);
				pathNode = pathNode.parent;
			}
			return path;
		}
	}
	
}