package com.robotacid.engine {
	import com.robotacid.geom.Pixel;
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.menu.InventoryMenuList;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	/**
	 * ...
	 * @author steed
	 */
	public class Effect {
		
		public var g:Game;
		public var active:Boolean;
		public var name:int;
		public var level:int;
		public var count:int;
		public var target:Character;
		public var source:int;
		
		public var health_step:Number;
		public var target_total_health:Number;
		
		public static const NAMES:Array = Item.RUNE_NAMES;
		
		public static const LIGHT:int = Item.LIGHT;
		public static const HEAL:int = Item.HEAL;
		public static const POISON:int = Item.POISON;
		public static const TELEPORT:int = Item.TELEPORT;
		public static const UNDEAD:int = Item.UNDEAD;
		public static const POLYMORPH:int = Item.POLYMORPH;
		public static const XP:int = Item.XP;
		
		public static const WEAPON:int = Item.WEAPON;
		public static const ARMOUR:int = Item.ARMOUR;
		public static const THROWN:int = 3;
		public static const EATEN:int = 4;
		
		public static const DECAY_DELAY_PER_LEVEL:int = 30 * 3;
		
		public static const MIN_TELEPORT_DIST:int = 10;
		public static const TELEPORT_COUNTDOWN_STEP:int = 600 / 20;
		
		public function Effect(name:int, level:int, source:int, g:Game, target:Character = null) {
			this.g = g;
			this.name = name;
			this.level = level;
			this.source = source;
			if(target){
				apply(target);
			}
		}
		
		public function copy():Effect{
			return new Effect(name, level, source, g);
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
							g.light_map.setLight(target, (target.light - current_radius) + new_radius, target is Player ? 255 : 150);
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
						target.applyHealth(health_step);
					} else {
						dismiss();
					}
				} else if(source == ARMOUR){
					target.applyHealth(health_step);
					// track the target's total_health, so when they level up we boost the heal
					if(target_total_health != target.total_health){
						target_total_health = target.total_health;
						health_step = target_total_health / (2 * DECAY_DELAY_PER_LEVEL * (1 + Game.MAX_LEVEL - level));
					}
				}
			} else if(name == POISON){
				if(count){
					count--;
					target.applyDamage(health_step, nameToString());
				} else {
					if(source == ARMOUR){
						active = false;
					} else {
						dismiss();
					}
				}
			} else if(name == TELEPORT){
				// this here is the constant chaos caused by wearing teleport armour
				// more so if the armour is cursed and ironically will require a teleport rune to remove it
				if(count-- <= 0){
					g.createTeleportSparkRect(target.rect, 20);
					SoundManager.playSound(g.library.TeleportSound);
					target.divorce();
					var dest:Pixel = getTeleportTarget(target.map_x, target.map_y, g.block_map);
					target.x = (dest.x + 0.5) * Game.SCALE;
					target.y = (dest.y + 0.5) * Game.SCALE;
					target.updateRect();
					target.updateMC();
					target.awake = Collider.AWAKE_DELAY;
					if(target is Player){
						g.light_map.blackOut();
						g.camera.main();
						g.camera.skipScroll();
					}
					count = (21 - level) * TELEPORT_COUNTDOWN_STEP;
					g.createTeleportSparkRect(target.rect, 20);
				}
			}
		}
		
		/* Used to embed an effect in an item, or apply an instant effect to said item
		 * 
		 * Since only the player can enchant items, and those items are in the inventory,
		 * there's some direct fiddling with the inventory list
		 */
		public function enchant(item:Item, inventory_list:InventoryMenuList):Item{
			
			source = item.type;
			
			
			if(name == POLYMORPH){
				// here we randomise the item
				// first we pull it out of the menu - randomising its skin is a messy business
				item = inventory_list.removeItem(item);
				var new_name:int = item.name;
				var new_mc_class:Class;
				var new_mc:Sprite;
				if(item.type == Item.WEAPON){
					while(new_name == item.name || new_name == Item.BOW) new_name = Math.random() * 6;
					new_mc_class = g.library.weaponIndexToMCClass(new_name);
					new_mc = new new_mc_class();
				} else if(item.type == Item.ARMOUR){
					while(new_name == item.name) new_name = Math.random() * 6;
					new_mc_class = g.library.armourIndexToMCClass(new_name);
					new_mc = new new_mc_class();
				}
				var holder:DisplayObjectContainer = item.mc.parent;
				if(holder){
					holder.removeChild(item.mc);
					holder.addChild(new_mc);
					new_mc.x = item.mc.x;
					new_mc.y = item.mc.y;
				}
				item.mc = new_mc;
				item.name = new_name;
				// now we try putting it back in
				inventory_list.addItem(item);
				return item;
			} else if(name == XP){
				// just raises the level of the item
				item.levelUp();
				inventory_list.updateItem(item);
				return item;
			}
			
			// this is the embedding routine
			// repeat enchants must upgrade existing effects or risk a clusterfuck of effects firing all the time
			if(item.effects){
				var upgrade:Boolean = false;
				for(var i:int = 0; i < item.effects.length; i++){
					if(item.effects[i].name == name){
						if(item.effects[i].level < Game.MAX_LEVEL){
							upgrade = true;
							if((item.state == Item.EQUIPPED || Item.MINION_EQUIPPED) && item.type == Item.ARMOUR) item.effects[i].levelUp();
							else item.effects[i].level++;
							break;
						}
					}
				}
				if(!upgrade){
					item.effects.push(this);
					if(item.state == Item.EQUIPPED && item.type == Item.ARMOUR) apply(g.player);
					else if(item.state == Item.MINION_EQUIPPED && item.type == Item.ARMOUR) apply(g.minion);
				}
			} else {
				// upon enchanting this item, there is a chance it may become cursed
				if(Math.random() < Item.CURSE_CHANCE) item.curse_state = Item.CURSE_HIDDEN;
				item.effects = new Vector.<Effect>();
				item.effects.push(this);
				if(item.state == Item.EQUIPPED){
					if(item.type == Item.ARMOUR) apply(g.player);
					if(item.curse_state == Item.CURSE_HIDDEN) item.revealCurse();
				} else if(item.state == Item.MINION_EQUIPPED){
					if(item.type == Item.ARMOUR) apply(g.minion);
					if(item.curse_state == Item.CURSE_HIDDEN){
						item.revealCurse();
						g.console.print("but the minion is unaffected...");
					}
				}
			}
			
			inventory_list.updateItem(item);
			
			if(name == TELEPORT){
				// this is possibly the biggest pisstake of all the spells, casting teleport on an item
				// in your inventory (suprise, surprise) teleports it to another location in the dungeon
				if(item.state & Item.EQUIPPED){
					item = g.player.unequip(item);
				}
				item = inventory_list.removeItem(item);
				var dest:Pixel = getTeleportTarget(g.player.map_x, g.player.map_y, g.block_map);
				item.dropToMap(dest.x, dest.y);
				g.entities.push(item);
				g.createTeleportSparkRect(g.player.rect, 10);
				SoundManager.playSound(g.library.TeleportSound);
			}
			
			return item;
		}
		
		/* Activates this effect on the target
		 * 
		 * if the block that implements the effect has a return statement in it then that
		 * means that the effect is once only and is not to be stored in the character's
		 * effect buffer
		 */
		public function apply(target:Character):void{
			
			var call_main:Boolean = false;
			
			this.target = target;
			if(name == LIGHT){
				// the light effect simply adds to the current radius of light on an object
				var radius:int = Math.ceil(level * 0.5);
				// the player is always lit at top strength - other things less so, for now.
				g.light_map.setLight(target, target.light + radius, target is Player ? 255 : 150);
				if(source == WEAPON || source == THROWN || source == EATEN){
					count = DECAY_DELAY_PER_LEVEL;
					call_main = true;
				}
			} else if(name == POISON){
				// poison affects a percentage of the victim's health over the decay delay period
				// making poison armour pinch some of your health for putting it on, thrown runes and
				// eaten runes take half health (unless you replenish health) and weapons steal a
				// percentage of health per hit
				health_step = (target.total_health * 0.5) / (1 + Game.MAX_LEVEL - level);
				health_step /= DECAY_DELAY_PER_LEVEL;
				count = DECAY_DELAY_PER_LEVEL;
				call_main = true;
			} else if(name == HEAL){
				// heal is the inverse of poison, but will restore twice all health
				// except on armour - where it affects the amount of time it will take for the player
				// to reach full health whilst wearing
				if(source == WEAPON || source == EATEN || source == THROWN){
					health_step = (target.total_health * 2) / (1 + Game.MAX_LEVEL - level);
					health_step /= (DECAY_DELAY_PER_LEVEL * 2);
					count = DECAY_DELAY_PER_LEVEL * 2;
				} else if(source == ARMOUR){
					target_total_health = target.total_health;
					health_step = target_total_health / (2 * DECAY_DELAY_PER_LEVEL * (1 + Game.MAX_LEVEL - level));
				}
				call_main = true;
			} else if(name == TELEPORT){
				// teleport enchanted armour will randomly hop the wearer around the map, the stronger
				// the effect, the more frequent the jumps
				if(source == ARMOUR){
					count = (21 - level) * TELEPORT_COUNTDOWN_STEP;
					call_main = true;
				} else {
					if(Math.random() < 0.05 * level){
						g.createTeleportSparkRect(target.rect, 20);
						target.divorce();
						var dest:Pixel = getTeleportTarget(target.map_x, target.map_y, g.block_map);
						target.x = (dest.x + 0.5) * Game.SCALE;
						target.y = (dest.y + 0.5) * Game.SCALE;
						target.updateRect();
						target.updateMC();
						target.awake = Collider.AWAKE_DELAY;
						if(target is Player){
							g.light_map.blackOut();
							g.camera.main();
							g.camera.skipScroll();
						}
						g.createTeleportSparkRect(target.rect, 20);
						SoundManager.playSound(g.library.TeleportSound);
					}
					// all other sources of teleport do not embed, they are one time effects only
					return;
				}
			} else if(name == POLYMORPH){
				if(source == EATEN || source == THROWN){
					var new_skin:Class = Object(target.mc).constructor;
					var new_skin_name:int;
					for(var i:int = 0; i < 100; i++){
						new_skin_name = (Math.random() * CharacterAttributes.NAME_SKINS.length) >> 0;
						new_skin = CharacterAttributes.NAME_SKINS[new_skin_name];
						if(new_skin != Object(target.mc).constructor) break;
					}
					target.undead = new_skin_name == Character.SKELETON;
					var new_skin_mc:MovieClip = new new_skin();
					target.reskin(new_skin_mc, new_skin_name, new_skin_mc.width, new_skin_mc.height);
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
			}
			if(!target.effects) target.effects = new Vector.<Effect>();
			target.effects.push(this);
			active = true;
			
			if(call_main) g.effects.push(this);
		}
		
		/* Used when upgrading an existing effect */
		public function levelUp(n:int = 1):void{
			var temp_target:Character = target;
			if(temp_target) dismiss();
			if(level + n < Game.MAX_LEVEL){
				level += 1;
			}
			if(temp_target) apply(temp_target);
		}
		
		/* Removes the effect from the target */
		public function dismiss(buffer:Boolean = false):void{
			
			var i:int;
			
			var call_main:Boolean = false;
			
			if(name == LIGHT){
				var radius:int = Math.ceil(level * 0.5);
				g.light_map.setLight(target, target.light - radius, target is Player ? 255 : 150);
			} else if(name == UNDEAD){
				// this rune's effect comes in to play when the target is killed and is not undead
				if(!target.active && !buffer && !target.undead){
					if(Math.random() < 0.05 * level){
						var mc:MovieClip;
						if(source == THROWN || source == WEAPON){
							// replenish the health of an exisiting minion
							if(g.minion){
								g.minion.applyHealth(g.minion.total_health);
								g.console.print("minion is repaired");
								g.createTeleportSparkRect(g.minion.rect, 20);
							} else {
								mc = new g.library.SkeletonMC();
								mc.x = target.x;
								mc.y =  -mc.height * 0.5 + (target.map_y + 1) * Game.SCALE;
								g.entities_holder.addChild(mc);
								g.minion = new Minion(mc, Character.SKELETON, mc.width, mc.height, g);
							}
						} else if(source == ARMOUR || source == EATEN){
							mc = new g.library.SkeletonMC();
							target.active = true;
							target.applyHealth(target.total_health);
							g.console.print(target.nameToString()+" returns as undead");
							target.reskin(mc, Character.SKELETON, mc.width, mc.height);
							target.undead = true;
						}
					}
				}
			}
			active = false;
			
			var n:int = target.effects.indexOf(this);
			if(n > -1) target.effects.splice(n, 1);
			if(target.effects.length == 0) target.effects = null;
			
			if(buffer){
				if(!target.effects_buffer) target.effects_buffer = new Vector.<Effect>()
				target.effects_buffer.push(this);
			}
			
			n = g.effects.indexOf(this);
			if(n > -1) g.effects.splice(n, 1);
			
			target = null;
		}
		
		public function nameToString():String{
			return NAMES[name];
		}
		
		/*public function toString():String{
			var string:String = "", name:String;
			for(var i:int = 0; i < names.length; i++){
				if(type & (1 << i)){
					if(CHAOS & (1 << i)){
						name = names[Math.random() * names.length];
					} else {
						name = names[i];
					}
					if(string == ""){
						string += " of " + name;
					} else {
						string += " " + name;
					}
				}
			}
			return string;
		}
		
		
		public static function hideNames():void{
			names = [];
			for(var i:int = 0; i < PROPERTY_NAMES.length; i++){
				names.push("?");
			}
		}*/
		
		/* Get a random location on the map to teleport to - aims for somewhere not too immediate */
		public static function getTeleportTarget(start_x:int, start_y:int, map:Vector.<Vector.<int>>):Pixel{
			var finish:Pixel = new Pixel(start_x, start_y);
			while((Math.abs(start_x - finish.x) < MIN_TELEPORT_DIST && Math.abs(start_y - finish.y) < MIN_TELEPORT_DIST) || (map[finish.y][finish.x] & Block.WALL)){
				finish.x = Math.random() * map[0].length;
				finish.y = Math.random() * map.length;
			}
			return finish;
		}
	}
	
}