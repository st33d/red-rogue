package com.robotacid.engine {
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Collider;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	
	/**
	 * Background creatures that can be crushed by characters
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Critter extends Collider{
		
		public var dir:int;
		public var state:int;
		public var count:int;
		public var delay:int;
		public var patrolAreaSet:Boolean;
		public var patrolMin:Number;
		public var patrolMax:Number;
		public var speed:Number;
		public var topOfThreadY:Number;
		
		public static const RAT:int = 0;
		public static const SPIDER:int = 1;
		
		public static const PATROL:int = 0;
		public static const PAUSE:int = 1;
		
		public static const UP:int = Character.UP;
		public static const RIGHT:int = Character.RIGHT;
		public static const DOWN:int = Character.DOWN;
		public static const LEFT:int = Character.LEFT;
		
		public static const DAMPING_X:Number = Character.DAMPING_X;
		
		public function Critter(mc:DisplayObject, name:int, g:Game) {
			super(mc, mc.width, mc.height, g, true);
			this.name = name;
			if(name == RAT){
				delay = 12;
				speed = 3;
				state = PATROL;
				dir = Math.random() < 0.5 ? LEFT : RIGHT;
			} else if(name == SPIDER){
				delay = 15;
				speed = 1;
				state = PATROL;
				dir = Math.random() < 0.5 ? UP : DOWN;
				// spiders should always be placed on the ceiling
				topOfThreadY = y - SCALE * 0.5;
			}
			count = delay;
			block.type |= Block.HEAD;
			ignore |= Block.HEAD;
			callMain = true;
			vx = vy = 0;
		}
		
		/* movement is handled separately to keep all colliders synchronized */
		override public function move():void {
			if(name == RAT){
				vx *= DAMPING_X;
				moveX(vx, this);
			} else if(name == SPIDER){
				vy *= DAMPING_X;
				moveY(vy, this);
			}
			mapX = (rect.x + rect.width * 0.5) * INV_SCALE;
			mapY = (rect.y + rect.height * 0.5) * INV_SCALE;
			// will put the collider to sleep if it doesn't move
			if((vx > 0 ? vx : -vx) < TOLERANCE && (vy > 0 ? vy : -vy) < TOLERANCE && (awake)) awake--;
		}
		
		override public function main():void {
			if(state == PATROL){
				if(patrolAreaSet){
					patrol();
				} else (setPatrolArea(g.blockMap));
				if(count-- <= 0){
					count = delay + Math.random() * delay;
					state = PAUSE;
				}
				if(dir == RIGHT) vx += speed;
				else if(dir == LEFT) vx -= speed;
				else if(dir == DOWN) vy += speed;
				else if(dir == UP) vy -= speed;
			} else if(state == PAUSE){
				if(count-- <= 0){
					count = delay + Math.random() * delay;
					state = PATROL;
				}
			}
			if(name == RAT){
				// lazy way of dealing with pit traps
				if(!(g.blockMap[mapY + 1][mapX] & UP)) kill();
				if(leftCollider){
					if(Math.abs(leftCollider.vx) > TOLERANCE) kill();
					else if(dir == LEFT) dir = RIGHT;
				}
				if(rightCollider){
					if(Math.abs(rightCollider.vx) > TOLERANCE) kill();
					else if(dir == RIGHT) dir = LEFT;
				}
				if(upCollider || downCollider) kill();
			} else if(name == SPIDER){
				if(leftCollider || rightCollider || upCollider || downCollider) kill();
			}
			upCollider = rightCollider = downCollider = leftCollider = null;
			collisions = 0;
			updateMC();
			
			// will wake up the collider when moving
			if((vx > 0 ? vx : -vx) > TOLERANCE || (vy > 0 ? vy : -vy) > TOLERANCE) awake = AWAKE_DELAY;
		}
		
		public function kill():void{
			active = false;
			g.createDebrisRect(rect, 0, 5, Game.BLOOD);
		}
		
		/* This walks a critter left and right in their patrol area
		 * The patrol area must be defined with setPatrolArea before using this method
		 */
		public function patrol():void {
			if(name == RAT){
				if(x >= patrolMax || (collisions & RIGHT)) dir = LEFT;
				if(x <= patrolMin || (collisions & LEFT)) dir = RIGHT;
			} else if(name == SPIDER){
				if(y >= patrolMax || (collisions & DOWN)) dir = UP;
				if(y <= patrolMin || (collisions & UP)) dir = DOWN;
			}
		}
		
		/* Scan the floor about the character to establish an area to tread
		 * This saves us from having to check the floor every frame
		 */
		public function setPatrolArea(map:Vector.<Vector.<int>>):void{
			if(name == RAT) patrolMax = patrolMin = (mapX + 0.5) * SCALE;
			else if(name == SPIDER) patrolMax = patrolMin = (mapY + 0.5) * SCALE;
			if(name == RAT){
				while(
					patrolMin > SCALE * 0.5 &&
					!(map[mapY][((patrolMin - SCALE) * INV_SCALE) >> 0] & Block.WALL) &&
					(map[mapY + 1][((patrolMin - SCALE) * INV_SCALE) >> 0] & UP)
				){
					patrolMin -= SCALE;
				}
				while(
					patrolMax < (map[0].length - 0.5) * SCALE &&
					!(map[mapY][((patrolMax + SCALE) * INV_SCALE) >> 0] & Block.WALL) &&
					(map[mapY + 1][((patrolMax + SCALE) * INV_SCALE) >> 0] & UP)
				){
					patrolMax += SCALE;
				}
			} else if(name == SPIDER){
				patrolMin = y - SCALE * 0.5;
				while(
					patrolMax < (map.length - 0.5) * SCALE &&
					!(map[((patrolMax + SCALE) * INV_SCALE) >> 0][mapX] & Block.WALL) &&
					!(map[((patrolMax + SCALE) * INV_SCALE) >> 0][mapX] & UP)
				){
					patrolMax += SCALE;
				}
			}
			patrolAreaSet = true;
		}
		
		override public function updateRect():void{
			rect.x = x - width * 0.5;
			rect.y = y - height * 0.5;
			rect.width = width;
			rect.height = height;
		}
		
		public function updateMC():void{
			mc.x = (x + 0.1) >> 0;
			mc.y = ((y + height * 0.5) + 0.1) >> 0;
			if(name == RAT){
				if ((dir & LEFT) && mc.scaleX != -1) mc.scaleX = -1;
				else if ((dir & RIGHT) && mc.scaleX != 1) mc.scaleX = 1;
			} else if(name == SPIDER){
				if(dir == DOWN){
					(mc as MovieClip).gotoAndStop("down");
				} else {
					(mc as MovieClip).gotoAndStop("up");
				}
				(mc as MovieClip).graphics.clear();
				(mc as MovieClip).graphics.beginFill(0xFFFFFF, 0.5);
				(mc as MovieClip).graphics.drawRect(0, topOfThreadY - y, 1, y - topOfThreadY);
				(mc as MovieClip).graphics.endFill();
			}
		}
	}

}