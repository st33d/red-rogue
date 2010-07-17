package com.robotacid.util {
	import com.robotacid.geom.Pixel;
	import flash.display.BitmapData;
	
	/**
	 * Bresenham ray casting algorithm. Returns a vector to resolve a collision with pixels.
	 * 
	 * @author Aaron Steed
	 */
	public class Bresenham {
		
		/* Strict mode walks the entire length of the line before returning a result */
		public static var strict:Boolean = true;
		
		private static var xd:int, yd:int;
		private static var i:int, x:int, y:int;
		private static var octant:int;
		private static var n:int;
		private static var error:int;
		private static var escape:Boolean;
		private static var tempx:int, tempy:int;
		private static var free:Boolean = false;
		
		/* Walks a line from x1,y1 to x2,y2. Any value that shows up through the mask results in the algorithm returning an escape vector
		 * that would place the would be pixel line walker outside of the pixel wall it encountered. The important question to ask
		 * is what mask to use. We want a mask that returns 0 for any pixel we consider empty, and non zero otherwise.
		 * 
		 * @param p the escape vector object that is passed in to the algorithm to save on object creation
		 * @param x1 start x position
		 * @param y1 start y position
		 * @param x2 end x position
		 * @param y2 end y position
		 * @param data the BitmapData object being tested
		 * @param mask a mask that each pixel tested is filtered through. The default mask tests for any non transparent pixel.
		 */
		public static function rayCast(x1:int, y1:int, x2:int, y2:int, data:BitmapData, col:uint):Boolean{
			xd = x2 - x1;
			yd = y2 - y1;
			octant = -1;
			// The first iteration of this algorithm had trouble with the masking operation being tested without dropping the
			// masked pixel into an int. Flash can be a cunt a times so I'm playing safe again
			n = 0;
			// establish octant:
			// imagine an eight spoke wheel, each area between the spokes requires different rules to scan
			// so counting round from below the east spoke clockwise we see what area or octant we are in
			if (x2 > x1 && y2 > y1 && (yd < 0 ? -yd : yd) < (xd < 0 ? -xd : xd)) octant = 0;
			else if (x2 > x1 && y2 > y1 && (yd < 0 ? -yd : yd) > (xd < 0 ? -xd : xd)) octant = 1;
			else if (x2 < x1 && y2 > y1 && (yd < 0 ? -yd : yd) > (xd < 0 ? -xd : xd)) octant = 2;
			else if (x2 < x1 && y2 > y1 && (yd < 0 ? -yd : yd) < (xd < 0 ? -xd : xd)) octant = 3;
			else if (x2 < x1 && y2 < y1 && (yd < 0 ? -yd : yd) < (xd < 0 ? -xd : xd)) octant = 4; // reversal of octant 0
			else if (x2 < x1 && y2 < y1 && (yd < 0 ? -yd : yd) > (xd < 0 ? -xd : xd)) octant = 5; // reversal of octant 1
			else if (x2 > x1 && y2 < y1 && (yd < 0 ? -yd : yd) > (xd < 0 ? -xd : xd)) octant = 6; // reversal of octant 2
			else if (x2 > x1 && y2 < y1 && (yd < 0 ? -yd : yd) < (xd < 0 ? -xd : xd)) octant = 7; // reversal of octant 3
			// bresenham works climbing a gradient inaccurately, this inaccuracy is rectified by the error
			// variable - the payoff being that we stick to integers and get a whopping speed increase
			error = 0;
			escape = false;
			//flip co-ords of octants above 3
			if (octant > 3){
				// because we have to calculate it backwards - we're looking for the exit point from the pixels
				escape = true;
				free = false;
				tempx = x1;
				tempy = y1;
				x1 = x2;
				y1 = y2;
				x2 = tempx;
				y2 = tempy;
				xd = x2 - x1;
				yd = y2 - y1;
			}
			x = x1;
			y = y1;
			if(octant == 4 || octant == 0){
				y = y1;
				for (x = x1; x <= x2; x++){
					if(data.getPixel32(x, y) == col) return true;
					if((error + yd) << 1 < xd){
						error += yd;
					} else {
						y++;
						error += yd - xd;
					}
				}
			} else if(octant == 5 || octant == 1){
				x = x1;
				for (y = y1; y <= y2; y++){
					if(data.getPixel32(x, y) == col) return true;
					if((error + xd) << 1 < yd){
						error += xd;
					} else {
						x++;
						error += xd - yd;
					}
				}
			} else if(octant == 6 || octant == 2){
				x = x1;
				xd = (xd < 0 ? -xd : xd);
				for (y = y1; y <= y2; y++){
					// flip reading point - algorithm doesn't work backwards
					if(data.getPixel32(x1 - (x - x1), y) == col) return true;
					if((error + xd) << 1 < yd){
						error += xd;
					} else {
					x++;
						error += xd - yd;
					}
				}
			} else if(octant == 7 || octant == 3){
				y = y1;
				yd = (yd < 0 ? -yd : yd);
				xd = (xd < 0 ? -xd : xd);
				for (x = x2; x <= x1; x++){
					// flip reading point - algorithm doesn't work backwards
					if(data.getPixel32(x, y1 - (y - y2)) == col) return true;
					if((error + yd) << 1 < xd){
						error += yd;
					} else {
						y++;
						error += yd - xd;
					}
				}
			} else {
				//line must be on division of octants
				// horizontal
				if (y1 == y2){
					y = y1;
					if (x1 > x2){
						escape = true;
						tempx = x1;
						x1 = x2;
						x2 = tempx;
					}
					for(x = x1; x <= x2; x++){
					if(data.getPixel32(x, y) == col) return true;
					}
				}
				// vertical
				if (x1 == x2){
					x = x1;
					if (y1 > y2){
						escape = true;
						tempy = y1;
						y1 = y2;
						y2 = tempy;
					}
					for(y = y1; y <= y2; y++){
					if(data.getPixel32(x, y) == col) return true;
					}
				}
				// diagonal
				if ((yd < 0 ? -yd : yd) == (xd < 0 ? -xd : xd)){
					x = x1;
					y = y1;
					for(i = 0; i <= (xd < 0 ? -xd : xd); i++){
					if(data.getPixel32(x, y) == col) return true;
						if (x2 > x1){
						  x++;
						} else {
						  x--;
						}
						if (y2 > y1){
						  y++;
						} else {
						  y--;
						}
					}
				}
			}
			return false;
		}
	}
	
}