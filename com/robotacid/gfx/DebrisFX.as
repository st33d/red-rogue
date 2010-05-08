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
		
		public var map_x:int, map_y:int;
		public var dx:Number, dy:Number;
		public var length:Number;
		public var ignore:int;
		public var px:Number;
		public var py:Number;
		public var temp_x:Number;
		public var temp_y:Number;
		public var print:BlitRect;
		public var smear:Boolean;
		
		public static var cast:Cast;
		
		public function DebrisFX(x:Number, y:Number, blit:BlitRect, image:BitmapData, image_holder:Bitmap, g:Game, print:BlitRect = null, smear:Boolean = false) {
			super(x, y, blit, image, image_holder, g);
			this.print = print;
			this.smear = smear;
			map_x = x * Game.INV_SCALE;
			map_y = y * Game.INV_SCALE;
			px = x;
			py = y;
			ignore = Block.CHARACTER | Block.LEDGE | Block.LADDER | Block.HEAD;
		}
	
		override public function main():void{
			// inlined verlet routine
			temp_x = x;
			temp_y = y;
			x += (x-px)*0.95;
			y += (y-py)+1.0;
			px = temp_x;
			py = temp_y;
			map_x = x * Game.INV_SCALE;
			map_y = y * Game.INV_SCALE;
			// react to scenery
			// off scroller?
			if(!g.renderer.contains(x, y)){
				active = false;
				return;
			}
			// block collision
			if(g.block_map[map_y][map_x] > Block.EMPTY && !(g.block_map[map_y][map_x] & ignore)){
				// resolve and kill
				getVector();
				cast = Cast.ray(px, py, dx, dy, g.block_map, ignore, g);
				x = px + cast.distance * dx;
				y = py + cast.distance * dy;
				// for oriented hit FX
				//if(cast.side == Cast.UP){
					//y += blit.dy;
				//} else if(cast.side == Cast.RIGHT){
					//x -= blit.dx;
				//} else if(cast.side == Cast.DOWN){
					//y -= blit.dy;
				//} else if(cast.side == Cast.LEFT){
					//x += blit.dx;
				//}
				//var side:int = cast.block.sideOf(x, y);
				if(print) printFade();
				if(!smear || cast.side == Rect.UP || cast.side == 0) kill();
			}
			// collider collision
			for (var i:int = 0; i < g.colliders.length; i++){
				if (g.colliders[i].contains(x, y) && !(g.colliders[i].block.type & ignore)){
					// resolve and kill
					getVector();
					cast = Cast.ray(px, py, dx, dy, g.block_map, ignore, g);
					x = px + cast.distance * dx;
					y = py + cast.distance * dy;
					// for oriented hit FX
					//var side:int = cast.block.sideOf(x, y);
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
			g.addFX(x, y, print, g.back_fx_image, g.back_fx_image_holder);
			//blit.x = x;
			//blit.y = y;
			//blit.multiRender(g.debris_map);
			//g.blood_small_bs.x = x;
			//g.blood_small_bs.y = y;
			//g.blood_small_bs.multiRender(g.debris_map);
		}
		
		public function addVelocity(x:Number, y:Number):void{
			px -= x;
			py -= y;
		}
		
		
	}
	
}