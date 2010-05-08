package com.robotacid.util.lerp {
	
	/* interpolate between two angles in degrees using the value "t" as a multiplier (t is between 0 and 1) */
	public function degreeLerp(a:Number, b:Number, t:Number):Number{
		a += (Math.abs(b-a) > 180) ? ((a < b) ? (360) : -(360)) : 0;
		return a + (b-a) * t;
	}

}