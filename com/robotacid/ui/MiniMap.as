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
		public var map_holder:Sprite;
		public var map:Bitmap;
		public var data:BitmapData;
		public var player:Bitmap;
		public var stairs_up:Bitmap;
		public var stairs_down:Bitmap;
		
		public static const WIDTH:int = 41;
		public static const HEIGHT:int = 41;
		
		public function MiniMap(block_map:Vector.<Vector.<int>>, g:Game):void{
			this.g = g;
			
			map_holder = new Sprite();
			addChild(map_holder);
			
			data = new BitmapData(block_map[0].length, block_map.length, true, 0x00000000);
			map = new Bitmap(data);
			map_holder.addChild(map);
			
			var stairs_up_data:BitmapData = new BitmapData(3, 3, true, 0x00000000);
			stairs_up_data.setPixel32(1, 0, 0xFFFFFFFF);
			stairs_up_data.fillRect(new Rectangle(0, 1, 3, 1), 0xFFFFFFFF);
			stairs_up = new Bitmap(stairs_up_data);
			stairs_up.visible = false;
			map_holder.addChild(stairs_up);
			
			var stairs_down_data:BitmapData = new BitmapData(3, 3, true, 0x00000000);
			stairs_down_data.setPixel32(1, 2, 0xFFFFFFFF);
			stairs_down_data.fillRect(new Rectangle(0, 1, 3, 1), 0xFFFFFFFF);
			stairs_down = new Bitmap(stairs_down_data);
			stairs_down.visible = false;
			map_holder.addChild(stairs_down);
			
			var player_data:BitmapData = new BitmapData(3, 3, true, 0xFFFFFFFF);
			player_data.setPixel32(1, 1, 0x00000000);
			player = new Bitmap(player_data);
			addChild(player);
			
			var shape:Shape = new Shape();
			shape.graphics.beginFill(0xFFFFFF);
			shape.graphics.drawRect( -20, -20, 41, 41);
			shape.graphics.endFill();
			addChild(shape);
			map_holder.cacheAsBitmap = true;
			shape.cacheAsBitmap = true;
			map_holder.mask = shape;
			
			var borderdata:BitmapData = new BitmapData(WIDTH, HEIGHT, true, 0xFF999999);
			borderdata.fillRect(new Rectangle(1, 1, WIDTH - 2, HEIGHT - 2), 0x00000000);
			var border:Bitmap = new Bitmap(borderdata);
			border.x = border.y = -20;
			addChild(border);
			
		}
		public function newMap(block_map:Vector.<Vector.<int>>):void{
			data = new BitmapData(block_map[0].length, block_map.length, true, 0x00000000);
			map.bitmapData = data;
			stairs_up.visible = false;
			stairs_down.visible = false;
		}
		public function update():void{
			map_holder.x = -g.player.map_x+1;
			map_holder.y = -g.player.map_y+1;
		}
		
	}
	
}