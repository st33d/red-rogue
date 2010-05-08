package com.robotacid.gfx{
	import com.robotacid.geom.Pixel;
	import com.robotacid.phys.Block;
	import com.robotacid.util.misc.randomiseArray;
	import flash.display.Graphics;
	/**
	 * Creates a lightning graphic that will travel between two points and return whether
	 * the path was interrupted by a wall or reached the target
	 * 
	 * Also operates on two scale levels - the smaller the grid the lightning runs on, the better it looks
	 * so it's best to run it on a smaller scale than the map wall array scale and convert between the
	 * two to check blockages
	 * 
	 * I've optimised the crap out of this object, so apologies if it don't port well
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Lightning{
		
		private var i:int;
		private var best:Number;
		private var node:Pixel;
		private var nodes:Vector.<Pixel>;
		private var h:Vector.<int>;
		
		private var sx:int;
		private var sy:int;
		private var fx:int;
		private var fy:int;
		private var dx:int;
		private var dy:int;
		
		private var map_x:int;
		private var map_y:int;
		
		private var map_width:int;
		private var map_height:int;
		
		private var map:Vector.<Vector.<int>>;
		private var pos:Array/*Pixel*/ = [
			new Pixel( -1, -1),
			new Pixel( 0, -1),
			new Pixel( 1, -1),
			new Pixel( -1, 0),
			new Pixel( 1, 0),
			new Pixel( -1, 1),
			new Pixel( 0, 1),
			new Pixel( 1, 1)
		];
		
		public static const SCALE:Number = 4;
		public static const INV_SCALE:Number = 1.0 / 4;
		
		public static const LIGHTNING_TO_MAP_CONVERSION:Number = SCALE * Game.INV_SCALE;
		
		public function Lightning() {
			nodes = new Vector.<Pixel>();
			h = new Vector.<int>();
			for(var i:int = 0; i < pos.length; i++){
				nodes.push(new Pixel());
				h.push(new Pixel());
			}
		}
		
		/* Generates the lightning graphic and returns whether the lightning walk was successful
		 * in reaching its target or was blocked by a wall */
		public function strike(gfx:Graphics, map:Vector.<Vector.<int>>, start_x:Number, start_y:Number, finish_x:Number, finish_y:Number):Boolean{
			// by randomising the search order of nodes we avoid paths being weighted
			randomiseArray(pos);
			
			sx = start_x * INV_SCALE;
			sy = start_y * INV_SCALE;
			fx = finish_x * INV_SCALE;
			fy = finish_y * INV_SCALE;
			
			this.map = map;
			
			map_x = sx * LIGHTNING_TO_MAP_CONVERSION;
			map_y = sy * LIGHTNING_TO_MAP_CONVERSION;
			
			map_height = map.length;
			map_width = map[0].length;
			
			// draw the initial jump to the grid
			gfx.lineStyle(1, 0xFFFFFF);
			gfx.moveTo(start_x, start_y);
			gfx.lineTo((SCALE * 0.5) + sx * SCALE, (SCALE * 0.5) + sy * SCALE);
			
			// keep looking till we find a wall or the target
			while(sx != fx || sy != fy){
				
				best = Number.MAX_VALUE;
				for(i = 0; i < nodes.length; i++){
					nodes[i].x = sx + pos[i].x;
					nodes[i].y = sy + pos[i].y;
					h[i] = dist(nodes[i], fx, fy);
					if(h[i] < best){
						best = h[i];
						node = nodes[i];
					}
				}
				
				gfx.lineStyle(1, 0xFFFFFF);
				gfx.moveTo((SCALE * 0.5) + sx * SCALE, (SCALE * 0.5) + sy * SCALE);
				dx = node.x - sx;
				dy = node.y - sy;
				dx += (Math.random() * -dy * 1.5) + (Math.random() * dy * 1.5);
				dy += (Math.random() * -dx * 1.5) + (Math.random() * dx * 1.5);
				sx += dx;
				sy += dy;
				map_x = sx * LIGHTNING_TO_MAP_CONVERSION;
				map_y = sy * LIGHTNING_TO_MAP_CONVERSION;
				if(map_x < 0 || map_y < 0 || map_x > map_width-1 || map_y > map_height-1 || (map[map_y][map_x] & Block.WALL)) break;
				gfx.lineTo((SCALE * 0.5) + sx * SCALE, (SCALE * 0.5) + sy * SCALE);
				lightningBranch(gfx, sx, sy, dx, dy, map_x, map_y, Math.random());
				
			}
			
			// connected? finish the path to the exact location
			if(sx == fx && sy == fy){
				gfx.lineStyle(1, 0xFFFFFF);
				gfx.moveTo((SCALE * 0.5) + fx * SCALE, (SCALE * 0.5) + fy * SCALE);
				gfx.lineTo(finish_x, finish_y);
				return true;
			}
			return false;
		}
		
		/* A recursive function that sends out random tendrils that either get blocked by walls or
		 * lose all energy to continue - this creates the branched forks that extend from the lightning
		 * path proper - these have no impact on the Boolean returned */
		private function lightningBranch(gfx:Graphics, x:int, y:int, dx:int, dy:int, map_x:int, map_y:int, decay:Number):void{
			gfx.lineStyle(1, 0xFFFFFF, decay);
			gfx.moveTo((SCALE * 0.5) + x * SCALE, (SCALE * 0.5) + y * SCALE);
			x += dx;
			y += dy;
			map_x = x * LIGHTNING_TO_MAP_CONVERSION;
			map_y = y * LIGHTNING_TO_MAP_CONVERSION;
			if(map_x < 0 || map_y < 0 || map_x > map_width-1 || map_y > map_height-1 || (map[map_y][map_x] & Block.WALL)) return;
			gfx.lineTo((SCALE * 0.5) + x * SCALE, (SCALE * 0.5) + y * SCALE);
			if(Math.random() < decay){
				dx += (Math.random() * -dy * 1.5) + (Math.random() * dy * 1.5);
				dy += (Math.random() * -dx * 1.5) + (Math.random() * dx * 1.5);
				lightningBranch(gfx, x, y, dx, dy, map_x, map_y, decay * Math.random());
			}
			
		}
		
		/* A simple squared distance function for finding a path heuristic */
		public function dist(p:Pixel, x:int, y:int):int{
			var dx:int = x - p.x;
			var dy:int = y - p.y;
			return dx * dx + dy * dy;
		}
		
	}

}