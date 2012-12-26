package com.robotacid.phys {

	import com.robotacid.engine.Missile;
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	
	/**
	 * A crate-like collision object.
	 *
	 * Movement is separated into X axis and Y axis separately for speed and sanity
	 *
	 * Collisions are handled recursively, allowing the Collider to push queues of Colliders.
	 *
	 * The Collider has several states to reflect how it may need to be handled.
	 *
	 * The stackCallback is for assigning to a function that signals a Collider has hit the floor.
	 *
	 * The crushCallback is for assigning to a function that signals a Collider has been crushed. A crush
	 * callback must call CollisionWorld.removeCollider as it is assumed the callback will want access to
	 * the world before the collider is destroyed
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Collider extends Rectangle {
		
		public var world:CollisionWorld;
		public var parent:Collider;
		public var mapCollider:Collider;
		public var children:Vector.<Collider>;
		public var userData:*;
		public var stackCallback:Function;
		public var crushCallback:Function;
		public var stompCallback:Function;
		public var upContact:Collider;
		public var rightContact:Collider;
		public var downContact:Collider;
		public var leftContact:Collider;
		
		public var state:int;
		public var properties:int;
		public var ignoreProperties:int;
		public var stompProperties:int;
		public var vx:Number;
		public var vy:Number;
		public var gravity:Number;
		public var dampingX:Number;
		public var dampingY:Number;
		public var pushDamping:Number;
		public var pressure:int;
		public var crushed:Boolean;
		public var awake:int;
		public var boundsPressure:Boolean;
		public var stackable:Boolean;
		
		/* Establishes a minimum movement policy */
		public static const MOVEMENT_TOLERANCE:Number = 0.0001;
		
		/* Used for compensate for floating point value drift */
		public static const INTERVAL_TOLERANCE:Number = CollisionWorld.INTERVAL_TOLERANCE;
		
		/* Echoing Box2D, colliders sleep when inactive to prevent method calls that aren't needed */
		public static var AWAKE_DELAY:int = 3;
		
		protected static var tempCollider:Collider;
		
		public static const DEFAULT_GRAVITY:Number = 0.8;
		public static const DEFAULT_DAMPING_X:Number = 0.45;
		public static const DEFAULT_DAMPING_Y:Number = 0.99;
		public static const DEFAULT_PUSH_DAMPING:Number = 1;
		
		// states
		public static const FALL:int = 0;
		public static const STACK:int = 1;
		public static const HOVER:int = 2;
		public static const MAP_COLLIDER:int = 3;
		
		/* No block here */
		public static const EMPTY:int = 0;
		
		// properties 0 to 3 are the sides of a Rectangle
		public static const UP:int = 1 << 0;
		public static const RIGHT:int = 1 << 1;
		public static const DOWN:int = 1 << 2;
		public static const LEFT:int = 1 << 3;
		// equivalent to (UP | RIGHT | LEFT | DOWN) the compiler won't allow calculated constants as default params
		public static const SOLID:int = 15;
		
		/* A Collider that doesn't move */
		public static const STATIC:int = 1 << 4;
		/* A Collider that can break */
		public static const BREAKABLE:int = 1 << 5;
		/* A free moving crate style Collider - for puzzles */
		public static const FREE:int = 1 << 6;
		/* A Collider that moves on its own */
		public static const MOVING:int = 1 << 7;
		/* This Collider is the collision space of a monster */
		public static const MONSTER:int = 1 << 8;
		/* This Collider is the collision space of the player */
		public static const PLAYER:int = 1 << 9;
		/* A Collider whose upper edge resists colliders moving down but not in any other direction */
		public static const LEDGE:int = 1 << 10;
		/* Dungeon walls */
		public static const WALL:int = 1 << 11;
		/* This Collider is either a monster or the player */
		public static const CHARACTER:int = 1 << 12;
		/* This Collider is a decapitated head */
		public static const HEAD:int = 1 << 13;
		/* This is an area that is a ladder */
		public static const LADDER:int = 1 << 14;
		/* This Collider is a slave of the player */
		public static const MINION:int = 1 << 15;
		/* This Collider is an animation for the decapitation of Characters */
		public static const CORPSE:int = 1 << 16;
		/* This Collider is a projectile */
		public static const MISSILE:int = 1 << 17;
		/* This Collider is a collectable item */
		public static const ITEM:int = 1 << 18;
		/* This Collider is a wall that can be attacked */
		public static const STONE:int = 1 << 19;
		/* This Collider is a wall that moves randomly */
		public static const CHAOS:int = 1 << 20;
		/* This Collider is a missile of the player team */
		public static const PLAYER_MISSILE:int = 1 << 21;
		/* This Collider is a missile of the monster team */
		public static const MONSTER_MISSILE:int = 1 << 22;
		/* This Collider is a horror creature */
		public static const HORROR:int = 1 << 23;
		/* This Collider is a wall on the edge of the map */
		public static const MAP_EDGE:int = 1 << 24;
		/* This Collider is a barrier that can be raised */
		public static const GATE:int = 1 << 25;
		/* This Collider is the end-game boss */
		public static const BALROG:int = 1 << 26;
		
		public function Collider(x:Number = 0, y:Number = 0, width:Number = 0, height:Number = 0, scale:Number = 0, properties:int = SOLID, ignoreProperties:int = 0, state:int = 0){
			super(x, y, width, height);
			this.properties = properties;
			this.ignoreProperties = ignoreProperties;
			this.state = state;
			
			vx = vy = 0;
			gravity = DEFAULT_GRAVITY;
			dampingX = DEFAULT_DAMPING_X;
			dampingY = DEFAULT_DAMPING_Y;
			pushDamping = DEFAULT_PUSH_DAMPING;
			awake = AWAKE_DELAY;
			boundsPressure = false;
			stackable = true;
			
			children = new Vector.<Collider>();
			
			if(state != MAP_COLLIDER){
				// create a dummy surface for interacting with the map
				mapCollider = new Collider(0, 0, scale, scale, scale, SOLID, 0, MAP_COLLIDER);
			}
		}
		
		public function main():void{
			if(state == STACK || state == FALL){
				
				vx *= dampingX;
				if((vx > 0 ? vx : -vx) > MOVEMENT_TOLERANCE) moveX(vx);
				
				// check for ignoring parent
				if(parent && (parent.properties & ignoreProperties)){
					parent.removeChild(this);
				}
				
				if(!parent || vy < -MOVEMENT_TOLERANCE){
					vy = vy * dampingY + gravity;
					if((vy > 0 ? vy : -vy) > MOVEMENT_TOLERANCE) moveY(vy);
				} else if(vy > MOVEMENT_TOLERANCE){
					vy = 0;
				}
				
				if(parent){
					if(state != STACK){
						state = STACK;
						if(Boolean(stackCallback)) stackCallback();
					}
					
				} else if(state != FALL){
					state = FALL;
				}
				
			} else if(state == HOVER){
				
				vx *= dampingX;
				vy *= dampingY;
				if((vx > 0 ? vx : -vx) > MOVEMENT_TOLERANCE) moveX(vx);
				if((vy > 0 ? vy : -vy) > MOVEMENT_TOLERANCE) moveY(vy);
				
			} else if(state == MAP_COLLIDER){
				
				if((vx > 0 ? vx : -vx) > MOVEMENT_TOLERANCE) moveX(vx);
				if((vy > 0 ? vy : -vy) > MOVEMENT_TOLERANCE) moveY(vy);
			}
			
			// will put the collider to sleep if it doesn't move
			if((vx > 0 ? vx : -vx) < MOVEMENT_TOLERANCE && (vy > 0 ? vy : -vy) < MOVEMENT_TOLERANCE && (awake)) awake--;
		}
		
		public function drag(vx:Number, vy:Number):void{
			moveX(vx);
			moveY(vy);
		}
		
		/* =================================================================
		 * Sorting callbacks for colliding with objects in the correct order
		 * =================================================================
		 */
		public static function sortLeftWards(a:Collider, b:Collider):Number{
			if(a.x < b.x) return -1;
			else if(a.x > b.x) return 1;
			return 0;
		}
		
		public static function sortRightWards(a:Collider, b:Collider):Number{
			if(a.x > b.x) return -1;
			else if(a.x < b.x) return 1;
			return 0;
		}
		
		public static function sortTopWards(a:Collider, b:Collider):Number{
			if(a.y < b.y) return -1;
			else if(a.y > b.y) return 1;
			return 0;
		}
		
		public static function sortBottomWards(a:Collider, b:Collider):Number{
			if(a.y > b.y) return -1;
			else if(a.y < b.y) return 1;
			return 0;
		}
		
		/* add a child Collider to this Collider - it will move when this collider moves */
		public function addChild(collider:Collider):void{
			collider.parent = this;
			collider.vy = 0;
			// optimisation:
			// children must be ordered leftwards so their parent can
			// move them with out them colliding into each other
			if(children.length){
				if(children.length == 1){
					if(collider.x < children[0].x){
						children.unshift(collider);
					} else {
						children.push(collider);
					}
				} else {
					children.push(collider);
					children.sort(sortLeftWards);
				}
			} else {
				children[0] = collider;
			}
		}
		
		/* remove a child collider from children */
		public function removeChild(collider:Collider):void{
			collider.parent = null;
			children.splice(children.indexOf(collider), 1);
			collider.awake = AWAKE_DELAY;
		}
		
		/* Get rid of children and parent - used to remove the collider from the game and clear current interaction */
		public function divorce():void{
			if(parent){
				parent.removeChild(this);
				vy = 0;
			}
			var collider:Collider;
			for(var i:int = 0; i < children.length; i++){
				collider = children[i];
				collider.parent = null;
				collider.vy = 0;
				collider.awake = AWAKE_DELAY;
			}
			pressure = 0;
			children.length = 0;
			awake = AWAKE_DELAY;
		}
		
		/* Creates a parent Collider out of thin air for this Collider - there are edge cases where this is desirable */
		public function createParent(properties:int):void{
			if(parent) parent.removeChild(this);
			mapCollider.x = x - width * 0.5;
			mapCollider.y = world.bounds.y + world.bounds.height;
			mapCollider.properties = properties;
			mapCollider.addChild(this);
		}
		
		public function moveX(vx:Number, source:Collider = null):Number{
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
					minY = (y + INTERVAL_TOLERANCE) * world.invScale;
					
					scanForwards:
					for(mapX = minX; mapX <= maxX; mapX++){
						for(mapY = minY; mapY <= maxY; mapY++){
							property = world.map[mapY][mapX];
							if(mapX * world.scale < (x + width - INTERVAL_TOLERANCE) + vx && (property & LEFT) && !(property & ignoreProperties)){
								vx -= (x + width + vx) - mapX * world.scale;
								if(this.vx > 0) this.vx = 0;
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
										if(collider.vx == 0 && this.vx > 0) this.vx = 0;
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
					minY = (y + INTERVAL_TOLERANCE) * world.invScale;
					
					scanBackwards:
					for(mapX = minX; mapX >= maxX; mapX--){
						for(mapY = minY; mapY <= maxY; mapY++){
							property = world.map[mapY][mapX];
							if((mapX + 1) * world.scale - INTERVAL_TOLERANCE > x + vx && (property & RIGHT) && !(property & ignoreProperties)){
								vx -= (x + vx) - (mapX + 1) * world.scale;
								if(this.vx < 0) this.vx = 0;
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
										if(collider.vx == 0 && this.vx < 0) this.vx = 0;
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
			tempCollider = null;
			return vx;
		}
		
		public function moveY(vy:Number, source:Collider = null):Number{
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
					minX = (x + INTERVAL_TOLERANCE) * world.invScale;
					
					scanForwards:
					for(mapY = minY; mapY <= maxY; mapY++){
						for(mapX = minX; mapX <= maxX; mapX++){
							property = world.map[mapY][mapX];
							if(mapY * world.scale < y + height + vy && (property & UP) && !(property & ignoreProperties)){
								vy -= (y + height + vy) - mapY * world.scale;
								if(this.vy > 0) this.vy = 0;
								pressure |= DOWN;
								// create a dummy collider surface to stand on
								if(stackable && parent != mapCollider){
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
											if(collider.vy == 0 && this.vy > 0) this.vy = 0;
										}
										pressure |= DOWN;
									
										// make this Collider a child of the obstacle
										if((stackable && collider.stackable) && collider != parent){
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
					minX = (x + INTERVAL_TOLERANCE) * world.invScale;
					
					scanBackwards:
					for(mapY = minY; mapY >= maxY; mapY--){
						for(mapX = minX; mapX <= maxX; mapX++){
							property = world.map[mapY][mapX];
							if((mapY + 1) * world.scale > y + vy && (property & DOWN) && !(property & ignoreProperties)){
								vy -= (y + vy) - ((mapY + 1) * world.scale);
								if(this.vy < 0) this.vy = 0;
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
										if(collider.vy == 0 && this.vy < 0) this.vy = 0;
									}
									pressure |= UP;
								} else {
									if(obstacleActuallyMoved > obstacleShouldMove){
										//collider.crushed = true;
									}
								}
								// make the obstacle a child of this Collider
								if((stackable && collider.stackable) && collider.state != MAP_COLLIDER && collider.parent != this && collider.pushDamping > 0){
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
			tempCollider = null;
			return vy;
		}
		
		/* Return a recent contact */
		public function getContact():Collider{
			if(upContact) return upContact;
			else if(rightContact) return rightContact;
			else if(downContact) return downContact;
			else if(leftContact) return leftContact;
			return null
		}
		
		/* Pushes a collider out of any map surfaces it overlaps - used to resolve changing a collider's shape */
		public function resolveMapInsertion(world:CollisionWorld = null):void{
			world = world || this.world;
			if(!world) return;
			
			var mapX:int, mapY:int;
			
			mapY = (y + height * 0.5) * world.invScale;
			
			mapX = x * world.invScale;
			if((world.map[mapY][mapX] & RIGHT) && x >= (mapX + 0.5) * world.scale) x = (mapX + 1) * world.scale;
			
			mapX = (x + width - INTERVAL_TOLERANCE) * world.invScale;
			if((world.map[mapY][mapX] & LEFT) && x + width - INTERVAL_TOLERANCE <= (mapX + 0.5) * world.scale) x = mapX * world.scale-width;
			
			mapX = (x + width * 0.5) * world.invScale;
			
			mapY = y * world.invScale;
			if((world.map[mapY][mapX] & DOWN) && y >= (mapY + 0.5) * world.scale) y = (mapY + 1) * world.scale;
			
			mapY = (y + height - INTERVAL_TOLERANCE) * world.invScale;
			if((world.map[mapY][mapX] & UP) && y + height - INTERVAL_TOLERANCE <= (mapY + 0.5) * world.scale) y = mapY * world.scale-height;
			
		}
		
		/* Draw debug diagram */
		public function draw(gfx:Graphics):void{
			gfx.lineStyle(1, 0x33AA66);
			gfx.drawRect(x, y, width, height);
			if(awake){
				gfx.drawRect(x + width * 0.4, y + height * 0.4, width * 0.2, height * 0.2);
			}
			if(parent != null){
				gfx.moveTo(x + width * 0.5, y + height * 0.5);
				gfx.lineTo(parent.x + parent.width * 0.5, parent.y + parent.height * 0.5);
			}
			if(state == STACK){
				gfx.drawCircle(x + width * 0.5, y + height - height * 0.25, Math.min(width, height) * 0.25);
			} else if(state == FALL){
				gfx.drawCircle(x + width * 0.5, y + height * 0.5, Math.min(width, height) * 0.25);
			}
			if(pressure){
				if(pressure & UP){
					gfx.moveTo(x + width * 0.2, y + height * 0.2);
					gfx.lineTo(x + width * 0.8, y + height * 0.2);
				}
				if(pressure & RIGHT){
					gfx.moveTo(x + width * 0.8, y + height * 0.2);
					gfx.lineTo(x + width * 0.8, y + height * 0.8);
				}
				if(pressure & DOWN){
					gfx.moveTo(x + width * 0.2, y + height * 0.8);
					gfx.lineTo(x + width * 0.8, y + height * 0.8);
				}
				if(pressure & LEFT){
					gfx.moveTo(x + width * 0.2, y + height * 0.2);
					gfx.lineTo(x + width * 0.2, y + height * 0.8);
				}
			}
		}
		
		override public function toString():String {
			return "(x:"+x+" y:"+y+" width:"+width+" height:"+height+" type:"+propertiesToString(properties)+")";
		}
		
		/* Returns all properties of this block as a string */
		public static function propertiesToString(type:int):String{
			if (type == EMPTY) return "EMPTY";
			var n:int, s:String = "";
			for (var i:int = 0; i < 12; i++){
				n = type & (1 << i);
				if (s == "UP|RIGHT|DOWN|LEFT|") s = "SOLID|";
				if (n == UP) s += "UP|";
				else if (n == RIGHT) s += "RIGHT|";
				else if (n == DOWN) s += "DOWN|";
				else if (n == LEFT) s += "LEFT|";
				else if (n == STATIC) s += "STATIC|";
				else if (n == BREAKABLE) s += "BREAKABLE|";
				else if (n == FREE) s += "FREE|";
				else if (n == MOVING) s += "MOVING|";
				else if (n == MONSTER) s += "MONSTER|";
				else if (n == PLAYER) s += "PLAYER|";
				else if (n == LEDGE) s += "LEDGE|";
				else if (n == WALL) s += "WALL|";
				else if (n == CHARACTER) s += "CHARACTER|";
			}
			return s.substr(0, s.length - 1);
		}
	}
}