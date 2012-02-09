package com.robotacid.ui {
	import com.robotacid.gfx.Renderer;
	import com.robotacid.ui.menu.EditorMenuList;
	import com.robotacid.ui.menu.GameMenu;
	import com.robotacid.ui.menu.MenuList;
	import com.robotacid.ui.menu.MenuOption;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * 
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Editor {
		
		public var game:Game;
		public var renderer:Renderer;
		public var highlight:BitmapData;
		public var menuList:EditorMenuList;
		public var bitmap:Bitmap;
		public var bitmapData:BitmapData;
		
		public var active:Boolean;
		public var mapX:int;
		public var mapY:int;
		
		public static var point:Point = new Point();
		
		public function Editor(game:Game, renderer:Renderer) {
			this.game = game;
			this.renderer = renderer;
			highlight = new BitmapData(Game.SCALE, Game.SCALE, true, 0xFFFFFFFF);
			highlight.fillRect(new Rectangle(1, 1, Game.SCALE-2, Game.SCALE-2), 0x00000000);
			bitmap = new Bitmap(new BitmapData(Game.WIDTH, Game.HEIGHT - Console.HEIGHT, true, 0x00000000));
			bitmapData = bitmap.bitmapData;
			
			//active = true;
		}
		
		public function main():void{
			mapX = renderer.canvas.mouseX * Game.INV_SCALE;
			mapY = renderer.canvas.mouseY * Game.INV_SCALE;
			if(mapX < 1) mapX = 1;
			if(mapY < 1) mapY = 1;
			if(mapX > game.dungeon.width - 2) mapX = game.dungeon.width - 2;
			if(mapY > game.dungeon.height - 2) mapY = game.dungeon.height - 2;
			if(game.mousePressedCount == game.frameCount){
				menuList.applySelection(mapX, mapY);
			}
		}
		
		public function render():void{
			bitmapData.fillRect(bitmapData.rect, 0x00000000);
			point.x = -renderer.bitmap.x + mapX * Game.SCALE;
			point.y = -renderer.bitmap.y + mapY * Game.SCALE;
			bitmapData.copyPixels(highlight, highlight.rect, point, null, null, true);
		}
		
	}

}