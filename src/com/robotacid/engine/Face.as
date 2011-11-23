package com.robotacid.engine {
	import com.robotacid.engine.Character;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	/**
	 * A special armour item that changes the race of its wearer
	 * 
	 * The nature of a race change involves stripping equipment and then re-equipping it.
	 * This of course will cause a recursive loop if not hacked around. Hence this class.
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Face extends Item {
		
		public var previousName:int;
		private var equipping:Boolean;
		
		public function Face(mc:DisplayObject, level:int) {
			super(mc, FACE, ARMOUR, level);
			previousName = -1;
			equipping = false;
		}
		
		/* Changes the race of the character - the equipping flag is used to prevent recursion */
		override public function addBuff(character:Character):void {
			if(!equipping){
				previousName = character.name;
				equipping = true;
				if(level != character.name) character.changeName(level, g.library.getCharacterGfx(level));
				equipping = false;
			}
		}
		
		/* Restores the race of the character - the equipping flag is used to prevent recursion */
		override public function removeBuff(character:Character):void {
			if(!equipping){
				if(previousName != level) character.changeName(previousName, g.library.getCharacterGfx(previousName));
				previousName = -1;
			}
		}
		
		/* We need to fetch a head graphic */
		override public function setDroppedRender():void {
			gfx = g.library.getCharacterHeadGfx(level);
			gfx.filters = [DROP_GLOW_FILTER];
		}
		
		override public function collect(character:Character, print:Boolean = true):void {
			super.collect(character, print);
			gfx = new Sprite();
		}
		
		override public function nameToString():String {
			return Character.stats["names"][level] + " face";
		}
		
	}

}