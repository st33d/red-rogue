package com.robotacid.util.array {
	/**
	 * Returns a string representing a series of nested arrays as nested arrays
	 * 
	 * eg:
	 * 
	 * "2,3,4,(1,2,3,4,(1,2),2),3,(4,5,6),((12,3,23),2,1),4"
	 * 
	 * returns:
	 * 
	 * [2, 3, 4, [1, 2, 3, 4, [1, 2], 2], 3, [4, 5, 6], [[12, 3, 23], 2, 1], 4]
	 * 
	 * uses code that grapefrukt off of TIGSource forums came up with:
	 * 
	 * http://forums.tigsource.com/index.php?topic=13022.0
	 * http://wonderfl.net/c/7B1c
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
		
	public function getParams(str:String):Array{
		var data:Array = [];
		parseFragment(str, 0, data);
		return data;
	}

}
	
function parseFragment(fragment:String, startIndex:int, dataArray:Array):int {
	var result      :Array = [];
	var endIndex    :int = startIndex;
	
	while(endIndex <= fragment.length){
		var char:String = fragment.charAt(endIndex);
		if(char == "("){ 
			parseSimple(fragment.substring(startIndex, endIndex), dataArray);
			var subArray:Array = [];
			dataArray.push(subArray);
			startIndex = parseFragment(fragment, endIndex + 1, subArray);
			endIndex = startIndex;
		} else if ( char == ")"){
			parseSimple(fragment.substring(startIndex, endIndex), dataArray);
			return endIndex + 1;
		} else if( endIndex == fragment.length - 1){
			parseSimple(fragment.substring(startIndex, endIndex + 1), dataArray);
			return endIndex + 1;
		}
		endIndex++;
	}
	return endIndex;
}

function parseSimple(fragment:String, dataArray:Array):void{
	var split:Array = fragment.split(",");
	for ( var i:int = 0; i < split.length; i++) if(parseFloat(split[i])) dataArray.push(split[i]);
}