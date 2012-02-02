package com.robotacid.ui {
	import com.robotacid.gfx.Renderer;
	import com.robotacid.ui.menu.EditorMenuList;
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
			if(game.mousePressedCount == game.frameCount){
				editorAction(renderer.canvas.mouseX * Game.INV_SCALE, renderer.canvas.mouseY * Game.INV_SCALE);
			}
		}
		
		public function render():void{
			point.x = -renderer.bitmap.x + ((renderer.canvas.mouseX * Game.INV_SCALE) >> 0) * Game.SCALE;
			point.y = -renderer.bitmap.y + ((renderer.canvas.mouseY * Game.INV_SCALE) >> 0) * Game.SCALE;
			renderer.bitmapData.copyPixels(highlight, highlight.rect, point, null, null, true);
		}
		
		/* Performs an action at mapX, mapY based on the current configuration of the EditorMenuList */
		public function editorAction(mapX:int, mapY:int):void{
			
		}
		
	}

}