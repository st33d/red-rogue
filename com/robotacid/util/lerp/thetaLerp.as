package com.robotacid.util.lerp {
	
	/* interpolate between two angles using the value "t" as a multiplier (t is between 0 and 1) */
	public function thetaLerp(a:Number, b:Number, t:Number):Number{
		a += (Math.abs(b-a) > Math.PI) ? ((a < b) ? (Math.PI*2) : -(Math.PI*2)) : 0;
		return a + (b-a) * t;
	}

}