package com.robotacid.phys {
	import flash.geom.Point;
	/**
	 * Used to perform a raycast within the Collision world
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Cast{
		
		public var collider:Collider;
		public var distance:Number;
		public var surface:int;
		
		// sides of a Collider
		public static const UP:int = Collider.UP;
		public static const RIGHT:int = Collider.RIGHT;
		public static const DOWN:int = Collider.DOWN;
		public static const LEFT:int = Collider.LEFT;
		
		public function Cast(){
			
		}
		
		/* Returns a Cast object with the first map surface or Collider encountered horizontally */
		public static function horiz(x:Number, y:Number, dir:Number, length:int, ignore:int, world:CollisionWorld):Cast{
			var r:int = y * Game.INV_SCALE;
			// catch off screen behaviour and return null value
			if(r >= world.height || r < 0) return null;
			var c:int = x * Game.INV_SCALE;
			if(c >= world.width || c < 0) return null;
			var id:int, i:int, lengthSteps:int = length;
			var cast:Cast = new Cast();
			for(c = x * Game.INV_SCALE; c > -1 && c < world.width && lengthSteps; c += dir, lengthSteps--){
				id = world.map[r][c];
				// found a static block
				if(id && !(ignore & id)){
					if((dir > 0 && (id & LEFT)) || (dir < 0 && (id & RIGHT))){
						cast.collider = new Collider(c * Game.SCALE, r * Game.SCALE, Game.SCALE, Game.SCALE, Game.SCALE, world.map[r][c], 0, Collider.MAP_COLLIDER);
						break;
					}
				}
			}
			// gone off screen, fake a collider
			if(!cast.collider && lengthSteps){
				if (dir > 0){
					cast.collider = new Collider(world.width * Game.SCALE, r * Game.SCALE, Game.SCALE, Game.SCALE, Game.SCALE, Collider.SOLID, 0, Collider.MAP_COLLIDER);
				} else if (dir < 0){
					cast.collider = new Collider(-1 * Game.SCALE, r * Game.SCALE, Game.SCALE, Game.SCALE, Game.SCALE, Collider.SOLID, 0, Collider.MAP_COLLIDER);
				}
			}
			// check colliders
			var collider:Collider;
			if(dir > 0){
				for(i = 0; i < world.colliders.length; i++){
					collider = world.colliders[i];
					if(ignore & collider.properties) continue;
					if(collider.x >= x && collider.y <= y && collider.y + collider.height - Collider.INTERVAL_TOLERANCE > y){
						if(cast.collider){
							if(cast.collider.x > collider.x) cast.collider = collider;
						} else {
							cast.collider = collider;
						}
					}
				}
			} else if(dir < 0){
				for(i = 0; i < world.colliders.length; i++){
					collider = world.colliders[i];
					if(ignore & collider.properties) continue;
					if(collider.x + collider.width - Collider.INTERVAL_TOLERANCE < x && collider.y <= y && collider.y + collider.height - Collider.INTERVAL_TOLERANCE > y){
						if(cast.collider){
							if(cast.collider.x < collider.x) cast.collider = collider;
						} else {
							cast.collider = collider;
						}
					}
				}
			}
			if(!cast.collider) return null;
			return cast;
		}
		
		/* Returns a Cast object with the first map surface or Collider encountered horizontally */
		public static function vert(x:Number, y:Number, dir:Number, length:int, ignore:int, world:CollisionWorld):Cast{
			var r:int = y * Game.INV_SCALE;
			// catch off screen behaviour and return null value
			if(r >= world.height || r < 0) return null;
			var c:int = x * Game.INV_SCALE;
			if(c >= world.width || c < 0) return null;
			var id:int, i:int, lengthSteps:int = length;
			var cast:Cast = new Cast();
			for(r = y * Game.INV_SCALE; r > -1 && r < world.height && lengthSteps; r += dir, lengthSteps--){
				id = world.map[r][c];
				// found a static block
				if(id && !(ignore & id)){
					if((dir > 0 && (id & UP)) || (dir < 0 && (id & DOWN))){
						cast.collider = new Collider(c * Game.SCALE, r * Game.SCALE, Game.SCALE, Game.SCALE, Game.SCALE, world.map[r][c], 0, Collider.MAP_COLLIDER);
						break;
					}
				}
			}
			// gone off screen, fake a collider
			if(!cast.collider && lengthSteps){
				if (dir > 0){
					cast.collider = new Collider(c * Game.SCALE, world.height * Game.SCALE, Game.SCALE, Game.SCALE, Game.SCALE, Collider.SOLID, 0, Collider.MAP_COLLIDER);
				} else if (dir < 0){
					cast.collider = new Collider(c * Game.SCALE, -1 * Game.SCALE, Game.SCALE, Game.SCALE, Game.SCALE, Collider.SOLID, 0, Collider.MAP_COLLIDER);
				}
			}
			// check colliders
			var collider:Collider;
			if(dir > 0){
				for(i = 0; i < world.colliders.length; i++){
					collider = world.colliders[i];
					if(ignore & collider.properties) continue;
					if(collider.y >= y && collider.x <= x && collider.x + collider.width - Collider.INTERVAL_TOLERANCE > x){
						if(cast.collider){
							if(cast.collider.y > collider.y) cast.collider = collider;
						} else {
							cast.collider = collider;
						}
					}
				}
			} else if(dir < 0){
				for(i = 0; i < world.colliders.length; i++){
					collider = world.colliders[i];
					if(ignore & collider.properties) continue;
					if(collider.y + collider.height - Collider.INTERVAL_TOLERANCE < y && collider.x <= x && collider.x + collider.width - Collider.INTERVAL_TOLERANCE > x){
						if(cast.collider){
							if(cast.collider.y < collider.y) cast.collider = collider;
						} else {
							cast.collider = collider;
						}
					}
				}
			}
			if(!cast.collider) return null;
			return cast;
		}
		
		/* Is there a line of sight from a point to a Collider?
		 *
		 * vector is the direction of the line of sight. radians describes the width of the cone of
		 * vision, eg: a value of 1.0 would describe a semi-circle of vision outwards from fov
		 * 
		 * this is a cheap test that only verifies a line to the target's center */
		public static function los(source:Point, target:Collider, vector:Point, radians:Number, world:CollisionWorld, ignoreProperties:int = 0):Boolean{
			var vx:Number = (target.x + target.width * 0.5) - source.x;
			var vy:Number = (target.y + target.height * 0.5) - source.y;
			var length:Number = Math.sqrt(vx * vx + vy * vy);
			var dx:Number, dy:Number;
			if(length){
				dx = vx / length;
				dy = vy / length;
			} else {
				return true;
			}
			
			// do a dot product check first to confirm the target is within the cone of vision
			var lx:Number = (radians * vector.x) + (1.0 - radians) * vector.y;
			var ly:Number = (radians * vector.y) + (1.0 - radians) * -vector.x;
			var rx:Number = (radians * vector.x) + (1.0 - radians) * -vector.y;
			var ry:Number = (radians * vector.y) + (1.0 - radians) * vector.x;
			
			if(
				lx * dx + ly * dy > 0 &&
				rx * dx + ry * dy > 0
			){
				var cast:Cast = Cast.ray(source.x, source.y, dx, dy, world, ignoreProperties);
				if(cast && cast.collider == target) return true;
			}
			
			return false;
		}
		
		/*
		 * Returns the distance to the nearest Collider or surface in the CollisionWorld from x,y
		 *
		 * dx,dy is the normal the ray is cast along.
		 */
		public static function ray(x:Number, y:Number, dx:Number, dy:Number, world:CollisionWorld, ignoreProperties:int = 0):Cast {
			
			// abort if we have a zero length normal
			if(dx == 0 && dy == 0) return null;
			
			
			var mapX:int = x * Game.INV_SCALE;
			var mapY:int = y * Game.INV_SCALE;
			
			// abort if outside the map
			if(mapX < 0 || mapY < 0 || mapX >= world.width || mapY >= world.height) return null;
			
			var mapProperty:int = world.map[mapY][mapX];
			var result:Cast = null;
			
			// return immediately if the cast starts inside a wall
			if((mapProperty & Collider.SOLID) == Collider.SOLID && !(mapProperty & ignoreProperties)){
				result = new Cast();
				result.collider = new Collider(mapX * Game.SCALE, mapY * Game.SCALE, Game.SCALE, Game.SCALE, Game.SCALE, mapProperty, 0, Collider.MAP_COLLIDER);
				result.collider.state
				result.distance = 0;
				return result;
			}
			
			var px:Number = x - (mapX * Game.SCALE);
			var py:Number = y - (mapY * Game.SCALE);
			var targetPX:Number = (dx < 0) ? 0 : Game.SCALE;
			var targetPY:Number = (dy < 0) ? 0 : Game.SCALE;
			var dirX:int = dx < 0 ? -1 : 1;
			var dirY:int = dy < 0 ? -1 : 1;
			var invDx:Number = 1 / dx;
			var invDy:Number = 1 / dy;
			var totalDistance:Number = 0;
			
			var breaker:int = 0;
			var toNextX:Number;
			var toNextY:Number;
			
			while(mapX > -1 && mapX < world.width && mapY > -1 && mapY < world.height){
			
				toNextX = Math.abs((px - targetPX) * invDx);
				toNextY = Math.abs((py - targetPY) * invDy);
				
				if(toNextX < toNextY){
					// move horizontally
					mapX += dirX;
					totalDistance += toNextX;
					
					//Game.debug.drawRect(mapX * Game.SCALE, mapY * Game.SCALE, Game.SCALE, Game.SCALE);
					
					// acquire block properties from grid or fabricate an out of range block
					if(mapX < 0 || mapY < 0 || mapY > world.height - 1 || mapX > world.width - 1) mapProperty = Collider.SOLID;
					else mapProperty = world.map[mapY][mapX];
					
					if(
						(mapProperty) && !(mapProperty & ignoreProperties) &&
						((dirX > 0 && (mapProperty & LEFT)) || (dirX < 0 && (mapProperty & RIGHT)))
					){
						result = new Cast;
						result.collider = new Collider(mapX * Game.SCALE, mapY * Game.SCALE, Game.SCALE, Game.SCALE, Game.SCALE, mapProperty, 0, Collider.MAP_COLLIDER);
						result.distance = totalDistance;
						result.surface = dirX > 0 ? LEFT : RIGHT;
						break;
					}
					px += dx * toNextX;
					py += dy * toNextX;
					px -= dirX * Game.SCALE;
				} else {
					// move vertically
					mapY += dirY;
					totalDistance += toNextY;
					
					//Game.debug.drawRect(mapX * Game.SCALE, mapY * Game.SCALE, Game.SCALE, Game.SCALE);
					
					// acquire block properties from grid or fabricate an out of range block
					if(mapX < 0 || mapY < 0 || mapY > world.height - 1 || mapX > world.width - 1) mapProperty = Collider.SOLID;
					else mapProperty = world.map[mapY][mapX];
					if(
						(mapProperty) && !(mapProperty & ignoreProperties) &&
						((dirY > 0 && (mapProperty & UP)) || (dirY < 0 && (mapProperty & DOWN)))
					){
						result = new Cast;
						result.collider = new Collider(mapX * Game.SCALE, mapY * Game.SCALE, Game.SCALE, Game.SCALE, Game.SCALE, mapProperty, 0, Collider.MAP_COLLIDER);
						result.distance = totalDistance;
						result.surface = dirY > 0 ? UP : DOWN;
						break;
					}
					px += dx * toNextY;
					py += dy * toNextY;
					py -= dirY * Game.SCALE;
				}
				
				if(breaker++ > 1000) break;
			}
			
			var lx:Number = dy;
			var ly:Number = -dx;
			var rayIntoNormal:Number = (lx * x) + (ly * y);
			var collider:Collider;
			
			for(var i:int = 0; i < world.colliders.length; i++){
				
				collider = world.colliders[i];
				
				if(collider.properties & ignoreProperties) continue;
				
				// bounding box check. the ray must fall in or before the object
				if(dx > 0 && x > collider.x + collider.width - Collider.INTERVAL_TOLERANCE) continue;
				if(dx < 0 && x < collider.x) continue;
				if(dy > 0 && y > collider.y + collider.height - Collider.INTERVAL_TOLERANCE) continue;
				if(dy < 0 && y < collider.y) continue;

				// check whether the ray passes through the object by testing the dot products in the corners
				var positiveTotal:int = 0;
				var pcx:Number, pcy:Number;
				for(var p:int = 0; p < 4; p ++) {
					pcx = ((p & 1) == 0) ? collider.x : collider.x + collider.width - Collider.INTERVAL_TOLERANCE;
					pcy = (p >= 2) ? collider.y : collider.y + collider.height - Collider.INTERVAL_TOLERANCE;
					if((lx * pcx) + (ly * pcy) >= rayIntoNormal) positiveTotal ++;
				}
				if((positiveTotal == 0) || (positiveTotal == 4)) continue;

				// hit. find *where* the ray hit the object
				var centerX:Number = collider.x + collider.width * 0.5;
				var centerY:Number = collider.y + collider.height * 0.5;
				var targetHitX:Number = (x > centerX) ? collider.x + collider.width - 1 : collider.x;
				var targetHitY:Number = (y > centerY) ? collider.y + collider.height - 1 : collider.y;
				
				var toHitTargetX:Number = Math.abs((x - targetHitX) * invDx);
				var toHitTargetY:Number = Math.abs((y - targetHitY) * invDy);
				
				var heightOfTargetX:Number = y + (dy * toHitTargetX);
				var validHitTargetX:Boolean =
					(heightOfTargetX > collider.y) && (heightOfTargetX < collider.y + collider.height);
					
				var columnOfTargetY:Number = x + (dx * toHitTargetY);
				var validHitTargetY:Boolean =
					(columnOfTargetY > collider.x) && (columnOfTargetY < collider.x + collider.width);
				var surface:int;
				var distance:Number;
				if(!validHitTargetX) {
					distance = toHitTargetY;
					surface = dy > 0 ? UP : DOWN;
				} else if(!validHitTargetY) {
					distance = toHitTargetX;
					surface = dx > 0 ? LEFT : RIGHT;
				} else {
					if(toHitTargetX < toHitTargetY){
						distance = toHitTargetX;
						surface = dx > 0 ? LEFT : RIGHT;
					} else {
						distance = toHitTargetY;
						surface = dy > 0 ? UP : DOWN;
					}
				}
				
				if((!result) || (distance < result.distance)) {
					if(!result) result = new Cast;
					result.collider = collider;
					result.distance = distance;
					result.surface = surface;
				}
			}
			
			return result;
		}
	}

}