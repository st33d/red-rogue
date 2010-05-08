package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.gfx.BlitBackgroundClip;
	import com.robotacid.gfx.BloodClip;
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.util.clips.localToLocal;
	import com.robotacid.util.HiddenInt;
	import com.robotacid.util.HiddenNumber;
	import com.robotacid.geom.Rect;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	/**
	 * This is the base class for all creatures in the game - including the player.
	 * 
	 * By levelling the playing field we get creatures that behave like the player -
	 * and as a bonus the player can transform into them with magic
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Character extends Collider{
		
		public var level:int;
		public var type:int
		
		// states
		public var state:int;
		public var dir:int;
		public var looking:int;
		public var actions:int;
		public var moving:Boolean;
		public var attack_speed:Number;
		public var attack_count:Number;
		public var block_map_type:int;
		public var move_frame:int;
		public var move_count:int;
		public var quickening_count:int;
		public var tile_center:Number;
		public var victim:Character;
		public var step_noise:Boolean;
		public var crushed:Boolean;
		public var undead:Boolean;
		public var in_the_dark:Boolean;
		public var debris_type:int;
		public var missile_ignore:int;
		
		// attributes
		public var speed:Number;
		public var health:Number;
		public var total_health:Number;
		public var damage:Number;
		public var xp_reward:Number;
		public var attack:Number;
		public var defense:Number;
		
		public var loot:Vector.<Item>;
		public var effects:Vector.<Effect>;
		public var effects_buffer:Vector.<Effect>;
		public var stairs:Stairs;
		public var weapon:Item;
		public var armour:Item;
		
		private var hit_result:Number;
		
		// type flags
		public static const PLAYER:int = 1;
		public static const MONSTER:int = 1 << 1;
		public static const MINION:int = 1 << 2;
		public static const STONE:int = 1 << 3;
		
		// character names
		public static const ROGUE:int = 0;
		public static const SKELETON:int = 1;
		public static const GOBLIN:int = 2;
		public static const ORC:int = 3;
		
		// states
		public static const WALKING:int = 1;
		public static const CLIMBING:int = 1 << 1;
		public static const FALLING:int = 1 << 2;
		public static const ATTACK:int = 1 << 3;
		public static const THROWN:int = 1 << 4;
		public static const DEAD:int = 1 << 5;
		public static const QUICKENING:int = 1 << 6;
		public static const EXIT:int = 1 << 7;
		public static const ENTER:int = 1 << 8;
		
		public static const MOVE_DELAY:int = 3;
		
		// physics constants
		public static const GRAVITY:Number = 0.8;
		public static const DAMPING_Y:Number = 0.99;
		public static const DAMPING_X:Number = 0.45;
		public static const THROW_SPEED:Number = 16;
		
		public static const LADDER_WIDTH:Number = 10;
		public static const LADDER_RIGHT:Number = 12;
		public static const LADDER_LEFT:Number = 3;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		public static const MISS:int = 0;
		public static const HIT:int = 1;
		public static const CRITICAL:int = 2;
		public static const CRITICAL_HIT:Number = 0.94;
		public static const CRITICAL_MISS:Number = 0.05;
		public static const QUICKENING_DELAY:int = 90;
		
		public static var p:Point = new Point();
		
		public function Character(mc:DisplayObject, name:int, type:int, level:int, width:int, height:int, g:Game) {
			super(mc, width, height, g);
			
			this.name = name;
			this.level = level;
			this.type = type;
			
			health = CharacterAttributes.NAME_HEALTHS[name] + CharacterAttributes.NAME_HEALTH_LEVELS[name] * level;
			total_health = health;
			attack = CharacterAttributes.NAME_ATTACKS[name] + CharacterAttributes.NAME_ATTACK_LEVELS[name] * level;
			defense = CharacterAttributes.NAME_DEFENCES[name] + CharacterAttributes.NAME_DEFENCE_LEVELS[name] * level;
			attack_speed = CharacterAttributes.NAME_ATTACK_SPEEDS[name] + CharacterAttributes.NAME_ATTACK_SPEED_LEVELS[name] * level;
			damage = CharacterAttributes.NAME_DAMAGES[name] + CharacterAttributes.NAME_DAMAGE_LEVELS[name] * level;
			speed = CharacterAttributes.NAME_SPEEDS[name] + CharacterAttributes.NAME_SPEED_LEVELS[name] * level;
			xp_reward = CharacterAttributes.NAME_XP_REWARDS[name] + CharacterAttributes.NAME_XP_REWARD_LEVELS[name] * level;
			
			state = FALLING;
			step_noise = false;
			attack_count = 1;
			vx = vy = 0;
			moving = false;
			move_count = 0;
			move_frame = 0;
			block.type |= Block.CHARACTER;
			block_map_type = g.block_map[map_y][map_x];
			call_main = true;
			crushed = false;
			undead = name == SKELETON;
			debris_type = name == SKELETON ? Game.BONE : Game.BLOOD;
			in_the_dark = false;
			missile_ignore = Block.LADDER | Block.LEDGE;
			missile_ignore = Block.LADDER | Block.LEDGE;
			crushable = true;
			inflicts_crush = true;
			
			loot = new Vector.<Item>();
		}
		
		
		/* movement is handled separately to keep all colliders synchronized */
		override public function move():void {
			if(state != ENTER && state != EXIT){
				vx *= DAMPING_X;
				moveX(vx, this);
			} else {
				x += vx;
				y += vy;
			}
			if(state == FALLING || state == WALKING){
				if (parent_block){
					checkFloor();
				}
				if(!parent_block){
					vy = DAMPING_Y * vy + GRAVITY;
					moveY(vy, this);
				}
				if(!parent_block){
					state = FALLING;
				} else {
					if(state == FALLING && step_noise) SoundManager.playSound(g.library.ThudSound);
					state = WALKING;
				}
			} else if(state == CLIMBING){
				moveY(vy * DAMPING_Y, this);
			} else if(state == QUICKENING){
				moveY(vy);
			} else if(state == ATTACK){
				if (parent_block){
					checkFloor();
				}
				if(!parent_block){
					vy = DAMPING_Y * vy + GRAVITY;
					moveY(vy, this);
				}
			}
			// pace movement
			if(state == WALKING || state == CLIMBING || state == EXIT || state == ENTER){
				if(!moving) move_count = 0;
				else {
					if(step_noise && moving && move_count == 0 && move_frame == 0) SoundManager.playSound(g.library.StepsSound);
					move_count = (move_count + 1) % MOVE_DELAY;
					// flip between climb frames as we move
					if(move_count == 0) move_frame ^= 1;
				}
			}
			
			map_x = (rect.x + rect.width * 0.5) * INV_SCALE;
			map_y = (rect.y + rect.height * 0.5) * INV_SCALE;
			
			
			
			if(map_y > g.block_map.length-1) throw new Error(nameToString()+" mapx:" + map_x + "mapy:" + map_y + " map dimensions:" + g.renderer.width + " " + g.renderer.height + " block map height:" + g.block_map.length);
			if(map_x > g.block_map[0].length-1) throw new Error(nameToString()+" mapx:" + map_x + "mapy:" + map_y + " map dimensions:" + g.renderer.width + " " + g.renderer.height + " block map height:" + g.block_map.length);
			
			
			
			
			block_map_type = g.block_map[map_y][map_x];
			
			// will put the collider to sleep if it doesn't move
			if((vx > 0 ? vx : -vx) < TOLERANCE && (vy > 0 ? vy : -vy) < TOLERANCE && (awake)) awake--;
		}
		
		override public function main():void{
			processActions();
			// lighting check - if the monster is in total darkness, we need not tend to their animation
			// and making them invisible will help the lighting engine conceal their presence.
			// however - if they are moving, they may "pop" in and out of darkness, so we check around them
			// for light
			if(light) in_the_dark = false;
			else{
				if(dir == 0){
					if(g.light_map.dark_image.getPixel32(map_x, map_y) != 0xFF000000) in_the_dark = false;
					else in_the_dark = true;
				} else if(dir & (RIGHT | LEFT)){
					if(g.light_map.dark_image.getPixel32(map_x, map_y) != 0xFF000000 || g.light_map.dark_image.getPixel32(map_x + 1, map_y) != 0xFF000000 || g.light_map.dark_image.getPixel32(map_x - 1, map_y) != 0xFF000000) in_the_dark = false;
					else in_the_dark = true;
				} else if(dir & (UP | DOWN)){
					if(g.light_map.dark_image.getPixel32(map_x, map_y) != 0xFF000000 || g.light_map.dark_image.getPixel32(map_x, map_y + 1) != 0xFF000000 || g.light_map.dark_image.getPixel32(map_x, map_y - 1) != 0xFF000000) in_the_dark = false;
					else in_the_dark = true;
				}
			}
			
			if(!in_the_dark){
				mc.visible = true;
				updateAnimState(mc as MovieClip);
				updateMC();
			} else {
				mc.visible = false;
			}
			up_collider = right_collider = down_collider = left_collider = null;
			collisions = 0;
		}
		
		// This chunk is the core state machine for all Characters
		public function processActions():void{
			if(parent_block != null) collisions |= Rect.DOWN;
			tile_center = (map_x + 0.5) * SCALE
			// react to direction state
			if(state == WALKING) moving = Boolean(dir & (LEFT | RIGHT));
			else if(state == CLIMBING) moving = Boolean(dir & (UP | DOWN));
			// moving left or right
			if(state == WALKING || state == FALLING){
				if(dir & RIGHT) vx += speed;
				else if(dir & LEFT) vx -= speed;
				// climbing
				if(dir & UP){
					if(canClimb() && !(parent_block && (parent_block.type & Block.LEDGE) && !(block_map_type & Block.LADDER))){
						state = CLIMBING;
						if (parent != null){
							parent.removeChild(this);
						}
						parent = null;
						parent_block = null;
					}
				}
				// dropping through ledges and climbing down
				if(dir & DOWN){
					if(parent_block && (parent_block.type & Block.LEDGE)){
						awake = AWAKE_DELAY;
						ignore |= Block.LEDGE;
						if (parent != null){
							parent.removeChild(this);
						}
						parent = null;
						parent_block = null;
						if(canClimb()) state = CLIMBING;
					}
				} else if(ignore & Block.LEDGE){
					ignore &= ~Block.LEDGE;
				}
			}
			// attacking
			if(state == WALKING){
				if(left_collider || right_collider){
					var target:Character = null;
					if((dir & LEFT) && left_collider && left_collider is Character && enemy(left_collider as Character)){
						target = left_collider as Character;
					} else if((dir & RIGHT) && right_collider && right_collider is Character && enemy(right_collider as Character)){
						target = right_collider as Character;
					}
					if(target){
						moving = false;
						if(attack_count >= 1 && (((dir & LEFT) && vx < 0) ||((dir & RIGHT) && vx > 0))){
							state = ATTACK;
							hit_result = hit(target);
							if(hit_result){
								if(!(target.type & STONE)) target.weight = 0;
								if(weapon && weapon.effects && target.active && !(target.type & STONE)){
									target.applyWeaponEffects(weapon);
								}
								target.applyDamage((damage + damage_bonus) * hit_result, nameToString(), hit_result > 1, type);
								SoundManager.playSound(g.library.HitSound);
								p = localToLocal(p, (mc as MovieClip).weapon, g.canvas);
								g.createDebrisSpurt(p.x, p.y, (dir & LEFT) ? -5 : 5, 5, target.debris_type);
							} else {
								SoundManager.playSound(g.library.MissSound);
							}
						}
						victim = target;
					}
				}
			} else if(state == ATTACK){
				if(attack_count > 0.5){
					state = WALKING;
				}
			} else if(state == THROWN){
				if(dir & RIGHT){
					vx = -THROW_SPEED;
					if(collisions & LEFT){
						state = FALLING;
						ignore &= ~Block.CHARACTER;
					}
				} else if(dir & LEFT){
					vx = THROW_SPEED;
					if(collisions & RIGHT){
						state = FALLING;
						ignore &= ~Block.CHARACTER;
					}
				}
			} else if(state == CLIMBING){
				if(canClimb()){
					// a character always tries to center itself on a ladder
					if((dir & UP)){
						vy = -speed;
						centerOnTile();
					} else if(dir & DOWN){
						vy = speed;
						centerOnTile();
					} else if(dir & RIGHT){
						state = FALLING
					} else if(dir & LEFT){
						state = FALLING;
					} else {
						vy = 0;
					}
					if(parent_block){
						state = WALKING;
						dir &= ~(UP | DOWN);
					}
				} else {
					state = FALLING;
					dir &= ~(UP | DOWN);
					vy = 0;
				}
			} else if(state == QUICKENING){
				vy = -0.5;
				var col_trans:ColorTransform = mc.transform.colorTransform;
				col_trans.redOffset+=4;
				col_trans.greenOffset+=4;
				col_trans.blueOffset+=4;
				mc.transform.colorTransform = col_trans;
				var node:Character;
				var tx:Number, ty:Number;
				// lightning from the right hand
				if((mc as MovieClip).weapon && (mc as MovieClip).left_hand){
					p = localToLocal(p, mc.scaleX == 1 ? (mc as MovieClip).weapon : (mc as MovieClip).left_hand, g.canvas);
					node = null;
					if(type == MINION || type == PLAYER){
						if(Brain.monster_characters.length){
							node = Brain.monster_characters[(Math.random() * Brain.monster_characters.length) >> 0];
						}
					} else if(type == MONSTER){
						if(Brain.player_characters.length){
							node = Brain.player_characters[(Math.random() * Brain.player_characters.length) >> 0];
						}
					}
					if(!node || !node.active || node.x < rect.x + rect.width * 0.5){
						node = null;
						tx = g.renderer.width * SCALE;
						ty = Math.random() * g.renderer.height * SCALE;
					} else {
						tx = node.rect.x + node.rect.width * 0.5;
						ty = node.rect.y + node.rect.height * 0.5;
					}
					if(g.lightning.strike(g.fx_holder.graphics, g.block_map, p.x, p.y, tx, ty) && node && enemy(node)){
						node.applyDamage(Math.random(), "quickening");
						g.createDebrisSpurt(tx, ty, 5, 5, node.debris_type);
					}
					// lightning from the left hand
					p = localToLocal(p, mc.scaleX == 1 ? (mc as MovieClip).left_hand : (mc as MovieClip).weapon, g.canvas);
					node = null;
					if(type == MINION || type == PLAYER){
						if(Brain.monster_characters.length){
							node = Brain.monster_characters[(Math.random() * Brain.monster_characters.length) >> 0];
						}
					} else if(type == MONSTER){
						if(Brain.player_characters.length){
							node = Brain.player_characters[(Math.random() * Brain.player_characters.length) >> 0];
						}
					}
					if(!node || !node.active || node.x > rect.x + rect.width * 0.5){
						node = null;
						tx = 0;
						ty = Math.random() * g.renderer.height * SCALE;
					} else {
						tx = node.rect.x + node.rect.width * 0.5;
						ty = node.rect.y + node.rect.height * 0.5;
					}
					if(g.lightning.strike(g.fx_holder.graphics, g.block_map, p.x, p.y, tx, ty) && node && enemy(node)){
						node.applyDamage(Math.random(), "quickening");
						g.createDebrisSpurt(tx, ty, -5, 5, node.debris_type);
					}
				}
				if(quickening_count-- <= 0){
					state = FALLING;
					// getting some weird bug where the character is fabricating invisible floor after quickening
					// am trying to force this not to happen
					divorce();
					mc.transform.colorTransform = new ColorTransform();
					if(this is Player) g.console.print("welcome to level " + level + " " + nameToString());
				}
			} else if(state == EXIT){
				moving = true;
				if(stairs.type == Stairs.UP){
					dir = looking = LEFT;
					if(move_count == 0) vx = vy = 0;
					else{
						vx = -2;
						vy = -2;
					}
				} else if(stairs.type == Stairs.DOWN){
					dir = looking = RIGHT;
					if(move_count == 0) vx = vy = 0;
					else{
						vx = 2;
						vy = 2;
					}
				}
				
			} else if(state == ENTER){
				moving = true;
				if(stairs.type == Stairs.UP){
					dir = looking = RIGHT;
					if(move_count == 0) vx = vy = 0;
					else{
						vx = 2;
						vy = 2;
					}
					if(x >= rect.x + width * 0.5 && y >= rect.y + height * 0.5){
						state = FALLING;
						mc.mask = null;
						stairs.mask.parent.removeChild(stairs.mask);
						stairs = null;
						g.colliders.push(this);
					}
				} else if(stairs.type == Stairs.DOWN){
					dir = looking = LEFT;
					if(move_count == 0) vx = vy = 0;
					else{
						vx = -2;
						vy = -2;
					}
					if(x <= rect.x + width * 0.5 && y <= rect.y + height * 0.5){
						state = FALLING;
						mc.mask = null;
						stairs.mask.parent.removeChild(stairs.mask);
						stairs = null;
						g.colliders.push(this);
					}
				}
			}
			//trace(g.block_map[((rect.y + rect.height - 1) * INV_SCALE) >> 0][map_x] & Block.LADDER);
			//trace(map_x);
			
			if(attack_count < 1){
				attack_count += attack_speed;
			}
			if(crushed){
				death("crushing");
			}
			
			// will wake up the collider when moving
			if((vx > 0 ? vx : -vx) > TOLERANCE || (vy > 0 ? vy : -vy) > TOLERANCE) awake = AWAKE_DELAY;
		}
		
		/* Kill the Character, printing a cause to the console and generating a Head object
		 * on decapitation. Decapitation is meant to occur only via hand to hand combat */
		public function death(cause:String, decapitation:Boolean = false, aggressor:int = 0):void{
			active = false;
			g.createDebrisRect(rect, 0, 20, debris_type);
			var method:String = decapitation ? "decapitated" : CharacterAttributes.NAME_DEATH_STRINGS[name];
			if(decapitation){
				var head:Head = new Head(mc as MovieClip, total_health * 0.5, g);
			}
			g.console.print(CharacterAttributes.NAME_STRINGS[name] + " " + method + " by " + cause);
			//NitromeGame.sound_manager.playSound("aiiee");
			g.shake(0, 3);
			SoundManager.playSound(g.library.KillSound);
			if(type == MONSTER) g.player.addXP(xp_reward);
			if(effects) removeEffects();
		}
		/* Advances the character to the next level */
		public function levelUp():void{
			level++;
			health = CharacterAttributes.NAME_HEALTHS[name] + CharacterAttributes.NAME_HEALTH_LEVELS[name] * level;
			total_health = health;
			attack = CharacterAttributes.NAME_ATTACKS[name] + CharacterAttributes.NAME_ATTACK_LEVELS[name] * level;
			defense = CharacterAttributes.NAME_DEFENCES[name] + CharacterAttributes.NAME_DEFENCE_LEVELS[name] * level;
			attack_speed = CharacterAttributes.NAME_ATTACK_SPEEDS[name] + CharacterAttributes.NAME_ATTACK_SPEED_LEVELS[name] * level;
			damage = CharacterAttributes.NAME_DAMAGES[name] + CharacterAttributes.NAME_DAMAGE_LEVELS[name] * level;
			speed = CharacterAttributes.NAME_SPEEDS[name] + CharacterAttributes.NAME_SPEED_LEVELS[name] * level;
			xp_reward = CharacterAttributes.NAME_XP_REWARDS[name] + CharacterAttributes.NAME_XP_REWARD_LEVELS[name] * level;
			applyHealth(total_health);
			quicken();
		}
		/* This method kicks off a character's quickening state. Whilst a character quickens, they
		 * send out lightning bolts from their hands and float up to the ceiling */
		public function quicken():void{
			state = QUICKENING;
			dir = RIGHT;
			divorce();
			quickening_count = QUICKENING_DELAY;
		}
		
		/* Used to auto-center when climbing */
		public function centerOnTile():void{
			if(x > tile_center) vx = x - speed > tile_center ? -speed : tile_center - x;
			else if(x < tile_center) vx = x + speed < tile_center ? speed : tile_center - x;
		}
		
		/* Used for launching Characters across the screen when they've been hit a magic effect */
		public function throwCharacter(character:Character):void{
			character.state = THROWN;
			character.ignore |= Block.CHARACTER;
			if(dir & LEFT){
				dir &= ~LEFT;
				dir |= RIGHT;
			} else if(dir & RIGHT){
				dir &= ~RIGHT;
				dir |= LEFT;
			}
			state = ATTACK;
			attack_count = 0;
		}
		
		
		/* The logic to validate climbing is pretty convoluted so it resides in another method,
		 * this goes against all my normal programming style, but I can still inline this
		 * shit if I'm in a pinch */
		public function canClimb():Boolean{
			return ((block_map_type & Block.LADDER) ||
			(g.block_map[((rect.y + rect.height) * INV_SCALE) >> 0][map_x] & Block.LADDER)) &&
			rect.x + rect.width >= LADDER_LEFT + map_x * SCALE &&
			rect.x <= LADDER_RIGHT + map_x * SCALE;
		}
		
		/* This reactivates any buffered effects  */
		public function restoreEffects(): void{
			if(effects_buffer){
				for(var i:int = 0; i < effects_buffer.length; i++){
					effects_buffer[i].apply(this);
				}
				effects_buffer = null;
			}
		}
		
		/* This buffers effects while the characters sleeps out of range of the renderer */
		public function bufferEffects(): void{
			while(effects && effects.length){
				effects[0].dismiss(true);
			}
		}
		
		/* This deactivates all effects - used in the event of death */
		public function removeEffects(): void{
			while(effects && effects.length){
				effects[0].dismiss();
			}
		}
		
		/* Select an item as a weapon or armour */
		public function equip(item:Item):Item{
			if(item.type == Item.WEAPON){
				if(weapon) return null;
				weapon = item;
			}
			if(item.type == Item.ARMOUR){
				if(armour) return null;
				armour = item;
				if(item.effects){
					for(var i:int = 0; i < item.effects.length; i++){
						item.effects[i].apply(this);
					}
				}
			}
			item.state = Item.EQUIPPED;
			(mc as Sprite).addChild(item.mc);
			updateAnimState(mc as MovieClip);
			updateMC();
			return item;
		}
		/* Unselect item as equipped */
		public function unequip(item:Item):Item{
			if(item != armour && item != weapon) return null;
			var i:int;
			for(i = 0; i < (mc as MovieClip).numChildren; i++){
				if((mc as MovieClip).getChildAt(i) == item.mc){
					(mc as MovieClip).removeChildAt(i);
					break;
				}
			}
			item.state = Item.INVENTORY;
			if(item == armour){
				if(item.effects){
					for(i = 0; i < item.effects.length; i++){
						item.effects[i].dismiss();
					}
				}
				armour = null;
			}
			if(item == weapon) weapon = null;
			
			// hack:
			// The BlitCanvasClip armour needs the parent clip to stay invisible when worn,
			// so when we take invisible armour off...
			mc.visible = true;
			
			updateAnimState(mc as MovieClip);
			updateMC();
			return item;
		}
		/* Drops an item from the Character's loot */
		public function dropItem(item:Item):void{
			var n:int = loot.indexOf(item);
			if(n > -1) loot.splice(n, 1);
		}
		public function updateAnimState(mc:MovieClip):void {
			if ((looking & LEFT) && mc.scaleX != -1) mc.scaleX = -1;
			else if ((looking & RIGHT) && mc.scaleX != 1) mc.scaleX = 1;
				
			if(weapon && weapon.name == Item.BOW){
				(weapon.mc as MovieClip).gotoAndStop("idle");
			}
				
			if(state == WALKING && moving){
				if(move_frame){
					if(mc.currentLabel != "walk_1") mc.gotoAndStop("walk_1");
				} else {
					if(mc.currentLabel != "walk_0") mc.gotoAndStop("walk_0");
				}
			} else if(state == WALKING && !moving){
				if(mc.currentLabel != "idle") mc.gotoAndStop("idle");
			} else if(state == CLIMBING){
				if(move_frame){
					if(mc.currentLabel != "climb_1") mc.gotoAndStop("climb_1");
				} else {
					if(mc.currentLabel != "climb_0") mc.gotoAndStop("climb_0");
				}
			} else if(state == FALLING){
				if(mc.currentLabel != "jump") mc.gotoAndStop("jump");
			} else if(state == ATTACK){
				if(mc.currentLabel != "attack") mc.gotoAndStop("attack");
				
				if(weapon && weapon.name == Item.BOW){
					(weapon.mc as MovieClip).gotoAndStop("attack");
				}
			} else if(state == THROWN){
				if(mc.currentLabel != "thrown") mc.gotoAndStop("thrown");
			} else if(state == QUICKENING){
				if(mc.currentLabel != "quickening") mc.gotoAndStop("quickening");
			} else if(state == EXIT || state == ENTER){
				if(move_frame){
					if(mc.currentLabel != "walk_1") mc.gotoAndStop("walk_1");
				} else {
					if(mc.currentLabel != "walk_0") mc.gotoAndStop("walk_0");
				}
			}
		}
		/* Update collision Rect / Block around character */
		override public function updateRect():void{
			rect.x = x - width * 0.5;
			rect.y = y - height * 0.5;
			rect.width = width;
			rect.height = height;
		}
		
		
		/* Handles refreshing animation and the position the canvas */
		public function updateMC():void{
			mc.x = (x + 0.1) >> 0;
			mc.y = ((y + height * 0.5) + 0.1) >> 0;
			if(mc.alpha < 1){
				mc.alpha += 0.1;
			}
			if(weapon){
				if((mc as MovieClip).weapon){
					weapon.mc.x = (mc as MovieClip).weapon.x;
					weapon.mc.y = (mc as MovieClip).weapon.y;
					if(state == CLIMBING) weapon.mc.visible = false;
					else weapon.mc.visible = true;
				}
			}
			if(armour){
				if((mc as MovieClip).armour){
					armour.mc.x = (mc as MovieClip).armour.x;
					armour.mc.y = (mc as MovieClip).armour.y;
					if(armour.name == Item.INVISIBILITY){
						(armour.mc as BlitBackgroundClip).render();
					}
					if(state != EXIT && state != ENTER){
						if(armour.name == Item.BLOOD){
							(armour.mc as BloodClip).render();
						}
					}
					if(armour.name == Item.SKULL){
						(armour.mc as MovieClip).gotoAndStop((mc as MovieClip).currentLabel);
					}
				}
			}
			
		}
		
		/* Determine if we have hit another character */
		public function hit(character:Character):int{
			attack_count = 0;
			var attack_roll:Number = Math.random();
			if(attack_roll >= CRITICAL_HIT)
				return CRITICAL;
			else if(attack_roll <= CRITICAL_MISS)
				return MISS
			else if(attack + attack_roll + (weapon ? weapon.attack : 0) > character.defense + (character.armour ? character.armour.defense : 0))
				return HIT;
				
			return MISS;
		}
		
		/* Loose a missile, could be an arrow or a rune */
		public function shoot(name:int, effect:Effect = null):void{
			if(attack_count < 1) return;
			state = ATTACK;
			attack_count = 0;
			var missile_mc:DisplayObject;
			if(name == Missile.ARROW){
				missile_mc = new g.library.ArrowMC();
			} else if(name == Missile.RUNE){
				missile_mc = new g.library.ThrownRuneMC();
			}
			missile_mc.x = rect.x + rect.width * 0.5;
			missile_mc.y = rect.y + rect.height * 0.5;
			g.entities_holder.addChild(missile_mc);
			if(name == Missile.ARROW){
				SoundManager.playSound(g.library.BowShootSound);
			} else if(name == Missile.RUNE){
				SoundManager.playSound(g.library.ThrowSound);
			}
			var missile:Missile = new Missile(missile_mc, name, this, (looking & RIGHT) ? 1 : -1, 0, 5, g, missile_ignore, effect, weapon);
		}
		
		/* Adds damage to the Character */
		public function applyDamage(n:Number, source:String, critical:Boolean = false, aggressor:int = 0):void{
			// killing a character on a set of stairs could crash the game
			if(state == ENTER || state == EXIT || state == QUICKENING) return;
			health-= n;
			if(critical) g.shake(0, 5);
			if(health <= 0){
				death(source, critical, aggressor);
			}
		}
		
		public function applyHealth(n:Number):void{
			health += n;
			if(health > total_health) health = total_health;
		}
		
		public function applyWeaponEffects(item:Item):void{
			if(item.effects){
				for(var i:int = 0; i < item.effects.length; i++){
					item.effects[i].copy().apply(this);
				}
			}
		}
		
		public function enemy(character:Character):Boolean{
			if(type & (PLAYER | MINION)) return (character.type & (MONSTER | STONE)) > 0;
			else if(type & MONSTER) return (character.type & (PLAYER | MINION)) > 0;
			return false;
		}
		
		public function get damage_bonus():Number{
			return 0;
		}
		
		public function reskin(mc:DisplayObject, name:int, width:Number, height:Number):void{
			this.name = name;
			var holder:DisplayObjectContainer = this.mc.parent;
			this.mc.parent.removeChild(this.mc);
			holder.addChild(mc);
			y = rect.y + rect.height - height * 0.5;
			this.width = width;
			this.height = height;
			var str:String = (mc as MovieClip).currentLabel;
			this.mc = mc;
			if(weapon) (mc as Sprite).addChild(weapon.mc);
			if(armour) (mc as Sprite).addChild(armour.mc);
			updateRect();
			updateAnimState(mc as MovieClip);
			updateMC();
			(mc as MovieClip).gotoAndStop(str);
			debris_type = undead ? Game.BONE : Game.BLOOD;
			health = CharacterAttributes.NAME_HEALTHS[name] + CharacterAttributes.NAME_HEALTH_LEVELS[name] * level;
			total_health = health;
			attack = CharacterAttributes.NAME_ATTACKS[name] + CharacterAttributes.NAME_ATTACK_LEVELS[name] * level;
			defense = CharacterAttributes.NAME_DEFENCES[name] + CharacterAttributes.NAME_DEFENCE_LEVELS[name] * level;
			attack_speed = CharacterAttributes.NAME_ATTACK_SPEEDS[name] + CharacterAttributes.NAME_ATTACK_SPEED_LEVELS[name] * level;
			damage = CharacterAttributes.NAME_DAMAGES[name] + CharacterAttributes.NAME_DAMAGE_LEVELS[name] * level;
			speed = CharacterAttributes.NAME_SPEEDS[name] + CharacterAttributes.NAME_SPEED_LEVELS[name] * level;
			xp_reward = CharacterAttributes.NAME_XP_REWARDS[name] + CharacterAttributes.NAME_XP_REWARD_LEVELS[name] * level;
			applyHealth(total_health);
		}
		
		override public function nameToString():String {
			return CharacterAttributes.NAME_STRINGS[name];
		}
		
		override public function addChild(collider:Collider):void {
			super.addChild(collider);
			if(crushable && collider.inflicts_crush){
				if(collider.rect.x < rect.x + rect.width * 0.5 && collider.rect.x + collider.rect.width > rect.x + rect.width * 0.5){
					crushed = true;
				} else {
					// try to be lenient to the character by offering a dodge from the collision - seeing
					// as they are only clipping the crusher
					divorce();
					if(collider.rect.x + collider.rect.width < rect.x + rect.width * 0.5){
						moveX(collider.rect.x + collider.rect.width - rect.x);
					} else if(collider.rect.x > rect.x + rect.width * 0.5){
						moveX((rect.x + collider.rect.width) - collider.rect.x);
					}
					// did it work?
					if(collider.rect.x < rect.x + rect.width * 0.5 && collider.rect.x + collider.rect.width > rect.x + rect.width * 0.5){
						crushed = true;
					}
				}
			}
		}
		
		override public function remove():void {
			if(effects){
				bufferEffects();
			}
			super.remove();
		}
		
	}
	
}