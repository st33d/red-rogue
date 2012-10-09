package com.robotacid.util {
	/**
	 * XorShift random number generator
	 *
	 * Adapted from: http://www.calypso88.com/?p=524
	 *
	 * I've inlined the algorithm repeatedly because it actually runs faster than Math.random()
	 * so we might as well keep the speed boost on all calls to this object
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class XorRandom {
		
		public static const MAX_RATIO:Number = 1 / uint.MAX_VALUE;
		public var r:uint;
		public var seed:uint;
		
		public function XorRandom(seed:uint = 0) {
			
			//seed = 1195675104;
			
			if(seed){
				r = seed;
			} else {
				r = seedFromDate();
			}
			this.seed = r;
		}
		
		/* Get a seed using a Date object */
		public static function seedFromDate():uint{
			var r:uint = (new Date().time % uint.MAX_VALUE) as uint;
			// once in a blue moon we can roll a zero from sourcing the seed from the Date
			if(r == 0) r = Math.random() * MAX_RATIO;
			return r;
		}
		
		/* Returns a number from 0 - 1 */
		public function value():Number{
			r ^= r << 21;
			r ^= r >>> 35;
			r ^= r << 4;
			return r * MAX_RATIO;
		}
		
		public function range(n:Number):Number{
			r ^= r << 21;
			r ^= r >>> 35;
			r ^= r << 4;
			return r * MAX_RATIO * n;
		}
		
		public function rangeInt(n:Number):int{
			r ^= r << 21;
			r ^= r >>> 35;
			r ^= r << 4;
			return r * MAX_RATIO * n;
		}
		
		public function coinFlip():Boolean{
			r ^= r << 21;
			r ^= r >>> 35;
			r ^= r << 4;
			return r * MAX_RATIO < 0.5;
		}
	}

}