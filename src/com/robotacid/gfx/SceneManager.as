package com.robotacid.gfx {
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Explosion;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.MapTileConverter;
	import com.robotacid.engine.Portal;
	import com.robotacid.engine.Stone;
	import com.robotacid.level.Map;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * Generates custom FX objects and overlays for certain areas
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class SceneManager {
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		public var mapLevel:int;
		public var mapType:int;
		public var mapZone:int;
		
		public var quakes:Boolean;
		
		// utilities
		private var i:int;
		private var n:Number;
		private var vx:Number;
		private var vy:Number;
		private var length:Number;
		private var fx:Vector.<FX>;
		private var automata:Vector.<ChaosAutomata>;
		private var bitmapData:BitmapData;
		private var matrix:Matrix = new Matrix();
		private var point:Point = new Point();
		private var auto:ChaosAutomata;
		private var endingData:Object;
		private var slideX:Number;
		private var slideY:Number;
		private var slideDist:Number;
		private var slideRect:Rectangle;
		private var slideBuffer:BitmapData;
		private var count:int;
		private var quakeCount:int;
		private var quakeHits:int;
		
		public static const UNDERWORLD_NOVAS:int = 20;
		public static const UNDERWORLD_NOVA_HEIGHT:int = 9;
		public static const UNDERWORLD_WAVE_HEIGHT:int = 12;
		public static const QUAKE_DELAY:int = 300;
		public static const QUAKE_HITS:int = 4;
		public static const CHAOS_SLIDE_DELAY:int = 90;
		public static const CHAOS_SLIDE_SPEED:Number = 1;
		public static const WAVE_SPEED:Number = 0.5;
		public static const STAR_SOUNDS:Array = ["star1", "star2", "star3", "star4"];
		public static const DUNGEON_DEATH_SOUNDS:Array = ["Scream01", "Scream02", "Scream03", "Scream04", "Scream05", "Scream06", "Scream07", "Scream08", "Scream09"];
		
		public function SceneManager(mapLevel:int, mapType:int) {
			this.mapLevel = mapLevel;
			this.mapType = mapType;
			mapZone = game.content.getLevelZone(mapLevel);
			
			if(mapLevel == Map.UNDERWORLD && mapType == Map.AREA){
				fx = new Vector.<FX>();
				for(i = 0; i < UNDERWORLD_NOVAS; i++){
					fx[i] = new FX(game.random.range(game.map.width * Game.SCALE), game.random.range(UNDERWORLD_NOVA_HEIGHT * Game.SCALE), renderer.novaBlit, renderer.bitmapData, renderer.bitmap);
					fx[i].frame = game.random.rangeInt(renderer.novaBlit.totalFrames);
				}
				var bitmap:Bitmap = new game.library.WaveB()
				bitmapData = bitmap.bitmapData;
				vx = 0;
				
			} else if(mapZone == Map.CHAOS){
				ChaosAutomata.pixels = renderer.backgroundBitmapData.getVector(renderer.backgroundBitmapData.rect);
				automata = new Vector.<ChaosAutomata>();
				for(i = 0; i < 30; i++){
					automata.push(new ChaosAutomata(i < 15));
				}
				count = CHAOS_SLIDE_DELAY + game.random.rangeInt(CHAOS_SLIDE_DELAY);
			}
			// the dungeon suffers quakes whilst the amulet of yendor is out of the enemy's hands
			if(UserData.gameState.husband || game.gameMenu.inventoryList.getItem(Item.YENDOR, Item.ARMOUR)){
				if(mapType != Map.AREA){
					quakes = true;
					quakeHits = QUAKE_HITS + game.random.rangeInt(QUAKE_HITS);
					quakeCount = QUAKE_DELAY + game.random.rangeInt(QUAKE_DELAY);
					
				// prep for ending
				} else if(mapLevel == Map.OVERWORLD){
					endingData = {
						firstDelay:45,
						debrisDelay:240,
						screamDelay:30,
						debrisRect:new Rectangle(Map.OVERWORLD_STAIRS_X * Game.SCALE, (game.map.height - 2) * Game.SCALE, Game.SCALE, Game.SCALE)
					}
					quakeCount = 1;
				}
			}
		}
		
		public function renderBackground():void{
			if(mapLevel == Map.UNDERWORLD && mapType == Map.AREA){
				// the underworld requires the constant upkeep of exploding stars in the sky
				var item:FX;
				for(i = fx.length - 1; i > -1; i--){
					item = fx[i];
					if(!item.active) fx[i] = new FX(game.random.range(game.map.width * Game.SCALE), game.random.range(UNDERWORLD_NOVA_HEIGHT * Game.SCALE), renderer.novaBlit, renderer.bitmapData, renderer.bitmap);
					else{
						item.main();
						if(item.frame == item.blit.totalFrames) game.soundQueue.addRandom("star", STAR_SOUNDS);
					}
				}
			} else if(mapZone == Map.CHAOS){
				if(count){
					count--;
					if(count == 0){
						slideDist = (game.random.rangeInt(4) + 3) * Game.SCALE;
						slideX = slideY = 0;
						if(game.random.coinFlip()){
							slideRect = new Rectangle(game.random.rangeInt(Map.BACKGROUND_WIDTH) * Game.SCALE, 0, Game.SCALE, Map.BACKGROUND_HEIGHT * Game.SCALE);
							slideY = game.random.coinFlip() ? 1 : -1;
						} else {
							slideRect = new Rectangle(0, game.random.rangeInt(Map.BACKGROUND_HEIGHT) * Game.SCALE, Map.BACKGROUND_WIDTH * Game.SCALE, Game.SCALE);
							slideX = game.random.coinFlip() ? 1 : -1;
						}
						slideBuffer = new BitmapData(slideRect.width, slideRect.height, true, 0x0);
					}
					for(i = 0; i < automata.length; i++){
						auto = automata[i];
						auto.main();
					}
					renderer.backgroundBitmapData.setVector(renderer.backgroundBitmapData.rect, ChaosAutomata.pixels);
				} else {
					// random sliding background
					if(slideDist){
						point.x = point.y = 0;
						slideBuffer.copyPixels(renderer.backgroundBitmapData, slideRect, point);
						point.x = slideRect.x + slideX * CHAOS_SLIDE_SPEED;
						point.y = slideRect.y + slideY * CHAOS_SLIDE_SPEED;
						renderer.backgroundBitmapData.copyPixels(slideBuffer, slideBuffer.rect, point);
						point.x -= (slideRect.width) * slideX;
						point.y -= (slideRect.height) * slideY;
						renderer.backgroundBitmapData.copyPixels(slideBuffer, slideBuffer.rect, point);
						slideDist -= CHAOS_SLIDE_SPEED;
					} else {
						count = CHAOS_SLIDE_DELAY + game.random.rangeInt(CHAOS_SLIDE_DELAY);
						ChaosAutomata.pixels = renderer.backgroundBitmapData.getVector(renderer.backgroundBitmapData.rect);
					}
				}
			}
			if(quakes){
				if(quakeCount){
					quakeCount--;
					if(quakeCount == 0) game.soundQueue.addRandom("quake", Stone.DEATH_SOUNDS, 0.2);
				} else {
					renderer.createDebrisRect(new Rectangle(renderer.bitmap.x, renderer.bitmap.y, renderer.bitmap.width, renderer.bitmap.height), 0, 200, Renderer.STONE);
					renderer.shake(0, 2 + game.random.rangeInt(4));
					quakeCount = 5 + game.random.rangeInt(5);
					if(quakeHits) quakeHits--;
					else {
						quakeHits = QUAKE_HITS + game.random.rangeInt(QUAKE_HITS);
						quakeCount = QUAKE_DELAY + game.random.rangeInt(QUAKE_DELAY);
					}
				}
			}
		}
		
		public function renderForeground():void{
			if(mapLevel == Map.UNDERWORLD && mapType == Map.AREA){
				// the underworld requires animation of waves
				if(vx < bitmapData.width) vx += WAVE_SPEED;
				else vx = 0;
				point.y = -renderer.bitmap.y + UNDERWORLD_WAVE_HEIGHT * Game.SCALE-bitmapData.height;
				for(point.x = -bitmapData.width + vx; point.x < game.map.width * Game.SCALE; point.x += bitmapData.width){
					renderer.bitmapData.copyPixels(bitmapData, bitmapData.rect, point, null, null, true);
				}
				
			} else if(mapLevel == Map.OVERWORLD && mapType == Map.AREA){
				
				// THE SCRIPTED ENDING TO THE GAME ---------------------------------------------------------
				
				if(endingData){
					// wait for it...
					if(endingData.firstDelay){
						endingData.firstDelay--;
						if(endingData.firstDelay == 0){
							var portal:Portal;
							for(i = 0; i < game.portals.length; i++){
								portal = game.portals[i];
								if(portal.type == Portal.STAIRS && portal.targetLevel == 1 && portal.targetType == Map.MAIN_DUNGEON){
									endingData.stairs = portal;
									break;
								}
							}
							endingData.stairs.playerPortal = false;
							var explosion:Explosion = new Explosion(0, Map.OVERWORLD_STAIRS_X, game.map.height - 2, 3, 0, game.player, null, game.player.missileIgnore);
							game.console.print("chaos dungeon collapses");
							game.soundQueue.playRandom(DUNGEON_DEATH_SOUNDS);
						}
					} else {
						// shower debris and cogs
						if(endingData.debrisDelay){
							endingData.debrisDelay--;
							endingData.screamDelay--;
							if(quakeCount){
								quakeCount--;
								if(quakeCount == 0){
									game.soundQueue.addRandom("quake", Stone.DEATH_SOUNDS, 0.2);
									game.mapTileManager.converter.convertIndicesToObjects(Map.OVERWORLD_STAIRS_X, game.map.height - 2, MapTileConverter.COG_BAT);
								}
							} else {
								renderer.shake(0, 2 + game.random.rangeInt(4));
								quakeCount = 5 + game.random.rangeInt(5);
							}
							if(endingData.screamDelay == 0){
								game.soundQueue.playRandom(DUNGEON_DEATH_SOUNDS);
								endingData.screamDelay = 20 + game.random.rangeInt(60);
							}
							if(endingData.debrisDelay == 0){
								endingData.fxDeathDelay = 10 + game.random.rangeInt(10);
							}
						} else {
							// fragment entrance and rise up with a solitary cog
							var blit:BlitSprite, item:FX;
							if(endingData.debrisRect.width > 0){
								endingData.debrisRect.width -= 0.2;
								endingData.debrisRect.x += 0.1;
							}
							if(!endingData.fx){
								(endingData.stairs.gfx as MovieClip).gotoAndStop("destroy");
								endingData.blits = BlitSprite.getBlitSprites(endingData.stairs.gfx);
								endingData.fx = new Vector.<FX>;
								for(i = 0; i < endingData.blits.length; i++){
									blit = endingData.blits[i];
									item = renderer.addFX(blit.x + endingData.stairs.gfx.x, blit.y + endingData.stairs.gfx.y + 1, blit, new Point(0, game.random.range( -0.5)), 0, false, true);
									renderer.createDebrisExplosion(new Rectangle(item.x, item.y, item.blit.width, item.blit.height), 2, item.blit.width, Renderer.STONE);
									endingData.fx.push(item);
								}
								endingData.cog = renderer.addFX(endingData.stairs.gfx.x + Game.SCALE * 0.5, endingData.stairs.gfx.y + Game.SCALE * 0.5, renderer.cogBlit, new Point(0, -0.25), 0, false, true);
								endingData.stairs.active = false;
								if(game.portalHash[endingData.stairs.hashKey] == endingData.stairs){
									delete game.portalHash[endingData.stairs.hashKey];
								}
							} else {
								if(endingData.fx.length){
									if(endingData.fxDeathDelay){
										endingData.fxDeathDelay--;
									} else {
										i = game.random.rangeInt(endingData.fx.length);
										item = endingData.fx[i];
										renderer.createDebrisRect(new Rectangle(item.x, item.y, item.blit.width, item.blit.height), 0, item.blit.height, Renderer.STONE);
										endingData.fx.splice(i, 1);
										item.active = false;
										game.soundQueue.addRandom("segmentDeath", Stone.DEATH_SOUNDS, 0.2);
										endingData.fxDeathDelay = 5 + game.random.rangeInt(10);
									}
								} else if(!endingData.homePortal){
									endingData.homePortalDelay = 10;
									game.console.print("rng opens the way home");
									endingData.homePortal = Portal.createPortal(Portal.ENDING, endingData.stairs.mapX, endingData.stairs.mapY, 1, Map.MAIN_DUNGEON, Map.OVERWORLD, Map.AREA);
									endingData.homePortal.maskPortalBase(Map.OVERWORLD);
								}
								if(endingData.cog.dir.y){
									if(endingData.cog.y < (game.map.height - 5) * Game.SCALE){
										endingData.cog.dir.y = 0;
									}
								}
							}
							if(endingData.homePortalDelay){
								endingData.homePortalDelay--;
								for(i = 0; i < 4; i++){
									game.lightning.strike(
										renderer.lightningShape.graphics, game.world.map,
										endingData.cog.x,
										endingData.cog.y,
										endingData.stairs.gfx.x + Game.SCALE * 0.5,
										endingData.stairs.gfx.y + game.random.range(Game.SCALE)
									);
								}
							}
							// if the player has left yendor on the floor - take it
							if(endingData.homePortal && endingData.homePortal == game.player.portal){
								var yendor:Item = game.getFloorItem(Item.YENDOR, Item.ARMOUR);
								if(yendor){
									yendor.destroyOnMap(true);
									game.createDistSound(yendor.mapX, yendor.mapY, "teleportYendor", Effect.TELEPORT_SOUNDS);
									game.console.print("rng takes yendor");
								}
							}
							
						}
						if(endingData.debrisRect.width > 0){
							renderer.createDebrisRectDir(endingData.debrisRect, -5 + game.random.range(10), -game.random.range(50), 10, Renderer.STONE);
							renderer.createDebrisRectDir(endingData.debrisRect, -3 + game.random.range(6), -game.random.range(20), 30, Renderer.STONE);
							renderer.createDebrisRectDir(endingData.debrisRect, -1 + game.random.range(2), -game.random.range(10), 5, Renderer.BLOOD);
						}
					}
				}
				
				// not sure I want to keep the following effect because the underworld is also an item warehouse
				
				// the overworld requires an effect over portals to imply the time loop spell
				/*if(game.portals.length){
					var portal:Portal;
					for(i = 0; i < game.portals.length; i++){
						portal = game.portals[i];
						renderer.createSparkRect(new Rectangle(portal.rect.x, portal.rect.y, portal.rect.width, portal.rect.height), 2, 0, -1);
					}
				}*/
			}
		}
		
		public static function getSceneManager(level:int, type:int):SceneManager{
			if(type == Map.AREA){
				return new SceneManager(level, type);
			} else if(type == Map.MAIN_DUNGEON || type == Map.ITEM_DUNGEON){
				// account for being in the test bed
				if(level == -1){
					level = game.gameMenu.editorList.dungeonLevelList.selection
				}
				var zone:int = game.content.getLevelZone(level);
				if(zone == Map.CHAOS || UserData.gameState.husband || game.gameMenu.inventoryList.getItem(Item.YENDOR, Item.ARMOUR)){
					return new SceneManager(level, type);
				}
			}
			return null;
		}
		
	}

}