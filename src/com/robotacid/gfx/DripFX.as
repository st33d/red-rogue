package com.robotacid.gfx {
	import com.robotacid.phys.Cast;
	import com.robotacid.phys.Collider;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * An FX that drips down colliders and walls
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class DripFX extends FX {
		
		public var rect:Rectangle;
		public var print:BlitRect;
		public var mapX:int;
		public var mapY:int;
		
		private var surface:Boolean;
		private var offsetX:Number;
		private var offsetY:Number;
		private var py:Number;
		private var count:int;
		private var slideDir:int;
		private var speed:Number;
		
		private static var tempY:Number;
		private static var cast:Cast;
		
		public static var IGNORE_PROPERTIES:int;// this is set in Game to Collider.CHARACTER | Collider.LEDGE | Collider.LADDER | Collider.HEAD | Collider.CORPSE
		// you can't set a constant using math with other constants
		public static const DELAY:int = 30;
		
		public function DripFX(x:Number, y:Number, blit:BlitRect, bitmapData:BitmapData, bitmap:DisplayObject, print:BlitRect, rect:Rectangle = null) {
			super(x, y, blit, bitmapData, bitmap, null, 0, true);
			this.rect = rect;
			this.print = print;
			count = DELAY + game.random.range(DELAY);
			speed = 0.05 + game.random.value();
			if(rect){
				offsetX = x - rect.x;
				offsetY = y - rect.y;
				surface = true;
			} else {
				surface = false;
				py = y;
			}
		}
	
		override public function main():void{
			
			if(surface){
				// drip down rect
				if(rect){
					offsetY += speed;
					x = rect.x + offsetX;
					y = rect.y + offsetY;
					if(offsetY > rect.height - 1){
						surface = false;
						y = py = rect.y + rect.height - 1;
						rect = null;
					}
				
				// slide along map surfaces
				} else {
					x += speed * slideDir;
					mapX = x * Game.INV_SCALE;
					mapY = y * Game.INV_SCALE;
					if(game.world.map[mapY][mapX] & (Collider.LEFT | Collider.RIGHT)){
						x -= speed * slideDir;
						slideDir = -slideDir;
					} else {
						if(!(game.world.map[mapY + 1][mapX] & Collider.UP)){
							surface = false;
							py = y;
						}
					}
				}
				if(count) count--;
				else {
					active = false;
					printFade();
				}
			
			// if there is no surface to drip down, behave like a simplified DebrisFX
			} else {
				// inlined verlet routine
				tempY = y;
				y += (y-py)+1.0;
				py = tempY;
				
				mapX = x * Game.INV_SCALE;
				mapY = y * Game.INV_SCALE;
				// react to scenery
				// off scroller?
				if(!game.mapTileManager.contains(x, y)){
					active = false;
					return;
				}
				// block collision
				if(!(game.world.map[mapY][mapX] & IGNORE_PROPERTIES)){
					// resolve and set to a map surface
					cast = Cast.vert(x, y, 1, 1 + ((y - py) * Game.INV_SCALE), IGNORE_PROPERTIES, game.world);
					if(cast && cast.collider){
						y = cast.collider.y - 1;
						surface = true;
						slideDir = game.random.coinFlip() ? -1 : 1;
					}
				}
			}
			// render
			super.main();
		}
		
		public function printFade():void{
			renderer.addFX(x, y, print, null, 0, true);
		}
		
	}

}