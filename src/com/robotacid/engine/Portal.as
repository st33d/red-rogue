package com.robotacid.engine {
	import com.robotacid.dungeon.Map;
	import com.robotacid.engine.Entity;
	import com.robotacid.phys.Collider;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * A gateway for Characters to enter or exit the level
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Portal extends Entity{
		
		public var state:int;
		public var type:int;
		public var seen:Boolean;
		public var targetLevel:int;
		
		public var item:Item;
		public var character:Character;
		
		private var count:int;
		
		public var rect:Rectangle;
		
		// states
		public static const OPEN:int = 0;
		public static const OPENING:int = 1;
		public static const CLOSING:int = 2;
		
		// types
		public static const STAIRS:int = 0;
		public static const ROGUE:int = 1;
		public static const MONSTER:int = 2;
		public static const ITEM:int = 3;
		public static const MINION:int = 4;
		public static const DUNGEON:int = 5;
		
		public static const GFX_CLASSES:Array = [, RoguePortalMC, MonsterPortalMC, DungeonPortalMC, MinionPortalMC, DungeonPortalMC];
		
		public static const OPEN_CLOSE_DELAY:int = 8;
		public static const SCALE_STEP:Number = 1.0 / OPEN_CLOSE_DELAY;
		public static const GFX_STEP:Number = (SCALE * 0.5) / OPEN_CLOSE_DELAY;
		public static const MONSTERS_PER_LEVEL:int = 2;
		
		public function Portal(mc:DisplayObject, rect:Rectangle, type:int, targetLevel:int) {
			super(mc, false, false);
			this.type = type;
			this.rect = rect;
			this.targetLevel = targetLevel;
			callMain = true;
			active = true;
			seen = false;
			if(type == STAIRS){
				state = OPEN;
			} else {
				state = OPENING;
				mc.scaleX = mc.scaleY = 0;
				mc.x += SCALE * 0.5;
				mc.y += SCALE * 0.5;
				count = OPEN_CLOSE_DELAY;
			}
			g.portals.push(this);
		}
		
		override public function main():void {
			if(state == OPENING){
				if(count){
					count--;
					gfx.scaleX += SCALE_STEP;
					gfx.scaleY += SCALE_STEP;
					gfx.x -= GFX_STEP;
					gfx.y -= GFX_STEP;
				} else {
					gfx.scaleX = gfx.scaleY = 1;
					gfx.x = mapX * SCALE;
					gfx.y = mapY * SCALE;
					state = OPEN;
					if(type == MONSTER){
						count = MONSTERS_PER_LEVEL * g.dungeon.level;
					}
				}
			} else if(state == OPEN){
				// if the portal is visible on the map - then make the portal icon on the map visible
				if(!seen && g.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000){
					seen = true;
					var bitmapData:BitmapData = new BitmapData(3, 3, true, 0x00000000);
					if(type == STAIRS){
						if(targetLevel < g.dungeon.level) {
							bitmapData.setPixel32(1, 0, 0xFFFFFFFF);
							bitmapData.fillRect(new Rectangle(0, 1, 3, 1), 0xFFFFFFFF);
						} else if(targetLevel > g.dungeon.level){
							bitmapData.setPixel32(1, 2, 0xFFFFFFFF);
							bitmapData.fillRect(new Rectangle(0, 1, 3, 1), 0xFFFFFFFF);
						}
					} else {
						bitmapData.setPixel32(1, 0, 0xFFFFFFFF);
						bitmapData.setPixel32(1, 2, 0xFFFFFFFF);
						bitmapData.fillRect(new Rectangle(0, 1, 3, 1), 0xFFFFFFFF);
					}
					g.miniMap.addFeature(mapX, mapY, -1, -1, bitmapData);
				}
			} else if(state == CLOSING){
				if(count){
					count--;
					gfx.scaleX -= SCALE_STEP;
					gfx.scaleY -= SCALE_STEP;
					gfx.x += GFX_STEP;
					gfx.y += GFX_STEP;
				} else {
					g.mapRenderer.removeFromRenderedArray(mapX, mapY, Map.ENTITIES, null);
					active = false;
				}
			}
		}
		
		public function close():void{
			state = CLOSING;
		}
		
		override public function remove():void {
			g.portals.splice(g.portals.indexOf(this), 1);
			g.portalHash[type] = false;
			super.remove();
		}
		
		/* Generates a portal within a level - only one portal of each type is allowed in the game */
		public static function createPortal(type:int, mapX:int, mapY:int, targetLevel:int = 0):Portal{
			var i:int, portal:Portal;
			// check that the portal is on a surface - if not cast downwards and put it on one
			while(!(g.world.map[mapY + 1][mapX] & Collider.UP)) mapY++;
			// check we're not obscuring the level stairs.
			// To avoid writing out the logic twice I'm popping an extra iteration in the loop to check the
			// MapRenderer tile position
			for(i = 0; i < g.portals.length + 1; i++){
				if(i < g.portals.length) portal = g.portals[i];
				else portal = g.mapRenderer.mapArrayLayers[Map.ENTITIES][mapY][mapX] as Portal;
				if(portal && portal.type == STAIRS && portal.mapX == mapX && portal.mapY == mapY){
					// there will be a square to the side of the stairs free - that's the level generation logic
					// check there is floor there
					if(g.world.map[mapY + 1][mapX + 1] & Collider.UP){
						mapX++;
					// fuck it - they can jump for the portal, they should have the sense not to put it in front of stairs
					} else {
						mapX--;
					}
					break;
				}
			}
			var mc:MovieClip = new GFX_CLASSES[type]();
			mc.x = mapX * SCALE;
			mc.y = mapY * SCALE;
			portal = new Portal(mc, new Rectangle(mapX * SCALE, mapY * SCALE, SCALE, SCALE), type, targetLevel);
			portal.mapX = mapX;
			portal.mapY = mapY;
			portal.mapZ = Map.ENTITIES;
			// the portal may have been generated outside of the mapRenderer zone
			if(!g.mapRenderer.intersects(portal.rect)){
				portal.remove();
			}
			// only one portal of a kind per level, existing portals are closed
			if(g.portalHash[type]){
				g.portalHash[type].close();
			}
			g.portalHash[type] = portal;
			return portal;
		}
	}

}