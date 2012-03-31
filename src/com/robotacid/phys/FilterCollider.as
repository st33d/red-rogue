package com.robotacid.phys {
	import flash.geom.Rectangle;
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class FilterCollider extends Collider {
		
		public var mapTarget:int;
		public var mapResult:int;
		public var targetIgnore:int;
		
		public function FilterCollider(x:Number = 0, y:Number = 0, width:Number = 0, height:Number = 0, scale:Number = 0, properties:int = SOLID, ignoreProperties:int = 0, state:int = 0) {
			super(x, y, width, height, scale, properties, ignoreProperties, state);
			
		}
		
		/* Sets this collider to interpret any map position with a property in mapTarget as mapResult */
		public function setFilter(mapTarget:int, mapResult:int, targetIgnore:int = 0):void{
			this.mapTarget = mapTarget;
			this.mapResult = mapResult;
			this.targetIgnore = targetIgnore;
		}
		
		override public function moveX(vx:Number, source:Collider = null):Number{
			if((vx > 0 ? vx : -vx) < MOVEMENT_TOLERANCE) return 0;
			var i:int;
			var obstacles:Vector.<Collider>;
			var collider:Collider;
			var obstacleShouldMove:Number;
			var obstacleActuallyMoved:Number;
			var mapX:int;
			var mapY:int;
			var n:Number;
			var minX:int;
			var minY:int;
			var maxX:int;
			var maxY:int;
			var property:int;
			var tempDamping:Number;
			if(vx > 0){
				
				// =============================================================================
				// collision with map:
				if(state != MAP_COLLIDER){
					// inline Math.ceil on X axis
					n = (x + width + vx - INTERVAL_TOLERANCE) * world.invScale;
					maxX = n != n >> 0 ? (n >> 0) + 1 : n >> 0;
					maxY = (y + height - INTERVAL_TOLERANCE) * world.invScale;
					n = (x + width - INTERVAL_TOLERANCE) * world.invScale;
					minX = n != n >> 0 ? (n >> 0) + 1 : n >> 0;
					if(minX >= world.width) minX = world.width - 1;
					if(maxX >= world.width) maxX = world.width - 1;
					minY = y * world.invScale;
					
					scanForwards:
					for(mapX = minX; mapX <= maxX; mapX++){
						for(mapY = minY; mapY <= maxY; mapY++){
							property = world.map[mapY][mapX];
							
							if((property & mapTarget) && !(property & targetIgnore)) property = mapResult;
							
							if(mapX * world.scale < (x + width - INTERVAL_TOLERANCE) + vx && (property & LEFT) && !(property & ignoreProperties)){
								vx -= (x + width + vx) - mapX * world.scale;
								this.vx = 0;
								pressure |= RIGHT;
								break scanForwards;
							}
						}
					}
				}
				
				// =============================================================================
				// collision with other Colliders:
				// check there's still velocity to justify a check
				if((vx > 0 ? vx : -vx) > MOVEMENT_TOLERANCE){
					obstacles = world.getCollidersIn(new Rectangle(x + width, y, vx, height), this, LEFT, ignoreProperties);
					// small optimisation here - sorting needs to be avoided
					if(obstacles.length > 2 ) obstacles.sort(sortLeftWards);
					else if(obstacles.length == 2){
						if(obstacles[0].x > obstacles[1].x){
							tempCollider = obstacles[0];
							obstacles[0] = obstacles[1];
							obstacles[1] = tempCollider;
						}
					}
					for(i = 0; i < obstacles.length; i++){
						collider = obstacles[i];
						// because the vx may get altered over this loop, we need to still check for overlap
						if(collider.x < x + width + vx){
							// bypass colliders we're already inside and platform vs platform
							if(collider.x > x + width - INTERVAL_TOLERANCE && !(state == MAP_COLLIDER && collider.state == MAP_COLLIDER)){
								
								obstacleShouldMove = (x + width + vx) - collider.x;
								if(collider.state == MAP_COLLIDER) obstacleActuallyMoved = 0;
								else if(collider.pushDamping == 1 || state == MAP_COLLIDER) obstacleActuallyMoved = collider.moveX(obstacleShouldMove, this);
								else obstacleActuallyMoved = collider.moveX(obstacleShouldMove * collider.pushDamping, this);
								
								if(collider.state != MAP_COLLIDER){
									collider.pressure |= LEFT;
									if(state != MAP_COLLIDER){
										collider.leftContact = this;
										rightContact = collider;
									}
								}
								
								if(state != MAP_COLLIDER){
									if(obstacleActuallyMoved < obstacleShouldMove){
										vx -= obstacleShouldMove - obstacleActuallyMoved;
										// kill energy when recursively hitting bounds
										if(collider.vx == 0) this.vx = 0;
									}
									pressure |= RIGHT;
								} else {
									if(obstacleActuallyMoved < obstacleShouldMove){
										//collider.crushed = true;
									}
								}
							}
						} else break;
					}
				}
				
				// =============================================================================
				// collision with bounds:
				if(state != MAP_COLLIDER && x + width + vx > world.bounds.x + world.bounds.width){
					vx -= (x + width + vx) - (world.bounds.x + world.bounds.width);
					this.vx = 0;
					if(boundsPressure) pressure |= RIGHT;
				}
			} else if(vx < 0){
				
				// =============================================================================
				// collision with map:
				if(state != MAP_COLLIDER){
					// inline Math.floor on X axis
					n = (x + vx) * world.invScale - 1;
					maxX = n << 0;
					maxY = (y + height - INTERVAL_TOLERANCE) * world.invScale;
					n = x * world.invScale - 1;
					minX = n << 0;
					if(minX < 0) minX = 0;
					if(maxX < 0) maxX = 0;
					minY = y * world.invScale;
					
					scanBackwards:
					for(mapX = minX; mapX >= maxX; mapX--){
						for(mapY = minY; mapY <= maxY; mapY++){
							property = world.map[mapY][mapX];
							
							if((property & mapTarget) && !(property & targetIgnore)) property = mapResult;
							
							if((mapX + 1) * world.scale - INTERVAL_TOLERANCE > x + vx && (property & RIGHT) && !(property & ignoreProperties)){
								vx -= (x + vx) - (mapX + 1) * world.scale;
								this.vx = 0;
								pressure |= LEFT;
								break scanBackwards;
							}
						}
					}
				}
				
				// =============================================================================
				// collision with other Colliders:
				// check there's still velocity to justify a check
				if((vx > 0 ? vx : -vx) > MOVEMENT_TOLERANCE){
					obstacles = world.getCollidersIn(new Rectangle(x + vx, y, -vx, height), this, RIGHT, ignoreProperties);
					// small optimisation here - sorting needs to be avoided
					if(obstacles.length > 2 ) obstacles.sort(sortRightWards);
					else if(obstacles.length == 2){
						if(obstacles[0].x < obstacles[1].x){
							tempCollider = obstacles[0];
							obstacles[0] = obstacles[1];
							obstacles[1] = tempCollider;
						}
					}
					for(i = 0; i < obstacles.length; i++){
						collider = obstacles[i];
						// because the vx may get altered over this loop, we need to still check for overlap
						if(collider.x + collider.width > x + vx){
							// bypass colliders we're already inside and platform vs platform
							if(collider.x + collider.width - INTERVAL_TOLERANCE < x && !(state == MAP_COLLIDER && collider.state == MAP_COLLIDER)){
								
								obstacleShouldMove = (x + vx) - (collider.x + collider.width);
								if(collider.state == MAP_COLLIDER) obstacleActuallyMoved = 0;
								else if(collider.pushDamping == 1 || state == MAP_COLLIDER) obstacleActuallyMoved = collider.moveX(obstacleShouldMove, this);
								else obstacleActuallyMoved = collider.moveX(obstacleShouldMove * collider.pushDamping, this);
								
								if(collider.state != MAP_COLLIDER){
									collider.pressure |= RIGHT;
									if(state != MAP_COLLIDER){
										collider.rightContact = this;
										leftContact = collider;
									}
								}
								
								if(state != MAP_COLLIDER){
									if(obstacleActuallyMoved > obstacleShouldMove){
										vx += obstacleActuallyMoved - obstacleShouldMove;
										// kill energy when recursively hitting bounds
										if(collider.vx == 0) this.vx = 0;
									}
									pressure |= LEFT;
								} else {
									if(obstacleActuallyMoved > obstacleShouldMove){
										//collider.crushed = true;
									}
								}
							}
						} else break;
					}
				}
				
				// =============================================================================
				// collision with bounds:
				if(state != MAP_COLLIDER && x + vx < world.bounds.x){
					vx += world.bounds.x - (x + vx);
					this.vx = 0;
					if(boundsPressure) pressure |= LEFT;
				}
			}
			x += vx;
			
			// if the collider has a parent, check it is still sitting on it
			if(parent && (x + width <= parent.x || x >= parent.x + parent.width)){
				parent.removeChild(this);
			}
			// if the collider has children, move them
			if(children.length){
				if(vx > 0){
					for(i = children.length - 1; i > -1; i--){
						collider = children[i];
						collider.moveX(vx);
					}
				} else if(vx < 0){
					for(i = 0; i < children.length; i++){
						collider = children[i];
						collider.moveX(vx);
					}
				}
			}
			awake = AWAKE_DELAY;
			return vx;
		}
		
		override public function moveY(vy:Number, source:Collider = null):Number{
			if((vy > 0 ? vy : -vy) < MOVEMENT_TOLERANCE) return 0;
			var i:int, j:int;
			var obstacles:Vector.<Collider>;
			var stompees:Vector.<Collider>;
			var collider:Collider;
			var obstacleShouldMove:Number;
			var obstacleActuallyMoved:Number;
			var mapX:int;
			var mapY:int;
			var n:Number;
			var minX:int;
			var minY:int;
			var maxX:int;
			var maxY:int;
			var property:int;
			if(vy > 0){
				
				// =============================================================================
				// collision with map:
				if(state != MAP_COLLIDER){
					// inline Math.ceil on Y axis
					n = (y + height + vy - INTERVAL_TOLERANCE) * world.invScale;
					maxY = n != n >> 0 ? (n >> 0) + 1 : n >> 0;
					maxX = (x + width - INTERVAL_TOLERANCE) * world.invScale;
					n = (y + height - INTERVAL_TOLERANCE) * world.invScale;
					minY = n != n >> 0 ? (n >> 0) + 1 : n >> 0;
					if(minY >= world.height) minY = world.height - 1;
					if(maxY >= world.height) maxY = world.height - 1;
					minX = x * world.invScale;
					
					scanForwards:
					for(mapY = minY; mapY <= maxY; mapY++){
						for(mapX = minX; mapX <= maxX; mapX++){
							property = world.map[mapY][mapX];
							
							if((property & mapTarget) && !(property & targetIgnore)) property = mapResult;
							
							if(mapY * world.scale < y + height + vy && (property & UP) && !(property & ignoreProperties)){
								vy -= (y + height + vy) - mapY * world.scale;
								this.vy = 0;
								pressure |= DOWN;
								// create a dummy collider surface to stand on
								if(parent != mapCollider){
									if(parent) parent.removeChild(this);
									mapCollider.x = mapX * world.scale;
									mapCollider.y = mapY * world.scale;
									mapCollider.properties = property;
									mapCollider.addChild(this);
								}
								break scanForwards;
							}
						}
					}
				}
				
				// =============================================================================
				// collision with other Colliders:
				// check there's still velocity to justify a check
				if((vy > 0 ? vy : -vy) > MOVEMENT_TOLERANCE){
					obstacles = world.getCollidersIn(new Rectangle(x, y + height, width, vy), this, UP, ignoreProperties);
					// small optimisation here - sorting needs to be avoided
					if(obstacles.length > 2 ) obstacles.sort(sortTopWards);
					else if(obstacles.length == 2){
						if(obstacles[0].y > obstacles[1].y){
							tempCollider = obstacles[0];
							obstacles[0] = obstacles[1];
							obstacles[1] = tempCollider;
						}
					}
					for(i = 0; i < obstacles.length; i++){
						collider = obstacles[i];
						// because the vy may get altered over this loop, we need to still check for overlap
						if(collider.y < y + height + vy){
							// bypass colliders we're already inside and platform vs platform
							if(collider.y > y + height - INTERVAL_TOLERANCE && !(state == MAP_COLLIDER && collider.state == MAP_COLLIDER)){
								
								obstacleShouldMove = (y + height + vy) - collider.y;
								if(collider.state == MAP_COLLIDER) obstacleActuallyMoved = 0;
								else if(collider.pushDamping == 1 || state == MAP_COLLIDER) obstacleActuallyMoved = collider.moveY(obstacleShouldMove, this);
								else obstacleActuallyMoved = collider.moveY(obstacleShouldMove * collider.pushDamping, this);
								
								if(collider.state != MAP_COLLIDER){
									collider.pressure |= UP;
									if(state != MAP_COLLIDER){
										collider.upContact = this;
										downContact = collider;
									}
								}
								
								if(state != MAP_COLLIDER){
									
									// ==========================================================================
									// STOMP LOGIC
									// this is specific to Red Rogue, used by Characters to perform their stomp-stun attack
									if(stompProperties && Boolean(collider.stompCallback)){
										
										n = collider.x + collider.width * 0.5;
										if(n < x + width * 0.5){
											collider.moveX(x - (collider.x + collider.width + MOVEMENT_TOLERANCE));
										} else {
											collider.moveX((x + width + MOVEMENT_TOLERANCE) - collider.x);
										}
										// if the collider is not STACKed, kick it downwards
										if(collider.state != Collider.STACK){
											collider.moveY(obstacleShouldMove, this);
											collider.state = Collider.FALL;
										}
										// scan, the stomp may not have pushed the collider free - it is doomed
										//stompees = world.getCollidersIn(new Rectangle(x, y + vy, width, height), this, stompProperties);
										//for(j = 0; j < stompees.length; j++){
											//tempCollider = stompees[j];
											//if(tempCollider == collider) collider.crushed = true;
										//}
										 //stomp callback only when the victim's center is under our base - be generous
										//if(!collider.crushed && (n < x || n > x + width - INTERVAL_TOLERANCE)) collider.stompCallback(this);
										collider.stompCallback(this);
										divorce();
										
									} else {
										if(obstacleActuallyMoved < obstacleShouldMove){
											vy -= obstacleShouldMove - obstacleActuallyMoved;
											// kill energy when recursively hitting bounds
											if(collider.vy == 0) this.vy = 0;
										}
										pressure |= DOWN;
									
										// make this Collider a child of the obstacle
										if(collider != parent){
											if(parent) parent.removeChild(this);
											collider.addChild(this);
										}
									}
								} else {
									if(obstacleActuallyMoved < obstacleShouldMove){
										//collider.crushed = true;
									}
								}
							}
						} else break;
					}
				}
				
				// =============================================================================
				// collision with bounds:
				if(state != MAP_COLLIDER && y + height + vy > world.bounds.y + world.bounds.height){
					vy -= (y + height + vy) - (world.bounds.y + world.bounds.height);
					this.vy = 0;
					if(boundsPressure) pressure |= DOWN;
				}
			} else if(vy < 0){
				
				// =============================================================================
				// collision with map:
				if(state != MAP_COLLIDER){
					// inline Math.floor on X axis
					n = (y + vy) * world.invScale - 1;
					maxY = n << 0;
					maxX = (x + width - INTERVAL_TOLERANCE) * world.invScale;
					n = y * world.invScale - 1;
					minY = n << 0;
					if(minY < 0) minY = 0;
					if(maxY < 0) maxY = 0;
					minX = x * world.invScale;
					
					scanBackwards:
					for(mapY = minY; mapY >= maxY; mapY--){
						for(mapX = minX; mapX <= maxX; mapX++){
							property = world.map[mapY][mapX];
							
							if((property & mapTarget) && !(property & targetIgnore)) property = mapResult;
							
							if((mapY + 1) * world.scale > y + vy && (property & DOWN) && !(property & ignoreProperties)){
								vy -= (y + vy) - ((mapY + 1) * world.scale);
								this.vy = 0;
								pressure |= UP;
								break scanBackwards;
							}
						}
					}
				}
				
				// =============================================================================
				// collision with other Colliders:
				// check there's still velocity to justify a check
				if((vy > 0 ? vy : -vy) > MOVEMENT_TOLERANCE){
					obstacles = world.getCollidersIn(new Rectangle(x, y + vy, width, -vy), this, DOWN, ignoreProperties);
					// small optimisation here - sorting needs to be avoided
					if(obstacles.length > 2 ) obstacles.sort(sortBottomWards);
					else if(obstacles.length == 2){
						if(obstacles[0].y < obstacles[1].y){
							tempCollider = obstacles[0];
							obstacles[0] = obstacles[1];
							obstacles[1] = tempCollider;
						}
					}
					for(i = 0; i < obstacles.length; i++){
						collider = obstacles[i];
						// because the vy may get altered over this loop, we need to still check for overlap
						if(collider.y + collider.height > y + vy){
							// bypass colliders we're already inside and platform vs platform
							if(collider.y + collider.height - INTERVAL_TOLERANCE < y && !(state == MAP_COLLIDER && collider.state == MAP_COLLIDER)){
								
								obstacleShouldMove = (y + vy) - (collider.y + collider.height);
								if(collider.state == MAP_COLLIDER) obstacleActuallyMoved = 0;
								else if(collider.pushDamping == 1 || state == MAP_COLLIDER) obstacleActuallyMoved = collider.moveY(obstacleShouldMove, this);
								else obstacleActuallyMoved = collider.moveY(obstacleShouldMove * collider.pushDamping, this);
								
								if(collider.state != MAP_COLLIDER){
									collider.pressure |= DOWN;
									if(state != MAP_COLLIDER){
										collider.downContact = this;
										upContact = collider;
									}
								}
								
								if(state != MAP_COLLIDER){
									if(obstacleActuallyMoved > obstacleShouldMove){
										vy += obstacleActuallyMoved - obstacleShouldMove;
										// kill energy when recursively hitting bounds
										if(collider.vy == 0) this.vy = 0;
									}
									pressure |= UP;
								} else {
									if(obstacleActuallyMoved > obstacleShouldMove){
										//collider.crushed = true;
									}
								}
								// make the obstacle a child of this Collider
								if(collider.state != MAP_COLLIDER && collider.parent != this && collider.pushDamping > 0){
									if(collider.parent) collider.parent.removeChild(collider);
									addChild(collider);
								}
							}
						} else break;
					}
				}
				
				// =============================================================================
				// collision with bounds:
				if(state != MAP_COLLIDER && y + vy < world.bounds.y){
					vy += world.bounds.y - (y + vy);
					this.vy = 0;
					if(boundsPressure) pressure |= UP;
				}
			}
			y += vy;
			
			// move children - ie: blocks stacked on top of this Collider
			// stacked children should not be moved when travelling up - this Collider is already taking care of that
			// by pushing them, climbing children on the other hand must be moved
			if(vy > 0){
				for(i = 0; i < children.length; i++){
					collider = children[i];
					collider.moveY(vy);
				}
			// if there is a parent, is it still below?
			} else if(vy < 0){
				if(parent && parent != source && parent.y > y + height + INTERVAL_TOLERANCE){
					parent.removeChild(this);
				}
				for(i = 0; i < children.length; i++){
					collider = children[i];
					if(collider.state == HOVER){
						children[i].moveY(vy);
					}
				}
			}
			awake = AWAKE_DELAY;
			return vy;
		}
	}

}