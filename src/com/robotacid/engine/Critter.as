package com.robotacid.engine {
	import com.robotacid.dungeon.Content;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.phys.Collider;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	/**
	 * Background creatures that can be crushed by characters
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Critter extends ColliderEntity{
		
		private var dir:int;
		private var state:int;
		private var count:int;
		private var delay:int;
		private var patrolAreaSet:Boolean;
		private var patrolMin:Number;
		private var patrolMax:Number;
		private var speed:Number;
		private var topOfThreadY:Number;
		private var debrisType:int;
		private var surface:int;
		
		public static const SPIDER:int = 0;
		public static const RAT:int = 1;
		public static const BAT:int = 2;
		public static const COG:int = 3;
		
		public static const PATROL:int = 0;
		public static const PAUSE:int = 1;
		public static const DROP:int = 2;
		
		public static const UP:int = Collider.UP;
		public static const RIGHT:int = Collider.RIGHT;
		public static const DOWN:int = Collider.DOWN;
		public static const LEFT:int = Collider.LEFT;
		
		public static const DAMPING_X:Number = Character.DAMPING_X;
		
		public function Critter(gfx:DisplayObject, x:Number, y:Number, name:int){
			super(gfx);
			this.name = name;
			if(name == RAT){
				delay = 12;
				speed = 3;
				state = PATROL;
				dir = game.random.value() < 0.5 ? LEFT : RIGHT;
				createCollider(x, y, Collider.HEAD | Collider.SOLID, Collider.HEAD, Collider.FALL);
				collider.stackCallback = hitFloor;
				debrisType = Renderer.BLOOD;
				
			} else if(name == SPIDER){
				delay = 15;
				speed = 1;
				state = PATROL;
				dir = game.random.value() < 0.5 ? UP : DOWN;
				// spiders should always be placed on the ceiling
				topOfThreadY = y - SCALE * 0.5;
				createCollider(x, y, Collider.HEAD | Collider.SOLID, Collider.HEAD, Collider.HOVER);
				collider.dampingY = collider.dampingX;
				debrisType = Renderer.BLOOD;
				
			} else if(name == BAT){
				delay = 30;
				speed = 1;
				state = PATROL;
				patrolAreaSet = true;
				dir = game.random.value() < 0.5 ? LEFT : RIGHT;
				createCollider(x, y, Collider.HEAD | Collider.SOLID, Collider.HEAD, Collider.FALL, false);
				(gfx as MovieClip).gotoAndPlay("fly");
				debrisType = Renderer.BLOOD;
				
			} else if(name == COG){
				delay = 60;
				speed = 1;
				state = PATROL;
				mapX = x * Game.INV_SCALE;
				mapY = y * Game.INV_SCALE;
				// get a surface to mount on
				var surfaces:Array = [];
				if(game.world.map[mapY - 1][mapX] & DOWN) surfaces.push(DOWN);
				if(game.world.map[mapY + 1][mapX] & UP) surfaces.push(UP);
				if(game.world.map[mapY][mapX - 1] & RIGHT) surfaces.push(RIGHT);
				if(game.world.map[mapY][mapX + 1] & LEFT) surfaces.push(LEFT);
				surface = surfaces[game.random.rangeInt(surfaces.length)];
				if(surface & (UP | DOWN)){
					if(surface == DOWN) y -= Game.SCALE * 0.5 - 2;
					else if(surface == UP) y += Game.SCALE * 0.5 - 2;
					dir = game.random.value() < 0.5 ? LEFT : RIGHT;
				} else if(surface & (LEFT | RIGHT)){
					if(surface == RIGHT) x -= Game.SCALE * 0.5 - 2;
					else if(surface == LEFT) x += Game.SCALE * 0.5 - 2;
					dir = game.random.value() < 0.5 ? UP : DOWN;
				}
				// a cogs collider exists at its hub
				// so we have to create the collider manually
				collider = new Collider(x - 2, y - 2, 4, 4, Game.SCALE, Collider.HEAD | Collider.SOLID, Collider.HEAD, Collider.HOVER);
				collider.userData = this;
				collider.dampingY = collider.dampingX;
				debrisType = Renderer.STONE;
				
			}
			count = delay;
			callMain = true;
		}
		
		private function hitFloor():void{
			mapX = (collider.x + collider.width * 0.5) * INV_SCALE;
			mapY = (collider.y + collider.height * 0.5) * INV_SCALE;
			setPatrolArea(game.world.map);
		}
		
		override public function main():void {
			
			// offscreen check
			if(!game.mapTileManager.intersects(collider)){
				remove();
				return;
			}
			
			mapX = (collider.x + collider.width * 0.5) * INV_SCALE;
			mapY = (collider.y + collider.height * 0.5) * INV_SCALE;
			
			if(state == PATROL){
				if(patrolAreaSet){
					patrol();
				} else (setPatrolArea(game.world.map));
				if(count-- <= 0){
					if(name == BAT && !(collider.pressure & UP)){
						dir = UP;
						
					} else {
						count = delay + game.random.range(delay);
						state = PAUSE;
						if(name == BAT){
							(gfx as MovieClip).gotoAndStop("idle");
							collider.state = Collider.HOVER;
						}
					}
				}
				if(dir) collider.awake = Collider.AWAKE_DELAY;
				if(dir & RIGHT) collider.vx += speed;
				if(dir & LEFT) collider.vx -= speed;
				if(dir & DOWN) collider.vy += speed;
				if(dir & UP) collider.vy -= speed;
				
			} else if(state == PAUSE){
				if(count-- <= 0){
					count = delay + game.random.range(delay);
					state = PATROL;
					if(name == BAT){
						(gfx as MovieClip).gotoAndPlay("fly");
						collider.state = Collider.FALL;
						dir = game.random.value() < 0.5 ? LEFT : RIGHT;
					}
				}
				
			} else if(state == DROP){
				collider.vy += speed * 2;
				if(collider.pressure & DOWN){
					patrolAreaSet = false;
					surface = UP;
					state = PATROL;
				}
			}
			// check cogs are still mounted (they may have been attached to chaos walls)
			if(name == COG){
				if(
					(surface == UP && !(game.world.map[mapY + 1][mapX] & UP)) ||
					(surface == RIGHT && !(game.world.map[mapY][mapX - 1] & RIGHT)) ||
					(surface == DOWN && !(game.world.map[mapY - 1][mapX] & DOWN)) ||
					(surface == LEFT && !(game.world.map[mapY][mapX + 1] & LEFT))
				){
					state = DROP;
					surface = 0;
				}
			}
			var contact:Collider = collider.getContact();
			if(contact){
				if(name == RAT){
					if(Math.abs(contact.vx) > Collider.MOVEMENT_TOLERANCE || collider.upContact || collider.downContact) kill();
				} else {
					kill();
				}
			}
			 
		}
		
		public function kill():void{
			active = false;
			collider.world.removeCollider(collider);
			renderer.createDebrisRect(collider, 0, 10, debrisType);
			if(name == COG){
				renderer.createDebrisRect(new Rectangle(collider.x - 4, collider.y - 4, 12, 12), 0, 20, debrisType);
			}
		}
		
		/* This walks a critter left and right in their patrol area
		 * The patrol area must be defined with setPatrolArea before using this method
		 */
		public function patrol():void {
			if(name == RAT){
				if(collider.x + collider.width >= patrolMax || (collider.pressure & RIGHT)) dir = LEFT;
				if(collider.x <= patrolMin || (collider.pressure & LEFT)) dir = RIGHT;
				
			} else if(name == SPIDER){
				if(collider.y + collider.height >= patrolMax || (collider.pressure & DOWN)) dir = UP;
				if(collider.y <= patrolMin || (collider.pressure & UP)) dir = DOWN;
				
			} else if(name == BAT){
				if(collider.x + collider.width >= patrolMax || (collider.pressure & RIGHT)) dir = LEFT;
				if(collider.x <= patrolMin || (collider.pressure & LEFT)) dir = RIGHT;
				//if((gfx as MovieClip).currentFrame > (gfx as MovieClip).totalFrames * 0.2) dir |= UP;
				if(game.random.value() > 0.2) dir |= UP;
				else dir &= ~UP;
				
			} else if(name == COG){
				if(surface & (UP | DOWN)){
					if(collider.x + collider.width >= patrolMax || (collider.pressure & RIGHT)) dir = LEFT;
					if(collider.x <= patrolMin || (collider.pressure & LEFT)) dir = RIGHT;
				} else if(surface & (LEFT | RIGHT)){
					if(collider.y + collider.height >= patrolMax || (collider.pressure & DOWN)) dir = UP;
					if(collider.y <= patrolMin || (collider.pressure & UP)) dir = DOWN;
				}
				
			}
		}
		
		/* Scan the floor about the character to establish an area to tread
		 * This saves us from having to check the floor every frame
		 */
		public function setPatrolArea(map:Vector.<Vector.<int>>):void{
			if(name == RAT) patrolMax = patrolMin = (mapX + 0.5) * SCALE;
			else if(name == SPIDER) patrolMax = patrolMin = (mapY + 0.5) * SCALE;
			else if(name == COG){
				if(surface & (UP | DOWN)) patrolMax = patrolMin = (mapX + 0.5) * SCALE;
				else if(surface & (RIGHT | LEFT)) patrolMax = patrolMin = (mapY + 0.5) * SCALE;
			}
			if(name == RAT){
				while(
					patrolMin > SCALE * 0.5 &&
					!(map[mapY][((patrolMin - SCALE) * INV_SCALE) >> 0] & Collider.WALL) &&
					(map[mapY + 1][((patrolMin - SCALE) * INV_SCALE) >> 0] & UP)
				){
					patrolMin -= SCALE;
				}
				while(
					patrolMax < (map[0].length - 0.5) * SCALE &&
					!(map[mapY][((patrolMax + SCALE) * INV_SCALE) >> 0] & Collider.WALL) &&
					(map[mapY + 1][((patrolMax + SCALE) * INV_SCALE) >> 0] & UP)
				){
					patrolMax += SCALE;
				}
				
			} else if(name == SPIDER){
				patrolMin = collider.y - SCALE * 0.5;
				while(
					patrolMax < (map.length - 0.5) * SCALE &&
					!(map[((patrolMax + SCALE) * INV_SCALE) >> 0][mapX] & Collider.WALL) &&
					!(map[((patrolMax + SCALE) * INV_SCALE) >> 0][mapX] & UP)
				){
					patrolMax += SCALE;
				}
				
			} else if(name == COG){
				if(surface & (UP | DOWN)){
					while(
						patrolMin > SCALE * 0.5 &&
						!(map[mapY][((patrolMin - SCALE) * INV_SCALE) >> 0] & Collider.WALL) &&
						(
							(surface == UP && (map[mapY + 1][((patrolMin - SCALE) * INV_SCALE) >> 0] & surface)) ||
							(surface == DOWN && (map[mapY - 1][((patrolMin - SCALE) * INV_SCALE) >> 0] & surface))
						)
					){
						patrolMin -= SCALE;
					}
					while(
						patrolMax < (map[0].length - 0.5) * SCALE &&
						!(map[mapY][((patrolMax + SCALE) * INV_SCALE) >> 0] & Collider.WALL) &&
						(
							(surface == UP && (map[mapY + 1][((patrolMax + SCALE) * INV_SCALE) >> 0] & surface)) ||
							(surface == DOWN && (map[mapY - 1][((patrolMax + SCALE) * INV_SCALE) >> 0] & surface))
						)
					){
						patrolMax += SCALE;
					}
				} else if(surface & (RIGHT | LEFT)){
					while(
						patrolMin > SCALE * 0.5 &&
						!(map[((patrolMin - SCALE) * INV_SCALE) >> 0][mapX] & Collider.WALL) &&
						(
							(surface == LEFT && (map[((patrolMin - SCALE) * INV_SCALE) >> 0][mapX + 1] & surface)) ||
							(surface == RIGHT && (map[((patrolMin - SCALE) * INV_SCALE) >> 0][mapX - 1] & surface))
						)
					){
						patrolMin -= SCALE;
					}
					while(
						patrolMax < (map[0].length - 0.5) * SCALE &&
						!(map[((patrolMax + SCALE) * INV_SCALE) >> 0][mapX] & Collider.WALL) &&
						(
							(surface == LEFT && (map[((patrolMax + SCALE) * INV_SCALE) >> 0][mapX + 1] & surface)) ||
							(surface == RIGHT && (map[((patrolMax + SCALE) * INV_SCALE) >> 0][mapX - 1] & surface))
						)
					){
						patrolMax += SCALE;
					}
				}
				
			}
			patrolAreaSet = true;
		}
		
		override public function render():void{
			
			var mc:MovieClip = gfx as MovieClip;
			
			if(name == RAT){
				gfx.x = (collider.x + collider.width * 0.5) >> 0;
				gfx.y = (collider.y + collider.height + 0.5) >> 0;
				if ((dir & LEFT) && gfx.scaleX != 1) gfx.scaleX = 1;
				else if ((dir & RIGHT) && gfx.scaleX != -1) gfx.scaleX = -1;
				
			} else if(name == SPIDER){
				gfx.x = (collider.x + collider.width * 0.5) >> 0;
				gfx.y = (collider.y + collider.height * 0.5) >> 0;
				if(dir == DOWN){
					mc.gotoAndStop("down");
				} else {
					mc.gotoAndStop("up");
				}
				mc.graphics.clear();
				mc.graphics.beginFill(0xFFFFFF, 0.5);
				mc.graphics.drawRect(0, topOfThreadY - collider.y, 1, collider.y - topOfThreadY);
				mc.graphics.endFill();
				
			} else if(name == BAT){
				gfx.x = (collider.x + collider.width * 0.5) >> 0;
				gfx.y = (collider.y + 0.5) >> 0;
				
			} else if(name == COG){
					gfx.x = (collider.x + collider.width * 0.5 + 0.5) >> 0;
					gfx.y = (collider.y + collider.width * 0.5 + 0.5) >> 0;
				if(surface == DOWN) gfx.y -= 4;
				else if(surface == UP) gfx.y += 4;
				else if(surface == RIGHT) gfx.x -= 4;
				else if(surface == LEFT) gfx.x += 4;
				
			}
			super.render();
		}
	}

}