package com.robotacid.gfx {
	import com.robotacid.geom.Dot;
	import com.robotacid.geom.Rect;
	import com.robotacid.ui.Key;
	import flash.display.Sprite;
	
	/**
	 * ...
	 * @author Aaron Steed, nitrome.com
	 */
	public class Camera {
		
		public var g:Game;
		public var canvas:Sprite;
		public var interpolation:Number = 0.2;
		public var scroll_target_x:Number, scroll_target_y:Number;
		public var last_canvas_x:Number, last_canvas_y:Number;
		public var virtual_canvas_x:Number, virtual_canvas_y:Number;
		public var last_virtual_canvas_x:Number, last_virtual_canvas_y:Number;
		public var scroll_x:Number, scroll_y:Number;
		public var scroll_rect:Rect;
		public var map_rect:Rect;
		public var view_width:Number;
		public var view_height:Number;
		
		public var count:int;
		public var delay_target:Dot;
		public var mouse_hidden:Boolean;
		public var scrolling:Boolean;
		public var scroll_focus:Dot;
		public var lock_out:Boolean;
		
		public var target_object:Dot;
		
		public static const SCROLL_PACE:Number = 0.5;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		
		public function Camera(g:Game, target_object:Dot, view_width:Number, view_height:Number) {
			this.g = g;
			this.target_object = target_object;
			this.view_width = view_width;
			this.view_height = view_height;
			this.canvas = g.canvas;
			map_rect = g.renderer.map_rect;
			scroll_rect = new Rect(60, 64, 200, 80);
			scroll_x = 0;
			scroll_y = scroll_rect.height * 0.5;
			scroll_target_x = -target_object.x+scroll_rect.x+scroll_x;
			scroll_target_y = -target_object.y+scroll_rect.y+scroll_y;
			scroll_target_x = Math.min(0, scroll_target_x);
			scroll_target_y = Math.min(0, scroll_target_y);
			scroll_target_x = Math.max(( -g.renderer.width * Game.SCALE) + view_width, scroll_target_x);
			scroll_target_y = Math.max(( -(g.renderer.height + 1) * Game.SCALE) + view_height, scroll_target_y);
			canvas.x = scroll_target_x >> 0;
			canvas.y = scroll_target_y >> 0;
			virtual_canvas_x = last_virtual_canvas_x = canvas.x;
			virtual_canvas_y = last_virtual_canvas_y = canvas.y;
			
			lock_out = false;
		}
		/* Update scrolling */
		public function main():void{
			if(count > 0){
				count--;
				if(count <= 0) setScrollTarget(delay_target.x, delay_target.y);
			}
			
			var looking:int = g.player.looking;
			if((looking & RIGHT) && scroll_x > 0) scroll_x -= SCROLL_PACE;
			if((looking & LEFT) && scroll_x < scroll_rect.width) scroll_x += SCROLL_PACE;
			if((looking & UP) && scroll_y < scroll_rect.height) scroll_y += SCROLL_PACE;
			else if((looking & DOWN) && scroll_y > 0) scroll_y -= SCROLL_PACE;
			else if(scroll_y > scroll_rect.height * 0.5) scroll_y -= SCROLL_PACE;
			else if(scroll_y < scroll_rect.height * 0.5) scroll_y += SCROLL_PACE;
			if((g.player.actions & RIGHT) && scroll_x > 0) scroll_x -= SCROLL_PACE * 2;
			if ((g.player.actions & LEFT) && scroll_x < scroll_rect.width) scroll_x += SCROLL_PACE * 2;
			// scroll down when down is pressed
			//if ((g.player.keys_pressed & DOWN) && scroll_y > 0) scroll_y -= 1;
			// scroll back to default when neither falling or down is pressed
			//if (!(g.player.keys_pressed & DOWN) && !(g.player.state == Character.FALLING) && scroll_y < scroll_rect.height) scroll_y += 1;
			
			scroll_target_x = -target_object.x + scroll_rect.x + scroll_x;
			scroll_target_y = -target_object.y + scroll_rect.y + scroll_y;
			/**/scroll_target_x = Math.min(0, scroll_target_x);
			scroll_target_y = Math.min(0, scroll_target_y);
			scroll_target_x = Math.max(( -g.renderer.width * Game.SCALE) + view_width, scroll_target_x);
			scroll_target_y = Math.max(( -(g.renderer.height+1) * Game.SCALE) + view_height, scroll_target_y);
			
			last_canvas_x = canvas.x;
			last_canvas_y = canvas.y;
			canvas.x += Math.round((scroll_target_x - canvas.x) * interpolation);
			canvas.y += Math.round((scroll_target_y - canvas.y) * interpolation);
			// the virtual canvas is where the canvas should precisely be if we weren't rounding off it's position
			// this helps scroll the background better when we move really slow
			last_virtual_canvas_x = virtual_canvas_x;
			last_virtual_canvas_y = virtual_canvas_y;
			virtual_canvas_x += canvas.x - last_canvas_x;
			virtual_canvas_y += canvas.y - last_canvas_y;
		}
		
		/* This sets where the screen will focus on - the coords are a point on the canvas you want centered on the map */
		public function setScrollTarget(x:Number, y:Number):void {
			scroll_target_x = (-x + view_width * 0.5) >> 0;
			scroll_target_y = (-y + view_height * 0.5) >> 0;
			scroll_target_x = Math.min(0, scroll_target_x);
			scroll_target_y = Math.min(0, scroll_target_y);
		}
		public function setDelayedScrollTarget(x:Number, y:Number, delay:int):void{
			delay_target = new Dot(x, y);
			count = delay;
		}
		public function setScrollInit(x:Number, y:Number):void{
			setScrollTarget(x, y);
			skipScroll();
		}
		public function skipScroll():void{
			canvas.x = scroll_target_x >> 0;
			canvas.y = scroll_target_y >> 0;
		}
		public function getScrollTarget():Dot{
			return new Dot( -scroll_target_x + view_width * 0.5, -scroll_target_y + view_height * 0.5);
		}
		public function reset():void{
			canvas.x = 0;
			canvas.y = 0;
			last_canvas_x = 0;
			last_canvas_y = 0;
		}
	}
	
}