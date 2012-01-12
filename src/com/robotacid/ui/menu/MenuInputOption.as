package com.robotacid.ui.menu {
	/**
	 * An option that allows a user to enter data
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class MenuInputOption extends MenuOption{
		
		public var charsAllowed:RegExp;
		public var charLimit:int;
		public var newLineFinish:Boolean;
		public var inputCallback:Function;
		public var defaultName:String;
		public var promptName:String;
		public var input:String;
		
		public function MenuInputOption(name:String, charsAllowed:RegExp, charLimit:int, inputCallback:Function, newLineFinish:Boolean = true, active:Boolean = true) {
			super(name, null, active);
			this.charsAllowed = charsAllowed;
			this.charLimit = charLimit;
			this.newLineFinish = newLineFinish;
			this.inputCallback = inputCallback;
			defaultName = name;
			promptName = "enter value";
			input = "";
			recordable = false;
		}
		
		public function addChar(char:String):void{
			if(char.search(charsAllowed) > -1){
				input += char;
			}
		}
		
	}

}