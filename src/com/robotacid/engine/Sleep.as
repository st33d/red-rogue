package com.robotacid.engine {
	import com.adobe.serialization.json.JSON;
	import com.robotacid.ai.BalrogBrain;
	import com.robotacid.ai.Brain;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.level.Map;
	import com.robotacid.ui.Console;
	import com.robotacid.ui.TextBox;
	import com.robotacid.util.array.randomiseArray;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	/**
	 * Manages Player sleep sessions
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Sleep extends Sprite{
		
		public var game:Game;
		public var renderer:Renderer;
		
		public var active:Boolean;
		public var textBox:TextBox;
		public var animState:int;
		
		private var dreamList:Array;
		private var dreamCount:int;
		private var fadeLight:FadeLight;
		private var aggroCount:int;
		private var aggroBegins:Boolean;
		private var animCount:int;
		private var charRects:Vector.<Rectangle>;
		private var charCols:Vector.<ColorTransform>;
		private var charOffsets:Vector.<Point>;
		private var charSpeeds:Vector.<Number>;
		private var charDelays:Vector.<int>;
		private var nightmare:Boolean;
		
		public static const HEIGHT:Number = Game.HEIGHT - Console.HEIGHT;
		public static const HEAL_RATE:Number = 1.0 / 240;
		public static const AGGRO_DELAY:int = 60;
		public static const ANIM_DELAY:int = 30;
		public static const CHAR_COL_STEP:Number = 1.0 / ANIM_DELAY;
		public static const DREAM_DELAY:int = 120;
		public static const MENU_SLEEP:int = 0;
		public static const MENU_WAKE_UP:int = 1;
		public static const NIGHTMARE_COL:ColorTransform = new ColorTransform(1, 0, 0);
		public static const NIGHTMARE_RANGE:int = 3;
		
		// anim states
		public static const ROLL_IN_TEXT:int = 0;
		public static const HOLD_TEXT:int = 1;
		public static const ROLL_OUT_TEXT:int = 2;
		
		[Embed(source = "dreams.json", mimeType = "application/octet-stream")] public static var dreamsData:Class;
		[Embed(source = "nightmares.json", mimeType = "application/octet-stream")] public static var nightmaresData:Class;
		public static var dreams:Array;
		public static var nightmares:Array;
		
		public function Sleep(game:Game, renderer:Renderer) {
			this.game = game;
			this.renderer = renderer;
			textBox = new TextBox(Game.WIDTH, 11 * 5, 0x0, 0x0);
			textBox.y = (HEIGHT * 0.5 - textBox.height * 0.5) >> 0;
			textBox.align = "center";
			textBox.alignVert = "center";
			addChild(textBox);
			graphics.beginFill(0);
			graphics.drawRect(0, 0, Game.WIDTH, Game.HEIGHT);
			visible = false;
		}
		
		public function main():void{
			
			// get the minion to a position where it can sleep
			if(game.minion && !game.minion.asleep){
				// teleport to player
				game.minion.teleportToPlayer();
				game.minion.setAsleep(true);
			}
			// check the fadeLight to see sleep has begun
			if(!fadeLight.active){
				if(!visible){
					initDream();
				}
				// heal the player
				if(game.player.health < game.player.totalHealth) game.player.applyHealth(HEAL_RATE * game.player.totalHealth);
				if(game.minion && game.minion.asleep && game.minion.health < game.minion.totalHealth){
					game.minion.applyHealth(HEAL_RATE * game.minion.totalHealth);
				}
				// update msg anim
				updateMsgAnim();
				
			} else {
				// aggravate local monsters
				aggroCount--;
				if(Brain.monsterCharacters.length){
					var monster:Monster = Brain.monsterCharacters[game.random.rangeInt(Brain.monsterCharacters.length)] as Monster;
					if(monster){
						monster.brain.attack(game.player);
						if(!aggroBegins){
							aggroBegins = true;
							game.console.print("monsters have heard you make camp");
						}
					}
				}
				if(aggroCount <= 0) aggroCount = AGGRO_DELAY;
			}
		}
		
		public function activate():void{
			active = true;
			fadeLight = new FadeLight(FadeLight.SLEEP, game.player.mapX, game.player.mapY, game.player);
			aggroCount = 0;
			game.gameMenu.sleepOption.state = MENU_WAKE_UP;
			game.gameMenu.update();
			aggroBegins = false;
		}
		
		public function deactivate():void{
			visible = false;
			active = false;
			if(fadeLight.active) fadeLight.active = false;
			fadeLight = null;
			game.gameMenu.sleepOption.state = MENU_SLEEP;
			game.gameMenu.update();
			if(nightmare){
				var effect:Effect = new Effect(Effect.FEAR, game.player.level, Effect.EATEN, game.player);
			}
		}
		
		/* Prepare the message animation and list of text */
		private function initDream():void{
			var index:int = game.map.zone;
			dreamList = dreams[index];
			// is the balrog close enough to invade the rogue's dreams?
			var balrogDist:int = int.MAX_VALUE;
			if(UserData.gameState.balrog) balrogDist = Math.abs(UserData.gameState.balrog.mapLevel - game.map.level);
			if(balrogDist <= 1 || (balrogDist <= NIGHTMARE_RANGE && game.random.coinFlip())){
				nightmare = true;
				dreamList = nightmares;
				game.soundQueue.addRandom("laughter", BalrogBrain.LAUGHTER);
			} else {
				nightmare = false;
			}
			var dreamStr:String = dreamList[game.random.rangeInt(dreamList.length)];
			dreamList = dreamStr.split("\n");
			textBox.text = "zzz";
			game.console.print("zzz");
			initMsgAnim();
			visible = true;
		}
		
		/* Prepare the next animation */
		private function initMsgAnim():void{
			charRects = textBox.getCharRects();
			charOffsets = new Vector.<Point>();
			charCols = new Vector.<ColorTransform>();
			charSpeeds = new Vector.<Number>();
			charDelays = new Vector.<int>();
			var i:int, rect:Rectangle, speed:Number;
			for(i = 0; i < charRects.length; i++){
				rect = charRects[i];
				speed = -1 + game.random.range(2);
				charDelays.push(game.random.range(ANIM_DELAY));
				charSpeeds.push(speed);
				charOffsets.push(new Point(rect.x, rect.y - speed * ANIM_DELAY));
				charCols.push(new ColorTransform(0, 0, 0));
			}
			animState = ROLL_IN_TEXT;
			textBox.applyTranformRects(charRects, charOffsets);
			textBox.bitmapData.colorTransform(textBox.bitmapData.rect, new ColorTransform(0, 0, 0));
			animCount = ANIM_DELAY * 2;
		}
		
		private function updateMsgAnim():void{
			var i:int, offset:Point, rect:Rectangle, delay:int, speed:Number, animElapsed:int, col:ColorTransform;
			
			if(animState == ROLL_IN_TEXT){
				animCount--;
				textBox.draw();
				if(nightmare) textBox.bitmapData.colorTransform(textBox.bitmapData.rect, NIGHTMARE_COL);
				if(animCount == 0){
					animState = HOLD_TEXT;
					dreamCount = textBox.text == "zzz" ? 10 : DREAM_DELAY;
				} else {
					animElapsed = ANIM_DELAY * 2 - animCount;
					for(i = 0; i < charRects.length; i++){
						delay = charDelays[i];
						if(animElapsed >= delay && animElapsed - delay <= ANIM_DELAY){
							rect = charRects[i];
							speed = charSpeeds[i];
							offset = charOffsets[i];
							offset.y += speed;
							if((speed < 0 && offset.y < rect.y) || (speed > 0 && offset.y > rect.y)) offset.y = rect.y;
							col = charCols[i];
							col.redMultiplier = col.greenMultiplier = col.blueMultiplier = (animElapsed - delay) * CHAR_COL_STEP;
						}
					}
					textBox.applyTranformRects(charRects, charOffsets, charCols);
				}
			} else if(animState == HOLD_TEXT){
				dreamCount--;
				if(dreamCount == 0){
					animState = ROLL_OUT_TEXT;
					animCount = ANIM_DELAY * 2;
				}
			} else if(animState == ROLL_OUT_TEXT){
				animCount--;
				textBox.draw();
				if(nightmare) textBox.bitmapData.colorTransform(textBox.bitmapData.rect, NIGHTMARE_COL);
				if(animCount == 0){
					if(dreamList.length){
						textBox.text = dreamList.shift();
					} else {
						textBox.text = "zzz";
					}
					initMsgAnim();
				} else {
					animElapsed = ANIM_DELAY * 2 - animCount;
					for(i = 0; i < charRects.length; i++){
						delay = charDelays[i];
						if(animElapsed >= delay && animElapsed - delay <= ANIM_DELAY){
							rect = charRects[i];
							speed = charSpeeds[i];
							offset = charOffsets[i];
							offset.y += speed;
							col = charCols[i];
							col.redMultiplier = col.greenMultiplier = col.blueMultiplier = (ANIM_DELAY - (animElapsed - delay)) * CHAR_COL_STEP;
						}
					}
					textBox.applyTranformRects(charRects, charOffsets, charCols);
				}
			}
		}
		
		public static function initDreams():void{
			var byteArray:ByteArray;
			byteArray = new dreamsData();
			dreams = JSON.decode(byteArray.readUTFBytes(byteArray.length));
			byteArray = new nightmaresData();
			nightmares = JSON.decode(byteArray.readUTFBytes(byteArray.length));
		}
		
	}

}