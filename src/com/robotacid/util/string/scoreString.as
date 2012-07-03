package com.robotacid.util.string {
	
	/* Convert a number to a string with a minimum number of trailing zeros */
	public function scoreString(score:int, digits:int):String{
		var string:String = score.toString();
		while(string.length < digits){
			string = "0" + string;
		}
		return string;
	}

}