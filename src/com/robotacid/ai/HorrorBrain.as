package com.robotacid.ai {
	import com.robotacid.engine.Character;
	
	/**
	 * Mind state object for Horror characters
	 * 
	 * Horrors simply track down their victim. They are unstoppable and do not need emotional states.
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class HorrorBrain extends Brain {
		
		public static var horrorVoiceCount:int;
		public static const VOICE:Array = ["horror1", "horror2", "horror3", "horror4"];
		public static const HORROR_VOICE_DELAY:int = 120;
		
		public function HorrorBrain(char:Character, target:Character) {
			super(char, NONE, null);
			searchSteps = MONSTER_SEARCH_STEPS;
			this.target = target;
			target.brain.runAway(char);
			
		}
		
		override public function main():void {
			charPos.x = char.collider.x + char.collider.width * 0.5;
			charPos.y = char.collider.y + char.collider.height * 0.5;
			
			crossedTileCenter = (
				(prevCenter < char.tileCenter && charPos.x > char.tileCenter) ||
				(prevCenter > char.tileCenter && charPos.x < char.tileCenter)
			);
			
			chase(target, true);
			
			if(target != game.player && !target.brain.target) target.brain.runAway(char);
			prevCenter = charPos.x;
			
			if(horrorVoiceCount <= 0){
				voiceDist = Math.abs(game.player.mapX - char.mapX) + Math.abs(game.player.mapY - char.mapY);
				if(voiceDist < VOICE_DIST_MAX) speak(VOICE, voiceDist);
			}
		}
		
		
		/* Triggers a sample representing horrors */
		override public function speak(voice:Array, dist:int):void{
			game.soundQueue.addRandom("horror", voice, (VOICE_DIST_MAX - dist) * INV_VOICE_DIST_MAX);
			horrorVoiceCount = HORROR_VOICE_DELAY;
		}
		
	}

}