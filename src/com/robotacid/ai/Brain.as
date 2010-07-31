package com.robotacid.ai {
	import com.robotacid.dungeon.DungeonBitmap;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.CharacterAttributes;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.Minion;
	import com.robotacid.engine.Missile;
	import com.robotacid.engine.Player;
	import com.robotacid.geom.Pixel;
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Cast;
	import com.robotacid.phys.Collider;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	
	/**
	 * A set of behaviours for Characters
	 *
	 * This class provides a toolkit of behaviours and actions as well as serving as an NPC's mind.
	 * brain.main() processes thoughts for a character
	 *
	 * Monster behaviour can be split into one of three types of behaviour:
	 *
	 * milling about, attacking an enemy and fleeing when said enemy is trying to land on its head
	 * namely: PAUSE/PATROL, ATTACK, FLEE
	 *
	 * Minion behaviour is the same apart from a special following behaviour which is a combination
	 * of the chase and flee routines (chase the player when too far, flee the player when too close)
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	
	public class Brain{
		
		public var g:Game;
		public var char:Character;
		public var target:Character;
		public var scheduleTarget:Character;
		public var buddyTarget:Character;
		public var ignore:int;
		
		
		public var state:int;
		public var count:int;
		public var delay:int;
		public var patrolMinX:Number;
		public var patrolMaxX:Number;
		public var patrolAreaSet:Boolean;
		public var dontRunIntoTheWallCount:int;
		public var sheduleIndex:int;
		public var allyIndex:int;
		public var allegiance:int;
		public var searchSteps:int;
		
		public static var playerCharacters:Vector.<Character>;
		public static var monsterCharacters:Vector.<Character>;
		
		private static var start:Node;
		private static var node:Node;
		private static var path:Vector.<Node>;
		
		public static var dungeonGraph:DungeonGraph;
		
		// alliegances
		public static const PLAYER:int = 0;
		public static const MONSTER:int = 1;
		
		// behavioural states
		public static const PATROL:int = 0;
		public static const PAUSE:int = 1;
		public static const ATTACK:int = 2;
		public static const FLEE:int = 3;
		
		// directional states
		public static const UP:int = Block.UP;
		public static const RIGHT:int = Block.RIGHT;
		public static const DOWN:int = Block.DOWN;
		public static const LEFT:int = Block.LEFT;
		public static const SHOOT:int = 1 << 4;
		
		// scale constants
		public static var scanStep:Number = Collider.scanStep;
		public static const SCALE:Number = Game.SCALE;
		public static const INV_SCALE:Number = Game.INV_SCALE;
		
		public static const MONSTER_SEARCH_STEPS:int = 14;
		public static const MINION_SEARCH_STEPS:int = 20;
		
		public static const LOS_BORDER:Number = 100;
		
		public static const FOLLOW_CHASE_EDGE:Number = Game.SCALE * 1.5;
		public static const FOLLOW_FLEE_EDGE:Number = Game.SCALE * 1;
		public static const FOLLOW_CHASE_EDGE_SQ:Number = FOLLOW_CHASE_EDGE * FOLLOW_CHASE_EDGE;
		public static const FOLLOW_FLEE_EDGE_SQ:Number = FOLLOW_FLEE_EDGE * FOLLOW_FLEE_EDGE;
		
		public static const SNIPE_CHASE_EDGE:Number = Game.SCALE * 5;
		public static const SNIPE_FLEE_EDGE:Number = Game.SCALE * 2;
		public static const SNIPE_CHASE_EDGE_SQ:Number = SNIPE_CHASE_EDGE * SNIPE_CHASE_EDGE;
		public static const SNIPE_FLEE_EDGE_SQ:Number = SNIPE_FLEE_EDGE * SNIPE_FLEE_EDGE;
		
		public static function initCharacterLists():void{
			playerCharacters = new Vector.<Character>();
			monsterCharacters = new Vector.<Character>();
		}
		public static function initDungeonGraph(bitmap:DungeonBitmap):void{
			dungeonGraph = new DungeonGraph(bitmap);
		}
		
		public function Brain(char:Character, allegiance:int, g:Game) {
			this.g = g;
			this.char = char;
			this.allegiance = allegiance;
			patrolAreaSet = false;
			state = PATROL;
			delay = CharacterAttributes.NAME_PAUSES[char.name];
			count = delay + Math.random() * delay;
			char.looking = Math.random() > 0.5 ? LEFT : RIGHT;
			dontRunIntoTheWallCount = 0;
			sheduleIndex = 0;
			allyIndex = 0;
			ignore = Block.LEDGE | Block.LADDER;
			if(allegiance == PLAYER){
				ignore |= Block.MINION | Block.PLAYER;
				searchSteps = MINION_SEARCH_STEPS;
			} else {
				ignore |= Block.MONSTER;
				searchSteps = MONSTER_SEARCH_STEPS;
			}
		}
		
		public function main():void{
			
			if(allegiance == PLAYER){
				if(monsterCharacters.length){
					sheduleIndex = (sheduleIndex + 1) % monsterCharacters.length;
					scheduleTarget = monsterCharacters[sheduleIndex];
				} else {
					scheduleTarget = null;
				}
			} else if(allegiance == MONSTER){
				if(playerCharacters.length){
					sheduleIndex = (sheduleIndex + 1) % playerCharacters.length;
					scheduleTarget = playerCharacters[sheduleIndex];
				} else {
					scheduleTarget = null;
				}
			}
			
			if(state == PATROL || state == PAUSE){
				if(state == PATROL){
					if(allegiance == MONSTER){
						if(patrolAreaSet){
							patrol();
							//Game.debug.moveTo(char.x, char.y);
							//Game.debug.lineTo(patrolMaxX, char.y);
							//Game.debug.moveTo(char.x, char.y);
							//Game.debug.lineTo(patrolMinX, char.y);
						}
						else (setPatrolArea(g.blockMap));
						if(count-- <= 0){
							count = delay + Math.random() * delay;
							state = PAUSE;
							char.actions = char.dir = 0;
						}
					} else if(allegiance == PLAYER){
						if(g.player.state != Character.QUICKENING) follow(g.player);
						else char.dir = 0;
					}
				} else if(state == PAUSE){
					if(count-- <= 0){
						count = delay + Math.random() * delay;
						state = PATROL;
					}
				}
				
				// here's where we look for targets
				// any enemy touching us counts as a target, but we also look for targets
				// rather than checking all enemy characters, we check one at a time each frame
				if(scheduleTarget){
					if(char.leftCollider && (char.leftCollider is Character) && char.enemy((char.leftCollider as Character))){
						target = (char.leftCollider as Character);
						state = ATTACK;
						count = 0;
					}
					if(char.rightCollider && (char.rightCollider is Character) && char.enemy((char.rightCollider as Character))){
						target = (char.rightCollider as Character);
						state = ATTACK;
						count = 0;
					}
					// we test LOS when the player is within a square area near the monster - this is cheaper
					// than doing a radial test and we don't want all monsters calling LOS all the time
					// we also avoid suprise attacks by avoiding checks from monsters in the dark
					if(!char.inTheDark){
						if(!(scheduleTarget.armour && scheduleTarget.armour.name == Item.INVISIBILITY)){
							if((char.looking & RIGHT) && scheduleTarget.x > char.x && scheduleTarget.x < char.x + LOS_BORDER && scheduleTarget.y > char.y - LOS_BORDER && scheduleTarget.y < char.y + LOS_BORDER){
								//Game.debug.moveTo(char.x, char.y);
								//Game.debug.lineTo(scheduleTarget.x, scheduleTarget.y);
								if(LOS(scheduleTarget, g.blockMap, ignore)){
									state = ATTACK;
									target = scheduleTarget;
									count = 0;
								}
							}
							if((char.looking & LEFT) && scheduleTarget.x < char.x && scheduleTarget.x > char.x - LOS_BORDER && scheduleTarget.y > char.y - LOS_BORDER && scheduleTarget.y < char.y + LOS_BORDER){
								//Game.debug.moveTo(char.x, char.y);
								//Game.debug.lineTo(scheduleTarget.x, scheduleTarget.y);
								if(LOS(scheduleTarget, g.blockMap, ignore)){
									state = ATTACK;
									target = scheduleTarget;
									count = 0;
								}
							}
						}
					}
				}
			} else if(state == ATTACK){
				
				if(char.weapon && char.weapon.name == Item.BOW){
					snipe(target);
				} else {
					chase(target);
				}
				
				// if the target is directly above, get the hell out of there
				if(
					char.rect.y >= target.rect.y + target.rect.height &&
					!(
						char.rect.x >= target.rect.x + target.rect.width ||
						char.rect.x + char.rect.width <= target.rect.x
					)
				){
					state = FLEE;
					count = delay + Math.random() * delay * 2;
				}
				
				if(!target.active){
					target = null;
					patrolAreaSet = false;
					state = PATROL;
				}
			} else if(state == FLEE){
				
				flee(target);
				if(count-- <= 0){
					if(char.inTheDark){
						// we want fleeing characters in the dark to go back to patrolling
						// but not if they're on a fucking ladder
						if(char.state == Character.CLIMBING){
							count = 1 + delay * Math.random();
						} else {
							target = null;
							patrolAreaSet = false;
							state = PATROL;
						}
					} else {
						state = ATTACK;
						count = 0;
					}
				}
				if(char.leftCollider && (char.leftCollider is Character) && char.enemy((char.leftCollider as Character))){
					target = (char.leftCollider as Character);
					state = ATTACK;
					count = 0;
				}
				if(char.rightCollider && (char.rightCollider is Character) && char.enemy((char.rightCollider as Character))){
					target = (char.rightCollider as Character);
					state = ATTACK;
					count = 0;
				}
			}
			
			// debugging colours
			//if(state == PATROL){
				//char.mc.transform.colorTransform = new ColorTransform(1, 1, 1, 1, 0, 200);
			//} else if(state == ATTACK){
				//char.mc.transform.colorTransform = new ColorTransform(1, 1, 1, 1, 200, 0);
			//} else if(state == FLEE){
				//char.mc.transform.colorTransform = new ColorTransform(1, 1, 1, 1, 150, 150);
			//} else if(state == PAUSE){
				//char.mc.transform.colorTransform = new ColorTransform(1, 1, 1, 1, 0, 150, 100);
			//}
		}
		
		/* Abandons any targets and reverts to PATROL state
		 *
		 * must be called on minion entering a new level as a target may still be pursued */
		public function clear():void{
			target = null;
			state = PATROL;
		}
		
		/* This walks a character left and right in their patrol area
		 * The patrol area must be defined with setPatrolArea before using this method
		 */
		public function patrol():void {
			char.dir = 0;
			
			if(char.actions == 0) char.actions = char.looking & (LEFT | RIGHT);
			
			if(char.state == Character.WALKING){
				if(char.actions & RIGHT) {
					if(char.x >= patrolMaxX || (char.collisions & RIGHT)) char.actions = LEFT;
				} else if(char.actions & LEFT) {
					if(char.x <= patrolMinX || (char.collisions & LEFT)) char.actions = RIGHT;
				}
				char.looking = char.actions & (LEFT | RIGHT);
				char.dir |= char.actions & (LEFT | RIGHT);
			}
		}
		
		/* Chase the player, Pepé Le Pew algorithm */
		public function chase(target:Character):void {
			char.actions = 0;
			//return;
			var i:int;
			
			// are we in the same tile?
			if(target.mapX == char.mapX && target.mapY == char.mapY){
			
				if(target.x < char.x) char.actions |= LEFT;
				else if(target.x > char.x) char.actions |= RIGHT;
				if(target.rect.y >= char.rect.y + char.rect.height) char.actions |= DOWN;
				// a climbing target is a deadly target - do not engage, run away
				else if(target.rect.y + target.rect.height < char.rect.y + char.rect.height && char.state == Character.CLIMBING){
					state = FLEE;
					count = delay + Math.random() * delay * 2;
				}
			
			// perform an A* search to locate the target
			} else {
				start = dungeonGraph.nodes[char.mapY][char.mapX];
				
				// no node means the character must be falling or clipping a ledge
				if(start){
					path = dungeonGraph.getPath(start, dungeonGraph.nodes[target.mapY][target.mapX], searchSteps);
					
					if(path){
						
						//if(char == g.minion) dungeonGraph.drawPath(path, Game.debug, SCALE);
						
						node = path[path.length - 1];
						if(node.y == char.mapY){
							if(node.x > char.mapX){
								char.actions |= RIGHT;
								// get to the top of a ladder before leaping off it
								if(char.rect.y + char.rect.height > (char.mapY + 1) * SCALE) char.actions = UP;
								// a rare situation occurs when walking off a ladder to a ledge, resulting falling short
								// so we get the character to climb higher, allowing them to leap onto the ledge
								else if(!char.parentBlock && char.canClimb() && char.rect.y + char.rect.height > (char.mapY + SCALE * 1.5) * SCALE) char.actions = UP;
							} else if(node.x < char.mapX){
								char.actions |= LEFT;
								// get to the top of a ladder before leaping off it
								if(char.rect.y + char.rect.height > (char.mapY + 1) * SCALE) char.actions = UP;
								// a rare situation occurs when walking off a ladder to a ledge, resulting falling short
								// so we get the character to climb higher, allowing them to leap onto the ledge
								else if(!char.parentBlock && char.canClimb() && char.rect.y + char.rect.height > (char.mapY + SCALE * 1.5) * SCALE) char.actions = UP;
							}
						} else if(node.x == char.mapX){
							// heading up or down it's best to center on a tile to avoid the confusion
							// in moving from horizontal to vertical movement
							if(node.y > char.mapY){
								char.actions |= DOWN;
								
								if(char.x > char.tileCenter) char.actions |= LEFT;
								else if(char.x < char.tileCenter) char.actions |= RIGHT;
								
							} else if(node.y < char.mapY){
								if(char.canClimb()){
									char.actions |= UP;
								} else {
									if(char.x < char.tileCenter) char.actions |= LEFT;
									else if(char.x > char.tileCenter) char.actions |= RIGHT;
								}
							}
						}
					}
					
				} else {
					// character might be standing on the edge of a ledge - outside of a node
					char.actions |= DOWN;
				}
				
			}
			
			if(char.actions) char.looking = char.actions & (LEFT | RIGHT);
			char.dir = char.actions & (LEFT | RIGHT | UP | DOWN);
		}
		
		/* Run away from a target, no special algorithms here, it makes the panic look better */
		public function flee(target:Character):void {
			// if the character hits a wall, we make them run the other way for a period of time
			if(dontRunIntoTheWallCount){
				dontRunIntoTheWallCount--;
				if(char.collisions & RIGHT) {
					char.actions = LEFT;
				} else if(char.collisions & LEFT) {
					char.actions = RIGHT;
				}
			} else if(dontRunIntoTheWallCount <= 0){
				// if the target is overhead, that may mean certain death - limit movement to left or right
				if(
					char.rect.y >= target.rect.y + target.rect.height &&
					!(
						char.rect.x >= target.rect.x + target.rect.width ||
						char.rect.x + char.rect.width <= target.rect.x
					)
				){
					dontRunIntoTheWallCount = delay + Math.random();
					if(target.x > char.x) char.actions = RIGHT;
					else char.actions = LEFT;
				} else if(char.canClimb() && !(char.parentBlock && (char.parentBlock.type & Block.LEDGE) && !(char.blockMapType & Block.LADDER))){
					char.actions = UP;
				} else if(char.collisions & RIGHT) {
					char.actions = LEFT;
					dontRunIntoTheWallCount = delay + Math.random();
				} else if(char.collisions & LEFT) {
					char.actions = RIGHT;
					dontRunIntoTheWallCount = delay + Math.random();
				} else {
					if(char.x < target.x) char.actions = LEFT;
					else char.actions = RIGHT;
				}
			}
			
			char.looking = char.actions & (LEFT | RIGHT);
			char.dir = char.actions & (LEFT | RIGHT | UP | DOWN);
			
		}
		
		/* Traipse after the target - but give them personal space */
		public function follow(target:Character):void{
			// first order of business is to follow the target, using the basic chasing algorithm
			// the second order of business is to check through a schedule list of allies
			// and ensure that they have breathing room, this we do second so it can correct the chasing
			// behaviour
			var vx:Number = target.x - char.x;
			var vy:Number = target.y - char.y;
			var distSq:Number = vx * vx + vy * vy;
			if(distSq > FOLLOW_CHASE_EDGE_SQ){
				chase(target);
			} else if(distSq < FOLLOW_FLEE_EDGE_SQ){
				flee(target);
			} else {
				// face the same direction as the leader - this sets up a charging tactic against
				// approaching enemies
				char.dir = 0;
				if(char.looking != target.looking && (char.looking & (LEFT | RIGHT))){
					char.looking = target.looking & (LEFT | RIGHT);
				}
			}
		}
		
		/* Keep a respectable distance from the target whilst shooting at them */
		public function snipe(target:Character):void{
			
			//Game.debug.drawCircle(char.x, char.y, SNIPE_CHASE_EDGE);
			//Game.debug.drawCircle(char.x, char.y, SNIPE_FLEE_EDGE);
			
			// use melee combat when in contact with the enemy
			if(char.leftCollider && char.leftCollider is Character && char.enemy(char.leftCollider as Character)){
				char.dir = char.looking = char.actions = LEFT;
			} else if(char.rightCollider && char.rightCollider is Character && char.enemy(char.rightCollider as Character)){
				char.dir = char.looking = char.actions = RIGHT;
			} else {
				if(char.state == Character.CLIMBING){
					flee(target);
				} else if(char.mapY >= target.mapY){
					var vx:Number = target.x - char.x;
					var vy:Number = target.y - char.y;
					var distSq:Number = vx * vx + vy * vy;
					if(distSq < SNIPE_FLEE_EDGE_SQ){
						flee(target);
					} else if(distSq > SNIPE_CHASE_EDGE_SQ){
						chase(target);
					} else {
						// face towards the target and shoot when ready
						char.dir = 0;
						if((char.looking & RIGHT) && target.x < char.x){
							char.looking = LEFT;
						} else if((char.looking & LEFT) && target.x > char.x){
							char.looking = RIGHT;
						} else {
							shootWhenReady(target, g.blockMap, 10, ignore);
						}
					}
				} else {
					patrolAreaSet = false;
					state = PATROL;
				}
				
			}
		}
		
		/* Scan the floor about the character to establish an area to tread
		 * This saves us from having to check the floor every frame
		 */
		public function setPatrolArea(map:Vector.<Vector.<int>>):void{
			// setting your patrol area in mid air is a tad silly
			if(!(map[char.mapY + 1][char.mapX] & UP)){
				patrolAreaSet = false;
				return;
			}
			patrolMaxX = patrolMinX = (char.mapX + 0.5) * Game.SCALE;
			while(
				patrolMinX > Game.SCALE * 0.5 &&
				!(map[char.mapY][((patrolMinX - Game.SCALE) * Game.INV_SCALE) >> 0] & Block.WALL) &&
				(map[char.mapY + 1][((patrolMinX - Game.SCALE) * Game.INV_SCALE) >> 0] & UP)
			){
				patrolMinX -= Game.SCALE;
			}
			while(
				patrolMaxX < (map[0].length - 0.5) * Game.SCALE &&
				!(map[char.mapY][((patrolMaxX + Game.SCALE) * Game.INV_SCALE) >> 0] & Block.WALL) &&
				(map[char.mapY + 1][((patrolMaxX + Game.SCALE) * Game.INV_SCALE) >> 0] & UP)
			){
				patrolMaxX += Game.SCALE;
			}
			patrolAreaSet = true;
		}
		/* This shoots at the target Character when it has a line of sight to it */
		public function shootWhenReady(target:Character, map:Vector.<Vector.<int>>, length:int, ignore:int = 0):void {
			if(char.attackCount >= 1 && horizLOS(target, map, length, ignore)) {
				char.shoot(Missile.ARROW);
			}
		}
		/* Given a 90 degree cone of vision before our NPC, can we draw an unbroken line between it and the target
		 * this method assumes that it would not have been called had the NPC not been facing the right direction
		 */
		public function LOS(target:Character, map:Vector.<Vector.<int>>, ignore:int = 0):Boolean{
			
			var dx:Number = 0, dy:Number = 0, vx:Number, vy:Number, length:Number, test:Cast;
			
			vx = target.x - char.x;
			vy = target.y - char.y;
			length = Math.sqrt(vx * vx + vy * vy);
			if(length){
				dy = vy / length;
				// reject targets outside of the cone of vision
				if(dy < -0.5 || dy > 0.5 || (char.weapon && char.weapon.name == Item.BOW && target.mapY > char.mapY)) return false;
				dx = vx / length;
			}
			
			test = Cast.ray(char.rect.x + char.rect.width * 0.5, char.rect.y + char.rect.height * 0.5, dx, dy, map, ignore, g);
			
			if(test && test.collider == target) {
				return true;
			}
			return false;
		}
		
		/* Can we see the other character along a horizontal beam? */
		public function horizLOS(target:Character, map:Vector.<Vector.<int>>, length:int, ignore:int = 0):Boolean {
			if(target.mapY != char.mapY || !(char.looking & LEFT | RIGHT)) return false;
			var r:Number;
			var test:Cast = null;
			var rect:Rectangle = char.rect;
			if(char.looking & RIGHT){
				test = Cast.horiz(rect.x + rect.width - 1, rect.y + rect.height * 0.5, 1, length, map, ignore, g);
				if(test && test.collider == target) {
					return true;
				}
			} else if(char.looking & LEFT){
				test = Cast.horiz(rect.x, rect.y + rect.height * 0.5, -1, length, map, ignore, g);
				if(test && test.collider == target) {
					return true;
				}
			}
			return false;
		}
	}
	
}