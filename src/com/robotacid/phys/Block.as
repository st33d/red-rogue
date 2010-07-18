package com.robotacid.phys {
	import com.robotacid.geom.Rect;
	import flash.display.Graphics;
	import flash.display.Sprite;
	
	/**
	* Work horse of the collision engine
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class Block extends Rect{
		
		public var active:Boolean;
		
		/* block properties are stored as bits in "type", making them swift to copy or initialise
		 *
		 * They can be stacked in type using the OR bitwise
		 * operator "|".
		 *
		 * eg:
		 *
		 * type |= BREAKABLE;
		 * type |= STATIC | SOLID;
		 *
		 * The presence of one of these properties can be determine using
		 * the AND bitwise operator "&"
		 *
		 * if(type & BREAKABLE) { // do something }
		 *
		 * The absence of a property can likewise be tested using bitwise NOT "~"
		 *
		 * if(~type & BREAKABLE) { // do something }
		 *
		 * If one is doing a complicated if statement, then the bitwise test must be in brackets to
		 * be evaluated as a boolean
		 *
		 * if((type & BREAKABLE) && active) { // do something }
		 *
		 * A property can be removed using the NOT operator ~ and an AND-EQUALS bitwise operation &=
		 *
		 * type &= ~SOLID;
		 * type &= ~(STATIC | SOLID);
		 *
		 * the inheirited direction properties are used to imply a side is solid, thus the composite property
		 * SOLID is the same as saying UP | RIGHT | DOWN | LEFT
		 */
		public var type:int;
		
		/* No block here */
		public static const EMPTY:int = 0;
		
		// properties 1 to 4 are the sides of a Rect, inhierited from Rect
		
		/* A block that doesn't move */
		public static const STATIC:int = 1 << 4;
		/* A block that can break */
		public static const BREAKABLE:int = 1 << 5;
		/* A free moving crate style block - for puzzles */
		public static const FREE:int = 1 << 6;
		/* A block that moves on its own */
		public static const MOVING:int = 1 << 7;
		/* This block is the collision space of a monster */
		public static const MONSTER:int = 1 << 8;
		/* This block is the collision space of the player */
		public static const PLAYER:int = 1 << 9;
		/* A block whose upper edge resists colliders moving down but not in any other direction */
		public static const LEDGE:int = 1 << 10;
		/* Dungeon walls */
		public static const WALL:int = 1 << 11;
		/* This block is either a monster or the player */
		public static const CHARACTER:int = 1 << 12;
		/* This block is a head */
		public static const HEAD:int = 1 << 13;
		/* This refers to an area that is a ladder */
		public static const LADDER:int = 1 << 14;
		/* This block is a slave of the player */
		public static const MINION:int = 1 << 15;
		/* This block is an animation for the decapitation of Characters */
		public static const CORPSE:int = 1 << 16;
		
		/* used with idToString() */
		public static const TOTAL_PROPERTIES:int = 12;
		
		// composite properties
		
		/* Equal to UP | RIGHT | DOWN | LEFT */
		public static const SOLID:int = 15;
		
		public function Block(x:Number = 0, y:Number = 0, width:Number = 0, height:Number = 0, type:int = 0){
			super(x, y, width, height);
			this.type = type;
			active = true;
		}
		public function copy():Block{
			return new Block(x, y, width, height, type);
		}
		public function map(x:Number = 0, y:Number = 0, width:Number = 0, height:Number = 0, type:int = 0):void{
			this.x = x;
			this.y = y;
			this.width = width;
			this.height = height;
			this.type = type;
		}
		override public function draw(gfx:Graphics):void {
			super.draw(gfx);
			if (type > 0){
				if (type & UP){
					gfx.moveTo(x + width * 0.5, y + height * 0.5);
					gfx.lineTo(x + width * 0.5, y);
				}
				if (type & RIGHT){
					gfx.moveTo(x + width * 0.5, y + height * 0.5);
					gfx.lineTo(x + width, y + height * 0.5);
				}
				if (type & DOWN){
					gfx.moveTo(x + width * 0.5, y + height * 0.5);
					gfx.lineTo(x + width * 0.5, y + height);
				}
				if (type & LEFT){
					gfx.moveTo(x + width * 0.5, y + height * 0.5);
					gfx.lineTo(x, y + height * 0.5);
				}
			}
		}
		override public function toString():String {
			return "(x:"+x+" y:"+y+" width:"+width+" height:"+height+" type:"+typeToString(type)+")";
		}
		/* Returns all properties of this block as a string */
		public static function typeToString(type:int):String{
			if (type == EMPTY) return "EMPTY";
			var n:int, s:String = "";
			for (var i:int = 0; i < TOTAL_PROPERTIES; i++){
				n = type & (1 << i);
				if (s == "UP|RIGHT|DOWN|LEFT|") s = "SOLID|";
				if (n == UP) s += "UP|";
				else if (n == RIGHT) s += "RIGHT|";
				else if (n == DOWN) s += "DOWN|";
				else if (n == LEFT) s += "LEFT|";
				else if (n == STATIC) s += "STATIC|";
				else if (n == BREAKABLE) s += "BREAKABLE|";
				else if (n == FREE) s += "FREE|";
				else if (n == MOVING) s += "MOVING|";
				else if (n == MONSTER) s += "MONSTER|";
				else if (n == PLAYER) s += "PLAYER|";
				else if (n == LEDGE) s += "LEDGE|";
				else if (n == WALL) s += "WALL|";
				else if (n == CHARACTER) s += "CHARACTER|";
			}
			return s.substr(0, s.length - 1);
		}
	}
	
}