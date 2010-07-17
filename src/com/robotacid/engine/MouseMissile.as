package com.robotacid.engine {
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Missile;
	import com.robotacid.phys.Cast;
	import flash.display.DisplayObject;
	
	/**
	 * Easter egg effect of runes: They stick to the mouse pointer
	 * when they collide in the air with it
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class MouseMissile extends Missile{
		
		public function MouseMissile(mc:DisplayObject, name:int, g:Game, ignore:int = 0, effect:Effect = null) {
			super(mc, name, null, 0, 0, speed, g, ignore, effect);
			
			g.lightMap.setLight(this, 3, 112);
			
		}
		
		override public function move():void {
			
			var vx:Number = g.canvas.mouseX - x;
			var vy:Number = g.canvas.mouseY - y;
			speed = Math.sqrt(vx * vx + vy * vy);
			if(speed){
				dx = vx / speed;
				dy = vy / speed;
			
				cast = Cast.ray(x, y, dx, dy, g.blockMap, ignore, g);
				
				if(cast && cast.distance < speed){
					if(cast.collider){
						if(cast.collider is Character) hitCharacter(cast.collider as Character);
					}
					// resolve
					x = x + dx * cast.distance;
					y = y + dx * cast.distance;
					kill();
				} else {
					x += vx;
					y += vy;
				}
			}
			// brute force check the colliders to see if one has walked into this
			else {
				for(var i:int = 0; i < g.colliders.length; i++){
					if(g.colliders[i].rect.contains(x, y)){
						if(g.colliders[i] is Character) hitCharacter(g.colliders[i] as Character);
						kill();
						break;
					}
				}
			}
			mapX = x * Game.INV_SCALE;
			mapY = y * Game.INV_SCALE;
		}
		
	}

}