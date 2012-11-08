package com.robotacid.sound {
	/**
	 * To reduce the number of calls to the SoundManager, this object builds a queue of all the sound
	 * events to take place in a given frame - adjusting the volume of repeat calls to a sound instead
	 * of issuing multiple calls.
	 *
	 * It will not handle loops or music - these should be handled directly with the SoundManager
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class SoundQueue{
		
		public var sounds:Object;
		public var groups:Object;
		public var delays:Object;
		
		// The volume needs to be cut off before it starts to distort
		public static const MAX_VOLUME:Number = 1.5;
		
		public function SoundQueue(){
			sounds = {};
			groups = {};
			delays = {};
		}
		
		/* Add a sound to the queue, an optional delay will play the sound after a given number of frames */
		public function add(name:String, volume:Number = 1.0, delay:int = 0):void{
			if(delay){
				delays[name] = delay;
			} else {
				if(sounds[name]){
					if(sounds[name] < MAX_VOLUME) sounds[name] += volume;
				} else
					sounds[name] = volume;
			}
		}
		
		/* Provides a means to play a from selection random sounds, but lock to one sound per frame and boost it's volume for multiple calls */
		public function addRandom(key:String, choices:Array, volume:Number = 1.0):void{
			if(!groups[key]){
				groups[key] = choices[(Math.random() * choices.length) >> 0];
			}
			add(groups[key], volume);
		}
		
		/* Play a random sound immediately instead of waiting for the update */
		public function playRandom(choices:Array, volume:Number = 1.0):void{
			var key:String = choices[(Math.random() * choices.length) >> 0];
			SoundManager.playSound(key);
		}
		
		/* Play all buffered sounds calls, then clear the buffer */
		public function play():void{
			
			var key:String;
			for(key in sounds){
				SoundManager.playSound(key, sounds[key]);
			}
			
			sounds = {};
			groups = {};
			
			for(key in delays){
				if(delays[key]) delays[key]--;
				else {
					add(key);
					delete delays[key];
				}
			}
		}
		
		/* Flushes the entire queue */
		public function clear():void{
			sounds = {};
			groups = {};
			delays = {};
		}
		
	}

}