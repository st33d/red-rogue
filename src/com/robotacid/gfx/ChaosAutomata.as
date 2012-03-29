package com.robotacid.gfx {
	import com.robotacid.level.Map;
	import com.robotacid.phys.Collider;
	import flash.display.BitmapData;
	/**
	 * Old School RobotAcid
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class ChaosAutomata {
		
		public static var pixels:Vector.<uint>;
		public static var n:int;
		
		private var x:int;
		private var y:int;
		private var dir:int;
		private var turns:int;
		private var light:Boolean;
		
		public static const UP:int = Collider.UP;
		public static const RIGHT:int = Collider.RIGHT;
		public static const DOWN:int = Collider.DOWN;
		public static const LEFT:int = Collider.LEFT;
		public static const WIDTH:int = Game.SCALE * Map.BACKGROUND_WIDTH;
		public static const HEIGHT:int = Game.SCALE * Map.BACKGROUND_HEIGHT;
		
		public static const DARKEST:uint = 0xFF9B9B9B;
		public static const LIGHTEST:uint = 0xFFC2C2C2;
		public static const STEP:uint = 0x0F0F0F;
		
		public function ChaosAutomata(light:Boolean) {
			x = Math.random() * WIDTH;
			y = Math.random() * HEIGHT;
			this.light = light;
			dir = 1 << ((Math.random() * 4) >> 0);
		}
		
		public function main():void{
			if(dir == UP){
				y--;
				if(y < 0) y = HEIGHT - 1;
				n = x + y * WIDTH;
				if(light && pixels[n] < LIGHTEST) pixels[n] += STEP;
				else if(pixels[n] > DARKEST) pixels[n] -= STEP;
				else{
					y++;
					if(y > HEIGHT - 1) y = 0;
					dir = RIGHT;
					turns++;
				}
				
			} else if(dir == RIGHT){
				x++;
				if(x > WIDTH - 1) x = 0;
				n = x + y * WIDTH;
				if(light && pixels[n] < LIGHTEST) pixels[n] += STEP;
				else if(pixels[n] > DARKEST) pixels[n] -= STEP;
				else {
					x--;
					if(x < 0) x = WIDTH - 1;
					dir = DOWN;
					turns++;
				}
				
			} else if(dir == DOWN){
				y++;
				if(y > HEIGHT - 1) y = 0;
				n = x + y * WIDTH;
				if(light && pixels[n] < LIGHTEST) pixels[n] += STEP;
				else if(pixels[n] > DARKEST) pixels[n] -= STEP;
				else {
					y--;
					if(y < 0) y = HEIGHT - 1;
					dir = LEFT;
					turns++;
				}
				
			} else if(dir == LEFT){
				x--;
				if(x < 0) x = WIDTH - 1;
				n = x + y * WIDTH;
				if(light && pixels[n] < LIGHTEST) pixels[n] += STEP;
				else if(pixels[n] > DARKEST) pixels[n] -= STEP;
				else {
					x++;
					if(x > WIDTH - 1) x = 0;
					dir = UP;
					turns++;
				}
			}
			if(turns > 7){
				x = Math.random() * WIDTH;
				y = Math.random() * HEIGHT;
				turns = 0;
			}
		}
		
	}

}