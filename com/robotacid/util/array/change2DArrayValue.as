package com.robotacid.util.array {
	
	public function change2DArrayValue(old_value:*, new_value:*, a:Array) {
		var r:int, c:int;
		for(r = 0; r < a.length; r++){
			for(c = 0; c < a[r].length; c++){
				if(a[r][c] == old_value) a[r][c] = new_value;
			}
		}
	}

}