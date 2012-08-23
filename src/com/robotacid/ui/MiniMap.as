package com.robotacid.ui {
	import com.robotacid.engine.MapTileManager;
	import com.robotacid.engine.Portal;
	import com.robotacid.gfx.BlitClip;
	import com.robotacid.gfx.FX;
	import com.robotacid.gfx.LightMap;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.phys.Collider;
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
		public var flashPrompt:Shape;
		public var bitmapData:BitmapData;
		public var fx:Vector.<MinimapFX>;
		
		private var searchRectBorder:Rectangle;
		private var playerBitmapData:BitmapData;
		
		public static const WIDTH:int = 55;
		public static const HEIGHT:int = 41;
		public static const SEARCH_COL:uint = 0xFFFFFFFF;
		public static const FLASH_PROMPT_STEP:Number = 0.15;
		
		private static const CX:int = WIDTH * 0.5;
		private static const CY:int = HEIGHT * 0.5;
		
		private static var point:Point = new Point();
		private static var i:int;
		private static var fxItem:MinimapFX;
		
		public function MiniMap(blockMap:Vector.<Vector.<int>>, game:Game, renderer:Renderer):void{
			this.game = game;
			this.renderer = renderer;
			
			bitmapData = new BitmapData(blockMap[0].length, blockMap.length, true, 0x0);
			window = new Bitmap(new BitmapData(WIDTH, HEIGHT, true, 0x0));
			addChild(window);
			
			flashPrompt = new Shape();
			flashPrompt.graphics.beginFill(0xFFFFFF);
			flashPrompt.graphics.drawRect(0, 0, WIDTH, HEIGHT);
			flashPrompt.graphics.endFill();
			flashPrompt.visible = false;
			addChild(flashPrompt);
			
			playerBitmapData = new BitmapData(3, 3, true, 0xFFFFFFFF);
			playerBitmapData.setPixel32(1, 1, 0x0);
			var playerBitmap:Bitmap = new Bitmap(playerBitmapData);
			playerBitmap.x = -1 + (WIDTH * 0.5) >> 0;
			playerBitmap.y = -1 + (HEIGHT * 0.5) >> 0;
			addChild(playerBitmap);
			
			var borderdata:BitmapData = new BitmapData(WIDTH, HEIGHT, true, 0xFF999999);
			borderdata.fillRect(new Rectangle(1, 1, WIDTH - 2, HEIGHT - 2), 0x0);
			var border:Bitmap = new Bitmap(borderdata);
			addChild(border);
			
			searchRectBorder = new Rectangle(0, 0, 1, 1);
			
			fx = new Vector.<MinimapFX>();
			view = new Rectangle(0, 0, WIDTH, HEIGHT);
		}
		
		/* Adds an animation to depict a given item on the minimap, searchReveal adds a visual "ping" to emphasise the discovery */
		public function addFeature(x:Number, y:Number, blit:BlitClip, searchReveal:Boolean = false):MinimapFX{
			var feature:MinimapFX = addFX(x, y, blit, null, 0, true);
			if(searchReveal){
				addFX(x, y, renderer.featureRevealedBlit);
				game.soundQueue.add("ping");
			}
			return feature;
		}
		
		public function addFX(x:Number, y:Number, blit:BlitClip, dir:Point = null, delay:int = 0, looped:Boolean = false):MinimapFX{
			var fxItem:MinimapFX = new MinimapFX(x, y, blit, window.bitmapData, view, dir, delay, looped);
			fx.push(fxItem);
			return fxItem;
		}
		
		public function newMap(blockMap:Vector.<Vector.<int>>):void{
			bitmapData = new BitmapData(blockMap[0].length, blockMap.length, true, 0x0);
			fx.length = 0;
		}
		
		/* Completes the whole map, albeit in a different tone to the rest of the map to show unvisited areas */
		public function reveal():void{
			var r:int, c:int, i:int;
			var blockMap:Vector.<Vector.<int>> = game.lightMap.blockMap;
			var col:uint;
			for(r = 1; r < bitmapData.height - 1; r++){
				for(c = 1; c < bitmapData.width - 1; c++){
					col = bitmapData.getPixel32(c, r);
					if(col == 0x0 && (blockMap[r][c] & Collider.SOLID) != Collider.SOLID){
						bitmapData.setPixel32(c, r, LightMap.MINIMAP_REVEAL_COL);
						// as well as marking empty squares, the surrounding squares must be checked for walls to mark
						if(blockMap[r - 1][c - 1] & LightMap.WALL) bitmapData.setPixel32(c - 1, r - 1, LightMap.MINIMAP_WALL_COL);
						if(blockMap[r - 1][c] & LightMap.WALL) bitmapData.setPixel32(c, r - 1, LightMap.MINIMAP_WALL_COL);
						if(blockMap[r - 1][c + 1] & LightMap.WALL) bitmapData.setPixel32(c + 1, r - 1, LightMap.MINIMAP_WALL_COL);
						if(blockMap[r][c - 1] & LightMap.WALL) bitmapData.setPixel32(c - 1, r, LightMap.MINIMAP_WALL_COL);
						if(blockMap[r][c + 1] & LightMap.WALL) bitmapData.setPixel32(c + 1, r, LightMap.MINIMAP_WALL_COL);
						if(blockMap[r + 1][c - 1] & LightMap.WALL) bitmapData.setPixel32(c - 1, r + 1, LightMap.MINIMAP_WALL_COL);
						if(blockMap[r + 1][c] & LightMap.WALL) bitmapData.setPixel32(c, r + 1, LightMap.MINIMAP_WALL_COL);
						if(blockMap[r + 1][c + 1] & LightMap.WALL) bitmapData.setPixel32(c + 1, r + 1, LightMap.MINIMAP_WALL_COL);
					}
				}
			}
			// reveal exits
			var portal:Portal;
			if(game.map.stairsUp){
				portal = game.mapTileManager.getTile(game.map.stairsUp.x, game.map.stairsUp.y, MapTileManager.ENTITY_LAYER) as Portal;
				if(portal && !portal.seen) portal.reveal();
				else {
					// create a marker for STAIRS to pick up when created
					addFeature(game.map.stairsUp.x, game.map.stairsUp.y, renderer.stairsUpFeatureBlit, true);
				}
			}
			if(game.map.stairsDown){
				portal = game.mapTileManager.getTile(game.map.stairsDown.x, game.map.stairsDown.y, MapTileManager.ENTITY_LAYER) as Portal;
				if(portal && !portal.seen) portal.reveal();
				else {
					// create a marker for STAIRS to pick up when created
					addFeature(game.map.stairsDown.x, game.map.stairsDown.y, renderer.stairsDownFeatureBlit, true);
				}
			}
			for(i = 0; i < game.map.portals.length; i++){
				portal = game.mapTileManager.getTile(game.map.portals[i].x, game.map.portals[i].y, MapTileManager.ENTITY_LAYER) as Portal;
				if(portal && !portal.seen) portal.reveal();
			}
			triggerFlashPrompt();
			if(game.player) render();
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
			
			if(flashPrompt.visible){
				flashPrompt.alpha -= FLASH_PROMPT_STEP;
				if(flashPrompt.alpha <= 0){
					flashPrompt.visible = false;
				}
			}
			
			for(i = fx.length - 1; i > -1; i--) {
				fxItem = fx[i];
				if(fxItem.active) fxItem.main();
				else fx.splice(i, 1);
			}
		}
		
		/* Set the flash prompt visible to draw the player's eye to the minimap */
		public function triggerFlashPrompt():void{
			flashPrompt.visible = true;
			flashPrompt.alpha = 1;
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