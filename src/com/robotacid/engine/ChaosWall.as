package com.robotacid.engine {
	import adobe.utils.CustomActions;
	import com.robotacid.gfx.CogRectBlit;
	import com.robotacid.level.Content;
	import com.robotacid.level.Map;
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
	import flash.geom.Rectangle;
	
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
		public var fuse:Boolean;
		
		private var target:Pixel;
		
		private var count:int;
		private var cogDisplacement:Number;
		private var cogFrame:int;
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
		
		public static const GOLEM_CHANCE:Number = 1.0 / 20;
		public static const GOLEM_TEMPLATE_XML:XML =<character name={Character.GOLEM} type={Character.MONSTER} characterNum={-1} />;
		public static const GOLEM_XP_REWARD:Number = 1 / 30;
		public static const CHAOS_CRUMBLE_CHANCE:Number = 1.0 / 5;
		
		public function ChaosWall(mapX:int, mapY:int) {
			super(new Sprite(), false);
			this.mapX = mapX;
			this.mapY = mapY;
			mapZ = Map.ENTITIES;
			free = false;
			fuse = false;
			callMain = true;
			state = IDLE;
			(gfx as Sprite).graphics.beginFill(0);
			(gfx as Sprite).graphics.drawRect(0, 0, SCALE, SCALE);
			(gfx as Sprite).graphics.endFill();
			cogDisplacement = 0;
			gfx.visible = false;
			createCollider(mapX * SCALE, mapY * SCALE, Collider.WALL | Collider.SOLID | Collider.CHAOS, Collider.WALL | Collider.GATE | Collider.CHARACTER | Collider.HEAD | Collider.CORPSE | Collider.ITEM, Collider.HOVER, false);
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
				distX = game.player.mapX - mapX;
				if(distX < 0) distX = -distX;
				distY = game.player.mapY - mapY;
				if(distY < 0) distY = -distY;
				if(
					distX + distY < READY_DIST &&
					(game.map.type == Map.AREA || game.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000)
				){
					// in later zones chaos walls simply crumble, and possibly spawn golems
					if(game.map.zone == Map.CAVES || (game.map.zone == Map.CHAOS && game.random.value() < CHAOS_CRUMBLE_CHANCE)){
						crumble();
					} else {
						ready();
					}
				}
			} else if(state == READY){
				if(count){
					count--;
				} else {
					move();
				}
			} else if(state == MOVING){
				if(collider.vx) dist = collider.x - target.x * SCALE;
				else if(collider.vy) dist = collider.y - target.y * SCALE;
				if(dist < 0) dist = -dist;
				if(dist < Collider.MOVEMENT_TOLERANCE){
					state = RETIRE;
					count = RETIRE_DELAY;
					renderer.shake(collider.vx, collider.vy);
					collider.vx = collider.vy = 0;
					game.soundQueue.add("chaosWallStop");
					if(fuse){
						kill();
					}
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
			game.world.removeMapPosition(mapX, mapY);
			game.mapTileManager.removeTile(this, mapX, mapY, mapZ);
			renderer.blockBitmapData.fillRect(new Rectangle(mapX * SCALE, mapY * SCALE, SCALE, SCALE), 0x0);
			// show empty on minimap
			game.miniMap.bitmapData.setPixel32(mapX, mapY, LightMap.MINIMAP_EMPTY_COL);
			gfx.visible = true;
			free = true;
			game.soundQueue.add("chaosWallReady");
		}
		
		/* Begin moving the ChaosWall, activate all neighbouring ChaosWalls to create a resting place and
		 * create cascading animations */
		public function move():void{
			var pixels:Array = [];
			// create shelter options
			if(mapX > 0 && ((game.world.map[mapY][mapX - 1] & Collider.WALL) || chaosWalls[mapY][mapX - 1])) pixels.push(new Pixel(mapX - 1, mapY));
			if(mapY > 0 && ((game.world.map[mapY - 1][mapX] & Collider.WALL) || chaosWalls[mapY - 1][mapX])) pixels.push(new Pixel(mapX, mapY - 1));
			if(mapX < mapWidth - 1 && ((game.world.map[mapY][mapX + 1] & Collider.WALL) || chaosWalls[mapY][mapX + 1])) pixels.push(new Pixel(mapX + 1, mapY));
			if(mapY < mapHeight - 1 && ((game.world.map[mapY + 1][mapX] & Collider.WALL) || chaosWalls[mapY + 1][mapX])) pixels.push(new Pixel(mapX, mapY + 1));
			// no shelter? crumble
			if(pixels.length == 0){
				crumble();
				return;
			}
			target = pixels[0];// game.random.rangeInt(pixels.length)];
			collider.divorce();
			if(target.y < mapY) collider.vy = -SPEED;
			else if(target.x > mapX) collider.vx = SPEED;
			else if(target.y > mapY) collider.vy = SPEED;
			else if(target.x < mapX) collider.vx = -SPEED;
			// fuse with a neighbouring chaos wall?
			if(chaosWalls[target.y][target.x]){
				chaosWalls[target.y][target.x].callMain = false;
				fuse = true;
			}
			// ready neighbouring walls
			if(mapX > 0 && chaosWalls[mapY][mapX - 1]){
				chaosWalls[mapY][mapX - 1].ready();
			}
			if(mapY > 0 && chaosWalls[mapY - 1][mapX]){
				chaosWalls[mapY - 1][mapX].ready();
			}
			if(mapX < mapWidth - 1 && chaosWalls[mapY][mapX + 1]){
				chaosWalls[mapY][mapX + 1].ready();
			}
			if(mapY < mapHeight - 1 && chaosWalls[mapY + 1][mapX]){
				chaosWalls[mapY + 1][mapX].ready();
			}
			state = MOVING;
			game.soundQueue.add("chaosWallMoving");
		}
		
		/* The standard way for chaos walls to go in the Caves zone and occasionally in Chaos */
		public function crumble():void{
			chaosWalls[mapY][mapX] = null;
			// remove from map renderer
			game.world.removeMapPosition(mapX, mapY);
			game.mapTileManager.removeTile(this, mapX, mapY, mapZ);
			renderer.blockBitmapData.fillRect(new Rectangle(mapX * SCALE, mapY * SCALE, SCALE, SCALE), 0x0);
			// show empty on minimap
			game.miniMap.bitmapData.setPixel32(mapX, mapY, LightMap.MINIMAP_EMPTY_COL);
			gfx.visible = true;
			free = true;
			game.soundQueue.addRandom("pitTrap", Stone.DEATH_SOUNDS);
			renderer.createDebrisRect(collider, 0, 100, Renderer.STONE);
			// create a golem?
			if(game.random.value() < GOLEM_CHANCE){
				renderer.shake(0, 5);
				var xml:XML = GOLEM_TEMPLATE_XML.copy();
				xml.@level = game.map.level;
				var monster:Monster = Content.XMLToEntity(mapX, mapY, xml);
				monster.xpReward = GOLEM_XP_REWARD * Content.getLevelXp(game.map.level);
				game.mapTileManager.converter.convertIndicesToObjects(mapX, mapY, monster);
			}
			kill();
		}
		
		/* Destructor */
		public function kill():void {
			if(fuse){
				if(chaosWalls[target.y][target.x]) chaosWalls[target.y][target.x].callMain = true;
			}
			active = false;
			//renderer.createDebrisRect(collider, 0, 100, debrisType);
			collider.world.removeCollider(collider);
		}
		
		override public function render():void {
			if(state == READY){
				if(cogDisplacement < SCALE * 0.5){
					cogDisplacement++;
				}
			} else if(state == MOVING){
				var blit:BlitRect;
				var print:FadingBlitRect;
				for(var i:int = 0; i < 5; i++){
					if(game.random.coinFlip()){
						blit = renderer.smallDebrisBlits[Renderer.STONE];
						print = renderer.smallFadeBlits[Renderer.STONE];
					} else {
						blit = renderer.bigDebrisBlits[Renderer.STONE];
						print = renderer.bigFadeBlits[Renderer.STONE];
					}
					if(collider.vy < 0) renderer.addDebris(collider.x + game.random.range(collider.width), collider.y + collider.height, blit, 0, game.random.range(3), print, true);
					else if(collider.vx > 0) renderer.addDebris(collider.x + collider.width, collider.y + game.random.range(collider.height), blit, -game.random.range(3), 0, print, true);
					else if(collider.vy > 0) renderer.addDebris(collider.x + game.random.range(collider.width), collider.y - 1, blit, 0, -game.random.range(5), print, true);
					else if(collider.vx < 0) renderer.addDebris(collider.x - 1, collider.y + game.random.range(collider.height), blit, game.random.range(3), 0, print, true);
				}
			} else if(state == RETIRE){
				if(cogDisplacement > 0){
					cogDisplacement--;
				}
			}
			gfx.x = (collider.x + 0.5) >> 0;
			gfx.y = (collider.y + 0.5) >> 0;
			super.render();
			if(cogDisplacement >= SCALE * 0.5){
				cogFrame++;
				if(cogFrame >= renderer.cogRectBlit.totalFrames) cogFrame = 0;
				renderer.cogRectBlit.dirs[CogRectBlit.TOP_LEFT] = 1;
				renderer.cogRectBlit.dirs[CogRectBlit.TOP_RIGHT] = -1;
				renderer.cogRectBlit.dirs[CogRectBlit.BOTTOM_RIGHT] = -1;
				renderer.cogRectBlit.dirs[CogRectBlit.BOTTOM_LEFT] = 1;
			}
			renderer.cogRectBlit.allVisible = true;
			renderer.cogRectBlit.displacement = cogDisplacement;
			renderer.cogRectBlit.x = -renderer.bitmap.x + ((collider.x + collider.width * 0.5 + 0.5) >> 0);
			renderer.cogRectBlit.y = -renderer.bitmap.y + ((collider.y + collider.height * 0.5 + 0.5) >> 0);
			renderer.cogRectBlit.render(renderer.bitmapData, cogFrame);
		}
		
		override public function remove():void {
			game.chaosWalls.splice(game.chaosWalls.indexOf(this), 1);
			super.remove();
		}
	}

}