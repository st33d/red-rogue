package com.robotacid.geom {
	import flash.geom.Rectangle;
	/**
	 * I've got this here because I tend to forget this handy piece of code
	 * and sometimes I like to inline this check rather than waste time on a method call
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	
	public function rectangleIntersection(a:Rectangle, b:Rectangle):Rectangle {
		return new Rectangle(Math.max(a.x, b.x), Math.max(a.y, b.y), Math.abs(Math.max(a.x, b.x) - Math.min(a.x + a.width, b.x + b.width)), Math.abs(Math.max(a.y, b.y) - Math.min(a.y + a.height, b.y + b.height)));
	}

}