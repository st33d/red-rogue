package com.robotacid.ai {
	import com.robotacid.engine.Gate;
	import com.robotacid.level.MapBitmap;
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
		
		public static var game:Game;
		
		public var char:Character;
		public var target:Character;
		public var scheduleTarget:Character;
		public var leader:Character;
		public var path:Vector.<Node>;
		public var altNode:Node;
		
		// states
		public var state:int;
		public var count:int;
		public var delay:int;
		public var ignore:int;
		public var patrolMinX:Number;
		public var patrolMaxX:Number;
		public var patrolState:int;
		public var sheduleIndex:int;
		public var allyIndex:int;
		public var allegiance:int;
		public var searchSteps:int;
		public var firingTeam:int;
		public var prevCenter:Number;
		public var confusedCount:int;
		public var wallWalker:Boolean;
		public var giveUpCount:int;
		public var followChaseEdgeSq:Number;
		public var followFleeEdgeSq:Number;
		
		public static var playerCharacters:Vector.<Character>;
		public static var monsterCharacters:Vector.<Character>;
		public static var mapGraph:MapGraph;
		public static var walkWalkGraph:WallWalkGraph;
		
		public static var voiceCount:int;
		
		protected static var start:Node;
		protected static var node:Node;
		protected static var charPos:Point = new Point();
		protected static var scheduleTargetPos:Point = new Point();
		protected static var voiceDist:Number;
		protected static var crossedTileCenter:Boolean;
		
		// alliegances
		public static const PLAYER:int = 0;
		public static const MONSTER:int = 1;
		public static const NONE:int = 2;
		
		// behavioural states
		public static const PATROL:int = 0;
		public static const PAUSE:int = 1;
		public static const ATTACK:int = 2;
		public static const FLEE:int = 3;
		
		// patrol states
		public static const INIT:int = 0;
		public static const WALK:int = 1;
		public static const CLIMB_UP:int = 2;
		public static const CLIMB_DOWN:int = 3;
		
		// directional states
		public static const UP:int = Collider.UP;
		public static const RIGHT:int = Collider.RIGHT;
		public static const DOWN:int = Collider.DOWN;
		public static const LEFT:int = Collider.LEFT;
		public static const SHOOT:int = 1 << 4;
		
		// scale constants
		public static const SCALE:Number = Game.SCALE;
		public static const INV_SCALE:Number = Game.INV_SCALE;
		
		public static const VOICE_DELAY:int = 30;
		
		public static const MONSTER_SEARCH_STEPS:int = 14;
		public static const MINION_SEARCH_STEPS:int = 20;
		
		public static const DEFAULT_LOS_BORDER:Number = 100;
		public static const INFRAVISION_LOS_BORDER_BONUS:Number = 200;
		
		public static const FOLLOW_CHASE_EDGE:Number = Game.SCALE * 1.7;
		public static const FOLLOW_FLEE_EDGE:Number = Game.SCALE * 1;
		
		public static const SNIPE_CHASE_EDGE:Number = Game.SCALE * 5;
		public static const SNIPE_FLEE_EDGE:Number = Game.SCALE * 2.5;
		public static const SNIPE_HAND_2_HAND_EDGE:Number = Game.SCALE * 1;
		public static const SNIPE_CHASE_EDGE_SQ:Number = SNIPE_CHASE_EDGE * SNIPE_CHASE_EDGE;
		public static const SNIPE_FLEE_EDGE_SQ:Number = SNIPE_FLEE_EDGE * SNIPE_FLEE_EDGE;
		public static const SNIPE_HAND_2_HAND_SQ:Number = SNIPE_HAND_2_HAND_EDGE * SNIPE_HAND_2_HAND_EDGE;
		
		public static function initCharacterLists():void{
			playerCharacters = new Vector.<Character>();
			monsterCharacters = new Vector.<Character>();
		}
		public static function initMapGraph(bitmap:MapBitmap, exit:Pixel):void{
			mapGraph = new MapGraph(bitmap, exit);
			walkWalkGraph = new WallWalkGraph(bitmap, exit);
		}
		
		public function Brain(char:Character, allegiance:int, leader:Character = null) {
			this.char = char;
			this.allegiance = allegiance;
			if(allegiance == PLAYER) firingTeam = Collider.PLAYER_MISSILE;
			else if(allegiance == MONSTER) firingTeam = Collider.MONSTER_MISSILE;
			this.leader = leader;
			patrolState = INIT;
			state = PATROL;
			delay = Character.stats["pauses"][char.name];
			count = delay + game.random.range(delay);
			char.looking = game.random.coinFlip() ? LEFT : RIGHT;
			sheduleIndex = 0;
			allyIndex = 0;
			ignore = Collider.LEDGE | Collider.LADDER | Collider.HEAD | Collider.CORPSE | Collider.ITEM;
			prevCenter = char.collider.x + char.collider.width * 0.5;
			followChaseEdgeSq = FOLLOW_CHASE_EDGE * FOLLOW_CHASE_EDGE;
			followFleeEdgeSq = FOLLOW_FLEE_EDGE * FOLLOW_FLEE_EDGE;
			if(allegiance == PLAYER){
				ignore |= Collider.MINION | Collider.PLAYER;
				searchSteps = MINION_SEARCH_STEPS;
			} else {
				ignore |= Collider.MONSTER;
				searchSteps = MONSTER_SEARCH_STEPS;
			}
			// assign the correct graph for the brain to use
			wallWalker = (char.name == Character.WRAITH || (char.rank == Character.ELITE && char.name == Character.BANSHEE));
		}
		
		public function main():void{
			
			charPos.x = char.collider.x + char.collider.width * 0.5;
			charPos.y = char.collider.y + char.collider.height * 0.5;
			var charContact:Character;
			if(char.collider.leftContact) charContact = char.collider.leftContact.userData as Character;
			if(!charContact && char.collider.rightContact) charContact = char.collider.rightContact.userData as Character;
			
			crossedTileCenter = (
				(prevCenter < char.tileCenter && charPos.x > char.tileCenter) ||
				(prevCenter > char.tileCenter && charPos.x < char.tileCenter)
			);
			
			// only random targets whilst confused
			if(confusedCount){
				confusedCount--;
				if(confusedCount == 0) clear();
				else if(confusedCount % 30 == 0) confusedBehaviour();
				
			} else {
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
			}
			
			if(state == PATROL || state == PAUSE){
				if(state == PATROL){
					if(allegiance == MONSTER){
						if(patrolState){
							patrol();
						} else {
							if(char.collider.state != Collider.FALL){
								setPatrolArea(game.world.map);
							}
						}
						
						if(count-- <= 0){
							count = delay + game.random.range(delay);
							state = PAUSE;
							char.actions = char.dir = 0;
						}
					} else if(allegiance == PLAYER){
						if(game.player.state != Character.QUICKENING) follow(leader);
						else char.dir = 0;
					}
				} else if(state == PAUSE){
					if(count-- <= 0){
						count = delay + game.random.range(delay);
						state = PATROL;
						// monsters will vocalise when they have finished pausing
						if(voiceCount == 0){
							game.createDistSound(char.mapX, char.mapY, "voice", char.voice);
							voiceCount = VOICE_DELAY + game.random.range(VOICE_DELAY);
						}
						// before resuming patrol randomly check for issues and exploration avenues
						if(patrolState && game.random.coinFlip()){
							// check for being trapped in an enclosure
							if(
								!wallWalker &&
								char.collider.parent == char.collider.mapCollider &&
								(char.collider.mapCollider.properties & Collider.LEDGE) &&
								char.mapX > 0 &&
								(game.world.map[char.mapY][char.mapX - 1] & Collider.WALL) &&
								char.mapX < game.world.width - 1 &&
								(game.world.map[char.mapY][char.mapX + 1] & Collider.WALL)
							){
								char.ledgeDrop();
								char.actions = char.dir = DOWN;
								patrolState = INIT;
								
							} else if(char.canClimb()){
								// explore a ladder
								var climbingOptions:Array = [];
								if(char.mapProperties & Collider.LADDER) climbingOptions.push(CLIMB_UP);
								if(game.world.map[((char.collider.y + char.collider.height + Collider.INTERVAL_TOLERANCE) * INV_SCALE) >> 0][char.mapX] & Collider.LADDER) climbingOptions.push(CLIMB_DOWN);
								patrolState = climbingOptions[game.random.rangeInt(climbingOptions.length)];
								
								// climbing down physically has little benefit
								if(patrolState == CLIMB_DOWN){
									char.ledgeDrop();
									char.actions = char.dir = DOWN;
									patrolState = INIT;
								}
								
							} else {
								// reinitialise patrol state
								patrolState = INIT;
							}
						}
					}
				}
				
				// indifferent characters do not look for a fight
				if(char.indifferent) return;
				
				// here's where we look for targets
				// any enemy touching us counts as a target, but we also look for targets
				// rather than checking all enemy characters, we check one at a time each frame
				if(scheduleTarget){
					// protect the leader
					var leaderContact:Character;
					if(leader && leader.active){
						if(leader.collider.leftContact) leaderContact = leader.collider.leftContact.userData as Character;
						if(!charContact && leader.collider.rightContact) leaderContact = leader.collider.rightContact.userData as Character;
					}
					
					if(charContact && char.enemy(charContact)){
						attack(charContact);
					
					} else if(
						leaderContact && char.enemy(leaderContact) &&
						!(leaderContact.type == Character.GATE || leaderContact.type == Character.STONE)
					){
						attack(leaderContact);
					
					// we test LOS when the player is within a square area near the monster - this is cheaper
					// than doing a radial test and we don't want all monsters calling LOS all the time
					// we also avoid suprise attacks by avoiding checks from monsters in the dark - unless they have infravision
					} else if(!char.inTheDark || (char.infravision)){
						if(!(scheduleTarget.armour && scheduleTarget.armour.name == Item.INVISIBILITY)){
							if(
								scheduleTargetPos.x < charPos.x  + char.losBorder && scheduleTargetPos.x > charPos.x - char.losBorder &&
								scheduleTargetPos.y > charPos.y - char.losBorder && scheduleTargetPos.y < charPos.y + char.losBorder
							){
								if(Cast.los(charPos, scheduleTarget.collider, new Point((char.looking & RIGHT) ? 1 : -1, 0), 0.5, game.world, ignore)){
									attack(scheduleTarget);
									
									// characters will vocalise when they see a target
									if(voiceCount == 0){
										game.createDistSound(char.mapX, char.mapY, "voice", char.voice);
										voiceCount = VOICE_DELAY + game.random.range(VOICE_DELAY);
									}
								}
							}
						}
					}
				}
			} else if(state == ATTACK){
				
				if(!target || !target.active){
					clear();
				
				} else if(
					target.type == Character.GATE ||
					target.type == Character.STONE
				){
					chase(target);
					// get bored of attacking gates and stones
					if(game.random.coinFlip()) clear();
					
				// stomp check
				} else if(
					char.collider.y >= target.collider.y + target.collider.height &&
					!(
						char.collider.x >= target.collider.x + target.collider.width ||
						char.collider.x + char.collider.width <= target.collider.x
					)
				){
					if(target.type == Character.GATE) clear();
					else flee(target);
				
				// attack logic
				} else {
					if(target.type != Character.GATE && (char.throwable || (char.weapon && (char.weapon.range & Item.MISSILE)))){
						snipe(target);
					} else {
						chase(target);
						// commute allies to the target
						if(charContact && target.active && !char.enemy(charContact) && charContact.brain) charContact.brain.copyState(this);
					}
					// get bored of chasing targets we can't see
					if(target && !Cast.los(charPos, target.collider, new Point((char.looking & RIGHT) ? 1 : -1, 0), 0.5, game.world, ignore)){
						if((giveUpCount--) <= 0) clear();
					} else {
						giveUpCount = delay * 2;
					}
				}
				
			} else if(state == FLEE){
				
				if(!target || !target.active){
					clear();
					
				} else {
					avoid(target);
					// commute allies away from the target
					if(charContact && target.active && !char.enemy(charContact) && charContact.brain) charContact.brain.copyState(this);
					if(count-- <= 0){
						if(char.inTheDark){
							// we want fleeing characters in the dark to go back to patrolling
							// but not if they're on a ladder
							if(char.collider.state == Collider.HOVER){
								count = 1 + game.random.range(delay);
							} else {
								clear();
							}
						} else {
							// is the target a gate?
							if(target.type == Character.GATE) clear();
							else attack(target);
						}
					}
					if(charContact && char.enemy(charContact)){
						attack(target);
					}
				}
			}
			
			prevCenter = charPos.x;
		}
		
		/* Called when a character fails a bravery check during melee, and used by Horror characters */
		public function flee(target:Character):void{
			if(state == FLEE && this.target == target) return;
			state = FLEE;
			altNode = null;
			count = delay + game.random.range(delay * 2);
			// for characters that fail a bravery check we need to halt lateral movement
			// else they will enter ATTACK state again
			char.collider.vx = 0;
			this.target = target;
		}
		
		/* Called when a character engages a target */
		public function attack(target:Character):void{
			state = ATTACK;
			altNode = null;
			count = 0;
			giveUpCount = delay * 2;
			this.target = target;
		}
		
		/* Abandons any targets and reverts to PATROL state
		 *
		 * must be called on minion entering a new level as a target may still be pursued */
		public function clear():void{
			target = null;
			patrolState = INIT;
			state = PATROL;
			altNode = null;
			// drop from ladder
			if(char.collider.state == Collider.HOVER){
				char.collider.state = Collider.FALL;
				char.collider.divorce();
			}
		}
		
		/* Copys one brain state on to another, along with target */
		public function copyState(template:Brain):void{
			// refuse state copying when either is confused
			if(confusedCount || template.confusedCount) return;
			
			state = template.state;
			target = template.target;
			
			// interpret the state in the character's own fashion
			if(state == FLEE){
				flee(template.target);
			} else if(state == ATTACK){
				attack(template.target);
			}
		}
		
		/* This walks a character left and right in their patrol area
		 * The patrol area must be defined with setPatrolArea before using this method
		 */
		public function patrol():void {
			char.dir = 0;
			
			if(char.actions == 0) char.actions = char.looking & (LEFT | RIGHT);
			
			if(char.state == Character.WALKING){
				if(patrolState == WALK){
					if(char.actions & RIGHT) {
						if(charPos.x >= patrolMaxX || (char.collider.pressure & RIGHT)) char.actions = LEFT;
					} else if(char.actions & LEFT) {
						if(charPos.x <= patrolMinX || (char.collider.pressure & LEFT)) char.actions = RIGHT;
					}
					char.looking = char.actions & (LEFT | RIGHT);
					char.dir |= char.actions & (LEFT | RIGHT);
					
				} else if(patrolState == CLIMB_UP){
					char.dir = char.actions = UP;
					
					// bumped our head, drop
					if(char.collider.upContact){
						char.ledgeDrop();
						char.actions = char.dir = DOWN;
						patrolState = INIT;
						
					} else if(!char.canClimb()){
						patrolState = INIT;
					}
				}
			}
		}
		
		/* Chase the player, Pepé Le Pew algorithm */
		public function chase(target:Character, following:Boolean = false):void {
			char.actions = 0;
			var i:int;
			var targetX:Number = target.collider.x + target.collider.width * 0.5;
			var targetY:Number = target.collider.y + target.collider.height * 0.5;
			var graph:MapGraph = wallWalker ? walkWalkGraph : mapGraph;
			
			// are we in the same tile?
			if(target.mapX == char.mapX && target.mapY == char.mapY){
				
				// when no-clipping a target, get out of the current tile
				if(
					!following &&
					target.collider.x + target.collider.width > char.collider.x &&
					char.collider.x + char.collider.width > target.collider.x &&
					target.collider.y + target.collider.height > char.collider.y &&
					char.collider.y + char.collider.height > target.collider.y
				) avoid(target);
				// else approach the target
				else if(targetX < charPos.x) char.actions |= LEFT;
				else if(targetX > charPos.x) char.actions |= RIGHT;
				if(target.collider.y >= char.collider.y + char.collider.height) char.actions |= DOWN;
				// a climbing target is a deadly target - do not engage, run away
				else if(
					target.collider.y + target.collider.height < char.collider.y + char.collider.height &&
					char.collider.state == Collider.HOVER
				){
					flee(target);
				}
				if(altNode) altNode = null;
			
			// perform an A* search to locate the target
			} else {
				start = graph.nodes[char.mapY][char.mapX];
				
				// no node means the character must be falling or clipping a ledge
				if(start){
					
					path = graph.getPathTo(start, graph.nodes[target.mapY][target.mapX], searchSteps);
					
					if(path){
						
						// choose node
						node = path[path.length - 1];
						
						// is this a metaheuristic dead end? choose a panic node
						if(path.length == 1 && node == start && !(node.x == target.mapX && node.y == target.mapY)){
							// only select a random node after crossing the center of the tile
							if(!altNode){
								if(!crossedTileCenter){
									if(charPos.x < char.tileCenter) char.actions |= RIGHT;
									else if(charPos.x > char.tileCenter) char.actions |= LEFT;
								} else {
									altNode = graph.getRandomNode(start, game.random);
								}
							}
							if(altNode) node = altNode;
						} else if(altNode){
							altNode = null;
						}
						
						// navigate to node
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
								// if the target is below, avoid climbing down in favour of dropping
								if(!following && char.collider.state == Collider.HOVER){
									char.collider.state = Collider.FALL;
								} else {
									char.actions |= DOWN;
									if(charPos.x > char.tileCenter) char.actions |= LEFT;
									else if(charPos.x < char.tileCenter) char.actions |= RIGHT;
								}
								
							} else if(node.y < char.mapY){
								if(char.canClimb()){
									if(!following && stompDanger()){
										flee(target);
									} else {
										char.actions |= UP;
									}
								} else {
									if(charPos.x > char.tileCenter) char.actions |= LEFT;
									else if(charPos.x < char.tileCenter) char.actions |= RIGHT;
								}
							}
							
						// we must be looking at a dive node
						} else {
							if(node.x > char.mapX){
								char.actions |= RIGHT;
							} else if(node.x < char.mapX){
								char.actions |= LEFT;
							}
						}
					}
				}
				// no path data to work with
				if(!start || !path){
					// character might be standing on the edge of a ledge - outside of a node
					char.actions |= DOWN;
					// chase the target blindly
					if(char.mapY == target.mapY){
						if(targetX < charPos.x) char.actions |= LEFT;
						else if(targetX > charPos.x) char.actions |= RIGHT;
					}
					
				}
				
			}
			
			// jumping might help an attack via smite
			if(char.canJump && !following && char.state == Character.WALKING && target.mapY == char.mapY){
				var charSpeedTemp:Number = char.speedModifier;
				var targetSpeedTemp:Number = target.speedModifier;
				if(charSpeedTemp < Character.MIN_SPEED_MODIFIER) charSpeedTemp = Character.MIN_SPEED_MODIFIER;
				if(charSpeedTemp > Character.MAX_SPEED_MODIFIER) charSpeedTemp = Character.MAX_SPEED_MODIFIER;
				if(targetSpeedTemp < Character.MIN_SPEED_MODIFIER) targetSpeedTemp = Character.MIN_SPEED_MODIFIER;
				if(targetSpeedTemp > Character.MAX_SPEED_MODIFIER) targetSpeedTemp = Character.MAX_SPEED_MODIFIER;
				charSpeedTemp *= char.speed;
				targetSpeedTemp *= char.speed;
				if(Math.abs(targetX - charPos.x) <= charSpeedTemp + targetSpeedTemp * 2){
					char.jump();
				}
			}
			
			if(char.actions & (LEFT | RIGHT)) char.looking = char.actions & (LEFT | RIGHT);
			char.dir = char.actions & (LEFT | RIGHT | UP | DOWN);
		}
		
		/* Run away from a target, Brown Trousers algorithm */
		public function avoid(target:Character, following:Boolean = false):void {
			char.actions = 0;
			var i:int;
			var targetX:Number = target.collider.x + target.collider.width * 0.5;
			var targetY:Number = target.collider.y + target.collider.height * 0.5;
			var graph:MapGraph = wallWalker ? walkWalkGraph : mapGraph;
			
			// are we in the same tile?
			if(target.mapX == char.mapX && target.mapY == char.mapY){
			
				if(targetX < charPos.x) char.actions |= RIGHT;
				else if(targetX > charPos.x) char.actions |= LEFT;
				else char.actions = game.random.coinFlip() ? RIGHT : LEFT;
				if(target.collider.y >= char.collider.y + char.collider.height) char.actions |= UP;
				if(altNode) altNode = null;
				
				// jumping might help escape
				if(!following && char.canJump && char.state == Character.WALKING && target.collider.y + target.collider.height >= char.collider.y) char.jump();
			
			// perform an Brown* search to escape the target
			} else {
				start = graph.nodes[char.mapY][char.mapX];
				
				// no node means the character must be falling or clipping a ledge
				if(start){
					// dive nodes confuse the Brown* algorithm, so we can't use them
					path = graph.getPathAway(start, graph.nodes[target.mapY][target.mapX], searchSteps, false);
					
					if(path){
						
						// choose node
						node = path[path.length - 1];
						
						if(!following){
							// the character might be in a dead end - to lengthen their dither cycle,
							// get them to fully visit the node, otherwise they will twiddle on the spot
							if(altNode){
								node = altNode;
								if(node.x == char.mapX && node.y == char.mapY){
									if(!crossedTileCenter){
										if(charPos.x < char.tileCenter) char.actions |= RIGHT;
										else if(charPos.x > char.tileCenter) char.actions |= LEFT;
									} else {
										altNode = null;
									}
								}
							} else if(path.length == 1){
								altNode = node;
							} else {
								altNode = null;
							}
						}
						
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
								// if the target is above, avoid climbing down in favour of dropping
								if(!following && target.mapX == char.mapX){
									if(char.collider.state == Collider.HOVER){
										char.collider.state = Collider.FALL;
									}
									if(char.collider.parent) char.actions |= DOWN;
								} else {
									char.actions |= DOWN;
									if(charPos.x > char.tileCenter) char.actions |= LEFT;
									else if(charPos.x < char.tileCenter) char.actions |= RIGHT;
								}
							} else if(node.y < char.mapY){
								if(char.canClimb()){
									char.actions |= UP;
								} else {
									if(charPos.x > char.tileCenter) char.actions |= LEFT;
									else if(charPos.x < char.tileCenter) char.actions |= RIGHT;
								}
							}
							
						// we must be looking at a dive node
						} else {
							if(node.x > char.mapX){
								char.actions |= RIGHT;
							} else if(node.x < char.mapX){
								char.actions |= LEFT;
							}
						}
					}
					
				}
				// no path data to work with
				if(!start || !path){
					// character might be standing on the edge of a ledge - outside of a node
					char.actions |= DOWN;
					// flee the target
					if(char.mapY == target.mapY){
						if(targetX < charPos.x) char.actions |= RIGHT;
						else if(targetX > charPos.x) char.actions |= LEFT;
					}
				}
				
			}
			
			if(char.actions & (LEFT | RIGHT)) char.looking = char.actions & (LEFT | RIGHT);
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
			if(distSq > followChaseEdgeSq){
				chase(target, true);
			} else if(distSq < followFleeEdgeSq){
				avoid(target, true);
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
			
			// use melee combat when in contact with the enemy
			if(char.collider.leftContact && (char.collider.leftContact.properties & Collider.CHARACTER) && char.enemy(char.collider.leftContact.userData)){
				char.dir = char.looking = char.actions = LEFT;
			} else if(char.collider.rightContact && (char.collider.rightContact.properties & Collider.CHARACTER) && char.enemy(char.collider.rightContact.userData)){
				char.dir = char.looking = char.actions = RIGHT;
			} else {
				if(char.collider.state == Collider.HOVER){
					avoid(target);
				} else {
					var vx:Number = targetX - charPos.x;
					var vy:Number = targetY - charPos.y;
					var distSq:Number = vx * vx + vy * vy;
					if(distSq < SNIPE_HAND_2_HAND_EDGE){
						chase(target);
					} else if(distSq < SNIPE_FLEE_EDGE_SQ){
						avoid(target);
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
				}
			}
		}
		
		/* Scan the floor about the character to establish an area to tread
		 * This saves us from having to check the floor every frame
		 */
		public function setPatrolArea(map:Vector.<Vector.<int>>):void{
			// setting your patrol area in mid air is a tad silly
			if(char.collider.parent != char.collider.mapCollider){
				// perform a dead drop
				if(char.collider.state == Collider.HOVER){
					char.ledgeDrop();
				}
				return;
			}
			patrolMaxX = patrolMinX = (char.mapX + 0.5) * Game.SCALE;
			while(
				patrolMinX > Game.SCALE * 0.5 &&
				(
					!(map[char.mapY][((patrolMinX - Game.SCALE) * Game.INV_SCALE) >> 0] & Collider.WALL) ||
					(
						wallWalker &&
						!(map[char.mapY][((patrolMinX - Game.SCALE) * Game.INV_SCALE) >> 0] & Collider.MAP_EDGE)
					)
				) &&
				(map[char.mapY + 1][((patrolMinX - Game.SCALE) * Game.INV_SCALE) >> 0] & UP)
			){
				patrolMinX -= Game.SCALE;
			}
			while(
				patrolMaxX < (map[0].length - 0.5) * Game.SCALE &&
				(
					!(map[char.mapY][((patrolMaxX + Game.SCALE) * Game.INV_SCALE) >> 0] & Collider.WALL) ||
					(
						wallWalker &&
						!(map[char.mapY][((patrolMaxX + Game.SCALE) * Game.INV_SCALE) >> 0] & Collider.MAP_EDGE)
					)
				)&&
				(map[char.mapY + 1][((patrolMaxX + Game.SCALE) * Game.INV_SCALE) >> 0] & UP)
			){
				patrolMaxX += Game.SCALE;
			}
			patrolState = WALK;
			char.actions = 0;
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
				test = Cast.horiz(rect.x + rect.width - Collider.INTERVAL_TOLERANCE, rect.y + rect.height * 0.5, 1, length, ignore, game.world);
				if(test && test.collider == target.collider) {
					return true;
				}
			} else if(char.looking & LEFT){
				test = Cast.horiz(rect.x, rect.y + rect.height * 0.5, -1, length, ignore, game.world);
				if(test && test.collider == target.collider) {
					return true;
				}
			}
			return false;
		}
		
		/* Is there an enemy missile headed towards the char? */
		public function missileDanger():Boolean{
			var rect:Rectangle = new Rectangle(char.collider.x - SCALE * 2, char.collider.y, char.collider.width + SCALE * 4, char.collider.height);
			var colliders:Vector.<Collider> = game.world.getCollidersIn(rect, char.collider, Collider.PLAYER_MISSILE | Collider.MONSTER_MISSILE);
			var collider:Collider;
			for(var i:int = 0; i < colliders.length; i++){
				collider = colliders[i];
				if(
					!(collider.properties & firingTeam) && (
						(collider.vx > 0 && collider.x + collider.width < char.collider.x) ||
						(collider.vx < 0 && collider.x > char.collider.x + char.collider.width)
					)
				){
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
		
		/* Enters the character into a confused state */
		public function confuse(delay:int):void{
			confusedCount += delay;
		}
		
		/* Randomly assigns a target - any target */
		protected function confusedBehaviour():void{
			
			var characters:Vector.<Character> = monsterCharacters.concat(playerCharacters);
			
			if(game.random.coinFlip()){
				flee(characters[game.random.rangeInt(characters.length)]);
			} else {
				attack(characters[game.random.rangeInt(characters.length)]);
			}
		}
	}
	
}