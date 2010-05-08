package com.robotacid.util.clips {
	
	/* Depth sort all items in "clip" */
	public function depthSort(clip:DisplayObjectContainer, sort_on:String = "y"):void{
		var depth_array:Array = new Array();
		for(var i:int = 0; i < clip.numChildren; i++){
			depth_array.push(clip.getChildAt(i));
		}
		depth_array.sortOn(sort_on, Array.NUMERIC);
		i = depth_array.length;
		while(i--){
			if (clip.getChildIndex(depth_array[i]) != i) {
				clip.setChildIndex(depth_array[i], i);
			}
		}
	}

}