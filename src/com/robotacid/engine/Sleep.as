package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.ui.Console;
	import com.robotacid.ui.TextBox;
	import flash.display.Shape;
	import flash.display.Sprite;
	
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
		
		private var fadeLight:FadeLight;
		private var aggroCount:int;
		private var aggroBegins:Boolean;
		
		public static const HEIGHT:Number = Game.HEIGHT - Console.HEIGHT;
		public static const HEAL_RATE:Number = 1.0 / 180;
		public static const AGGRO_DELAY:Number = 60;
		public static const MENU_SLEEP:int = 0;
		public static const MENU_WAKE_UP:int = 1;
		
		public function Sleep(game:Game, renderer:Renderer) {
			this.game = game;
			this.renderer = renderer;
			textBox = new TextBox(Game.WIDTH, 11 * 3, 0x0, 0x0);
			textBox.y = (HEIGHT * 0.5 - textBox.height * 0.5) >> 0;
			textBox.align = "center";
			textBox.alignVert = "center";
			addChild(textBox);
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
					textBox.text = "zzz";
					game.console.print("zzz");
					visible = true;
				}
				// heal the player
				if(game.player.health < game.player.totalHealth) game.player.applyHealth(HEAL_RATE * game.player.totalHealth);
				if(game.minion && game.minion.asleep && game.minion.health < game.minion.totalHealth){
					game.minion.applyHealth(HEAL_RATE * game.minion.totalHealth);
				}
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
			game.menu.sleepOption.state = MENU_WAKE_UP;
			game.menu.update();
			aggroBegins = false;
		}
		
		public function deactivate():void{
			visible = false;
			active = false;
			if(fadeLight.active) fadeLight.active = false;
			fadeLight = null;
			game.menu.sleepOption.state = MENU_SLEEP;
			game.menu.update();
		}
		
	}

}