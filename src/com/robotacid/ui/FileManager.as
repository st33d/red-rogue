package com.robotacid.ui {
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.ui.Mouse;
	import flash.utils.ByteArray;
	/**
	 * Provides a wrapper for FileReference functionality
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class FileManager{
		
		private static var fileReference:FileReference = new FileReference();
		
		public static var mouseHide:Boolean = false;
		public static var name:String;
		public static var data:ByteArray;
		
		private static var _selectionCallback:Function;
		private static var _completionCallback:Function;
		private static var _errorCallback:Function;
		
		public static const XML_FILTER:FileFilter = new FileFilter("XML", "*.xml");
		public static const PNG_FILTER:FileFilter = new FileFilter("Images", "*.png;");
		public static const JSON_FILTER:FileFilter = new FileFilter("JSON", "*.json;");
		public static const DAT_FILTER:FileFilter = new FileFilter("DAT", "*.dat;");
		
		/* Saves a file via FileReference */
		public static function save(data:*, defaultFileName:String):void{
			fileReference.addEventListener(Event.SELECT, cancelFile);
			fileReference.addEventListener(Event.CANCEL, cancelFile);
			fileReference.save(data, defaultFileName);
		}
		
		/* Loads a file via FileReference
		 *
		 * The result is put into the "data" property of this class */
		public static function load(completionCallBack:Function, selectionCallback:Function = null, fileFilters:Array = null, errorCallback:Function = null):void{
			data = null;
			name = null;
			_selectionCallback = selectionCallback;
			_completionCallback = completionCallBack;
			_errorCallback = errorCallback;
			fileReference.addEventListener(Event.SELECT, fileSelected);
			fileReference.addEventListener(Event.CANCEL, cancelFile);
			fileReference.browse(fileFilters);
		}
		
		/* FileReference events */
		private static function fileSelected(e:Event):void{
			// fileReference makes the mouse reappear if hidden
			if(mouseHide) Mouse.hide();
			try{
				name = fileReference.name;
			}catch(e:Error){
				name = null;
			}
			if(Boolean(_selectionCallback)) _selectionCallback();
			fileReference.removeEventListener(Event.SELECT, fileSelected);
			fileReference.removeEventListener(Event.CANCEL, cancelFile);
			fileReference.addEventListener(IOErrorEvent.IO_ERROR, ioError);
			fileReference.addEventListener(Event.COMPLETE, loadComplete);
			fileReference.load();
		}
		private static function cancelFile(e:Event):void{
			// fileReference makes the mouse reappear if hidden
			if(mouseHide) Mouse.hide();
			fileReference.removeEventListener(Event.SELECT, fileSelected);
			fileReference.removeEventListener(Event.CANCEL, cancelFile);
		}
		private static function loadComplete(e:Event):void{
			fileReference.removeEventListener(Event.COMPLETE, loadComplete);
			data = fileReference.data;
			if(Boolean(_completionCallback)) _completionCallback();
		}
		private static function ioError(e:IOErrorEvent):void{
			trace(e.toString());
			fileReference.removeEventListener(Event.COMPLETE, loadComplete);
			fileReference.removeEventListener(IOErrorEvent.IO_ERROR, ioError);
			if(Boolean(_errorCallback)) _errorCallback();
			
		}
		
	}

}