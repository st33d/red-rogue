package com.robotacid.geom {
	import flash.geom.Rectangle;
	/**
	 * I've got this here because I tend to forget this handy piece of code
	 * and sometimes I like to inline this check rather than waste time on a method call
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	
	public function rectangleIntersection(a:Rectangle, b:Rectangle):Boolean {
		return !(a.x > b.x + (b.width - 1) || a.x + (a.width - 1) < b.x || a.y > b.y + (b.height - 1) || a.y + (a.height - 1) < b.y);
	}

}