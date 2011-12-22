package com.robotacid.gfx{
	import com.robotacid.geom.Pixel;
	import com.robotacid.phys.Collider;
	import com.robotacid.util.array.randomiseArray;
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
		
		public static var game:Game;
		
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
		
		private var mapX:int;
		private var mapY:int;
		
		private var mapWidth:int;
		private var mapHeight:int;
		
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
		public function strike(gfx:Graphics, map:Vector.<Vector.<int>>, startX:Number, startY:Number, finishX:Number, finishY:Number):Boolean{
			// by randomising the search order of nodes we avoid paths being weighted
			randomiseArray(pos, game.random);
			
			sx = startX * INV_SCALE;
			sy = startY * INV_SCALE;
			fx = finishX * INV_SCALE;
			fy = finishY * INV_SCALE;
			
			this.map = map;
			
			mapX = sx * LIGHTNING_TO_MAP_CONVERSION;
			mapY = sy * LIGHTNING_TO_MAP_CONVERSION;
			
			mapHeight = map.length;
			mapWidth = map[0].length;
			
			// draw the initial jump to the grid
			gfx.lineStyle(1, 0xFFFFFF);
			gfx.moveTo(startX, startY);
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
				dx += game.random.range(-dy) * 1.5 + game.random.range(dy) * 1.5;
				dy += game.random.range(-dx) * 1.5 + game.random.range(dx) * 1.5;
				sx += dx;
				sy += dy;
				mapX = sx * LIGHTNING_TO_MAP_CONVERSION;
				mapY = sy * LIGHTNING_TO_MAP_CONVERSION;
				if(mapX < 0 || mapY < 0 || mapX > mapWidth-1 || mapY > mapHeight-1 || (map[mapY][mapX] & Collider.WALL)) break;
				gfx.lineTo((SCALE * 0.5) + sx * SCALE, (SCALE * 0.5) + sy * SCALE);
				lightningBranch(gfx, sx, sy, dx, dy, mapX, mapY, game.random.value());
				
			}
			
			// connected? finish the path to the exact location
			if(sx == fx && sy == fy){
				gfx.lineStyle(1, 0xFFFFFF);
				gfx.moveTo((SCALE * 0.5) + fx * SCALE, (SCALE * 0.5) + fy * SCALE);
				gfx.lineTo(finishX, finishY);
				return true;
			}
			return false;
		}
		
		/* A recursive function that sends out random tendrils that either get blocked by walls or
		 * lose all energy to continue - this creates the branched forks that extend from the lightning
		 * path proper - these have no impact on the Boolean returned */
		private function lightningBranch(gfx:Graphics, x:int, y:int, dx:int, dy:int, mapX:int, mapY:int, decay:Number):void{
			gfx.lineStyle(1, 0xFFFFFF, decay);
			gfx.moveTo((SCALE * 0.5) + x * SCALE, (SCALE * 0.5) + y * SCALE);
			x += dx;
			y += dy;
			mapX = x * LIGHTNING_TO_MAP_CONVERSION;
			mapY = y * LIGHTNING_TO_MAP_CONVERSION;
			if(mapX < 0 || mapY < 0 || mapX > mapWidth-1 || mapY > mapHeight-1 || (map[mapY][mapX] & Collider.WALL)) return;
			gfx.lineTo((SCALE * 0.5) + x * SCALE, (SCALE * 0.5) + y * SCALE);
			if(game.random.value() < decay){
				dx += game.random.range(-dy) * 1.5 + game.random.range(dy) * 1.5;
				dy += game.random.range(-dx) * 1.5 + game.random.range(dx) * 1.5;
				lightningBranch(gfx, x, y, dx, dy, mapX, mapY, decay * game.random.value());
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