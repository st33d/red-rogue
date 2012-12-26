package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.ai.PlayerBrain;
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.level.Content;
	import com.robotacid.level.Map;
	import com.robotacid.geom.Pixel;
	import com.robotacid.gfx.ItemMovieClip;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.level.Surface;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.menu.InventoryMenuList;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	/**
	 * An object that applies spell effects to characters and items
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Effect {
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		public var active:Boolean;
		public var name:int;
		public var level:int;
		public var count:int;
		public var target:Character;
		public var source:int;
		public var applicable:Boolean;
		public var consolePrint:Boolean;
		
		public var healthStep:Number;
		public var targetTotalHealth:Number;
		
		public static const LIGHT:int = Item.LIGHT;
		public static const HEAL:int = Item.HEAL;
		public static const BLEED:int = Item.BLEED;
		public static const IDENTIFY:int = Item.IDENTIFY;
		public static const UNDEAD:int = Item.UNDEAD;
		public static const TELEPORT:int = Item.TELEPORT;
		public static const THORNS:int = Item.THORNS;
		public static const NULL:int = Item.NULL;
		public static const PORTAL:int = Item.PORTAL;
		public static const SLOW:int = Item.SLOW;
		public static const HASTE:int = Item.HASTE;
		public static const HOLY:int = Item.HOLY;
		public static const PROTECTION:int = Item.PROTECTION;
		public static const STUN:int = Item.STUN;
		public static const POLYMORPH:int = Item.POLYMORPH;
		public static const CONFUSION:int = Item.CONFUSION;
		public static const FEAR:int = Item.FEAR;
		public static const LEECH:int = Item.LEECH_RUNE;
		public static const XP:int = Item.XP;
		public static const CHAOS:int = Item.CHAOS;
		
		public static var BANNED_RANDOM_ENCHANTMENTS:Object = {};
		
		public static const FAVOURABLE_WEAPON_ENCHANTMENTS:Array = [BLEED, TELEPORT, SLOW, STUN, CONFUSION, FEAR, LEECH];
		public static const FAVOURABLE_ARMOUR_ENCHANTMENTS:Array = [LIGHT, HEAL, UNDEAD, THORNS, HASTE, PROTECTION];
		
		public static const WEAPON:int = Item.WEAPON;
		public static const ARMOUR:int = Item.ARMOUR;
		public static const THROWN:int = 3;
		public static const EATEN:int = 4;
		
		public static const TELEPORT_SOUNDS:Array = ["teleport1", "teleport2", "teleport3"];
		
		public static const DECAY_DELAY_PER_LEVEL:int = 30 * 3;
		/* There are 3 damage reflection opportunities: being a cactuar, the thorns spell, bees and knives armour - knives
		 * reflect twice as much as bees - so we divide 1.0 by 20 * 4 */
		public static const THORNS_PER_LEVEL:Number = 0.0125;
		/* Sources of leech are only from weapons and being a vampire */
		public static const LEECH_PER_LEVEL:Number = 0.5 / 20;
		/* Leech enchanted armour reduces maximum health by up to half */
		public static const LEECH_ARMOUR_PENALTY_PER_LEVEL:Number = 0.5 / 20;
		/* Max stun enchant should add just 0.5 to an item's stun stat */
		public static const STUN_PER_LEVEL:Number = 1.0 / 40;
		/* Min speed is half normal speed */
		public static const SLOW_PER_LEVEL:Number = 1.0 / 40;
		/* Max speed is double normal speed */
		public static const HASTE_PER_LEVEL:Number = 1.0 / 20;
		/* Protection should only add a maximum of 0.5 or halve damage */
		public static const PROTECTION_PER_LEVEL:Number = 1.0 / 40;
		/* The duration refers to how long the Horror created by the FEAR Effect will last */
		public static const FEAR_PER_LEVEL:int = 30;
		/* The duration refers to how long confusion created by the CONFUSION Effect will last */
		public static const CONFUSION_PER_LEVEL:int = 30;
		/* Random chance for a spell to work */
		public static const CHANCE_PER_LEVEL:Number = 1.0 / 20;
		
		public static const MIN_TELEPORT_DIST:int = 10;
		public static const ARMOUR_COUNTDOWN_STEP:int = 600 / 20;
		
		public function Effect(name:int, level:int, source:int = 0, target:Character = null, count:int = 0, racial:Boolean = false, consolePrint:Boolean = true) {
			this.name = name;
			this.level = level;
			this.source = source;
			this.consolePrint = consolePrint;
			applicable = true;
			if(target){
				apply(target, count, racial);
			}
		}
		
		public function copy():Effect{
			return new Effect(name, level, source);
		}
		
		public function main():void{
			if(name == LIGHT){
				// we have it as a given being in main() that this effect came from
				// weapon, eaten or thrown
				if(count-- <= 0){
					if(level > 1){
						var current_radius:int = Math.ceil(level * 0.5);
						var new_radius:int = Math.ceil((level - 1) * 0.5);
						if(new_radius < current_radius){
							game.lightMap.setLight(target, (target.light - current_radius) + new_radius, target is Player ? 255 : 150);
						}
						level--;
						count = DECAY_DELAY_PER_LEVEL;
					} else {
						if(target is Player && consolePrint) game.console.print("the " + nameToString() + " wears off");
						dismiss();
					}
				}
			} else if(name == HEAL) {
				if((game.frameCount & 1) == 0) renderer.createSparkRect(target.collider, 1, 0, -1, target.debrisType);
				if(source == EATEN || source == THROWN || source == WEAPON){
					if(count){
						count--;
						target.applyHealth(healthStep);
					} else {
						dismiss();
					}
				} else if(source == ARMOUR){
					target.applyHealth(healthStep);
					// track the target's totalHealth, so when they level up we boost the heal
					if(targetTotalHealth != target.totalHealth){
						targetTotalHealth = target.totalHealth;
						healthStep = targetTotalHealth / (2 * DECAY_DELAY_PER_LEVEL * (1 + Game.MAX_LEVEL - level));
					}
				}
			} else if(name == UNDEAD){
				// we get here because the effect is applied actively to undead characters
				if(source == WEAPON){
					if(count){
						count--;
						target.applyHealth(healthStep);
					} else {
						dismiss();
					}
				} else if(source == ARMOUR){
					target.applyHealth(healthStep);
					// track the target's totalHealth, so when they level up we boost the heal
					if(targetTotalHealth != target.totalHealth){
						targetTotalHealth = target.totalHealth;
						healthStep = targetTotalHealth / (2 * DECAY_DELAY_PER_LEVEL * (1 + Game.MAX_LEVEL - level));
					}
				}
				
			} else if(name == BLEED){
				if(count){
					count--;
					if(!target.undead){
						target.applyDamage(healthStep, nameToString(), 0, false, null, false);
						// death of the target orphans this object
						if(!active) return;
						
						// drip blood
						var blit:BlitRect, print:BlitRect;
						if(game.random.coinFlip()){
							blit = renderer.smallDebrisBlits[target.debrisType];
							print = renderer.smallFadeBlits[target.debrisType];
						} else {
							blit = renderer.bigDebrisBlits[target.debrisType];
							print = renderer.bigFadeBlits[target.debrisType];
						}
						renderer.addDebris(
							target.collider.x + game.random.range(target.collider.width),
							target.collider.y + game.random.range(target.collider.height),
							blit,
							0 , 0, print, true
						);
					}
				} else {
					if(source == ARMOUR){
						if(target is Player && consolePrint) game.console.print("the " + nameToString() + " wears off");
						active = false;
					} else {
						dismiss();
					}
				}
			} else if(name == THORNS){
				// we have it as a given being in main() that this effect came from
				// weapon, eaten or thrown
				if(count-- <= 0){
					if(level > 0){
						target.thorns -= THORNS_PER_LEVEL;
						level--;
						if(level == 0){
							if(target is Player && consolePrint) game.console.print("the " + nameToString() + " wears off");
							dismiss();
						} else {
							count = DECAY_DELAY_PER_LEVEL;
						}
					}
				}
			} else if(name == SLOW){
				// we have it as a given being in main() that this effect came from
				// weapon, eaten or thrown
				if(count-- <= 0){
					if(level > 0){
						target.speedModifier += SLOW_PER_LEVEL;
						target.attackSpeedModifier += SLOW_PER_LEVEL;
						level--;
						if(level == 0){
							if(target is Player && consolePrint) game.console.print("the " + nameToString() + " wears off");
							dismiss();
						} else {
							count = DECAY_DELAY_PER_LEVEL;
						}
					}
				}
			} else if(name == HASTE){
				// we have it as a given being in main() that this effect came from
				// weapon, eaten or thrown
				if(count-- <= 0){
					if(level > 0){
						target.speedModifier -= HASTE_PER_LEVEL;
						target.attackSpeedModifier -= HASTE_PER_LEVEL;
						level--;
						if(level == 0){
							if(target is Player && consolePrint) game.console.print("the " + nameToString() + " wears off");
							dismiss();
						} else {
							count = DECAY_DELAY_PER_LEVEL;
						}
					}
				}
			} else if(name == PROTECTION){
				// we have it as a given being in main() that this effect came from
				// weapon, eaten or thrown
				if(count-- <= 0){
					if(level > 0){
						target.protectionModifier += PROTECTION_PER_LEVEL;
						target.endurance -= PROTECTION_PER_LEVEL;
						level--;
						if(level == 0){
							if(target is Player && consolePrint) game.console.print("the " + nameToString() + " wears off");
							dismiss();
						} else {
							count = DECAY_DELAY_PER_LEVEL;
						}
					}
				}
			} else if(name == TELEPORT){
				// this here is the constant chaos caused by wearing teleport armour
				// more so if the armour is cursed and ironically may require a teleport rune to remove it
				if(count){
					// being stunned disrupts teleport armour
					if(target.state != Character.STUNNED){
						count--;
					}
				} else {
					if(target.state == Character.WALKING){
						teleportCharacter(target);
						count = (20 - game.random.rangeInt(level)) * ARMOUR_COUNTDOWN_STEP;
					}
				}
			} else if(name == STUN){
				// stun armour is similar to teleport armour in that it stuns the target periodically
				if(count) count--;
				else {
					if(target.state == Character.WALKING){
						target.applyStun(level * STUN_PER_LEVEL);
						count = (20 - game.random.rangeInt(level)) * ARMOUR_COUNTDOWN_STEP;
					}
				}
			} else if(name == FEAR){
				// fear armour is similar to teleport armour in that it spawns level 1 Horrors periodically
				if(count) count--;
				else {
					if(target.state == Character.WALKING){
						var horror:Horror = new Horror(target, FEAR_PER_LEVEL);
						count = (21 - level) * ARMOUR_COUNTDOWN_STEP;
					}
				}
			} else if(name == CONFUSION){
				// confusion armour is similar to teleport armour in that it confuses the target periodically
				if(count) count--;
				else {
					if(target.state == Character.WALKING){
						target.brain.confuse(CONFUSION_PER_LEVEL);
						count = (20 - game.random.rangeInt(level)) * ARMOUR_COUNTDOWN_STEP;
					}
				}
			} else if(name == CHAOS){
				// chaos armour is similar to teleport armour in that casts chaos on the target periodically
				if(count) count--;
				else {
					if(target.state == Character.WALKING) {
						count = (20 - game.random.rangeInt(level)) * ARMOUR_COUNTDOWN_STEP;
						
						// we can't risk banned area effects being called in areas, so chaos armour will do nothing there
						if(game.map && game.map.type == Map.AREA) return;
						
						var effect:Effect = new Effect(CHAOS, game.random.rangeInt(Game.MAX_LEVEL), EATEN, target);
					}
				}
			}
		}
		
		/* Used to embed an effect in an item, or apply an instant effect to said item
		 *
		 * When items are in the inventory,
		 * there's some direct fiddling with the inventory list
		 */
		public function enchant(item:Item, inventoryList:InventoryMenuList = null, user:Character = null):Item{
			
			var dest:Pixel, str:String, i:int;
			var vx:Number, vy:Number, length:Number;
			source = item.type;
			
			if(name == POLYMORPH){
				// here we randomise the item
				// first we pull it out of the menu - changing its skin is a messy business
				if(inventoryList) item = inventoryList.removeItem(item);
				
				var newName:int = item.name;
				var nameRange:int;
				if(item.type == Item.ARMOUR){
					nameRange = Content.armourNameDeck.length;
				} else if(item.type == Item.WEAPON){
					nameRange = Content.weaponNameDeck.length;
				}
				// limit change by exploration - catch possible infinite loop
				if(nameRange > game.deepestLevelReached) nameRange = game.deepestLevelReached;
				if(item.name == 0 && nameRange == 1){
					newName = item.name == 1 ? 0 : 1;
				} else {
					if(item.type == Item.ARMOUR) while(newName == item.name) newName = Content.armourNameDeck[game.random.rangeInt(nameRange)];
					else if(item.type == Item.WEAPON) while(newName == item.name) newName = Content.weaponNameDeck[game.random.rangeInt(nameRange)];
				}
				item.gfx = game.library.getItemGfx(newName, item.type);
				item.name = newName;
				// rolling a cursed indifference could brick the game for someone
				if(
					item.type == Item.ARMOUR && item.name == Item.INDIFFERENCE &&
					(item.holyState == Item.CURSE_REVEALED || item.holyState == Item.CURSE_HIDDEN)
				) item.holyState = Item.NO_CURSE;
				item.setStats();
				
				// now we try putting it back in
				if(inventoryList) inventoryList.addItem(item);
				SoundManager.playSound("Polymorph");
				return item;
				
			} else if(name == XP){
				// raises the level of the item by 1-3 levels
				while(level--){
					i = game.random.rangeInt(3) + 1;
					while(i--) item.levelUp();
				}
				if(inventoryList) inventoryList.updateItem(item);
				return item;
				
			} else if(name == LEECH){
				// leech levels up leeches and curses other items
				if(
					(item.type == Item.WEAPON && (item.name == Item.LEECH_WEAPON || item.name == Item.GUN_LEECH)) ||
					(item.type == Item.ARMOUR && item.name == Item.BLOOD)
				){
					while(level--) item.levelUp();
					if(inventoryList) inventoryList.updateItem(item);
					return item;
					
				} else if(item.holyState != Item.BLESSED) item.applyCurse();
				
			} else if(name == PORTAL){
				// create an item portal and send the item into the level it leads to
				if(inventoryList){
					renderer.createSparkRect(user.collider, 10, 0, -1);
					item = inventoryList.removeItem(item);
					item = randomEnchant(item, game.map.level);
					item.location = Item.UNASSIGNED;
					var portal:Portal = Portal.createPortal(Portal.PORTAL, user.mapX, user.mapY, game.map.level, Map.ITEM_DUNGEON);
					game.content.setItemDungeonContent(item, game.map.level, game.map.type);
					game.console.print("the " + item.nameToString() + " is sent into another dimension");
				}
				return item;
				
			} else if(name == NULL){
				// leech weapons become blood armour
				if(item.name == Item.LEECH_WEAPON){
					// first we pull it out of the menu - changing its skin is a messy business
					if(inventoryList) item = inventoryList.removeItem(item);
					item.type = Item.ARMOUR;
					item.name = Item.BLOOD;
					item.gfx = game.library.getItemGfx(Item.BLOOD, Item.ARMOUR);
					if(item.holyState == Item.CURSE_REVEALED || item.holyState == Item.CURSE_HIDDEN) item.holyState = Item.NO_CURSE;
					item.setStats();
					// now we try putting it back in
					if(inventoryList) inventoryList.addItem(item);
					game.console.print("blood armour created");
					if(user) renderer.createDebrisExplosion(user.collider, 8, 30, Renderer.BLOOD);
					
				} else {
					// strip all enchantments
					item.effects = null;
					item.holyState = Item.NO_CURSE;
					item.uniqueNameStr = null;
					item.setStats();
					if(inventoryList) inventoryList.updateItem(item);
				}
				return item;
				
			} else if(name == IDENTIFY){
				randomEnchant(item, game.deepestLevelReached, true);
				if(!item.uniqueNameStr){
					if(item.type == Item.WEAPON){
						str = Item.stats["weapon names"][item.name];
					} else if(item.type == Item.ARMOUR){
						str = Item.stats["armour names"][item.name];
					}
					item.createUniqueNameStr();
					game.console.print("the " + str + (str.charAt(str.length - 1) == "s" ? "'" : "'s") + " true name is " + item.uniqueNameStr);
				}
				game.gameMenu.loreList.unlockLore(item);
				if(inventoryList) inventoryList.updateItem(item);
				return item;
				
			} else if(name == HOLY){
				favourableEnchant(item, game.deepestLevelReached);
				if(item.holyState != Item.BLESSED){
					// leech weapons become plated
					if(item.type == Item.WEAPON && item.name == Item.LEECH_WEAPON){
						item.uniqueNameStr = "plated leech";
						item.gfx = game.library.getItemGfx(newName, item.type);
					}
					game.console.print((item.uniqueNameStr ? item.uniqueNameStr : item.nameStr) + " has been blessed by the gods");
					item.holyState = Item.BLESSED;
				}
				if(inventoryList) inventoryList.updateItem(item);
				return item;
				
			} else if(name == CHAOS){
				randomEnchant(item, Game.MAX_LEVEL);
				return item;
			}
			
			// this is the embedding routine
			addToItem(item);
			
			// non-applicable enchantments merely alter a stat on an item, they don't transmit effect objects to the target
			if(name == LEECH){
				if(item.type == Item.WEAPON){
					applicable = false;
					item.setStats();
				}
			} else if(name == THORNS){
				if(item.type == Item.ARMOUR){
					applicable = false;
					item.setStats();
				}
			} else if(name == STUN){
				if(item.type == Item.WEAPON){
					applicable = false;
					item.setStats();
				}
			}
			
			if(inventoryList) inventoryList.updateItem(item);
			
			if(name == TELEPORT && inventoryList){
				// casting teleport on an item in your inventory (suprise, surprise) teleports it to another location
				// in the level
				// at least if it was cursed this is a good thing
				item = inventoryList.removeItem(item);
				dest = getTeleportTarget(game.player.mapX, game.player.mapY, game.world.map, game.mapTileManager.mapRect, Boolean(Surface.fragmentationMap));
				
				if(user){
					vx = dest.x - game.player.mapX;
					vy = dest.y - game.player.mapY;
					length = Math.sqrt(vx * vx + vy * vy);
					if(length){
						vx /= length;
						vy /= length;
					} else {
						vx = vy = 0;
					}
					renderer.createSparkRect(user.collider, 20, vx, vy);
				}
				
				item.dropToMap(dest.x, dest.y);
				game.soundQueue.addRandom("teleport", ["teleport1", "teleport2", "teleport3"]);
				game.console.print("the " + item.nameToString() + " teleports away");
			}
			
			return item;
		}
		
		/* Add an effect to an item's effect list or creates the effect list */
		public function addToItem(item:Item):void{
			// item effects do not print out status reports all the time
			consolePrint = false;
			// repeat enchants must upgrade existing effects or risk a clusterfuck of effects firing all the time
			if(item.effects){
				var effect:Effect;
				for(var i:int = 0; i < item.effects.length; i++){
					effect = item.effects[i];
					if(effect.name == name){
						if(effect.level < Game.MAX_LEVEL){
							while(level-- && effect.level < Game.MAX_LEVEL){
								effect.level++;
							}
							break;
						}
					}
				}
				if(i == item.effects.length){
					// wizard hats double their first enchantment
					if(item.type == Item.ARMOUR && item.name == Item.WIZARD_HAT) level++;
					item.effects.push(this);
				}
			} else {
				item.effects = new Vector.<Effect>();
				// wizard hats double their first enchantment
				if(item.type == Item.ARMOUR && item.name == Item.WIZARD_HAT) level++;
				item.effects.push(this);
			}
		}
		
		/* Activates this effect on the target
		 *
		 * if the block that implements the effect has a return statement in it then that
		 * means that the effect is once only and is not to be stored in the character's
		 * effect buffer
		 */
		public function apply(target:Character, count:int = 0, racial:Boolean = false):void{
			
			var callMain:Boolean = false;
			var i:int;
			this.count = 0;
			
			this.target = target;
			
			if(name == LIGHT){
				// the light effect simply adds to the current radius of light on an object
				var radius:int = Math.ceil(level * 0.5);
				// the player is always lit at top strength - other things less so, for now.
				game.lightMap.setLight(target, target.light + radius, target is Player ? 255 : 150);
				if(source == WEAPON || source == THROWN || source == EATEN){
					this.count = count > 0 ? count : DECAY_DELAY_PER_LEVEL;
					callMain = true;
				}
				
			} else if(name == BLEED){
				// bleed affects a percentage of the victim's health over the decay delay period
				// making bleed armour pinch some of your health for putting it on, thrown runes and
				// eaten runes take half health (unless you replenish health) and weapons steal a
				// percentage of health per hit
				healthStep = (target.totalHealth * 0.5) / (1 + Game.MAX_LEVEL - level);
				healthStep /= DECAY_DELAY_PER_LEVEL;
				this.count = count > 0 ? count : DECAY_DELAY_PER_LEVEL;
				callMain = true;
				
			} else if(name == HEAL){
				// heal is the inverse of bleed, but will restore twice all health
				// except on armour - where it affects the amount of time it will take for the player
				// to reach full health whilst wearing
				if(source == WEAPON || source == EATEN || source == THROWN){
					healthStep = (target.totalHealth * 2) / (1 + Game.MAX_LEVEL - level);
					healthStep /= (DECAY_DELAY_PER_LEVEL * 2);
					this.count = count > 0 ? count : DECAY_DELAY_PER_LEVEL * 2;
				} else if(source == ARMOUR){
					targetTotalHealth = target.totalHealth;
					healthStep = targetTotalHealth / (2 * DECAY_DELAY_PER_LEVEL * (1 + Game.MAX_LEVEL - level));
				}
				callMain = true;
				
			} else if(name == SLOW){
				target.speedModifier -= level * SLOW_PER_LEVEL;
				target.attackSpeedModifier -= level * SLOW_PER_LEVEL;
				if(source == EATEN || source == THROWN || source == WEAPON){
					this.count = count > 0 ? count : DECAY_DELAY_PER_LEVEL;
					callMain = true;
				}
				
			} else if(name == HASTE){
				target.speedModifier += level * HASTE_PER_LEVEL;
				target.attackSpeedModifier += level * HASTE_PER_LEVEL;
				if(source == EATEN || source == THROWN || source == WEAPON){
					this.count = count > 0 ? count : DECAY_DELAY_PER_LEVEL;
					callMain = true;
				}
				
			} else if(name == PROTECTION){
				target.endurance += level * PROTECTION_PER_LEVEL;
				target.protectionModifier -= level * PROTECTION_PER_LEVEL;
				if(source == EATEN || source == THROWN || source == WEAPON){
					this.count = count > 0 ? count : DECAY_DELAY_PER_LEVEL;
					callMain = true;
				}
				
			} else if(name == UNDEAD){
				// if the target is undead, the effect acts like an instant heal rune
				// unless on a weapon - it renders undead enchanted weapons useless against undead
				if(target.undead){
					if(source == THROWN || source == EATEN){
						target.applyHealth((target.totalHealth / Game.MAX_LEVEL) * level);
						return;
						
					} else if(source == WEAPON){
						healthStep = target.totalHealth / (1 + Game.MAX_LEVEL - level);
						healthStep /= DECAY_DELAY_PER_LEVEL;
						this.count = count > 0 ? count : DECAY_DELAY_PER_LEVEL;
						
					} else if(source == ARMOUR){
						targetTotalHealth = target.totalHealth;
						healthStep = targetTotalHealth / (2 * DECAY_DELAY_PER_LEVEL * (1 + Game.MAX_LEVEL - level));
					}
					callMain = true;
				} else {
					if(consolePrint && (target == game.player || target == game.minion)) game.console.print(target.nameToString() + " may survive death");
				}
				
			} else if(name == TELEPORT){
				// teleport enchanted armour will randomly hop the wearer around the map, the stronger
				// the effect, the more frequent the jumps
				if(source == ARMOUR){
					count = (21 - level) * ARMOUR_COUNTDOWN_STEP;
					callMain = true;
				} else if(source == WEAPON){
					if(game.random.value() < CHANCE_PER_LEVEL * level){
						teleportCharacter(target);
					}
					return;
				} else {
					teleportCharacter(target);
					return;
				}
				
			} else if(name == STUN){
				// stun enchanted armour will periodically stun the wearer - the stronger the effect
				// the more frequently it occurs
				if(source == ARMOUR){
					count = (21 - level) * ARMOUR_COUNTDOWN_STEP;
					callMain = true;
				} else {
					// stun the target for an extra long duration
					target.applyStun(STUN_PER_LEVEL * level * 2);
					return;
				}
				
			} else if(name == POLYMORPH){
				if(source == EATEN || source == THROWN){
					var newName:int;
					// limit change by exploration - no infinite loop to catch here, there are two options from the start
					var nameRange:int = game.deepestLevelReached + 1;
					if(nameRange > Content.monsterNameDeck.length) nameRange = Content.monsterNameDeck.length;
					if(target.armour && target.armour.name == Item.FACE){
						// when the character is wearing face armour, we only need change the race underneath
						newName = (target.armour as Face).previousName;
						while(newName == (target.armour as Face).previousName) newName = Content.monsterNameDeck[game.random.rangeInt(nameRange)];
						(target.armour as Face).previousName = newName;
					} else {
						newName = target.name
						while(newName == target.name) newName = Content.monsterNameDeck[game.random.rangeInt(nameRange)];
						target.changeName(newName);
					}
					game.createDistSound(target.mapX, target.mapY, "Polymorph");
					return;
				}
				
			} else if(name == XP){
				// all characters except the player will get a level up, the player gets xp to their next level
				if(target.level < Game.MAX_LEVEL){
					if(target is Player){
						(target as Player).addXP(1 + (Content.xpTable[(target as Player).level] - (target as Player).xp));
					} else {
						target.levelUp();
					}
				} else {
					target.quicken();
				}
				return;
				
			} else if(name == LEECH){
				if(source == EATEN || source == THROWN){
					var item:Item = new Item(new ItemMovieClip(Item.LEECH_WEAPON, Item.WEAPON), Item.LEECH_WEAPON, Item.WEAPON, target.level);
					item.applyCurse();
					item.holyState = Item.CURSE_REVEALED;
					item.collect(target, false);
					if(target.weapon) target.unequip(target.weapon);
					target.equip(item);
					return;
					
				} else if(source == ARMOUR){
					target.totalHealth = (Character.stats["healths"][target.name] + Character.stats["health levels"][target.name] * target.level) * (1.0 - LEECH_ARMOUR_PENALTY_PER_LEVEL * level);
					if(target.health > target.totalHealth) target.health = target.totalHealth;
					if(target == game.player) game.playerHealthBar.setValue(target.health, target.totalHealth);
					else if(target == game.minion) game.minionHealthBar.setValue(target.health, target.totalHealth);
				}
				
			} else if(name == THORNS){
				if(source == EATEN || source == THROWN || source == WEAPON){
					target.thorns += level * THORNS_PER_LEVEL;
					this.count = count > 0 ? count : DECAY_DELAY_PER_LEVEL;
					callMain = true;
				}
				
			} else if(name == PORTAL){
				var portal:Portal;
				if(source == EATEN){
					if(target is Player){
						Portal.createPortal(Portal.PORTAL, target.mapX, target.mapY, Map.OVERWORLD, Map.AREA, game.map.level, game.map.type);
					} else if(target is Minion){
						if(target.name == Character.HUSBAND || UserData.gameState.husband){
							portal = Portal.createPortal(Portal.PORTAL, target.mapX, target.mapY, Map.OVERWORLD, Map.AREA, game.map.level, game.map.type);
						} else {
							portal = Portal.createPortal(Portal.PORTAL, target.mapX, target.mapY, Map.UNDERWORLD, Map.AREA, game.map.level, game.map.type);
						}
					}
				} else if(source == THROWN){
					if(target is Monster){
						portal = Portal.createPortal(Portal.MONSTER, target.mapX, target.mapY);
						portal.setCloneTemplate(target.toXML());
					}
				}
				return;
				
			} else if(name == NULL){
				// strip all eaten and thrown effects
				var effect:Effect;
				if(target.effects){
					for(i = target.effects.length - 1; i > -1; i--){
						effect = target.effects[i];
						if(effect.source == THROWN || effect.source == EATEN || effect.source == WEAPON){
							effect.dismiss();
						}
					}
				}
				// destroy all Horrors chasing the target
				for(i = game.entities.length - 1; i > -1; i--){
					if(game.entities[i] is Horror && (game.entities[i] as Horror).victim == target){
						(game.entities[i] as Horror).count = 0;
					}
				}
				// cancel confusion
				if(target.brain.confusedCount){
					target.brain.confusedCount = 0;
					target.brain.clear();
				}
				// strip name
				if(target != game.player && target != game.minion) target.uniqueNameStr = null;
				// revert rogue or minion to true form
				if(target == game.player && target.name != Character.ROGUE){
					target.changeName(Character.ROGUE);
				} else if(target == game.minion && target.name != Character.SKELETON){
					target.changeName(Character.SKELETON);
				}
				return;
				
			} else if(name == IDENTIFY){
				if(target is Player){
					game.gameMenu.inventoryList.identifyRunes();
					game.gameMenu.inventoryList.revealCurses();
					game.miniMap.reveal();
					if(target.name != Character.ROGUE) game.gameMenu.loreList.unlockLore(target);
					
				} else if(target is Minion){
					if(target.uniqueNameStr == Minion.DEFAULT_UNIQUE_NAME_STR){
						target.uniqueNameStr = "@";
						game.console.print("the minion's true name is @");
					}
					game.gameMenu.loreList.unlockLore(target);
					game.gameMenu.loreList.questsList.createQuest();
					if(target.name != Character.SKELETON) game.gameMenu.loreList.unlockLore(target);
					
				} else if(target is Monster){
					if(!target.uniqueNameStr){
						target.createUniqueNameStr();
						game.console.print("the " + target.nameStr + (target.nameStr.charAt(target.nameStr.length - 1) == "s" ? "'" : "'s") + " true name is " + target.uniqueNameStr);
					}
					game.gameMenu.loreList.unlockLore(target);
				}
				return;
				
			} else if(name == FEAR){
				if(source == ARMOUR){
					count = (21 - level) * ARMOUR_COUNTDOWN_STEP;
					callMain = true;
				} else {
					if(
						source == THROWN ||
						source == EATEN ||
						game.random.value() < CHANCE_PER_LEVEL * level
					){
						var horror:Horror = new Horror(target, FEAR_PER_LEVEL * level);
					}
					return;
				}
			} else if(name == CONFUSION){
				if(source == ARMOUR){
					count = (21 - level) * ARMOUR_COUNTDOWN_STEP;
					callMain = true;
				} else {
					if(
						source == THROWN ||
						source == EATEN ||
						game.random.value() < CHANCE_PER_LEVEL * level
					){
						target.brain.confuse(CONFUSION_PER_LEVEL * level);
						if(consolePrint) game.console.print(target.nameToString() + " is confused");
					}
					return;
				}
			} else if(name == HOLY){
				prayer(target);
				return;
				
			} else if(name == CHAOS){
				// chaos armour is a hack-effect for giving the chaos-helm an ability via this class
				if(source == ARMOUR){
					count = (21 - level) * ARMOUR_COUNTDOWN_STEP;
					callMain = true;
				} else {
					// change to a random name and re-apply
					while(name == CHAOS) name = game.random.rangeInt(Game.MAX_LEVEL);
					apply(target, count, racial);
					return;
				}
			}
			
			// racial effects are managed by the character class internally
			if(!racial){
				if(!target.effects) target.effects = new Vector.<Effect>();
				target.effects.push(this);
				active = true;
				
				if(callMain){
					// check that this effect isn't already deployed
					// it may have been turned on and off by a setStats call
					if(game.effects.indexOf(this) == -1) game.effects.push(this);
				}
			}
		}
		
		/* Removes the effect from the target */
		public function dismiss(buffer:Boolean = false):void{
			
			//if(target && target == game.player) trace("player effect dismiss", name);
			active = false;
			var n:int = target.effects.indexOf(this);
			if(n > -1) target.effects.splice(n, 1);
			//if(target && target == game.player) trace("player effects", target.effects.length);
			if(target.effects.length == 0) target.effects = null;
			
			if(buffer){
				if(!target.effectsBuffer) target.effectsBuffer = new Vector.<Effect>()
				target.effectsBuffer.push(this);
			}
			
			var i:int;
			
			var callMain:Boolean = false;
			
			if(name == LIGHT){
				var radius:int = Math.ceil(level * 0.5);
				game.lightMap.setLight(target, target.light - radius, target is Player ? 255 : 150);
				
			} else if(name == UNDEAD){
				// this rune's effect comes in to play when the target is killed and is not undead
				// face armour complicates this a little
				var living:Boolean = !target.undead;
				if(
					target.armour &&
					target.armour.name == Item.FACE &&
					Character.stats["undeads"][(target.armour as Face).previousName] == 0
				) living = true;
				
				if(!target.active && !buffer && living){
					if(game.random.value() < CHANCE_PER_LEVEL * level){
						var mc:MovieClip;
						// resurrect the player or the minion as a skeleton
						if(target == game.player || target == game.minion){
							target.active = true;
							target.applyHealth(target.totalHealth);
							game.console.print(target.nameToString() + " returns as undead");
							target.resurrect = true;
						
						} else {
							// replenish the health of the minion
							if(game.minion){
								game.minion.applyHealth(game.minion.totalHealth);
								game.console.print("the minion is healed by this sacrifice");
								renderer.createSparkRect(game.minion.collider, 20, 0, -1);
							
							// or open the underworld portal here if the minion had been destroyed
							} else {
								var portal:Portal = Portal.createPortal(Portal.PORTAL, target.mapX, target.mapY, Map.UNDERWORLD, Map.AREA, game.map.level, game.map.type);
								game.console.print("the underworld portal is opened by this sacrifice");
							}
						}
					}
				}
			} else if(name == THORNS){
				// remove floating point errors
				if(Math.abs(target.thorns) < 0.00001) target.thorns = 0;
				
			} else if(name == SLOW || name == HASTE){
				if(source == ARMOUR){
					if(name == SLOW){
						target.speedModifier += SLOW_PER_LEVEL * level;
						target.attackSpeedModifier += SLOW_PER_LEVEL * level;
					} else if(name == HASTE){
						target.speedModifier -= HASTE_PER_LEVEL * level;
						target.attackSpeedModifier -= HASTE_PER_LEVEL * level;
					}
				}
				// remove floating point errors
				if(Math.abs(target.speedModifier - 1) < 0.00001) target.speedModifier = 1;
				if(Math.abs(target.attackSpeedModifier - 1) < 0.00001) target.attackSpeedModifier = 1;
				
			} else if(name == PROTECTION){
				if(source == ARMOUR){
					target.protectionModifier -= PROTECTION_PER_LEVEL * level;
					target.endurance += PROTECTION_PER_LEVEL * level;
				}
				// remove floating point errors
				if(Math.abs(target.protectionModifier - 1) < 0.00001) target.protectionModifier = 1;
				
			} else if(name == LEECH){
				if(source == ARMOUR){
					target.totalHealth = Character.stats["healths"][target.name] + Character.stats["health levels"][target.name] * target.level;
					if(target == game.player) game.playerHealthBar.setValue(target.health, target.totalHealth);
					else if(target == game.minion) game.minionHealthBar.setValue(target.health, target.totalHealth);
				}
				
			}
			
			target = null;
		}
		
		/* Effects a teleportation upon a character */
		public static function teleportCharacter(target:Character, dest:Pixel = null, silent:Boolean = false):void{
			
			target.collider.divorce();
			if(!dest) dest = getTeleportTarget(target.mapX, target.mapY, game.world.map, game.mapTileManager.mapRect, (target == game.player && !game.player.keyItem && Surface.fragmentationMap));
			
			if(!silent){
				var vx:Number, vy:Number, length:Number;
				vx = dest.x - target.mapX;
				vy = dest.y - target.mapY;
				length = Math.sqrt(vx * vx + vy * vy);
				if(length){
					vx /= length;
					vy /= length;
				} else {
					vx = vy = 0;
				}
				renderer.createSparkRect(target.collider, 40, vx, vy);
				game.createDistSound(target.mapX, target.mapY, "teleportFrom", TELEPORT_SOUNDS);
			}
			
			target.collider.x = -target.collider.width * 0.5 + (dest.x + 0.5) * Game.SCALE;
			target.collider.y = -target.collider.height + (dest.y + 1) * Game.SCALE;
			if(target.brain && !(target.brain is PlayerBrain)) target.brain.clear();
			if(target is Player){
				game.lightMap.blackOut();
				(target as Player).snapCamera();
			}
			if(!silent){
				renderer.createSparkRect(target.collider, 40, -vx, -vy);
				game.createDistSound(dest.x, dest.y, "teleportTo", TELEPORT_SOUNDS);
			}
		}
		
		public function nameToString():String{
			return Item.runeNames[name];
		}
		
		public function toXML():XML{
			return <effect name={name} level={level} count={count} source={source} />;
		}
		
		/* Get a random location on the map to teleport to  */
		public static function getTeleportTarget(startX:int, startY:int, map:Vector.<Vector.<int>>, mapRect:Rectangle, fragmentationCheck:Boolean):Pixel{
			var finish:Pixel = new Pixel(startX, startY);
			var minTeleportDist:int = MIN_TELEPORT_DIST;
			var minDistImpossible:int = 100;
			
			while(
				// on fragmented levels we always teleport the player to a location that is entrance-side of the break
				(fragmentationCheck && Surface.fragmentationMap.getPixel32(finish.x, finish.y) != Surface.entranceCol) ||
				(Math.abs(startX - finish.x) < minTeleportDist && Math.abs(startY - finish.y) < minTeleportDist) ||
				(map[finish.y][finish.x] & Collider.WALL) ||
				!mapRect.contains((finish.x + 0.5) * Game.SCALE, (finish.y + 0.5) * Game.SCALE)
			){
				finish.x = game.random.range(map[0].length);
				finish.y = game.random.range(map.length);
				if(minDistImpossible-- <= 0){
					minDistImpossible = 100;
					minTeleportDist--;
				}
			}
			return finish;
		}
		
		/* Applies a set of random enchantments to an item */
		public static function randomEnchant(item:Item, level:int, existingEffectOnly:Boolean = false):Item{
			var name:int, i:int;
			var nameRange:int;
			var enchantments:int = 2 + game.random.range(level * 0.2);
			// bucket sort selection process, probably faster than a hash at this scale, can be arsed to verify
			var bucket:Vector.<int> = new Vector.<int>(Game.MAX_LEVEL);
			var index:int;
			if(existingEffectOnly){
				if(item.effects) index = game.random.range(item.effects.length);
				else return item;
			}
			while(enchantments--){
				if(existingEffectOnly){
					bucket[item.effects[index].name]++;
					index++;
					if(index >= item.effects.length) index = 0;
				} else {
					nameRange = game.random.range(Game.MAX_LEVEL);
					if(nameRange > game.deepestLevelReached) nameRange = game.deepestLevelReached;
					name = Content.runeNameDeck[game.random.range(nameRange)];
					// some enchantments confer multiple extra enchantments -
					// that can of worms will stay closed
					if(!Effect.BANNED_RANDOM_ENCHANTMENTS[name]) bucket[name]++;
					else enchantments++;
				}
			}
			var effect:Effect;
			for(i = 0; i < bucket.length; i++){
				if(bucket[i]){
					effect = new Effect(i, bucket[i]);
					if(item.enchantable(i)) item = effect.enchant(item);
				}
			}
			// apply/remove curse?
			if(item.holyState != Item.BLESSED && game.random.value() < 0.2){
				if(item.holyState == Item.CURSE_HIDDEN || item.holyState == Item.CURSE_REVEALED) item.holyState = Item.NO_CURSE;
				else item.holyState = Item.CURSE_HIDDEN;
			}
			return item;
		}
		
		/* Applies a set of favourable random enchantments to an item */
		public static function favourableEnchant(item:Item, level:int):Item{
			var name:int, i:int;
			var nameRange:int;
			var enchantments:int = 1 + game.random.range(level * 0.2);
			var runeList:Vector.<int> = new Vector.<int>();
			var list:Array = item.type == Item.WEAPON ? FAVOURABLE_WEAPON_ENCHANTMENTS : FAVOURABLE_ARMOUR_ENCHANTMENTS;
			// bucket sort selection process, probably faster than a hash at this scale, can be arsed to verify
			var bucket:Vector.<int> = new Vector.<int>(Game.MAX_LEVEL);
			while(enchantments--){
				bucket[list[game.random.rangeInt(list.length)]]++;
			}
			var effect:Effect;
			for(i = 0; i < bucket.length; i++){
				if(bucket[i]){
					effect = new Effect(i, bucket[i]);
					if(item.enchantable(i)) item = effect.enchant(item);
				}
			}
			return item;
		}
		
		/* Performs a random effect that is beneficial to the player */
		public static function prayer(target:Character):void{
			// assess situation and respond in kind
			if(target == game.player || target == game.minion){
				// if health is low, insta-heal
				if(target.health <= target.totalHealth * 0.25){
					target.applyHealth(target.totalHealth);
				} else {
					var list:Array = FAVOURABLE_ARMOUR_ENCHANTMENTS.slice();
					list.push(PORTAL, XP);
					var effect:Effect = new Effect(list[game.random.rangeInt(list.length)], Game.MAX_LEVEL, EATEN, target);
				}
			} else {
				// obliterate the target
				if(game.random.coinFlip()) target.smite((target.looking & Collider.RIGHT) ? Collider.LEFT : Collider.RIGHT, target.totalHealth * (target.rank == Character.ELITE ? 0.5 : 1));
				else var explosion:Explosion = new Explosion(0, target.mapX, target.mapY, 5, target.totalHealth * 0.5 * (target.rank == Character.ELITE ? 0.5 : 1), game.player, null, game.player.missileIgnore);
			}
			game.soundQueue.playRandom(["Prayer01", "Prayer02", "Prayer03"]);
		}
	}
	
}