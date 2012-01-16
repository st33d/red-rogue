package com.robotacid.ui {
	/**
	 * Rocks text back and forth in a limited space
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class TextBoxMarquee {
		
		public var offset:int;
		private var minOffset:int;
		private var count:int;
		private var dir:int;
		
		public static const SPEED:int = 1;
		public static const ROCK_DELAY:int = 30;
		
		public function TextBoxMarquee(minOffset:int) {
			this.minOffset = minOffset;
			this.offset = 0;
			count = ROCK_DELAY;
			dir = -1;
		}
		
		public function main():void{
			if(count){
				count--;
			} else {
				if(dir < 0){
					offset -= SPEED;
					if(offset <= minOffset){
						offset = minOffset;
						count = ROCK_DELAY;
						dir = 1;
					}
				} else if(dir > 0){
					offset += SPEED * 2;
					if(offset >= 0){
						offset = 0;
						count = ROCK_DELAY;
						dir = -1;
					}
				}
			}
		}
		
	}

}