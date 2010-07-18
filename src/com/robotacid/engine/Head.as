package com.robotacid.engine {
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Collider;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	/**
	 * A decapitated head that bounces along spewing blood when
	 * kicked by the player and inflicts damage upon
	 * monsters
	 *
	 * :D
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Head extends Collider{
		
		public var damage:Number;
		public var bloodCount:int;
		
		public static const GRAVITY:Number = 0.8;
		public static const DAMPING_Y:Number = 0.99;
		public static const DAMPING_X:Number = 0.9;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		public static const BLOOD_DELAY:int = 20;
		
		public function Head(victim:MovieClip, damage:Number, g:Game) {
			// first we get capture the target's head
			// each decapitatable victim has a marker clip on it called "neck" that we chop at
			var neckY:int = victim.neck.y + 1;
			var bounds:Rectangle = victim.getBounds(victim);
			var data:BitmapData = new BitmapData(Math.ceil(bounds.width), Math.ceil(-bounds.top + neckY), true, 0x00000000);
			data.draw(victim, new Matrix(1, 0, 0, 1, -bounds.left, -bounds.top));
			var holder:Sprite = new Sprite();
			var bitmap:Bitmap = new Bitmap(data);
			bitmap.x = bounds.left;
			holder.addChild(bitmap);
			g.fxHolder.addChild(holder);
			holder.x = victim.x;
			holder.y = victim.y + neckY;
			// now we've got a head, but the width of the actual graphic may be lying
			var colourBounds:Rectangle = data.getColorBoundsRect(0xFFFFFFFF, 0x00000000, false);
			bitmap.y = -colourBounds.bottom;
			super(holder, colourBounds.width, colourBounds.height, g, true);
			callMain = true;
			weight = 0;
			bloodCount = BLOOD_DELAY;
			block.type |= Block.HEAD;
			ignore |= Block.CORPSE;
			this.damage = damage;
			inflictsCrush = false;
		}
		
		override public function main():void{
			if(leftCollider is Character) punt(leftCollider as Character);
			else if(rightCollider is Character) punt(rightCollider as Character);
			if(Math.abs(vx) > Collider.TOLERANCE || Math.abs(vy) > Collider.TOLERANCE){
				if(bloodCount > 0){
					bloodCount--;
					var blit:BlitRect, print:BlitRect;
					if(Math.random() > 0.5){
						blit = g.smallDebrisBrs[Game.BLOOD];
						print = g.smallFadeFbrs[Game.BLOOD];
					} else {
						blit = g.bigDebrisBrs[Game.BLOOD];
						print = g.bigFadeFbrs[Game.BLOOD];
					}
					g.addDebris(x, y, blit, -1 + vx + Math.random(), -Math.random(), print, true);
				}
			}
			soccerCheck();
			// when crushed - just pop the head and kill it
			if(((collisions & RIGHT) && (collisions & LEFT)) || ((collisions & UP) && (collisions & DOWN))){
				kill();
			}
			upCollider = rightCollider = downCollider = leftCollider = null;
			collisions = 0;
			updateMC();
		}
		
		/* Apply damage to monsters that collide with the Head object */
		public function soccerCheck():void{
			if(upCollider && upCollider is Monster) (upCollider as Character).applyDamage(damage, nameToString())
			if(rightCollider && rightCollider is Monster) (rightCollider as Character).applyDamage(damage, nameToString())
			if(leftCollider && leftCollider is Monster) (leftCollider as Character).applyDamage(damage, nameToString())
			if(downCollider && downCollider is Monster) (downCollider as Character).applyDamage(damage, nameToString())
		}
		
		/* Movement is handled separately to keep all colliders synchronized */
		override public function move():void {
			vx *= DAMPING_X;
			moveX(vx, this);
			if (parentBlock){
				checkFloor();
			}
			if(!parentBlock){
				vy = DAMPING_Y * vy + GRAVITY;
				moveY(vy, this);
			}
			
			mapX = (rect.x + rect.width * 0.5) * INV_SCALE;
			mapY = (rect.y + rect.height * 0.5) * INV_SCALE;
		}
		
		public function punt(character:Character):void{
			parentBlock = null;
			bloodCount = BLOOD_DELAY;
			if(parent) parent.removeChild(this);
			vy -= Math.abs(character.vx * 0.5);
			vx += character.vx * 0.5;
		}
		
		public function kill():void{
			active = false;
			g.createDebrisRect(rect, 0, 10, Game.BLOOD);
		}
		
		
		/* Update collision Rect / Block */
		override public function updateRect():void{
			rect.x = x - width * 0.5;
			rect.y = y - height * 0.5;
			rect.width = width;
			rect.height = height;
		}
		
		/* Handles refreshing animation and the position on the canvas */
		public function updateMC():void{
			mc.x = (x + 0.1) >> 0;
			mc.y = ((y + height * 0.5) + 0.1) >> 0;
			if(mc.alpha < 1){
				mc.alpha += 0.1;
			}
		}
		
		override public function nameToString():String {
			return "soccer";
		}
	}
	
}