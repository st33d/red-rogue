package com.robotacid.util.lerp {
	
	/* Interpolate between two values using the value "t" as a multiplier (t is between 0 and 1) */
	public function lerp(a:Number, b:Number, t:Number):Number{
		return a + (b-a) * t;
	}

}