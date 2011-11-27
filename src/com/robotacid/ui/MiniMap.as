﻿package com.robotacid.ui {
	import com.robotacid.gfx.BlitClip;
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
		
		private var searchRectBorder:Rectangle;
		
		public static const WIDTH:int = 55;
		public static const HEIGHT:int = 41;
		public static const SEARCH_COL:uint = 0xFFFFFFFF;
		
		private static const CX:int = WIDTH * 0.5;
		private static const CY:int = HEIGHT * 0.5;
		
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
			
			searchRectBorder = new Rectangle(0, 0, 1, 1);
			
			features = new Vector.<MinimapFeature>();
			view = new Rectangle(0, 0, WIDTH, HEIGHT);
		}
		
		public function addFeature(x:Number, y:Number, blit:BlitClip, searchReveal:Boolean = false):MinimapFeature{
			var feature:MinimapFeature = new MinimapFeature(x, y, blit, searchReveal);
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
			window.bitmapData.fillRect(window.bitmapData.rect, 0x66666666);
			window.bitmapData.copyPixels(bitmapData, view, point, null, null, true);
			
			// illustrate the search area as a hollow square
			if(g.player.searchRadius > -1){
				drawSearchRadius(g.player.searchRadius);
			}
			
			for(i = features.length - 1; i > -1; i--) {
				feature = features[i];
				if(feature.active) {
					if(
						feature.x + feature.blit.dx + feature.blit.width >= view.x &&
						feature.y + feature.blit.dy + feature.blit.height >= view.y &&
						feature.x + feature.blit.dx <= view.x + view.width &&
						feature.y + feature.blit.dy <= view.y + view.height
					)
					feature.render();
				}
				else features.splice(i, 1);
			}
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