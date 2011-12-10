package com.robotacid.ai {
	import com.robotacid.dungeon.DungeonBitmap;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.Minion;
	import com.robotacid.engine.Missile;
	import com.robotacid.engine.Player;
	import com.robotacid.geom.Pixel;
	import com.robotacid.phys.Cast;
	import com.robotacid.phys.Collider;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
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
		
		public static var g:Game;
		
		public var char:Character;
		public var target:Character;
		public var scheduleTarget:Character;
		public var leader:Character;
		
		public var state:int;
		public var count:int;
		public var delay:int;
		public var ignore:int;
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
		public static var dungeonGraph:DungeonGraph;
		
		private static var start:Node;
		private static var node:Node;
		private static var path:Vector.<Node>;
		private static var charPos:Point = new Point();
		private static var scheduleTargetPos:Point = new Point();
		
		// alliegances
		public static const PLAYER:int = 0;
		public static const MONSTER:int = 1;
		
		// behavioural states
		public static const PATROL:int = 0;
		public static const PAUSE:int = 1;
		public static const ATTACK:int = 2;
		public static const FLEE:int = 3;
		
		// directional states
		public static const UP:int = Collider.UP;
		public static const RIGHT:int = Collider.RIGHT;
		public static const DOWN:int = Collider.DOWN;
		public static const LEFT:int = Collider.LEFT;
		public static const SHOOT:int = 1 << 4;
		
		// scale constants
		public static const SCALE:Number = Game.SCALE;
		public static const INV_SCALE:Number = Game.INV_SCALE;
		
		public static const MONSTER_SEARCH_STEPS:int = 14;
		public static const MINION_SEARCH_STEPS:int = 20;
		
		public static const DEFAULT_LOS_BORDER:Number = 100;
		public static const INFRAVISION_LOS_BORDER_BONUS:Number = 200;
		
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
		
		public function Brain(char:Character, allegiance:int, leader:Character = null) {
			this.char = char;
			this.allegiance = allegiance;
			this.leader = leader;
			patrolAreaSet = false;
			state = PATROL;
			delay = Character.stats["pauses"][char.name];
			count = delay + g.random.range(delay);
			char.looking = g.random.value() < 0.5 ? LEFT : RIGHT;
			dontRunIntoTheWallCount = 0;
			sheduleIndex = 0;
			allyIndex = 0;
			ignore = Collider.LEDGE | Collider.LADDER | Collider.HEAD | Collider.CORPSE | Collider.ITEM;
			if(allegiance == PLAYER){
				ignore |= Collider.MINION | Collider.PLAYER;
				searchSteps = MINION_SEARCH_STEPS;
			} else {
				ignore |= Collider.MONSTER;
				searchSteps = MONSTER_SEARCH_STEPS;
			}
		}
		
		public function main():void{
			
			charPos.x = char.collider.x + char.collider.width * 0.5;
			charPos.y = char.collider.y + char.collider.height * 0.5;
			
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
			
			if(scheduleTarget){
				scheduleTargetPos.x = scheduleTarget.collider.x + scheduleTarget.collider.width * 0.5;
				scheduleTargetPos.y = scheduleTarget.collider.y + scheduleTarget.collider.height * 0.5;
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
						else (setPatrolArea(g.world.map));
						if(count-- <= 0){
							count = delay + g.random.range(delay);
							state = PAUSE;
							char.actions = char.dir = 0;
						}
					} else if(allegiance == PLAYER){
						if(g.player.state != Character.QUICKENING) follow(leader);
						else char.dir = 0;
					}
				} else if(state == PAUSE){
					if(count-- <= 0){
						count = delay + g.random.range(delay);
						state = PATROL;
					}
				}
				
				// indifferent characters do not look for a fight
				if(char.indifferent) return;
				
				// here's where we look for targets
				// any enemy touching us counts as a target, but we also look for targets
				// rather than checking all enemy characters, we check one at a time each frame
				if(scheduleTarget){
					if(char.collider.leftContact && (char.collider.leftContact.properties & Collider.CHARACTER) && char.enemy(char.collider.leftContact.userData)){
						target = char.collider.leftContact.userData as Character;
						state = ATTACK;
						count = 0;
					} else if(char.collider.rightContact && (char.collider.rightContact.properties & Collider.CHARACTER) && char.enemy(char.collider.rightContact.userData)){
						target = char.collider.rightContact.userData as Character;
						state = ATTACK;
						count = 0;
					
					// we test LOS when the player is within a square area near the monster - this is cheaper
					// than doing a radial test and we don't want all monsters calling LOS all the time
					// we also avoid suprise attacks by avoiding checks from monsters in the dark - unless they have infravision
					} else if(!char.inTheDark || (char.infravision)){
						if(!(scheduleTarget.armour && scheduleTarget.armour.name == Item.INVISIBILITY)){
							if(
								scheduleTargetPos.x < charPos.x  + char.losBorder && scheduleTargetPos.x > charPos.x - char.losBorder &&
								scheduleTargetPos.y > charPos.y - char.losBorder && scheduleTargetPos.y < charPos.y + char.losBorder
							){
								if(Cast.los(charPos, scheduleTarget.collider, new Point((char.looking & RIGHT) ? 1 : -1, 0), 0.5, g.world, ignore)){
									state = ATTACK;
									target = scheduleTarget;
									count = 0;
								}
							}
						}
					}
				}
			} else if(state == ATTACK){
				
				if(char.weapon && (char.weapon.range & Item.MISSILE)){
					snipe(target);
				} else {
					chase(target);
				}
				
				// if the target is directly above, get the hell out of there
				if(
					char.collider.y >= target.collider.y + target.collider.height &&
					!(
						char.collider.x >= target.collider.x + target.collider.width ||
						char.collider.x + char.collider.width <= target.collider.x
					)
				){
					state = FLEE;
					count = delay + g.random.range(delay * 2);
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
						// but not if they're on a ladder
						if(char.collider.state == Collider.HOVER){
							count = 1 + g.random.range(delay);
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
				if(char.collider.leftContact && (char.collider.leftContact.properties & Collider.CHARACTER) && char.enemy(char.collider.leftContact.userData)){
					target = char.collider.leftContact.userData as Character;
					state = ATTACK;
					count = 0;
				} else if(char.collider.rightContact && (char.collider.rightContact.properties & Collider.CHARACTER) && char.enemy(char.collider.rightContact.userData)){
					target = char.collider.rightContact.userData as Character;
					state = ATTACK;
					count = 0;
				}
			}
			
			// debugging colours
			//if(state == PATROL){
				//char.gfx.transform.colorTransform = new ColorTransform(1, 1, 1, 1, 0, 200);
			//} else if(state == ATTACK){
				//char.gfx.transform.colorTransform = new ColorTransform(1, 1, 1, 1, 200, 0);
			//} else if(state == FLEE){
				//char.gfx.transform.colorTransform = new ColorTransform(1, 1, 1, 1, 150, 150);
			//} else if(state == PAUSE){
				//char.gfx.transform.colorTransform = new ColorTransform(1, 1, 1, 1, 0, 150, 100);
			//}
		}
		
		/* Abandons any targets and reverts to PATROL state
		 *
		 * must be called on minion entering a new level as a target may still be pursued */
		public function clear():void{
			target = null;
			patrolAreaSet = false;
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
					if(charPos.x >= patrolMaxX || (char.collider.pressure & RIGHT)) char.actions = LEFT;
				} else if(char.actions & LEFT) {
					if(charPos.x <= patrolMinX || (char.collider.pressure & LEFT)) char.actions = RIGHT;
				}
				char.looking = char.actions & (LEFT | RIGHT);
				char.dir |= char.actions & (LEFT | RIGHT);
			}
		}
		
		/* Chase the player, Pepé Le Pew algorithm */
		public function chase(target:Character, following:Boolean = false):void {
			char.actions = 0;
			var i:int;
			var targetX:Number = target.collider.x + target.collider.width * 0.5;
			var targetY:Number = target.collider.y + target.collider.height * 0.5;
			
			// are we in the same tile?
			if(target.mapX == char.mapX && target.mapY == char.mapY){
			
				if(targetX < charPos.x) char.actions |= LEFT;
				else if(targetX > charPos.x) char.actions |= RIGHT;
				if(target.collider.y >= char.collider.y + char.collider.height) char.actions |= DOWN;
				// a climbing target is a deadly target - do not engage, run away
				else if(
					target.collider.y + target.collider.height < char.collider.y + char.collider.height &&
					char.collider.state == Collider.HOVER
				){
					state = FLEE;
					count = delay + g.random.range(delay * 2);
				}
			
			// perform an A* search to locate the target
			} else {
				start = dungeonGraph.nodes[char.mapY][char.mapX];
				
				// no node means the character must be falling or clipping a ledge
				if(start){
					path = dungeonGraph.getPathTo(start, dungeonGraph.nodes[target.mapY][target.mapX], searchSteps);
					
					if(path){
						
						//if(char == g.minion) dungeonGraph.drawPath(path, Game.debug, SCALE);
						//dungeonGraph.drawPath(path, Game.debug, SCALE);
						
						node = path[path.length - 1];
						if(node.y == char.mapY){
							if(node.x > char.mapX){
								char.actions |= RIGHT;
								// get to the top of a ladder before leaping off it
								if(char.collider.y + char.collider.height - Collider.INTERVAL_TOLERANCE > (char.mapY + 1) * SCALE){
									char.actions = UP;
								}
								// a rare situation occurs when walking off a ladder to a ledge, resulting falling short
								// so we get the character to climb higher, allowing them to leap onto the ledge
								else if(!char.collider.parent && char.canClimb() && char.collider.y + char.collider.height > (char.mapY + SCALE * 1.5) * SCALE){
									char.actions = UP;
								}
							} else if(node.x < char.mapX){
								char.actions |= LEFT;
								// get to the top of a ladder before leaping off it
								if(char.collider.y + char.collider.height - Collider.INTERVAL_TOLERANCE > (char.mapY + 1) * SCALE){
									char.actions = UP;
								}
								// a rare situation occurs when walking off a ladder to a ledge, resulting falling short
								// so we get the character to climb higher, allowing them to leap onto the ledge
								else if(!char.collider.parent && char.canClimb() && char.collider.y + char.collider.height > (char.mapY + SCALE * 1.5) * SCALE){
									char.actions = UP;
								}
							}
						} else if(node.x == char.mapX){
							// heading up or down it's best to center on a tile to avoid the confusion
							// in moving from horizontal to vertical movement
							if(node.y > char.mapY){
								char.actions |= DOWN;
								
								if(charPos.x > char.tileCenter) char.actions |= LEFT;
								else if(charPos.x < char.tileCenter) char.actions |= RIGHT;
								
							} else if(node.y < char.mapY){
								if(char.canClimb()){
									if(!following && stompDanger()){
										state = FLEE;
										count = delay + g.random.range(delay * 2);
									} else {
										char.actions |= UP;
									}
								} else {
									if(charPos.x < char.tileCenter) char.actions |= LEFT;
									else if(charPos.x > char.tileCenter) char.actions |= RIGHT;
								}
							}
						}
					}
					
				} else {
					// character might be standing on the edge of a ledge - outside of a node
					char.actions |= DOWN;
					// chase the target
					if(targetX < charPos.x) char.actions |= LEFT;
					else if(targetX > charPos.x) char.actions |= RIGHT;
					
				}
				
			}
			
			if(char.actions) char.looking = char.actions & (LEFT | RIGHT);
			char.dir = char.actions & (LEFT | RIGHT | UP | DOWN);
		}
		
		/* Run away from a target, Brown Trousers algorithm */
		public function flee(target:Character, following:Boolean = false):void {
			char.actions = 0;
			var i:int;
			var targetX:Number = target.collider.x + target.collider.width * 0.5;
			var targetY:Number = target.collider.y + target.collider.height * 0.5;
			
			// are we in the same tile?
			if(target.mapX == char.mapX && target.mapY == char.mapY){
			
				if(targetX < charPos.x) char.actions |= RIGHT;
				else if(targetX > charPos.x) char.actions |= LEFT;
				if(target.collider.y >= char.collider.y + char.collider.height) char.actions |= UP;
			
			// perform an Brown* search to escape the target
			} else {
				start = dungeonGraph.nodes[char.mapY][char.mapX];
				
				// no node means the character must be falling or clipping a ledge
				if(start){
					path = dungeonGraph.getPathAway(start, dungeonGraph.nodes[target.mapY][target.mapX], searchSteps);
					
					if(path){
						
						//if(char == g.minion) dungeonGraph.drawPath(path, Game.debug, SCALE);
						//dungeonGraph.drawPath(path, Game.debug, SCALE);
						
						node = path[path.length - 1];
						if(node.y == char.mapY){
							if(node.x > char.mapX){
								char.actions |= RIGHT;
								// get to the top of a ladder before leaping off it
								if(char.collider.y + char.collider.height - Collider.INTERVAL_TOLERANCE > (char.mapY + 1) * SCALE){
									char.actions = UP;
								}
								// a rare situation occurs when walking off a ladder to a ledge, resulting falling short
								// so we get the character to climb higher, allowing them to leap onto the ledge
								else if(!char.collider.parent && char.canClimb() && char.collider.y + char.collider.height > (char.mapY + SCALE * 1.5) * SCALE){
									char.actions = UP;
								}
							} else if(node.x < char.mapX){
								char.actions |= LEFT;
								// get to the top of a ladder before leaping off it
								if(char.collider.y + char.collider.height - Collider.INTERVAL_TOLERANCE > (char.mapY + 1) * SCALE){
									char.actions = UP;
								}
								// a rare situation occurs when walking off a ladder to a ledge, resulting falling short
								// so we get the character to climb higher, allowing them to leap onto the ledge
								else if(!char.collider.parent && char.canClimb() && char.collider.y + char.collider.height > (char.mapY + SCALE * 1.5) * SCALE){
									char.actions = UP;
								}
							}
						} else if(node.x == char.mapX){
							// heading up or down it's best to center on a tile to avoid the confusion
							// in moving from horizontal to vertical movement
							if(node.y > char.mapY){
								char.actions |= DOWN;
								
								if(charPos.x > char.tileCenter) char.actions |= LEFT;
								else if(charPos.x < char.tileCenter) char.actions |= RIGHT;
								
							} else if(node.y < char.mapY){
								if(char.canClimb()){
									char.actions |= UP;
								} else {
									if(charPos.x < char.tileCenter) char.actions |= LEFT;
									else if(charPos.x > char.tileCenter) char.actions |= RIGHT;
								}
							}
						}
					}
					
				} else {
					// character might be standing on the edge of a ledge - outside of a node
					char.actions |= DOWN;
					// flee the target
					if(targetX < charPos.x) char.actions |= RIGHT;
					else if(targetX > charPos.x) char.actions |= LEFT;
				}
				
			}
			
			char.looking = char.actions & (LEFT | RIGHT);
			char.dir = char.actions & (LEFT | RIGHT | UP | DOWN);
		}
		
		/* Traipse after the target - but give them personal space */
		public function follow(target:Character):void{
			var targetX:Number = target.collider.x + target.collider.width * 0.5;
			var targetY:Number = target.collider.y + target.collider.height * 0.5;
			// first order of business is to follow the target, using the basic chasing algorithm
			// the second order of business is to check through a schedule list of allies
			// and ensure that they have breathing room, this we do second so it can correct the chasing
			// behaviour
			var vx:Number = targetX - charPos.x;
			var vy:Number = targetY - charPos.y;
			var distSq:Number = vx * vx + vy * vy;
			if(distSq > FOLLOW_CHASE_EDGE_SQ){
				chase(target, true);
			} else if(distSq < FOLLOW_FLEE_EDGE_SQ){
				flee(target, true);
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
			
			var targetX:Number = target.collider.x + target.collider.width * 0.5;
			var targetY:Number = target.collider.y + target.collider.height * 0.5;
			
			//Game.debug.drawCircle(char.x, char.y, SNIPE_CHASE_EDGE);
			//Game.debug.drawCircle(char.x, char.y, SNIPE_FLEE_EDGE);
			
			// use melee combat when in contact with the enemy
			if(char.collider.leftContact && (char.collider.leftContact.properties & Collider.CHARACTER) && char.enemy(char.collider.leftContact.userData)){
				char.dir = char.looking = char.actions = LEFT;
			} else if(char.collider.rightContact && (char.collider.rightContact.properties & Collider.CHARACTER) && char.enemy(char.collider.rightContact.userData)){
				char.dir = char.looking = char.actions = RIGHT;
			} else {
				if(char.collider.state == Collider.HOVER){
					flee(target);
				} else if(char.mapY >= target.mapY){
					var vx:Number = targetX - charPos.x;
					var vy:Number = targetY - charPos.y;
					var distSq:Number = vx * vx + vy * vy;
					if(distSq < SNIPE_FLEE_EDGE_SQ){
						flee(target);
					} else if(distSq > SNIPE_CHASE_EDGE_SQ){
						chase(target);
					} else {
						// face towards the target and shoot when ready
						char.dir = 0;
						if((char.looking & RIGHT) && targetX < charPos.x){
							char.looking = LEFT;
						} else if((char.looking & LEFT) && targetX > charPos.x){
							char.looking = RIGHT;
						} else {
							shootWhenReady(target, 10, ignore);
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
				!(map[char.mapY][((patrolMinX - Game.SCALE) * Game.INV_SCALE) >> 0] & Collider.WALL) &&
				(map[char.mapY + 1][((patrolMinX - Game.SCALE) * Game.INV_SCALE) >> 0] & UP)
			){
				patrolMinX -= Game.SCALE;
			}
			while(
				patrolMaxX < (map[0].length - 0.5) * Game.SCALE &&
				!(map[char.mapY][((patrolMaxX + Game.SCALE) * Game.INV_SCALE) >> 0] & Collider.WALL) &&
				(map[char.mapY + 1][((patrolMaxX + Game.SCALE) * Game.INV_SCALE) >> 0] & UP)
			){
				patrolMaxX += Game.SCALE;
			}
			patrolAreaSet = true;
		}
		/* This shoots at the target Character when it has a line of sight to it */
		public function shootWhenReady(target:Character, length:int, ignore:int = 0):void {
			if(char.attackCount >= 1 && canShoot(target, length, ignore)) {
				char.shoot(Missile.ITEM);
			}
		}
		
		/* Can we see the other character along a horizontal beam? */
		public function canShoot(target:Character, length:int, ignore:int = 0):Boolean {
			if(target.mapY != char.mapY || !(char.looking & LEFT | RIGHT)) return false;
			var r:Number;
			var test:Cast = null;
			var rect:Rectangle = char.collider;
			if(char.looking & RIGHT){
				test = Cast.horiz(rect.x + rect.width - Collider.INTERVAL_TOLERANCE, rect.y + rect.height * 0.5, 1, length, ignore, g.world);
				if(test && test.collider == target.collider) {
					return true;
				}
			} else if(char.looking & LEFT){
				test = Cast.horiz(rect.x, rect.y + rect.height * 0.5, -1, length, ignore, g.world);
				if(test && test.collider == target.collider) {
					return true;
				}
			}
			return false;
		}
		
		/* Returns true if the character is in danger of being stomped */
		public function stompDanger():Boolean{
			return (char.collider.y + char.collider.height > target.collider.y + target.collider.height * 0.5 &&
				(
					char.collider.x <= target.collider.x + target.collider.width + SCALE * 0.5 &&
					char.collider.x + char.collider.width + SCALE * 0.5 >= target.collider.x
				)) ||
 				(
					scheduleTarget &&
					char.collider.y + char.collider.height > scheduleTarget.collider.y + scheduleTarget.collider.height * 0.5 &&
				(
					char.collider.x <= scheduleTarget.collider.x + scheduleTarget.collider.width + SCALE * 0.5 &&
					char.collider.x + char.collider.width + SCALE * 0.5 >= scheduleTarget.collider.x
				));
		}
	}
	
}