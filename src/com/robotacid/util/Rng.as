package com.robotacid.util {
	/**
	 * Adobe broke >>> operator on iOS so I'm using GSkinner's PM version.
	 * Having a >>> operator shifting by 35 always struck me as odd anyway.
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Rng {
		
		public static const MAX_RATIO:Number = 1 / uint.MAX_VALUE;
		public var r:uint;
		public var seed:uint;
		
		public function Rng(seed:uint = 0) {
						
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
			return (r = (r * 16807) % 2147483647)/0x7FFFFFFF+0.000000000233;
		}
		
		public function range(n:Number):Number{
			return value() * n;
		}
		
		public function rangeInt(n:Number):int{
			return value() * n;
		}
		
		public function coinFlip():Boolean{
			return value() < 0.5;
		}
		
		/* Advance the sequence by n steps */
		public function step(n:int = 1):void{
			while(n--){
				value();
			}
		}
	}

}