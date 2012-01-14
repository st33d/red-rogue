package com.robotacid.ui {
	import com.robotacid.ui.TextBox;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Used to print out events that occur in the game, it simulates the look of a TextBox.
	 * 
	 * Scrolls new lines of text in by buffering them to images and then scrolling them in
	 * and shifting the image of the old messages out
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Console extends Bitmap{
		
		private var lineBuffer:Vector.<BitmapData>;
		private var border:BitmapData;
		private var textBox:TextBox;
		private var scrollPoint:Point;
		private var point:Point;
		private var scrollSpeed:Number;
		
		public static const LINES:int = 3;
		public static const HEIGHT:Number = 35
		public static const BACKGROUND_COL:uint = 0xFF111111;
		public static const BORDER_COL:uint = 0xFF999999;
		public static const FONT_COL:uint = 0xFFDDDDDD;
		public static const SCROLL_SPEED_MAX:Number = 4;
		public static const LINE_SPACING:Number = 11;
		
		public function Console() {
			super(new BitmapData(Game.WIDTH, HEIGHT, true, BACKGROUND_COL));
			lineBuffer = new Vector.<BitmapData>();
			scrollPoint = new Point();
			point = new Point();
			border = bitmapData.clone();
			border.fillRect(bitmapData.rect, BORDER_COL);
			border.fillRect(new Rectangle(1, 1, bitmapData.width - 2, bitmapData.height - 2), 0x00000000);
			textBox = new TextBox(Game.WIDTH, LINE_SPACING + 1, BACKGROUND_COL, BACKGROUND_COL, FONT_COL);
			textBox.wordWrap = false;
			
			addEventListener(Event.ENTER_FRAME, main, false, 0, true);
		}
		
		public function main(e:Event = null):void{
			if(scrollPoint.y < 0){
				scrollSpeed = SCROLL_SPEED_MAX;
				if( -scrollPoint.y < SCROLL_SPEED_MAX) scrollSpeed = -scrollPoint.y;
				bitmapData.scroll(0, scrollSpeed);
				scrollPoint.y += scrollSpeed;
				bitmapData.copyPixels(lineBuffer[lineBuffer.length - 1], textBox.bitmapData.rect, scrollPoint);
				bitmapData.copyPixels(border, border.rect, point, null, null, true);
				
				if(scrollPoint.y == 0){
					lineBuffer.pop();
					if(lineBuffer.length) scrollPoint.y = -LINE_SPACING;
				}
			}
		}
		
		/* Adds a new image of a line of text to the buffer */
		public function print(str:String):void{
			// catch multiple lines here, split and recurse
			str = str.toUpperCase();
			if(str.indexOf("\n") > -1){
				var printList:Array = str.split("\n");
				while(printList.length) print(printList.shift());
				return;
			}
			textBox.text = str;
			lineBuffer.push(textBox.bitmapData.clone());
			if(scrollPoint.y == 0) scrollPoint.y = -LINE_SPACING;
			try{
				ExternalInterface.call("printToLog", str);
			}catch(e:Error){}
		}
		
		
	}

}