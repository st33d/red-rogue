package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.gfx.BlitSprite;
	import com.robotacid.phys.Cast;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	/**
	* Basic missile class - only moves in straight lines for now
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class Missile extends ColliderEntity{
		
		public var type:int;
		public var dx:Number;
		public var dy:Number;
		public var speed:Number;
		public var effect:Effect;
		public var sender:Character;
		public var item:Item;
		public var clipRect:Rectangle;
		
		protected static var target:Character;
		
		// missile names
		public static const ITEM:int = 1;
		public static const RUNE:int = 2;
		public static const DART:int = 3;
		
		public function Missile(mc:DisplayObject, x:Number, y:Number, type:int, sender:Character, dx:Number, dy:Number, speed:Number, ignore:int = 0, effect:Effect = null, item:Item = null, clipRect:Rectangle = null) {
			super(mc, true);
			this.type = type;
			this.sender = sender;
			this.dx = dx;
			this.dy = dy;
			this.speed = speed;
			this.effect = effect;
			this.item = item;
			this.clipRect = clipRect;
			callMain = true;
			
			createCollider(x, y, Collider.SOLID | Collider.MISSILE, ignore, Collider.HOVER, false);
			collider.dampingX = 1;
			collider.dampingY = 1;
			g.world.restoreCollider(collider);
			
			// runes glow when they are converted to missiles
			if(type == RUNE){
				g.lightMap.setLight(this, 3, 112);
			}
		}
		
		override public function main():void {
			mapX = (collider.x + collider.width * 0.5) * Game.INV_SCALE;
			mapY = (collider.y + collider.height * 0.5) * Game.INV_SCALE;
			collider.vx = speed * dx;
			collider.vy = speed * dy;
			collider.awake = Collider.AWAKE_DELAY;
			if(collider.pressure){
				var contact:Collider = collider.getContact();
				if(contact){
					target = contact.userData as Character;
					if(target){
						if(type == ITEM){
							var hitResult:int = sender.hit(target, Item.MISSILE | Item.THROWN);
							if(hitResult){
								hitCharacter(target, hitResult);
							} else {
								// pass through next simulation frame
								collider.ignoreProperties |= Collider.SOLID;
							}
						} else {
							hitCharacter(target);
						}
					}
				} else {
					kill();
				}
			} else {
				// check runes for proximity to the mouse for conversion to MouseMissile
				if(type == RUNE){
					var mouseVx:Number = renderer.canvas.mouseX - collider.x;
					var mouseVy:Number = renderer.canvas.mouseY - collider.y;
					if(mouseVx * mouseVx + mouseVy * mouseVy <= speed){
						var mouseMissile:MouseMissile = new MouseMissile(gfx, collider.x, collider.y, type, collider.ignoreProperties, effect);
						collider.world.removeCollider(collider);
						active = false;
						return;
					}
				}
				// repair contact filter from failed hits
				collider.ignoreProperties &= ~(Collider.SOLID);
			}
		}
		
		public function hitCharacter(character:Character, hitResult:int = 0):void{
			if(type == ITEM){
				// need to make sure that monsters hit by arrows fly into battle mode
				if(character is Monster && (character as Monster).brain.state == Brain.PATROL){
					(character as Monster).brain.state == Brain.ATTACK;
					(character as Monster).brain.target = sender;
				}
				// would help if the player can see what they're doing to the target
				if(sender is Player) sender.victim = character;
				if(hitResult & Character.CRITICAL) renderer.shake(0, 5);
				if(item.effects) character.applyWeaponEffects(item);
				var thrownWeapon:Boolean = Boolean(item.range & Item.THROWN);
				// knockback
				var enduranceDamping:Number = 1.0 - (target.endurance + (target.armour ? target.armour.endurance : 0));
				if(enduranceDamping < 0) enduranceDamping = 0;
				var hitKnockback:Number = (item.knockback + (thrownWeapon ? sender.knockback : 0)) * enduranceDamping;
				if(dx < 0) hitKnockback = -hitKnockback;
				// stun
				if(hitResult & Character.STUN){
					var hitStun:Number = (item.stun + (thrownWeapon ? sender.stun : 0)) * enduranceDamping;
					if(hitStun) character.applyStun(hitStun);
				}
				// damage
				var hitDamage:Number = item.damage + (thrownWeapon ? sender.damage : 0);
				if(hitResult & Character.CRITICAL) hitDamage *= 2;
				character.applyDamage(hitDamage, "arrow", hitKnockback, Boolean(hitResult & Character.CRITICAL));
				// leech
				if(sender.leech){
					var leechValue:Number = sender.leech > 1 ? 1 : sender.leech;
					sender.applyHealth(leechValue * hitDamage);
				}
				// thorns
				if(target.thorns){
					renderer.createDebrisRect(sender.collider, 0, 10, sender.debrisType);
					sender.applyDamage(hitDamage * (target.thorns <= 1 ? target.thorns : 1), target.nameToString(), 0, false, target.type);
				}
				// blood
				renderer.createDebrisSpurt(collider.x + collider.width * 0.5, collider.y + collider.height * 0.5, dx > 0 ? 5 : -5, 5, character.debrisType);
				g.soundQueue.add("hit");
				
			} else if(type == RUNE){
				if(character.type & Character.STONE) return;
				Item.revealName(effect.name, g.menu.inventoryList);
				g.console.print(effect.nameToString() + " cast upon " + character.nameToString());
				effect.apply(character);
				g.soundQueue.add("runeHit");
			} else if(type == DART){
				if(character.type & Character.STONE) return;
				g.console.print(effect.nameToString() + " dart hits " + character.nameToString());
				effect.apply(character);
				g.soundQueue.add("runeHit");
			}
			kill();
		}
		
		public function kill(side:int = 0):void{
			if(!active) return;
			if(type == RUNE || type == DART){
				renderer.createSparks(collider.x + collider.width * 0.5, collider.y + collider.height * 0.5, -dx, -dy, 10);
			}
			collider.world.removeCollider(collider);
			active = false;
			if(item && (item.range & Item.THROWN)){
				item.dropToMap(mapX, mapY);
			}
		}
		
		override public function render():void {
			var clipTemp:Rectangle;
			if(clipRect){
				clipTemp = clipRect.clone();
				clipTemp.x -= renderer.bitmap.x;
				clipTemp.y -= renderer.bitmap.y;
			}
			gfx.x = collider.x >> 0;
			gfx.y = collider.y >> 0;
			matrix = gfx.transform.matrix;
			matrix.tx -= renderer.bitmap.x;
			matrix.ty -= renderer.bitmap.y;
			renderer.bitmapData.draw(gfx, matrix, gfx.transform.colorTransform, null, clipTemp);
		}
	}
	
}