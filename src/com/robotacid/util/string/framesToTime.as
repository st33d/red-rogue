package com.robotacid.util.string {
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	
	public function framesToTime(frames:int, fps:int):String{
		var seconds:int = frames / fps;
		var minutes:int = seconds / 60;
		var hours:int = minutes / 60;
		return hours + ":" + (minutes < 10 ? "0" + minutes : minutes) + ":" + (seconds < 10 ? "0" + seconds : seconds);
	}

}