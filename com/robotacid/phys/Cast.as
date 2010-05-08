package com.robotacid.phys {
	import com.robotacid.geom.Dot;
	import com.robotacid.geom.Rect;
	import com.robotacid.phys.Block;
	import com.robotacid.geom.Line;
	import com.robotacid.engine.Player;
	
	/**
	* Scans for blocks or Colliders
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class Cast {
		
		public var block:Block;
		public var collider:Collider;
		public var distance:Number;
		public var side:int;
		
		public static var g:Game;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		public static const EMPTY:int = -1;
		
		public function Cast() {
		}
		
		/* Returns a Cast object with the first block or Collider (the block then being a property
		 * of the Collider) encountered horizontally in a direction given by dir (1 or -1). ignore
		 * is given as a composite of flags referring to properties that should be ignored. map is
		 * the identity map of values for static blocks (g.block_map)
		 */
		public static function horiz(x:Number, y:Number, dir:Number, length:int, map:Vector.<Vector.<int>>, ignore:int, g:Game):Cast{
			var width:int = map[0].length;
			var r:int = y * Game.INV_SCALE;
			// catch off screen behaviour and return null value
			if(r >= g.renderer.height || r < 0) return null;
			var c:int = x * Game.INV_SCALE;
			if(c >= g.renderer.width || c < 0) return null;
			var id:int;
			var i:int;
			var cast:Cast = new Cast();
			var block:Block;
			for (c = x * Game.INV_SCALE; c > -1 && c < width && length > 0; c += dir, length--) {
				id = map[r][c];
				// found a static block
				if (id > EMPTY && !(ignore & id)){
					if ((dir > 0 && (id & LEFT)) || (dir < 0 && (id & RIGHT))){
						cast.block = new Block(c * Game.SCALE, r * Game.SCALE, Game.SCALE, Game.SCALE, map[r][c]);
						break;
					}
				}
			}
			// gone off screen, fake a block
			if (!cast.block){
				if (dir > 0){
					cast.block = new Block(width * Game.SCALE, r * Game.SCALE, Game.SCALE, Block.SOLID);
				} else if (dir < 0){
					cast.block = new Block(-1 * Game.SCALE, r * Game.SCALE, Game.SCALE, Game.SCALE, Block.SOLID);
				}
			}
			// check colliders
			if(dir > 0){
				for (i = 0; i < g.colliders.length; i++){
					block = g.colliders[i].block;
					if (ignore & block.type) continue;
					if (block.x > x && block.x < cast.block.x && y >= block.y && y < block.y + block.height){
						cast.block = g.colliders[i].block;
						cast.collider = g.colliders[i];
					}
				}
			} else if(dir < 0){
				for (i = 0; i < g.colliders.length; i++){
					block = g.colliders[i].block;
					if (ignore & block.type) continue;
					if (block.x + block.width - 1 < x && block.x + block.width - 1 > cast.block.x + cast.block.width - 1 && y >= block.y && y < block.y + block.height){
						cast.block = g.colliders[i].block;
						cast.collider = g.colliders[i];
					}
				}
			}
			return cast;
		}
		
		/* Returns a Cast object with the first block or Collider (the block then being a property
		 * of the Collider) encountered vertically in a direction given by dir (1 or -1). ignore
		 * is given as a composite of flags referring to properties that should be ignored. map is
		 * the identity map of values for static blocks (g.block_map)
		 */
		public static function vert(x:Number, y:Number, dir:Number, length:int, map:Vector.<Vector.<int>>, ignore:int, g:Game):Cast{
			var height:int = map.length;
			var r:int = y * Game.INV_SCALE;
			// catch off screen behaviour and return null value
			if(r >= g.renderer.height || r < 0) return null;
			var c:int = x * Game.INV_SCALE;
			if(c >= g.renderer.width || c < 0) return null;
			var type:int;
			var i:int;
			var cast:Cast = new Cast();
			var block:Block;
			for (r = y * Game.INV_SCALE; r > -1 && r < height && length > 0; r += dir, length--) {
				type = map[r][c];
				// found a static block
				if (type > EMPTY && !(ignore & type)){
					if ((dir > 0 && (type & UP) && y < r * Game.SCALE) || (dir < 0 && (type & DOWN))){
						cast.block = new Block(c * Game.SCALE, r * Game.SCALE, Game.SCALE, Game.SCALE, map[r][c]);
						break;
					}
				}
			}
			// gone off screen, fake a block
			if (!cast.block){
				if (dir > 0){
					cast.block = new Block(c * Game.SCALE, height * Game.SCALE, Game.SCALE, Game.SCALE, UP | RIGHT | DOWN | LEFT);
				} else if (dir < 0){
					cast.block = new Block(c * Game.SCALE, -1 * Game.SCALE, Game.SCALE, Game.SCALE, UP | RIGHT | DOWN | LEFT);
				}
			}
			// check colliders
			if(dir > 0){
				for (i = 0; i < g.colliders.length; i++){
					block = g.colliders[i].block;
					if (ignore & block.type) continue;
					if (block.y > y && block.y < cast.block.y && x >= block.x && x < block.x + block.width){
						cast.block = g.colliders[i].block;
						cast.collider = g.colliders[i];
					}
				}
			} else if(dir < 0){
				for (i = 0; i < g.colliders.length; i++){
					block = g.colliders[i].block;
					if (ignore & block.type) continue;
					if (block.y + block.height - 1 < y && block.y + block.height - 1 > cast.block.y + cast.block.height - 1 && x >= block.x && x < block.x + block.width){
						cast.block = g.colliders[i].block;
						cast.collider = g.colliders[i];
					}
				}
			}
			return cast;
		}
		
		/*
		 * Returns the distance to the nearest block or Collider
		 *
		 * code is taken from Rustyard
		 * renamed a few variables so they fall in line with my own naming conventions,
		 * changed a few numbers to ints, and set it up to work with Colliders and the type map system
		 */
		
		public static function ray(x:Number, y:Number, dx:Number, dy:Number, map:Vector.<Vector.<int>>, ignore:int, g:Game):Cast {
			// n.b. if the ray direction is not normalized, WEIRD THINGS WILL HAPPEN!
			
			
			var map_x:int = x * Game.INV_SCALE;
			var map_y:int = y * Game.INV_SCALE;
			var width:int = g.renderer.width;
			var height:int = g.renderer.height;
			
			var result:Cast;
			
			if (map[map_y][map_x] > Block.EMPTY && !(ignore & map[map_y][map_x])){
				result = new Cast;
				result.block = new Block(map_x * Game.SCALE, map_y * Game.SCALE, Game.SCALE, Game.SCALE, map[map_y][map_x]);
				result.distance = 0;
				return result;
			}
			var px:Number = x - (map_x * Game.SCALE);
			var py:Number = y - (map_y * Game.SCALE);
			var targetPX:Number = (dx < 0) ? 0 : Game.SCALE;
			var targetPY:Number = (dy < 0) ? 0 : Game.SCALE;
			var dirX:int = dx < 0 ? -1 : 1;
			var dirY:int = dy < 0 ? -1 : 1;
			var invdx:Number = 1 / dx;
			var invdy:Number = 1 / dy;
			var totalDistance:Number = 0;
			var type:int;
			
			while(map_x > -1 && map_x < width && map_y > -1 && map_y < height) {
				
				
				var toNextX:Number = Math.abs((px - targetPX) * invdx);
				var toNextY:Number = Math.abs((py - targetPY) * invdy);
				
				if(toNextX < toNextY) {
					// move horizontally
					map_x += dirX;
					totalDistance += toNextX;
					// acquire block properties from grid or fabricate an out of range block
					if(map_x < 0 || map_y < 0 || map_y > height - 1 || map_x > width - 1) type = Block.SOLID | Block.STATIC;
					else type = map[map_y][map_x];
					if(type > Block.EMPTY && !(ignore & type)){
						result = new Cast;
						result.block = new Block(map_x * Game.SCALE, map_y * Game.SCALE, Game.SCALE, Game.SCALE, type);
						result.distance = totalDistance;
						result.side = dirX > 0 ? LEFT : RIGHT;
						break;
					}
					px += dx * toNextX;
					py += dy * toNextX;
					px -= dirX * Game.SCALE;
				} else {
					// move vertically
					map_y += dirY;
					totalDistance += toNextY;
					// acquire block properties from grid or fabricate an out of range block
					if(map_x < 0 || map_y < 0 || map_y > height - 1 || map_x > width - 1) type = Block.SOLID | Block.STATIC;
					else type = map[map_y][map_x];
					if(type > Block.EMPTY && !(ignore & type)){
						result = new Cast;
						result.block = new Block(map_x * Game.SCALE, map_y * Game.SCALE, Game.SCALE, Game.SCALE, type);
						result.distance = totalDistance;
						result.side = dirY > 0 ? UP : DOWN;
						break;
					}
					px += dx * toNextY;
					py += dy * toNextY;
					py -= dirY * Game.SCALE;
				}
			}
			
			var lx:Number = dy;
			var ly:Number = -dx;
			var rayIntoNormal:Number = (lx * x) + (ly * y);
			
			for (var n:int = 0; n < g.colliders.length; n ++) {
				
				if (g.colliders[n].block.type & ignore) continue;
				
				var rect:Rect = g.colliders[n].rect;
				
				// bounding box check. the ray must fall in or before the object
				if(dx > 0 && x > rect.x + rect.width - 1) continue;
				if(dx < 0 && x < rect.x) continue;
				if(dy > 0 && y > rect.y + rect.height - 1) continue;
				if(dy < 0 && y < rect.y) continue;
				
				// check whether the ray passes through the object
				var positiveTotal:int = 0;
				var pcx:Number, pcy:Number;
				for(var p:int = 0; p < 4; p ++) {
					pcx = (p%2 == 0) ? rect.x : rect.x + rect.width - 1;
					pcy = (p >= 2) ? rect.y : rect.y + rect.height - 1;
					if((lx * pcx) + (ly * pcy) >= rayIntoNormal) positiveTotal ++;
				}
				if((positiveTotal == 0) || (positiveTotal == 4)) continue;
				
				// hit. find *where* the ray hit the object
				var centerX:Number = rect.x + rect.width * 0.5;
				var centerY:Number = rect.y + rect.height * 0.5;
				var targetHitX:Number = (x > centerX) ? rect.x + rect.width - 1 : rect.x;
				var targetHitY:Number = (y > centerY) ? rect.y + rect.height - 1 : rect.y;
				
				var toHitTargetX:Number = Math.abs((x - targetHitX) * invdx);
				var toHitTargetY:Number = Math.abs((y - targetHitY) * invdy);
				
				var heightOfTargetX:Number = y + (dy * toHitTargetX);
				var validHitTargetX:Boolean =
					(heightOfTargetX > rect.y) && (heightOfTargetX < rect.y + rect.height);
				
				var columnOfTargetY:Number = x + (dx * toHitTargetY);
				var validHitTargetY:Boolean =
					(columnOfTargetY > rect.x) && (columnOfTargetY < rect.x + rect.width);
				var side:int;
				var dist:Number;
				if(!validHitTargetX) {
					dist = toHitTargetY;
					side = dy > 0 ? UP : DOWN;
				} else if(!validHitTargetY) {
					dist = toHitTargetX;
					side = dx > 0 ? LEFT : RIGHT;
				} else {
					if(toHitTargetX < toHitTargetY){
						dist = toHitTargetX;
						side = dx > 0 ? LEFT : RIGHT;
					} else {
						dist = toHitTargetY;
						side = dy > 0 ? UP : DOWN;
					}
				}
				
				if((!result) || (dist < result.distance)) {
					if(!result) result = new Cast;
					result.block = g.colliders[n].block;
					result.collider = g.colliders[n];
					result.distance = dist;
					result.side = side;
				}
			}
			
			return result;
		}
	
	}
	
}