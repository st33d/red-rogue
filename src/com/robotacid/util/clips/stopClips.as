package com.robotacid.util.clips {
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	/* Pause hack - freezes mc and all of its children */
	public function stopClips(mc:DisplayObjectContainer):void{
		for(var i:int = 0; i < mc.numChildren; i++){
			if (mc.getChildAt(i) is MovieClip){
				(mc.getChildAt(i) as MovieClip).stop();
			}
			if(mc.getChildAt(i) is DisplayObjectContainer){
				stopClips(mc.getChildAt(i) as DisplayObjectContainer);
			}
		}
	}

}