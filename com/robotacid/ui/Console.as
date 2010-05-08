package com.robotacid.ui {
	import com.robotacid.ui.TextBox;
	import flash.external.ExternalInterface;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class Console extends TextBox{
		
		public function Console(_width:Number, line_height:int, background_col:uint = 0x111111, border_col:uint = 0x999999, font_col:uint = 0xDDDDDD) {
			super(_width, line_height, background_col, border_col, font_col);
		}
		
		public function print(str:String):void{
			if(lines >= max_lines){
				_text = _text.substr(_text.indexOf("\n") + 1);
				lines--;
			}
			_text += (lines > 0 ? "\n" : "") + str;
			info.text = _text;
			lines++;
			try{
				ExternalInterface.call("printToLog", str);
			}catch(e:Error){}
		}
		
		
	}

}