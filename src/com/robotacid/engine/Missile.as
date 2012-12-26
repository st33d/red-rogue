package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.BlitSprite;
	import com.robotacid.gfx.FadingBlitRect;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.phys.Cast;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
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
		public var reflections:int;
		public var alchemical:Boolean;
		
		private var offsetX:Number;
		private var offsetY:Number;
		private var catchable:Boolean;
		private var debris:Boolean;
		private var debrisType:int;
		
		protected static var target:Character;
		
		public static const LIGHTNING_DAMAGE_RATIO:Number = 1 / 8;
		public static const CHAKRAM_REFLECTIONS:int = 10;
		public static const RUNE_REFLECTIONS:int = 5;
		public static const CHAOS_MISSILE_RADIUS:Number = 3;
		
		// missile types
		public static const ITEM:int = 1;
		public static const RUNE:int = 2;
		public static const DART:int = 3;
		public static const CHAOS:int = 4;
		
		// debris types
		public static const DRIP:int = 3;
		
		public static const LIGHTNING_SOUNDS:Array = ["lightning1", "lightning2", "lightning3", "lightning4"];
		
		public function Missile(
			mc:DisplayObject, x:Number, y:Number, type:int, sender:Character, dx:Number, dy:Number, speed:Number,
			ignore:int = 0, effect:Effect = null, item:Item = null, clipRect:Rectangle = null, reflections:int = 0,
			firingTeam:int = 0, alchemical:Boolean = false
		){
			super(mc, true);
			this.type = type;
			this.sender = sender;
			this.dx = dx;
			this.dy = dy;
			this.speed = speed;
			this.effect = effect;
			this.item = item;
			this.clipRect = clipRect;
			this.reflections = reflections;
			this.alchemical = alchemical;
			callMain = true;
			debris = false;
			offsetX = 0;
			offsetY = 0;
			
			createCollider(x, y, Collider.LEFT | Collider.RIGHT | Collider.MISSILE | firingTeam, ignore, Collider.HOVER, false);
			
			if(type == CHAOS){
				collider.x = x - CHAOS_MISSILE_RADIUS;
				collider.y = y - CHAOS_MISSILE_RADIUS;
				collider.width = CHAOS_MISSILE_RADIUS * 2;
				collider.height = CHAOS_MISSILE_RADIUS * 2;
			}
			
			if(sender){
				// adjust the collider to make it fly nicely out of the sender
				// - it won't matter to the physics engine as we have to do a ghosting check anyway
				if(dx < 0) collider.x = (sender.collider.x + sender.collider.width * 0.5) - collider.width;
				else if(dx > 0) collider.x = sender.collider.x + sender.collider.width * 0.5
				collider.y = (sender.collider.y + sender.collider.height * 0.5) - collider.height * 0.5;
				if(collider.y + collider.height >= sender.collider.y + sender.collider.height){
					collider.y = (sender.collider.y + sender.collider.height) - collider.height;
				}
			}
			collider.dampingX = 1;
			collider.dampingY = 1;
			game.world.restoreCollider(collider);
			
			// enchanted missiles glow
			if((effect && type != DART) || (item && item.effects)){
				var lightRadius:int = 3;
				var lightValue:int = 112;
				var effectName:int;
				var effectLevel:int;
				if(effect){
					effectName = effect.name;
					effectLevel = effect.level;
				} else {
					var itemEffect:Effect = item.effects[game.random.rangeInt(item.effects.length)];
					effectName = itemEffect.name;
					effectLevel = itemEffect.level;
				}
				// holy and light runes generate max-light missiles
				if(effectName == Effect.LIGHT || effectName == Item.HOLY){
					lightRadius = effectName == Item.HOLY ? 15 : 5 + Math.ceil(effectLevel * 0.5);
					lightValue = 255;
				}
				game.lightMap.setLight(this, lightRadius, lightValue);
				
				// xp, light, chaos and leech effects are coloured
				if(effectName == Item.CHAOS){
					gfx.transform.colorTransform = new ColorTransform(0, 0, 0);
					debris = true;
					debrisType = Renderer.STONE;
				} else if(effectName == Item.LIGHT || effectName == Item.XP || effectName == Item.HOLY) gfx.transform.colorTransform = new ColorTransform(0, 0, 0, 1, 255, 255, 255);
				else if(effectName == Item.LEECH_RUNE) gfx.transform.colorTransform = new ColorTransform(0.7, 0, 0);
				else if(effectName == Item.BLEED){
					debris = true;
					debrisType = Renderer.BLOOD;
				} else if(effectName == Item.FEAR){
					gfx.transform.colorTransform = new ColorTransform(0, 0, 0);
					debris = true;
					debrisType = -1;
				}
			}
			
			if(item){
				// leech gun shots are always red and bleeding
				if(item.name == Item.GUN_LEECH){
					gfx.transform.colorTransform = new ColorTransform(0.7, 0, 0);
					debris = true;
					debrisType = Renderer.BLOOD;
				
				// create a top surface for the harpoon	
				} else if(item.name == Item.HARPOON){
					collider.properties |= Collider.UP;
					this.speed *= 0.5;
					collider.properties &= ~(firingTeam);
					this.reflections = 10;
				}
			}
			
			
			
			// set graphic offset
			var bounds:Rectangle = gfx.getBounds(gfx);
			offsetX = -bounds.left;
			offsetY = -bounds.top;
			if(mc.scaleX == -1){
				offsetX = bounds.width + bounds.left;
			}
			
			// the missile may have initialised inside a wall (excepting trap missiles)
			// or have initialised inside a character
			// without resolving it now the missile will pass through the physics object because
			// of the predictive collision set up we have
			ghostCheck();
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
						if(target != sender && (!sender || sender.enemy(target))){
							if(type == ITEM){
								// is the target protected?
								if(
									target.protectionModifier < 1 &&
									game.random.value() > (target.protectionModifier < Character.MIN_PROTECTION_MODIFIER ? Character.MIN_PROTECTION_MODIFIER : target.protectionModifier)
								){
									reflect(target); 
								} else {
									var hitResult:int = sender.hit(target, Item.MISSILE | Item.THROWN, item);
									if(hitResult){
										hitCharacter(target, hitResult);
									} else {
										if(target is Stone || target is Gate){
											kill();
										} else {
											// if the character is facing a throwable missile, they can catch it
											if(
												item && (item.range & Item.THROWN) && (
													(dx < 0 && (target.looking & Collider.RIGHT)) ||
													(dx > 0 && (target.looking & Collider.LEFT))
												)
											){
												target.catchThrowable(item);
												item = null;
												kill();
											} else {
												// pass through next simulation frame
												collider.ignoreProperties |= Collider.SOLID;
											}
										}
									}
								}
							} else {
								// is the target protected?
								if(
									target.protectionModifier < 1 &&
									game.random.value() > (target.protectionModifier < Character.MIN_PROTECTION_MODIFIER ? Character.MIN_PROTECTION_MODIFIER : target.protectionModifier)
								){
									reflect(target);
								}
								else hitCharacter(target);
							}
						}
					} else {
						if(reflections) reflect();
						else kill();
					}
				} else {
					if(alchemical && transmutable(mapX + (dx > 0 ? 1 : -1), mapY)) alchemy(mapX + (dx > 0 ? 1 : -1), mapY)
					else if(reflections) reflect();
					else kill();
				}
			} else {
				// repair contact filter from failed hits
				collider.ignoreProperties &= ~(Collider.SOLID);
				
				// debris?
				if(debris) {
					if(debrisType < 0) renderer.createDrips(collider, 1, Renderer.STONE);
					else renderer.createDebrisRect(collider, -dx, 2, debrisType);
				}
				
				if(sender && sender.active){
					// lightning and xp runes cast quickening lightning
					if(
						item &&
						(
							(item.type == Item.WEAPON && item.name == Item.LIGHTNING) ||
							(item.type == Item.RUNE && item.name == Item.XP)
						)
					){
						quickening();
					}
					if(catchable){
						// check for collision with sender if reflective, allowing them to catch the item
						if(
							sender.collider.x + sender.collider.width > collider.x &&
							collider.x + collider.width > sender.collider.x &&
							sender.collider.y + sender.collider.height > collider.y &&
							collider.y + collider.height > sender.collider.y
						){
							kill();
							if(item){
								item.collect(sender);
							}
						}
					}
				}
			}
		}
		
		/* Can the map location be converted to a Stone? */
		public function transmutable(mapX:int, mapY:int):Boolean{
			if(effect && effect.name == Effect.CHAOS){
				return (game.world.map[mapY][mapX] & Collider.SOLID) == Collider.SOLID;
			}
			var trap:Trap;
			var rect:Rectangle = new Rectangle(mapX * SCALE, mapY * SCALE, SCALE, SCALE);
			for(var i:int = 0; i < game.entities.length; i++){
				trap = game.entities[i] as Trap;
				if(trap){
					if(trap.type == Trap.PIT && trap.rect.intersects(rect)) return false;
				}
			}
			return (
				!(game.world.map[mapY][mapX] & (Collider.CHAOS | Collider.STONE)) &&
				game.world.getCollidersIn(rect, collider).length == 0 &&
				!game.mapTileManager.mapLayers[MapTileManager.ENTITY_LAYER][mapY][mapX]
			)
		}
		
		/* Converts a wall */
		public function alchemy(mapX:int, mapY:int):void{
			if(effect){
				var entity:ColliderEntity;
				var blit:BlitRect;
				var print:FadingBlitRect;
				var debrisType:int;
				
				if(effect.name == Effect.HEAL || effect.name == Effect.XP){
					var stoneName:int;
					if(effect.name == Effect.HEAL){
						entity = new Stone(mapX * SCALE, mapY * SCALE, Stone.HEAL);
						game.console.print("healstone created");
						debrisType = Renderer.BLOOD;
					} else if(effect.name == Effect.XP){
						entity = new Stone(mapX * SCALE, mapY * SCALE, Stone.GRIND);
						game.console.print("grindstone created");
						debrisType = Renderer.STONE;
					}
					entity.mapX = mapX;
					entity.mapY = mapY;
					entity.mapZ = MapTileManager.ENTITY_LAYER;
					game.mapTileManager.addTile(entity, mapX, mapY, MapTileManager.ENTITY_LAYER);
					game.world.restoreCollider(entity.collider);
					
				} else if(effect.name == Effect.CHAOS){
					entity = ChaosWall.initInvasionSite(mapX, mapY, collider);
					// if a chaos wall can't be created then instigate reflection or kill
					if(!entity){
						if(reflections) reflect();
						else kill();
						return;
					}
					if(item) game.console.print("chaos wall created");
					debrisType = Renderer.STONE;
				}
				Item.revealName(effect.name, game.gameMenu.inventoryList.runesList);
				renderer.createDebrisExplosion(entity.collider, 5, 30, debrisType);
				for(var i:int = 0; i < 30; i++){
					if(game.random.coinFlip()){
						blit = renderer.smallDebrisBlits[debrisType];
						print = renderer.smallFadeBlits[debrisType];
					} else {
						blit = renderer.bigDebrisBlits[debrisType];
						print = renderer.bigFadeBlits[debrisType];
					}
					renderer.addDebris(entity.collider.x + game.random.range(entity.collider.width), entity.collider.y + entity.collider.height, blit, 0, game.random.range(3), print, true);
					renderer.addDebris(entity.collider.x + entity.collider.width, entity.collider.y + game.random.range(entity.collider.height), blit, -game.random.range(3), 0, print, true);
					renderer.addDebris(entity.collider.x + game.random.range(entity.collider.width), entity.collider.y - 1, blit, 0, -game.random.range(5), print, true);
					renderer.addDebris(entity.collider.x - 1, entity.collider.y + game.random.range(entity.collider.height), blit, game.random.range(3), 0, print, true);
				}
				game.soundQueue.addRandom("alchemy", Stone.DEATH_SOUNDS);
				item = null;
			}
			kill();
		}
		
		public function hitCharacter(character:Character, hitResult:int = 0):void{
			if(type == ITEM){
				// need to make sure that monsters hit by arrows fly into battle mode
				if(character.brain && !(character.brain.state == Brain.ATTACK || character.brain.state == Brain.FLEE)){
					character.brain.attack(sender);
				}
				// would help if the player can see what they're doing to the target
				if(sender is Player) sender.victim = character;
				if(hitResult & Character.CRITICAL) renderer.shake(0, 5);
				if(item.effects && character.active && !(character.type & (Character.STONE | Character.GATE))){
					character.applyWeaponEffects(item);
				}
				// knockback
				var enduranceDamping:Number = 1.0 - (character.endurance + (character.armour ? character.armour.endurance : 0));
				if(enduranceDamping < 0) enduranceDamping = 0;
				var hitKnockback:Number = (item.knockback + sender.knockback) * enduranceDamping;
				if(dx < 0) hitKnockback = -hitKnockback;
				// stun
				if(hitResult & Character.STUN){
					var hitStun:Number = (item.stun + sender.stun) * enduranceDamping;
					if(hitStun) character.applyStun(hitStun);
				}
				// damage
				var hitDamage:Number = item.damage + (Boolean(item.range & Item.THROWN) ? sender.damage : sender.damage * 0.25);
				if(character.protectionModifier < 1){
					hitDamage *= character.protectionModifier < Character.MIN_PROTECTION_MODIFIER ? Character.MIN_PROTECTION_MODIFIER : character.protectionModifier;
				}
				// crit multiplier
				if(hitResult & Character.CRITICAL){
					hitDamage *= 2;
				}
				// blessed weapon? roll for smite
				if(item.holyState == Item.BLESSED && ((hitResult & Character.CRITICAL) || game.random.value() < Character.SMITE_PER_LEVEL * item.level)){
					character.smite(dx > 0 ? Collider.RIGHT : Collider.LEFT, hitDamage * 0.5);
					// half of hitDamage is transferred to the smite state
					hitDamage *= 0.5;
				}
				// leech
				if((sender.leech || (item.leech)) && !(character.armour && character.armour.name == Item.BLOOD) && !(character.type & Character.STONE)){
					var leechValue:Number = sender.leech + item.leech;
					if(leechValue > 1) leechValue = 1;
					leechValue *= hitDamage;
					if(leechValue > character.health) leechValue = character.health;
					sender.applyHealth(leechValue);
				}
				// apply damage
				character.applyDamage(hitDamage, sender.nameToString(), hitKnockback, Boolean(hitResult & Character.CRITICAL));
				// blood
				renderer.createDebrisSpurt(collider.x + collider.width * 0.5, collider.y + collider.height * 0.5, dx > 0 ? 5 : -5, 5, character.debrisType);
				
			} else if(type == RUNE){
				if(character.type & (Character.STONE | Character.GATE)){
					kill();
					return;
				}
				Item.revealName(effect.name, game.gameMenu.inventoryList.runesList);
				game.console.print(effect.nameToString() + " cast upon " + character.nameToString());
				effect.apply(character);
				game.soundQueue.add("runeHit");
				item = null;
				
			} else if(type == DART){
				if(character.type & (Character.STONE | Character.GATE)){
					kill();
					return;
				}
				game.console.print(effect.nameToString() + " dart hits " + character.nameToString());
				effect.apply(character);
				game.soundQueue.add("runeHit");
				
			} else if(type == CHAOS){
				if(character.type & (Character.STONE | Character.GATE)){
					kill();
					return;
				}
				game.console.print("? hits " + character.nameToString());
				effect.apply(character);
				game.soundQueue.add("runeHit");
			}
			kill();
		}
		
		/* Bounces the missile and sends it in the opposite direction */
		public function reflect(target:Character = null):void{
			if(reflections) reflections--;
			if(type == RUNE || type == DART || type == CHAOS){
				renderer.createSparks(collider.x + collider.width * 0.5, collider.y + collider.height * 0.5, -dx, -dy, 10);
			}
			if(dx){
				dx = -dx;
				gfx.scaleX = -gfx.scaleX;
			}
			if(dy){
				dy = -dy;
				gfx.scaleY = -gfx.scaleY;
			}
			game.soundQueue.add("thud");
			collider.vx = collider.vy = 0;
			catchable = item && (item.range & Item.THROWN);
			// change ownership of missile if reflected by protection effect
			if(target && target.brain && sender && sender.brain){
				collider.properties &= ~sender.brain.firingTeam;
				collider.properties |= target.brain.firingTeam;
				collider.ignoreProperties &= ~sender.missileIgnore;
				collider.ignoreProperties |= target.missileIgnore;
				sender = target;
			}
		}
		
		public function kill():void{
			if(!active) return;
			if(type == RUNE || type == DART || type == CHAOS){
				renderer.createSparks(collider.x + collider.width * 0.5, collider.y + collider.height * 0.5, -dx, -dy, 10);
			}
			collider.world.removeCollider(collider);
			active = false;
			if(item && (item.range & Item.THROWN)){
				if(item.name == Item.BOMB){
					var explosion:Explosion = new Explosion(0, mapX, mapY, 1 + Math.ceil(item.level / 4), item.damage, sender, item, collider.ignoreProperties);
				} else {
					gfx.scaleX = 1;
					item.dropToMap(mapX, mapY);
				}
			}
		}
		
		/* It's possible for a missile to get spawned in the middle of level geometry, causing a lot of undesirable effects
		 * this is checked for here and corrections are made to the physics to accomodate the situation */
		public function ghostCheck():void{
			// resolve out of walls
			if(!(type == DART || type == CHAOS)){
				var map:Vector.<Vector.<int>> = collider.world.map;
				var mapX:int, mapY:int;
				mapX = collider.x * INV_SCALE;
				mapY = collider.y * INV_SCALE;
				if((map[mapY][mapX] & Collider.RIGHT) && collider.x < (mapX + 1) * SCALE) collider.x = (mapX + 1) * SCALE + Collider.INTERVAL_TOLERANCE;
				mapX = (collider.x + collider.width - Collider.INTERVAL_TOLERANCE) * INV_SCALE;
				mapY = (collider.y + collider.height - Collider.INTERVAL_TOLERANCE) * INV_SCALE;
				if((map[mapY][mapX] & Collider.LEFT) && collider.x + collider.width - Collider.INTERVAL_TOLERANCE > mapX * SCALE) collider.x = (mapX * SCALE) - collider.width;
			}
			// collision test for targets
			var colliders:Vector.<Collider> = collider.world.getCollidersIn(collider, collider, -1, collider.ignoreProperties);
			for(var i:int = 0; i < colliders.length; i++){
				target = colliders[i].userData as Character;
				if(target && target != sender){
					if(type == ITEM){
						var hitResult:int = sender.hit(target, Item.MISSILE | Item.THROWN);
						if(hitResult){
							hitCharacter(target, hitResult);
							break;
						} else {
							// pass through next simulation frame
							collider.ignoreProperties |= Collider.SOLID;
						}
					} else {
						hitCharacter(target);
						break;
					}
				}
			}
		}
		
		/* The lightning effect that issues from the lightning throwable */
		public function quickening():void{
			var node:Character;
			var tx:Number, ty:Number;
			var points:Array = [new Point(collider.x, dx > 0 ? collider.y : collider.y + collider.height - 1), new Point(collider.x + collider.width - 1, dx > 0 ? collider.y + collider.height - 1 : collider.y)];
			var p:Point;
			for(var i:int = 0; i < points.length; i++){
				p = points[i];
				if(type == Character.MINION || type == Character.PLAYER){
					if(Brain.monsterCharacters.length){
						node = Brain.monsterCharacters[game.random.rangeInt(Brain.monsterCharacters.length)];
					}
				} else if(type == Character.MONSTER){
					if(Brain.playerCharacters.length){
						node = Brain.playerCharacters[game.random.rangeInt(Brain.playerCharacters.length)];
					}
				}
				
				if(
					!node || !node.active || node.state == Character.QUICKENING ||
					node.state == Character.ENTERING || node.state == Character.EXITING ||
					(
						// left wards
						i == 0 &&
						node.collider.x + node.collider.width * 0.5 > collider.x + collider.width * 0.5
					) ||
					(
						// right wards
						i == 1 &&
						node.collider.x + node.collider.width * 0.5 < collider.x + collider.width * 0.5
					)
				){
					node = null;
					tx = i == 0 ? 0 : game.mapTileManager.width * SCALE;
					ty = game.random.range(game.mapTileManager.height) * SCALE;
				} else {
					tx = node.collider.x + node.collider.width * 0.5;
					ty = node.collider.y + node.collider.height * 0.5;
				}
				if(game.lightning.strike(renderer.lightningShape.graphics, game.world.map, p.x, p.y, tx, ty) && node && sender.enemy(node.collider.userData)){
					node.applyDamage(game.random.value() * LIGHTNING_DAMAGE_RATIO * item.damage * (node.name == Character.BALROG ? 0.5 : 1), "lightning");
					renderer.createDebrisSpurt(tx, ty, 5, i == 0 ? -5 : 5, node.debrisType);
				}
			}
			if(game.frameCount % 2 == 0){
				game.createDistSound(mapX, mapY, "lightning", LIGHTNING_SOUNDS);
			}
		}
		
		override public function render():void {
			var clipTemp:Rectangle;
			if(clipRect){
				clipTemp = clipRect.clone();
				clipTemp.x -= renderer.bitmap.x;
				clipTemp.y -= renderer.bitmap.y;
			}
			gfx.x = (collider.x + offsetX) >> 0;
			gfx.y = (collider.y + offsetY) >> 0;
			matrix = gfx.transform.matrix;
			matrix.tx -= renderer.bitmap.x;
			matrix.ty -= renderer.bitmap.y;
			renderer.bitmapData.draw(gfx, matrix, gfx.transform.colorTransform, null, clipTemp);
		}
	}
	
}