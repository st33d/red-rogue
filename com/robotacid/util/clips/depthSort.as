package com.robotacid.util.clips {
	
	/* Depth sort all items in "clip" */
	public function depthSort(clip:DisplayObjectContainer, sort_on:String = "y"):void{
		var depthArray:Array = new Array();
		for(var i:int = 0; i < clip.numChildren; i++){
			depthArray.push(clip.getChildAt(i));
		}
		depthArray.sortOn(sort_on, Array.NUMERIC);
		i = depthArray.length;
		while(i--){
			if (clip.getChildIndex(depthArray[i]) != i) {
				clip.setChildIndex(depthArray[i], i);
			}
		}
	}

}