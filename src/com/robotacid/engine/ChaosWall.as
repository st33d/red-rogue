package com.robotacid.engine {
	import adobe.utils.CustomActions;
	import com.robotacid.dungeon.Map;
	import com.robotacid.geom.Pixel;
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.FadingBlitRect;
	import com.robotacid.gfx.LightMap;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.phys.Collider;
	import com.robotacid.phys.CollisionWorld;
	import com.robotacid.ui.MiniMap;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	/**
	 * Moving walls that imply that the dungeon is constantly rearranging itself
	 * 
	 * ChaosWalls either naturally reveal parts of the dungeon, or travel randomly creating new pathways
	 * randomly moving ChaosWalls are created with chaos runes
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class ChaosWall extends ColliderEntity {
		
		public static var mapWidth:int;
		public static var mapHeight:int;
		public static var chaosWalls:Vector.<Vector.<ChaosWall>>;
		
		public var state:int;
		
		private var cogs:Vector.<MovieClip>;
		private var target:Pixel;
		
		private var count:int;
		private var cogDisplacement:Number;
		private var playerDist:int;
		
		private static var distX:int;
		private static var distY:int;
		private static var dist:Number;
		
		//states
		public static const IDLE:int = 0;
		public static const READY:int = 1;
		public static const MOVING:int = 2;
		public static const RETIRE:int = 3;
		public static const DEAD:int = 4;
		
		public static const READY_DIST:int = 4;
		public static const SPEED:Number = 2;
		public static const READY_DELAY:int = 10;
		public static const RETIRE_DELAY:int = 10;
		
		public function ChaosWall(mapX:int, mapY:int) {
			super(new Sprite(), false);
			this.mapX = mapX;
			this.mapY = mapY;
			mapZ = Map.ENTITIES;
			free = false;
			callMain = true;
			state = IDLE;
			(gfx as Sprite).graphics.beginFill(0);
			(gfx as Sprite).graphics.drawRect(0, 0, SCALE, SCALE);
			(gfx as Sprite).graphics.endFill();
			cogs = new Vector.<MovieClip>();
			var i:int;
			for(i = 0; i < 4; i++){
				cogs[i] = new CogMC();
				cogs[i].x = SCALE * 0.5;
				cogs[i].y = SCALE * 0.5;
				(gfx as Sprite).addChild(cogs[i]);
			}
			cogDisplacement = 0;
			gfx.visible = false;
			createCollider(mapX * SCALE, mapY * SCALE, Collider.WALL | Collider.SOLID | Collider.CHAOS, Collider.WALL, Collider.HOVER, false);
			collider.pushDamping = 0;
			collider.dampingX = collider.dampingY = 1;
			chaosWalls[mapY][mapX] = this;
		}
		
		public static function init(width:int, height:int):void{
			mapWidth = width;
			mapHeight = height;
			chaosWalls = new Vector.<Vector.<ChaosWall>>();
			var r:int, c:int;
			for(r = 0; r < height; r++){
				chaosWalls[r] = new Vector.<ChaosWall>()
				for(c = 0; c < width; c++){
					chaosWalls[r][c] = null;
				}
			}
		}
		
		override public function main():void {
			//Game.debug.drawCircle(collider.x + SCALE * 0.5, collider.y + SCALE * 0.5, 8);
			if(state == IDLE){
				distX = g.player.mapX - mapX;
				if(distX < 0) distX = -distX;
				distY = g.player.mapY - mapY;
				if(distY < 0) distY = -distY;
				if(distX + distY < READY_DIST){
					ready();
				}
			} else if(state == READY){
				if(count){
					count--;
				} else {
					move();
				}
			} else if(state == MOVING){
				if(collider.vx) dist = collider.x - target.x * Game.SCALE;
				else if(collider.vy) dist = collider.y - target.y * Game.SCALE;
				if(dist < 0) dist = -dist;
				if(dist < Collider.MOVEMENT_TOLERANCE){
					state = RETIRE;
					count = RETIRE_DELAY;
					renderer.shake(collider.vx, collider.vy);
					collider.vx = collider.vy = 0;
					g.soundQueue.add("thud", 3);
				}
			} else if(state == RETIRE){
				if(count){
					count--;
				} else {
					kill();
				}
			}
			
		}
		
		/* Prepare the ChaosWall for movement, warm up the cog animation */
		public function ready():void{
			count = READY_DELAY;
			state = READY;
			chaosWalls[mapY][mapX] = null;
			// remove from map renderer
			g.world.map[mapY][mapX] = 0;
			g.mapRenderer.removeFromRenderedArray(mapX, mapY, Map.BLOCKS, null);
			g.mapRenderer.removeFromRenderedArray(mapX, mapY, Map.ENTITIES, null);
			g.mapRenderer.removeTile(Map.BLOCKS, mapX, mapY);
			// show empty on minimap
			g.miniMap.bitmapData.setPixel32(mapX, mapY, LightMap.MINIMAP_EMPTY_COL);
			gfx.visible = true;
			free = true;
		}
		
		/* Begin moving the ChaosWall, activate all neighbouring ChaosWalls to create a resting place and
		 * create cascading animations */
		public function move():void{
			// ready neighbouring walls
			if(mapX > 0 && chaosWalls[mapY][mapX - 1]) chaosWalls[mapY][mapX - 1].ready();
			if(mapY > 0 && chaosWalls[mapY - 1][mapX]) chaosWalls[mapY - 1][mapX].ready();
			if(mapX < mapWidth - 1 && chaosWalls[mapY][mapX + 1]) chaosWalls[mapY][mapX + 1].ready();
			if(mapY < mapHeight - 1 && chaosWalls[mapY + 1][mapX]) chaosWalls[mapY + 1][mapX].ready();
			// find shelter options - chaos walls should be out of the way now
			var pixels:Array = [];
			if(mapX > 0 && (g.world.map[mapY][mapX - 1] & Collider.WALL)) pixels.push(new Pixel(mapX - 1, mapY));
			if(mapY > 0 && (g.world.map[mapY - 1][mapX] & Collider.WALL)) pixels.push(new Pixel(mapX, mapY - 1));
			if(mapX < mapWidth - 1 && (g.world.map[mapY][mapX + 1] & Collider.WALL)) pixels.push(new Pixel(mapX + 1, mapY));
			if(mapY < mapHeight - 1 && (g.world.map[mapY + 1][mapX] & Collider.WALL)) pixels.push(new Pixel(mapX, mapY + 1));
			target = pixels[g.random.rangeInt(pixels.length)];
			collider.divorce();
			if(target.y < mapY) collider.vy = -SPEED;
			else if(target.x > mapX) collider.vx = SPEED;
			else if(target.y > mapY) collider.vy = SPEED;
			else if(target.x < mapX) collider.vx = -SPEED;
			state = MOVING;
		}
		
		/* Destructor */
		public function kill():void {
			active = false;
			//renderer.createDebrisRect(collider, 0, 100, debrisType);
			collider.world.removeCollider(collider);
			trace("kill", mapX, mapY);
		}
		
		override public function render():void {
			if(state == READY){
				if(cogDisplacement < SCALE * 0.5){
					cogDisplacement++;
					cogs[0].x = SCALE * 0.5 - cogDisplacement;
					cogs[0].y = SCALE * 0.5 - cogDisplacement;
					cogs[1].x = SCALE * 0.5 + cogDisplacement;
					cogs[1].y = SCALE * 0.5 - cogDisplacement;
					cogs[2].x = SCALE * 0.5 - cogDisplacement;
					cogs[2].y = SCALE * 0.5 + cogDisplacement;
					cogs[3].x = SCALE * 0.5 + cogDisplacement;
					cogs[3].y = SCALE * 0.5 + cogDisplacement;
				}
			} else if(state == MOVING){
				var blit:BlitRect;
				var print:FadingBlitRect;
				for(var i:int = 0; i < 5; i++){
					if(g.random.value() < 0.5){
						blit = renderer.smallDebrisBlits[Renderer.STONE];
						print = renderer.smallFadeBlits[Renderer.STONE];
					} else {
						blit = renderer.bigDebrisBlits[Renderer.STONE];
						print = renderer.bigFadeBlits[Renderer.STONE];
					}
					if(collider.vy < 0) renderer.addDebris(collider.x + g.random.range(collider.width), collider.y + collider.height, blit, 0, g.random.range(3), print, true);
					else if(collider.vx > 0) renderer.addDebris(collider.x + collider.width, collider.y + g.random.range(collider.height), blit, -g.random.range(3), 0, print, true);
					else if(collider.vy > 0) renderer.addDebris(collider.x + g.random.range(collider.width), collider.y - 1, blit, 0, -g.random.range(5), print, true);
					else if(collider.vx < 0) renderer.addDebris(collider.x - 1, collider.y + g.random.range(collider.height), blit, g.random.range(3), 0, print, true);
				}
			} else if(state == RETIRE){
				if(cogDisplacement > 0){
					cogDisplacement--;
					cogs[0].x = SCALE * 0.5 - cogDisplacement;
					cogs[0].y = SCALE * 0.5 - cogDisplacement;
					cogs[1].x = SCALE * 0.5 + cogDisplacement;
					cogs[1].y = SCALE * 0.5 - cogDisplacement;
					cogs[2].x = SCALE * 0.5 - cogDisplacement;
					cogs[2].y = SCALE * 0.5 + cogDisplacement;
					cogs[3].x = SCALE * 0.5 + cogDisplacement;
					cogs[3].y = SCALE * 0.5 + cogDisplacement;
				}
			}
			gfx.x = (collider.x + 0.5) >> 0;
			gfx.y = (collider.y + 0.5) >> 0;
			super.render();
		}
		
		override public function remove():void {
			trace("remove", mapX, mapY);
			g.chaosWalls.splice(g.chaosWalls.indexOf(this), 1);
			super.remove();
		}
	}

}