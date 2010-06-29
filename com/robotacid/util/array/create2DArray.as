package com.robotacid.util.array {
		
	public function create2DArray(width:int, height:int, base:* = null) {
		var r:int, c:int, a:Array = [];
		for(r = 0; r < height; r++){
			a[r] = [];
			for(c = 0; c < width; c++){
				a[r][c] = base;
			}
		}
		return a;
	}

}