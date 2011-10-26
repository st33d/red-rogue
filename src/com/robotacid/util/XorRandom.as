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
		public static var r:uint;
		
		public function XorRandom(seed:uint = 0) {
			if(seed){
				r = seed;
			} else {
				r = Math.random() * uint.MAX_VALUE;
			}
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
	}

}