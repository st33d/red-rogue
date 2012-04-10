package com.robotacid.level {
	import com.robotacid.geom.Pixel;
	
	/**
	 * Needed a pixel version of a Rect for making rooms
	 * 
	 * Also need the capacity to theme rooms and identify the other rooms they are connected to
	 * for pacing
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Room {
		
		public var start:Boolean;
		public var gridNum:int;
		public var x:int;
		public var y:int;
		public var width:int;
		public var height:int;
		public var id:int;
		public var num:int;
		public var siblings:Vector.<Room>;
		public var doors:Vector.<Pixel>;
		public var surfaces:Vector.<Surface>;
		
		public static var roomCount:int = 0;
		
		public function Room(x:int = 0, y:int = 0, width:int = 0, height:int = 0, id:int = 0) {
			this.x = x;
			this.y = y;
			this.width = width;
			this.height = height;
			this.id = id;
			start = false;
			siblings = new Vector.<Room>();
			doors = new Vector.<Pixel>();
			surfaces = new Vector.<Surface>();
			num = roomCount++;
		}
		public function touchesDoors(p:Pixel):Boolean{
			for(var i:int = 0; i < doors.length; i++){
				if(p.y == doors[i].y && (p.x == doors[i].x - 1 || p.x == doors[i].x + 1)) return true;
				if(p.x == doors[i].x && (p.y == doors[i].y - 1 || p.y == doors[i].y + 1)) return true;
			}
			return false;
		}
		/* Do two Rooms touch? */
		public function touches(b:Room):Boolean{
			return !(this.x > b.x + b.width || this.x + this.width < b.x || this.y > b.y + b.height || this.y + this.height < b.y);
		}
		/* Do two Rooms intersect? */
		public function intersects(b:Room):Boolean{
			return !(this.x > b.x + (b.width - 1) || this.x + (this.width - 1) < b.x || this.y > b.y + (b.height - 1) || this.y + (this.height - 1) < b.y);
		}
		/* Is this point inside the Room */
		public function contains(x:int, y:int):Boolean{
			return x >= this.x && y >= this.y && x < this.x + width && y < this.y + height;
		}
	}
	
}