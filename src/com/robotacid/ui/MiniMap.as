package com.robotacid.ui {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Illustrates the area explored by Player and where important features are such as stairs and discovered traps/secrets
	 * 
	 * The bitmapData image is updated by the LightMap object
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class MiniMap extends Sprite{
		
		public var g:Game;
		
		public var view:Rectangle;
		public var window:Bitmap;
		public var bitmapData:BitmapData;
		public var features:Vector.<MinimapFeature>;
		
		public static const WIDTH:int = 55;
		public static const HEIGHT:int = 41;
		
		private static var point:Point = new Point();
		private static var i:int;
		private static var feature:MinimapFeature;
		
		public function MiniMap(blockMap:Vector.<Vector.<int>>, g:Game):void{
			this.g = g;
			
			MinimapFeature.minimap = this;
			
			bitmapData = new BitmapData(blockMap[0].length, blockMap.length, true, 0x00000000);
			window = new Bitmap(new BitmapData(WIDTH, HEIGHT, true, 0x00000000));
			addChild(window);
			
			var playerBitmapData:BitmapData = new BitmapData(3, 3, true, 0xFFFFFFFF);
			playerBitmapData.setPixel32(1, 1, 0x00000000);
			var playerBitmap:Bitmap = new Bitmap(playerBitmapData);
			playerBitmap.x = -1 + (WIDTH * 0.5) >> 0;
			playerBitmap.y = -1 + (HEIGHT * 0.5) >> 0;
			addChild(playerBitmap);
			
			var borderdata:BitmapData = new BitmapData(WIDTH, HEIGHT, true, 0xFF999999);
			borderdata.fillRect(new Rectangle(1, 1, WIDTH - 2, HEIGHT - 2), 0x00000000);
			var border:Bitmap = new Bitmap(borderdata);
			addChild(border);
			
			features = new Vector.<MinimapFeature>();
			view = new Rectangle(0, 0, WIDTH, HEIGHT);
		}
		
		public function addFeature(x:Number, y:Number, dx:Number, dy:Number, bitmapData:BitmapData):MinimapFeature{
			var feature:MinimapFeature = new MinimapFeature(x, y, dx, dy, bitmapData);
			features.push(feature);
			return feature;
		}
		
		public function newMap(blockMap:Vector.<Vector.<int>>):void{
			bitmapData = new BitmapData(blockMap[0].length, blockMap.length, true, 0x00000000);
			features.length = 0;
		}
		public function render():void {
			view.x = g.player.mapX - int(WIDTH * 0.5);
			view.y = g.player.mapY - int(HEIGHT * 0.5);
			window.bitmapData.fillRect(window.bitmapData.rect, 0x66000000);
			window.bitmapData.copyPixels(bitmapData, view, point, null, null, true);
			for(i = features.length - 1; i > -1; i--) {
				feature = features[i];
				if(feature.active) {
					if(
						feature.x + feature.dx + feature.bitmapData.width >= view.x &&
						feature.y + feature.dy + feature.bitmapData.height >= view.y &&
						feature.x + feature.dx <= view.x + view.width &&
						feature.y + feature.dy <= view.y + view.height
					)
					feature.render();
				}
				else features.splice(i, 1);
			}
		}
		
	}
	
}