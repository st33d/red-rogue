package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.gfx.BlitSprite;
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Cast;
	import com.robotacid.geom.Dot;
	import com.robotacid.sound.SoundManager;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import com.robotacid.geom.Rect;
	
	/**
	* Basic missile class - only moves in straight lines for now
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class Missile extends Entity{
		
		public var dx:Number;
		public var dy:Number;
		public var speed:Number;
		public var temp_x:Number, temp_y:Number;
		public var ignore:int;
		public var effect:Effect;
		public var sender:Character;
		public var target:Character;
		public var failed_target:Character;
		public var item:Item;
		
		public static var cast:Cast;
		
		public static const ARROW:int = 1;
		public static const RUNE:int = 2;
		public static const DART:int = 3;
		
		public function Missile(mc:DisplayObject, name:int, sender:Character, dx:Number, dy:Number, speed:Number, g:Game, ignore:int = 0, effect:Effect = null, item:Item = null) {
			super(mc, g, true);
			this.name = name;
			this.sender = sender;
			this.dx = dx;
			this.dy = dy;
			this.speed = speed;
			this.ignore = ignore;
			this.effect = effect;
			this.item = item;
			call_main = true;
			
			// runes glow when they are converted to missiles
			if(name == RUNE){
				g.light_map.setLight(this, 3, 112);
			}
		}
		override public function main():void {
			move();
			if(mc) updateMC();
		}
		
		public function move():void{
			var vx:Number = speed * dx;
			var vy:Number = speed * dy;
			cast = Cast.ray(x, y, vx > 0 ? 1 : -1, vy > 0 ? 1 : -1, g.block_map, ignore, g);
			if(cast && cast.block && cast.distance < speed){
				
				if(cast.collider){
					if(cast.collider is Character){
						target = cast.collider as Character;
						if(target == failed_target){
							x += vx;
							y += vy;
						} else {
							if(name == ARROW){
								var hit_result:int = sender.hit(target);
								if(hit_result){
									hitCharacter(target, hit_result > 1);
									resolve(cast);
								} else {
									failed_target = target;
									x += vx;
									y += vy;
								}
							} else {
								hitCharacter(target);
								resolve(cast);
							}
						}
					} else {
						resolve(cast);
					}
				} else {
					resolve(cast);
				}
			} else {
				x += vx;
				y += vy;
				// check runes for proximity to the mouse for conversion to MouseMissile
				if(name == RUNE){
					if((g.canvas.mouseX - x) * (g.canvas.mouseX - x) + (g.canvas.mouseY - y) * (g.canvas.mouseY - y) <= speed){
						var mouse_missile:MouseMissile = new MouseMissile(mc, name, g, ignore, effect);
						// we have to stop the mc from being harvested
						mc = null;
						// and get this missile out of the equation
						active = false;
					}
				}
			}
			map_x = x * Game.INV_SCALE;
			map_y = y * Game.INV_SCALE;
				
		}
		
		public function resolve(cast:Cast):void{
			var vx:Number = speed * dx;
			var vy:Number = speed * dy;
			// resolve
			if(vx > 0 && cast.block.x <= x + vx){
				x = cast.block.x - 1;
			}
			if(vx < 0 && cast.block.x + cast.block.width > x + vx){
				x = cast.block.x + cast.block.width;
			}
			if(vy > 0 && cast.block.y <= y + vy){
				y = cast.block.y - 1;
			}
			if(vy < 0 && cast.block.y + cast.block.height > y + vy){
				y = cast.block.y + cast.block.height;
			}
			kill();
		}
		
		public function kill(side:int = 0):void{
			if(!active) return;
			if(name == RUNE || name == DART){
				g.createSparks(x - dx, y - dy, -dx, -dy, 10);
			}
			active = false;
		}
		public function updateMC():void {
			mc.x = x >> 0;
			mc.y = y >> 0;
		}
		public function hitCharacter(character:Character, critical:Boolean = false):void{
			if(name == ARROW){
				// need to make sure that monsters hit by arrows fly into battle mode
				if(character is Monster && (character as Monster).brain.state == Brain.PATROL){
					(character as Monster).brain.state == Brain.ATTACK;
					(character as Monster).brain.target = sender;
				}
				// would help if the player can see what they're doing to the target
				if(sender is Player) sender.victim = character;
				if(critical) g.shake(0, 5);
				if(item.effects) character.applyWeaponEffects(item);
				character.applyDamage(Item.WEAPON_DAMAGES[Item.BOW] * (critical ? 2 : 1), "arrow");
				g.createDebrisSpurt(x, y, dx > 0 ? 5 : -5, 5, character.debris_type);
				SoundManager.playSound(g.library.HitSound);
			} else if(name == RUNE){
				if(character.type & Character.STONE) return;
				Item.revealName(effect.name, g.menu.inventory_list);
				g.console.print(effect.nameToString() + " cast upon " + character.nameToString());
				effect.apply(character);
				SoundManager.playSound(g.library.RuneHitSound);
			} else if(name == DART){
				if(character.type & Character.STONE) return;
				g.console.print(effect.nameToString() + " dart hits " + character.nameToString());
				effect.apply(character);
				SoundManager.playSound(g.library.RuneHitSound);
			}
		}
	}
	
}