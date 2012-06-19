package com.robotacid.ai {
	import com.robotacid.geom.Pixel;
	import com.robotacid.level.MapBitmap;
	
	/**
	 * A special map graph for wall-walking, used by wraiths
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class WallWalkGraph extends MapGraph {
		
		public function WallWalkGraph(bitmap:MapBitmap, exit:Pixel) {
			super(bitmap, exit);
		}
		
		override public function connectNodes(pixels:Vector.<uint>):void {
			
			super.connectNodes(pixels);
			
			// there must be extra nodes in every wall, and where possible cliffs walking out of walls could be
			var i:int, r:int, c:int, n:int;
			var node:Node, escapeNode:Node, connection:Node, escapeConnection:Node;
			const NEW_NODE:int = -2;
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
					if(c == 0 || c == width - 1) continue;
					
					node = new Node(c, r);
					escapeNode = new Node(c, r);
					nodes[r][c] = node;
					escapeNodes[r][c] = escapeNode;
					// the new nodes are tagged using their openId to avoid repeat connecting nodes
					node.openId = NEW_NODE;
					// generate cliff nodes to walk out of this wall node
					if(c < width - 2 && !nodes[r][c + 1]){
						node = new Node(c + 1, r);
						escapeNode = new Node(c + 1, r);
						nodes[r][c + 1] = node;
						escapeNodes[r][c + 1] = escapeNode;
						node.openId = NEW_NODE;
					}
					if(c > 1 && !nodes[r][c - 1]){
						node = new Node(c - 1, r);
						escapeNode = new Node(c - 1, r);
						nodes[r][c - 1] = node;
						escapeNodes[r][c - 1] = escapeNode;
						node.openId = NEW_NODE;
					}
				}
			}
			// connect the new nodes
			for(r = 1; r < height - 1; r++){
				for(c = 1; c < width - 1; c++){
					node = nodes[r][c];
					if(node){
						escapeNode = escapeNodes[r][c];
						n = c + r * width;
						// connect new nodes rightwards
						connection = nodes[r][c + 1];
						escapeConnection = escapeNodes[r][c + 1];
						if(connection && (node.openId == NEW_NODE || connection.openId == NEW_NODE)){
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
						// connect new nodes downwards
						if(
							node.openId == NEW_NODE && 
							pixels[n + width] != MapBitmap.WALL
						){
							for(i = r + 1; i < height; i++){
								if(nodes[i][c]){
									node.connections.push(nodes[i][c]);
									// reverse the connection for the escape node - we need to search backwards
									escapeNodes[i][c].connections.push(escapeNode);
									break;
								}
							}
						}
					}
				}
			}
		}
		
	}

}