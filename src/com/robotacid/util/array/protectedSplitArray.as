package com.robotacid.util.array {
	/**
	 * Takes a string representation of an array that has nested arrays within it
	 *
	 * These nested arrays must be contained within enclosing characters such as parenthesis ()
	 *
	 * eg: [1, 2, 3, 4, (1, 2, 3, 4), 5, 6] with the regex: /\([^\(\)]+\)/g
	 *
	 * This method would return the example as a single dimensional array with (1, 2, 3, 4) intact as one of the array members
	 * This allows lisp style instruction sets to be written as strings and subsequently parsed into arrays
	 *
	 * The protection of nested arrays requires replacing them with a token character during the splitting phase and then
	 * restoring that token
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public function protectedSplitArray(str:String, regex:RegExp, token:String = "*", separator:String = ","):Array {
		
		var protect:Array = str.match(regex);
		str = str.replace(regex, token);
		
		var list:Array = str.split(separator);
		
		for(var i:int = 0; i < list.length; i++){
			// restore protected string portions if present
			if(protect && protect.length){
				if(list[i].indexOf(token) > -1){
					list[i] = list[i].replace(token, protect.shift());
				}
			} else break;
		}
		
		return list;
	}

}