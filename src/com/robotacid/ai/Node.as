package com.robotacid.ai {
	import com.robotacid.geom.Pixel;
	/**
	 * A search node of the MapGraph.
	 *
	 * Contains methods and properties used for A* pathfinding
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Node extends Pixel{
		
		public var f:int;
		public var h:int;
		public var g:int;
		public var parent:Node;
		
		public var w:int;
		
		public var closedId:int;
		public var openId:int;
		
		public var connections:Vector.<Node>;
		
		public function Node(x:int, y:int) {
			super(x, y);
			closedId = openId = -1;
			connections = new Vector.<Node>();
		}
		
		// A* Pathfinding calculations
		
		/* Calculate f
		 * All calculation is inlined to increase speed */
		public function setF(finish:Node):void{
			
			// Manhattan distance measuring - Math.abs inlined for speed
			
			// set g - goal value, how far we have travelled
			g = parent.g + (parent.x < x ? x - parent.x : parent.x - x) + (parent.y < y ? y - parent.y : parent.y - y);
			
			// set h - heuristic, how far the target is
			h = (finish.x < x ? x - finish.x : finish.x - x) + (finish.y < y ? y - finish.y : finish.y - y);
			
			// therefore f equals:
			f = g + h;
		}
		
		/* Called at the beginning of the search to initialise the the start square as farthest */
		public function setH(finish:Node):void{
			// Manhattan distance measuring - Math.abs inlined for speed
			h = (finish.x < x ? x - finish.x : finish.x - x) + (finish.y < y ? y - finish.y : finish.y - y);
		}
		
		/* Calculate w - the best route away from a target
		 * All calculation is inlined to increase speed */
		public function setW(start:Node):void{
			
			// Manhattan distance measuring - Math.abs inlined for speed
			
			// set g - goal value, how far we have travelled
			g = parent.g + (parent.x < x ? x - parent.x : parent.x - x) + (parent.y < y ? y - parent.y : parent.y - y);
			
			// set h - heuristic, how far the target is
			h = (start.x < x ? x - start.x : start.x - x) + (start.y < y ? y - start.y : start.y - y);
			
			// therefore w equals:
			w = g - h;
		}
		
		/* Calculate g - the distance travelled to this node */
		public function setG():void{
			
			// Manhattan distance measuring - Math.abs inlined for speed
			
			// set g - goal value, how far we have travelled
			g = parent.g + (parent.x < x ? x - parent.x : parent.x - x) + (parent.y < y ? y - parent.y : parent.y - y);
		}
	}

}