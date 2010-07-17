package com.robotacid.util.clips {
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	/* Pause hack - freezes mc and all of its children */
	public function countClips(mc:DisplayObjectContainer, counter:Object):void{
		counter.n += mc.numChildren;
		for(var i:int = 0; i < mc.numChildren; i++){
			if(mc.getChildAt(i) is DisplayObjectContainer){
				countClips(mc.getChildAt(i) as DisplayObjectContainer, counter);
			}
		}
	}
}