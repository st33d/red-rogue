package com.robotacid.util{
	
	/* Compresses strings using the Lempel-Ziv-Welch algorithm
	 *
	 * Compresses strings up to a 5th of their original size, though RLE compression is recommended beforehand
	 * as that cuts size down to a 10th, so in combination they're quite the team
	 *
	 * Bewarned that the output is in unicode format and if saved in a text file, the text file must be a unicode
	 * text file. An ansi text file will garble the data
	 *
	 * I found the AS2 version of this algorithm at
	 *
	 * http://www.razorberry.com/blog/archives/2004/08/22/lzw-compression-methods-in-as2/
	 *
	 * And someone in the comments had done an AS3 version - which is the version you're looking at now
	 * (albeit slightly tweaked because I don't see the point in it not being a static method)
	 *
	 * http://ascrypt3.riaforge.org/
	 *
	 * although I think the site for it has gone down since I downloaded it :(
	 */

	public class LZW {

		/* Change this variable to output an xml safe string */
		public static var xmlsafe:Boolean = true;
		
		
		public static function compress(str:String):String
		{
			var dico:Array = [];
			var skipnum:Number = xmlsafe?5:0;
			
			// JH dotComIt 1/9/07 specified declaration of loop variable outside of loops
			var i:int;
			
			for (i = 0; i < 256; i++)
			{
				dico[String.fromCharCode(i)] = i;
			}
			if (xmlsafe)
			{
				dico["<"] = 256;
				dico[">"] = 257;
				dico["&"] = 258;
				dico["\""] = 259;
				dico["'"] = 260;
			}
			var res:String = "";
			var txt2encode:String = str;
			var splitStr:Array = txt2encode.split("");
			var len:Number = splitStr.length;
			var nbChar:Number = 256+skipnum;
			var buffer:String = "";

			// JH DotComit 1/9/07 added current declaration
			var current:String;
			for (i = 0; i <= len; i++)
			{
				// JH DotComit 1/9/07 removed var
				current = splitStr[i];
				if (dico[buffer + current] !== undefined)
				{
					buffer += current;
				}
				else
				{
					res += String.fromCharCode(dico[buffer]);
					dico[buffer + current] = nbChar;
					nbChar++;
					buffer = current;
				}
			}
			return res;
		}
		
		// JH dotComIT 1/9/07 removed static
		public static function uncompress(str:String):String
		{
			var dico:Array = [];
			var skipnum:Number = xmlsafe?5:0;
			
			// JH DotComIt
			var i:int;
			
			for (i = 0; i < 256; i++)
			{
				var c:String = String.fromCharCode(i);
				dico[i] = c;
			}
			if (xmlsafe)
			{
				dico[256] = "<";
				dico[257] = ">";
				dico[258] = "&";
				dico[259] = "\"";
				dico[260] = "'";
			}
			var txt2encode:String = str;
			var splitStr:Array = txt2encode.split("");
			var length:Number = splitStr.length;
			var nbChar:Number = 256+skipnum;
			var buffer:String = "";
			var chaine:String = "";
			var result:String = "";
			for (i = 0; i < length; i++)
			{
				var code:Number = txt2encode.charCodeAt(i);
				var current:String = dico[code];
				if (buffer == "")
				{
					buffer = current;
					result += current;
				}
				else
				{
					if (code <= 255+skipnum)
					{
						result += current;
						chaine = buffer + current;
						dico[nbChar] = chaine;
						nbChar++;
						buffer = current;
					}
					else
					{
						chaine = dico[code];
						// JH DotComIt 1/9/07 changed from undefiend to null
						
						if (chaine == null) {
							chaine = buffer + buffer.slice(0,1);
						}
						result += chaine;
						dico[nbChar] = buffer + chaine.slice(0, 1);
						nbChar++;
						buffer = chaine;
						
					}
				}
			}
			return result;
		}
	}
}