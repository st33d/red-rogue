package com.robotacid.geom {
	import flash.geom.Rectangle;
	/**
	 * I've got this here because I tend to forget this handy piece of code
	 *
	 * Does rect intersect line?
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	
	public function rectangleIntersectsLine(rect:Rectangle, line:Line):Boolean{
		// test for a bounding box collision
		if(x > Math.max(line.a.x, line.b.x) || rect.x + rect.width - 1 < Math.min(line.a.x, line.b.x) || y > Math.max(line.a.y, line.b.y) || rect.y + rect.height - 1 < Math.min(line.a.y, line.b.y)) return false;
		// first test the end points of the lines for containment
		if((line.a.x >= x && line.a.y >= y && line.a.x < rect.x + rect.width && line.a.y < rect.y + rect.height) || (line.b.x >= rect.x && line.b.y >= rect.y && line.b.x < rect.x + rect.width && line.b.y < rect.y + rect.height)) return true;
		// now test to see if the line end points are either side of the rect, bisecting it
		if(
			(line.a.x >= rect.x && line.a.x < rect.x + rect.width && line.b.x >= rect.x && line.b.x < rect.x + rect.width && (line.a.y < rect.y && line.b.y > rect.y + rect.height - 1 || line.b.y < rect.y && line.a.y > rect.y + rect.height - 1)) ||
			(line.a.y >= rect.y && line.a.y < rect.y + rect.height && line.b.y >= rect.y && line.b.y < rect.y + rect.height && (line.a.x < rect.x && line.b.x > rect.x + rect.width - 1 || line.b.x < rect.x && line.a.x > rect.x + rect.width - 1))
		) return true;
		// one last test: check for correspoding dot products from the corners
		var vx:Number, vy:Number, dots:int;
		vx = rect.x - line.a.x;
		vy = rect.y - line.a.y;
		if(vx * line.rx + vy * line.ry < 0) dots++;
		vx = (rect.x + rect.width - 1) - line.a.x;
		vy = rect.y - line.a.y;
		if(vx * line.rx + vy * line.ry < 0) dots++;
		vx = rect.x - line.a.x;
		vy = (rect.y + rect.height - 1) - line.a.y;
		if(vx * line.rx + vy * line.ry < 0) dots++;
		vx = (rect.x + rect.width - 1) - line.a.x;
		vy = (rect.y + rect.height - 1) - line.a.y;
		if(vx * line.rx + vy * line.ry < 0) dots++;
		if(dots == 0 || dots == 4) return false;
		return true;
	}

}