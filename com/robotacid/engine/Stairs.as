package com.robotacid.engine {
	import com.robotacid.engine.Entity;
	import com.robotacid.geom.Rect;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	
	/**
	 * A trap style entity that allows access to the next/previous level
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Stairs extends Entity{
		
		public var type:int;
		public var contact:Boolean;
		public var mask:Bitmap;
		public var seen:Boolean;
		
		public static const UP:int = 0;
		public static const DOWN:int = 1;
		
		/* This variable tells me whether the player was heading up or down stairs when entering
		 * the level */
		public static var last_stairs_used_type:int = DOWN;
		
		public function Stairs(mc:DisplayObject, type:int, g:Game) {
			super(mc, g);
			this.type = type;
			rect = new Rect(x, y, SCALE, SCALE);
			call_main = true;
			contact = false;
			mask = new g.library.StairsMaskB();
			mask.x = mc.x;
			mask.y = mc.y;
			mask.cacheAsBitmap = true;
			if(type != last_stairs_used_type) g.entrance = this;
			seen = false;
		}
		
		override public function main():void {
			if(rect.intersects(g.player.rect) && g.player.state == Character.WALKING){
				if(!contact){
					contact = true;
					g.menu.stairs_option.active = true;
					g.menu.go_up_down_option.state = type;
					g.menu.selection = g.menu.selection;
					g.menu.go_up_down_option.target = this;
				}
			} else if(contact){
				contact = false;
				g.menu.stairs_option.active = false;
				if(g.menu.current_menu_list == g.menu.stairs_list) g.menu.stepBack();
				g.menu.selection = g.menu.selection;
			}
			// if the stairs are visible on the map - then make the stairs icon on the map visible
			if(!seen && g.light_map.dark_image.getPixel32(map_x, map_y) != 0xFF000000){
				seen = true;
				if(type == UP){
					g.mini_map.stairs_up.visible = true;
					g.mini_map.stairs_up.x = map_x - 1;
					g.mini_map.stairs_up.y = map_y - 1;
				} else if(type == DOWN){
					g.mini_map.stairs_down.visible = true;
					g.mini_map.stairs_down.x = map_x - 1;
					g.mini_map.stairs_down.y = map_y - 1;
				}
			}
			//rect.draw(Game.debug);
		}
	}

}