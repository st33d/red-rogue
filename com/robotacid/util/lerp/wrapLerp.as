package com.robotacid.util.lerp {
	
	/* Interpolate between two values using the value "t" as a multiplier (t is between 0 and 1) - implementing a wraparound */
	public function wrapLerp(a:Number, b:Number, t:Number, minX:Number, maxX:Number):Number{
		var w:Number = Math.abs(minX-maxX);
		a += (Math.abs(b-a) > w*0.5) ? ((a < b) ? w : -w) : 0;
		return lerp(a, b, t);
	}

}