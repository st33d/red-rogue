package com.robotacid.ai {
	import com.robotacid.geom.Pixel;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class SearchNode extends Pixel{
		
		public var f:int;
		public var h:int;
		public var g:int;
		public var walkable:Boolean;
		
		public function SearchNode(x:int, y:int) {
			super(x, y);
		}
		
		// A* Pathfinding calculations
		
		// Calculate F
		// All calculation is inlined to increase speed
		function setF(fin:Object):Void {
			// set _g - goal value, how far we have travelled
			var xd = x - parent.x;
			var yd = y - parent.y;
			// Manhattan distance measuring - Math.abs inlined for speed
			_g = parent._g + (xd < 0 ? -xd : xd) + (yd < 0 ? -yd : yd);
			// set _h - heuristic, how far the target is
			xd = x - fin.x;
			yd = y - fin.y;
			_h = (xd < 0 ? -xd : xd) + (yd < 0 ? -yd : yd);
			// therefore _f equals:
			_f = _g + _h;
		}
		// Called at the beginning of the search to initialise the the start square as farthest
		function setH(fin:Object):Void{
			// Manhattan distance measuring - Math.abs inlined for speed
			var xd = x - fin.x;
			var yd = y - fin.y;
			_h = (xd < 0 ? -xd : xd) + (yd < 0 ? -yd : yd);
		}
	}
	
}