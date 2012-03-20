package com.robotacid.engine {
	import com.robotacid.dungeon.Content;
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	
	/**
	 * Appears to be a chest but actually generates a MIMIC Character
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Mimic extends Entity {
		
		public var rect:Rectangle;
		public var mimicXML:XML;
		public var twinkleCount:int;
		
		public static const TWINKLE_DELAY:int = Chest.TWINKLE_DELAY;
		
		public function Mimic(xml:XML, mapX:int, mapY:int) {
			mimicXML = xml;
			this.mapX = mapX;
			this.mapY = mapY;
			gfx = new ChestMC();
			gfx.x = (mapX + 0.5) * Game.SCALE;
			gfx.y = (mapY + 1) * Game.SCALE;
			super(gfx, false, false);
			rect = new Rectangle((mapX - 1) * Game.SCALE, (mapY - 1) * Game.SCALE, SCALE * 3, SCALE * 3);
			callMain = true;
			
		}
		
		override public function main():void {
			// concealing the twinkle in the dark will help avoid showing a clipped effect on the edge
			// of the light map
			if(game.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000){
				// create a twinkle twinkle effect so the player knows this is a collectable
				if(twinkleCount-- <= 0){
					renderer.addFX(rect.x + game.random.range(rect.width), rect.y + game.random.range(rect.height), renderer.twinkleBlit);
					twinkleCount = TWINKLE_DELAY + game.random.range(TWINKLE_DELAY);
				}
			}
			if(
				game.player.collider.x >= rect.x &&
				game.player.collider.x + game.player.collider.width <= rect.x + rect.width &&
				game.player.collider.y < rect.y + rect.height &&
				game.player.collider.y + game.player.collider.height > rect.y &&
				!game.player.indifferent
			){
				// create mimic
				var monster:Monster = Content.XMLToEntity(mapX, mapY, mimicXML);
				game.mapTileManager.converter.convertIndicesToObjects(mapX, mapY, monster);
				renderer.createTeleportSparkRect(monster.collider, 20);
				game.soundQueue.add("chestOpen");
			}
		}
		
	}

}