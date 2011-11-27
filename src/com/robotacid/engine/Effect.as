package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.geom.Pixel;
	import com.robotacid.gfx.ItemMovieClip;
	import com.robotacid.gfx.Renderer;
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
		
		public static var g:Game;
		public static var renderer:Renderer;
		
		public var active:Boolean;
		public var name:int;
		public var level:int;
		public var count:int;
		public var target:Character;
		public var source:int;
		public var applicable:Boolean;
		
		public var healthStep:Number;
		public var targetTotalHealth:Number;
		
		public static const LIGHT:int = Item.LIGHT;
		public static const HEAL:int = Item.HEAL;
		public static const POISON:int = Item.POISON;
		public static const TELEPORT:int = Item.TELEPORT;
		public static const UNDEAD:int = Item.UNDEAD;
		public static const POLYMORPH:int = Item.POLYMORPH;
		public static const XP:int = Item.XP;
		public static const LEECH:int = Item.LEECH_RUNE;
		public static const THORNS:int = Item.THORNS;
		public static const PORTAL:int = Item.PORTAL;
		
		public static var BANNED_RANDOM_ENCHANTMENTS:Array = [];
		
		public static const WEAPON:int = Item.WEAPON;
		public static const ARMOUR:int = Item.ARMOUR;
		public static const THROWN:int = 3;
		public static const EATEN:int = 4;
		
		public static const DECAY_DELAY_PER_LEVEL:int = 30 * 3;
		/* There are 3 damage reflection opportunities: being a cactuar, the thorns spell, bees and knives armour - knives
		 * reflect twice as much as bees - so we divide 1.0 by 20 * 4 */
		public static const THORNS_PER_LEVEL:Number = 0.0125;
		/* There are 5 health stealing opportunities: being a vampire, the leech weapon, blood armour and leech enchantment
		 * counts as two - but we're going to treat it as four and divide 1.0 by 20 * 4 */
		public static const LEECH_PER_LEVEL:Number = 0.0125;
		
		public static const MIN_TELEPORT_DIST:int = 10;
		public static const TELEPORT_COUNTDOWN_STEP:int = 600 / 20;
		
		public function Effect(name:int, level:int, source:int, target:Character = null, count:int = 0) {
			this.name = name;
			this.level = level;
			this.source = source;
			applicable = true;
			if(target){
				apply(target, count);
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
							g.lightMap.setLight(target, (target.light - current_radius) + new_radius, target is Player ? 255 : 150);
						}
						level--;
						count = DECAY_DELAY_PER_LEVEL;
					} else {
						if(target is Player) g.console.print("the " + nameToString() + " wears off");
						dismiss();
					}
				}
			} else if(name == HEAL){
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
			} else if(name == POISON){
				if(count){
					count--;
					target.applyDamage(healthStep, nameToString());
				} else {
					if(source == ARMOUR){
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
							if(target is Player) g.console.print("the " + nameToString() + " wears off");
							dismiss();
						} else {
							count = DECAY_DELAY_PER_LEVEL;
						}
					}
				}
			} else if(name == TELEPORT){
				// this here is the constant chaos caused by wearing teleport armour
				// more so if the armour is cursed and ironically will require a teleport rune to remove it
				if(count-- <= 0){
					teleportCharacter(target);
					count = (21 - level) * TELEPORT_COUNTDOWN_STEP;
				}
			}
		}
		
		/* Used to embed an effect in an item, or apply an instant effect to said item
		 *
		 * When items are in the inventory,
		 * there's some direct fiddling with the inventory list
		 */
		public function enchant(item:Item, inventoryList:InventoryMenuList = null, user:Character = null):Item{
			
			var dest:Pixel;
			source = item.type;
			
			if(name == POLYMORPH){
				// here we randomise the item
				// first we pull it out of the menu - randomising its skin is a messy business
				if(inventoryList) item = inventoryList.removeItem(item);
				
				var newName:int = item.name;
				var nameRange:int;
				if(item.type == Item.ARMOUR){
					nameRange = Item.ITEM_MAX;
				} else if(item.type == Item.WEAPON){
					nameRange = Item.ITEM_MAX;
				}
				// limit change by exploration - catch possible infinite loop
				if(nameRange > g.deepestLevelReached) nameRange = g.deepestLevelReached;
				if(item.name == 0 && nameRange == 1){
					newName = item.name == 1 ? 0 : 1;
				} else {
					while(newName == item.name) newName = g.random.range(nameRange);
				}
				var newGfx:DisplayObject = g.library.getItemGfx(newName, item.type);
				item.gfx = newGfx;
				item.name = newName;
				item.setStats();
				
				// now we try putting it back in
				if(inventoryList) inventoryList.addItem(item);
				return item;
				
			} else if(name == XP){
				// just raises the level of the item
				while(level--) item.levelUp();
				if(inventoryList) inventoryList.updateItem(item);
				return item;
				
			} else if(name == PORTAL){
				// create an item portal and send the item into the level it leads to
				if(inventoryList){
					renderer.createTeleportSparkRect(user.collider, 10);
					item = inventoryList.removeItem(item);
					item = randomEnchant(item, g.dungeon.level);
					item.location = Item.UNASSIGNED;
					var portal:Portal = Portal.createPortal(Portal.ITEM, user.mapX, user.mapY, g.dungeon.level);
					g.content.setItemDungeonContent(item, g.dungeon.level);
				}
				return item;
				
			}
			
			// this is the embedding routine
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
				if(i == item.effects.length) item.effects.push(this);
			} else {
				item.effects = new Vector.<Effect>();
				item.effects.push(this);
				
				// upon enchanting this item for the first time, there is a chance it may become cursed
				if(g.random.value() < Item.CURSE_CHANCE) item.applyCurse();
			}
			
			// non-applicable enchantments merely alter a stat on an item, conferring no active effect
			if(name == LEECH){
				applicable = false;
				item.setStats();
			} else if(name == THORNS){
				if(item.type == Item.ARMOUR){
					applicable = false;
					item.setStats();
				}
			}
			
			if(inventoryList) inventoryList.updateItem(item);
			
			if(name == TELEPORT && inventoryList){
				// this is possibly the biggest pisstake of all the spells, casting teleport on an item
				// in your inventory (suprise, surprise) teleports it to another location in the dungeon
				// at least if it was cursed this is a good thing
				if(user) renderer.createTeleportSparkRect(user.collider, 10);
				item = inventoryList.removeItem(item);
				dest = getTeleportTarget(g.player.mapX, g.player.mapY, g.world.map, g.mapTileManager.mapRect);
				item.dropToMap(dest.x, dest.y);
				g.soundQueue.add("teleport");
			}
			
			return item;
		}
		
		/* Activates this effect on the target
		 *
		 * if the block that implements the effect has a return statement in it then that
		 * means that the effect is once only and is not to be stored in the character's
		 * effect buffer
		 */
		public function apply(target:Character, count:int = 0):void{
			
			var callMain:Boolean = false;
			this.count = 0;
			
			this.target = target;
			
			if(name == LIGHT){
				// the light effect simply adds to the current radius of light on an object
				var radius:int = Math.ceil(level * 0.5);
				// the player is always lit at top strength - other things less so, for now.
				g.lightMap.setLight(target, target.light + radius, target is Player ? 255 : 150);
				if(source == WEAPON || source == THROWN || source == EATEN){
					this.count = count > 0 ? count : DECAY_DELAY_PER_LEVEL;
					callMain = true;
				}
				
			} else if(name == POISON){
				// poison affects a percentage of the victim's health over the decay delay period
				// making poison armour pinch some of your health for putting it on, thrown runes and
				// eaten runes take half health (unless you replenish health) and weapons steal a
				// percentage of health per hit
				healthStep = (target.totalHealth * 0.5) / (1 + Game.MAX_LEVEL - level);
				healthStep /= DECAY_DELAY_PER_LEVEL;
				this.count = count > 0 ? count : DECAY_DELAY_PER_LEVEL;
				callMain = true;
				
			} else if(name == HEAL){
				// heal is the inverse of poison, but will restore twice all health
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
				
			} else if(name == TELEPORT){
				// teleport enchanted armour will randomly hop the wearer around the map, the stronger
				// the effect, the more frequent the jumps
				if(source == ARMOUR){
					count = (21 - level) * TELEPORT_COUNTDOWN_STEP;
					callMain = true;
				} else {
					if(g.random.value() < 0.05 * level){
						teleportCharacter(target);
					}
					// all other sources of teleport do not embed, they are one time effects only
					return;
				}
				
			} else if(name == POLYMORPH){
				if(source == EATEN || source == THROWN){
					var newName:int;
					// limit change by exploration - no infinite loop to catch here, there are two options from the start
					var nameRange:int = g.deepestLevelReached + 1;
					if(target.armour && target.armour.name == Item.FACE){
						// when the character is wearing face armour, we only need change the race underneath
						newName = (target.armour as Face).previousName;
						while(newName == (target.armour as Face).previousName) newName = g.random.range(nameRange);
						(target.armour as Face).previousName = newName;
					} else {
						newName = target.name
						while(newName == target.name) newName = g.random.range(nameRange);
						target.changeName(newName);
					}
					return;
				}
				
			} else if(name == XP){
				// all characters except the player will get a level up, the player gets xp to their next level
				if(target is Player){
					(target as Player).addXP(1 + (Player.XP_LEVELS[(target as Player).level] - (target as Player).xp));
				} else {
					target.levelUp();
				}
				return;
				
			} else if(name == LEECH){
				if(source == EATEN || source == THROWN){
					var item:Item = new Item(new ItemMovieClip(Item.LEECH_WEAPON, Item.WEAPON), Item.LEECH_WEAPON, Item.WEAPON, target.level);
					item.applyCurse();
					item.curseState = Item.CURSE_REVEALED;
					item.collect(target, false);
					if(target.weapon) target.unequip(target.weapon);
					target.equip(item);
				}
				return;
				
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
						Portal.createPortal(Portal.ROGUE, target.mapX, target.mapY);
					} else if(target is Minion){
						portal = Portal.createPortal(Portal.MINION, target.mapX, target.mapY);
					}
				} else if(source == THROWN){
					if(target is Monster){
						portal = Portal.createPortal(Portal.MONSTER, target.mapX, target.mapY);
						portal.setMonsterTemplate(target as Monster);
					}
				}
				
			}
			if(!target.effects) target.effects = new Vector.<Effect>();
			target.effects.push(this);
			active = true;
			
			if(callMain) g.effects.push(this);
		}
		
		/* Removes the effect from the target */
		public function dismiss(buffer:Boolean = false):void{
			
			var i:int;
			
			var callMain:Boolean = false;
			
			if(name == LIGHT){
				var radius:int = Math.ceil(level * 0.5);
				g.lightMap.setLight(target, target.light - radius, target is Player ? 255 : 150);
			} else if(name == UNDEAD){
				// this rune's effect comes in to play when the target is killed and is not undead
				if(!target.active && !buffer && !target.undead && !target.crushed){
					if(g.random.value() < 0.05 * level){
						var mc:MovieClip;
						if(source == THROWN || source == WEAPON){
							// replenish the health of an exisiting minion
							if(g.minion){
								g.minion.applyHealth(g.minion.totalHealth);
								g.console.print("minion is repaired");
								renderer.createTeleportSparkRect(g.minion.collider, 20);
							} else {
								mc = new MinionMC();
								g.minion = new Minion(mc, target.collider.x + target.collider.width * 0.5, target.collider.y + target.collider.height, Character.SKELETON);
								g.world.restoreCollider(g.minion.collider);
								g.minion.collider.state = Collider.FALL;
								g.minion.state = Character.WALKING;
								g.console.print("undead minion summoned");
							}
						} else if(source == ARMOUR || source == EATEN){
							target.active = true;
							target.applyHealth(target.totalHealth);
							g.console.print(target.nameToString()+" returns as undead");
							target.changeName(Character.SKELETON);
						}
					}
				}
			} else if(name == THORNS){
				// remove floating point errors
				if(Math.abs(target.thorns) < 0.00001) target.thorns = 0;
			}
			active = false;
			
			var n:int = target.effects.indexOf(this);
			if(n > -1) target.effects.splice(n, 1);
			if(target.effects.length == 0) target.effects = null;
			
			if(buffer){
				if(!target.effectsBuffer) target.effectsBuffer = new Vector.<Effect>()
				target.effectsBuffer.push(this);
			}
			
			n = g.effects.indexOf(this);
			if(n > -1) g.effects.splice(n, 1);
			
			target = null;
		}
		
		/* Effects a teleportation upon a character */
		private function teleportCharacter(target:Character):void{
			renderer.createTeleportSparkRect(target.collider, 20);
			target.collider.divorce();
			var dest:Pixel = getTeleportTarget(target.mapX, target.mapY, g.world.map, g.mapTileManager.mapRect);
			target.collider.x = -target.collider.width * 0.5 + (dest.x + 0.5) * Game.SCALE;
			target.collider.y = -target.collider.height + (dest.y + 1) * Game.SCALE;
			if(target is Player){
				g.lightMap.blackOut();
				(target as Player).snapCamera();
			} else if(target is Monster){
				(target as Monster).brain.clear();
			}
			renderer.createTeleportSparkRect(target.collider, 20);
			g.soundQueue.add("teleport");
		}
		
		public function nameToString():String{
			return Item.stats["rune names"][name];
		}
		
		public function toXML():XML{
			var xml:XML = <effect />;
			xml.@name = name;
			xml.@level = level;
			xml.@count = count;
			xml.@source = source;
			return xml;
		}
		
		/* Get a random location on the map to teleport to - aims for somewhere not too immediate */
		public static function getTeleportTarget(startX:int, startY:int, map:Vector.<Vector.<int>>, mapRect:Rectangle):Pixel{
			var finish:Pixel = new Pixel(startX, startY);
			while((Math.abs(startX - finish.x) < MIN_TELEPORT_DIST && Math.abs(startY - finish.y) < MIN_TELEPORT_DIST) || (map[finish.y][finish.x] & Collider.WALL) || !mapRect.contains((finish.x + 0.5) * Game.SCALE, (finish.y + 0.5) * Game.SCALE)){
				finish.x = g.random.range(map[0].length);
				finish.y = g.random.range(map.length);
			}
			return finish;
		}
		
		/* Applies a set of random enchantments to an item */
		public static function randomEnchant(item:Item, level:int):Item{
			var name:int;
			var nameRange:int;
			var enchantments:int = 2 + g.random.range(level * 0.5);
			var runeList:Vector.<int> = new Vector.<int>();
			while(enchantments--){
				nameRange = g.random.range(Item.stats["rune names"].length);
				if(nameRange > g.deepestLevelReached) nameRange = g.deepestLevelReached;
				name = g.random.range(nameRange);
				// some enchantments confer multiple extra enchantments -
				// that can of worms will stay closed
				if(!Effect.BANNED_RANDOM_ENCHANTMENTS[name]) runeList.push(name);
				else enchantments++;
			}
			// each effect must now be given a level, for this we do a bucket sort
			// to stack the effects
			var bucket:Vector.<int> = new Vector.<int>(Item.stats["rune names"].length);
			var i:int;
			for(i = 0; i < runeList.length; i++){
				bucket[runeList[i]]++;
			}
			var effect:Effect;
			for(i = 0; i < bucket.length; i++){
				if(bucket[i]){
					effect = new Effect(i, bucket[i], 0);
					if(item.enchantable(i)) item = effect.enchant(item);
				}
			}
			// apply/remove curse?
			if(item.curseState != Item.BLESSED && g.random.value() < 0.2){
				if(item.curseState == Item.CURSE_HIDDEN || item.curseState == Item.CURSE_REVEALED) item.curseState = Item.NO_CURSE;
				else item.curseState = Item.CURSE_HIDDEN;
			}
			return item;
		}
	}
	
}