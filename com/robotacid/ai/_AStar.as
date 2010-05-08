package com.robotacid.ai {
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class AStar {
		
		public var search_id:Number = 0;
		public var g:Game;
		public var open:Vector.<SearchNode>;
		public var adjacent_tile:SearchNode;
		public var adjacent_entity:SearchNode
		public var SEARCH_STEPS:Number = 20;
	
		public function AStar(g:Game) {
			this.g = g;
		}
		// Returns an Array of Nodes defining the shortest distance between x0,y0 & x1,y1
		// Note that the A* map is a scale version of your game map - it locates the grid
		// node in a linear array.
		public function getPath(start:SearchNode, finish:SearchNode, steps:int = 20):Array {
			search_id++;
			if (start == finish || !finish.walkable || start == undefined || finish == undefined) {
				return new Array();
			}
			start.setH(finish);
			open = new Array();
			open.push(start);
			var found:Boolean = false;
			var closest_good_node:Object = start;
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
				if(current._h < closest_good_node._h) closest_good_node = current;
				current.closed_id = search_id;
				current.open_id = 0;
				if (current == finish) {
					found = true;
					break;
				}
				// Check all directions
				// UP
				if(current.y > 0){
					adjacent_tile = g.tile_map[current.y-1][current.x];
					adjacent_entity = g.entity_map[current.y-1][current.x];
					if (adjacent_entity == undefined && adjacent_tile.walkable && adjacent_tile.closed_id != search_id) {
						if (adjacent_tile.open_id != search_id) {
							open.push(adjacent_tile);
							adjacent_tile.open_id = search_id;
							adjacent_tile.closed_id = 0;
							adjacent_tile.parent = current;
							adjacent_tile.setF(finish);
						} else {
							if (adjacent_tile._g > current._g + 1){
								adjacent_tile.parent = current;
								adjacent_tile.setF(finish);
							}
						}
					}
				}
				// RIGHT
				if(current.x < g.map_width){
					adjacent_tile = g.tile_map[current.y][current.x+1];
					adjacent_entity = g.entity_map[current.y][current.x+1];
					if (adjacent_entity == undefined && adjacent_tile.walkable && adjacent_tile.closed_id != search_id) {
						if (adjacent_tile.open_id != search_id) {
							open.push(adjacent_tile);
							adjacent_tile.open_id = search_id;
							adjacent_tile.closed_id = 0;
							adjacent_tile.parent = current;
							adjacent_tile.setF(finish);
						} else {
							if (adjacent_tile._g > current._g + 1){
								adjacent_tile.parent = current;
								adjacent_tile.setF(finish);
							}
						}
					}
				}
				// DOWN
				if(current.y < g.map_height){
					adjacent_tile = g.tile_map[current.y+1][current.x];
					adjacent_entity = g.entity_map[current.y+1][current.x];
					if (adjacent_entity == undefined && adjacent_tile.walkable && adjacent_tile.closed_id != search_id) {
						if (adjacent_tile.open_id != search_id) {
							open.push(adjacent_tile);
							adjacent_tile.open_id = search_id;
							adjacent_tile.closed_id = 0;
							adjacent_tile.parent = current;
							adjacent_tile.setF(finish);
						} else {
							if (adjacent_tile._g > current._g + 1){
								adjacent_tile.parent = current;
								adjacent_tile.setF(finish);
							}
						}
					}
				}
				// LEFT
				if(current.x > 0){
					adjacent_tile = g.tile_map[current.y][current.x-1];
					adjacent_entity = g.entity_map[current.y][current.x-1];
					if (adjacent_entity == undefined && adjacent_tile.walkable && adjacent_tile.closed_id != search_id) {
						if (adjacent_tile.open_id != search_id) {
							open.push(adjacent_tile);
							adjacent_tile.open_id = search_id;
							adjacent_tile.closed_id = 0;
							adjacent_tile.parent = current;
							adjacent_tile.setF(finish);
						} else {
							if (adjacent_tile._g > current._g + 1){
								adjacent_tile.parent = current;
								adjacent_tile.setF(finish);
							}
						}
					}
				}
			}
			var path = new Array();
			var path_node:Object = finish;
			if(!found) path_node = closest_good_node;
			for(var k:Number = 0; k < 1000;k++){
			if(path_node == start) break;
				path.push(path_node);
				path_node = path_node.parent;
			}
			return path;
		}
	}
	
}