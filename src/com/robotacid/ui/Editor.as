package com.robotacid.ui {
	import com.robotacid.ai.Brain;
	import com.robotacid.ai.MapGraph;
	import com.robotacid.ai.Node;
	import com.robotacid.engine.Character;
	import com.robotacid.geom.Pixel;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.level.Surface;
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
		public var textBox:TextBox;
		
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
			highlight.fillRect(new Rectangle(1, 1, Game.SCALE-2, Game.SCALE-2), 0x0);
			bitmap = new Bitmap(new BitmapData(Game.WIDTH, Game.HEIGHT - Console.HEIGHT, true, 0x0));
			bitmapData = bitmap.bitmapData;
			topLeft = new Pixel();
			bottomRight = new Pixel();
			sprite = new Sprite();
			textBox = new TextBox(100, 12, 0x0, 0x0);
			//active = true;
		}
		
		public function main():void{
			mapX = renderer.canvas.mouseX * Game.INV_SCALE;
			mapY = renderer.canvas.mouseY * Game.INV_SCALE;
			if(mapX < 1) mapX = 1;
			if(mapY < 1) mapY = 1;
			if(mapX > game.map.width - 2) mapX = game.map.width - 2;
			if(mapY > game.map.height - 2) mapY = game.map.height - 2;
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
			if(bottomRight.x > game.map.width - 2) bottomRight.x = game.map.width - 2;
			if(bottomRight.y > game.map.height - 2) bottomRight.y = game.map.height - 2;
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
			
			var i:int, r:int, c:int;
			var node:Node, character:Character;
			var gfx:Graphics = sprite.graphics;
			var graph:MapGraph = Brain.mapGraph;
			var wallWalkGraph:MapGraph = Brain.walkWalkGraph;
			var rect:Rectangle = new Rectangle();
			
			bitmapData.fillRect(bitmapData.rect, 0x0);
			
			// render settings
			if(menuList.renderCollisionList.selection == EditorMenuList.ON){
				// parent colliders
				for(i = 0; i < game.world.colliders.length; i++){
					if(game.world.colliders[i].parent){
						rect = game.world.colliders[i].parent.clone();
						rect.x -= renderer.bitmap.x;
						rect.y -= renderer.bitmap.y;
						bitmapData.fillRect(rect, 0xCC0000FF);
					}
				}
				// colliders
				for(i = 0; i < game.world.colliders.length; i++){
					rect = game.world.colliders[i].clone();
					rect.x -= renderer.bitmap.x;
					rect.y -= renderer.bitmap.y;
					bitmapData.fillRect(rect, 0xCC00FF00);
				}
			}
			if(menuList.renderAIGraphList.selection == EditorMenuList.ON){
				gfx.clear();
				gfx.lineStyle(2, 0xFFFF00, 0.4);
				graph.drawGraph(graph.nodes, gfx, Game.SCALE, topLeft, bottomRight);
				bitmapData.draw(sprite, new Matrix(1, 0, 0, 1, -renderer.bitmap.x, -renderer.bitmap.y));
			}
			if(menuList.renderAIEscapeGraphList.selection == EditorMenuList.ON){
				gfx.clear();
				gfx.lineStyle(2, 0xFFFF00, 0.4);
				graph.drawGraph(graph.escapeNodes, gfx, Game.SCALE, topLeft, bottomRight);
				bitmapData.draw(sprite, new Matrix(1, 0, 0, 1, -renderer.bitmap.x, -renderer.bitmap.y));
			}
			if(menuList.renderAIWallWalkGraphList.selection == EditorMenuList.ON){
				gfx.clear();
				gfx.lineStyle(2, 0xFFFF00, 0.4);
				wallWalkGraph.drawGraph(wallWalkGraph.nodes, gfx, Game.SCALE, topLeft, bottomRight);
				bitmapData.draw(sprite, new Matrix(1, 0, 0, 1, -renderer.bitmap.x, -renderer.bitmap.y));
			}
			if(menuList.renderAIWallWalkEscapeGraphList.selection == EditorMenuList.ON){
				gfx.clear();
				gfx.lineStyle(2, 0xFFFF00, 0.4);
				wallWalkGraph.drawGraph(wallWalkGraph.escapeNodes, gfx, Game.SCALE, topLeft, bottomRight);
				bitmapData.draw(sprite, new Matrix(1, 0, 0, 1, -renderer.bitmap.x, -renderer.bitmap.y));
			}
			if(menuList.renderSurfacesList.selection == EditorMenuList.ON){
				gfx.clear();
				gfx.lineStyle(2, 0x00FF00, 0.4);
				Surface.draw(gfx, Game.SCALE, topLeft, bottomRight);
				bitmapData.draw(sprite, new Matrix(1, 0, 0, 1, -renderer.bitmap.x, -renderer.bitmap.y));
			}
			if(menuList.renderAIPathsList.selection == EditorMenuList.ON){
				gfx.clear();
				rect.width = rect.height = 5;
				for(i = 0; i < Brain.monsterCharacters.length; i++){
					character = Brain.monsterCharacters[i];
					rect.x = -renderer.bitmap.x + character.mapX * Game.SCALE;
					rect.y = -renderer.bitmap.y + character.mapY * Game.SCALE;
					bitmapData.fillRect(rect, 0xCCFF00FF);
					if(character.brain.target && character.collider){
						gfx.lineStyle(2, 0x00FFFF, 0.5);
						gfx.drawCircle(
							(character.brain.target.mapX + 0.5) * Game.SCALE,
							(character.brain.target.mapY + 0.5) * Game.SCALE,
						Game.SCALE * 0.3);
						gfx.moveTo(
							character.collider.x + character.collider.width * 0.5,
							character.collider.y + character.collider.height * 0.5
						);
						gfx.lineTo(
							(character.brain.target.mapX + 0.5) * Game.SCALE,
							(character.brain.target.mapY + 0.5) * Game.SCALE
						);
					}
					if(character.brain.state != Brain.PATROL && character.brain.state != Brain.PAUSE){
						gfx.lineStyle(2, 0xFF0000, 0.5);
						if(character.brain.path) graph.drawPath(character.brain.path, gfx, Game.SCALE);
						if(character.brain.altNode) gfx.drawCircle(
							(character.brain.altNode.x + 0.5) * Game.SCALE,
							(character.brain.altNode.y + 0.5) * Game.SCALE,
						Game.SCALE * 0.2);
					} else {
						if(character.brain.patrolState){
							gfx.lineStyle(2, 0x0000FF, 0.5);
							gfx.drawCircle(character.brain.patrolMinX, (character.mapY + 0.5) * Game.SCALE, Game.SCALE * 0.2);
							gfx.drawCircle(character.brain.patrolMaxX, (character.mapY + 0.5) * Game.SCALE, Game.SCALE * 0.2);
							gfx.moveTo(character.brain.patrolMinX, (character.mapY + 0.5) * Game.SCALE);
							gfx.lineTo(character.brain.patrolMaxX, (character.mapY + 0.5) * Game.SCALE);
						}
					}
				}
				for(i = 0; i < Brain.playerCharacters.length; i++){
					character = Brain.playerCharacters[i];
					rect.x = -renderer.bitmap.x + character.mapX * Game.SCALE;
					rect.y = -renderer.bitmap.y + character.mapY * Game.SCALE;
					bitmapData.fillRect(rect, 0xCCFF00FF);
					if(character.brain.target && character.collider){
						gfx.lineStyle(2, 0x00FFFF, 0.5);
						gfx.drawCircle(
							(character.brain.target.mapX + 0.5) * Game.SCALE,
							(character.brain.target.mapY + 0.5) * Game.SCALE,
						Game.SCALE * 0.3);
						gfx.moveTo(
							character.collider.x + character.collider.width * 0.5,
							character.collider.y + character.collider.height * 0.5
						);
						gfx.lineTo(
							(character.brain.target.mapX + 0.5) * Game.SCALE,
							(character.brain.target.mapY + 0.5) * Game.SCALE
						);
					}
					gfx.lineStyle(2, 0xFF0000, 0.5);
					if(character.brain.path) graph.drawPath(character.brain.path, gfx, Game.SCALE);
					if(character.brain.altNode) gfx.drawCircle(
						(character.brain.altNode.x + 0.5) * Game.SCALE,
						(character.brain.altNode.y + 0.5) * Game.SCALE,
					Game.SCALE * 0.2);
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
			point.x += highlight.rect.width + 1;
			textBox.text = mapX + "," + mapY;
			bitmapData.copyPixels(textBox.bitmapData, textBox.bitmapData.rect, point, null, null, true);
		}
		
	}

}