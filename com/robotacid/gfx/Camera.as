package com.robotacid.gfx {
	import com.robotacid.geom.Dot;
	import com.robotacid.geom.Rect;
	import com.robotacid.ui.Key;
	import flash.display.Sprite;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class Camera {
		
		public var g:Game;
		public var canvas:Sprite;
		public var interpolation:Number = 0.2;
		public var scrollTargetX:Number, scrollTargetY:Number;
		public var lastCanvasX:Number, lastCanvasY:Number;
		public var virtualCanvasX:Number, virtualCanvasY:Number;
		public var lastVirtualCanvasX:Number, lastVirtualCanvasY:Number;
		public var scrollX:Number, scrollY:Number;
		public var scrollRect:Rect;
		public var mapRect:Rect;
		public var viewWidth:Number;
		public var viewHeight:Number;
		
		public var count:int;
		public var delayTarget:Dot;
		public var mouseHidden:Boolean;
		public var scrolling:Boolean;
		public var scrollFocus:Dot;
		public var lockOut:Boolean;
		
		public var targetObject:Dot;
		
		public static const SCROLL_PACE:Number = 0.5;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		
		public function Camera(g:Game, targetObject:Dot, viewWidth:Number, viewHeight:Number) {
			this.g = g;
			this.targetObject = targetObject;
			this.viewWidth = viewWidth;
			this.viewHeight = viewHeight;
			this.canvas = g.canvas;
			mapRect = g.renderer.mapRect;
			scrollRect = new Rect(60, 64, 200, 80);
			scrollX = 0;
			scrollY = scrollRect.height * 0.5;
			scrollTargetX = -targetObject.x+scrollRect.x+scrollX;
			scrollTargetY = -targetObject.y+scrollRect.y+scrollY;
			scrollTargetX = Math.min(0, scrollTargetX);
			scrollTargetY = Math.min(0, scrollTargetY);
			scrollTargetX = Math.max(( -g.renderer.width * Game.SCALE) + viewWidth, scrollTargetX);
			scrollTargetY = Math.max(( -(g.renderer.height + 1) * Game.SCALE) + viewHeight, scrollTargetY);
			canvas.x = scrollTargetX >> 0;
			canvas.y = scrollTargetY >> 0;
			virtualCanvasX = lastVirtualCanvasX = canvas.x;
			virtualCanvasY = lastVirtualCanvasY = canvas.y;
			
			lockOut = false;
		}
		/* Update scrolling */
		public function main():void{
			if(count > 0){
				count--;
				if(count <= 0) setScrollTarget(delayTarget.x, delayTarget.y);
			}
			
			var looking:int = g.player.looking;
			if((looking & RIGHT) && scrollX > 0) scrollX -= SCROLL_PACE;
			if((looking & LEFT) && scrollX < scrollRect.width) scrollX += SCROLL_PACE;
			if((looking & UP) && scrollY < scrollRect.height) scrollY += SCROLL_PACE;
			else if((looking & DOWN) && scrollY > 0) scrollY -= SCROLL_PACE;
			else if(scrollY > scrollRect.height * 0.5) scrollY -= SCROLL_PACE;
			else if(scrollY < scrollRect.height * 0.5) scrollY += SCROLL_PACE;
			if((g.player.actions & RIGHT) && scrollX > 0) scrollX -= SCROLL_PACE * 2;
			if ((g.player.actions & LEFT) && scrollX < scrollRect.width) scrollX += SCROLL_PACE * 2;
			// scroll down when down is pressed
			//if ((g.player.keysPressed & DOWN) && scrollY > 0) scrollY -= 1;
			// scroll back to default when neither falling or down is pressed
			//if (!(g.player.keysPressed & DOWN) && !(g.player.state == Character.FALLING) && scrollY < scrollRect.height) scrollY += 1;
			
			scrollTargetX = -targetObject.x + scrollRect.x + scrollX;
			scrollTargetY = -targetObject.y + scrollRect.y + scrollY;
			/**/scrollTargetX = Math.min(0, scrollTargetX);
			scrollTargetY = Math.min(0, scrollTargetY);
			scrollTargetX = Math.max(( -g.renderer.width * Game.SCALE) + viewWidth, scrollTargetX);
			scrollTargetY = Math.max(( -(g.renderer.height+1) * Game.SCALE) + viewHeight, scrollTargetY);
			
			lastCanvasX = canvas.x;
			lastCanvasY = canvas.y;
			canvas.x += Math.round((scrollTargetX - canvas.x) * interpolation);
			canvas.y += Math.round((scrollTargetY - canvas.y) * interpolation);
			// the virtual canvas is where the canvas should precisely be if we weren't rounding off it's position
			// this helps scroll the background better when we move really slow
			lastVirtualCanvasX = virtualCanvasX;
			lastVirtualCanvasY = virtualCanvasY;
			virtualCanvasX += canvas.x - lastCanvasX;
			virtualCanvasY += canvas.y - lastCanvasY;
		}
		
		/* This sets where the screen will focus on - the coords are a point on the canvas you want centered on the map */
		public function setScrollTarget(x:Number, y:Number):void {
			scrollTargetX = (-x + viewWidth * 0.5) >> 0;
			scrollTargetY = (-y + viewHeight * 0.5) >> 0;
			scrollTargetX = Math.min(0, scrollTargetX);
			scrollTargetY = Math.min(0, scrollTargetY);
		}
		public function setDelayedScrollTarget(x:Number, y:Number, delay:int):void{
			delayTarget = new Dot(x, y);
			count = delay;
		}
		public function setScrollInit(x:Number, y:Number):void{
			setScrollTarget(x, y);
			skipScroll();
		}
		public function skipScroll():void{
			canvas.x = scrollTargetX >> 0;
			canvas.y = scrollTargetY >> 0;
		}
		public function getScrollTarget():Dot{
			return new Dot( -scrollTargetX + viewWidth * 0.5, -scrollTargetY + viewHeight * 0.5);
		}
		public function reset():void{
			canvas.x = 0;
			canvas.y = 0;
			lastCanvasX = 0;
			lastCanvasY = 0;
		}
	}
	
}