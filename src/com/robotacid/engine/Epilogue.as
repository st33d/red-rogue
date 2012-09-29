package com.robotacid.engine {
	import com.adobe.serialization.json.JSON;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.ui.Key;
	import com.robotacid.ui.TextBox;
	import flash.display.Sprite;
	import flash.utils.ByteArray;
	/**
	 * Manages the end of game epilogue
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Epilogue extends Sprite{
		
		public var game:Game;
		public var renderer:Renderer;
		
		public var state:int;
		public var type:int;
		public var index:int;
		public var currentStr:String;
		public var lines:Array;
		public var textBox:TextBox;
		
		// types
		public static const YENDOR:int = 0;
		public static const HUSBAND:int = 1;
		
		// states
		public static const IDLE:int = 0;
		public static const FADE_OUT:int = 1;
		public static const FADE_IN:int = 2;
		
		[Embed(source = "epilogue.json", mimeType = "application/octet-stream")] public static var epilogueData:Class;
		public static var epilogue:Array;
		
		public function Epilogue(type:int, game:Game, renderer:Renderer) {
			this.type = type;
			this.game = game;
			this.renderer = renderer;
			lines = epilogue[type];
			advance();
			textBox = new TextBox(Game.WIDTH, Game.HEIGHT, 0x0, 0x0);
			textBox.align = "center";
			textBox.alignVert = "center";
			addChild(textBox);
			graphics.beginFill(0);
			graphics.drawRect(0, 0, Game.WIDTH, Game.HEIGHT);
			alpha = 0;
			textBox.text = currentStr;
		}
		
		public function main():void{
			if(alpha < 1){
				alpha += 0.01;
			}
			if(state == IDLE){
				if(Key.customDown(Game.MENU_KEY)){
					if(index < lines.length){
						advance();
						state = FADE_OUT;
					}
				}
			} else if(state == FADE_OUT){
				if(textBox.alpha > 0){
					textBox.alpha -= 0.1;
				} else {
					textBox.alpha = 0;
					textBox.text = currentStr;
					state = FADE_IN;
				}
			} else if(state == FADE_IN){
				if(textBox.alpha < 1){
					textBox.alpha += 0.1;
				} else {
					textBox.alpha = 1;
					textBox.text = currentStr;
					state = IDLE;
				}
			}
		}
		
		/* Moves on to the next piece of text */
		public function advance():void{
			trace(lines);
			var strs:Array = lines[index];
			trace(strs);
			currentStr = strs[game.random.rangeInt(strs.length)];
			trace(currentStr);
		}
		
		public static function initEpilogue():void{
			var byteArray:ByteArray = new epilogueData();
			epilogue = JSON.decode(byteArray.readUTFBytes(byteArray.length));
		}
		
	}

}