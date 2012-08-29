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
		public var theBalrog:Boolean;
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
				if(level != character.name) character.changeName(level, game.library.getCharacterGfx(level));
				equipping = false;
			}
		}
		
		/* Restores the race of the character - the equipping flag is used to prevent recursion */
		override public function removeBuff(character:Character):void {
			if(!equipping){
				if(previousName != level) character.changeName(previousName, game.library.getCharacterGfx(previousName));
				previousName = -1;
			}
		}
		
		/* We need to fetch a head graphic */
		override public function setDroppedRender():void {
			gfx = game.library.getCharacterHeadGfx(level);
			gfx.filters = [DROP_GLOW_FILTER];
		}
		
		override public function collect(character:Character, print:Boolean = true, caught:Boolean = false):void {
			super.collect(character, print, false);
			gfx = new Sprite();
		}
		
		override public function nameToString():String {
			var str:String = "";
			if(user && user == game.player) str += "w: ";
			else if(user && user == game.minion) str += "m: ";
			if(uniqueNameStr) return uniqueNameStr;
			return str + Character.stats["names"][level] + " face";
		}
		
		override public function getHelpText():String {
			var str:String = "this armour is" + (uniqueNameStr ? " " + uniqueNameStr : "") + " a";
			var name:String = Character.stats["names"][level] + " face";
			
			if(holyState == CURSE_REVEALED) name = "cursed " + name;
			else if(holyState == BLESSED) name = "blessed " + name;
			else if(effects) name = "enchanted " + name;
			
			str += (name.charAt(0).search(/[aeiou]/i) == 0) ? "n " : " ";
			str += name;
			return str;
		}
		
	}

}