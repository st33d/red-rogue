package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.dungeon.Map;
	import com.robotacid.engine.Character;
	import com.robotacid.sound.SoundManager;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class Stone extends Character{
		
		public var side:int;
		public var revealed:Boolean;
		
		public static const SECRET_WALL:int = 0;
		public static const HEALTH:int = 1;
		public static const GRIND:int = 2;
		
		public static const STONE_NAME_HEALTHS:Array = [
			5,
			0,
			0
		];
		
		public function Stone(mc:DisplayObject, name:int, width:int, height:int, g:Game) {
			super(mc, name, STONE, 0, width, height, g, true);
			health = STONE_NAME_HEALTHS[name];
			defense = 0;
			callMain = false;
			debrisType = name == HEALTH ? Game.BLOOD : Game.STONE;
			free = false;
			weight = 20;
			crushable = false;
			if(name == SECRET_WALL){
				revealed = false;
				if(x >= g.renderer.mapRect.x + g.renderer.mapRect.width * 0.5){
					side = RIGHT;
				} else {
					side = LEFT;
				}
			}
		}
		
		override public function applyDamage(n:Number, source:String, critical:Boolean = false, aggressor:int = PLAYER):void {
			if(name == SECRET_WALL) super.applyDamage(n, source, critical);
			else if(name == HEALTH){
				g.player.applyHealth(n);
			} else if(name == GRIND){
				g.player.addXP(0.1);
			}
		}
		
		/* Update collision Rect / Block around character */
		override public function updateRect():void{
			rect.x = x;
			rect.y = y;
			rect.width = width;
			rect.height = height;
		}
		
		/* The secret wall is the only stone that can be destroyed, so only its death is dealt with here */
		override public function death(cause:String, decapitation:Boolean = false, aggressor:int = PLAYER):void {
			active = false;
			g.createDebrisRect(rect, 0, 100, debrisType);
			g.console.print("secret revealed");
			g.shake(0, 3);
			SoundManager.playSound(g.library.KillSound);
			g.player.addXP(xpReward);
			g.blockMap[mapY][mapX] = 0;
			g.renderer.removeFromRenderedArray(mapX, mapY, Map.BLOCKS, null);
			g.renderer.removeFromRenderedArray(mapX, mapY, Map.ENTITIES, null);
			g.renderer.removeTile(Map.BLOCKS, mapX, mapY);
			// adjust the mapRect to show new content
			if(mapX < g.player.mapX){
				g.renderer.mapRect.x = 0;
				g.renderer.mapRect.width += g.dungeon.bitmap.leftSecretWidth;
			} else if(mapX > g.player.mapX){
				g.renderer.mapRect.width += g.dungeon.bitmap.rightSecretWidth;
			}
		}
		
		/* A search action can reveal to the player where a secret wall is */
		public function reveal():void{
			var trapRevealedB:Bitmap = new g.library.TrapRevealedB();
			var matrix:Matrix = new Matrix();
			matrix.tx = -SCALE * 0.5;
			matrix.ty = -SCALE * 0.5;
			matrix.rotate(side == RIGHT ? -Math.PI * 0.5 : Math.PI * 0.5);
			matrix.tx += side == RIGHT ? -((SCALE * 0.5) - 1) : 1 + (SCALE * 1.5);
			matrix.ty += SCALE * 0.5;
			trace(matrix.tx);
			trapRevealedB.transform.matrix = matrix;
			(mc as Sprite).addChild(trapRevealedB);
			revealed = true;
			trace("revealed secret");
		}
	}

}