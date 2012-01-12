package com.robotacid.ui {
	import com.robotacid.gfx.BlitClip;
	import com.robotacid.gfx.FX;
	import com.robotacid.gfx.Renderer;
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
		
		public var game:Game;
		public var renderer:Renderer;
		
		public var view:Rectangle;
		public var window:Bitmap;
		public var bitmapData:BitmapData;
		public var fx:Vector.<MinimapFX>;
		
		private var searchRectBorder:Rectangle;
		private var playerBitmapData:BitmapData;
		
		public static const WIDTH:int = 55;
		public static const HEIGHT:int = 41;
		public static const SEARCH_COL:uint = 0xFFFFFFFF;
		
		private static const CX:int = WIDTH * 0.5;
		private static const CY:int = HEIGHT * 0.5;
		
		private static var point:Point = new Point();
		private static var i:int;
		private static var fxItem:MinimapFX;
		
		public function MiniMap(blockMap:Vector.<Vector.<int>>, game:Game, renderer:Renderer):void{
			this.game = game;
			this.renderer = renderer;
			
			bitmapData = new BitmapData(blockMap[0].length, blockMap.length, true, 0x00000000);
			window = new Bitmap(new BitmapData(WIDTH, HEIGHT, true, 0x00000000));
			addChild(window);
			
			playerBitmapData = new BitmapData(3, 3, true, 0xFFFFFFFF);
			playerBitmapData.setPixel32(1, 1, 0x00000000);
			var playerBitmap:Bitmap = new Bitmap(playerBitmapData);
			playerBitmap.x = -1 + (WIDTH * 0.5) >> 0;
			playerBitmap.y = -1 + (HEIGHT * 0.5) >> 0;
			addChild(playerBitmap);
			
			var borderdata:BitmapData = new BitmapData(WIDTH, HEIGHT, true, 0xFF999999);
			borderdata.fillRect(new Rectangle(1, 1, WIDTH - 2, HEIGHT - 2), 0x00000000);
			var border:Bitmap = new Bitmap(borderdata);
			addChild(border);
			
			searchRectBorder = new Rectangle(0, 0, 1, 1);
			
			fx = new Vector.<MinimapFX>();
			view = new Rectangle(0, 0, WIDTH, HEIGHT);
		}
		
		/* Adds an animation to depict a given item on the minimap, searchReveal adds a visual "ping" to emphasise the discovery */
		public function addFeature(x:Number, y:Number, blit:BlitClip, searchReveal:Boolean = false):MinimapFX{
			var feature:MinimapFX = addFX(x, y, blit, null, 0, true);
			if(searchReveal) addFX(x, y, renderer.featureRevealedBlit);
			return feature;
		}
		
		public function addFX(x:Number, y:Number, blit:BlitClip, dir:Point = null, delay:int = 0, looped:Boolean = false):MinimapFX{
			var fxItem:MinimapFX = new MinimapFX(x, y, blit, window.bitmapData, view, dir, delay, looped);
			fx.push(fxItem);
			return fxItem;
		}
		
		public function newMap(blockMap:Vector.<Vector.<int>>):void{
			bitmapData = new BitmapData(blockMap[0].length, blockMap.length, true, 0x00000000);
			fx.length = 0;
		}
		
		public function render():void {
			view.x = game.player.mapX - ((WIDTH * 0.5) >> 0);
			view.y = game.player.mapY - ((HEIGHT * 0.5) >> 0);
			window.bitmapData.fillRect(window.bitmapData.rect, 0x66666666);
			window.bitmapData.copyPixels(bitmapData, view, point, null, null, true);
			
			// illustrate the search area as a hollow square
			if(game.player.searchRadius > -1){
				drawSearchRadius(game.player.searchRadius);
			}
			
			for(i = fx.length - 1; i > -1; i--) {
				fxItem = fx[i];
				if(fxItem.active) fxItem.main();
				else fx.splice(i, 1);
			}
		}
		
		/* Renders the minimap to a given image */
		public function renderTo(target:BitmapData):void{
			var point:Point = new Point();
			point.x = -game.player.mapX + ((target.width * 0.5) >> 0);
			point.y = -game.player.mapY + ((target.height * 0.5) >> 0);
			target.copyPixels(bitmapData, bitmapData.rect, point, null, null, true);
			
			var temp:Rectangle;
			var view:Rectangle = new Rectangle(-point.x, -point.y, target.width, target.height);
			for(i = fx.length - 1; i > -1; i--) {
				fxItem = fx[i];
				if(fxItem.active){
					// hijack the view in the MinimapFX item
					temp = fxItem.view;
					fxItem.view = view;
					fxItem.bitmapData = target;
					fxItem.main();
					fxItem.view = temp;
					fxItem.bitmapData = window.bitmapData;
				}
				else fx.splice(i, 1);
			}
			point.x = -1 + ((target.width * 0.5) >> 0);
			point.y = -1 + ((target.height * 0.5) >> 0);
			target.copyPixels(playerBitmapData, playerBitmapData.rect, point, null, null, true);
		}
		
		/* Draw a square describing the current extent of the search */
		private function drawSearchRadius(radius:int):void{
			searchRectBorder.x = CX - radius;
			searchRectBorder.y = CY - radius;
			searchRectBorder.width = 1 + radius * 2;
			searchRectBorder.height = 1;
			window.bitmapData.fillRect(searchRectBorder, SEARCH_COL);
			searchRectBorder.y += radius * 2;
			window.bitmapData.fillRect(searchRectBorder, SEARCH_COL);
			searchRectBorder.y = CY - radius;
			searchRectBorder.width = 1;
			searchRectBorder.height = 1 + radius * 2;
			window.bitmapData.fillRect(searchRectBorder, SEARCH_COL);
			searchRectBorder.x += radius * 2;
			window.bitmapData.fillRect(searchRectBorder, SEARCH_COL);
		}
		
	}
	
}