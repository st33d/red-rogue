package com.robotacid.engine {
	import com.robotacid.dungeon.Map;
	import com.robotacid.engine.Entity;
	import com.robotacid.phys.Collider;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.DisplayObject;
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
		
		private var count:int;
		private var scaleStep:Number;
		private var spawn:Character;
		
		public var rect:Rectangle;
		
		// states
		public static const OPEN:int = 0;
		public static const OPENING:int = 1;
		public static const CLOSING:int = 2;
		
		// types
		public static const STAIRS:int = 0;
		public static const TOWN_PORTAL:int = 1;
		public static const MONSTER_SPAWNER:int = 2;
		public static const QUEST:int = 3;
		public static const MINON:int = 4;
		
		public static const OPEN_CLOSE_DELAY:int = 20;
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
				scaleStep = 1.0 / OPEN_CLOSE_DELAY;
				count = OPEN_CLOSE_DELAY;
			}
			g.portals.push(this);
		}
		
		override public function main():void {
			if(state == OPENING){
				if(count){
					count--;
					gfx.scaleX += scaleStep;
					gfx.scaleY += scaleStep;
				} else {
					gfx.scaleX = gfx.scaleY = 1;
					state = OPEN;
					if(type == MONSTER_SPAWNER){
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
					gfx.scaleX -= scaleStep;
					gfx.scaleY -= scaleStep;
				} else {
					g.mapRenderer.removeFromRenderedArray(mapX, mapY, Map.ENTITIES, null);
					active = false;
				}
			}
		}
		
		override public function remove():void {
			g.portals.splice(g.portals.indexOf(this), 1);
			super.remove();
		}
	}

}