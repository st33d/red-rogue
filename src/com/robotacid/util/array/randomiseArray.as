package com.robotacid.util.array {
	import com.robotacid.util.Rng;
	/* Does just what it says */
	public function randomiseArray(a:Array, random:Rng):void{
		for(var x:*, j:int, i:int = a.length; i; j = random.rangeInt(i), x = a[--i], a[i] = a[j], a[j] = x){}
	}

}