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
	import com.robotacid.level.MapBitmap;
	import com.robotacid.phys.Collider;
	import com.robotacid.phys.CollisionWorld;
	import com.robotacid.ui.MiniMap;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
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
		public var invading:Boolean;
		public var target:Pixel;
		
		private var count:int;
		private var cogDisplacement:Number;
		private var cogFrame:int;
		
		private static var soundDist:Number;
		private static var distX:int;
		private static var distY:int;
		private static var dist:Number;
		
		//states
		public static const IDLE:int = 0;
		public static const READY:int = 1;
		public static const MOVING:int = 2;
		public static const RETIRE:int = 3;
		public static const RESTING:int = 4;
		public static const DEAD:int = 5;
		
		public static const READY_DIST:int = 4;
		public static const SPEED:Number = 2;
		public static const READY_DELAY:int = 10;
		public static const RETIRE_DELAY:int = 10;
		
		public static const GOLEM_CHANCE:Number = 1.0 / 20;
		public static const GOLEM_TEMPLATE_XML:XML =<character name={Character.GOLEM} type={Character.MONSTER} characterNum={-1} />;
		public static const GOLEM_XP_REWARD:Number = 1 / 30;
		public static const CHAOS_CRUMBLE_CHANCE:Number = 1.0 / 5;
		
		public function ChaosWall(mapX:int, mapY:int, invading:Boolean = false) {
			super(new Sprite(), false);
			this.mapX = mapX;
			this.mapY = mapY;
			this.invading = invading;
			mapZ = Map.ENTITIES;
			free = invading;
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
			if(!invading) chaosWalls[mapY][mapX] = this;
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
		
		/* Attempts to create a site that a wandering chaos wall will generate more chaos walls from */
		public static function initInvasionSite(mapX:int, mapY:int, ignore:Collider = null):ChaosWall{
			//trace("initInvasionSite", mapX, mapY);
			// don't instigate near the player, it causes loops
			distX = game.player.mapX - mapX;
			if(distX < 0) distX = -distX;
			distY = game.player.mapY - mapY;
			if(distY < 0) distY = -distY;
			if(distX + distY < READY_DIST) return null;
			
			// clean walls only
			//if(game.map.bitmap.bitmapData.getPixel32(mapX, mapY) == MapBitmap.PIT || game.map.bitmap.bitmapData.getPixel32(mapX, mapY) == MapBitmap.SECRET) return null;
			
			// find a direction to grow into
			var pixels:Array = [];
			if(
				mapX > 0 && game.world.map[mapY][mapX - 1] == Collider.EMPTY &&
				game.map.bitmap.bitmapData.getPixel32(mapX - 1, mapY + 1) != MapBitmap.LADDER_LEDGE &&
				!game.mapTileManager.getTile(mapX - 1, mapY, MapTileManager.ENTITY_LAYER) &&
				game.world.getCollidersIn(new Rectangle((mapX - 1) * SCALE, mapY * SCALE, SCALE, SCALE), ignore).length == 0
			) pixels.push(new Pixel(mapX - 1, mapY));
			if(
				mapY > 0 && game.world.map[mapY - 1][mapX] == Collider.EMPTY &&
				!game.mapTileManager.getTile(mapX, mapY - 1, MapTileManager.ENTITY_LAYER) &&
				game.world.getCollidersIn(new Rectangle(mapX * SCALE, (mapY - 1) * SCALE, SCALE, SCALE), ignore).length == 0
			) pixels.push(new Pixel(mapX, mapY - 1));
			if(
				mapX < mapWidth - 1 && game.world.map[mapY][mapX + 1] == Collider.EMPTY &&
				game.map.bitmap.bitmapData.getPixel32(mapX + 1, mapY + 1) != MapBitmap.LADDER_LEDGE &&
				!game.mapTileManager.getTile(mapX + 1, mapY, MapTileManager.ENTITY_LAYER) &&
				game.world.getCollidersIn(new Rectangle((mapX + 1) * SCALE, mapY * SCALE, SCALE, SCALE), ignore).length == 0
			) pixels.push(new Pixel(mapX + 1, mapY));
			if(
				mapY < mapHeight - 1 && game.world.map[mapY + 1][mapX] == Collider.EMPTY &&
				game.map.bitmap.bitmapData.getPixel32(mapX, mapY + 2) != MapBitmap.LADDER_LEDGE &&
				!game.mapTileManager.getTile(mapX, mapY + 1, MapTileManager.ENTITY_LAYER) &&
				game.world.getCollidersIn(new Rectangle(mapX * SCALE, (mapY + 1) * SCALE, SCALE, SCALE), ignore).length == 0
			) pixels.push(new Pixel(mapX, mapY + 1));
			
			if(pixels.length == 0) return null;
			
			var target:Pixel = pixels[game.random.rangeInt(pixels.length)];
			
			distX = game.player.mapX - target.x;
			if(distX < 0) distX = -distX;
			distY = game.player.mapY - target.y;
			if(distY < 0) distY = -distY;
			if(distX + distY < READY_DIST) return null;
			
			var chaosWall:ChaosWall = new ChaosWall(mapX, mapY, true);
			game.mapTileManager.converter.convertIndicesToObjects(mapX, mapY, chaosWall);
			chaosWall.target = target;
			chaosWall.ready();
			
			return chaosWall;
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
				// crumble when next to the balrog - this helps him escape and spawn golems to harry the player
				if(game.balrog && state == IDLE){
					distX = game.balrog.mapX - mapX;
					if(distX < 0) distX = -distX;
					distY = game.balrog.mapY - mapY;
					if(distY < 0) distY = -distY;
					if(distX + distY <= 1) crumble();
				}
			} else if(state == READY){
				if(count){
					count--;
				} else {
					if(invading) invade();
					else retreat();
				}
			} else if(state == MOVING){
				if(collider.vx) dist = collider.x - target.x * SCALE;
				else if(collider.vy) dist = collider.y - target.y * SCALE;
				if(dist < 0) dist = -dist;
				if(dist < Collider.MOVEMENT_TOLERANCE){
					renderer.shake(collider.vx, collider.vy, new Pixel(mapX, mapY));
					collider.vx = collider.vy = 0;
					game.createDistSound(mapX, mapY, "chaosWallStop");
					state = RETIRE;
					count = RETIRE_DELAY;
					if(fuse){
						kill();
					}
					
				// stop the invasion if anything occupies the invastion site
				} else if(
					invading &&
					game.world.getCollidersIn(new Rectangle(target.x * SCALE, target.y * SCALE, SCALE, SCALE), collider).length){
					renderer.createDebrisRect(collider, 0, 100, Renderer.STONE);
					game.createDistSound(mapX, mapY, "pitTrap", Stone.DEATH_SOUNDS);
					kill();
				}
			} else if(state == RETIRE){
				if(count){
					count--;
				} else {
					if(invading) rest();
					else kill();
				}
			}
			
		}
		
		/* Prepare the ChaosWall for movement, warm up the cog animation */
		public function ready():void{
			//trace("ready", mapX, mapY);
			count = READY_DELAY;
			state = READY;
			if(!invading){
				chaosWalls[mapY][mapX] = null;
				// remove from map renderer
				game.world.removeMapPosition(mapX, mapY);
				game.mapTileManager.removeTile(this, mapX, mapY, mapZ);
				renderer.blockBitmapData.copyPixels(renderer.backBitmapData, new Rectangle(mapX * SCALE, mapY * SCALE, SCALE, SCALE), new Point(mapX * SCALE, mapY * SCALE));
				// show empty on minimap
				game.miniMap.bitmapData.setPixel32(mapX, mapY, LightMap.MINIMAP_EMPTY_COL);
			}
			gfx.visible = true;
			free = true;
			game.createDistSound(mapX, mapY, "chaosWallReady");
		}
		
		/* Begin moving the ChaosWall, activate all neighbouring ChaosWalls to create a resting place and
		 * create cascading animations */
		public function retreat():void{
			//trace("retreat", mapX, mapY);
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
			target = pixels[game.random.rangeInt(pixels.length)];
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
			game.createDistSound(mapX, mapY, "chaosWallMoving");
		}
		
		/* Occupy a previously empty area */
		public function invade():void{
			//trace("invade", mapX, mapY);
			state = MOVING;
			collider.divorce();
			if(target.y < mapY) collider.vy = -SPEED;
			else if(target.x > mapX) collider.vx = SPEED;
			else if(target.y > mapY) collider.vy = SPEED;
			else if(target.x < mapX) collider.vx = -SPEED;
			game.createDistSound(mapX, mapY, "chaosWallMoving");
		}
		
		/* Convert to IDLE state after invasion */
		public function rest():void{
			//trace("rest", mapX, mapY);
			state = IDLE;
			invading = false;
			free = false;
			mapX = target.x;
			mapY = target.y;
			game.world.map[mapY][mapX] = MapTileConverter.getMapProperties(MapTileConverter.WALL);
			game.mapTileManager.changeLayer(MapTileManager.BLOCK_LAYER);
			var blit:BlitRect = game.mapTileManager.converter.convertIndicesToObjects(mapX, mapY, MapTileConverter.WALL) as BlitRect;
			blit.x = mapX * Game.SCALE;
			blit.y = mapY * Game.SCALE;
			blit.render(renderer.blockBitmapData);
			chaosWalls[mapY][mapX] = this;
			if(game.mapTileManager.containsTile(mapX, mapY, MapTileManager.ENTITY_LAYER)){
				game.mapTileManager.addTile(this, mapX, mapY, MapTileManager.ENTITY_LAYER);
			} else {
				remove();
			}
			initInvasionSite(mapX, mapY);
		}
		
		/* The standard way for chaos walls to go in the Caves zone and occasionally in Chaos */
		public function crumble():void{
			//trace("crumble", mapX, mapY);
			chaosWalls[mapY][mapX] = null;
			// remove from map renderer
			game.world.removeMapPosition(mapX, mapY);
			game.mapTileManager.removeTile(this, mapX, mapY, mapZ);
			//renderer.blockBitmapData.fillRect(new Rectangle(mapX * SCALE, mapY * SCALE, SCALE, SCALE), 0x0);
			renderer.blockBitmapData.copyPixels(renderer.backBitmapData, new Rectangle(mapX * SCALE, mapY * SCALE, SCALE, SCALE), new Point(mapX * SCALE, mapY * SCALE));
			// show empty on minimap
			game.miniMap.bitmapData.setPixel32(mapX, mapY, LightMap.MINIMAP_EMPTY_COL);
			gfx.visible = true;
			free = true;
			game.createDistSound(mapX, mapY, "pitTrap", Stone.DEATH_SOUNDS);
			// create a golem?
			if(game.random.value() < GOLEM_CHANCE){
				renderer.shake(0, 5, new Pixel(mapX, mapY));
				var xml:XML = GOLEM_TEMPLATE_XML.copy();
				xml.@level = game.map.level;
				var monster:Monster = Content.XMLToEntity(mapX, mapY, xml);
				monster.xpReward = GOLEM_XP_REWARD * Content.getLevelXp(game.map.level);
				game.mapTileManager.converter.convertIndicesToObjects(mapX, mapY, monster);
				renderer.createDebrisExplosion(collider, 10, 80, Renderer.STONE);
				renderer.createDebrisRect(collider, 0, 60, Renderer.STONE);
				if(game.map.completionCount){
					game.map.completionCount++;
					game.map.completionTotal++;
				}
			} else {
				renderer.createDebrisRect(collider, 0, 100, Renderer.STONE);
			}
			kill();
		}
		
		/* Destructor */
		public function kill():void {
			if(!active) return;
			//trace("kill", mapX, mapY);
			state = DEAD;
			if(fuse){
				if(chaosWalls[target.y][target.x]) chaosWalls[target.y][target.x].callMain = true;
			}
			active = false;
			if(collider.world) collider.world.removeCollider(collider);
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
			//trace("remove", mapX, mapY);
			game.chaosWalls.splice(game.chaosWalls.indexOf(this), 1);
			super.remove();
		}
	}

}