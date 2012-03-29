package com.robotacid.ai {
	import com.robotacid.level.MapBitmap;
	
	/**
	 * A special map graph for wall-walking, used by wraiths
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class WallWalkGraph extends MapGraph {
		
		public function WallWalkGraph(bitmap:MapBitmap) {
			super(bitmap);
		}
		
		override public function connectNodes(pixels:Vector.<uint>):void {
			
			super.connectNodes(pixels);
			
			// wraiths can walk thru walls, meaning that there must be extra nodes in every wall
			var i:int, r:int, c:int, n:int;
			var node:Node;
			for(i = width; i < pixels.length - width; i++){
				if(
					pixels[i] == MapBitmap.WALL && (
						pixels[i + width] == MapBitmap.PIT ||
						pixels[i + width] == MapBitmap.LEDGE ||
						pixels[i + width] == MapBitmap.LADDER_LEDGE ||
						pixels[i + width] == MapBitmap.WALL
					)
				){
					r = i / width;
					c = i % width;
					node = new Node(c, r);
					nodes[r][c] = node;
				}
			}
			// connect the new nodes
			for(r = 1; r < height - 1; r++){
				for(c = 1; c < width - 1; c++){
					if(nodes[r][c]){
						n = c + r * width;
						// wall walking only works horizontally, so only a horizontal check is needed
						if(nodes[r][c + 1] && (pixels[n] == MapBitmap.WALL || pixels[n + 1] == MapBitmap.WALL)){
							nodes[r][c].connections.push(nodes[r][c + 1]);
							nodes[r][c + 1].connections.push(nodes[r][c]);
						}
					}
				}
			}
		}
		
	}

}