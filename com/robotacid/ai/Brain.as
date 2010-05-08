package com.robotacid.ai {
	import com.robotacid.engine.Character;
	import com.robotacid.engine.CharacterAttributes;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.Minion;
	import com.robotacid.engine.Missile;
	import com.robotacid.engine.Player;
	import com.robotacid.geom.Rect;
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Cast;
	import com.robotacid.phys.Collider;
	
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
		public var schedule_target:Character;
		public var buddy_target:Character;
		public var ignore:int;
		
		
		public var state:int;
		public var count:int;
		public var delay:int;
		public var patrol_min_x:Number;
		public var patrol_max_x:Number;
		public var patrol_area_set:Boolean;
		public var dont_run_into_the_wall_count:int;
		public var shedule_index:int;
		public var ally_index:int;
		public var allegiance:int;
		
		public static var player_characters:Vector.<Character>;
		public static var monster_characters:Vector.<Character>;
		
		// alliegances
		public static const PLAYER:int = 0;
		public static const MONSTER:int = 1;
		
		// behavioural states
		public static const PATROL:int = 0;
		public static const PAUSE:int = 1;
		public static const ATTACK:int = 2;
		public static const FLEE:int = 3;
		
		// directional states
		public static const UP:int = Rect.UP;
		public static const RIGHT:int = Rect.RIGHT;
		public static const DOWN:int = Rect.DOWN;
		public static const LEFT:int = Rect.LEFT;
		public static const SHOOT:int = 1 << 4;
		
		// scale constants
		public static var scan_step:Number = Collider.scan_step;
		public static const SCALE:Number = Game.SCALE;
		public static const INV_SCALE:Number = Game.INV_SCALE;
		
		public static const LOS_BORDER:Number = 100;
		
		public static const FOLLOW_CHASE_EDGE:Number = Game.SCALE * 1.5;
		public static const FOLLOW_FLEE_EDGE:Number = Game.SCALE * 1;
		public static const FOLLOW_CHASE_EDGE_SQ:Number = FOLLOW_CHASE_EDGE * FOLLOW_CHASE_EDGE;
		public static const FOLLOW_FLEE_EDGE_SQ:Number = FOLLOW_FLEE_EDGE * FOLLOW_FLEE_EDGE;
		
		public static const SNIPE_CHASE_EDGE:Number = Game.SCALE * 5;
		public static const SNIPE_FLEE_EDGE:Number = Game.SCALE * 2;
		public static const SNIPE_CHASE_EDGE_SQ:Number = SNIPE_CHASE_EDGE * SNIPE_CHASE_EDGE;
		public static const SNIPE_FLEE_EDGE_SQ:Number = SNIPE_FLEE_EDGE * SNIPE_FLEE_EDGE;
		
		public static function init():void{
			player_characters = new Vector.<Character>();
			monster_characters = new Vector.<Character>();
		}
		
		public function Brain(char:Character, allegiance:int, g:Game) {
			this.g = g;
			this.char = char;
			this.allegiance = allegiance;
			patrol_area_set = false;
			state = PATROL;
			delay = CharacterAttributes.NAME_PAUSES[char.name];
			count = delay + Math.random() * delay;
			char.looking = Math.random() > 0.5 ? LEFT : RIGHT;
			dont_run_into_the_wall_count = 0;
			shedule_index = 0;
			ally_index = 0;
			ignore = Block.LEDGE | Block.LADDER;
			if(allegiance == PLAYER){
				ignore |= Block.MINION | Block.PLAYER;
			} else {
				ignore |= Block.MONSTER;
			}
		}
		
		public function main():void{
			
			if(allegiance == PLAYER){
				if(monster_characters.length){
					shedule_index = (shedule_index + 1) % monster_characters.length;
					schedule_target = monster_characters[shedule_index];
				} else {
					schedule_target = null;
				}
			} else if(allegiance == MONSTER){
				if(player_characters.length){
					shedule_index = (shedule_index + 1) % player_characters.length;
					schedule_target = player_characters[shedule_index];
				} else {
					schedule_target = null;
				}
			}
			
			if(state == PATROL || state == PAUSE){
				if(state == PATROL){
					if(allegiance == MONSTER){
						if(patrol_area_set){
							patrol();
							//Game.debug.moveTo(char.x, char.y);
							//Game.debug.lineTo(patrol_max_x, char.y);
							//Game.debug.moveTo(char.x, char.y);
							//Game.debug.lineTo(patrol_min_x, char.y);
						}
						else (setPatrolArea(g.block_map));
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
				if(schedule_target){
					if(char.left_collider && (char.left_collider is Character) && char.enemy((char.left_collider as Character))){
						target = (char.left_collider as Character);
						state = ATTACK;
						count = 0;
					}
					if(char.right_collider && (char.right_collider is Character) && char.enemy((char.right_collider as Character))){
						target = (char.right_collider as Character);
						state = ATTACK;
						count = 0;
					}
					// we test LOS when the player is within a square area near the monster - this is cheaper
					// than doing a radial test and we don't want all monsters calling LOS all the time
					// we also avoid suprise attacks by avoiding checks from monsters in the dark
					if(!char.in_the_dark){
						if(!(schedule_target.armour && schedule_target.armour.name == Item.INVISIBILITY)){
							if((char.looking & RIGHT) && schedule_target.x > char.x && schedule_target.x < char.x + LOS_BORDER && schedule_target.y > char.y - LOS_BORDER && schedule_target.y < char.y + LOS_BORDER){
								//Game.debug.moveTo(char.x, char.y);
								//Game.debug.lineTo(schedule_target.x, schedule_target.y);
								if(LOS(schedule_target, g.block_map, ignore)){
									state = ATTACK;
									target = schedule_target;
									count = 0;
								}
							}
							if((char.looking & LEFT) && schedule_target.x < char.x && schedule_target.x > char.x - LOS_BORDER && schedule_target.y > char.y - LOS_BORDER && schedule_target.y < char.y + LOS_BORDER){
								//Game.debug.moveTo(char.x, char.y);
								//Game.debug.lineTo(schedule_target.x, schedule_target.y);
								if(LOS(schedule_target, g.block_map, ignore)){
									state = ATTACK;
									target = schedule_target;
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
				
				// if a schedule_target is directly above, get the hell out of there
				
				if(schedule_target){
					if(
						char.y > schedule_target.rect.y + schedule_target.rect.height &&
						char.map_x == schedule_target.map_x 
					){
						state = FLEE;
						target = schedule_target;
						count = delay + Math.random() * delay * 2;
					}
				}
				
				// sometimes the target can be at the same height on a ladder
				// when two characters are chasing each other, this causes a stalemate,
				// an infinite loop, one of them must flee for a moment to break the cycle
				if(char.map_x == target.map_x && char.map_y == target.map_y && char.state == Character.CLIMBING && target.state == Character.CLIMBING){
					state = FLEE;
					target = schedule_target;
					count = 5 + Math.random() * delay;
				}
				
				if(!target.active){
					target = null;
					patrol_area_set = false;
					state = PATROL;
				}
			} else if(state == FLEE){
				
				flee(target);
				if(count-- <= 0){
					if(char.in_the_dark){
						// we want fleeing characters in the dark to go back to patrolling
						// but not if they're on a fucking ladder
						if(char.state == Character.CLIMBING){
							count = 1 + delay * Math.random();
						} else {
							target = null;
							patrol_area_set = false;
							state = PATROL;
						}
					} else {
						state = ATTACK;
						count = 0;
					}
				}
				if(char.left_collider && (char.left_collider is Character) && char.enemy((char.left_collider as Character))){
					target = (char.left_collider as Character);
					state = ATTACK;
					count = 0;
				}
				if(char.right_collider && (char.right_collider is Character) && char.enemy((char.right_collider as Character))){
					target = (char.right_collider as Character);
					state = ATTACK;
					count = 0;
				}
			}
		}
		
		/* This walks a character left and right in their patrol area
		 * The patrol area must be defined with setPatrolArea before using this method
		 */
		public function patrol():void {
			char.dir = 0;
			
			if(char.actions == 0) char.actions = char.looking & (LEFT | RIGHT);
			
			if(char.state == Character.WALKING){
				if(char.actions & RIGHT) {
					if(char.x >= patrol_max_x || (char.collisions & RIGHT)) char.actions = LEFT;
				} else if(char.actions & LEFT) {
					if(char.x <= patrol_min_x || (char.collisions & LEFT)) char.actions = RIGHT;
				}
				char.looking = char.actions & (LEFT | RIGHT);
				char.dir |= char.actions & (LEFT | RIGHT);
			}
		}
		
		/* Chase the player, Pepé Le Pew algorithm */
		public function chase(target:Character):void {
			char.actions = 0;
			
			if(target.x < char.x) char.actions |= LEFT;
			else if(target.x > char.x) char.actions |= RIGHT;
			
			if(target.map_y > char.map_y) char.actions |= DOWN;
			// you can't walk sideways and climb a ladder at the same time
			else if(target.rect.y + target.rect.height < char.rect.y + char.rect.height && char.canClimb() && !(char.parent_block && (char.parent_block.type & Block.LEDGE) && !(char.block_map_type & Block.LADDER))){
				char.actions = UP;
			}
			
			char.looking = char.actions & (LEFT | RIGHT);
			char.dir = char.actions & (LEFT | RIGHT | UP | DOWN);
		}
		
		/* Run away from a target */
		public function flee(target:Character):void {
			// if the character hits a wall, we make them run the other way for a period of time
			if(dont_run_into_the_wall_count){
				dont_run_into_the_wall_count--;
				if(char.collisions & RIGHT) {
					char.actions = LEFT;
				} else if(char.collisions & LEFT) {
					char.actions = RIGHT;
				}
			} else if(dont_run_into_the_wall_count <= 0){
				// if the target is overhead, that may mean certain death - limit movement to left or right
				if(
					char.y > target.rect.y + target.rect.height &&
					char.map_x == target.map_x
				){
					dont_run_into_the_wall_count = delay + Math.random();
					if(target.x > char.x) char.actions = RIGHT;
					else char.actions = LEFT;
				} else if(char.canClimb() && !(char.parent_block && (char.parent_block.type & Block.LEDGE) && !(char.block_map_type & Block.LADDER))){
					char.actions = UP;
				} else if(char.collisions & RIGHT) {
					char.actions = LEFT;
					dont_run_into_the_wall_count = delay + Math.random();
				} else if(char.collisions & LEFT) {
					char.actions = RIGHT;
					dont_run_into_the_wall_count = delay + Math.random();
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
			var dist_sq:Number = vx * vx + vy * vy;
			if(dist_sq > FOLLOW_CHASE_EDGE_SQ){
				chase(target);
			} else if(dist_sq < FOLLOW_FLEE_EDGE_SQ){
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
			if(char.left_collider && char.left_collider is Character && char.enemy(char.left_collider as Character)){
				char.dir = char.looking = char.actions = LEFT;
			} else if(char.right_collider && char.right_collider is Character && char.enemy(char.right_collider as Character)){
				char.dir = char.looking = char.actions = RIGHT;
			} else {
				if(char.state == Character.CLIMBING){
					flee(target);
				} else if(char.map_y >= target.map_y){
					var vx:Number = target.x - char.x;
					var vy:Number = target.y - char.y;
					var dist_sq:Number = vx * vx + vy * vy;
					if(dist_sq < SNIPE_FLEE_EDGE_SQ){
						flee(target);
					} else if(dist_sq > SNIPE_CHASE_EDGE_SQ){
						chase(target);
					} else {
						// face towards the target and shoot when ready
						char.dir = 0;
						if((char.looking & RIGHT) && target.x < char.x){
							char.looking = LEFT;
						} else if((char.looking & LEFT) && target.x > char.x){
							char.looking = RIGHT;
						} else {
							shootWhenReady(target, g.block_map, 10, ignore);
						}
					}
				} else {
					patrol_area_set = false;
					state = PATROL;
				}
				
			}
		}
		
		/* Scan the floor about the character to establish an area to tread
		 * This saves us from having to check the floor every frame
		 */
		public function setPatrolArea(map:Vector.<Vector.<int>>):void{
			// setting your patrol area in mid air is a tad silly
			if(!(map[char.map_y + 1][char.map_x] & UP)){
				patrol_area_set = false;
				return;
			}
			patrol_max_x = patrol_min_x = (char.map_x + 0.5) * Game.SCALE;
			while(
				patrol_min_x > Game.SCALE * 0.5 &&
				!(map[char.map_y][((patrol_min_x - Game.SCALE) * Game.INV_SCALE) >> 0] & Block.WALL) &&
				(map[char.map_y + 1][((patrol_min_x - Game.SCALE) * Game.INV_SCALE) >> 0] & UP)
			){
				patrol_min_x -= Game.SCALE;
			}
			while(
				patrol_max_x < (map[0].length - 0.5) * Game.SCALE &&
				!(map[char.map_y][((patrol_max_x + Game.SCALE) * Game.INV_SCALE) >> 0] & Block.WALL) &&
				(map[char.map_y + 1][((patrol_max_x + Game.SCALE) * Game.INV_SCALE) >> 0] & UP)
			){
				patrol_max_x += Game.SCALE;
			}
			patrol_area_set = true;
		}
		/* This shoots at the target Character when it has a line of sight to it */
		public function shootWhenReady(target:Character, map:Vector.<Vector.<int>>, length:int, ignore:int = 0):void {
			if(char.attack_count >= 1 && horizLOS(target, map, length, ignore)) {
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
				if(dy < -0.5 || dy > 0.5 || (char.weapon && char.weapon.name == Item.BOW && target.map_y > char.map_y)) return false;
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
			if(target.map_y != char.map_y || !(char.looking & LEFT | RIGHT)) return false;
			var r:Number;
			var test:Cast = null;
			var rect:Rect = char.rect;
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