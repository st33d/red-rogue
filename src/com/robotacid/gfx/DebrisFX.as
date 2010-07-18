package com.robotacid.gfx {
	import com.robotacid.geom.Dot;
	import com.robotacid.geom.Rect;
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Cast;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	/**
	* An FX object that falls off screen
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class DebrisFX extends FX{
		
		public var mapX:int, mapY:int;
		public var dx:Number, dy:Number;
		public var length:Number;
		public var ignore:int;
		public var px:Number;
		public var py:Number;
		public var tempX:Number;
		public var tempY:Number;
		public var print:BlitRect;
		public var smear:Boolean;
		
		public static var cast:Cast;
		
		public function DebrisFX(x:Number, y:Number, blit:BlitRect, image:BitmapData, imageHolder:Bitmap, g:Game, print:BlitRect = null, smear:Boolean = false) {
			super(x, y, blit, image, imageHolder, g);
			this.print = print;
			this.smear = smear;
			mapX = x * Game.INV_SCALE;
			mapY = y * Game.INV_SCALE;
			px = x;
			py = y;
			ignore = Block.CHARACTER | Block.LEDGE | Block.LADDER | Block.HEAD | Block.CORPSE;
		}
	
		override public function main():void{
			// inlined verlet routine
			tempX = x;
			tempY = y;
			x += (x-px)*0.95;
			y += (y-py)+1.0;
			px = tempX;
			py = tempY;
			mapX = x * Game.INV_SCALE;
			mapY = y * Game.INV_SCALE;
			// react to scenery
			// off scroller?
			if(!g.renderer.contains(x, y)){
				active = false;
				return;
			}
			// block collision
			if(g.blockMap[mapY][mapX] > Block.EMPTY && !(g.blockMap[mapY][mapX] & ignore)){
				// resolve and kill
				getVector();
				cast = Cast.ray(px, py, dx, dy, g.blockMap, ignore, g);
				x = px + cast.distance * dx;
				y = py + cast.distance * dy;
				if(print) printFade();
				if(!smear || cast.side == Rect.UP || cast.side == 0) kill();
			}
			// collider collision
			for (var i:int = 0; i < g.colliders.length; i++){
				if (g.colliders[i].contains(x, y) && !(g.colliders[i].block.type & ignore)){
					// resolve and kill
					getVector();
					cast = Cast.ray(px, py, dx, dy, g.blockMap, ignore, g);
					x = px + cast.distance * dx;
					y = py + cast.distance * dy;
					kill();
				}
			}
			// render
			super.main();
		}
		/* Calculate the normalised vector this particle is travelling on */
		public function getVector():void{
			length = Math.sqrt((x - px) * (x - px) + (y - py) * (y - py));
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
			g.addFX(x, y, print, g.backFxImage, g.backFxImageHolder);
		}
		
		public function addVelocity(x:Number, y:Number):void{
			px -= x;
			py -= y;
		}
		
		
	}
	
}