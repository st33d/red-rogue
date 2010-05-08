package com.robotacid.dungeon {
	/**
	 * This is a graph vertex
	 * 
	 * Its edges are the connections vector which we keep the same size as
	 * the connections_active vector for the graph pruning stage of map building
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Node{
		
		public var x:int, y:int;
		public var visited:Boolean;
		public var connections:Vector.<Node>;
		public var connections_active:Vector.<Boolean>;
		public var drop:Boolean;
		
		public function Node(x:int, y:int) {
			this.x = x;
			this.y = y;
			visited = false;
			connections = new Vector.<Node>();
			connections_active = new Vector.<Boolean>();
			drop = false;
		}
		
	}

}