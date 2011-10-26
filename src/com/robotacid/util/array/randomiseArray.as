package com.robotacid.util.array {
	/* Does just what it says */
	public function randomiseArray(a:Array):void{
		for(var x:*, j:int, i:int = a.length; i; j = Math.random() * i, x = a[--i], a[i] = a[j], a[j] = x){}
	}

}