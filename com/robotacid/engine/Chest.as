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
		
		public var twinkle_count:int;
		public var contents:Vector.<Item>;
		
		public static const TWINKLE_DELAY:int = 20;
		public static const OPEN_ID:int = 53;
		
		public function Chest(mc:DisplayObject, g:Game, open:Boolean = false) {
			super(mc, g, false, true);
			
			var bounds:Rectangle = mc.getBounds(mc);
			//mc.x += -bounds.left;
			//mc.y += -bounds.top;
			x = mc.x;
			y = mc.y;
			// for the sake of brevity - an open chest is an empty chest
			if(!open){
				contents = new Vector.<Item>();
				g.items.push(this);
				bounds = mc.getBounds(g.canvas);
				rect = new Rect(bounds.left, bounds.top, bounds.width, bounds.height);
				call_main = true;
				
				fill();
			}
			(mc as MovieClip).gotoAndStop(open ? "open" : "closed");
		}
		
		override public function main():void {
			// concealing the twinkle in the dark will help avoid showing a clipped effect on the edge
			// of the light map
			if(g.light_map.dark_image.getPixel32(map_x, map_y) != 0xFF000000){
				// create a twinkle twinkle effect so the player knows this is a collectable
				if(twinkle_count-- <= 0){
					g.addFX(rect.x + Math.random() * rect.width, rect.y + Math.random() * rect.height, g.twinkle_bc, g.back_fx_image, g.back_fx_image_holder);
					twinkle_count = TWINKLE_DELAY + Math.random() * TWINKLE_DELAY;
				}
			}
		}
		
		public function collect(character:Character):void{
			(mc as MovieClip).gotoAndStop("open");
			tile_id = ""+OPEN_ID;
			for(var i:int = 0; i < contents.length; i++){
				character.loot.push(contents[i]);
				if(character is Player){
					g.menu.inventory_list.addItem(contents[i]);
				}
			}
			SoundManager.playSound(g.library.ChestOpenSound);
			contents = null;
			call_main = false;
			var n:int = g.items.indexOf(this);
			if(n > -1) g.items.splice(n, 1);
		}
		
		public function fill():void{
			var item:Item
			//item = new Item(new g.library.BowMC(), Item.BOW, Item.WEAPON, 0, null, g);
			item = new Item(new g.library.RuneMC(), Math.random() * 7, Item.RUNE, 0, g);
			//item = new Item(new g.library.RuneMC(), Item.HEAL, Item.RUNE, 0, g);
			contents.push(item);
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