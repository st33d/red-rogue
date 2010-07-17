package com.robotacid.util.clips {
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	/* Get a locale from a nested movie clip in relation to another movie clip */
	public function localToLocal(p:Point, mc0:DisplayObject, mc1:DisplayObject):Point{
		p.x = p.y = 0;
		p = mc0.localToGlobal(p);
		p = mc1.globalToLocal(p);
		return p;
	}

}