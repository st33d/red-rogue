package com.robotacid.gfx {
    import flash.display.Loader;
    import flash.geom.Rectangle;
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.utils.ByteArray;
    import flash.events.Event;
    import flash.display.LoaderInfo;
    import flash.display.Loader;
	
	/**
	 * Encodes and decodes PNGs,
	 *
	 * Based on the Adobe class for this task with the additional ability to encode meta-data in the image file that
	 * will not affect the image. The PNG file format comes with a number of informational data chunks that can be
	 * legally filled with data so we're using the tEXt chunk which accepts key:value pairs for storage.
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	
	public class PNGEncoder{

		public static var bitmapData:BitmapData;
		public static var metaData:Object;
		private static var _decodeCompleteCallBack:Function;
		
        public static const CHAR_SET:String = "iso-8859-1";
        public static const IDAT_ID:uint = 0x49444154;
        public static const tEXt_ID:uint = 0x74455874;
		
		public function PNGEncoder(){
			
		}
		
		/* Loads the bitmapData and metaData properties of this class with the data in png */
		public static function decode(png:ByteArray, decodeCompleteCallBack:Function = null):void{
            var loader:Loader = new Loader();
			_decodeCompleteCallBack = decodeCompleteCallBack;
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, contentLoaderComplete);
            loader.loadBytes(png);
			metaData = getMetaData(png);
		}

        private static function contentLoaderComplete(e:Event):void{
            var loaderInfo:LoaderInfo = (e.target as LoaderInfo);
            loaderInfo.removeEventListener(Event.COMPLETE, contentLoaderComplete);
			var bitmap:Bitmap = loaderInfo.content as Bitmap;
			if(bitmap) bitmapData = bitmap.bitmapData;
			else bitmapData = null;
			if(Boolean(_decodeCompleteCallBack)) _decodeCompleteCallBack();
        }
		
        /* Reads metadata from a png ByteArray, then returns an object loaded with the data
		 *
		 * Unlike the rest of this class, I had to write this myself. That was a long evening. */
        public static function getMetaData(png:ByteArray):Object{
            var metaData:Object = {};
            var i:int, j:int, key:String, value:String;
            for(i = 0; i < png.length - 4; i++){
                png.position = i;
                // look for the tEXt chunk type
                if(png.readUnsignedInt() == tEXt_ID){
                    // chunks are broken into length, type, data and CRC
                    // we've stopped at the type, wind back to get the length
                    png.position = i - 4;
                    var totalLength:int = png.readUnsignedInt();
                    // the key/value is broken with a single 0x0 byte
                    var keyLength:int = 0;
                    for(j = 0; j < totalLength; j++){
                        png.position = i + 4 + j;
                        if(png.readByte() == 0x0){
                            keyLength = j;
                            break;
                        }
                    }
                    // capture the key
                    png.position = i + 4;
                    key = png.readMultiByte(keyLength, CHAR_SET);
                    // capture the value
                    png.position = i + 4 + keyLength + 1;
                    value = png.readMultiByte(totalLength - (keyLength + 1), CHAR_SET);
                    metaData[key] = value;
                }
                // quit searching once the IDAT chunk is encountered
                // pngs encoded by this class store the metadata before the IDAT
                if(png.readUnsignedInt() == IDAT_ID){
                    break;
                }
            }
            return metaData;
        }

        public static function encode(img:BitmapData, meta:Object = null):ByteArray {
            // Create output byte array
            var png:ByteArray = new ByteArray();
            // Write PNG signature
            png.writeUnsignedInt(0x89504e47);
            png.writeUnsignedInt(0x0D0A1A0A);
            // Build IHDR chunk
            var IHDR:ByteArray = new ByteArray();
            IHDR.writeInt(img.width);
            IHDR.writeInt(img.height);
            IHDR.writeUnsignedInt(0x08060000); // 32bit RGBA
            IHDR.writeByte(0);
            writeChunk(png,0x49484452,IHDR);

            // meta data insertion
            for (var k:String in meta){
               writeChunk_tEXt(png, k, meta[k]);
            }

            // Build IDAT chunk
            var IDAT:ByteArray= new ByteArray();
            for(var i:int = 0; i < img.height; i++){
                // no filter
                IDAT.writeByte(0);
                var p:uint;
                var j:int;
                if(!img.transparent){
                    for(j = 0; j < img.width; j++){
                        p = img.getPixel(j,i);
                        IDAT.writeUnsignedInt(
                            uint(((p&0xFFFFFF) << 8)|0xFF));
                    }
                } else {
                    for(j = 0; j < img.width; j++){
                        p = img.getPixel32(j,i);
                        IDAT.writeUnsignedInt(
                            uint(((p&0xFFFFFF) << 8)|
                            (p>>>24)));
                    }
                }
            }
            IDAT.compress();
            writeChunk(png,0x49444154,IDAT);
            // Build IEND chunk
            writeChunk(png,0x49454E44,null);
            // return PNG

            return png;
        }

        private static var crcTable:Array;
        private static var crcTableComputed:Boolean = false;

        private static function writeChunk(png:ByteArray,
                type:uint, data:ByteArray):void{
            if(!crcTableComputed){
                crcTableComputed = true;
                crcTable = [];
                var c:uint;
                for(var n:uint = 0; n < 256; n++){
                    c = n;
                    for(var k:uint = 0; k < 8; k++){
                        if(c & 1){
                            c = uint(uint(0xedb88320) ^
                                uint(c >>> 1));
                        } else {
                            c = uint(c >>> 1);
                        }
                    }
                    crcTable[n] = c;
                }
            }
            var len:uint = 0;
            if(data != null){
                len = data.length;
            }
            png.writeUnsignedInt(len);
            var p:uint = png.position;
            png.writeUnsignedInt(type);
            if(data != null){
                png.writeBytes(data);
            }
            var e:uint = png.position;
            png.position = p;
            c = 0xffffffff;
            for(var i:int = 0; i < (e-p); i++){
                c = uint(crcTable[
                    (c ^ png.readUnsignedByte()) &
                    uint(0xff)] ^ uint(c >>> 8));
            }
            c = uint(c^uint(0xffffffff));
            png.position = e;
            png.writeUnsignedInt(c);
        }

        // from: http://blog.client9.com/2007/08/adding-metadata-to-actionscript-3-png.html

        // meta data can be viewed here: http://regex.info/exif.cgi

        /**
         * write out metadata using Latin1, uncompressed
         *
         * @param png The output bytearray
         * @param key the metadata key.  Must be in latin1, between 1-79 characters
         * @param value the metadata value.  Must be in latin1.
         *
         * the key or value is null or violates some contraints, the metadata
         *  is silently not added
         */
        private static function writeChunk_tEXt(png:ByteArray, key:String, value:String):void{
            if(key == null || key.length == 0 || key.length > 79){
                return;
            }
            if(value == null){
                value = "";
            }
            // the spec says this should be latin1,
            // but UTF8 is probably ok, but be care of overflows
            var tEXt:ByteArray = new ByteArray();
            tEXt.writeMultiByte(key, CHAR_SET);
            tEXt.writeByte(0x0);
            tEXt.writeMultiByte(value, CHAR_SET);
            writeChunk(png, tEXt_ID, tEXt);
        }

    }
}