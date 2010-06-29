package com.robotacid.ui {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author steed
	 */
	public class MiniMap extends Sprite{
		
		public var g:Game;
		public var mapHolder:Sprite;
		public var map:Bitmap;
		public var data:BitmapData;
		public var player:Bitmap;
		public var stairsUp:Bitmap;
		public var stairsDown:Bitmap;
		
		public static const WIDTH:int = 41;
		public static const HEIGHT:int = 41;
		
		public function MiniMap(blockMap:Vector.<Vector.<int>>, g:Game):void{
			this.g = g;
			
			mapHolder = new Sprite();
			addChild(mapHolder);
			
			data = new BitmapData(blockMap[0].length, blockMap.length, true, 0x00000000);
			map = new Bitmap(data);
			mapHolder.addChild(map);
			
			var stairsUpData:BitmapData = new BitmapData(3, 3, true, 0x00000000);
			stairsUpData.setPixel32(1, 0, 0xFFFFFFFF);
			stairsUpData.fillRect(new Rectangle(0, 1, 3, 1), 0xFFFFFFFF);
			stairsUp = new Bitmap(stairsUpData);
			stairsUp.visible = false;
			mapHolder.addChild(stairsUp);
			
			var stairsDownData:BitmapData = new BitmapData(3, 3, true, 0x00000000);
			stairsDownData.setPixel32(1, 2, 0xFFFFFFFF);
			stairsDownData.fillRect(new Rectangle(0, 1, 3, 1), 0xFFFFFFFF);
			stairsDown = new Bitmap(stairsDownData);
			stairsDown.visible = false;
			mapHolder.addChild(stairsDown);
			
			var playerData:BitmapData = new BitmapData(3, 3, true, 0xFFFFFFFF);
			playerData.setPixel32(1, 1, 0x00000000);
			player = new Bitmap(playerData);
			addChild(player);
			
			var shape:Shape = new Shape();
			shape.graphics.beginFill(0xFFFFFF);
			shape.graphics.drawRect( -20, -20, 41, 41);
			shape.graphics.endFill();
			addChild(shape);
			mapHolder.cacheAsBitmap = true;
			shape.cacheAsBitmap = true;
			mapHolder.mask = shape;
			
			var borderdata:BitmapData = new BitmapData(WIDTH, HEIGHT, true, 0xFF999999);
			borderdata.fillRect(new Rectangle(1, 1, WIDTH - 2, HEIGHT - 2), 0x00000000);
			var border:Bitmap = new Bitmap(borderdata);
			border.x = border.y = -20;
			addChild(border);
			
		}
		public function newMap(blockMap:Vector.<Vector.<int>>):void{
			data = new BitmapData(blockMap[0].length, blockMap.length, true, 0x00000000);
			map.bitmapData = data;
			stairsUp.visible = false;
			stairsDown.visible = false;
		}
		public function update():void{
			mapHolder.x = -g.player.mapX+1;
			mapHolder.y = -g.player.mapY+1;
		}
		
	}
	
}