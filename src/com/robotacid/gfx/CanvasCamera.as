package com.robotacid.gfx {
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.Console;
	import com.robotacid.ui.Key;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	
	/**
	 * Controls the view of the canvas
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class CanvasCamera {
		
		public var renderer:Renderer;
		public var canvas:Sprite;
		public var canvasX:Number, canvasY:Number;
		public var lastCanvasX:Number, lastCanvasY:Number;
		public var mapRect:Rectangle;
		public var targetPos:Point;
		public var vx:Number, vy:Number;
		public var count:int;
		public var delayedTargetPos:Point;
		public var interpolation:Number;
		
		private var viewWidth:Number;
		private var viewHeight:Number;
		
		public static const DEFAULT_INTERPOLATION:Number = 0.2;
		public static const INTERFACE_BORDER_TOP:Number = 30;
		public static const INTERFACE_BORDER_BOTTOM:Number = 20;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		public function CanvasCamera(canvas:Sprite, renderer:Renderer) {
			this.canvas = canvas;
			this.renderer = renderer;
			targetPos = new Point();
			count = 0;
			vx = vy = 0;
			interpolation = DEFAULT_INTERPOLATION;
			viewWidth = Game.WIDTH;
			viewHeight = Game.HEIGHT - Console.HEIGHT;
		}
		
		/* This sets where the screen will focus on - the coords are a point on the canvas you want centered on the map */
		public function setTarget(x:Number, y:Number):void{
			
			targetPos.x = int( -x + viewWidth * 0.5);
			if(targetPos.x > -mapRect.x) targetPos.x = -mapRect.x;
			else if(targetPos.x < viewWidth - (mapRect.x + mapRect.width)) targetPos.x = viewWidth - (mapRect.x + mapRect.width);
			
			targetPos.y = int( -y + viewHeight * 0.5);
			if(targetPos.y > INTERFACE_BORDER_TOP) targetPos.y = INTERFACE_BORDER_TOP;
			if(targetPos.y < -((mapRect.y + mapRect.height - viewHeight) + INTERFACE_BORDER_BOTTOM)) targetPos.y = -((mapRect.y + mapRect.height - viewHeight) + INTERFACE_BORDER_BOTTOM);
		}
		
		/* Set a target to scroll to after a given delay */
		public function setDelayedTarget(x:Number, y:Number, delay:int):void{
			delayedTargetPos = new Point(x, y);
			count = delay;
		}
		
		/* No interpolation - jump straight to the target */
		public function skipPan():void{
			canvas.x = int(targetPos.x);
			canvas.y = int(targetPos.y);
			canvasX = lastCanvasX = canvas.x;
			canvasY = lastCanvasY = canvas.y;
			//back.y = canvas.y;
		}
		
		/* Get a target position to feed back to the Camera later */
		public function getTarget():Point{
			return new Point( -targetPos.x + viewWidth * 0.5, -targetPos.y + viewHeight * 0.5);
		}
		
		public function main():void {
			
			lastCanvasX = canvasX;
			lastCanvasY = canvasY;
			
			if(count > 0){
				count--;
				if(count <= 0) setTarget(delayedTargetPos.x, delayedTargetPos.y);
			}
			
			// update the canvas position
			vx = (targetPos.x - canvasX) * interpolation;
			vy = (targetPos.y - canvasY) * interpolation;
			
			canvasX += vx;
			canvasY += vy;
			//back.move(vx, vy);
			
			canvas.x = int(canvasX) - renderer.shakeOffset.x;
			canvas.y = int(canvasY) - renderer.shakeOffset.y;
			
			if(interpolation != DEFAULT_INTERPOLATION) interpolation = DEFAULT_INTERPOLATION;
		}
	}
	
}