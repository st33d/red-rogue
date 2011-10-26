package com.robotacid.util {
	
	/**
	 * Converts arrays to Run Length Encoded strings and back
	 *
	 * This method of compression cuts file size down to up to 10% of the original size
	 *
	 * @author Aaron Steed robotacid.com
	 */
	public class RLE {
		
		/* Convert an array to a RLE compressed String
		 * index is the character or string that sits between an item and its repetitions
		 * separator is the character or string that marks the boundary between each array item
		 */
		public static function compress(list:Array, index:String = ":", separator:String = ","):String {
			var string:String = "";
			var count:Number = 0;
			for(var i:int = 0; i < list.length; i++){
				count ++;
				if(list[i] != list[i+1]) {
					string += list[i];
					if(count > 1) string += index + count;
					if(i < list.length-1) string += separator;
					count = 0;
				}
			}
			return string;
		}
		/* Uncompress an RLE String
		 * index is the character or string that sits between an item and its repetitions
		 * separator is the character or string that marks the boundary between each array item
		 *
		 * The match RegExp protects portions of the string that contain separators that should be ignored by
		 * replacing them with the marker string and then swapping them back in during decompression
		 *
		 * Why not use a different separator you say? Because if I'd've realised the monumental cock up I'd made
		 * by using the same separator in parts of the compressed string I wanted to protect before I'd made 30 levels
		 * then I'd be using a different bloody separator
		 */
		public static function uncompress(string:String, index:String = ":", separator:String = ",", match:RegExp = null, marker:String = "*"):Array{
			var protect:Array;
			if(match){
				protect = string.match(match);
				string = string.replace(match, marker);
			}
			var array:Array = [];
			var list:Array = string.split(separator);
			for(var i:int = 0; i < list.length; i++){
				// restore protected string portions if present
				if(protect){
					if(list[i].indexOf(marker) > -1){
						list[i] = list[i].replace(marker, protect.shift());
					}
				}
				if(list[i].indexOf(index) > -1){
					var compound:Array = list[i].split(index);
					var num:int = int(compound[1])
					for(var j:int = 0; j < num; j++){
						array.push(compound[0]);
					}
				} else {
					array.push(list[i]);
				}
			}
			return array;
		}
		
	}
	
}