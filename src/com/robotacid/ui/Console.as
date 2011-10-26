package com.robotacid.ui {
	import com.robotacid.ui.TextBox;
	import flash.external.ExternalInterface;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class Console extends TextBox{
		
		public var maxLines:int;
		
		public function Console(_width:Number, _height:Number, maxLines:int, backgroundCol:uint = 0xFF111111, borderCol:uint = 0xFF999999, fontCol:uint = 0xFFDDDDDD) {
			super(_width, _height, backgroundCol, borderCol, fontCol);
			this.maxLines = maxLines;
			wordWrap = false;
		}
		
		public function print(str:String):void{
			// catch multiple lines here, split and recurse
			str = str.toUpperCase();
			if(str.indexOf("\n") > -1){
				var printList:Array = str.split("\n");
				while(printList.length) print(printList.shift());
				return;
			}
			_text += (_text.length > 0 ? "\n" : "") + str;
			var consoleLines:int = _text.split("\n").length;
			if(consoleLines > maxLines){
				_text = _text.substr(_text.indexOf("\n") + 1);
			}
			updateText();
			draw();
			try{
				ExternalInterface.call("printToLog", str);
			}catch(e:Error){}
		}
		
		
	}

}