package com.robotacid.engine {
	import com.adobe.serialization.json.JSON;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.ui.Key;
	import com.robotacid.ui.TextBox;
	import com.robotacid.util.array.randomiseArray;
	import flash.display.DisplayObjectContainer;
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
		public var prompt:TextBox;
		
		// types
		public static const YENDOR:int = 0;
		public static const HUSBAND:int = 1;
		public static const EMPTY_HANDED:int = 2;
		
		// states
		public static const IDLE:int = 0;
		public static const FADE_OUT:int = 1;
		public static const FADE_IN:int = 2;
		
		public function Epilogue(type:int, game:Game, renderer:Renderer) {
			this.type = type;
			this.game = game;
			this.renderer = renderer;
			createLines();
			advance();
			textBox = new TextBox(Game.WIDTH, Game.HEIGHT, 0x0, 0x0);
			prompt = new TextBox(Game.WIDTH - 10, 11, 0x0);
			textBox.align = "center";
			textBox.alignVert = "center";
			prompt.align = "center";
			prompt.x = 5;
			prompt.y = Game.HEIGHT - (prompt.height + 5);
			prompt.text = "press menu key (" + Key.keyString(Key.custom[Game.MENU_KEY]) + ") to advance";
			prompt.alpha = 0.7;
			addChild(textBox);
			addChild(prompt);
			graphics.beginFill(0);
			graphics.drawRect(0, 0, Game.WIDTH, Game.HEIGHT);
			textBox.text = currentStr;
		}
		
		public function main():void{
			if(state == IDLE){
				if(Key.customDown(Game.MENU_KEY)){
					if(index < lines.length){
						advance();
						state = FADE_OUT;
					} else {
						// destructor
						game.transition.init(function():void{
							game.state = Game.GAME;
							game.gameMenu.reset();
							if(game.epilogue.parent) parent.removeChild(game.epilogue);
							game.epilogue = null;
						}, null, "dungeons");
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
			currentStr = lines[index];
			index++;
		}
		
		/* Construct a story to follow the game */
		private function createLines():void{
			lines = [];
			// if this is the player's first ascension, prepend lines with being renamed the immortal
			if(!UserData.settings.ascended){
				lines = lines.concat([
					"like her husband before her, red rogue was given a new name on her return",
					"hearing of her use of the rune of time and her constant cheating of death, they named her...",
					"immortal"
				]);
				UserData.settings.ascended = true;
				var focusPromptParent:DisplayObjectContainer = game.focusPrompt.parent;
				if(focusPromptParent) focusPromptParent.removeChild(game.focusPrompt);
				game.createFocusPrompt();
				if(focusPromptParent) focusPromptParent.addChild(game.focusPrompt);
			}
			// three stories, depending on what happened to yendor
			var deck:Array, str:String;
			if(type == YENDOR){
				if(game.random.value() < 0.5){
					lines.push("she returned to rule the kingdom she had once abandoned");
					lines.push("for " + (20 + game.random.rangeInt(20)) + " years she ruled in peace. no one dared question or make war with one who travelled through time and wielded the power of yendor.");
					lines.push("she took no prince and gave her people no heirs. her quest for vengeance of her dead husband had brought no solace.");
					if(game.minion){
						lines.push("offers of marriage were made to her, dying on their lips as they saw " + game.minion.nameToString() + " advance following her rebuttal");
					}
					lines.push("on her death bed, her people were divided. those doubting her title rioting, those defending it becoming cruel vigilantes. it was not long before the kingdom was at war with its neighbours.");
				} else {
					lines.push("she travelled aimlessly across the kingdom she had once abandonned");
					str = "using the amulet of yendor she ";
					deck = ["slew the dragon of diahrmid pass", "defeated an army of ogres", "scaled the world's tallest mountain to retrieve the egg of the phoenix", "destroyed the ifrit of the barren wastes"];
					randomiseArray(deck, game.random);
					str += deck[0] + " and " + deck[1];
					lines.push(str);
					lines.push("but her heart was still empty, even after claiming vengeance on her husband's murder");
					if(game.minion){
						lines.push(game.minion.nameToString() + " followed her wherever she went on her adventures. tending to her when she was too weary to travel anymore.");
					}
				}
				
			} else if(type == HUSBAND){
				lines.push("she and her husband retired to their farm to live out quieter lives");
				var kids:int = game.random.rangeInt(4);
				if(kids == 1){
					lines.push("they had only one child, whose life was unremarkable, but gave joy to the married couple every day.");
				} else if(kids){
					lines.push("they had " + kids + " children, whose lives were unremarkable, but gave joy to the married couple every day.");
				} else {
					lines.push("they had no children. their adventures had quelled any desire to grow a familiy.");
				}
				lines.push("thankful to merely have each other after being apart in flesh, they led simple lives until the end of their days. the immortal's husband was not fool enough to send his wife on yet another errand.");
				
			} else if(type == EMPTY_HANDED){
				lines.push("returning empty handed, she was able to survive a few days before the calamity struck.");
				lines.push("rng, seizing the power that had once held him hostage, let loose catastrophic chaos.");
				deck = [
					"he turned the seas to oatmeal porridge.", "he replaced all the stars with candles, destroying all warmth and light in the universe.", "he made turned every man whose name began with an \"s\" to lead.", "he replaced the world's fish with birds and world's birds with fish, leaving most to drown.", "he turned great swathes of land to honey, its peoples buried or mired.", "he changed everyone's name to bob, which surprisingly wasn't that harmful.", "he made every blade of grass a sharp as a knife, crippling many.", "he turned all the sand in the world to sodium. the seas exploded."
				];
				randomiseArray(deck, game.random);
				lines.push(deck[0], deck[1], deck[2]);
				lines.push("what life the immortal had the brief chance to experience was not a happy one");
			}
			// the epilogue's ending is always the same
			if(!UserData.settings.minionConsumed){
				if(type == HUSBAND){
					lines.push(["when her husband died, he returned to the underworld."]);
				} else if(game.minion){
					lines.push(["eventually " + game.minion.nameToString() + " returned to the underworld."]);
				}
			}
			lines = lines.concat([
				"when the immortal died, the rune of time took effect" + (UserData.settings.hasDied ? " again as it had when she had died in the dungeon" : "") + ".\n\nperhaps the world continued without her, or perhaps it was erased as she was pulled back through time.",
				"the immortal looked into eternity, and descended..."
			]);
		}
		
	}

}