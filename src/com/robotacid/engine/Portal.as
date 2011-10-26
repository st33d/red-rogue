package com.robotacid.engine {
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
		
		public var type:int;
		public var seen:Boolean;
		
		public var rect:Rectangle;
		
		// names
		public static const STAIRS:int = 0;
		public static const TOWN_PORTAL:int = 1;
		public static const MOB_SPAWNER:int = 2;
		public static const QUEST:int = 3;
		
		// types - these refer to the direction they lead out of the level, a DOWN portal will take you deeper
		public static const UP:int = 0;
		public static const DOWN:int = 1;
		public static const SIDE:int = 2;
		
		public function Portal(mc:DisplayObject, rect:Rectangle, type:int) {
			super(mc, false, false);
			this.type = type;
			this.rect = rect;
			callMain = true;
			active = true;
			seen = false;
			g.portals.push(this);
		}
		
		override public function main():void {
			// if the stairs are visible on the map - then make the stairs icon on the map visible
			if(!seen && g.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000){
				seen = true;
				var bitmapData:BitmapData = new BitmapData(3, 3, true, 0x00000000);
				if(type == UP) {
					bitmapData.setPixel32(1, 0, 0xFFFFFFFF);
					bitmapData.fillRect(new Rectangle(0, 1, 3, 1), 0xFFFFFFFF);
				} else if(type == DOWN){
					bitmapData.setPixel32(1, 2, 0xFFFFFFFF);
					bitmapData.fillRect(new Rectangle(0, 1, 3, 1), 0xFFFFFFFF);
				}
				g.miniMap.addFeature(mapX, mapY, -1, -1, bitmapData);
				callMain = false;
			}
		}
		
		override public function remove():void {
			g.portals.splice(g.portals.indexOf(this), 1);
			super.remove();
		}
	}

}