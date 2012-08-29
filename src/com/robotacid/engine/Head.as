package com.robotacid.engine {
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.phys.Collider;
	import flash.display.MovieClip;
	
	/**
	 * A decapitated head that bounces along spewing blood when
	 * kicked by the player and inflicts damage upon
	 * monsters
	 *
	 * :D
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Head extends ColliderEntity{
		
		public var damage:Number;
		
		private var debrisType:int;
		private var bloodCount:int;
		private var uniqueNameStr:String;
		private var theBalrog:Boolean;
		
		public static const GRAVITY:Number = 0.8;
		public static const DAMPING_Y:Number = 0.99;
		public static const DAMPING_X:Number = 0.9;
		public static const INIT_V:Number = 6;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		public static const BLOOD_DELAY:int = 20;
		public static const FACE_DROP_CHANCE:Number = 0.25;
		
		public function Head(victim:Character, damage:Number) {
			gfx = game.library.getCharacterHeadGfx(victim.name);
			super(gfx, true);
			name = victim.name;
			debrisType = victim.debrisType;
			if(victim.uniqueNameStr){
				uniqueNameStr = victim.uniqueNameStr + (
					(victim.uniqueNameStr.charAt(victim.uniqueNameStr.length - 1) == "s") ? "' " : "'s "
				) + " face";
			}
			theBalrog = victim is Balrog;
			createCollider(victim.gfx.x, victim.collider.y + gfx.height, Collider.HEAD | Collider.SOLID, Collider.CORPSE | Collider.ITEM);
			game.world.restoreCollider(collider);
			collider.resolveMapInsertion();
			if(victim.dir & RIGHT){
				collider.vx -= INIT_V;
			} else if(victim.dir & LEFT){
				collider.vx += INIT_V;
			}
			collider.vy -= INIT_V;
			collider.dampingX = DAMPING_X;
			collider.dampingY = DAMPING_Y;
			collider.gravity = GRAVITY;
			collider.crushCallback = kill;
			callMain = true;
			bloodCount = BLOOD_DELAY;
			this.damage = damage;
		}
		
		override public function main():void{
			
			mapX = (collider.x + collider.width * 0.5) * INV_SCALE;
			mapY = (collider.y + collider.height * 0.5) * INV_SCALE;
			
			if(collider.leftContact && collider.leftContact.properties & Collider.CHARACTER) punt(collider.leftContact);
			else if(collider.rightContact && collider.rightContact.properties & Collider.CHARACTER) punt(collider.rightContact);
			if(Math.abs(collider.vx) > Collider.MOVEMENT_TOLERANCE || Math.abs(collider.vy) > Collider.MOVEMENT_TOLERANCE){
				if(bloodCount > 0){
					bloodCount--;
					var blit:BlitRect, print:BlitRect;
					if(game.random.coinFlip()){
						blit = renderer.smallDebrisBlits[debrisType];
						print = renderer.smallFadeBlits[debrisType];
					} else {
						blit = renderer.bigDebrisBlits[debrisType];
						print = renderer.bigFadeBlits[debrisType];
					}
					renderer.addDebris(collider.x + collider.width * 0.5, collider.y + collider.height, blit, -1 + collider.vx + game.random.value(), -game.random.value(), print, true);
				}
			}
			soccerCheck();
			// crush the head when pressed from both sides
			if((collider.pressure & (RIGHT | LEFT)) == (LEFT | RIGHT) || (collider.pressure & (UP | DOWN)) == (UP | DOWN)) kill();
		}
		
		/* Apply damage to monsters that collide with the Head object */
		public function soccerCheck():void{
			if(collider.vy < -Collider.MOVEMENT_TOLERANCE && collider.upContact && collider.upContact.properties & Collider.MONSTER) (collider.upContact.userData as Character).applyDamage(damage, nameToString())
			else if(collider.vx > Collider.MOVEMENT_TOLERANCE && collider.rightContact && collider.rightContact.properties & Collider.MONSTER) (collider.rightContact.userData as Character).applyDamage(damage, nameToString())
			else if(collider.vy > Collider.MOVEMENT_TOLERANCE && collider.leftContact && collider.leftContact.properties & Collider.MONSTER) (collider.leftContact.userData as Character).applyDamage(damage, nameToString())
			else if(collider.vx < -Collider.MOVEMENT_TOLERANCE && collider.downContact && collider.downContact.properties & Collider.MONSTER) (collider.downContact.userData as Character).applyDamage(damage, nameToString())
		}
		
		public function punt(kicker:Collider):void{
			bloodCount = BLOOD_DELAY;
			collider.vy -= Math.abs(kicker.vx * 0.5);
			collider.vx += kicker.vx * 0.5;
		}
		
		public function kill():void{
			if(name == Character.BALROG || game.random.value() <= FACE_DROP_CHANCE){
				// create face armour and drop to the map
				var face:Face = new Face(game.library.getCharacterHeadGfx(name), name);
				face.uniqueNameStr = uniqueNameStr
				face.theBalrog = theBalrog;
				face.dropToMap(mapX, mapY);
				game.console.print("a " + Character.stats["names"][name] + " face is created");
			}
			renderer.createDebrisExplosion(collider, 4, 10, debrisType);
			renderer.createDebrisRect(collider, 0, 10, debrisType);
			game.world.removeCollider(collider);
			active = false;
		}
		
		/* Handles refreshing animation and the position on the canvas */
		override public function render():void{
			gfx.x = (collider.x + collider.width * 0.5) >> 0;
			gfx.y = Math.round(collider.y + collider.height);
			if(gfx.alpha < 1){
				gfx.alpha += 0.1;
			}
			super.render();
		}
		
		override public function nameToString():String {
			return "soccer";
		}
	}
	
}