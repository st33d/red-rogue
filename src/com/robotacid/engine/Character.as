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
		public var attackSpeed:Number;
		public var attackCount:Number;
		public var blockMapType:int;
		public var moveFrame:int;
		public var moveCount:int;
		public var quickeningCount:int;
		public var tileCenter:Number;
		public var victim:Character;
		public var stepNoise:Boolean;
		public var crushed:Boolean;
		public var undead:Boolean;
		public var inTheDark:Boolean;
		public var debrisType:int;
		public var missileIgnore:int;
		
		// attributes
		public var speed:Number;
		public var health:Number;
		public var totalHealth:Number;
		public var damage:Number;
		public var xpReward:Number;
		public var attack:Number;
		public var defense:Number;
		
		public var loot:Vector.<Item>;
		public var effects:Vector.<Effect>;
		public var effectsBuffer:Vector.<Effect>;
		public var stairs:Stairs;
		public var weapon:Item;
		public var armour:Item;
		
		private var hitResult:Number;
		
		// type flags
		public static const PLAYER:int = 1;
		public static const MONSTER:int = 1 << 1;
		public static const MINION:int = 1 << 2;
		public static const STONE:int = 1 << 3;
		
		// character names
		public static const ROGUE:int = 0;
		public static const SKELETON:int = 1;
		public static const KOBOLD:int = 2;
		public static const GOBLIN:int = 3;
		public static const ORC:int = 4;
		public static const TROLL:int = 5;
		
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
		
		public static const CRUSH_TOLERANCE:Number = 2;
		
		public static var p:Point = new Point();
		
		public function Character(mc:DisplayObject, name:int, type:int, level:int, width:int, height:int, g:Game, active:Boolean = false) {
			super(mc, width, height, g, active);
			
			this.name = name;
			this.level = level;
			this.type = type;
			
			health = CharacterAttributes.NAME_HEALTHS[name] + CharacterAttributes.NAME_HEALTH_LEVELS[name] * level;
			totalHealth = health;
			attack = CharacterAttributes.NAME_ATTACKS[name] + CharacterAttributes.NAME_ATTACK_LEVELS[name] * level;
			defense = CharacterAttributes.NAME_DEFENCES[name] + CharacterAttributes.NAME_DEFENCE_LEVELS[name] * level;
			attackSpeed = CharacterAttributes.NAME_ATTACK_SPEEDS[name] + CharacterAttributes.NAME_ATTACK_SPEED_LEVELS[name] * level;
			damage = CharacterAttributes.NAME_DAMAGES[name] + CharacterAttributes.NAME_DAMAGE_LEVELS[name] * level;
			speed = CharacterAttributes.NAME_SPEEDS[name] + CharacterAttributes.NAME_SPEED_LEVELS[name] * level;
			xpReward = CharacterAttributes.NAME_XP_REWARDS[name] + CharacterAttributes.NAME_XP_REWARD_LEVELS[name] * level;
			
			state = FALLING;
			stepNoise = false;
			attackCount = 1;
			vx = vy = 0;
			moving = false;
			moveCount = 0;
			moveFrame = 0;
			block.type |= Block.CHARACTER;
			blockMapType = 0;// g.blockMap[mapY][mapX];
			callMain = true;
			crushed = false;
			undead = name == SKELETON;
			debrisType = name == SKELETON ? Game.BONE : Game.BLOOD;
			inTheDark = false;
			missileIgnore = Block.LADDER | Block.LEDGE | Block.CORPSE;
			ignore |= Block.CORPSE;
			crushable = true;
			inflictsCrush = true;
			
			loot = new Vector.<Item>();
			addNameAbilities(name);
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
				if (parentBlock){
					checkFloor();
				}
				if(!parentBlock){
					vy = DAMPING_Y * vy + GRAVITY;
					moveY(vy, this);
				}
				if(!parentBlock){
					state = FALLING;
				} else {
					if(state == FALLING && stepNoise) SoundManager.playSound(g.library.ThudSound);
					state = WALKING;
				}
			} else if(state == CLIMBING){
				moveY(vy * DAMPING_Y, this);
			} else if(state == QUICKENING){
				moveY(vy);
			} else if(state == ATTACK){
				if (parentBlock){
					checkFloor();
				}
				if(!parentBlock){
					vy = DAMPING_Y * vy + GRAVITY;
					moveY(vy, this);
				}
			}
			// pace movement
			if(state == WALKING || state == CLIMBING || state == EXIT || state == ENTER){
				if(!moving) moveCount = 0;
				else {
					if(stepNoise && moving && moveCount == 0 && moveFrame == 0) SoundManager.playSound(g.library.StepsSound);
					moveCount = (moveCount + 1) % MOVE_DELAY;
					// flip between climb frames as we move
					if(moveCount == 0) moveFrame ^= 1;
				}
			}
			
			mapX = (rect.x + rect.width * 0.5) * INV_SCALE;
			mapY = (rect.y + rect.height * 0.5) * INV_SCALE;
			
			blockMapType = g.blockMap[mapY][mapX];
			
			// will put the collider to sleep if it doesn't move
			if((vx > 0 ? vx : -vx) < TOLERANCE && (vy > 0 ? vy : -vy) < TOLERANCE && (awake)) awake--;
		}
		
		override public function main():void{
			processActions();
			// lighting check - if the monster is in total darkness, we need not tend to their animation
			// and making them invisible will help the lighting engine conceal their presence.
			// however - if they are moving, they may "pop" in and out of darkness, so we check around them
			// for light
			if(light) inTheDark = false;
			else{
				if(dir == 0){
					if(g.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000) inTheDark = false;
					else inTheDark = true;
				} else if(dir & (RIGHT | LEFT)){
					if(g.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000 || g.lightMap.darkImage.getPixel32(mapX + 1, mapY) != 0xFF000000 || g.lightMap.darkImage.getPixel32(mapX - 1, mapY) != 0xFF000000) inTheDark = false;
					else inTheDark = true;
				} else if(dir & (UP | DOWN)){
					if(g.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000 || g.lightMap.darkImage.getPixel32(mapX, mapY + 1) != 0xFF000000 || g.lightMap.darkImage.getPixel32(mapX, mapY - 1) != 0xFF000000) inTheDark = false;
					else inTheDark = true;
				}
			}
			
			if(!inTheDark){
				mc.visible = true;
				updateAnimState(mc as MovieClip);
				updateMC();
			} else {
				mc.visible = false;
			}
			upCollider = rightCollider = downCollider = leftCollider = null;
			collisions = 0;
		}
		
		// This chunk is the core state machine for all Characters
		public function processActions():void{
			if(parentBlock != null) collisions |= Rect.DOWN;
			tileCenter = (mapX + 0.5) * SCALE;
			// react to direction state
			if(state == WALKING) moving = Boolean(dir & (LEFT | RIGHT));
			else if(state == CLIMBING) moving = Boolean(dir & (UP | DOWN));
			// moving left or right
			if(state == WALKING || state == FALLING){
				if(dir & RIGHT) vx += speed;
				else if(dir & LEFT) vx -= speed;
				// climbing
				if(dir & UP){
					if(canClimb() && !(parentBlock && (parentBlock.type & Block.LEDGE) && !(blockMapType & Block.LADDER))){
						state = CLIMBING;
						if (parent != null){
							parent.removeChild(this);
						}
						parent = null;
						parentBlock = null;
					}
				}
				// dropping through ledges and climbing down
				if(dir & DOWN){
					if(parentBlock && (parentBlock.type & Block.LEDGE)){
						awake = AWAKE_DELAY;
						ignore |= Block.LEDGE;
						vy = 0;
						if (parent != null){
							parent.removeChild(this);
						}
						parent = null;
						parentBlock = null;
						if(canClimb()) state = CLIMBING;
					}
				} else if(ignore & Block.LEDGE){
					ignore &= ~Block.LEDGE;
				}
			}
			// attacking
			if(state == WALKING){
				if(leftCollider || rightCollider){
					var target:Character = null;
					if((dir & LEFT) && leftCollider && leftCollider is Character && enemy(leftCollider as Character)){
						target = leftCollider as Character;
					} else if((dir & RIGHT) && rightCollider && rightCollider is Character && enemy(rightCollider as Character)){
						target = rightCollider as Character;
					}
					if(target){
						moving = false;
						if(attackCount >= 1 && (((dir & LEFT) && vx < 0) ||((dir & RIGHT) && vx > 0))){
							state = ATTACK;
							hitResult = hit(target);
							if(hitResult){
								if(!(target.type & STONE)) target.weight = 0;
								if(weapon && weapon.effects && target.active && !(target.type & STONE)){
									target.applyWeaponEffects(weapon);
								}
								target.applyDamage((damage + (weapon ? weapon.damage : 0)) * hitResult, nameToString(), hitResult > 1, type);
								SoundManager.playSound(g.library.HitSound);
								p = localToLocal(p, (mc as MovieClip).weapon, g.canvas);
								g.createDebrisSpurt(p.x, p.y, (dir & LEFT) ? -5 : 5, 5, target.debrisType);
							} else {
								SoundManager.playSound(g.library.MissSound);
							}
						}
						victim = target;
					}
				}
			} else if(state == ATTACK){
				if(attackCount > 0.5){
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
					if(parentBlock){
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
				var colTrans:ColorTransform = mc.transform.colorTransform;
				colTrans.redOffset+=4;
				colTrans.greenOffset+=4;
				colTrans.blueOffset+=4;
				mc.transform.colorTransform = colTrans;
				var node:Character;
				var tx:Number, ty:Number;
				// lightning from the right hand
				if((mc as MovieClip).weapon && (mc as MovieClip).leftHand){
					p = localToLocal(p, mc.scaleX == 1 ? (mc as MovieClip).weapon : (mc as MovieClip).leftHand, g.canvas);
					node = null;
					if(type == MINION || type == PLAYER){
						if(Brain.monsterCharacters.length){
							node = Brain.monsterCharacters[(Math.random() * Brain.monsterCharacters.length) >> 0];
						}
					} else if(type == MONSTER){
						if(Brain.playerCharacters.length){
							node = Brain.playerCharacters[(Math.random() * Brain.playerCharacters.length) >> 0];
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
					if(g.lightning.strike(g.fxHolder.graphics, g.blockMap, p.x, p.y, tx, ty) && node && enemy(node)){
						node.applyDamage(Math.random(), "quickening");
						g.createDebrisSpurt(tx, ty, 5, 5, node.debrisType);
					}
					// lightning from the left hand
					p = localToLocal(p, mc.scaleX == 1 ? (mc as MovieClip).leftHand : (mc as MovieClip).weapon, g.canvas);
					node = null;
					if(type == MINION || type == PLAYER){
						if(Brain.monsterCharacters.length){
							node = Brain.monsterCharacters[(Math.random() * Brain.monsterCharacters.length) >> 0];
						}
					} else if(type == MONSTER){
						if(Brain.playerCharacters.length){
							node = Brain.playerCharacters[(Math.random() * Brain.playerCharacters.length) >> 0];
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
					if(g.lightning.strike(g.fxHolder.graphics, g.blockMap, p.x, p.y, tx, ty) && node && enemy(node)){
						node.applyDamage(Math.random(), "quickening");
						g.createDebrisSpurt(tx, ty, -5, 5, node.debrisType);
					}
				}
				if(quickeningCount-- <= 0){
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
					if(moveCount == 0) vx = vy = 0;
					else{
						vx = -2;
						vy = -2;
					}
				} else if(stairs.type == Stairs.DOWN){
					dir = looking = RIGHT;
					if(moveCount == 0) vx = vy = 0;
					else{
						vx = 2;
						vy = 2;
					}
				}
				
			} else if(state == ENTER){
				moving = true;
				if(stairs.type == Stairs.UP){
					dir = looking = RIGHT;
					if(moveCount == 0) vx = vy = 0;
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
					if(moveCount == 0) vx = vy = 0;
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
			//trace(g.blockMap[((rect.y + rect.height - 1) * INV_SCALE) >> 0][mapX] & Block.LADDER);
			//trace(mapX);
			
			if(attackCount < 1){
				attackCount += attackSpeed;
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
			g.createDebrisRect(rect, 0, 20, debrisType);
			var method:String = decapitation ? "decapitated" : CharacterAttributes.NAME_DEATH_STRINGS[name];
			if(decapitation){
				var head:Head = new Head(mc as MovieClip, totalHealth * 0.5, g);
				var corpse:Corpse = new Corpse(this, g);
			}
			g.console.print(CharacterAttributes.NAME_STRINGS[name] + " " + method + " by " + cause);
			g.shake(0, 3);
			SoundManager.playSound(g.library.KillSound);
			if(type == MONSTER) g.player.addXP(xpReward);
			if(effects) removeEffects();
		}
		/* Advances the character to the next level */
		public function levelUp():void{
			level++;
			health = CharacterAttributes.NAME_HEALTHS[name] + CharacterAttributes.NAME_HEALTH_LEVELS[name] * level;
			totalHealth = health;
			attack = CharacterAttributes.NAME_ATTACKS[name] + CharacterAttributes.NAME_ATTACK_LEVELS[name] * level;
			defense = CharacterAttributes.NAME_DEFENCES[name] + CharacterAttributes.NAME_DEFENCE_LEVELS[name] * level;
			attackSpeed = CharacterAttributes.NAME_ATTACK_SPEEDS[name] + CharacterAttributes.NAME_ATTACK_SPEED_LEVELS[name] * level;
			damage = CharacterAttributes.NAME_DAMAGES[name] + CharacterAttributes.NAME_DAMAGE_LEVELS[name] * level;
			speed = CharacterAttributes.NAME_SPEEDS[name] + CharacterAttributes.NAME_SPEED_LEVELS[name] * level;
			xpReward = CharacterAttributes.NAME_XP_REWARDS[name] + CharacterAttributes.NAME_XP_REWARD_LEVELS[name] * level;
			applyHealth(totalHealth);
			quicken();
		}
		/* This method kicks off a character's quickening state. Whilst a character quickens, they
		 * send out lightning bolts from their hands and float up to the ceiling */
		public function quicken():void{
			state = QUICKENING;
			dir = RIGHT;
			divorce();
			quickeningCount = QUICKENING_DELAY;
		}
		
		/* Used to auto-center when climbing */
		public function centerOnTile():void{
			if(x > tileCenter) vx = x - speed > tileCenter ? -speed : tileCenter - x;
			else if(x < tileCenter) vx = x + speed < tileCenter ? speed : tileCenter - x;
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
			attackCount = 0;
		}
		
		
		/* The logic to validate climbing is pretty convoluted so it resides in another method,
		 * this goes against all my normal programming style, but I can still inline this
		 * shit if I'm in a pinch */
		public function canClimb():Boolean{
			return ((blockMapType & Block.LADDER) ||
			(g.blockMap[((rect.y + rect.height) * INV_SCALE) >> 0][mapX] & Block.LADDER)) &&
			rect.x + rect.width >= LADDER_LEFT + mapX * SCALE &&
			rect.x <= LADDER_RIGHT + mapX * SCALE;
		}
		
		/* This reactivates any buffered effects  */
		public function restoreEffects(): void{
			if(effectsBuffer){
				for(var i:int = 0; i < effectsBuffer.length; i++){
					effectsBuffer[i].apply(this);
				}
				effectsBuffer = null;
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
				if(moveFrame){
					if(mc.currentLabel != "walk_1") mc.gotoAndStop("walk_1");
				} else {
					if(mc.currentLabel != "walk_0") mc.gotoAndStop("walk_0");
				}
			} else if(state == WALKING && !moving){
				if(mc.currentLabel != "idle") mc.gotoAndStop("idle");
			} else if(state == CLIMBING){
				if(moveFrame){
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
				if(moveFrame){
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
		
		
		/* Positions the graphic */
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
			attackCount = 0;
			var attackRoll:Number = Math.random();
			if(attackRoll >= CRITICAL_HIT)
				return CRITICAL;
			else if(attackRoll <= CRITICAL_MISS)
				return MISS
			else if(attack + attackRoll + (weapon ? weapon.attack : 0) > character.defense + (character.armour ? character.armour.defense : 0))
				return HIT;
				
			return MISS;
		}
		
		/* Loose a missile, could be an arrow or a rune */
		public function shoot(name:int, effect:Effect = null):void{
			if(attackCount < 1) return;
			state = ATTACK;
			attackCount = 0;
			var missileMc:DisplayObject;
			if(name == Missile.ARROW){
				missileMc = new g.library.ArrowMC();
			} else if(name == Missile.RUNE){
				missileMc = new g.library.ThrownRuneMC();
			}
			missileMc.x = rect.x + rect.width * 0.5;
			missileMc.y = rect.y + rect.height * 0.5;
			g.entitiesHolder.addChild(missileMc);
			if(name == Missile.ARROW){
				SoundManager.playSound(g.library.BowShootSound);
			} else if(name == Missile.RUNE){
				SoundManager.playSound(g.library.ThrowSound);
			}
			var missile:Missile = new Missile(missileMc, name, this, (looking & RIGHT) ? 1 : -1, 0, 5, g, missileIgnore, effect, weapon);
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
			if(health > totalHealth) health = totalHealth;
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
		
		public function reskin(mc:DisplayObject, name:int, width:Number, height:Number):void{
			this.name = name;
			undead = name == SKELETON;
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
			debrisType = undead ? Game.BONE : Game.BLOOD;
			health = CharacterAttributes.NAME_HEALTHS[name] + CharacterAttributes.NAME_HEALTH_LEVELS[name] * level;
			totalHealth = health;
			attack = CharacterAttributes.NAME_ATTACKS[name] + CharacterAttributes.NAME_ATTACK_LEVELS[name] * level;
			defense = CharacterAttributes.NAME_DEFENCES[name] + CharacterAttributes.NAME_DEFENCE_LEVELS[name] * level;
			attackSpeed = CharacterAttributes.NAME_ATTACK_SPEEDS[name] + CharacterAttributes.NAME_ATTACK_SPEED_LEVELS[name] * level;
			damage = CharacterAttributes.NAME_DAMAGES[name] + CharacterAttributes.NAME_DAMAGE_LEVELS[name] * level;
			speed = CharacterAttributes.NAME_SPEEDS[name] + CharacterAttributes.NAME_SPEED_LEVELS[name] * level;
			xpReward = CharacterAttributes.NAME_XP_REWARDS[name] + CharacterAttributes.NAME_XP_REWARD_LEVELS[name] * level;
			removeNameAbilities(name);
			addNameAbilities(name);
			applyHealth(totalHealth);
		}
		
		public function addNameAbilities(n:int):void{
			if(n == TROLL){
				
			}
		}
		
		public function removeNameAbilities(n:int):void{
			
		}
		
		override public function toXML():XML {
			var xml:XML = <character />;
			xml.@name = name;
			xml.@type = type;
			xml.@level = level;
			xml.@health = health;
 			if(effects && effects.length){
				for(var i:int = 0; i < effects.length; i++){
					if(effects[i].source != Effect.ARMOUR){
						xml.appendChild(effects[i].toXML());
					}
				}
			}
			return xml;
		}
		
		override public function nameToString():String {
			return CharacterAttributes.NAME_STRINGS[name];
		}
		
		override public function addChild(collider:Collider):void {
			super.addChild(collider);
			if(crushable && collider.inflictsCrush && state != QUICKENING){
				// if the centers of both colliders are within crush tolerance range, then we execute
				// a crush death for the player or minon - for the other's we're less kind
				if(type == PLAYER || type == MINION){
					if(Math.abs(collider.x - x) < CRUSH_TOLERANCE){
						crushed = true;
					} else {
						// we try to be lenient to the character by offering a dodge from the collision - seeing
						// as they are only clipping the crusher
						divorce();
						if(collider.x > x){
							collider.moveX(1 + vx + ((rect.x + rect.width) - collider.rect.x));
						} else if(collider.x < x){
							collider.moveX(-1 + vx + (rect.x - (collider.rect.x + collider.rect.width)));
						}
						// did it work? is the offending collider free from contact?
						if(!(rect.x > collider.rect.x + (collider.rect.width - 1) || rect.x + (rect.width - 1) < collider.rect.x)){
							crushed = true;
						}
					}
				} else {
					crushed = true;
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