package com.robotacid.ui {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * Custom bitmap font
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class TextBox extends Bitmap{
		
		[Embed(source = "../../../assets/font/a.png")] public static var A:Class;
		[Embed(source = "../../../assets/font/b.png")] public static var B:Class;
		[Embed(source = "../../../assets/font/c.png")] public static var C:Class;
		[Embed(source = "../../../assets/font/d.png")] public static var D:Class;
		[Embed(source = "../../../assets/font/e.png")] public static var E:Class;
		[Embed(source = "../../../assets/font/f.png")] public static var F:Class;
		[Embed(source = "../../../assets/font/g.png")] public static var G:Class;
		[Embed(source = "../../../assets/font/h.png")] public static var H:Class;
		[Embed(source = "../../../assets/font/i.png")] public static var I:Class;
		[Embed(source = "../../../assets/font/j.png")] public static var J:Class;
		[Embed(source = "../../../assets/font/k.png")] public static var K:Class;
		[Embed(source = "../../../assets/font/l.png")] public static var L:Class;
		[Embed(source = "../../../assets/font/m.png")] public static var M:Class;
		[Embed(source = "../../../assets/font/n.png")] public static var N:Class;
		[Embed(source = "../../../assets/font/o.png")] public static var O:Class;
		[Embed(source = "../../../assets/font/p.png")] public static var P:Class;
		[Embed(source = "../../../assets/font/q.png")] public static var Q:Class;
		[Embed(source = "../../../assets/font/r.png")] public static var R:Class;
		[Embed(source = "../../../assets/font/s.png")] public static var S:Class;
		[Embed(source = "../../../assets/font/t.png")] public static var T:Class;
		[Embed(source = "../../../assets/font/u.png")] public static var U:Class;
		[Embed(source = "../../../assets/font/v.png")] public static var V:Class;
		[Embed(source = "../../../assets/font/w.png")] public static var W:Class;
		[Embed(source = "../../../assets/font/x.png")] public static var X:Class;
		[Embed(source = "../../../assets/font/y.png")] public static var Y:Class;
		[Embed(source = "../../../assets/font/z.png")] public static var Z:Class;
		[Embed(source = "../../../assets/font/0.png")] public static var NUMBER_0:Class;
		[Embed(source = "../../../assets/font/1.png")] public static var NUMBER_1:Class;
		[Embed(source = "../../../assets/font/2.png")] public static var NUMBER_2:Class;
		[Embed(source = "../../../assets/font/3.png")] public static var NUMBER_3:Class;
		[Embed(source = "../../../assets/font/4.png")] public static var NUMBER_4:Class;
		[Embed(source = "../../../assets/font/5.png")] public static var NUMBER_5:Class;
		[Embed(source = "../../../assets/font/6.png")] public static var NUMBER_6:Class;
		[Embed(source = "../../../assets/font/7.png")] public static var NUMBER_7:Class;
		[Embed(source = "../../../assets/font/8.png")] public static var NUMBER_8:Class;
		[Embed(source = "../../../assets/font/9.png")] public static var NUMBER_9:Class;
		[Embed(source = "../../../assets/font/APOSTROPHE.png")] public static var APOSTROPHE:Class;
		[Embed(source = "../../../assets/font/BACKSLASH.png")] public static var BACKSLASH:Class;
		[Embed(source = "../../../assets/font/COLON.png")] public static var COLON:Class;
		[Embed(source = "../../../assets/font/COMMA.png")] public static var COMMA:Class;
		[Embed(source = "../../../assets/font/EQUALS.png")] public static var EQUALS:Class;
		[Embed(source = "../../../assets/font/EXCLAMATION.png")] public static var EXCLAMATION:Class;
		[Embed(source = "../../../assets/font/FOWARDSLASH.png")] public static var FORWARDSLASH:Class;
		[Embed(source = "../../../assets/font/HYPHEN.png")] public static var HYPHEN:Class;
		[Embed(source = "../../../assets/font/LEFT_BRACKET.png")] public static var LEFT_BRACKET:Class;
		[Embed(source = "../../../assets/font/PLUS.png")] public static var PLUS:Class;
		[Embed(source = "../../../assets/font/QUESTION.png")] public static var QUESTION:Class;
		[Embed(source = "../../../assets/font/RIGHT_BRACKET.png")] public static var RIGHT_BRACKET:Class;
		[Embed(source = "../../../assets/font/SEMICOLON.png")] public static var SEMICOLON:Class;
		[Embed(source = "../../../assets/font/STOP.png")] public static var STOP:Class;
		[Embed(source = "../../../assets/font/AT.png")] public static var AT:Class;
		[Embed(source = "../../../assets/font/UNDERSCORE.png")] public static var UNDERSCORE:Class;
		[Embed(source = "../../../assets/font/PERCENT.png")] public static var PERCENT:Class;
		[Embed(source = "../../../assets/font/ASTERISK.png")] public static var ASTERISK:Class;
		[Embed(source = "../../../assets/font/QUOTES.png")] public static var QUOTES:Class;
		
		public static const CHARACTER_CLASSES:Array = [A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, NUMBER_0, NUMBER_1, NUMBER_2, NUMBER_3, NUMBER_4, NUMBER_5, NUMBER_6, NUMBER_7, NUMBER_8, NUMBER_9, APOSTROPHE, BACKSLASH, COLON, COMMA, EQUALS, EXCLAMATION, FORWARDSLASH, HYPHEN, LEFT_BRACKET, PLUS, QUESTION, RIGHT_BRACKET, SEMICOLON, STOP, AT, UNDERSCORE, PERCENT, ASTERISK, QUOTES];
		
		public static var characters:Array;
		
		public var lines:Array;						// a 2D array of all the bitmapDatas used, in lines
		public var lineWidths:Array;				// the width of each line of text (used for alignment)
		public var textLines:Array;					// a 2D array of the characters used (used for fetching offset and kerning data)
		public var tracking:int;					// tracking: the spacing between letters
		public var align:String;					// align: whether the text is centered, left or right aligned
		public var alignVert:String;				// align_vert: vertical alignment of the text
		public var lineSpacing:int;					// line_spacing: distance between each line of copy
		public var wordWrap:Boolean;				// turns wordWrap on and off
		public var marquee:Boolean;					// sets up marquee scroll for lines that exceed the width (wordWrap must be false)
		public var backgroundCol:uint;
		public var borderCol:uint;
		public var backgroundAlpha:Number;
		public var leading:int;
		
		protected var _colorInt:uint;				// the actual uint of the color being applied
		protected var _color:ColorTransform;		// a color transform object that is applied to the whole TextBox
		
		protected var whitespaceLength:int;			// the distance a whitespace takes up
		
		protected var _width:int;
		protected var _height:int;
		protected var _text:String;
		protected var borderRect:Rectangle;
		protected var boundsRect:Rectangle;
		protected var maskRect:Rectangle;
		protected var marqueeLines:Vector.<TextBoxMarquee>;
		
		public static const BORDER_ALLOWANCE:int = 2;
		
		public function TextBox(_width:Number, _height:Number, backgroundCol:uint = 0xFF111111, borderCol:uint = 0xFF999999) {
			this._width = _width;
			this._height = _height;
			this.backgroundCol = backgroundCol;
			this.borderCol = borderCol;
			align = "left";
			alignVert = "top";
			_colorInt = 0xFFFFFF;
			wordWrap = true;
			marquee = false;
			tracking = 2;
			leading = 1;
			whitespaceLength = 4;
			lineSpacing = 11;
			_text = "";
			
			lines = [];
			
			borderRect = new Rectangle(1, 1, _width - 2, _height - 2);
			boundsRect = new Rectangle(2, 2, _width - 4, _height - 4);
			maskRect = new Rectangle(0, 0, 1, 1);
			super(new BitmapData(_width, _height, true, 0x0), "auto", false);
			drawBorder();
		}
		
		/* This must be called before any TextBox is created so the bitmaps can be extracted from the
		 * imported assets */
		public static function init():void{
			characters = [];
			var textBitmap:Bitmap;
			var className:String;
			var characterName:String;
			var col:ColorTransform = new ColorTransform(1, 1, 1, 1, -8, -8, -8);
			for(var i:int = 0; i < CHARACTER_CLASSES.length; i++){
				textBitmap = new CHARACTER_CLASSES[i]();
				className = getQualifiedClassName(CHARACTER_CLASSES[i]);
				if(className.indexOf("NUMBER_") > -1) characterName = className.substr(className.indexOf("NUMBER_") + 7);
				else characterName = className.substr(className.indexOf("TextBox_") + 8);
				// taking a little of the edge off the whiteness of the text
				textBitmap.bitmapData.colorTransform(textBitmap.bitmapData.rect, col);
				characters[characterName] = textBitmap.bitmapData;
			}
		}
		
		public function set text(str:String):void{
			_text = str;
			updateText();
			draw();
		}
		
		public function get text():String{
			return _text;
		}
		
		// color
		public function get color():uint {
			return _colorInt;
		}
		public function set color(c:uint):void {
			_colorInt = c;
			if(c == 0xFFFFFF) {
				_color = null;
			} else {
				_color = new ColorTransform(
					((c >> 16) % 256) / 255,
					((c >> 8) % 256) / 255,
					(c % 256) / 255
				);
			}
			if(_color) transform.colorTransform = _color;
		}
		
		public function setSize(width:int, height:int):void{
			_width = width;
			_height = height;
			borderRect = new Rectangle(1, 1, _width - 2, _height - 2);
			boundsRect = new Rectangle(2, 2, _width - 4, _height - 4);
			bitmapData = new BitmapData(width, height, true, 0x0);
			updateText();
			draw();
		}
		
		/* Calculates an array of BitmapDatas needed to render the text */
		protected function updateText():void{
			
			// we create an array called lines that holds references to all of the
			// bitmapDatas needed and structure it like the text
			
			// the lines property is public so it can be used to ticker text
			lines = [];
			lineWidths = [];
			textLines = [];
			
			var currentLine:Array = [];
			var currentTextLine:Array = [];
			var wordBeginning:int = 0;
			var currentLineWidth:int = 0;
			var completeWordsWidth:int = 0;
			var wordWidth:int = 0;
			var newLine:Array = [];
			var newTextLine:Array = [];
			var c:String;
			
			if(!_text) _text = "";
			
			var upperCaseText:String = _text.toUpperCase();
			
			for(var i:int = 0; i < upperCaseText.length; i++){
				
				c = upperCaseText.charAt(i);
				
				// next we swap the special characters for descriptive strings
				if(c == " ") c = "SPACE";
				else if(c == ".") c = "STOP";
				else if(c == "?") c = "QUESTION";
				else if(c == ",") c = "COMMA";
				else if(c == "!") c = "EXCLAMATION";
				else if(c == "\\") c = "BACKSLASH";
				else if(c == "/") c = "FORWARDSLASH";
				else if(c == "=") c = "EQUALS";
				else if(c == "+") c = "PLUS";
				else if(c == "(") c = "LEFT_BRACKET";
				else if(c == ")") c = "RIGHT_BRACKET";
				else if(c == "-") c = "HYPHEN";
				else if(c == "\"") c = "QUOTES";
				else if(c == ":") c = "COLON";
				else if(c == "£") c = "POUND";
				else if(c == "_") c = "UNDERSCORE";
				else if(c == "'") c = "APOSTROPHE";
				else if(c == "@") c = "AT";
				else if(c == "&") c = "AMPERSAND";
				else if(c == "$") c = "DOLLAR";
				else if(c == "*") c = "ASTERISK";
				else if(c == ";") c = "SEMICOLON";
				else if(c == "%") c = "PERCENT";
				else if(c == "~") c = "TILDE";
				else if(c == "{") c = "LEFT_BRACE";
				else if(c == "}") c = "RIGHT_BRACE";
				else if(c == "@") c = "AT";
				else if(c == "_") c = "UNDERSCORE";
				else if(c == "%") c = "PERCENT";
				else if(c == "*") c = "ASTERISK";
				else if(c == "\"") c = "QUOTES";
				
				// new line characters
				if(c == "\n" || c == "\r" || c == "|"){
					lines.push(currentLine);
					textLines.push(currentTextLine);
					lineWidths.push(currentLineWidth);
					currentLineWidth = 0;
					completeWordsWidth = 0;
					wordBeginning = 0;
					wordWidth = 0;
					currentLine = [];
					currentTextLine = [];
					continue;
				}
				
				// push a character into the array
				if(characters[c]){
					// check we're in the middle of a word - spaces are null
					if(currentLine.length > 0 && currentLine[currentLine.length -1]){
						currentLineWidth += tracking;
						wordWidth += tracking;
					}
					wordWidth += characters[c].width
					currentLineWidth += characters[c].width;
					currentLine.push(characters[c]);
					currentTextLine.push(c);
				
				// the character is a SPACE or unrecognised and will be treated as a SPACE
				} else {
					if(currentLine.length > 0 && currentLine[currentLine.length - 1]){
						completeWordsWidth = currentLineWidth;
					}
					currentLineWidth += whitespaceLength;
					currentLine.push(null);
					currentTextLine.push(null);
					wordBeginning = currentLine.length;
					wordWidth = 0;
				}
				
				// if the length of the current line exceeds the width, we splice it into the next line
				// effecting word wrap
				
				if(currentLineWidth > _width - (BORDER_ALLOWANCE * 2) && wordWrap){
					// in the case where the word is larger than the text field we take back the last character
					// and jump to a new line with it
					if(wordBeginning == 0 && currentLine[currentLine.length - 1]){
						currentLineWidth -= tracking + currentLine[currentLine.length - 1].width;
						// now we take back the offending last character
						var lastBitmapData:BitmapData = currentLine.pop();
						var lastChar:String = currentTextLine.pop();
						
						lines.push(currentLine);
						textLines.push(currentTextLine);
						lineWidths.push(currentLineWidth);
						
						currentLineWidth = lastBitmapData.width;
						completeWordsWidth = 0;
						wordBeginning = 0;
						wordWidth = lastBitmapData.width;
						currentLine = [lastBitmapData];
						currentTextLine = [lastChar];
						continue;
					}
					
					newLine = currentLine.splice(wordBeginning, currentLine.length - wordBeginning);
					newTextLine = currentTextLine.splice(wordBeginning, currentTextLine.length - wordBeginning);
					lines.push(currentLine);
					textLines.push(currentTextLine);
					lineWidths.push(completeWordsWidth);
					completeWordsWidth = 0;
					wordBeginning = 0;
					currentLine = newLine;
					currentTextLine = newTextLine;
					currentLineWidth = wordWidth;
				}
			}
			// save the last line
			lines.push(currentLine);
			textLines.push(currentTextLine);
			lineWidths.push(currentLineWidth);
			
			// set up marquees (if active)
			if(!wordWrap && marquee){
				marqueeLines = new Vector.<TextBoxMarquee>();
				var offset:int;
				for(i = 0; i < lineWidths.length; i++){
					offset = (_width - BORDER_ALLOWANCE * 2) - lineWidths[i];
					marqueeLines[i] = offset < 0 ? new TextBoxMarquee(offset) : null;
				}
			}
		}
		
		/* Render */
		public function draw():void{
			
			drawBorder();
			
			var i:int, j:int;
			var point:Point = new Point();
			var x:int;
			var y:int = BORDER_ALLOWANCE;
			var alignX:int;
			var alignY:int;
			var char:BitmapData;
			var offset:Point;
			var wordBeginning:int = 0;
			var linesHeight:int = lineSpacing * lines.length;
			
			for(i = 0; i < lines.length; i++, point.y += lineSpacing){
				x = BORDER_ALLOWANCE;
				
				if(marquee){
					if(marqueeLines[i]) x += marqueeLines[i].offset;
				}
				
				wordBeginning = 0;
				for(j = 0; j < lines[i].length; j++){
					char = lines[i][j];
					
					// alignment to bitmap
					if(align == "left"){
						alignX = 0;
					} else if(align == "center"){
						alignX = _width * 0.5 - (lineWidths[i] * 0.5 + BORDER_ALLOWANCE);
					} else if(align == "right"){
						alignX = _width - lineWidths[i];
					}
					if(alignVert == "top"){
						alignY = 0;
					} else if(alignVert == "center"){
						alignY = _height * 0.5 - linesHeight * 0.5;
					} else if(alignVert == "bottom"){
						alignY = _height - linesHeight;
					}
					
					// print to bitmapdata
					if(char){
						if(j > wordBeginning){
							x += tracking;
						}
						point.x = alignX + x;
						point.y = alignY + y + leading;
						// mask characters that are outside the boundsRect
						if(
							point.x < boundsRect.x ||
							point.y < boundsRect.y ||
							point.x + char.rect.width >= boundsRect.x + boundsRect.width ||
							point.y + char.rect.height >= boundsRect.y + boundsRect.height
						){
							// are they even in the bounds rect?
							if(
								point.x + char.rect.width > boundsRect.x &&
								boundsRect.x + boundsRect.width > point.x &&
								point.y + char.rect.height > boundsRect.y &&
								boundsRect.y + boundsRect.height > point.y
							){
								// going to make a glib assumption that the TextBox won't be smaller than a single character
								maskRect.x = point.x >= boundsRect.x ? 0 : point.x - boundsRect.x;
								maskRect.y = point.y >= boundsRect.y ? 0 : point.y - boundsRect.y;
								maskRect.width = point.x + char.rect.width <= boundsRect.x + boundsRect.width ? char.rect.width : (boundsRect.x + boundsRect.width) - point.x;
								maskRect.height = point.y + char.rect.height <= boundsRect.y + boundsRect.height ? char.rect.height : (boundsRect.y + boundsRect.height) - point.y;
								if(point.x < boundsRect.x){
									maskRect.x = boundsRect.x - point.x;
									point.x = boundsRect.x;
								}
								if(point.y < boundsRect.y){
									maskRect.y = boundsRect.y - point.y;
									point.y = boundsRect.y;
								}
								bitmapData.copyPixels(char, maskRect, point, null, null, true);
							}
						} else {
							bitmapData.copyPixels(char, char.rect, point, null, null, true);
						}
						x += char.width;
					} else {
						x += whitespaceLength;
						wordBeginning = j + 1;
					}
				}
				y += lineSpacing;
			}
			
			if(_color) transform.colorTransform = _color;
		}
		
		/* Get a list of rectangles describing character positions for performing transforms */
		public function getCharRects():Vector.<Rectangle>{
			
			var rects:Vector.<Rectangle> = new Vector.<Rectangle>();
			var rect:Rectangle = new Rectangle();
			var i:int, j:int;
			var x:int;
			var y:int = BORDER_ALLOWANCE;
			var alignX:int;
			var alignY:int;
			var char:BitmapData;
			var offset:Point;
			var wordBeginning:int = 0;
			var linesHeight:int = lineSpacing * lines.length;
			
			for(i = 0; i < lines.length; i++, rect.y += lineSpacing){
				x = BORDER_ALLOWANCE;
				
				if(marquee){
					if(marqueeLines[i]) x += marqueeLines[i].offset;
				}
				
				wordBeginning = 0;
				for(j = 0; j < lines[i].length; j++){
					char = lines[i][j];
					
					// alignment to bitmap
					if(align == "left"){
						alignX = 0;
					} else if(align == "center"){
						alignX = _width * 0.5 - (lineWidths[i] * 0.5 + BORDER_ALLOWANCE);
					} else if(align == "right"){
						alignX = _width - lineWidths[i];
					}
					if(alignVert == "top"){
						alignY = 0;
					} else if(alignVert == "center"){
						alignY = _height * 0.5 - linesHeight * 0.5;
					} else if(alignVert == "bottom"){
						alignY = _height - linesHeight;
					}
					
					// print to bitmapdata
					if(char){
						if(j > wordBeginning){
							x += tracking;
						}
						rect.x = alignX + x;
						rect.y = alignY + y + leading;
						// mask characters that are outside the boundsRect
						if(
							rect.x < boundsRect.x ||
							rect.y < boundsRect.y ||
							rect.x + char.rect.width >= boundsRect.x + boundsRect.width ||
							rect.y + char.rect.height >= boundsRect.y + boundsRect.height
						){
							// are they even in the bounds rect?
							if(
								rect.x + char.rect.width > boundsRect.x &&
								boundsRect.x + boundsRect.width > rect.x &&
								rect.y + char.rect.height > boundsRect.y &&
								boundsRect.y + boundsRect.height > rect.y
							){
								// going to make a glib assumption that the TextBox won't be smaller than a single character
								maskRect.x = rect.x >= boundsRect.x ? 0 : rect.x - boundsRect.x;
								maskRect.y = rect.y >= boundsRect.y ? 0 : rect.y - boundsRect.y;
								maskRect.width = rect.x + char.rect.width <= boundsRect.x + boundsRect.width ? char.rect.width : (boundsRect.x + boundsRect.width) - rect.x;
								maskRect.height = rect.y + char.rect.height <= boundsRect.y + boundsRect.height ? char.rect.height : (boundsRect.y + boundsRect.height) - rect.y;
								if(rect.x < boundsRect.x){
									maskRect.x = boundsRect.x - rect.x;
									rect.x = boundsRect.x;
								}
								if(rect.y < boundsRect.y){
									maskRect.y = boundsRect.y - rect.y;
									rect.y = boundsRect.y;
								}
								rects.push(maskRect.clone());
							}
						} else {
							rect.width = char.width;
							rect.height = char.height;
							rects.push(rect.clone());
						}
						x += char.width;
					} else {
						x += whitespaceLength;
						wordBeginning = j + 1;
					}
				}
				y += lineSpacing;
			}
			
			return rects;
		}
		
		/* Move rectangles of pixels and applies colorTransforms, the transforms are applied sequentially */
		public function applyTranformRects(sources:Vector.<Rectangle>, destinations:Vector.<Point>, colorTransforms:Vector.<ColorTransform> = null):void{
			var source:Rectangle, destination:Point, colorTransform:ColorTransform;
			var buffer:BitmapData = bitmapData.clone();
			drawBorder();
			for(var i:int = 0; i < sources.length; i++){
				source = sources[i];
				destination = destinations[i];
				if(colorTransforms){
					colorTransform = colorTransforms[i];
					buffer.colorTransform(source, colorTransform);
				}
				bitmapData.copyPixels(buffer, source, destination, null, null, true);
			}
		}
		
		/* Update lines that have been assigned TextBoxMarquees */
		public function updateMarquee():void{
			var marquee:TextBoxMarquee;
			for(var i:int = 0; i < marqueeLines.length; i++){
				marquee = marqueeLines[i];
				if(marquee) marquee.main();
			}
			draw();
		}
		
		/* Reset the offsets on the TextBoxMarquees */
		public function resetMarquee():void{
			var marquee:TextBoxMarquee;
			for(var i:int = 0; i < marqueeLines.length; i++){
				marquee = marqueeLines[i];
				if(marquee) marquee.offset = 0;
			}
			draw();
		}
		
		/* Applies a ColorTransform to a line of text */
		public function setLineCol(n:int, col:ColorTransform):void{
			var disableRect:Rectangle = new Rectangle(BORDER_ALLOWANCE, BORDER_ALLOWANCE + n * lineSpacing, _width - BORDER_ALLOWANCE * 2, lineSpacing - 1);
			bitmapData.colorTransform(disableRect, col);
		}
		
		public function drawBorder():void{
			bitmapData.fillRect(bitmapData.rect, borderCol);
			bitmapData.fillRect(borderRect, backgroundCol);
		}
		
	}

}