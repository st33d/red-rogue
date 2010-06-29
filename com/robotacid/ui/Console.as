package com.robotacid.ui {
	import com.robotacid.ui.TextBox;
	import flash.external.ExternalInterface;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class Console extends TextBox{
		
		public function Console(_width:Number, line_height:int, backgroundCol:uint = 0x111111, borderCol:uint = 0x999999, fontCol:uint = 0xDDDDDD) {
			super(_width, line_height, backgroundCol, borderCol, fontCol);
		}
		
		public function print(str:String):void{
			// catch multiple lines here, split and recurse
			if(str.indexOf("\n") > -1){
				var printList:Array = str.split("\n");
				while(printList.length) print(printList.shift());
				return;
			}
			if(lines >= maxLines){
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