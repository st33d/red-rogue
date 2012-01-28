package com.robotacid.ui {
	import com.robotacid.gfx.BlitClip;
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
		
		public var targetScrollDir:int;
		
		private var lineBuffer:Vector.<BitmapData>;
		private var lineWidthBuffer:Vector.<Number>;
		private var border:BitmapData;
		private var textBox:TextBox;
		private var insertionPoint:BlitClip;
		private var insertionPointPos:Point;
		private var insertionPointRect:Rectangle;
		private var scrollPoint:Point;
		private var point:Point;
		private var scrollSpeed:Number;
		private var scrollDir:int;
		private var scrolling:Boolean;
		private var insertionPointFrame:int;
		
		public static const LINES:int = 3;
		public static const HEIGHT:Number = 35
		public static const BACKGROUND_COL:uint = 0xFF111111;
		public static const BORDER_COL:uint = 0xFF999999;
		public static const FONT_COL:uint = 0xFFDDDDDD;
		public static const SCROLL_SPEED_MAX:Number = 4;
		public static const LINE_SPACING:Number = 11;
		public static const SCROLL_UP_STOP_Y:Number = HEIGHT - (LINE_SPACING + 2);
		
		public function Console() {
			super(new BitmapData(Game.WIDTH, HEIGHT, true, BACKGROUND_COL));
			lineBuffer = new Vector.<BitmapData>();
			lineWidthBuffer = new Vector.<Number>();
			point = new Point();
			border = bitmapData.clone();
			border.fillRect(bitmapData.rect, BORDER_COL);
			border.fillRect(new Rectangle(1, 1, bitmapData.width - 2, bitmapData.height - 2), 0x00000000);
			textBox = new TextBox(Game.WIDTH, LINE_SPACING + 1, BACKGROUND_COL, BACKGROUND_COL, FONT_COL);
			textBox.wordWrap = false;
			insertionPoint = Game.renderer.insertionPointBlit;
			insertionPointRect = insertionPoint.rect.clone();
			
			// by default, console text scrolls in upwards
			scrollDir = -1;
			insertionPointPos = new Point(0, SCROLL_UP_STOP_Y + 3);
			targetScrollDir = -1;
			scrollPoint = new Point(0, SCROLL_UP_STOP_Y);
			
			addEventListener(Event.ENTER_FRAME, main, false, 0, true);
		}
		
		public function main(e:Event = null):void{
			if(scrollDir == 1){
				if(scrollPoint.y < 0){
					scrollSpeed = SCROLL_SPEED_MAX;
					if( -scrollPoint.y < SCROLL_SPEED_MAX) scrollSpeed = -scrollPoint.y;
					bitmapData.scroll(0, scrollSpeed);
					scrollPoint.y += scrollSpeed;
					bitmapData.copyPixels(lineBuffer[lineBuffer.length - 1], textBox.bitmapData.rect, scrollPoint);
					bitmapData.copyPixels(border, border.rect, point, null, null, true);
					
					if(scrollPoint.y == 0){
						lineBuffer.pop();
						lineWidthBuffer.pop();
						if(lineBuffer.length){
							scrollPoint.y = -LINE_SPACING;
							insertionPointPos.x = lineWidthBuffer[lineWidthBuffer.length - 1];
						}
						else scrolling = false;
					}
				}
			} else if(scrollDir == -1){
				if(scrollPoint.y > SCROLL_UP_STOP_Y){
					scrollSpeed = -SCROLL_SPEED_MAX;
					if(scrollPoint.y < SCROLL_UP_STOP_Y + SCROLL_SPEED_MAX) scrollSpeed = SCROLL_UP_STOP_Y - scrollPoint.y;
					bitmapData.scroll(0, scrollSpeed);
					scrollPoint.y += scrollSpeed;
					bitmapData.copyPixels(lineBuffer[lineBuffer.length - 1], textBox.bitmapData.rect, scrollPoint);
					bitmapData.copyPixels(border, border.rect, point, null, null, true);
					
					if(scrollPoint.y == SCROLL_UP_STOP_Y){
						lineBuffer.pop();
						lineWidthBuffer.pop();
						if(lineBuffer.length){
							scrollPoint.y = SCROLL_UP_STOP_Y + LINE_SPACING;
							insertionPointPos.x = lineWidthBuffer[lineWidthBuffer.length - 1];
						}
						else scrolling = false;
					}
				}
			}
			if(!scrolling){
				// animate a glowing cursor after the last entry
				insertionPoint.x = insertionPointRect.x = insertionPointPos.x;
				insertionPoint.y = insertionPointRect.y = insertionPointPos.y;
				bitmapData.fillRect(insertionPointRect, BACKGROUND_COL);
				insertionPoint.render(bitmapData, insertionPointFrame++);
				if(insertionPointFrame >= insertionPoint.totalFrames) insertionPointFrame = 0;
				
				// wait until scrolling has stopped before switching the direction of text
				if(targetScrollDir != scrollDir){
					scrollDir = targetScrollDir;
					if(scrollDir == 1){
						scrollPoint.y = 0;
						insertionPointPos.y = 3;
					} else if(scrollDir == -1){
						scrollPoint.y = SCROLL_UP_STOP_Y;
						insertionPointPos.y = SCROLL_UP_STOP_Y + 3;
					}
					print("console scroll direction changed");
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
			lineWidthBuffer.push(textBox.lineWidths[0] + textBox.tracking + 2);
			if(scrollDir == 1){
				if(scrollPoint.y == 0) scrollPoint.y = -LINE_SPACING * scrollDir;
			} else if(scrollDir == -1){
				if(scrollPoint.y == SCROLL_UP_STOP_Y) scrollPoint.y = SCROLL_UP_STOP_Y + LINE_SPACING;
			}
			if(!scrolling){
				insertionPointRect.x = insertionPoint.x;
				insertionPointRect.y = insertionPoint.y;
				insertionPointFrame = 0;
				bitmapData.fillRect(insertionPointRect, BACKGROUND_COL);
			}
			insertionPointPos.x = lineWidthBuffer[lineWidthBuffer.length - 1];
			scrolling = true;
			try{
				ExternalInterface.call("printToLog", str);
			}catch(e:Error){}
		}
		
		/* Changes the scrolling behaviour of the console */
		public function toggleScrollDir():void{
			if(targetScrollDir == -1) targetScrollDir = 1;
			else targetScrollDir = -1;
		}
		
	}

}