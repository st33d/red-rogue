package com.robotacid.geom {
	import flash.geom.Rectangle;
	/**
	 * I've got this here because I tend to forget this handy piece of code
	 *
	 * Does Rectangle rect intersect a circle with center point cx,cy and radius r
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	
	public function rectangleIntersectsCircle(rect:Rectangle, cx:Number, cy:Number, r:Number):Boolean{
		var testX:Number = cx;
		var testY:Number = cy;
		if(testX < rect.x) testX = rect.x;
		if(testX > (rect.x + rect.width - 1)) testX = (rect.x + rect.width - 1);
		if(testY < rect.y) testY = rect.y;
		if(testY > (rect.y + rect.height - 1)) testY = (rect.y + rect.height - 1);
		return ((cx - testX) * (cx - testX) + (cy - testY) * (cy - testY)) < r * r;
	}

}