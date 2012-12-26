package com.robotacid.ai {
	import com.robotacid.engine.Character;
	import com.robotacid.phys.Collider;
	
	/**
	 * Mind state object for Horror characters
	 * 
	 * Horrors simply track down their victim. They are unstoppable and do not need emotional states.
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class HorrorBrain extends Brain {
		
		public static var horrorVoiceCount:int;
		public static const HORROR_VOICE_DELAY:int = 70;
		
		public function HorrorBrain(char:Character, target:Character) {
			super(char, NONE, null);
			searchSteps = MONSTER_SEARCH_STEPS;
			this.target = target;
			target.brain.flee(char);
			wallWalker = true;
		}
		
		override public function main():void {
			charPos.x = char.collider.x + char.collider.width * 0.5;
			charPos.y = char.collider.y + char.collider.height * 0.5;
			
			crossedTileCenter = (
				(prevCenter < char.tileCenter && charPos.x > char.tileCenter) ||
				(prevCenter > char.tileCenter && charPos.x < char.tileCenter)
			);
			
			chase(target, true);
			
			if(target != game.player && !target.brain.target) target.brain.flee(char);
			prevCenter = charPos.x;
			
			if(horrorVoiceCount <= 0){
				game.createDistSound(char.mapX, char.mapY, "horror", char.voice);
				horrorVoiceCount = HORROR_VOICE_DELAY;
			}
		}
		
		/* Standard Brain clearing nulls the target - causing a crash */
		override public function clear():void {
			altNode = null;
			// drop from ladder
			if(char.collider.state == Collider.HOVER){
				char.collider.state = Collider.FALL;
				char.collider.divorce();
			}
		}
		
	}

}