package com.robotacid.engine {
	import com.robotacid.dungeon.Map;
	import com.robotacid.geom.Dot;
	import com.robotacid.geom.Rect;
	import com.robotacid.phys.Block;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.util.HiddenInt;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	/**
	 * Various entities that will attack the player when triggered
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Trap extends Entity{
		
		public var type:int;
		public var contact:Boolean;
		public var revealed:Boolean;
		public var dartGun:Dot;
		public var count:int;
		
		// type flags
		public static const PIT:int = 0;
		public static const POISON_DART:int = 1;
		public static const TELEPORT_DART:int = 2;
		
		public static const SPIKES:int = 3;
		
		public static const PIT_COVER_DELAY:int = 7;
		
		public function Trap(mc:DisplayObject, type:int, g:Game) {
			super(mc, g);
			this.type = type;
			revealed = false;
			if(type == PIT){
				rect = new Rect(x, y - 1, SCALE, SCALE);
			} else if(type == POISON_DART || type == TELEPORT_DART){
				rect = new Rect(x, y - 1, SCALE, 5);
				dartGun = new Dot(x + SCALE * 0.5, y - SCALE);
				while(!(g.blockMap[((dartGun.y - 1) * INV_SCALE) >> 0][(dartGun.x * INV_SCALE) >> 0] & Block.WALL)) dartGun.y -= SCALE;
			}
			callMain = true;
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
			if(count){
				count--;
				if(count == 0){
					if(type == PIT){
						active = false;
						g.renderer.addToRenderedArray(mapX, mapY, Map.BLOCKS, MapTileConverter.ID_TO_GRAPHIC[MapTileConverter.LEDGE_SINGLE]);
						g.renderer.mapArrayLayers[Map.BLOCKS][mapY][mapX] = MapTileConverter.LEDGE_SINGLE;
						g.blockMap[mapY][mapX] = Rect.UP | Block.LEDGE;
					}
				}
			}
			//rect.draw(Game.debug);
		}
		
		public function resolveCollision():void {
			if(type == SPIKES){
				// thinking that this should be a character wide trap
			} else {
				if(type == PIT){
					if(count) return;
					count = PIT_COVER_DELAY;
					g.console.print("pit trap triggered");
					//active = false;
					rect.y += 1;
					g.createDebrisRect(rect, 0, 100, Game.STONE);
					g.shake(0, 3);
					SoundManager.playSound(g.library.KillSound);
					g.blockMap[mapY][mapX] = 0;
					g.renderer.removeFromRenderedArray(mapX, mapY, Map.BLOCKS, null);
					g.renderer.removeFromRenderedArray(mapX, mapY, Map.ENTITIES, null);
					g.renderer.removeTile(Map.BLOCKS, mapX, mapY);
					g.renderer.addTile(Map.BLOCKS, mapX, mapY, MapTileConverter.LEDGE_SINGLE);
					// check to see if any colliders are on this and drop them
					for(var i:int = 0; i < g.colliders.length; i++){
						if(g.colliders[i].mapX == mapX && g.colliders[i].mapY == mapY - 1){
							g.colliders[i].divorce();
						}
					}
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
			// a trap that still exists after being triggered gets revealed
			if(!revealed && active){
				reveal();
			}
		}
		/* Adds a graphic to this trap to show the player where it is */
		public function reveal():void{
			var trapRevealedB:Bitmap = new g.library.TrapRevealedB();
			trapRevealedB.y = -SCALE;
			(mc as Sprite).addChild(trapRevealedB);
			revealed = true;
		}
		
		public function shootDart(effect:Effect):void{
			var missileMc:DisplayObject = new g.library.DartMC();
			missileMc.x = dartGun.x;
			missileMc.y = dartGun.y;
			g.entitiesHolder.addChild(missileMc);
			var missile:Missile = new Missile(missileMc, Missile.DART, null, 0, 1, 5, g, Block.LADDER | Block.LEDGE, effect);
		}
		
	}
	
}