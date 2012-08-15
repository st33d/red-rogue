package com.robotacid.engine {
	import com.adobe.serialization.json.JSON;
	import com.robotacid.ai.Brain;
	import com.robotacid.gfx.WritingBlit;
	import com.robotacid.phys.Collider;
	import com.robotacid.util.XorRandom;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	/**
	 * Messages left by the Balrog and Minion on the walls of the dungeons.
	 * 
	 * Some messages have special powers
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Writing extends Entity {
		
		public var text:String;
		public var level:int;
		public var index:int;
		public var rect:Rectangle;
		public var firstReading:Boolean;
		
		private var read:Boolean;
		
		public static var writings:Vector.<Writing>;
		public static var storyCharCodes:Array;
		
		// names
		public static const MESSAGE:int = 0;
		public static const ELBERETH:int = 1;
		
		public static const CHAR_TOTAL:int = 7;
		
		[Embed(source = "story.json", mimeType = "application/octet-stream")] public static var storyData:Class;
		public static var story:Array;
		
		public function Writing(mapX:int, mapY:int, text:String, level:int, index:int) {
			this.mapX = mapX;
			this.mapY = mapY;
			this.text = text;
			this.level = level;
			this.index = index;
			if(text == "elbereth") name = ELBERETH;
			rect = new Rectangle((mapX - 1) * SCALE, mapY * SCALE, SCALE * 3, SCALE);
			super(new Sprite(), false, false);
			gfx.visible = false;
			callMain = true;
			addToEntities = true;
			firstReading = false;
			writings.push(this);
		}
		
		override public function main():void {
			var i:int, character:Character;
			if(game.player.actions & Collider.UP){
				if(
					!read &&
					game.player.collider.x + game.player.collider.width > rect.x &&
					rect.x + rect.width > game.player.collider.x &&
					game.player.collider.y + game.player.collider.height > rect.y &&
					rect.y + rect.height > game.player.collider.y
				){
					game.console.print("\"" + text + "\"");
					read = true;
					if(!firstReading){
						firstReading = true;
						if(name == ELBERETH){
							// summon a horror to attack any monster in range
							if(Brain.monsterCharacters.length){
								character = Brain.monsterCharacters[game.random.rangeInt(Brain.monsterCharacters.length)];
								var effect:Effect = new Effect(Effect.FEAR, game.player.level, Effect.EATEN, character);
							}
						}
					}
				}
			} else if(read){
				read = false;
			}
			if(name == ELBERETH){
				// make any monster targeting the player, run away
				if(
					game.player.collider.x + game.player.collider.width > rect.x &&
					rect.x + rect.width > game.player.collider.x &&
					game.player.collider.y + game.player.collider.height > rect.y &&
					rect.y + rect.height > game.player.collider.y
				){
					for(i = 0; i < Brain.monsterCharacters.length; i++){
						character = Brain.monsterCharacters[i];
						if(character.brain && character.brain.target && character.brain.state == Brain.ATTACK){
							character.brain.flee(character.brain.target);
						}
					}
				}
			}
			//Game.debug.drawRect(rect.x, rect.y, rect.width, rect.height);
		}
		
		/* Pre-render the writing graphics to the block layer */
		public static function renderWritings():void{
			var i:int;
			var writing:Writing, chars:Array;
			var underBlit:WritingBlit, overBlit:WritingBlit;
			
			for(i = 0; i < writings.length; i++){
				writing = writings[i];
				chars = storyCharCodes[writing.level][writing.index].split(",");
				underBlit = renderer.redWritingUnderBlit;
				overBlit = renderer.redWritingOverBlit;
				underBlit.chars = overBlit.chars = chars;
				underBlit.x = overBlit.x = writing.rect.x + 1;
				underBlit.y = overBlit.y = writing.rect.y;
				underBlit.render(renderer.backBitmapData);
				overBlit.render(renderer.backBitmapData);
			}
		}
		
		public static function createStoryCharCodes(random:XorRandom):void{
			
			var byteArray:ByteArray = new storyData();
			story = JSON.decode(byteArray.readUTFBytes(byteArray.length));
			
			var i:int, j:int, k:int, m:int;
			var typeArray:Array, levelArray:Array;
			
			elberethCode = getCode(random);
			storyCharCodes = [];
			
			for(i = 0; i < story.length; i++){
				storyCharCodes[i] = [];
				levelArray = story[i];
				for(j = 0; j < levelArray.length; j++){
					storyCharCodes[i][j] = getCode(random, levelArray[j]);
				}
			}
		}
		
		/* Create a random sequence of shapes - a set code for "elbereth" is predetermined */
		public static function getCode(random:XorRandom, str:String = ""):String{
			if(str == "elbereth") return elberethCode;
			var i:int;
			var code:String = code = "";
			for(i = 0; i < CHAR_TOTAL; i++){
				code += CHAR_SHAPES[random.rangeInt(CHAR_SHAPES.length)] + "";
				if(i < CHAR_TOTAL - 1) code += ",";
			}
			return code;
		}
		
		public static var elberethCode:String = "";
		
		/* Always want at least two lines, otherwise the writing looks a bit shit */
		public static const CHAR_SHAPES:Array = [
			WritingBlit.TOP_LEFT | WritingBlit.TOP_RIGHT | WritingBlit.BOTTOM_LEFT | WritingBlit.BOTTOM_RIGHT,
			WritingBlit.TOP_LEFT | WritingBlit.TOP_RIGHT | WritingBlit.BOTTOM_LEFT,
			WritingBlit.TOP_LEFT | WritingBlit.BOTTOM_LEFT | WritingBlit.BOTTOM_RIGHT,
			WritingBlit.TOP_RIGHT | WritingBlit.BOTTOM_LEFT | WritingBlit.BOTTOM_RIGHT,
			WritingBlit.TOP_LEFT | WritingBlit.TOP_RIGHT | WritingBlit.BOTTOM_RIGHT,
			WritingBlit.TOP_LEFT | WritingBlit.TOP_RIGHT,
			WritingBlit.BOTTOM_LEFT | WritingBlit.BOTTOM_RIGHT,
			WritingBlit.TOP_LEFT | WritingBlit.BOTTOM_RIGHT,
			WritingBlit.BOTTOM_LEFT | WritingBlit.TOP_RIGHT,
			WritingBlit.BOTTOM_LEFT | WritingBlit.TOP_LEFT,
			WritingBlit.BOTTOM_RIGHT | WritingBlit.TOP_RIGHT
		]
		
	}

}