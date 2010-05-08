package com.robotacid.engine {
	import com.robotacid.dungeon.Map;
	import com.robotacid.geom.Dot;
	import com.robotacid.geom.Rect;
	import com.robotacid.phys.Block;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.util.HiddenInt;
	import flash.display.DisplayObject;
	
	/**
	 * Various entities that will attack the player when triggered
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Trap extends Entity{
		
		public var type:int;
		public var contact:Boolean;
		public var dart_gun:Dot;
		
		// type flags
		public static const SPIKES:int = 1;
		public static const PIT:int = 2;
		public static const POISON_DART:int = 3;
		public static const TELEPORT_DART:int = 4;
		
		public function Trap(mc:DisplayObject, type:int, g:Game) {
			super(mc, g);
			this.type = type;
			if(type == PIT){
				rect = new Rect(x, y - 1, SCALE, SCALE);
			} else if(type == POISON_DART || type == TELEPORT_DART){
				rect = new Rect(x, y - 1, SCALE, 5);
				dart_gun = new Dot(x + SCALE * 0.5, y - SCALE);
				while(!(g.block_map[((dart_gun.y - 1) * INV_SCALE) >> 0][(dart_gun.x * INV_SCALE) >> 0] & Block.WALL)) dart_gun.y -= SCALE;
			}
			call_main = true;
			contact = false;
		}
		
		override public function main():void {
			if(rect.intersects(g.player.rect)){
				if(!contact){
					contact = true;
					resolveCollision();
				}
			} else if(contact){
				contact = false;
			}
			//rect.draw(Game.debug);
		}
		
		public function resolveCollision():void {
			if(type == SPIKES){
				g.player.death("spikes");
			} else {
				if(type == PIT){
					g.console.print("pit trap triggered");
					active = false;
					rect.y += 1;
					g.createDebrisRect(rect, 0, 100, Game.STONE);
					g.shake(0, 3);
					SoundManager.playSound(g.library.KillSound);
					g.block_map[map_y][map_x] = 0;
					g.renderer.removeFromRenderedArray(map_x, map_y, Map.BLOCKS, null);
					g.renderer.removeFromRenderedArray(map_x, map_y, Map.ENTITIES, null);
					g.renderer.removeTile(Map.BLOCKS, map_x, map_y);
					SoundManager.playSound(g.library.KillSound);
				} else if(type == POISON_DART){
					g.console.print("poison trap triggered");
					SoundManager.playSound(g.library.ThrowSound);
					shootDart(new Effect(Effect.POISON, g.dungeon.level, Effect.THROWN, g));
				} else if(type == TELEPORT_DART){
					g.console.print("teleport trap triggered");
					SoundManager.playSound(g.library.ThrowSound);
					shootDart(new Effect(Effect.TELEPORT, Game.MAX_LEVEL, Effect.THROWN, g));
				}
			}
		}
		
		public function shootDart(effect:Effect):void{
			var missile_mc:DisplayObject = new g.library.DartMC();
			missile_mc.x = dart_gun.x;
			missile_mc.y = dart_gun.y;
			g.entities_holder.addChild(missile_mc);
			var missile:Missile = new Missile(missile_mc, Missile.DART, null, 0, 1, 5, g, Block.LADDER | Block.LEDGE, effect);
		}
		
	}
	
}