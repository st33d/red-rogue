package com.robotacid.engine {
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.phys.Collider;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	/**
	 * Counterpart to the decaptitated head is the corpse that gushes blood out
	 * of its neck
	 *
	 * :D
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Corpse extends ColliderEntity{
		
		private var state:int;
		private var looking:int;
		private var dir:int;
		private var speed:Number;
		private var moving:Boolean;
		private var moveFrame:int;
		private var moveCount:int;
		private var debrisType:int;
		private var boomCount:int;
		private var theBalrog:Boolean;
		
		public static const WALKING:int = Character.WALKING;
		
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
		
		public function Corpse(victim:Character) {
			boomCount = BOOM_DELAY;
			state = WALKING;
			looking = victim.looking;
			speed = victim.speed;
			moving = victim.moving;
			dir = victim.looking;
			theBalrog = victim is Balrog;
			if(!(dir & (LEFT | RIGHT))){
				dir = looking = game.random.coinFlip() ? LEFT : RIGHT;
			}
			debrisType = victim.debrisType;
			var mcClass:Class = (Object(victim.gfx).constructor as Class);
			gfx = new mcClass();
			super(gfx, true);
			createCollider(victim.gfx.x, victim.gfx.y, Collider.CORPSE | Collider.SOLID, Collider.CORPSE | Collider.ITEM);
			game.world.restoreCollider(collider);
			callMain = true;
		}
		
		override public function main():void{
			
			mapX = (collider.x + collider.width * 0.5) * INV_SCALE;
			mapY = (collider.y + collider.height * 0.5) * INV_SCALE;
			
			// react to direction state
			if(state == WALKING) moving = Boolean(dir & (LEFT | RIGHT));
			// moving left or right
			if(state == WALKING){
				if(dir & RIGHT) collider.vx += speed;
				else if(dir & LEFT) collider.vx -= speed;
			}
			
			if(theBalrog){
				if(collider.pressure & (LEFT | RIGHT)){
					dir = looking = (collider.pressure & LEFT) ? RIGHT : LEFT;
				}
				// check to see if the we've be resurrected
				if(game.balrog){
					kill();
				}
			} else {
				if((collider.pressure & (LEFT | RIGHT)) || (boomCount--) <= 0) kill();
			}
		}
		
		public function kill():void{
			renderer.createDebrisExplosion(collider, 10, 20, debrisType);
			renderer.createDebrisRect(collider, 0, 20, debrisType);
			game.world.removeCollider(collider);
			active = false;
		}
		
		/* Handles refreshing animation and the position the canvas */
		override public function render():void{
			
			var mc:MovieClip = gfx as MovieClip;
			
			if ((looking & LEFT) && mc.scaleX != -1) mc.scaleX = -1;
			else if ((looking & RIGHT) && mc.scaleX != 1) mc.scaleX = 1;
			
			
			// pace movement
			if(state == WALKING){
				if(!moving) moveCount = 0;
				else {
					moveCount = (moveCount + 1) % MOVE_DELAY;
					// flip between climb frames as we move
					if(moveCount == 0) moveFrame ^= 1;
				}
			}
			if(state == WALKING){
				if(collider.state == Collider.STACK){
					if(moving){
						if(moveFrame){
							if(mc.currentLabel != "corpse1") mc.gotoAndStop("corpse1");
						} else {
							if(mc.currentLabel != "corpse0") mc.gotoAndStop("corpse0");
						}
					} else {
						if(mc.currentLabel != "corpse0"){
							mc.gotoAndStop("corpse0");
						}
					}
				} else if(collider.state == Collider.FALL){
					if(mc.currentLabel != "corpse0"){
						mc.gotoAndStop("corpse0");
					}
				}
				if(moveFrame){
					if(mc.currentLabel != "corpse1") mc.gotoAndStop("corpse1");
				} else {
					if(mc.currentLabel != "corpse0") mc.gotoAndStop("corpse0");
				}
			}
			
			// and spew loads of blood
			var blit:BlitRect, print:BlitRect;
			
			//Game.debug.drawCircle(point.x, point.y, 3);
			
			point = new Point(mc.x + mc.blood.x, mc.y + mc.blood.y);
			
			for(var i:int = 0; i < 8; i++){
				if(game.random.value() < 0.8){
					blit = renderer.smallDebrisBlits[debrisType];
					print = renderer.smallFadeBlits[debrisType];
				} else {
					blit = renderer.bigDebrisBlits[debrisType];
					print = renderer.bigFadeBlits[debrisType];
				}
				renderer.addDebris(point.x + collider.vx * collider.dampingX, point.y + 5, blit, -1 + game.random.range(2), -5 -game.random.range(5), print, true);
			}
			gfx.x = (collider.x + collider.width * 0.5) >> 0;
			gfx.y = Math.round(collider.y + collider.height);
			if(gfx.alpha < 1){
				gfx.alpha += 0.1;
			}
			super.render();
		}
		
	}

}