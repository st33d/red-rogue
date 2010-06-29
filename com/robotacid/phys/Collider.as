package com.robotacid.phys {
	import com.robotacid.engine.Entity;
	import com.robotacid.engine.Player;
	import com.robotacid.geom.Rect;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	
	/**
	 * A block that can move or be moved
	 * Serves as a superclass to the Player, monsters, FreeBlocks and MovingBlocks
	 *
	 * Stacked movement is achieved through a child-parent system
	 * When a Collider lands on another Collider, it becomes a child of that Collider,
	 * moving when its parent moves. It's not a perfect system, but the best I could come
	 * up with to deal with the problem of moving platforms and pushing stacks of crates.
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	
	public class Collider extends Entity{
		
		public var vx:Number, vy:Number;
		
		public var platform:Boolean;
		public var children:Vector.<Collider>;
		public var parent:Collider;
		public var parentBlock:Block;
		
		public var collisions:int;
		
		/* basically a block object we can access through rect */
		public var block:Block;
		
		/* A Collider will ignore all blocks with properties present in this variable */
		public var ignore:int;
		
		public var awake:int;
		
		public var width:Number;
		public var height:Number;
		
		public var weight:int;
		
		public var upCollider:Collider;
		public var rightCollider:Collider;
		public var leftCollider:Collider;
		public var downCollider:Collider;
		
		/* To give Characters a chance of surviving a glancing blow to the head, we make their heads slippy */
		public var inflictsCrush:Boolean;
		public var crushable:Boolean;
		
		// there needs to be a limit to how little an object can move
		public static const TOLERANCE:Number = 0.0001;
		
		/* The size lip the collider will walk up when travelling left or right */
		public static const LIP_HEIGHT:Number = 2;
		
		// This value needs to be at a maximum value of the smallest side a Collider has been given in the game
		// otherwise that small Collider will curiously sink into other objects
		// The value is variable for on the fly optimisation
		public static var scanStep:Number = 5;
		
		/* Echoing Box2D, colliders sleep when inactive to prevent method calls that aren't needed */
		public static var AWAKE_DELAY:int = 10;
		
		public function Collider(mc:DisplayObject, width:Number, height:Number, g:Game, active:Boolean = false) {
			super(mc, g, true, active);
			this.width = width;
			this.height = height;
			block = new Block(x, y, width, height, Block.SOLID);
			rect = block;
			updateRect();
			parent = null;
			children = new Vector.<Collider>();
			if(active) g.colliders.push(this);
			ignore = 0;
			weight = 1;
			platform = false;
			awake = AWAKE_DELAY;
			vx = vy = 0;
			inflictsCrush = false;
			crushable = false;
		}
		
		public function updateRect():void{
			rect.x = x;
			rect.y = y;
		}
		
		/* Move the collider horizontally and push any Colliders it encounters in its way
		 * also moves any children of this collider
		 */
		public function moveX(xm:Number, source:Collider = null):Number{
			if(Math.abs(xm) < TOLERANCE) return 0;
			var r:Number;
			var c:Number;
			var test:Cast;
			var colliderMoved:Number = 0;
			var length:int = 2 + Math.abs(xm) * INV_SCALE;
			// horizontal movement
			// moving right
			if(xm > 0){
				// test grid intervals
				for(r = rect.y; r < rect.y + rect.height + SCALE; r += scanStep){
					
					// cast for obstacles
					test = Cast.horiz(rect.x + rect.width - 1, r < rect.y + rect.height - 1 ? r : rect.y + rect.height - 1, 1, length, g.blockMap, ignore, g);
					if(test){
						// moving against a collider
						if(test.collider && test.collider != this){
							if(test.collider.parent != this && parent != test.collider){
								if(rect.x + rect.width + xm >= test.block.x){
									
									test.collider.collisions |= Rect.LEFT;
									collisions |= Rect.RIGHT;
									test.collider.leftCollider = this;
									rightCollider = test.collider;
									
									// move collider as much as it was bitten into
									if(!(test.collider.collisions & Rect.RIGHT) && test.collider.weight < weight){
										colliderMoved = test.collider.moveX(xm - (test.block.x - (rect.x + rect.width)), source);
									}
									// if the collider has met a static wall, reduce possible movement
									// and adopt collision status
									if((test.collider.collisions & Rect.RIGHT) || test.collider.weight >= weight){
										if(colliderMoved != 0){
											xm -= xm - colliderMoved;
										} else {
											xm = test.collider.rect.x - (rect.x + rect.width);
										}
									}
								}
							}
						// moving against static walls
						} else if(test.block){
							if(rect.x + rect.width + xm >= test.block.x){
								xm = test.block.x - (rect.x + rect.width);
								collisions |= Rect.RIGHT;
							}
						}
					}
				}
			// moving left
			} else if(xm < 0){
				// test grid intervals
				for(r = rect.y; r < rect.y + rect.height + SCALE; r += scanStep){
					
					// cast for obstacles
					test = Cast.horiz(rect.x, r < rect.y + rect.height - 1 ? r : rect.y + rect.height - 1, -1, length, g.blockMap, ignore, g);
					
					if(test){
						// moving against a collider
						if(test.collider && test.collider != this){
							if(test.collider.parent != this && parent != test.collider){
								if(rect.x + xm < test.block.x + test.block.width){
									
									test.collider.collisions |= Rect.RIGHT;
									collisions |= Rect.LEFT;
									test.collider.rightCollider = this;
									leftCollider = test.collider;
									
									// move collider as much as it was bitten into
									if(!(test.collider.collisions & Rect.LEFT) && test.collider.weight < weight){
										colliderMoved = test.collider.moveX(xm - ((test.block.x + test.block.width) - rect.x), source);
									}
									// if the collider has met a static wall, reduce possible movement
									// and adopt collision status
									if((test.collider.collisions & Rect.LEFT) || test.collider.weight >= weight){
										if (colliderMoved != 0){
											xm -= xm - colliderMoved;
										} else {
											xm = (test.collider.rect.x + test.collider.rect.width) - rect.x;
										}
									}
								}
							}
						// moving against static walls
						} else if(test.block){
							if (rect.x + xm < test.block.x + test.block.width){
								xm = (test.block.x + test.block.width) - rect.x;
								collisions |= Rect.LEFT;
							}
						}
					}
				}
			}
			x += xm;
			updateRect();
			// move children - ie: blocks stacked on top of this Collider
			for (var i:int = 0; i < children.length; i++){
				children[i].moveX(xm, source);
			}
			awake = AWAKE_DELAY;
			return xm;
		}
		
		/* Move the collider vertically and push any Colliders it encounters in its way
		 * also moves any children of this collider
		 */
		public function moveY(ym:Number, source:Collider = null):Number{
			if(Math.abs(ym) < TOLERANCE) return 0;
			var r:Number;
			var c:Number;
			var test:Cast;
			var colliderMoved:Number = 0;
			var length:int = 2 + Math.abs(ym) * INV_SCALE;
			// vertical movement
			// moving down
			if(ym > 0){
				// test grid intervals
				for(c = rect.x; c < rect.x + rect.width + SCALE; c += scanStep){
					
					// cast for obstacles
					test = Cast.vert(c < rect.x + rect.width - 1 ? c : rect.x + rect.width - 1, rect.y + rect.height - 1, 1, length, g.blockMap, ignore, g);
					
					if(test){
						// moving against a collider
						if(test.collider && test.collider != this){
							if(test.collider.parent != this && parent != test.collider){
								if(rect.y + rect.height + ym >= test.block.y){
									
									test.collider.collisions |= Rect.UP;
									collisions |= Rect.DOWN;
									test.collider.upCollider = this;
									downCollider = test.collider;
									
									// move collider as much as it was bitten into
									if(!(test.collider.collisions & Rect.DOWN) && test.collider.weight < weight){
										colliderMoved = test.collider.moveY(ym - (test.block.y - (rect.y + rect.height)), source);
									}
									// if the collider has met a static wall, reduce possible movement
									// and adopt collision status
									if((test.collider.collisions & Rect.DOWN) || test.collider.weight >= weight){
										if(colliderMoved != 0){
											ym -= ym - colliderMoved;
										} else {
											ym = test.collider.rect.y - (rect.y + rect.height);
										}
									}
									
									// become a child of the collider - moving when it moves
									if(!platform){
										// add to platforms
										if (parent){
											parent.removeChild(this);
										}
										test.collider.addChild(this);
									}
								}
							}
						// moving against static walls
						} else if(test.block){
							if(rect.y + rect.height + ym >= test.block.y){
								ym = test.block.y - (rect.y + rect.height);
								collisions |= Rect.DOWN;
								// add to platforms
								
								if(parent != null){
									parent.removeChild(this);
								}
								parentBlock = test.block;
								parent = null;
							}
						}
					}
				}
			// moving up
			} else if(ym < 0){
				// test grid intervals
				for(c = rect.x; c < rect.x + rect.width + SCALE; c += scanStep){
					
					// cast for obstacles
					test = Cast.vert(c < rect.x + rect.width - 1 ? c : rect.x + rect.width - 1, rect.y, -1, length, g.blockMap, ignore, g);
					
					if(test){ // a map height condition goes well in here to catch falling off the map
						// moving against a collider
						if(test.collider && test.collider != this){
							if(test.collider.parent != this && parent != test.collider){
								if (rect.y + ym < test.block.y + test.block.height){
									
									test.collider.collisions |= Rect.DOWN;
									collisions |= Rect.UP;
									test.collider.downCollider = this;
									upCollider = test.collider;
									
									// move collider as much as it was bitten into
									if(!(test.collider.collisions & Rect.UP) && test.collider.weight < weight){
										colliderMoved = test.collider.moveY(ym - ((test.block.y + test.block.height) - rect.y), source);
									}
									// if the collider has met a static wall, reduce possible movement
									// and adopt collision status
									if((test.collider.collisions & Rect.UP) || test.collider.weight >= weight){
										if(colliderMoved != 0){
											ym -= ym - colliderMoved;
										} else {
											ym = (test.collider.rect.y + test.block.height) - rect.y;
										}
									}
									// object being pushed up adopts this Collider as it's new platform
									if(!test.collider.platform){
										if(test.collider.parent){
											test.collider.parent.removeChild(test.collider);
										}
										addChild(test.collider);
									}
								}
							}
						// moving against static walls
						} else if(test.block){
							if(rect.y + ym < test.block.y + test.block.height){
								ym = (test.block.y + test.block.height) - rect.y;
								collisions |= Rect.UP;
							}
						}
					}
				}
			}
			y += ym;
			updateRect();
			// move children - ie: blocks stacked on top of this Collider
			for(var i:int = 0; i < children.length; i++){
				children[i].moveY(ym, source);
			}
			awake = AWAKE_DELAY;
			
			// head bumping on ceiling when jumping
			if(!platform && (collisions & Rect.UP) && vy < 0) vy = 0;
			
			return ym;
		}
		
		/* add a child collider to this collider - it will move when this collider moves */
		public function addChild(collider:Collider):void{
			collider.parent = this;
			collider.parentBlock = block;
			collider.vy = 0;
			children.push(collider);
		}
		
		/* remove a child collider from children */
		public function removeChild(collider:Collider):void{
			collider.parent = null;
			collider.parentBlock = null;
			children.splice(children.lastIndexOf(collider), 1);
		}
		
		/* Check the floor is still beneath us */
		public function checkFloor():void{
			// test if we've walked beyond a block's width or if that block is breakable and has ceased to be
			if(parentBlock && (parentBlock.x > rect.x + rect.width - 1 || parentBlock.x + parentBlock.width - 1 < rect.x)){
				if(parent){
					parent.removeChild(this);
				}
				parentBlock = null;
				vy = 0;
			} else {
				collisions |= Rect.DOWN;
			}
		}
		
		/* Override to synchronise collider movement */
		public function move():void{
			// will put the collider to sleep if it doesn't move
			//if((vx > 0 ? vx : -vx) < TOLERANCE && (vy > 0 ? vy : -vy) < TOLERANCE && (awake)) awake--;
		}
		
		/* Get rid of children and parent - used to remove the collider from the game and clear current interaction */
		public function divorce():void{
			if(parent){
				parent.removeChild(this);
				vy = 0;
			}
			for (var i:int = 0; i < children.length; i++) {
				children[i].parent = null;
				children[i].parentBlock = null;
				children[i].vy = 0;
			}
			children.length = 0;
			parentBlock = null;
			awake = AWAKE_DELAY;
		}
		
		/* Draw debug diagram */
		public function draw(gfx:Graphics):void{
			if(awake == 0) return;
			rect.draw(gfx);
			if(parent != null){
				gfx.moveTo(rect.x + rect.width * 0.5, rect.y + rect.height * 0.5);
				gfx.lineTo(parent.rect.x + parent.rect.width * 0.5, parent.rect.y + parent.rect.height * 0.5);
			}
			if(collisions){
				if(collisions & Rect.UP){
					gfx.moveTo(rect.x + 5, rect.y + 5);
					gfx.lineTo(rect.x + rect.width - 5, rect.y + 5);
				}
				if(collisions & Rect.RIGHT){
					gfx.moveTo(rect.x + rect.width- 5, rect.y + 5);
					gfx.lineTo(rect.x + rect.width - 5, rect.y + rect.height - 5);
				}
				if(collisions & Rect.DOWN){
					gfx.moveTo(rect.x + 5, rect.y + rect.height - 5);
					gfx.lineTo(rect.x + rect.width - 5, rect.y + rect.height - 5);
				}
				if(collisions & Rect.LEFT){
					gfx.moveTo(rect.x + 5, rect.y + 5);
					gfx.lineTo(rect.x + 5, rect.y + rect.height - 5);
				}
			}
		}
		override public function toString():String {
			return "["+super.toString()+block.toString()+"]";
		}
	}
	
}