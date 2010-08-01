package com.robotacid.engine {
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Collider;
	import com.robotacid.util.clips.localToLocal;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	/**
	 * Counterpart to the decaptitated head is the corpse that gushes blood out
	 * of its neck
	 *
	 * :D
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Corpse extends Collider{
		
		public var state:int;
		public var looking:int;
		public var dir:int;
		public var speed:Number;
		public var moving:Boolean;
		public var moveFrame:int;
		public var moveCount:int;
		
		public var boomCount:int;
		
		public static const WALKING:int = Character.WALKING;
		public static const FALLING:int = Character.FALLING;
		
		public static const UP:int = Character.UP;
		public static const RIGHT:int = Character.RIGHT;
		public static const DOWN:int = Character.DOWN;
		public static const LEFT:int = Character.LEFT;
		
		public static const MOVE_DELAY:int = Character.MOVE_DELAY;
		public static const DAMPING_X:Number = Character.DAMPING_X;
		public static const DAMPING_Y:Number = Character.DAMPING_Y;
		public static const GRAVITY:Number = Character.GRAVITY;
		
		public static const BOOM_DELAY:int = 90;
		
		public static var point:Point = new Point();
		
		public function Corpse(victim:Character, g:Game) {
			boomCount = BOOM_DELAY;
			state = WALKING;
			looking = victim.looking;
			speed = victim.speed;
			moving = victim.moving;
			dir = victim.looking;
			
			var mcClass:Class = (Object(victim.mc).constructor as Class);
			mc = new mcClass();
			(mc as MovieClip).gotoAndStop("corpse_1");
			mc.x = victim.mc.x;
			mc.y = victim.mc.y;
			victim.holder.addChild(mc);
			vx = vy = 0;
			
			super(mc, victim.width, victim.height, g, true);
			x = victim.x;
			y = victim.y;
			updateRect();
			callMain = true;
			weight = 0;
			
			inflictsCrush = false;
			crushable = false;
			ignore |= Block.CHARACTER | Block.CORPSE | Block.HEAD;
			block.type |= Block.CORPSE;
		}
		
		/* movement is handled separately to keep all colliders synchronized */
		override public function move():void {
			vx *= DAMPING_X;
			moveX(vx, this);
			if(state == FALLING || state == WALKING){
				if (parentBlock){
					checkFloor();
				}
				if(!parentBlock){
					vy = DAMPING_Y * vy + GRAVITY;
					moveY(vy, this);
				}
				if(!parentBlock){
					state = FALLING;
				} else {
					state = WALKING;
				}
			}
			// pace movement
			if(state == WALKING){
				if(!moving) moveCount = 0;
				else {
					moveCount = (moveCount + 1) % MOVE_DELAY;
					// flip between climb frames as we move
					if(moveCount == 0) moveFrame ^= 1;
				}
			}
			
			mapX = (rect.x + rect.width * 0.5) * INV_SCALE;
			mapY = (rect.y + rect.height * 0.5) * INV_SCALE;
			
			
			// will put the collider to sleep if it doesn't move
			if((vx > 0 ? vx : -vx) < TOLERANCE && (vy > 0 ? vy : -vy) < TOLERANCE && (awake)) awake--;
		}
		
		override public function main():void{
			if(parentBlock != null) collisions |= Block.DOWN;
			// react to direction state
			if(state == WALKING) moving = Boolean(dir & (LEFT | RIGHT));
			// moving left or right
			if(state == WALKING || state == FALLING){
				if(dir & RIGHT) vx += speed;
				else if(dir & LEFT) vx -= speed;
			}
			updateAnimState(mc as MovieClip);
			updateMC();
			
			if((collisions & (LEFT | RIGHT)) || (boomCount--) <= 0) kill();
			
			upCollider = rightCollider = downCollider = leftCollider = null;
			collisions = 0;
		}
		
		public function kill():void{
			active = false;
			g.createDebrisRect(rect, 0, 20, Game.BLOOD);
		}
		public function updateAnimState(mc:MovieClip):void {
			if ((looking & LEFT) && mc.scaleX != -1) mc.scaleX = -1;
			else if ((looking & RIGHT) && mc.scaleX != 1) mc.scaleX = 1;
			
			
			if(state == WALKING && moving){
				if(moveFrame){
					if(mc.currentLabel != "corpse_1") mc.gotoAndStop("corpse_1");
				} else {
					if(mc.currentLabel != "corpse_0") mc.gotoAndStop("corpse_0");
				}
			} else if(state == WALKING && !moving){
				if(mc.currentLabel != "corpse_1") mc.gotoAndStop("corpse_1");
			} else if(state == FALLING){
				if(mc.currentLabel != "corpse_0") mc.gotoAndStop("corpse_0");
			}
			
			// and spew loads of blood
			var blit:BlitRect, print:BlitRect;
			
			//Game.debug.drawCircle(point.x, point.y, 3);
			
			point = localToLocal(point, mc.neck, g.canvas);
			
			for(var i:int = 0; i < 5; i++){
				if(Math.random() > 0.5){
					blit = g.smallDebrisBrs[Game.BLOOD];
					print = g.smallFadeFbrs[Game.BLOOD];
				} else {
					blit = g.bigDebrisBrs[Game.BLOOD];
					print = g.bigFadeFbrs[Game.BLOOD];
				}
				g.addDebris(point.x, point.y + 5, blit, -1 + Math.random() * 2, -5 -Math.random() * 5, print, true);
			}
		}
		/* Update collision Rect / Block around character */
		override public function updateRect():void{
			rect.x = x - width * 0.5;
			rect.y = y - height * 0.5;
			rect.width = width;
			rect.height = height;
		}
		/* Handles refreshing animation and the position the canvas */
		public function updateMC():void{
			mc.x = (x + 0.1) >> 0;
			mc.y = ((y + height * 0.5) + 0.1) >> 0;
			if(mc.alpha < 1){
				mc.alpha += 0.1;
			}
		}
		
	}

}