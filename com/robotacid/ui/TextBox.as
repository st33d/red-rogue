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
		public var info_mask:Shape;
		public var back_shape:Shape;
		public var disabled_shape:Shape;
		public var line_metrics:TextLineMetrics;
		public var fixed_height:Boolean;
		
		public var background_col:uint;
		public var border_col:uint;
		public var font_col:uint;
		public var background_alpha:Number;
		
		public var max_lines:int;
		
		public function TextBox(_width:Number, line_height:int, background_col:uint = 0x111111, border_col:uint = 0x999999, font_col:uint = 0xDDDDDD, background_alpha:Number = 1.0) {
			this._width = _width;
			this.background_col = background_col;
			this.border_col = border_col;
			this.font_col = font_col;
			this.background_alpha = background_alpha;
			back_shape = new Shape();
			addChild(back_shape);
			info = new TextField();
			info.x = 1;
			info.y = -3;
			info.width = _width-2;
			addChild(info);
			info.embedFonts = true;
			info.antiAliasType = AntiAliasType.NORMAL;
			info.gridFitType = GridFitType.PIXEL;
			var tf:TextFormat = new TextFormat("quadratis", 8, font_col);
			//tf.letterSpacing = -1;
			info.defaultTextFormat = tf;
			info.selectable = false;
			info.text = _text = "";
			info.wordWrap = false;
			info.autoSize = "none";
			line_metrics = info.getLineMetrics(0);
			lines = 0;
			fixed_height = false;
			info_mask = new Shape();
			//addChild(info_mask);
			//info.mask = info_mask;
			
			disabled_shape = new Shape();
			addChild(disabled_shape);
			
			setLineHeight(line_height);
		}
		
		public function set text(str:String):void{
			_text = str;
			if(!fixed_height){
				lines = str.split("\n").length;
				setLineHeight(lines);
			}
			info.text = _text;
		}
		
		public function get text():String{
			return _text;
		}
		
		public function setLineHeight(n:int):void{
			info.height = line_metrics.height * n + 8;
			_height = info.height - 8;
			update();
		}
		
		/* Draws a background coloured alpha shape over a line of text.
		 * requires that disabled_shape.graphics.clear() be called first
		 * because you may want to shadow out multiple lines
		 */
		public function setDisabledLine(n:int):void{
			disabled_shape.graphics.beginFill(background_col, 0.5);
			disabled_shape.graphics.drawRect(
				1,
				line_metrics.height * n + (n == 0 ? 1 : 0),
				_width - 2,
				line_metrics.height + (n == lines - 1 ? -1 : 0)
			);
			disabled_shape.graphics.endFill();
		}
		
		public function update():void{
			graphics.clear();
			graphics.drawRect(0, 0, _width, _height);
			
			info_mask.graphics.clear();
			info_mask.graphics.beginFill(0xFF0000);
			info_mask.graphics.drawRect(0, 0, _width, _height);
			info_mask.graphics.endFill();
			back_shape.graphics.clear();
			if(background_alpha < 1.0){
				back_shape.graphics.beginFill(border_col);
				back_shape.graphics.drawRect(0, 0, _width, 1);
				back_shape.graphics.endFill();
				back_shape.graphics.beginFill(border_col);
				back_shape.graphics.drawRect(0, _height - 1, _width, 1);
				back_shape.graphics.endFill();
				back_shape.graphics.beginFill(border_col);
				back_shape.graphics.drawRect(0, 0, 1, _height);
				back_shape.graphics.endFill();
				back_shape.graphics.beginFill(border_col);
				back_shape.graphics.drawRect(_width - 1, 0, 1, _height);
				back_shape.graphics.endFill();
			} else {
				back_shape.graphics.beginFill(border_col);
				back_shape.graphics.drawRect(0, 0, _width, _height);
			}
			
			back_shape.graphics.beginFill(background_col, background_alpha);
			back_shape.graphics.drawRect(1, 1, _width-2, _height-2);
			back_shape.graphics.endFill();
		}
		
	}

}