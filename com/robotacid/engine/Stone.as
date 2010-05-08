package com.robotacid.engine {
	import com.robotacid.dungeon.Map;
	import com.robotacid.engine.Character;
	import com.robotacid.sound.SoundManager;
	import flash.display.DisplayObject;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class Stone extends Character{
		
		public static const SECRET_WALL:int = 0;
		public static const HEALTH:int = 1;
		public static const GRIND:int = 2;
		
		public static const STONE_NAME_HEALTHS:Array = [
			3,
			0,
			0
		];
		
		public function Stone(mc:DisplayObject, name:int, width:int, height:int, g:Game) {
			super(mc, name, STONE, 0, width, height, g);
			health = STONE_NAME_HEALTHS[name];
			defense = 0;
			call_main = false;
			debris_type = name == HEALTH ? Game.BLOOD : Game.STONE;
			free = false;
			weight = 20;
			crushable = false;
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
		
		override public function death(cause:String, decapitation:Boolean = false, aggressor:int = PLAYER):void {
			active = false;
			g.createDebrisRect(rect, 0, 100, debris_type);
			g.console.print("secret revealed");
			g.shake(0, 3);
			SoundManager.playSound(g.library.KillSound);
			g.player.addXP(xp_reward);
			g.block_map[map_y][map_x] = 0;
			g.renderer.removeFromRenderedArray(map_x, map_y, Map.BLOCKS, null);
			g.renderer.removeFromRenderedArray(map_x, map_y, Map.ENTITIES, null);
			g.renderer.removeTile(Map.BLOCKS, map_x, map_y);
		}
	}

}