package com.robotacid.ai {
	import com.robotacid.engine.Character;
	
	/**
	 * Runs away from the player and minion towards the next floor of the dungeon
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class BalrogBrain extends Brain {
		
		// behavioural states
		//public static const PATROL:int = 0;
		//public static const PAUSE:int = 1;
		//public static const ATTACK:int = 2;
		//public static const FLEE:int = 3;
		public static const ESCAPE:int = 4;
		
		public function BalrogBrain(char:Character) {
			super(char, MONSTER, null);
			state = ESCAPE;
		}
		
		override public function main():void {
			
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
				if(playerCharacters.length){
					sheduleIndex = (sheduleIndex + 1) % playerCharacters.length;
					scheduleTarget = playerCharacters[sheduleIndex];
				} else {
					scheduleTarget = null;
				}
				
				if(scheduleTarget){
					scheduleTargetPos.x = scheduleTarget.collider.x + scheduleTarget.collider.width * 0.5;
					scheduleTargetPos.y = scheduleTarget.collider.y + scheduleTarget.collider.height * 0.5;
				}
			}
			
			// the balrog will run ahead, then wait for the player or minion - taunting them
			if(state == ESCAPE || state == PAUSE){
				if(state == ESCAPE){
					
					
					if(patrolAreaSet){
						patrol();
					} else {
						setPatrolArea(game.world.map);
					}
					
					if(count-- <= 0){
						count = delay + game.random.range(delay);
						state = PAUSE;
						char.actions = char.dir = 0;
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
						// check for changes in patrol area at random
						if(patrolAreaSet && game.random.coinFlip()) patrolAreaSet = false;
					}
				}
				
				// indifferent characters do not look for a fight
				if(char.indifferent) return;
				
				// here's where we look for targets
				// any enemy touching us counts as a target, but we also look for targets
				// rather than checking all enemy characters, we check one at a time each frame
				if(scheduleTarget){
					if(charContact && char.enemy(charContact)){
						attack(charContact);
					
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
					char.collider.y >= target.collider.y + target.collider.height &&
					!(
						char.collider.x >= target.collider.x + target.collider.width ||
						char.collider.x + char.collider.width <= target.collider.x
					)
				){
					if(target.type == Character.GATE) clear();
					else flee(target);
					
				} else {
					if(char.throwable || (char.weapon && (char.weapon.range & Item.MISSILE))){
						snipe(target);
					} else {
						chase(target);
						// commute allies to the target
						if(charContact && target.active && !char.enemy(charContact) && charContact.brain) charContact.brain.copyState(this);
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
		
	}

}