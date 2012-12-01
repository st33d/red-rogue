package com.robotacid.ui.menu {
	/**
	 * An option that allows a user to enter data
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class MenuInputList extends MenuList{
		
		public var option:MenuOption;
		public var charsAllowed:RegExp;
		public var charLimit:int;
		public var newLineFinish:Boolean;
		public var inputCallback:Function;
		public var promptName:String;
		public var input:String;
		public var done:Boolean;
		
		private var firstInput:Boolean;
		
		public function MenuInputList(name:String, charsAllowed:RegExp, charLimit:int, inputCallback:Function, newLineFinish:Boolean = true) {
			option = new MenuOption(name);
			super(Vector.<MenuOption>([option]));
			this.charsAllowed = charsAllowed;
			this.charLimit = charLimit;
			this.inputCallback = inputCallback;
			this.newLineFinish = newLineFinish;
			promptName = "enter value";
			input = "";
			option.recordable = false;
			firstInput = false;
		}
		
		public function begin():void{
			option.name = promptName;
			input = "";
			done = false;
		}
		
		public function addChar(char:String):void{
			if(char.search(charsAllowed) > -1){
				input += char;
				option.name = input;
				if(input.length >= charLimit){
					finish();
				}
			}
		}
		
		public function removeChar():void{
			if(input.length){
				input = input.substr(0, input.length - 1);
				option.name = input;
			}
		}
		
		public function finish():void{
			inputCallback(this);
			done = true;
		}
		
	}

}