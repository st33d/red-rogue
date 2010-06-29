package com.robotacid.engine {
	import com.robotacid.geom.Rect;
	import com.robotacid.sound.SoundManager;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class Chest extends Entity{
		
		public var twinkleCount:int;
		public var contents:Vector.<Item>;
		
		public static const TWINKLE_DELAY:int = 20;
		public static const OPEN_ID:int = 53;
		
		public function Chest(mc:DisplayObject, items:Vector.<Item>, g:Game, open:Boolean = false) {
			super(mc, g, false, false);
			
			var bounds:Rectangle = mc.getBounds(mc);
			//mc.x += -bounds.left;
			//mc.y += -bounds.top;
			x = mc.x;
			y = mc.y;
			// for the sake of brevity - an open chest is an empty chest
			if(!open){
				contents = items;
				//g.items.push(this);
				bounds = mc.getBounds(mc);
				rect = new Rect(x + bounds.left, y + bounds.top, bounds.width, bounds.height);
				callMain = true;
			}
			(mc as MovieClip).gotoAndStop(open ? "open" : "closed");
		}
		
		override public function main():void {
			// concealing the twinkle in the dark will help avoid showing a clipped effect on the edge
			// of the light map
			if(g.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000){
				// create a twinkle twinkle effect so the player knows this is a collectable
				if(twinkleCount-- <= 0){
					g.addFX(rect.x + Math.random() * rect.width, rect.y + Math.random() * rect.height, g.twinkleBc, g.backFxImage, g.backFxImageHolder);
					twinkleCount = TWINKLE_DELAY + Math.random() * TWINKLE_DELAY;
				}
			}
		}
		
		public function collect(character:Character):void{
			(mc as MovieClip).gotoAndStop("open");
			tileId = ""+OPEN_ID;
			for(var i:int = 0; i < contents.length; i++){
				character.loot.push(contents[i]);
				if(character is Player){
					g.menu.inventoryList.addItem(contents[i]);
				}
			}
			SoundManager.playSound(g.library.ChestOpenSound);
			contents = null;
			callMain = false;
			var n:int = g.items.indexOf(this);
			if(n > -1) g.items.splice(n, 1);
		}
		
		override public function nameToString():String {
			var str:String = "";
			if(contents){
				for(var i:int = 0; i < contents.length; i++){
					str += contents[i].nameToString();
					if(i < contents.length - 1){
						str += "\n";
					}
				}
			}
			return str;
		}
		
	}

}