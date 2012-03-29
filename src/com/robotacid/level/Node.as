package com.robotacid.level {
	/**
	 * This is a graph vertex
	 * 
	 * Its edges are the connections vector which we keep the same size as
	 * the connectionsActive vector for the graph pruning stage of map building
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Node{
		
		public var x:int, y:int;
		public var visited:Boolean;
		public var connections:Vector.<Node>;
		public var connectionsActive:Vector.<Boolean>;
		public var drop:Boolean;
		
		public function Node(x:int, y:int) {
			this.x = x;
			this.y = y;
			visited = false;
			connections = new Vector.<Node>();
			connectionsActive = new Vector.<Boolean>();
			drop = false;
		}
		
	}

}