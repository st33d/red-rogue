package com.robotacid.ui {
	import com.robotacid.ai.Brain;
	import com.robotacid.ai.DungeonGraph;
	import com.robotacid.ai.Node;
	import com.robotacid.geom.Pixel;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.phys.Collider;
	import com.robotacid.ui.menu.EditorMenuList;
	import com.robotacid.ui.menu.GameMenu;
	import com.robotacid.ui.menu.MenuList;
	import com.robotacid.ui.menu.MenuOption;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Matrix;
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
		public var sprite:Sprite;
		
		public var active:Boolean;
		public var mapX:int;
		public var mapY:int;
		public var topLeft:Pixel;
		public var bottomRight:Pixel;
		
		public static var point:Point = new Point();
		
		public function Editor(game:Game, renderer:Renderer) {
			this.game = game;
			this.renderer = renderer;
			highlight = new BitmapData(Game.SCALE, Game.SCALE, true, 0xFFFFFFFF);
			highlight.fillRect(new Rectangle(1, 1, Game.SCALE-2, Game.SCALE-2), 0x00000000);
			bitmap = new Bitmap(new BitmapData(Game.WIDTH, Game.HEIGHT - Console.HEIGHT, true, 0x00000000));
			bitmapData = bitmap.bitmapData;
			topLeft = new Pixel();
			bottomRight = new Pixel();
			sprite = new Sprite();
			
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
				menuList.applySelection(mapX, mapY, EditorMenuList.MOUSE_CLICK);
			} else if(game.mousePressed){
				menuList.applySelection(mapX, mapY, EditorMenuList.MOUSE_HELD);
			}
			topLeft.x = -renderer.canvas.x * Game.INV_SCALE;
			topLeft.y = -renderer.canvas.y * Game.INV_SCALE;
			if(topLeft.x < 1) topLeft.x = 1;
			if(topLeft.y < 1) topLeft.y = 1;
			bottomRight.x = (-renderer.canvas.x + Game.WIDTH) * Game.INV_SCALE;
			bottomRight.y = (-renderer.canvas.y + Game.WIDTH) * Game.INV_SCALE;
			if(bottomRight.x > game.dungeon.width - 2) bottomRight.x = game.dungeon.width - 2;
			if(bottomRight.y > game.dungeon.height - 2) bottomRight.y = game.dungeon.height - 2;
		}
		
		public function activate():void{
			active = true;
			bitmap.visible = true;
		}
		
		public function deactivate():void{
			active = false;
			bitmap.visible = false;
		}
		
		public function render():void{
			var i:int, rect:Rectangle;
			var r:int, c:int;
			var gfx:Graphics;
			
			bitmapData.fillRect(bitmapData.rect, 0x00000000);
			
			// render settings
			if(menuList.renderCollisionList.selection == EditorMenuList.ON){
				for(i = 0; i < game.world.colliders.length; i++){
					rect = game.world.colliders[i].clone();
					rect.x -= renderer.bitmap.x;
					rect.y -= renderer.bitmap.y;
					bitmapData.fillRect(rect, 0xCC00FF00);
				}
			}
			if(menuList.renderAIGraphList.selection == EditorMenuList.ON){
				var graph:DungeonGraph = Brain.dungeonGraph;
				var node:Node;
				gfx = sprite.graphics;
				gfx.clear();
				for(r = topLeft.y; r <= bottomRight.y; r++){
					for(c = topLeft.x; c <= bottomRight.x; c++){
						if(graph.nodes[r][c]){
							node = graph.nodes[r][c];
							gfx.lineStyle(2, 0xFFFF00, 0.3);
							gfx.drawCircle((node.x + 0.5) * Game.SCALE, (node.y + 0.5) * Game.SCALE, Game.SCALE * 0.1);
							for(i = 0; i < node.connections.length; i++){
								gfx.moveTo((node.x + 0.5) * Game.SCALE, (node.y + 0.5) * Game.SCALE);
								gfx.lineTo((node.connections[i].x + 0.5) * Game.SCALE, (node.connections[i].y + 0.5) * Game.SCALE);
								// arrows
								gfx.lineStyle(2, 0xFFFF00, 0.5);
								if(node.connections[i].x == node.x){
									if(node.connections[i].y > node.y){
										gfx.moveTo((node.x + 0.3) * Game.SCALE, (node.y + 0.7) * Game.SCALE);
										gfx.lineTo((node.x + 0.5) * Game.SCALE, (node.y + 0.8) * Game.SCALE);
										gfx.lineTo((node.x + 0.7) * Game.SCALE, (node.y + 0.7) * Game.SCALE);
									} else if(node.connections[i].y < node.y){
										gfx.moveTo((node.x + 0.3) * Game.SCALE, (node.y + 0.3) * Game.SCALE);
										gfx.lineTo((node.x + 0.5) * Game.SCALE, (node.y + 0.2) * Game.SCALE);
										gfx.lineTo((node.x + 0.7) * Game.SCALE, (node.y + 0.3) * Game.SCALE);
									}
								} else if(node.connections[i].y == node.y){
									if(node.connections[i].x > node.x){
										gfx.moveTo((node.x + 0.7) * Game.SCALE, (node.y + 0.3) * Game.SCALE);
										gfx.lineTo((node.x + 0.8) * Game.SCALE, (node.y + 0.5) * Game.SCALE);
										gfx.lineTo((node.x + 0.7) * Game.SCALE, (node.y + 0.7) * Game.SCALE);
									} else if(node.connections[i].x < node.x){
										gfx.moveTo((node.x + 0.3) * Game.SCALE, (node.y + 0.3) * Game.SCALE);
										gfx.lineTo((node.x + 0.2) * Game.SCALE, (node.y + 0.5) * Game.SCALE);
										gfx.lineTo((node.x + 0.3) * Game.SCALE, (node.y + 0.7) * Game.SCALE);
									}
								}
							}
						}
					}
				}
				bitmapData.draw(sprite, new Matrix(1, 0, 0, 1, -renderer.bitmap.x, -renderer.bitmap.y));
			}
			
			//rect = new Rectangle(topLeft.x * Game.SCALE, topLeft.y * Game.SCALE, Game.SCALE, Game.SCALE);
			//rect.x -= renderer.bitmap.x;
			//rect.y -= renderer.bitmap.y;
			//bitmapData.fillRect(rect, 0xCCFF0000);
			//rect = new Rectangle(bottomRight.x * Game.SCALE, bottomRight.y * Game.SCALE, Game.SCALE, Game.SCALE);
			//rect.x -= renderer.bitmap.x;
			//rect.y -= renderer.bitmap.y;
			//bitmapData.fillRect(rect, 0xCCFF0000);
			
			// selection rect
			point.x = -renderer.bitmap.x + mapX * Game.SCALE;
			point.y = -renderer.bitmap.y + mapY * Game.SCALE;
			bitmapData.copyPixels(highlight, highlight.rect, point, null, null, true);
		}
		
	}

}