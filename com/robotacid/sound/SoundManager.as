package com.robotacid.sound {
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	/**
	 * ...
	 * @author steed
	 */
	public class SoundManager {
		
		public static var sfx:Boolean = true;
		
		static public function playSound(sound:Class, volume:Number = 1):void{
			if(!sfx) return;
			(new sound).play(0,0,new SoundTransform(volume));
		}
		
	}
	
}