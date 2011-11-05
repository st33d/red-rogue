package com.robotacid.engine {
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	/**
	 * Item container
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Chest extends Entity{
		
		public var twinkleCount:int;
		public var rect:Rectangle;
		public var contents:Vector.<Item>;
		
		public static const TWINKLE_DELAY:int = 20;
		public static const OPEN_ID:int = 53;
		
		public function Chest(mc:DisplayObject, x:Number, y:Number, items:Vector.<Item>) {
			super(mc, false, false);
			
			mc.x = x;
			mc.y = y;
			
			mapX = x * Game.INV_SCALE;
			mapY = y * Game.INV_SCALE;
			
			// for the sake of brevity - an open chest is an empty chest
			if(items){
				contents = items;
				rect = mc.getBounds(mc);
				rect.x += x;
				rect.y += y;
				callMain = true;
			}
			(mc as MovieClip).gotoAndStop(contents ? "closed" : "open");
		}
		
		override public function main():void {
			// concealing the twinkle in the dark will help avoid showing a clipped effect on the edge
			// of the light map
			if(g.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000){
				// create a twinkle twinkle effect so the player knows this is a collectable
				if(twinkleCount-- <= 0){
					renderer.addFX(rect.x + g.random.range(rect.width), rect.y + g.random.range(rect.height), renderer.twinkleBlit);
					twinkleCount = TWINKLE_DELAY + g.random.range(TWINKLE_DELAY);
				}
			}
			
			// check for collection by player
			if((g.player.actions & Collider.UP) && rect.intersects(g.player.collider) && !g.player.indifferent){
				collect(g.player);
			}
		}
		
		public function collect(character:Character):void{
			(gfx as MovieClip).gotoAndStop("open");
			tileId = ""+OPEN_ID;
			for(var i:int = 0; i < contents.length; i++){
				character.loot.push(contents[i]);
				if(character is Player){
					g.menu.inventoryList.addItem(contents[i]);
					g.console.print("picked up " + contents[i].nameToString());
				}
			}
			g.soundQueue.add("chestOpen");
			contents = null;
			callMain = false;
		}
		
		override public function nameToString():String {
			var str:String = "";
			if(contents){
				for(var i:int = 0; i < contents.length; i++){
					str += contents[i].nameToString();
					if(i < contents.length - 1){
						str += "\nand ";
					}
				}
			}
			return str;
		}
		
		override public function remove():void {
			super.remove();
			var n:int = g.items.indexOf(this);
			if(n > -1) g.items.splice(n, 1);
		}
		
		override public function toXML():XML {
			if(contents){
				var xml:XML = <chest />;
				for(var i:int = 0; i < contents.length; i++){
					xml.appendChild(contents[i].toXML());
				}
				return xml;
			}
			return null;
			
		}
		
	}

}