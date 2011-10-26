package com.robotacid.engine {
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Missile;
	import com.robotacid.phys.Cast;
	import com.robotacid.phys.Collider;
	import flash.display.DisplayObject;
	
	/**
	 * Easter egg effect of runes: They stick to the mouse pointer
	 * when they collide in the air with it
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class MouseMissile extends Missile{
		
		public function MouseMissile(mc:DisplayObject, x:Number, y:Number, type:int, ignore:int = 0, effect:Effect = null) {
			super(mc, x, y, type, null, 0, 0, speed, ignore, effect);
		}
		
		override public function main():void {
			mapX = (collider.x + collider.width * 0.5) * Game.INV_SCALE;
			mapY = (collider.y + collider.height * 0.5) * Game.INV_SCALE;
			collider.vx = renderer.canvas.mouseX - collider.x;
			collider.vy = renderer.canvas.mouseY - collider.y;
			
			if(collider.pressure){
				var contact:Collider = collider.getContact();
				target = contact.userData as Character;
				if(target) hitCharacter(target);
				else kill();
			}
		}
		
	}

}