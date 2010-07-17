package com.robotacid.engine {
	import com.robotacid.engine.Entity;
	import com.robotacid.geom.Rect;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	
	/**
	 * A trap style entity that allows access to the next/previous level
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Stairs extends Entity{
		
		public var type:int;
		public var contact:Boolean;
		public var mask:Bitmap;
		public var seen:Boolean;
		
		public static const UP:int = 0;
		public static const DOWN:int = 1;
		
		/* This variable tells me whether the player was heading up or down stairs when entering
		 * the level */
		public static var lastStairsUsedType:int = DOWN;
		
		public function Stairs(mc:DisplayObject, type:int, g:Game) {
			super(mc, g);
			this.type = type;
			rect = new Rect(x, y, SCALE, SCALE);
			callMain = true;
			contact = false;
			mask = new g.library.StairsMaskB();
			mask.x = mc.x;
			mask.y = mc.y;
			mask.cacheAsBitmap = true;
			if(type != lastStairsUsedType) g.entrance = this;
			seen = false;
		}
		
		override public function main():void {
			if(rect.intersects(g.player.rect) && g.player.state == Character.WALKING){
				if(!contact){
					contact = true;
					g.menu.stairsOption.active = true;
					g.menu.goUpDownOption.state = type;
					g.menu.selection = g.menu.selection;
					g.menu.goUpDownOption.target = this;
				}
			} else if(contact){
				contact = false;
				g.menu.stairsOption.active = false;
				if(g.menu.currentMenuList == g.menu.stairsList) g.menu.stepBack();
				g.menu.selection = g.menu.selection;
			}
			// if the stairs are visible on the map - then make the stairs icon on the map visible
			if(!seen && g.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000){
				seen = true;
				if(type == UP){
					g.miniMap.stairsUp.visible = true;
					g.miniMap.stairsUp.x = mapX - 1;
					g.miniMap.stairsUp.y = mapY - 1;
				} else if(type == DOWN){
					g.miniMap.stairsDown.visible = true;
					g.miniMap.stairsDown.x = mapX - 1;
					g.miniMap.stairsDown.y = mapY - 1;
				}
			}
			//rect.draw(Game.debug);
		}
	}

}