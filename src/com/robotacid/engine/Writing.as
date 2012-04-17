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
		
		private var read:Boolean;
		
		public static var writings:Vector.<Writing>;
		public static var storyCharCodes:Array;
		
		// names
		public static const MESSAGE:int = 0;
		public static const ELBERETH:int = 1;
		public static const FEAR:int = 2;
		
		public static const CHAR_TOTAL:int = 5;
		
		[Embed(source = "story.json", mimeType = "application/octet-stream")] public static var storyData:Class;
		public static var story:Array;
		
		public function Writing(mapX:int, mapY:int, text:String, level:int, index:int) {
			this.mapX = mapX;
			this.mapY = mapY;
			this.text = text;
			this.level = level;
			this.index = index;
			if(text == "elbereth") name = ELBERETH;
			else if(text == "he comes") name = FEAR;
			rect = new Rectangle((mapX - 1) * SCALE, mapY * SCALE, SCALE * 3, SCALE);
			super(new Sprite(), false, false);
			gfx.visible = false;
			callMain = true;
			addToEntities = true;
			writings.push(this);
		}
		
		override public function main():void {
			if(game.player.actions & Collider.UP){
				if(!read && game.player.collider.intersects(rect)){
					game.console.print("\"" + text + "\"");
					read = true;
					if(name == FEAR){
						// send a horror after the player
						var effect:Effect = new Effect(Effect.FEAR, game.player.level, Effect.WEAPON, game.player);
					}
				}
			} else if(read){
				read = false;
			}
			if(name == ELBERETH){
				// make any monster targeting the player, run away
				if(game.player.collider.intersects(rect)){
					var i:int, character:Character;
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
				if(story[writing.level][writing.index].indexOf("b:") > -1){
					underBlit = renderer.redWritingUnderBlit;
					overBlit = renderer.redWritingOverBlit;
				} else {
					underBlit = renderer.blackWritingUnderBlit;
					overBlit = renderer.blackWritingOverBlit;
				}
				underBlit.chars = overBlit.chars = chars;
				underBlit.x = overBlit.x = writing.rect.x;
				underBlit.y = overBlit.y = writing.rect.y;
				underBlit.render(renderer.blockBitmapData);
				overBlit.render(renderer.blockBitmapData);
			}
		}
		
		public static function createStoryCharCodes(random:XorRandom):void{
			
			var byteArray:ByteArray = new storyData();
			story = JSON.decode(byteArray.readUTFBytes(byteArray.length));
			
			var i:int, j:int, k:int, m:int;
			var typeArray:Array, levelArray:Array, code:String;
			
			storyCharCodes = [];
			for(i = 0; i < story.length; i++){
				storyCharCodes[i] = [];
				levelArray = story[i];
				for(j = 0; j < levelArray.length; j++){
					code = "";
					for(m = 0; m < CHAR_TOTAL; m++){
						code += "" + (1 + random.rangeInt(30));
						if(m < CHAR_TOTAL - 1) code += ",";
					}
					storyCharCodes[i][j] = code;
				}
			}
			
		}
		
	}

}