package com.robotacid.gfx {
	import com.robotacid.phys.Cast;
	import com.robotacid.phys.Collider;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	
	/**
	* An FX object that falls off screen
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class DebrisFX extends FX{
		
		public var mapX:int, mapY:int;
		public var dx:Number, dy:Number;
		public var px:Number;
		public var py:Number;
		public var print:BlitRect;
		public var smear:Boolean;
		public var map:Boolean;
		
		// temp vars
		private static var tempX:Number;
		private static var tempY:Number;
		private static var cast:Cast;
		
		public static var IGNORE_PROPERTIES:int;// this is set in Game to Collider.CHARACTER | Collider.LEDGE | Collider.LADDER | Collider.HEAD | Collider.CORPSE
		// you can't set a constant using math with other constants
		
		public function DebrisFX(x:Number, y:Number, blit:BlitRect, bitmapData:BitmapData, bitmap:DisplayObject, print:BlitRect = null, smear:Boolean = false, map:Boolean = true) {
			super(x, y, blit, bitmapData, bitmap);
			this.print = print;
			this.smear = smear;
			this.map = map;
			looped = true;
			mapX = x * Game.INV_SCALE;
			mapY = y * Game.INV_SCALE;
			px = x;
			py = y;
		}
		
		override public function main():void{
			// inlined verlet routine
			tempX = x;
			tempY = y;
			x += (x-px)*0.95;
			y += (y-py)+1.0;
			px = tempX;
			py = tempY;
			
			if(map){
				mapX = x * Game.INV_SCALE;
				mapY = y * Game.INV_SCALE;
				// react to scenery
				// off scroller?
				if(!game.mapTileManager.contains(x, y)){
					active = false;
					return;
				}
				// block collision
				if(game.world.map[mapY][mapX] > Collider.EMPTY && !(game.world.map[mapY][mapX] & IGNORE_PROPERTIES)){
					// resolve and kill
					getVector();
					cast = Cast.ray(px, py, dx, dy, game.world, IGNORE_PROPERTIES);
					if(cast){
						x = px + cast.distance * dx;
						y = py + cast.distance * dy;
						if(print) printFade();
						if(!smear || cast.surface == Collider.UP || cast.surface == 0) kill();
						
					} else {
						kill();
					}
				}
			}
			// render
			super.main();
		}
		/* Calculate the normalised vector this particle is travelling on */
		public function getVector():void{
			var length:Number = Math.sqrt((x - px) * (x - px) + (y - py) * (y - py));
			if(length > 0){
				dx = (x - px) / length;
				dy = (y - py) / length;
			} else {
				dx = dy = 0;
			}
		}
		public function kill():void{
			if(!active) return;
			active = false;
		}
		public function printFade():void{
			renderer.addFX(x, y, print, null, 0, true);
		}
		
		public function addVelocity(x:Number, y:Number):void{
			px -= x;
			py -= y;
		}
		
		
	}
	
}