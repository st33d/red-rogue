package com.robotacid.ui {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * ...
	 * @author ...
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
		
		public static const CHARACTER_CLASSES:Array = [A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, NUMBER_0, NUMBER_1, NUMBER_2, NUMBER_3, NUMBER_4, NUMBER_5, NUMBER_6, NUMBER_7, NUMBER_8, NUMBER_9, APOSTROPHE, BACKSLASH, COLON, COMMA, EQUALS, EXCLAMATION, FORWARDSLASH, HYPHEN, LEFT_BRACKET, PLUS, QUESTION, RIGHT_BRACKET, SEMICOLON, STOP];
		
		public static var point:Point = new Point();
		
		public static var characters:Array;
		
		protected var _width:int;
		protected var _height:int;
		protected var _text:String;
		protected var borderRect:Rectangle;
		
		public var lines:int;
		public var fixedHeight:Boolean;
		public var backgroundCol:uint;
		public var borderCol:uint;
		public var fontCol:uint;
		public var backgroundAlpha:Number;
		public var maxLines:int;
		
		public static var lineHeight:Number = 10;
		public var leading:int = 1;
		public var tracking:Number = 2;
		public var spaceWidth:Number = 4;
		
		public static const BORDER_ALLOWANCE:int = 2;
		
		public function TextBox(_width:Number, lines:int = 1, backgroundCol:uint = 0xFF111111, borderCol:uint = 0xFF999999, fontCol:uint = 0xFFDDDDDD) {
			this._width = _width;
			this.backgroundCol = backgroundCol;
			this.borderCol = borderCol;
			this.fontCol = fontCol;
			if(lines < 1) lines = 1;
			_text = "";
			fixedHeight = false;
			setLines(lines);
			super(bitmapData, "auto", false);
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
		
		public function setLines(n:int):void{
			lines = n;
			bitmapData = new BitmapData(_width, lines * lineHeight + BORDER_ALLOWANCE * 2, true, 0x00000000);
			borderRect = new Rectangle(1, 1, _width - 2, BORDER_ALLOWANCE + lines * lineHeight);
			drawBorder();
		}
		
		public function set text(str:String):void{
			_text = str.toUpperCase();
			if(!fixedHeight){
				lines = str.split("\n").length;
				setLines(lines);
			}
			drawText();
		}
		
		public function get text():String{
			return _text;
		}
		
		/* Draws a background coloured alpha shape over a line of text.
		 * requires that disabledShape.graphics.clear() be called first
		 * because you may want to shadow out multiple lines
		 */
		public function setDisabledLine(n:int):void{
			var disableRect:Rectangle = new Rectangle(BORDER_ALLOWANCE, BORDER_ALLOWANCE + n * lineHeight, _width - BORDER_ALLOWANCE * 2, lineHeight);
			bitmapData.colorTransform(disableRect, new ColorTransform(1, 1, 1, 1, -100, -100, -100));
		}
		
		public function drawBorder():void{
			bitmapData.fillRect(bitmapData.rect, borderCol);
			bitmapData.fillRect(borderRect, backgroundCol);
		}
		
		public function drawText():void{
			drawBorder();
			point.x = BORDER_ALLOWANCE;
			point.y = BORDER_ALLOWANCE;
			var c:String, textBitmapData:BitmapData;
			for(var i:int = 0; i < _text.length; i++){
				c = _text.charAt(i);
				if(c == " "){
					point.x += spaceWidth + tracking;
					continue;
				} else if(c == "\n"){
					point.x = BORDER_ALLOWANCE;
					point.y += lineHeight;
					continue;
				} else if(c == "'"){
					textBitmapData = characters["APOSTROPHE"];
				} else if(c == "\\"){
					textBitmapData = characters["BACKSLASH"];
				} else if(c == ":"){
					textBitmapData = characters["COLON"];
				} else if(c == ","){
					textBitmapData = characters["COMMA"];
				} else if(c == "="){
					textBitmapData = characters["EQUALS"];
				} else if(c == "!"){
					textBitmapData = characters["EXCLAMATION"];
				} else if(c == "/"){
					textBitmapData = characters["FORWARDSLASH"];
				} else if(c == "-"){
					textBitmapData = characters["HYPHEN"];
				} else if(c == "("){
					textBitmapData = characters["LEFT_BRACKET"];
				} else if(c == "+"){
					textBitmapData = characters["PLUS"];
				} else if(c == "?"){
					textBitmapData = characters["QUESTION"];
				} else if(c == ")"){
					textBitmapData = characters["RIGHT_BRACKET"];
				} else if(c == ";"){
					textBitmapData = characters["SEMICOLON"];
				} else if(c == "."){
					textBitmapData = characters["STOP"];
				} else {
					textBitmapData = characters[c];
				}
				point.y += leading;
				bitmapData.copyPixels(textBitmapData, textBitmapData.rect, point, null, null, true);
				point.y -= leading;
				point.x += textBitmapData.width + tracking;
			}
		}
		
	}

}