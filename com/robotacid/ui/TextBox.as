package com.robotacid.ui {
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextLineMetrics;
	
	/**
	 * This is a TextField with a background shape border that is rendered to be pixel friendly
	 * 
	 * Because Flash is a bit of a dick about fonts, it has been custom designed for the
	 * FFF Quadratis font, and would need re-jigging for another font
	 * 
	 * This class is undergoing a bit of an overhaul, so there may be some redundant methods
	 * in here.
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class TextBox extends Sprite{
		
		[Embed(source="../../../assets/fff_Quadratis.ttf",fontFamily="quadratis")] public var font_name:String;
		
		public var _width:int;
		public var _height:int;
		public var _text:String;
		public var lines:int;
		public var info:TextField;
		public var infoMask:Shape;
		public var backShape:Shape;
		public var disabledShape:Shape;
		public var lineMetrics:TextLineMetrics;
		public var fixedHeight:Boolean;
		
		public var backgroundCol:uint;
		public var borderCol:uint;
		public var fontCol:uint;
		public var backgroundAlpha:Number;
		
		public var maxLines:int;
		
		public function TextBox(_width:Number, lineHeight:int, backgroundCol:uint = 0x111111, borderCol:uint = 0x999999, fontCol:uint = 0xDDDDDD, backgroundAlpha:Number = 1.0) {
			this._width = _width;
			this.backgroundCol = backgroundCol;
			this.borderCol = borderCol;
			this.fontCol = fontCol;
			this.backgroundAlpha = backgroundAlpha;
			backShape = new Shape();
			addChild(backShape);
			info = new TextField();
			info.x = 1;
			info.y = -3;
			info.width = _width-2;
			addChild(info);
			info.embedFonts = true;
			info.antiAliasType = AntiAliasType.NORMAL;
			info.gridFitType = GridFitType.PIXEL;
			var tf:TextFormat = new TextFormat("quadratis", 8, fontCol);
			//tf.letterSpacing = -1;
			info.defaultTextFormat = tf;
			info.selectable = false;
			info.text = _text = "";
			info.wordWrap = false;
			info.autoSize = "none";
			lineMetrics = info.getLineMetrics(0);
			lines = 0;
			fixedHeight = false;
			infoMask = new Shape();
			//addChild(infoMask);
			//info.mask = infoMask;
			
			disabledShape = new Shape();
			addChild(disabledShape);
			
			setLineHeight(lineHeight);
		}
		
		public function set text(str:String):void{
			_text = str;
			if(!fixedHeight){
				lines = str.split("\n").length;
				setLineHeight(lines);
			}
			info.text = _text;
		}
		
		public function get text():String{
			return _text;
		}
		
		public function setLineHeight(n:int):void{
			info.height = lineMetrics.height * n + 8;
			_height = info.height - 8;
			update();
		}
		
		/* Draws a background coloured alpha shape over a line of text.
		 * requires that disabledShape.graphics.clear() be called first
		 * because you may want to shadow out multiple lines
		 */
		public function setDisabledLine(n:int):void{
			disabledShape.graphics.beginFill(backgroundCol, 0.5);
			disabledShape.graphics.drawRect(
				1,
				lineMetrics.height * n + (n == 0 ? 1 : 0),
				_width - 2,
				lineMetrics.height + (n == lines - 1 ? -1 : 0)
			);
			disabledShape.graphics.endFill();
		}
		
		public function update():void{
			graphics.clear();
			graphics.drawRect(0, 0, _width, _height);
			
			infoMask.graphics.clear();
			infoMask.graphics.beginFill(0xFF0000);
			infoMask.graphics.drawRect(0, 0, _width, _height);
			infoMask.graphics.endFill();
			backShape.graphics.clear();
			if(backgroundAlpha < 1.0){
				backShape.graphics.beginFill(borderCol);
				backShape.graphics.drawRect(0, 0, _width, 1);
				backShape.graphics.endFill();
				backShape.graphics.beginFill(borderCol);
				backShape.graphics.drawRect(0, _height - 1, _width, 1);
				backShape.graphics.endFill();
				backShape.graphics.beginFill(borderCol);
				backShape.graphics.drawRect(0, 0, 1, _height);
				backShape.graphics.endFill();
				backShape.graphics.beginFill(borderCol);
				backShape.graphics.drawRect(_width - 1, 0, 1, _height);
				backShape.graphics.endFill();
			} else {
				backShape.graphics.beginFill(borderCol);
				backShape.graphics.drawRect(0, 0, _width, _height);
			}
			
			backShape.graphics.beginFill(backgroundCol, backgroundAlpha);
			backShape.graphics.drawRect(1, 1, _width-2, _height-2);
			backShape.graphics.endFill();
		}
		
	}

}