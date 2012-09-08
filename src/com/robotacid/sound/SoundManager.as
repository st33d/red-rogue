package com.robotacid.sound {
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	import flash.media.SoundChannel;
	import flash.utils.getTimer;
	/**
	 * A static class that plays sounds and music.
	 *
	 * Will only play one music track at a time.
	 * Will not play multiple sound loops of the same type either.
	 * Negative fades will simply fade the music out to silence, not a target volume.
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class SoundManager{
		
		public static var music:Boolean = true;
		public static var sfx:Boolean = true;
		
		public static var loopsPaused:Boolean = false;
		
		public static var sounds:Object/*Sound*/ = {};
		public static var soundChannels:Object/*SoundChannel*/= {};
		public static var volumes:Object/*Number*/ = {};
		
		public static var soundLoops:Object/*SoundLoop*/= {};
		public static var musicTimes:Object/*int*/= {};
		
		public static var expendableChannels:Array/*SoundChannel*/ = [];
		public static var expendableSounds:Array/*Sound*/= [];
		
		public static var currentMusic:String;
		
		private static var musicTime:int;
		private static var fading:Boolean = false;
		
		/* The size the killList needs to be before being checked for garbage collection */
		private static const MAX_EXPENDABLES:int = 64;
		
		public static const DEFAULT_FADE_STEP:Number = 0.1;
		
		public function SoundManager(){
			
		}
		
		/* Reads values for music and sfx toggles from the SharedObject */
		public static function init():void{
			sfx = UserData.settings.sfx;
			music = UserData.settings.music;
			gameSoundsInit();
		}
		
		/* Adds a sound to the sounds hash. Use this method to add all sounds to a project */
		public static function addSound(sound:Sound, name:String, volume:Number = 1.0):void{
			sounds[name] = sound;
			volumes[name] = volume;
		}
		
		/* Plays a sound once */
		public static function playSound(name:String, volume:Number = 1, highPriority:Boolean = false):void{
			if(!sfx || !sounds[name]) return;
			
			var sound:Sound = sounds[name];
			var soundTransform:SoundTransform = new SoundTransform(volumes[name] * volume);
			
			soundChannels[name] = sound.play(0, 0, soundTransform);
			
			if(highPriority){
				// if too many SoundChannels are in use, sound.play() will silently fail
				// to resolve this we force a low priority SoundChannel to sacrifice itself
				if(!soundChannels[name]){
					reserveChannel();
					soundChannels[name] = sound.play(0, int.MAX_VALUE, soundTransform);
				}
			} else {
				if(soundChannels[name]){
					expendableChannels.push(soundChannels[name]);
					expendableSounds.push(sounds[name]);
				}
				if(expendableChannels.length >= MAX_EXPENDABLES){
					garbageCollectExpendableChannels();
				}
			}
		}
		
		/* Plays an infinitely looping sound */
		public static function loopSound(name:String, volume:Number = 1):void{
			if(!sounds[name] || soundLoops[name]) return;
			
			var soundTransform:SoundTransform = new SoundTransform(volumes[name] * volume);
			
			if(sfx && !loopsPaused){
				var sound:Sound = sounds[name];
				soundChannels[name] = sound.play(0, int.MAX_VALUE, soundTransform);
				
				// if too many SoundChannels are in use, sound.play() will silently fail
				// to resolve this we force a low priority SoundChannel to sacrifice itself
				if(!soundChannels[name]){
					reserveChannel();
					soundChannels[name] = sound.play(0, int.MAX_VALUE, soundTransform);
				}
			}
			soundLoops[name] = new SoundLoop(name, sounds[name], soundTransform, soundChannels[name]);
		}
		
		/* Halts all looping sounds. The loops hash is left unmarred so the loops can be reinitiated with
		 * startLoops()
		 *
		 * the "toggle" parameter refers to pausing loops by setting the sfx parameter */
		public static function pauseLoops(toggle:Boolean = false):void{
			
			if(loopsPaused) return;
			
			for(var key:String in soundLoops){
				if(key == currentMusic) continue;
				if(soundLoops[key].soundChannel){
					soundLoops[key].soundChannel.stop();
				}
				delete soundChannels[key];
				if(soundLoops[key].fadeStep){
					if(soundLoops[key].fadeStep > 0){
						soundLoops[key].fadeStep = 0;
					} else {
						delete soundLoops[key];
					}
				}
			}
			if(!toggle) loopsPaused = true;
		}
		
		/* Restarts any loops that were paused by pauseLoops
		 *
		 * the "toggle" parameter refers to unpausing loops by setting the sfx parameter */
		public static function startLoops(toggle:Boolean = false):void{
			
			if(sfx && (toggle != loopsPaused)){
				for(var key:String in soundLoops){
					if(key == currentMusic) continue;
					
					var soundTransform:SoundTransform = soundLoops[key].soundTransform;
					
					soundChannels[key] = sounds[key].play(0, int.MAX_VALUE, soundTransform);
					
					// if too many SoundChannels are in use, sound.play() will silently fail
					// to resolve this we force a low priority SoundChannel to sacrifice itself
					if(!soundChannels[key]){
						reserveChannel();
						soundChannels[key] = sounds[key].play(0, int.MAX_VALUE, soundTransform);
					}
					soundLoops[key].soundChannel = soundChannels[key];
				}
			}
			if(!toggle) loopsPaused = false;
		}
		
		/* Stops a sound, deleting any loop or fading operation */
		public static function stopSound(name:String):void {
			if(soundChannels[name]){
				soundChannels[name].stop();
				delete soundChannels[name];
			}
			if(soundLoops[name]) delete soundLoops[name];
		}
		
		/* Stops all sounds (except the currentMusic) */
		public static function stopAllSounds():void{
			var key:String;
			for(key in soundChannels){
				if(key != currentMusic){
					stopSound(key);
				}
			}
			for(key in soundLoops){
				if(key != currentMusic){
					stopSound(key);
				}
			}
			garbageCollectChannels();
		}
		
		/* Stops all loops (except the currentMusic) */
		public static function stopAllLoops():void{
			var key:String;
			for(key in soundLoops){
				if(key != currentMusic){
					stopSound(key);
				}
			}
		}
		
		/* Plays a sound loop and assigns it as currentMusic. Any new calls to playMusic
		 * will stop playing the currentMusic and assign the new sound as currentMusic */
		public static function playMusic(name:String, start:int = 0, playOnce:Boolean = false):void{
			if(!sounds[name] || soundChannels[name]) return;
			
			var soundTransform:SoundTransform = new SoundTransform(volumes[name]);
			
			if(music){
				if(soundChannels[currentMusic]){
					musicTimes[currentMusic] = getTime();
					soundChannels[currentMusic].stop();
					delete soundChannels[currentMusic];
				}
				
				var sound:Sound = sounds[name];
				
				if(start >= sound.length) start %= sound.length;
				
				soundChannels[name] = sound.play(start, (start || playOnce) ? 1 : int.MAX_VALUE, soundTransform);
				
				// if too many SoundChannels are in use, sound.play() will silently fail
				// to resolve this we force a low priority SoundChannel to sacrifice itself
				if(!soundChannels[name]){
					reserveChannel();
					soundChannels[name] = sound.play(start, (start || playOnce) ? 1 : int.MAX_VALUE, soundTransform);
				}
				setTime(start);
				// music that is started ahead of its start point needs an SOUND_COMPLETE to hack it into looping
				if(start != 0) soundChannels[name].addEventListener(Event.SOUND_COMPLETE, loopMusic, false, 0, true);
			}
			
			if(soundLoops[currentMusic]) delete soundLoops[currentMusic];
			soundLoops[name] = new SoundLoop(name, sounds[name], soundTransform, soundChannels[name]);
			currentMusic = name;
		}
		
		/* Hack for looping music that was played with a non zero start position */
		private static function loopMusic(e:Event):void{
			e.target.removeEventListener(Event.SOUND_COMPLETE, loopMusic);
			if(music){
				var soundTransform:SoundTransform = new SoundTransform(volumes[currentMusic]);
				
				soundChannels[currentMusic] = sounds[currentMusic].play(0, int.MAX_VALUE, soundTransform);
				
				// if too many SoundChannels are in use, sound.play() will silently fail
				// to resolve this we force a low priority SoundChannel to sacrifice itself
				if(!soundChannels[currentMusic]){
					reserveChannel();
					soundChannels[currentMusic] = sounds[currentMusic].play(0, int.MAX_VALUE, soundTransform);
				}
				soundLoops[currentMusic].soundChannel = soundChannels[currentMusic];
				setTime(0);
			}
		}
		
		/* Stops any currently playing music, retains the currentMusic choice to allow it to be recalled */
		public static function stopMusic():void{
			if(!currentMusic) return;
			if(soundChannels[currentMusic]){
				soundChannels[currentMusic].stop();
				delete soundChannels[currentMusic];
			}
			if(soundLoops[currentMusic]){
				soundLoops[currentMusic].fadeStep = 0;
			}
		}
		
		/* Switches sound effects on and off */
		public static function toggleSfx():void {
			if(sfx){
				turnOffSfx();
			} else {
				turnOnSfx();
			}
		}
		/* Switches music on and off */
		public static function toggleMusic():void {
			if(music){
				turnOffMusic();
			} else {
				turnOnMusic();
			}
		}
		/* Turn off sound effects */
		public static function turnOffSfx():void{
			sfx = false;
			pauseLoops(true);
		}
		/* Turn on sound effects */
		public static function turnOnSfx():void{
			sfx = true;
			startLoops(true);
		}
		/* Turn on music */
		public static function turnOnMusic():void {
			music = true;
			if(currentMusic) playMusic(currentMusic);
		}
		/* Turn off music */
		public static function turnOffMusic():void {
			stopMusic();
			music = false;
		}
		
		/* The position property of a SoundChannel feeds us with false data - so we have
		 * to keep our own time. When a new music type is selected, we reset musicTime.
		 */
		public static function getTime():int{
			if(!currentMusic) return 0;
			return (getTimer() - musicTime) % sounds[currentMusic].length;
		}
		public static function setTime(newTime:int):void{
			musicTime = getTimer() - newTime;
		}
		
		/* Fades music in by default, set step to a negative figure to fade.
		 * Fades out currentMusic at the same rate */
		public static function fadeMusic(name:String, step:Number = DEFAULT_FADE_STEP, start:int = 0, playOnce:Boolean = false):void{
			
			if(
				!sounds[name] ||
				(soundLoops[name] && soundLoops[name].fadeStep * step > 0) ||
				(step > 0 && currentMusic == name) ||
				(step < 0 && !soundLoops[name])
			) return;
			
			// if music is on, perform a fade - otherwise, just do a straight switch of music
			
			if(music){
				
				var fadeTarget:Number = step > 0 ? volumes[name] : 0;
				
				// force any existing fading in music to fade out
				if(currentMusic){
					soundLoops[currentMusic].fadeStep = -step;
					soundLoops[currentMusic].fadeTarget = 0;
					musicTimes[currentMusic] = getTime();
				}
				
				if(!soundLoops[name]){
					
					// we shouldn't have gotten here if step isn't positively signed (see condition above),
					// this condition here is for speed readers
					if(step > 0){
						var soundTransform:SoundTransform = new SoundTransform(0);
						var sound:Sound = sounds[name];
						if(start >= sound.length) start %= sound.length;
						
						soundChannels[name] = sound.play(start, (start || playOnce) ? 1 : int.MAX_VALUE, soundTransform);
						
						// if too many SoundChannels are in use, sound.play() will silently fail
						// to resolve this we force a low priority SoundChannel to sacrifice itself
						if(!soundChannels[name]){
							reserveChannel();
							soundChannels[name] = sound.play(start, (start || playOnce) ? 1 : int.MAX_VALUE, soundTransform);
						}
						setTime(start);
						// music that is started ahead of its start point needs an SOUND_COMPLETE to hack it into looping
						if(start) soundChannels[name].addEventListener(Event.SOUND_COMPLETE, loopMusic, false, 0, true);
						
						soundLoops[name] = new SoundLoop(name, sound, soundTransform, soundChannels[name]);
					}
				}
				
				soundLoops[name].fadeStep = step;
				soundLoops[name].fadeTarget = fadeTarget;
				
				if(step > 0) currentMusic = name;
				
				if(!fading){
					fading = true;
					Game.game.addEventListener(Event.ENTER_FRAME, fadeUpdate);
				}
			} else {
				if(step > 0){
					playMusic(name);
				} else {
					if(currentMusic && soundLoops[currentMusic]) delete soundLoops[currentMusic];
					currentMusic = null;
				}
			}
		}
		
		/* Fades a sound in by default, set step to a negative figure to fade a sound out */
		public static function fadeLoopSound(name:String, step:Number = DEFAULT_FADE_STEP, volume:Number = 1):void{
			if(
				!sounds[name] ||
				(soundLoops[name] && soundLoops[name].fadeStep * step > 0) ||
				(step < 0 && !soundLoops[name])
			) return;
			
			// sfx is on and loops aren't paused, perform a fade, otherwise just play the loop or turn it off
			
			if(sfx && !loopsPaused){
				
				var fadeTarget:Number = step > 0 ? volumes[name] : 0;
				
				if(!soundLoops[name]){
					// we shouldn't have gotten here if step isn't positively signed (see condition above),
					// this condition here is for speed readers
					if(step > 0){
						var soundTransform:SoundTransform = new SoundTransform(0);
						var sound:Sound = sounds[name];
						
						soundChannels[name] = sound.play(0, int.MAX_VALUE, soundTransform);
						
						// if too many SoundChannels are in use, sound.play() will silently fail
						// to resolve this we force a low priority SoundChannel to sacrifice itself
						if(!soundChannels[name]){
							reserveChannel();
							soundChannels[name] = sound.play(0, int.MAX_VALUE, soundTransform);
						}
						
						soundLoops[name] = new SoundLoop(name, sounds[name], soundTransform, soundChannels[name]);
					}
				}
				
				soundLoops[name].fadeStep = step;
				soundLoops[name].fadeTarget = fadeTarget;
				
				if(!fading){
					fading = true;
					Game.game.addEventListener(Event.ENTER_FRAME, fadeUpdate);
				}
			} else {
				if(step > 0){
					loopSound(name, volume)
				} else {
					stopSound(name);
				}
			}
		}
		
		/* Sound fading event - mixes all sound loops */
		private static function fadeUpdate(e:Event):void{
			var stopFade:Boolean = true;
			var soundLoop:SoundLoop;
			
			for(var key:String in soundLoops){
				
				soundLoop = soundLoops[key];
				
				if(soundLoop.fadeStep){
					stopFade = false;
					
					if(soundLoop.fadeStep > 0){
						
						soundLoop.soundTransform.volume += soundLoop.fadeStep;
						if(soundLoop.soundTransform.volume >= soundLoop.fadeTarget){
							soundLoop.soundTransform.volume = soundLoop.fadeTarget;
							soundLoop.fadeStep = 0;
						}
						soundChannels[key].soundTransform = soundLoop.soundTransform;
						
					} else if(soundLoop.fadeStep < 0){
						
						soundLoop.soundTransform.volume += soundLoop.fadeStep;
						if(soundLoop.soundTransform.volume <= soundLoop.fadeTarget){
							soundChannels[key].stop();
							delete soundChannels[key];
							if(key == currentMusic){
								musicTimes[currentMusic] = getTime();
								currentMusic = null;
							}
							soundLoop.soundTransform.volume = soundLoop.fadeTarget;
							soundLoop.fadeStep = 0;
						} else {
							soundChannels[key].soundTransform = soundLoop.soundTransform;
						}
						
						if(soundLoop.soundTransform.volume == soundLoop.fadeTarget){
							delete soundLoops[key];
						}
					}
					
				}
			}
			if(stopFade){
				e.target.removeEventListener(Event.ENTER_FRAME, fadeUpdate);
				fading = false;
			}
		}
		
		/* Find a low priority SoundChannel currently in use and stop it */
		public static function reserveChannel():void{
			for(var i:int = 0; i < expendableChannels.length; i++){
				if(expendableChannels[i].position < expendableSounds[i].length){
					expendableChannels[i].stop();
					expendableChannels.splice(i, 1);
					expendableSounds.splice(i, 1);
				}
			}
		}
		
		/* Clear any expendableChannels that have finished playing */
		public static function garbageCollectExpendableChannels():void{
			for(var i:int = expendableChannels.length - 1; i > -1; i--){
				if(expendableChannels[i].position == expendableSounds[i].length){
					expendableChannels.splice(i, 1);
					expendableSounds.splice(i, 1);
				}
			}
		}
		
		/* Null old SoundChannels that aren't in use */
		public static function garbageCollectChannels():void{
			for(var key:String in soundChannels){
				if(key != currentMusic){
					if(soundChannels[key] && soundChannels[key].position == sounds[key].length){
						delete soundChannels[key];
					}
				}
			}
		}
		
	}

}