package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.ai.PlayerBrain;
	import com.robotacid.level.Map;
	import com.robotacid.gfx.ItemMovieClip;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.level.Surface;
	import com.robotacid.phys.Collider;
	import com.robotacid.phys.FilterCollider;
	import com.robotacid.phys.Force;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.menu.QuestMenuOption;
	import com.robotacid.util.clips.localToLocal;
	import com.robotacid.util.HiddenInt;
	import com.robotacid.util.HiddenNumber;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * This is the base class for all creatures in the game - including the player.
	 *
	 * By levelling the playing field we get creatures that behave like the player -
	 * and as a bonus the player can transform into them with magic
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Character extends ColliderEntity{
		
		public var loot:Vector.<Item>;
		public var effects:Vector.<Effect>;
		public var effectsBuffer:Vector.<Effect>;
		public var portal:Portal;
		public var weapon:Item;
		public var throwable:Item;
		public var armour:Item;
		public var brain:Brain;
		public var racialEffect:Effect;
		public var questVictim:Boolean;
		
		// states
		public var level:int;
		public var type:int
		public var state:int;
		public var nameStr:String;
		public var uniqueNameStr:String;
		public var dir:int;
		public var looking:int;
		public var actions:int;
		public var moving:Boolean;
		public var attackCount:Number;
		public var stunCount:Number;
		public var mapProperties:int;
		public var moveFrame:int;
		public var moveCount:int;
		public var quickeningCount:int;
		public var tileCenter:Number;
		public var victim:Character;
		public var stepNoise:Boolean;
		public var stepSound:int;
		public var inTheDark:Boolean;
		public var debrisType:int;
		public var missileIgnore:int;
		public var infravisionRenderState:int;
		public var characterNum:int;
		public var missileFilter:int;
		public var quickenQueued:Boolean;
		public var canJump:Boolean;
		public var voice:Array;
		public var asleep:Boolean;
		public var resurrect:Boolean;
		public var lungeState:int;
		public var twinkleCount:int;
		public var bannerGfx:MovieClip;
		public var stomping:Boolean;
		public var equipmentGfxLayerUpdateCount:int;
		
		// stats
		public var speed:Number;
		public var speedModifier:Number;
		public var attackSpeed:Number;
		public var attackSpeedModifier:Number;
		public var health:Number;
		public var totalHealth:Number;
		public var damage:Number;
		public var xpReward:Number;
		public var attack:Number;
		public var defence:Number;
		public var stun:Number;
		public var knockback:Number;
		public var endurance:Number;
		public var infravision:int;
		public var leech:Number;
		public var thorns:Number;
		public var indifferent:Boolean;
		public var losBorder:Number;
		public var specialAttack:Boolean;
		public var undead:Boolean;
		public var protectionModifier:Number;
		public var bravery:Number;
		public var smiteDamage:Number;
		public var rank:int;
		
		private var hitResult:int;
		
		// type flags - do not refactor from bitwise, the AI checks for (PLAYER | MINION)
		public static const PLAYER:int = 1;
		public static const MONSTER:int = 1 << 1;
		public static const MINION:int = 1 << 2;
		public static const STONE:int = 1 << 3;
		public static const HORROR:int = 1 << 4;
		public static const GATE:int = 1 << 5;
		
		// character names
		public static const ROGUE:int = 0;
		public static const KOBOLD:int = 1;
		public static const GOBLIN:int = 2;
		public static const ORC:int = 3;
		public static const TROLL:int = 4;
		public static const GNOLL:int = 5;
		public static const DROW:int = 6;
		public static const CACTUAR:int = 7;
		public static const NYMPH:int = 8;
		public static const VAMPIRE:int = 9;
		public static const WEREWOLF:int = 10;
		public static const MIMIC:int = 11;
		public static const NAGA:int = 12;
		public static const GORGON:int = 13;
		public static const UMBER_HULK:int = 14;
		public static const GOLEM:int = 15;
		public static const BANSHEE:int = 16;
		public static const WRAITH:int = 17;
		public static const MIND_FLAYER:int = 18;
		public static const RAKSHASA:int = 19;
		public static const BALROG:int = 20;
		public static const SKELETON:int = 21;
		public static const HUSBAND:int = 22;
		
		// states
		public static const WALKING:int = 1;
		public static const LUNGING:int = 2;
		public static const QUICKENING:int = 3;
		public static const EXITING:int = 4;
		public static const ENTERING:int = 5;
		public static const STUNNED:int = 6;
		public static const SMITED:int = 7;
		
		// ranks
		public static const NORMAL:int = 0;
		public static const CHAMPION:int = 1;
		public static const ELITE:int = 2;
		
		// directions - from com.robotacid.phys.Collider
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		// hit flags
		public static const MISS:int = 0;
		public static const HIT:int = 1 << 0;
		public static const CRITICAL:int = 1 << 1;
		public static const STUN:int = 1 << 2;
		
		// lunge states
		public static const LUNGE_FORWARD:int = 0;
		public static const LUNGE_BACK:int = 1;
		
		// based on debris type order
		public static const HIT_SOUNDS:Array = [
			["bloodHit1", "bloodHit2", "bloodHit3", "bloodHit4"],
			["boneHit1", "boneHit2", "boneHit3", "boneHit4"],
			["stoneHit1", "stoneHit2", "stoneHit3", "stoneHit4"]
		];
		public static const QUICKENING_SOUNDS:Array = ["quickening1", "quickening2", "quickening3"];
		
		public static const STEP_SOUNDS:Array = [
			["floorStep1", "floorStep2"],
			["ladderStep1", "ladderStep2"]
		];
		
		public static const SMITE_SOUNDS:Array = ["star1", "star2", "star3", "star4"];
		public static const STUN_SOUNDS:Array = ["stun1", "stun2", "stun3"];
		
		public static const FLOOR_STEP_SOUND:int = 0;
		public static const LADDER_STEP_SOUND:int = 1;
		
		// physics constants
		public static const GRAVITY:Number = 0.8;
		public static const DAMPING_Y:Number = 0.99;
		public static const DAMPING_X:Number = 0.45;
		public static const THROW_SPEED:Number = 16;
		
		public static const LADDER_WIDTH:Number = 10;
		public static const LADDER_RIGHT:Number = 12;
		public static const LADDER_LEFT:Number = 3;
		
		public static const PORTAL_STEPS:int = 8;
		public static const STAIRS_SPEED:Number = 2;
		public static const PORTAL_DISTANCE:Number = STAIRS_SPEED * PORTAL_STEPS;
		
		public static const MOVE_DELAY:int = 3;
		public static const CRITICAL_HIT:Number = 0.94;
		public static const CRITICAL_MISS:Number = 0.05;
		public static const QUICKENING_DELAY:int = 90;
		public static const STUN_DECAY:Number = 1.0 / 90; // The denominator is maximum duration of stun in frames
		public static const SPECIAL_ATTACK_PER_LEVEL:Number = 1.0 / 40;
		public static const MAX_SPEED_MODIFIER:Number = 2;
		public static const MIN_SPEED_MODIFIER:Number = 0.5;
		public static const MIN_PROTECTION_MODIFIER:Number = 0.5;
		public static const SMITED_SPEED:Number = 8;
		public static const SMITE_DAMAGE_RATIO:Number = 1.5;
		public static const SMITE_PER_LEVEL:Number = 0.05;
		public static const QUICKENING_PER_LEVEL:Number = 0.5;
		public static const JUMP_VELOCITY:Number = -7;
		public static const KNOCKBACK_DAMPING:Number = 0.6;
		public static const KNOCKBACK_DIST:Number = 16;
		
		public static const DEFAULT_COL:ColorTransform = new ColorTransform();
		public static const INFRAVISION_COLS:Vector.<ColorTransform> = Vector.<ColorTransform>([DEFAULT_COL, new ColorTransform(1, 0, 0, 1, 255), new ColorTransform(1, 0.7, 0.7, 1, 50)]);
		public static const QUEST_VICTIM_FILTER:GlowFilter = new GlowFilter(0xAA0000, 0.5, 2, 2, 1000);
		
		public static var tent:MovieClip = new TentMC;
		
		public static var p:Point = new Point();
		
		/* Characters require a unique id to identify them in circumstances such as quests */
		public static var characterNumCount:int = 0;
		
		[Embed(source = "characterStats.json", mimeType = "application/octet-stream")] public static var statsData:Class;
		public static var stats:Object;
		
		public function Character(gfx:DisplayObject, x:Number, y:Number, name:int, type:int, level:int, addToEntities:Boolean = true) {
			super(gfx, addToEntities);
			
			this.name = name;
			this.level = level;
			this.type = type;
			
			createCollider(x, y, Collider.CHARACTER | Collider.SOLID, Collider.CORPSE | Collider.ITEM);
			
			state = WALKING;
			stepNoise = false;
			attackCount = 1;
			moving = false;
			moveCount = 0;
			moveFrame = 0;
			mapProperties = 0;
			stunCount = 0;
			callMain = true;
			inTheDark = false;
			quickenQueued = false;
			missileIgnore = Collider.LADDER | Collider.LEDGE | Collider.CORPSE | Collider.ITEM | Collider.HEAD | Collider.HORROR;
			uniqueNameStr = null;
			canJump = false;
			asleep = false;
			resurrect = false;
			
			setStats();
			
			loot = new Vector.<Item>();
		}
		
		/* Initialise a character's abilities and statistics */
		public function setStats():void{
			var i:int, effect:Effect;
			// the character's equipment needs to be removed whilst stats are applied
			var weaponTemp:Item, armourTemp:Item, throwableTemp:Item;
			if(weapon) weaponTemp = unequip(weapon);
			if(armour) armourTemp = unequip(armour);
			if(throwable) throwableTemp = unequip(throwable);
			
			nameStr = stats["names"][name];
			health = stats["healths"][name] + stats["health levels"][name] * level;
			if(rank != NORMAL){
				if(rank == CHAMPION){
					health *= 2.5;
					createUniqueNameStr();
				} else if(rank == ELITE){
					health *= 4;
					uniqueNameStr = stats["elite names"][name];
				}
			}
			totalHealth = health;
			attack = stats["attacks"][name] + stats["attack levels"][name] * level;
			defence = stats["defences"][name] + stats["defence levels"][name] * level;
			attackSpeed = stats["attack speeds"][name] + stats["attack speed levels"][name] * level;
			damage = stats["damages"][name] + stats["damage levels"][name] * level;
			speed = stats["speeds"][name] + stats["speed levels"][name] * level;
			stun = stats["stuns"][name];
			knockback = stats["knockbacks"][name] * KNOCKBACK_DIST;
			endurance = stats["endurances"][name];
			undead = stats["undeads"][name] == 1;
			if(rank == ELITE && name == GNOLL) undead = true;
			bravery = stats["braveries"][name];
			voice = stats["voices"][name];
			debrisType = Renderer.BLOOD;
			losBorder = Brain.DEFAULT_LOS_BORDER;
			speedModifier = 1;
			attackSpeedModifier = 1;
			protectionModifier = 1;
			
			// this is calculated by the Content class or the object generating the monster
			xpReward = 0;
			
			// racial modifications
			if(name == SKELETON){
				debrisType = Renderer.BONE;
			} else if(name == GOLEM && rank != ELITE){
				debrisType = Renderer.STONE;
			}
			if(name == DROW){
				setInfravision(1);
			} else {
				setInfravision(0);
			}
			if(name == VAMPIRE){
				leech = Effect.LEECH_PER_LEVEL * level;
			} else {
				leech = 0;
			}
			if(name == CACTUAR){
				thorns = Effect.THORNS_PER_LEVEL * level;
			} else {
				thorns = 0;
			}
			if(name == KOBOLD && level){
				// kobolds have chaotic stat bonuses
				if(rank != ELITE){
					health += stats["health levels"][name] * level * game.random.value();
					totalHealth = health;
					attack += stats["attack levels"][name] * level * game.random.value();
					defence += stats["defence levels"][name] * level * game.random.value();
					attackSpeed += stats["attack speed levels"][name] * level * game.random.value();
					damage += stats["damage levels"][name] * level * game.random.value();
					speed += stats["speed levels"][name] * level * game.random.value();
				// the elite character pun pun has max stats
				} else {
					health += stats["health levels"][name] * level;
					totalHealth = health;
					attack += stats["attack levels"][name] * level;
					defence += stats["defence levels"][name] * level;
					attackSpeed += stats["attack speed levels"][name] * level;
					damage += stats["damage levels"][name] * level;
					speed += stats["speed levels"][name] * level;
				}
			}
			
			// reapply effects
			if(effects){
				for(i = 0; i < effects.length; i++){
					effect = effects[i];
					if(effect.name == Effect.THORNS){
						thorns += Effect.THORNS_PER_LEVEL * effect.level;
						
					} else if(effect.name == Effect.SLOW){
						speedModifier -= Effect.SLOW_PER_LEVEL * effect.level;
						attackSpeedModifier -= Effect.SLOW_PER_LEVEL * effect.level;
						
					} else if(effect.name == Effect.HASTE){
						speedModifier += Effect.HASTE_PER_LEVEL * effect.level;
						attackSpeedModifier += Effect.HASTE_PER_LEVEL * effect.level;
						
					} else if(effect.name == Effect.PROTECTION){
						endurance += Effect.PROTECTION_PER_LEVEL * effect.level;
						protectionModifier -= Effect.PROTECTION_PER_LEVEL * effect.level;
						
					// UNDEAD runs as an active effect only when undead
					} else if(effect.name == Effect.UNDEAD){
						if(undead){
							if(game.effects.indexOf(this) == -1) game.effects.push(effect);
						} else {
							var effectIndex:int = game.effects.indexOf(this);
							if(effectIndex > -1) game.effects.splice(effectIndex, 1);
						}
					}
				}
			}
			
			if(name == TROLL){
				racialEffect = new Effect(Effect.HEAL, rank == ELITE ? Game.MAX_LEVEL : level, Effect.ARMOUR, this, 0, true, false);
			} else if(name == WEREWOLF){
				racialEffect = new Effect(Effect.STUN, level, Effect.ARMOUR, this, 0, true, false);
			} else if(rank == ELITE){
				if(name == DROW || name == GOLEM){
					racialEffect = new Effect(Effect.HEAL, level, Effect.ARMOUR, this, 0, true, false);
				} else if(name == MIMIC){
					racialEffect = new Effect(Effect.TELEPORT, level, Effect.ARMOUR, this, 0, true, false);
				} else if(name == BALROG){
					racialEffect = new Effect(Effect.HEAL, UserData.settings.ascended ? 2 : 1, Effect.ARMOUR, this, 0, true, false);
				}
			} else {
				racialEffect = null;
			}
			
			specialAttack =
				name == NYMPH ||
				name == WEREWOLF ||
				name == MIMIC ||
				name == NAGA ||
				name == GORGON ||
				name == UMBER_HULK ||
				name == BANSHEE ||
				name == MIND_FLAYER ||
				name == RAKSHASA ||
				(rank == ELITE && (
					name == CACTUAR ||
					name == WRAITH
				));
			
			indifferent = false;
			
			// re-equip
			if(weaponTemp) equip(weaponTemp);
			if(armourTemp) equip(armourTemp);
			if(throwableTemp) equip(throwableTemp, true);
		}
		
		override public function createCollider(x:Number, y:Number, properties:int, ignoreProperties:int, state:int = 0, positionByBase:Boolean = true):void {
			// characters are thinner than their graphics, so we have to read their widths from the stats
			var bounds:Rectangle = gfx.getBounds(gfx);
			var w:Number = stats["widths"][name];
			// wraiths can wall walk
			if(name == WRAITH || (rank == ELITE && name == Character.BANSHEE)){
				collider = new FilterCollider(x - w * 0.5, y - bounds.height, w, bounds.height, Game.SCALE, properties, ignoreProperties, state);
				(collider as FilterCollider).setFilter(Collider.WALL, Collider.WALL | Collider.UP | Collider.DOWN, Collider.MAP_EDGE);
			} else {
				collider = new Collider(x - w * 0.5, y - bounds.height, w, bounds.height, Game.SCALE, properties, ignoreProperties, state);
			}
			collider.userData = this;
			mapX = (collider.x + collider.width * 0.5) * Game.INV_SCALE;
			mapY = (collider.y + collider.height * 0.5) * Game.INV_SCALE;
			
			if(!(type & STONE)){
				collider.stompCallback = stompCallback;
				collider.stackCallback = hitFloor;
			}
		}
		
		protected function hitFloor():void{
			if(stomping){
				renderer.addFX(collider.x + collider.width * 0.5, 1 + (collider.y + collider.height + 0.5) >> 0, renderer.stunShockBlit);
				stomping = false;
				game.createDistSound(mapX, mapY, "stunHit", SMITE_SOUNDS, 10);
			}
		}
		
		override public function main():void{
			
			move();
			if(!active) return;
			
			// any passive effects a race enjoys are updated with the racialEffect object
			if(racialEffect){
				racialEffect.main();
			}
			
			// lighting check - if the monster is in total darkness, we need not tend to their animation
			// and making them invisible will help the lighting engine conceal their presence.
			// however - if they are moving, they may "pop" in and out of darkness, so we check around them
			// for light
			if(light || game.map.type == Map.AREA) inTheDark = false;
			else{
				if(dir == 0){
					if(game.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000) inTheDark = false;
					else inTheDark = true;
				} else if(dir & (RIGHT | LEFT)){
					if(game.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000 || game.lightMap.darkImage.getPixel32(mapX + 1, mapY) != 0xFF000000 || game.lightMap.darkImage.getPixel32(mapX - 1, mapY) != 0xFF000000) inTheDark = false;
					else inTheDark = true;
				} else if(dir & (UP | DOWN)){
					if(game.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000 || game.lightMap.darkImage.getPixel32(mapX, mapY + 1) != 0xFF000000 || game.lightMap.darkImage.getPixel32(mapX, mapY - 1) != 0xFF000000) inTheDark = false;
					else inTheDark = true;
				}
			}
			
			// set visibility - account for player infravision and changes to their infravision
			// this is handled here instead of at the rendering stage to save us the cost of the method call
			// to get into the rendering method
			gfx.visible = !inTheDark || (game.player.infravision);
			var targetInfravisionRenderState:int = !inTheDark ? 0 : game.player.infravision;
			if(infravisionRenderState != targetInfravisionRenderState){
				gfx.transform.colorTransform = INFRAVISION_COLS[targetInfravisionRenderState];
				infravisionRenderState = targetInfravisionRenderState;
			}
		}
		
		// This chunk is the core state machine for all Characters
		protected function move():void{
			
			var mc:MovieClip = gfx as MovieClip;
			var target:Character = null;
			
			var moveSpeedTemp:Number = speedModifier;
			if(moveSpeedTemp < MIN_SPEED_MODIFIER) moveSpeedTemp = MIN_SPEED_MODIFIER;
			if(moveSpeedTemp > MAX_SPEED_MODIFIER) moveSpeedTemp = MAX_SPEED_MODIFIER;
			
			// is the character queued to quicken?
			if(quickenQueued && !asleep && (state == WALKING || state == LUNGING || state == STUNNED)){
				quicken();
			}
			
			// react to direction state
			if(state == WALKING){
				if(collider.state == Collider.STACK || collider.state == Collider.FALL) moving = Boolean(dir & (LEFT | RIGHT));
				else if(collider.state == Collider.HOVER) moving = Boolean(dir & (UP | DOWN));
				
				// moving left or right
				if(dir & RIGHT) collider.vx += speed * moveSpeedTemp;
				else if(dir & LEFT) collider.vx -= speed * moveSpeedTemp;
				// climbing
				if(dir & UP){
					if(canClimb() && !(collider.parent && (collider.parent.properties & Collider.LEDGE) && !(mapProperties & Collider.LADDER))){
						collider.divorce();
						collider.state = Collider.HOVER;
					}
				}
				// dropping through ledges and climbing down
				if(dir & DOWN){
					if(collider.parent && (collider.parent.properties & Collider.LEDGE)){
						collider.ignoreProperties |= Collider.LEDGE;
						collider.divorce();
						if(canClimb()){
							collider.state = Collider.HOVER;
						}
					}
				} else if(collider.ignoreProperties & Collider.LEDGE){
					collider.ignoreProperties &= ~Collider.LEDGE;
				}
				
				// COMBAT =====================================================================================
				
				if(collider.state == Collider.STACK || collider.state == Collider.FALL && !indifferent){
					if(collider.leftContact || collider.rightContact){
						if((dir & LEFT) && collider.leftContact && (collider.leftContact.properties & Collider.CHARACTER) && enemy(collider.leftContact.userData)){
							target = collider.leftContact.userData as Character;
						} else if((dir & RIGHT) && collider.rightContact && (collider.rightContact.properties & Collider.CHARACTER) && enemy(collider.rightContact.userData)){
							target = collider.rightContact.userData as Character;
						}
						if(target){
							moving = false;
							if(attackCount >= 1){
								meleeAttack(target);
							}
						}
					}
					
				// character is using a ladder
				} else if(collider.state == Collider.HOVER){
					if(canClimb()){
						// a character always tries to center itself on a ladder
						if((dir & UP)){
							collider.vy = -speed * moveSpeedTemp;
							centerOnTile();
						} else if(dir & DOWN){
							collider.vy = speed * moveSpeedTemp;
							centerOnTile();
						} else if(dir & (RIGHT | LEFT)){
							collider.state = Collider.FALL;
						} else {
							collider.vy = 0;
						}
						if(collider.parent){
							dir &= ~(UP | DOWN);
						}
					} else {
						collider.state = Collider.FALL;
						dir &= ~(UP | DOWN);
						collider.vy = 0;
					}
				}
			} else if(state == STUNNED){
				stunCount -= STUN_DECAY;
				if(stunCount <= 0){
					state = WALKING;
				}
			} else if(state == SMITED){
				if(looking & RIGHT) collider.vx -= SMITED_SPEED;
				else if(looking & LEFT) collider.vx += SMITED_SPEED;
				
				// hitting a surface deals damage to the smitee and knocks them out of the SMITED state
				if(
					(collider.pressure & (UP | DOWN)) ||
					((looking & RIGHT) && (collider.pressure & LEFT)) ||
					((looking & LEFT) && (collider.pressure & RIGHT))
				){
					applyDamage(smiteDamage, "smite", 0, true);
					state = WALKING;
					collider.state = Collider.FALL;
					collider.divorce();
					renderer.createDebrisSpurt(collider.x + collider.width * 0.5, collider.y + collider.height * 0.5, (looking & RIGHT) ? 2 : -2, 8, debrisType);
				}
				
			} else if(state == LUNGING){
				if(attackCount > 0.5){
					// check for whirlwind attack
					if(throwable && (dir & (LEFT | RIGHT))){
						var enemiesBehind:Vector.<Collider>;
						if(
							(lungeState == LUNGE_FORWARD && (dir & RIGHT)) ||
							(lungeState == LUNGE_BACK && (dir & LEFT))
						){
							enemiesBehind = game.world.getCollidersIn(new Rectangle(collider.x - moveSpeedTemp, collider.y, moveSpeedTemp, collider.height), collider, Collider.CHARACTER, missileIgnore | Collider.GATE | Collider.STONE);
						} else if(
							(lungeState == LUNGE_FORWARD && (dir & LEFT)) ||
							(lungeState == LUNGE_BACK && (dir & RIGHT))
						){
							enemiesBehind = game.world.getCollidersIn(new Rectangle(collider.x + collider.width, collider.y, moveSpeedTemp, collider.height), collider, Collider.CHARACTER, missileIgnore | Collider.GATE | Collider.STONE);
						}
						if(enemiesBehind.length){
							target = enemiesBehind[0].userData as Character;
							if(!enemy(target)) target = null;
						}
					}
					if(target){
						lungeState = lungeState == LUNGE_FORWARD ? LUNGE_BACK : LUNGE_FORWARD;
						equipmentGfxLayerUpdateCount = game.frameCount;
						meleeAttack(target);
					} else {
						state = WALKING;
						if(lungeState != LUNGE_FORWARD){
							lungeState = LUNGE_FORWARD;
							equipmentGfxLayerUpdateCount = game.frameCount;
						}
					}
				}
			} else if(state == QUICKENING){
				collider.vy = -1.5;
				var colTrans:ColorTransform = gfx.transform.colorTransform;
				colTrans.redOffset += 4;
				colTrans.greenOffset += 4;
				colTrans.blueOffset += 4;
				gfx.transform.colorTransform = colTrans;
				var node:Character;
				var tx:Number, ty:Number;
				// lightning from the right hand
				if(mc.weapon && mc.throwable) {
					p.x = mc.x + (mc.scaleX == 1 ? mc.weapon.x : -mc.throwable.x);
					p.y = mc.y + mc.weapon.y;
					node = null;
					if(type == MINION || type == PLAYER){
						if(Brain.monsterCharacters.length){
							node = Brain.monsterCharacters[game.random.rangeInt(Brain.monsterCharacters.length)];
						}
					} else if(type == MONSTER){
						if(Brain.playerCharacters.length){
							node = Brain.playerCharacters[game.random.rangeInt(Brain.playerCharacters.length)];
						}
					}
					if(!node || !node.active || node.state == QUICKENING || node.state == ENTERING || node.state == EXITING || node.indifferent || node.collider.x + node.collider.width * 0.5 < collider.x + collider.width * 0.5){
						node = null;
						tx = game.mapTileManager.width * SCALE;
						ty = game.random.range(game.mapTileManager.height) * SCALE;
					} else {
						tx = node.collider.x + node.collider.width * 0.5;
						ty = node.collider.y + node.collider.height * 0.5;
					}
					if(game.lightning.strike(renderer.lightningShape.graphics, game.world.map, p.x, p.y, tx, ty) && node && enemy(node.collider.userData)){
						node.applyDamage(
							game.random.value() * QUICKENING_PER_LEVEL * level * (node.name == BALROG ? 0.5 : 1),
							"quickening"
						);
						if(node.brain) node.brain.flee(this);
						renderer.createDebrisSpurt(tx, ty, 5, 5, node.debrisType);
					}
					// lightning from the left hand
					p.x = mc.x + (mc.scaleX == 1 ? mc.throwable.x : -mc.weapon.x);
					p.y = mc.y + mc.throwable.y;
					node = null;
					if(type == MINION || type == PLAYER){
						if(Brain.monsterCharacters.length){
							node = Brain.monsterCharacters[game.random.rangeInt(Brain.monsterCharacters.length)];
						}
					} else if(type == MONSTER){
						if(Brain.playerCharacters.length){
							node = Brain.playerCharacters[game.random.rangeInt(Brain.playerCharacters.length)];
						}
					}
					if(!node || !node.active || node.state == QUICKENING || node.state == ENTERING || node.state == EXITING || node.indifferent || node.collider.x + node.collider.width * 0.5 > collider.x + collider.width * 0.5){
						node = null;
						tx = 0;
						ty = game.random.range(game.mapTileManager.height) * SCALE;
					} else {
						tx = node.collider.x + node.collider.width * 0.5;
						ty = node.collider.y + node.collider.height * 0.5;
					}
					if(game.lightning.strike(renderer.lightningShape.graphics, game.world.map, p.x, p.y, tx, ty) && node && enemy(node.collider.userData)){
						node.applyDamage(
							game.random.value() * QUICKENING_PER_LEVEL * level * (node.name == BALROG ? 0.5 : 1),
							"quickening"
						);
						if(node.brain) node.brain.flee(this);
						renderer.createDebrisSpurt(tx, ty, -5, 5, node.debrisType);
					}
				}
				if(quickeningCount-- <= 0){
					finishQuicken();
				}
			} else if(state == ENTERING){
				moving = true;
				if(portal.type == Portal.STAIRS){
					if(portal.targetLevel < game.map.level){
						if(moveCount){
							if(dir == RIGHT) gfx.x += STAIRS_SPEED;
							else if(dir == LEFT) gfx.x -= STAIRS_SPEED;
							gfx.y += STAIRS_SPEED;
						}
						if(gfx.y >= (portal.mapY + 1) * Game.SCALE) portal = null;
					} else if(portal.targetLevel > game.map.level){
						if(moveCount){
							if(dir == RIGHT) gfx.x += STAIRS_SPEED;
							else if(dir == LEFT) gfx.x -= STAIRS_SPEED;
							gfx.y -= STAIRS_SPEED;
						}
						if(gfx.y <= (portal.mapY + 1) * Game.SCALE) portal = null;
					}
				} else {
					// movement through a portal
					if(dir == RIGHT){
						gfx.x += speed * collider.dampingX;
						if(gfx.x > (portal.mapX + 0.5) * Game.SCALE) portal = null;
					} else if(dir == LEFT){
						gfx.x -= speed * collider.dampingX;
						if(gfx.x < (portal.mapX + 0.5) * Game.SCALE) portal = null;
					}
				}
				if(!portal){
					game.world.restoreCollider(collider);
					collider.state = Collider.FALL;
					state = WALKING;
				}
			}
			//trace(game.blockMap[((rect.y + rect.height - 1) * INV_SCALE) >> 0][mapX] & Block.LADDER);
			//trace(mapX);
			
			if(attackCount < 1){
				var attackSpeedTemp:Number = attackSpeedModifier;
				if(attackSpeedTemp < MIN_SPEED_MODIFIER) attackSpeedTemp = MIN_SPEED_MODIFIER;
				if(attackSpeedTemp > MAX_SPEED_MODIFIER) attackSpeedTemp = MAX_SPEED_MODIFIER;
				attackCount += attackSpeed * attackSpeedTemp;
			}
			if(dir) collider.awake = Collider.AWAKE_DELAY;
		}
		
		/* Handles all the logic for a single melee attack */
		protected function meleeAttack(target:Character):void{
			attackCount = 0;
			hitResult = hit(target, Item.MELEE);
			if(hitResult){
				var mc:MovieClip = gfx as MovieClip;
				var item:Item = lungeState == LUNGE_FORWARD ? weapon : throwable;
				// weapon position
				p.x = gfx.x + (mc.weapon ? mc.weapon.x : 0);
				p.y = gfx.y + (mc.weapon ? mc.weapon.y : 0);
				// nudge
				if(!(target.type & (STONE | GATE))) target.collider.pushDamping = 1;
				// effects
				if(item && item.effects && target.active && !(target.type & (STONE | GATE))){
					target.applyWeaponEffects(item);
				}
				if(specialAttack && target.active && (!(target.type & STONE) || name == NYMPH) && !(target.type & GATE)) racialAttack(target, hitResult);
				var meleeWeapon:Boolean = Boolean(item && (item.range & Item.MELEE));
				// knockback
				var enduranceDamping:Number = 1.0 - (target.endurance + (target.armour ? target.armour.endurance : 0));
				if(enduranceDamping < 0) enduranceDamping = 0;
				var hitKnockback:Number = (knockback + (meleeWeapon ? item.knockback : 0)) * enduranceDamping;
				if(dir & LEFT) hitKnockback = -hitKnockback;
				// stun
				if(hitResult & STUN){
					var hitStun:Number = (stun + (meleeWeapon ? item.stun : 0)) * enduranceDamping;
					if(hitStun) target.applyStun(hitStun);
				}
				// damage
				var hitDamage:Number = damage + (meleeWeapon ? item.damage : 0);
				if(target.protectionModifier < 1){
					hitDamage *= target.protectionModifier < MIN_PROTECTION_MODIFIER ? MIN_PROTECTION_MODIFIER : target.protectionModifier;
				}
				// rogue's backstab multiplier
				if((name == ROGUE || name == HUSBAND) && (looking & (LEFT | RIGHT)) == (target.looking & (LEFT | RIGHT))){
					hitDamage *= 2;
					renderer.createDebrisRect(target.collider, (looking & (LEFT | RIGHT)) == RIGHT ? 8 : -8, 30, target.debrisType);
				}
				// crit multiplier
				if(hitResult & CRITICAL){
					hitDamage *= 2;
				}
				// falling attack or blessed weapon? roll for smite
				if(
					(
						(item && item.holyState == Item.BLESSED) && (
							(hitResult & CRITICAL) ||
							game.random.value() < SMITE_PER_LEVEL * (
								item.level + (collider.state == Collider.FALL ? level : 0)
							)
						)
					) || (
						collider.state == Collider.FALL && (
							(hitResult & CRITICAL) ||
							game.random.value() < SMITE_PER_LEVEL * level
						)
					)
				){
					target.smite(looking, hitDamage * 0.5);
					// half of hitDamage is transferred to the smite state
					hitDamage *= 0.5;
				}
				// leech
				if((leech || (item && item.leech)) && !(target.armour && target.armour.name == Item.BLOOD) && !(target.type & (STONE | GATE))){
					var leechValue:Number = leech + (item ? item.leech : 0);
					if(leechValue > 1) leechValue = 1;
					leechValue *= hitDamage;
					if(leechValue > target.health) leechValue = target.health;
					applyHealth(leechValue);
				}
				// damage applied
				target.applyDamage(hitDamage, nameToString(), hitKnockback, Boolean(hitResult & CRITICAL), this);
				// thorns
				if(target.thorns){
					renderer.createDebrisRect(collider, 0, 10, debrisType);
					applyDamage(hitDamage * (target.thorns <= 1 ? target.thorns : 1), target.nameToString(), 0, false);
				}
				// blood
				if((dir & RIGHT) || ((dir & LEFT) && lungeState == LUNGE_BACK)){
					renderer.createDebrisSpurt(p.x < target.collider.x ? p.x : target.collider.x - 1, p.y, -2, 8, target.debrisType);
				} else if((dir & LEFT) || ((dir & RIGHT) && lungeState == LUNGE_BACK)){
					renderer.createDebrisSpurt(p.x >= target.collider.x + target.collider.width ? p.x : target.collider.x + target.collider.width, p.y, 2, 8, target.debrisType);
				}
				
			} else {
				game.soundQueue.add("miss");
			}
			if(state != QUICKENING){
				state = LUNGING;
				
				// bravery check - quick monsters may favour running away
				if(brain && !(brain is PlayerBrain)){
					if(
						target.brain &&
						bravery < 1 &&
						speed * speedModifier >= target.speed * target.speedModifier &&
						game.random.value() >= bravery
					){
						brain.flee(target);
					}
				}
			} else {
				if(lungeState != LUNGE_FORWARD){
					lungeState = LUNGE_FORWARD;
					equipmentGfxLayerUpdateCount = game.frameCount;
				}
			}
			victim = target;
		}
		
		protected function stompCallback(stomper:Collider):void{
			if(state == QUICKENING || state == SMITED || !active) return;
			applyStun(0.5);
			var center:Number = collider.x + collider.width * 0.5;
			var stomperCenter:Number = stomper.x + stomper.width * 0.5;
			if(center < stomperCenter){
				collider.vx -= stomper.width + stomper.userData.knockback;
			} else {
				collider.vx += stomper.width + stomper.userData.knockback;
			}
			if(stomper.state == Collider.FALL){
				var char:Character = stomper.userData as Character;
				if(char) char.stomping = true;
			}
		}
		
		/* Kill the Character, printing a cause to the console and generating a Head object on decapitation */
		public function death(cause:String = "crushing", decapitation:Boolean = false, aggressor:Character = null):void{
			active = false;
			renderer.createDebrisExplosion(collider, 3, 20, debrisType);
			renderer.createDebrisRect(collider, 0, 20, debrisType);
			
			// the goblin elite is always decapitated
			if(rank == ELITE && name == GOBLIN) decapitation = true;
			
			var method:String = decapitation ? "decapitated" : stats["death strings"][name];
			//decapitation = true;
			if(decapitation){
				var head:Head = new Head(this, totalHealth * 0.5);
				var corpse:Corpse = new Corpse(this);
			}
			game.console.print(nameToString() + " " + method + " by " + cause);
			if(questVictim) game.gameMenu.loreList.questsList.questCheck(QuestMenuOption.KILL, this);
			renderer.shake(0, 3);
			game.soundQueue.add("kill");
			if(type == MONSTER){
				var xp:Number = xpReward;
				if(rank == CHAMPION) xp *= 2;
				else if(rank == ELITE) xp *= 3;
				game.player.addXP(xp);
			}
			if(effects) removeEffects();
			// character may have been resurrected -
			// skin change must occur here outside of changes to effects list
			if(resurrect){
				changeName(SKELETON);
				resurrect = false;
			}
			if(!active && collider.world) collider.world.removeCollider(collider);
		}
		
		/* Drop down through a ledge - typically called by com.robotacid.ai.Brain */
		public function ledgeDrop():void{
			collider.ignoreProperties |= Collider.LEDGE;
			collider.divorce();
			collider.state = Collider.FALL;
			dir &= ~(UP | DOWN);
		}
		
		/* Enter the level via a portal */
		public function enterLevel(portal:Portal, dir:int = RIGHT):void{
			this.portal = portal;
			if(dir == RIGHT){
				gfx.x = (portal.mapX + 0.5) * Game.SCALE - PORTAL_DISTANCE;
			} else if(dir == LEFT){
				gfx.x = (portal.mapX + 0.5) * Game.SCALE + PORTAL_DISTANCE;
			}
			if(portal.type == Portal.STAIRS){
				if(portal.targetLevel > game.map.level){
					gfx.y = (portal.mapY + 1) * Game.SCALE + PORTAL_DISTANCE;
				} else if(portal.targetLevel < game.map.level){
					gfx.y = (portal.mapY + 1) * Game.SCALE - PORTAL_DISTANCE;
				}
			} else {
				gfx.y = (portal.mapY + 1) * Game.SCALE;
			}
			this.dir = looking = dir;
			state = ENTERING;
			
			// reinitialise equipment animations
			if(armour && armour.gfx is ItemMovieClip) (armour.gfx as ItemMovieClip).setEquipRender();
			if(weapon && weapon.gfx is ItemMovieClip) (weapon.gfx as ItemMovieClip).setEquipRender();
		}
		
		/* Advances the character to the next level */
		public function levelUp():void{
			if(level >= Game.MAX_LEVEL) return;
			level++;
			setStats();
			applyHealth(totalHealth);
			// quickening whilst using a portal crashes the character, it must be queued till the character is free
			quickenQueued = true;
		}
		
		/* This method kicks off a character's quickening state. Whilst a character quickens, they
		 * send out lightning bolts from their hands and float up to the ceiling */
		public function quicken():void{
			quickenQueued = false;
			state = QUICKENING;
			dir = RIGHT;
			collider.divorce();
			quickeningCount = QUICKENING_DELAY;
			stunCount = 0;
			attackCount = 1;
			if(lungeState != LUNGE_FORWARD) lungeState = LUNGE_FORWARD;
			equipmentGfxLayerUpdateCount = game.frameCount;
			// since the minion and player quicken together, we try to avoid phased sound effects
			if(!(this == game.minion && game.player.state == QUICKENING)){
				game.soundQueue.addRandom("quickening", QUICKENING_SOUNDS);
			}
		}
		
		/* Called at the end of the quickening or if the quickening is interrupted by a spell like stun */
		public function finishQuicken():void{
			state = WALKING;
			gfx.transform.colorTransform = new ColorTransform();
			if(this is Player) {
				if(level < Game.MAX_LEVEL) game.console.print("welcome to level " + level + " " + nameToString());
				else game.console.print(nameToString() + " has reached maximum level");
			}
		}
		
		/* Used to auto-center when climbing */
		public function centerOnTile():void{
			var colliderCenter:Number = collider.x + collider.width * 0.5;
			if(colliderCenter > tileCenter) collider.vx = colliderCenter - speed > tileCenter ? -speed : tileCenter - colliderCenter;
			else if(colliderCenter < tileCenter) collider.vx = colliderCenter + speed < tileCenter ? speed : tileCenter - colliderCenter;
		}
		
		/* Enters the SMITED state - caused by being hit by a blessed weapon */
		public function smite(dir:int, damage:Number):void{
			// blessed armour resists smiting - also cancelling damage
			if(armour && armour.holyState == Item.BLESSED){
				game.soundQueue.addRandom("smite", SMITE_SOUNDS, 10);
				renderer.createSparks(
					collider.x + ((dir & RIGHT) ? 0 : collider.width),
					collider.y + collider.height * 0.5,
					(dir & RIGHT) ? -2 : 2,
					0, 10
				);
				return;
			}
			if(type & (STONE | GATE)){
				applyDamage(damage * SMITE_DAMAGE_RATIO, "smite", 0, true);
			} else {
				state = SMITED;
				collider.state = Collider.HOVER;
				collider.divorce();
				this.dir = dir;
				smiteDamage = damage * SMITE_DAMAGE_RATIO;
				stunCount = 0;
			}
			if(dir & RIGHT){
				looking = LEFT;
				renderer.addFX(collider.x, collider.y + collider.height * 0.5, renderer.smiteRightBlit, new Point(1, 0));
			} else if(dir & LEFT){
				looking = RIGHT;
				renderer.addFX(collider.x + collider.width, collider.y + collider.height * 0.5, renderer.smiteLeftBlit, new Point(-1, 0));
			}
			game.soundQueue.addRandom("smite", SMITE_SOUNDS, 20);
		}
		
		/* The logic to validate climbing is pretty convoluted so it resides in another method,
		 * this goes against all my normal programming style, but I can still inline this
		 * shit if I'm in a pinch */
		public function canClimb():Boolean{
			return (
				(mapProperties & Collider.LADDER) ||
				(game.world.map[((collider.y + collider.height + Collider.INTERVAL_TOLERANCE) * INV_SCALE) >> 0][mapX] & Collider.LADDER)
			) &&
			collider.x + collider.width >= LADDER_LEFT + mapX * SCALE &&
			collider.x <= LADDER_RIGHT + mapX * SCALE;
		}
		
		/* This reactivates any buffered effects  */
		public function restoreEffects(): void{
			if(effectsBuffer){
				var effect:Effect;
				for(var i:int = 0; i < effectsBuffer.length; i++){
					effect = effectsBuffer[i];
					effect.apply(this);
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
		public function equip(item:Item, throwing:Boolean = false):Item{
			item.location = Item.EQUIPPED;
			item.user = this;
			if(item.type == Item.WEAPON){
				if(throwing) throwable = item;
				else weapon = item;
			}
			if(item.type == Item.ARMOUR){
				armour = item;
				canJump = item.name == Item.YENDOR;
				if(item.effects){
					var effect:Effect;
					for(var i:int = 0; i < item.effects.length; i++){
						effect = item.effects[i];
						if(effect.applicable) effect.apply(this);
					}
				}
				armour.gfx.x = armour.gfx.y = 0;
			}
			
			item.addBuff(this);
			equipmentGfxLayerUpdateCount = game.frameCount;
			if(item.gfx is ItemMovieClip) (item.gfx as ItemMovieClip).setEquipRender();
			return item;
		}
		
		/* Unselect item as equipped */
		public function unequip(item:Item):Item{
			if(item != armour && item != weapon && item != throwable) return null;
			item.location = Item.INVENTORY;
			item.user = null;
			var i:int;
			for(i = 0; i < (gfx as MovieClip).numChildren; i++){
				if((gfx as MovieClip).getChildAt(i) == item.gfx){
					(gfx as MovieClip).removeChildAt(i);
					break;
				}
			}
			if(item == armour){
				if(item.effects){
					var effect:Effect;
					for(i = 0; i < item.effects.length; i++){
						effect = item.effects[i];
						// the effect may already have been dismissed as a result
						// of resurrection
						if(effect.applicable && effect.target) effect.dismiss();
					}
				}
				canJump = false;
				armour = null;
			}
			if(item == weapon) weapon = null;
			if(item == throwable) throwable = null;
			
			item.removeBuff(this);
			
			return item;
		}
		
		/* Juggles the graphics layers so that the items are on the right layers at the right time */
		protected function setEquipmentGfxLayers():void{
			var mc:MovieClip = gfx as MovieClip;
			if(lungeState == LUNGE_FORWARD){
				if(armour){
					if(armour.name == Item.YENDOR) mc.addChildAt(armour.gfx, 0);
					else mc.addChild(armour.gfx);
				}
				if(weapon) mc.addChild(weapon.gfx);
				if(throwable) mc.addChildAt(throwable.gfx, 0);
				
			} else if(lungeState == LUNGE_BACK){
				if(armour){
					if(armour.name == Item.YENDOR) mc.addChildAt(armour.gfx, 0);
					else mc.addChild(armour.gfx);
				}
				if(throwable) mc.addChild(throwable.gfx);
				if(weapon) mc.addChildAt(weapon.gfx, 0);
			}
			if(bannerGfx){
				if(state == WALKING && collider.state == Collider.HOVER){
					mc.addChild(bannerGfx);
					bannerGfx.gotoAndStop("climb");
				} else {
					mc.addChildAt(bannerGfx, 0);
					bannerGfx.gotoAndStop("idle");
				}
			}
		}
		
		/* Drops an item from the Character's loot */
		public function dropItem(item:Item):void{
			var n:int = loot.indexOf(item);
			if(n > -1) loot.splice(n, 1);
		}
		
		/* Determine if we have hit another character */
		public function hit(character:Character, range:int, item:Item = null):int{
			if(indifferent) return MISS;
			var attackRoll:Number = game.random.value();
			if(!item) item = lungeState == LUNGE_FORWARD ? weapon : throwable;
			if(attackRoll >= CRITICAL_HIT)
				return CRITICAL | STUN;
			else if(attackRoll <= CRITICAL_MISS)
				return MISS;
			else if(
				attack + attackRoll + (item && (item.range & range) ? item.attack : 0) > character.defence + (character.armour ? character.armour.defence : 0
			)){
				// stun roll
				var enduranceDamping:Number = 1.0 - (character.endurance + (character.armour ? character.armour.endurance : 0));
				if(enduranceDamping < 0) enduranceDamping = 0;
				var stunCheck:Number = (stun + (item && (item.range & range) ? item.stun : 0)) * enduranceDamping;
				if(stunCheck && game.random.value() <= stunCheck) return HIT | STUN;
				return HIT;
			}
				
			return MISS;
		}
		
		/* Effect stun state on this character */
		public function applyStun(delay:Number):void{
			// inanimate objects can't be stunned
			if((type == STONE && name != Stone.DEATH) || type == GATE) return;
			// exit the quickening state if already in it
			if(state == QUICKENING) finishQuicken();
			if(stunCount <= 0) game.createDistSound(mapX, mapY, "stun", STUN_SOUNDS);
			stunCount = delay;
			state = STUNNED;
			if(lungeState != LUNGE_FORWARD) lungeState = LUNGE_FORWARD;
			equipmentGfxLayerUpdateCount = game.frameCount;
			if(collider.state == Collider.HOVER){
				collider.state = Collider.FALL;
			}
		}
		
		/* Loose a missile, could be a throwable, weapon projectile or a rune */
		public function shoot(type:int, effect:Effect = null, rune:Item = null):void{
			if(attackCount < 1 || (mapProperties & Collider.WALL)) return;
			state = LUNGING;
			attackCount = 0;
			var missileMc:DisplayObject;
			var item:Item;
			var reflections:int = 0;
			var alchemical:Boolean = false;
			
			// check for chaos wand and create chaos spell
			if(type == Missile.ITEM && weapon && weapon.name == Item.CHAOS_WAND){
				type = Missile.RUNE;
				effect = new Effect(Item.CHAOS, weapon.level, Effect.THROWN);
			}
			
			// create missile
			if(type == Missile.RUNE){
				missileMc = new ThrownRuneMC();
				item = rune;
				alchemical = (
					effect.name == Item.HEAL ||
					effect.name == Item.XP ||
					effect.name == Item.CHAOS
				);
			} else if(type == Missile.ITEM){
				if(throwable){
					item = unequip(throwable);
					if(this == game.player || this == game.minion) item = game.gameMenu.inventoryList.removeItem(item);
					else dropItem(item);
					item.location = Item.FLIGHT;
					missileMc = item.gfx;
					item.gfx.visible = true;
					item.autoEquip = this.type;
					if(item.gfx is ItemMovieClip) (item.gfx as ItemMovieClip).setThrowRender();
					if(item.name == Item.CHAKRAM){
						reflections = Missile.CHAKRAM_REFLECTIONS;
					}
				// we can only get here if the main weapon is a missile weapon
				} else {
					missileMc = new weapon.missileGfxClass();
					item = weapon;
				}
			}
			if(type == Missile.ITEM) {
				if(item.name == Item.GUN_BLADE){
					game.soundQueue.addRandom("gunBlade", ["gunBlade1", "gunBlade2", "gunBlade3"]);
				} else if(item.name == Item.ARQUEBUS){
					game.soundQueue.addRandom("arquebus", ["arquebus1", "arquebus2", "arquebus3"]);
				} else if(item.name == Item.ARBALEST){
					game.soundQueue.add("arbalest");
				} else if(item.name == Item.GUN_LEECH){
					game.soundQueue.addRandom("leech gun", Stone.HEAL_STONE_HIT_SOUNDS);
				} else {
					game.soundQueue.add("bowShoot");
				}
			} else if (type == Missile.RUNE){
				game.soundQueue.add("throw");
				if(rune) reflections = Missile.RUNE_REFLECTIONS;
			}
			missileMc.scaleX = (looking & RIGHT) ? 1 : -1;
			var missile:Missile = new Missile(missileMc, collider.x + collider.width * 0.5, collider.y + collider.height * 0.5, type, this, (looking & RIGHT) ? 1 : -1, 0, 5, missileIgnore, effect, item, null, reflections, brain.firingTeam, alchemical);
			if(asleep) setAsleep(false);
		}
		
		/* Called by Missile to effect a throwing being caught by a character */
		public function catchThrowable(item:Item):void{
			item.collect(this, true, true);
			if(!throwable && !(weapon && weapon.range & Item.MISSILE)) equip(item, true);
		}
		
		/* The most ironic method ever to appear in what is advertised as a platform game */
		public function jump():void{
			if(state != WALKING || collider.state == Collider.FALL) return;
			collider.divorce();
			collider.state = Collider.FALL;
			collider.vy = JUMP_VELOCITY;
			game.soundQueue.add("jump");
			if(asleep) setAsleep(false);
		}
		
		/* Adds damage to the Character */
		public function applyDamage(n:Number, source:String, knockback:Number = 0, critical:Boolean = false, aggressor:Character = null, defaultSound:Boolean = true):void{
			// killing a character on a set of stairs could crash the game
			if(state == ENTERING || state == EXITING || state == QUICKENING) return;
			// wake up any sleeping character
			if(asleep) setAsleep(false);
			
			health-= n;
			if(defaultSound) game.soundQueue.addRandom("hit" + debrisType, HIT_SOUNDS[debrisType]);
			if(critical) renderer.shake(0, 5);
			if(health <= 0){
				death(source, critical, aggressor);
			} else if(knockback){
				game.world.addForce(collider, knockback, 0, KNOCKBACK_DAMPING, 0);
			}
		}
		
		public function applyHealth(n:Number):void{
			health += n;
			if(health > totalHealth) health = totalHealth;
		}
		
		public function applyWeaponEffects(item:Item):void{
			if(item.effects){
				var effect:Effect;
				for(var i:int = 0; i < item.effects.length; i++){
					effect = item.effects[i];
					if(effect.applicable) effect.copy().apply(this);
				}
			}
		}
		
		public function enemy(target:Character):Boolean{
			if(!target.active || target.state == QUICKENING || target.state == ENTERING || target.state == EXITING) return false;
			if(type & (PLAYER | MINION)) return Boolean(target.type & (MONSTER | STONE | GATE));
			else if(type & MONSTER) return Boolean(target.type & (PLAYER | MINION));
			return false;
		}
		
		/* Activate the infravision stat on a Character - affects Minion, Monster and Player differently
		 * Player's see the lightMap differently and see monsters in the dark in red, monsters get superior
		 * vision in their Brain calculations */
		public function setInfravision(value:int):void{
			if(value == infravision) return;
			var i:int, character:Character;
			infravision = value;
			if(this is Player){
				if(infravision){
					if(infravision == 1){
						renderer.lightBitmap.alpha = 0.86;
					} else if(infravision == 2){
						renderer.lightBitmap.alpha = 0.44;
					}
				} else {
					renderer.lightBitmap.alpha = 1;
				}
			} else {
				losBorder = Brain.DEFAULT_LOS_BORDER + infravision * Brain.INFRAVISION_LOS_BORDER_BONUS;
			}
		}
		
		/* Changes the character's sleep state (overridden by Player) */
		public function setAsleep(value:Boolean):void{
			asleep = value;
			if(value){
				collider.vx = 0;
				actions = dir = 0;
			}
		}
		
		/* Some races have a special attack as their racial ability, this method is executed during a successful melee strike */
		public function racialAttack(target:Character, hitResult:int):void{
			
			// racial attacks require a roll to see if they are executed (level based with racial modifiers)
			if(!(hitResult & CRITICAL)){
				var roll:Number = game.random.value();
				if(name == NYMPH){
					roll *= 0.5;
					if(rank == ELITE) roll = 0;
					
				} else if(name == MIND_FLAYER){
					roll *= 1.5;
				}
				if(roll > level * SPECIAL_ATTACK_PER_LEVEL) return;
			}
			
			var effect:Effect;
			
			// steal attack
			if(name == NYMPH){
				var item:Item;
				if(target.weapon){
					item = target.weapon;
				} else if(target.throwable){
					item = target.throwable;
				} else if(target.armour){
					item = target.armour;
				}
				if(item){
					var user:Character = item.user;
					item = target.unequip(item);
					if(user == game.player || user == game.minion){
						item = game.gameMenu.inventoryList.removeItem(item);
					}
					target.dropItem(item);
					item.collect(this, false);
					if(brain) brain.flee(target);
					game.console.print(nameToString() + " stole " + item.nameToString());
					game.createDistSound(mapX, mapY, "pickUp");
				}
				
			// polymorph target into a werewolf
			} else if(name == WEREWOLF){
				// we target face wearing characters through their armour
				if(rank != ELITE){
					if(target.name != WEREWOLF){
						game.console.print(target.nameToString() + " falls to the werewolf curse");
						if(target.armour && target.armour.name == Item.FACE) (target.armour as Face).previousName = WEREWOLF;
						else target.changeName(WEREWOLF);
					} else {
						game.console.print(target.nameToString() + " is still a werewolf");
					}
				} else {
					game.console.print(target.nameToString() + " falls to the " + uniqueNameStr + " curse");
					var newName:int = target.name;
					while(newName == target.name) newName = game.random.rangeInt(stats["names"].length);
					if(target.armour && target.armour.name == Item.FACE) (target.armour as Face).previousName = newName;
					else target.changeName(newName);
				}
				game.createDistSound(target.mapX, target.mapY, "Polymorph");
				renderer.createSparkRect(target.collider, 20, 0, -1);
			
			// polymorph into target
			} else if(name == MIMIC){
				if(armour && armour.name == Item.FACE) (armour as Face).previousName = target.name;
				else changeName(target.name);
				game.console.print("mimic stole " + target.nameToString() + " form");
				renderer.createSparkRect(collider, 20, 0, -1);
				game.createDistSound(mapX, mapY, "Polymorph");
				
			// bleed attack
			} else if(name == NAGA){
				effect = new Effect(Effect.BLEED, level, Effect.THROWN, target);
				if(rank == ELITE) effect = new Effect(Effect.FEAR, level, Effect.THROWN, target);
				
			// stun attack
			} else if(name == GORGON){
				effect = new Effect(Effect.STUN, level, Effect.THROWN, target);
				if(rank == ELITE) effect = new Effect(Effect.SLOW, level, Effect.THROWN, target);
				
			// confuse attack
			} else if(name == UMBER_HULK || (rank == ELITE && name == CACTUAR)){
				effect = new Effect(Effect.CONFUSION, level, Effect.THROWN, target);
				
			// fear attack
			} else if(name == BANSHEE){
				effect = new Effect(Effect.FEAR, level, Effect.THROWN, target);
				
			// teleport attack
			} else if(rank == ELITE && name == WRAITH){
				effect = new Effect(Effect.TELEPORT, level, Effect.THROWN, target);
				
			// level drain attack
			} else if(name == MIND_FLAYER){
				if(target.level > 1){
					target.level--;
					target.setStats();
					game.console.print(nameToString() + " drains a level from " + target.nameToString());
					if(this == game.player) game.player.addXP(target.level + 1);
					if(target == game.player){
						// update the player's experience bar
						game.player.addXP(0);
					}
				}
				if(rank == ELITE){
					effect = new Effect(Effect.FEAR, level, Effect.THROWN, target);
					effect = new Effect(Effect.CONFUSION, level, Effect.THROWN, target);
				}
				
			// chaos attack
			} else if(name == RAKSHASA){
				effect = new Effect(Effect.CHAOS, level, Effect.THROWN, target);
				if(rank == ELITE){
					if(looking & RIGHT) effect = new Effect(Effect.BLEED, level, Effect.THROWN, target);
					else if(looking & LEFT) effect = new Effect(Effect.HEAL, level, Effect.THROWN, target);
				}
				
			}
		}
		
		/* Change the race of the character - involves resetting physics for the character as well as stats */
		public function changeName(name:int, gfx:MovieClip = null):void{
			if(this.name == name && !gfx) return;
			var previousName:int = this.name;
			
			// change gfx
			this.name = name;
			if(!gfx){
				this.gfx = gfx = game.library.getCharacterGfx(name);
			} else{
				this.gfx = gfx;
			}
			
			// change physics
			var restore:Boolean = false;
			if(collider.world){
				collider.world.removeCollider(collider);
				restore = true;
			}
			createCollider(collider.x + collider.width * 0.5, collider.y + collider.height, collider.properties, collider.ignoreProperties, Collider.FALL);
			if(restore){
				game.world.restoreCollider(collider);
				if(!(name == WRAITH || (rank == ELITE && name == Character.BANSHEE))) collider.resolveMapInsertion();
				// if a character ceases to be a wraith whilst wall-walking, teleport them out
				// also teleport the player out of locked areas
				if(
					(
						previousName == WRAITH ||
						(rank == ELITE && previousName == Character.BANSHEE)
					) && (
						(game.world.map[mapY][mapX] & Collider.WALL) ||
						(
							Surface.fragmentationMap &&
							Surface.fragmentationMap.getPixel32(mapX, mapY) != Surface.entranceCol
						)
					)
				){
					Effect.teleportCharacter(this);
				}
			}
			
			// set the correct ai graph for the character's brain
			brain.wallWalker = (name == WRAITH || (rank == ELITE && name == Character.BANSHEE));
			
			// change stats - items will be equipped to the new graphic in the setStats method
			var originalHealthRatio:Number = health / totalHealth;
			setStats();
			health = 0;
			applyHealth(originalHealthRatio * totalHealth);
			
			// if this character is a quest victim, they need to update their name in the quest
			// and move the marker to the new graphic
			if(questVictim){
				questTarget();
				game.gameMenu.loreList.questsList.updateName(this);
			}
		}
		
		/* Makes this character the victim of a quest */
		public function questTarget():void{
			questVictim = true;
			gfx.filters = [QUEST_VICTIM_FILTER];
		}
		
		override public function nameToString():String {
			return uniqueNameStr ? uniqueNameStr : nameStr;
		}
		
		/* Creates a unique name for the Character */
		public function createUniqueNameStr():void{
			uniqueNameStr = stats["unique names"][name][game.random.rangeInt(stats["unique names"][name].length)];
		}
		
		override public function toXML():XML {
			var xml:XML = <character characterNum={characterNum} name={name} type={type} level={level} rank={rank} questVictim={questVictim} />;
 			if(effects && effects.length){
				for(var i:int = 0; i < effects.length; i++){
					if(effects[i].source != Effect.ARMOUR){
						xml.appendChild(effects[i].toXML());
					}
				}
			}
			return xml;
		}
		
		override public function remove():void {
			if(effects){
				bufferEffects();
			}
			super.remove();
		}
		
		override public function render():void{
			
			var mc:MovieClip = gfx as MovieClip
			
			if(!portal){
				gfx.x = ((collider.x + collider.width * 0.5) + 0.5) >> 0;
				gfx.y = ((collider.y + collider.height) + 0.5) >> 0;
			}
			if((looking & LEFT) && mc.scaleX != -1) mc.scaleX = -1;
			else if((looking & RIGHT) && mc.scaleX != 1) mc.scaleX = 1;
			
			if(asleep){
				if(this == game.player){
					tent.x = gfx.x - tent.width * 0.5;
					tent.y = gfx.y - SCALE;
					matrix = tent.transform.matrix;
					matrix.tx -= renderer.bitmap.x;
					matrix.ty -= renderer.bitmap.y;
					renderer.bitmapData.draw(tent, matrix, gfx.transform.colorTransform);
				}
				return;
			}
			
			// pace movement
			if(state == WALKING || state == EXITING || state == ENTERING){
				if(!moving) moveCount = 0;
				else {
					if(stepNoise && moving && moveCount == 0 && moveFrame == 0 && !(collider.pressure & looking)){
						stepSound &= 1;
						game.soundQueue.add(STEP_SOUNDS[collider.state == Collider.STACK ? 0 : 1][stepSound]);
					}
					moveCount = (moveCount + 1) % MOVE_DELAY;
					// flip between climb frames as we move
					if(moveCount == 0) moveFrame ^= 1;
				}
			}
			if(state == WALKING){
				if(collider.state == Collider.STACK){
					if(moving && !(collider.pressure & looking)){
						if(moveFrame){
							if(mc.currentLabel != "move1") mc.gotoAndStop("move1");
						} else {
							if(mc.currentLabel != "move0") mc.gotoAndStop("move0");
						}
					} else {
						if(mc.currentLabel != "idle"){
							mc.gotoAndStop("idle");
						}
					}
				} else if(collider.state == Collider.FALL){
					if(mc.currentLabel != "move1"){
						mc.gotoAndStop("move1");
					}
				} else if(collider.state == Collider.HOVER){
					if(moveFrame){
						if(mc.currentLabel != "climb1") mc.gotoAndStop("climb1");
					} else {
						if(mc.currentLabel != "climb0") mc.gotoAndStop("climb0");
					}
				}
			} else if(state == LUNGING){
				if(mc.currentLabel != "lunge") mc.gotoAndStop("lunge");
				if(lungeState == LUNGE_BACK){
					if((looking & RIGHT) && mc.scaleX != -1) mc.scaleX = -1;
					else if((looking & LEFT) && mc.scaleX != 1) mc.scaleX = 1;
				}
				
			} else if(state == QUICKENING){
				if(mc.currentLabel != "quicken") mc.gotoAndStop("quicken");
				
			} else if(state == EXITING || state == ENTERING){
				if(moveFrame){
					if(mc.currentLabel != "move1") mc.gotoAndStop("move1");
				} else {
					if(mc.currentLabel != "move0") mc.gotoAndStop("move0");
				}
			} else if(state == STUNNED){
				if(mc.currentLabel != "stun") mc.gotoAndStop("stun");
				
			} else if(state == SMITED){
				if(mc.currentLabel != "smited") mc.gotoAndStop("smited");
			}
			if(gfx.alpha < 1){
				gfx.alpha += 0.1;
			}
			if(gfx.visible && equipmentGfxLayerUpdateCount == game.frameCount) setEquipmentGfxLayers();
			if(weapon){
				if(mc.weapon){
					if(collider.state == Collider.HOVER) weapon.gfx.visible = false;
					else {
						weapon.gfx.visible = true;
						if(state == LUNGING && lungeState == LUNGE_BACK){
							weapon.gfx.x = mc.throwable.x;
							weapon.gfx.y = mc.throwable.y;
						} else {
							weapon.gfx.x = mc.weapon.x;
							weapon.gfx.y = mc.weapon.y;
						}
					}
				}
				if(weapon.gfx is ItemMovieClip){
					(weapon.gfx as ItemMovieClip).render(this, mc);
				}
			}
			if(throwable){
				if(mc.throwable){
					if(collider.state == Collider.HOVER) throwable.gfx.visible = false;
					else {
						throwable.gfx.visible = true;
						if(state == LUNGING && lungeState == LUNGE_BACK){
							throwable.gfx.x = mc.weapon.x;
							throwable.gfx.y = mc.weapon.y;
						} else {
							throwable.gfx.x = mc.throwable.x;
							throwable.gfx.y = mc.throwable.y;
						}
					}
				}
				if(throwable.gfx is ItemMovieClip){
					(throwable.gfx as ItemMovieClip).render(this, mc);
				}
			}
			if(armour){
				if(mc.armour){
					if(armour.position == Item.HAT){
						armour.gfx.x = mc.armour.x;
						armour.gfx.y = mc.armour.y;
					}
				}
				if(armour.gfx is ItemMovieClip){
					(armour.gfx as ItemMovieClip).render(this, mc);
				}
			}
			if(bannerGfx){
				if(bannerGfx){
					if(state == WALKING && collider.state == Collider.HOVER){
						if(bannerGfx.currentLabel != "climb"){
							mc.addChild(bannerGfx);
							bannerGfx.gotoAndStop("climb");
						}
					} else {
						if(bannerGfx.currentLabel != "idle"){
							mc.addChildAt(bannerGfx, 0);
							bannerGfx.gotoAndStop("idle");
						}
					}
				}
			}
			// armour may render the gfx non-visible
			if(gfx.visible){
				if(portal){
					var clipRect:Rectangle = new Rectangle( -renderer.bitmap.x + portal.rect.x, -renderer.bitmap.y + portal.rect.y, portal.rect.width, portal.rect.height);
					matrix = gfx.transform.matrix;
					matrix.tx -= renderer.bitmap.x;
					matrix.ty -= renderer.bitmap.y;
					renderer.bitmapData.draw(gfx, matrix, gfx.transform.colorTransform, null, clipRect);
				} else {
					super.render();
					// render stars above a character's head when they are stunned or confused
					if(state == STUNNED || (brain && brain.confusedCount > 0)){
						renderer.stunBlit.x = -renderer.bitmap.x + gfx.x;
						renderer.stunBlit.y = -renderer.bitmap.y + gfx.y - (collider.height + 2);
						renderer.stunBlit.render(renderer.bitmapData, game.frameCount % renderer.stunBlit.totalFrames);
					}
					// render protection
					if(protectionModifier < 1){
						renderer.protectionBlit.x = -renderer.bitmap.x + gfx.x;
						renderer.protectionBlit.y = -renderer.bitmap.y + gfx.y;
						renderer.protectionBlit.render(renderer.bitmapData, game.frameCount % renderer.protectionBlit.totalFrames);
					}
					// render thorns
					if(thorns > 0){
						renderer.thornsBlit.x = -renderer.bitmap.x + gfx.x;
						renderer.thornsBlit.y = -renderer.bitmap.y + gfx.y;
						renderer.thornsBlit.render(renderer.bitmapData, (game.frameCount + renderer.thornsBlit.totalFrames * 0.5) % renderer.thornsBlit.totalFrames);
					}
				}
				
				// the elite vampire sparkles
				if(rank == ELITE && name == VAMPIRE){
					if(twinkleCount-- <= 0){
						renderer.addFX(collider.x + game.random.range(collider.width), collider.y + game.random.range(collider.height), renderer.twinkleBlit);
						twinkleCount = Item.TWINKLE_DELAY + game.random.range(Item.TWINKLE_DELAY);
					}
				}
			}
		}
		
	}
	
}