package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.level.Content;
	import com.robotacid.level.Map;
	import com.robotacid.engine.Entity;
	import com.robotacid.gfx.BlitClip;
	import com.robotacid.phys.Collider;
	import com.robotacid.ui.MinimapFX;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * A gateway for Characters to enter or exit the level
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Portal extends Entity{
		
		public var state:int;
		public var type:int;
		public var seen:Boolean;
		public var targetLevel:int;
		public var targetType:int;
		public var playerPortal:Boolean;
		public var hashKey:String;
		
		public var rect:Rectangle;
		
		private var count:int;
		private var backgroundBuffer:BitmapData;
		
		private var minimapFX:MinimapFX;
		private var cloneTemplate:XML;
		private var cloneEntryCount:int;
		private var cloneTotal:int;
		private var clone:Character;
		
		// states
		public static const OPEN:int = 0;
		public static const OPENING:int = 1;
		public static const CLOSING:int = 2;
		
		// types
		public static const STAIRS:int = 0;
		public static const PORTAL:int = 1;
		public static const MONSTER:int = 2;
		public static const ENDING:int = 3;
		public static const MINION:int = 4;
		
		public static const OPEN_CLOSE_DELAY:int = 8;
		public static const SCALE_STEP:Number = 1.0 / OPEN_CLOSE_DELAY;
		public static const GFX_STEP:Number = (SCALE * 0.5) / OPEN_CLOSE_DELAY;
		public static const CLONE_ENTRY_DELAY:int = 8;
		public static const UNDEAD_HEAL_RATE:Number = 0.05;
		
		public function Portal(gfx:DisplayObject, rect:Rectangle, type:int, targetLevel:int, targetType:int, state:int = OPEN, active:Boolean = true){
			super(gfx, false, false);
			this.type = type;
			this.rect = rect;
			this.targetLevel = targetLevel;
			this.targetType = targetType;
			this.state = state;
			this.active = active;
			playerPortal = type != MONSTER && type != MINION;
			hashKey = "type" + type + "targetLevel" + targetLevel + "targetType" + targetType;
			callMain = true;
			seen = false;
			if(state == OPENING){
				game.soundQueue.add("portalOpen");
				gfx.scaleX = gfx.scaleY = 0;
				gfx.x += SCALE * 0.5;
				gfx.y += SCALE * 0.5;
				count = OPEN_CLOSE_DELAY;
			}
			if(active) game.portals.push(this);
		}
		
		override public function main():void {
			var eraseRect:Rectangle;
			if(state == OPENING){
				if(count){
					count--;
					gfx.scaleX += SCALE_STEP;
					gfx.scaleY += SCALE_STEP;
					gfx.x -= GFX_STEP;
					gfx.y -= GFX_STEP;
					// erase the background
					eraseRect = new Rectangle((mapX + 0.5) * SCALE - count, (mapY + 0.5) * SCALE - count, count * 2, count * 2);
					renderer.blockBitmapData.fillRect(eraseRect, 0x0);
				} else {
					gfx.scaleX = gfx.scaleY = 1;
					gfx.x = mapX * SCALE;
					gfx.y = mapY * SCALE;
					state = OPEN;
					// erase the background
					eraseRect = new Rectangle(mapX * SCALE, mapY * SCALE, SCALE, SCALE);
				}
			} else if(state == OPEN){
				// if the portal is visible on the map - then make the portal icon on the map visible
				if(!seen && game.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000){
					reveal();
				}
				// shit out clones
				if(type == MONSTER || type == MINION){
					if(cloneEntryCount) cloneEntryCount--;
					else{
						if(clone){
							if(clone.state != Character.ENTERING) clone = null;
						} else {
							if(cloneTotal){
								cloneTotal--;
								if(type == MINION){
									clone = new MinionClone(game.library.getCharacterGfx(Character.SKELETON), (mapX + 0.5) * Game.SCALE, (mapY + 1) * Game.SCALE, Character.SKELETON, Character.MINION, game.random.rangeInt(game.player.level));
								} else if(type == MONSTER){
									clone = Content.XMLToEntity(mapX, mapY, cloneTemplate);
									Brain.monsterCharacters.push(clone);
									if(game.map.completionCount){
										game.map.completionCount++;
										game.map.completionTotal++;
									}
								}
								game.entities.push(clone);
								clone.enterLevel(this);
								cloneEntryCount = CLONE_ENTRY_DELAY;
							} else {
								close();
							}
						}
					}
				// heal the undead
				} else if(targetType == Map.AREA && targetLevel == Map.UNDERWORLD){
					if(
						game.player.undead &&
						game.player.health < game.player.totalHealth &&
						game.player.collider.x + game.player.collider.width > rect.x &&
						rect.x + rect.width > game.player.collider.x &&
						game.player.collider.y + game.player.collider.height > rect.y &&
						rect.y + rect.height > game.player.collider.y
					){
						game.player.applyHealth(game.player.totalHealth * UNDEAD_HEAL_RATE);
						renderer.createSparkRect(game.player.collider, 5, 0, -1, character.debrisType);
					}
					var character:Character;
					for(var i:int = 0; i < game.entities.length; i++){
						character = game.entities[i] as Character;
						if(
							character &&
							character.undead &&
							character.health < character.totalHealth &&
							character.collider.x + character.collider.width > rect.x &&
							rect.x + rect.width > character.collider.x &&
							character.collider.y + character.collider.height > rect.y &&
							rect.y + rect.height > character.collider.y
						){
							character.applyHealth(character.totalHealth * UNDEAD_HEAL_RATE);
							renderer.createSparkRect(character.collider, 5, 0, -1, character.debrisType);
						}
					}
					// resurrect the minion if dead
					if(!game.minion && !UserData.settings.minionConsumed){
						UserData.initMinion();
						var mc:MovieClip = new SkeletonMC();
						game.minion = new Minion(mc, rect.x + rect.width * 0.5, rect.y + rect.height, Character.SKELETON);
						game.entities.push(game.minion);
						game.minion.enterLevel(this);
						game.minion.brain.clear();
						game.minion.addMinimapFeature();
						game.console.print("undead minion returns from underworld");
					}
					
				}
			} else if(state == CLOSING){
				if(count){
					count--;
					gfx.scaleX -= SCALE_STEP;
					gfx.scaleY -= SCALE_STEP;
					gfx.x += GFX_STEP;
					gfx.y += GFX_STEP;
					// paint and erase
					if(backgroundBuffer){
						renderer.blockBitmapData.copyPixels(backgroundBuffer, backgroundBuffer.rect, new Point(mapX * SCALE, mapY * SCALE));
						// erase the background
						eraseRect = new Rectangle((mapX + 0.5) * SCALE - count, (mapY + 0.5) * SCALE - count, count * 2, count * 2);
						renderer.blockBitmapData.fillRect(eraseRect, 0x0);
					}
				} else {
					if(backgroundBuffer){
						renderer.blockBitmapData.copyPixels(backgroundBuffer, backgroundBuffer.rect, new Point(mapX * SCALE, mapY * SCALE));
					}
					active = false;
					if(game.portalHash[hashKey] == this){
						delete game.portalHash[hashKey];
					}
				}
			}
		}
		
		public function close():void{
			game.mapTileManager.removeTile(this, mapX, mapY, mapZ);
			if(minimapFX) minimapFX.active = false;
			free = false;
			state = CLOSING;
			count = OPEN_CLOSE_DELAY;
			game.soundQueue.add("portalClose");
		}
		
		/* Creates the appropriate minimap feature for the portal */
		public function reveal():void{
			seen = true;
			var blit:BlitClip, item:MinimapFX;
			if(type == STAIRS){
				if(targetLevel < game.map.level) {
					blit = renderer.stairsUpFeatureBlit;
				} else if(targetLevel > game.map.level){
					blit = renderer.stairsDownFeatureBlit;
				} else {
					// if we are here, something is wrong with the stairs
					blit = renderer.portalFeatureBlit;
				}
				// fetch for an existing minimap feature that may have been created by a map reveal
				for(var i:int = 0; i < game.miniMap.fx.length; i++){
					item = game.miniMap.fx[i];
					if(item.blit == blit){
						minimapFX = item;
						return;
					}
				}
			} else {
				blit = renderer.portalFeatureBlit;
			}
			minimapFX = game.miniMap.addFeature(mapX, mapY, blit, this != game.entrance);
		}
		
		/* Covers the bottom edge of a portal to make it neater in outside areas */
		public function maskPortalBase(level:int):void{
			var blackOut:Shape = new Shape();
			var bitmap:Bitmap;
			if(level == Map.OVERWORLD) bitmap = new game.library.OverworldB();
			else if(level == Map.UNDERWORLD) bitmap = new game.library.UnderworldB();
			blackOut.graphics.beginBitmapFill(bitmap.bitmapData, new Matrix(1, 0, 0, 1, -mapX * Game.SCALE, -mapY * Game.SCALE), false);
			blackOut.graphics.drawRect(-8, 16, 32, 8);
			blackOut.graphics.endFill();
			(gfx as MovieClip).addChild(blackOut);
		}
		
		/* Creates the type of monster that will pour out of the portal */
		public function setCloneTemplate(xml:XML = null):void{
			if(xml){
				cloneTemplate = xml;
				cloneTemplate.@characterNum = -1;
				// strip the monster of items - this is not an item farm
				delete cloneTemplate.item;
			}
			cloneTotal = 1 + game.map.zone;
			cloneEntryCount = CLONE_ENTRY_DELAY;
		}
		
		override public function remove():void {
			game.portals.splice(game.portals.indexOf(this), 1);
			super.remove();
		}
		
		override public function toXML():XML {
			return <portal type={type} targetLevel={targetLevel} targetType={targetType} />;
		}
		
		/* Used by Map to create a way back to the main dungeon from an item portal */
		public static function getItemReturnPortalXML():XML{
			return <portal type={PORTAL} targetLevel={Player.previousLevel} targetType={Player.previousMapType} />;
		}
		
		/* Generates a portal within a level - only one portal between each area is allowed in the game */
		public static function createPortal(type:int, mapX:int, mapY:int, targetLevel:int = 0, targetType:int = 0, fromLevel:int = 0, fromType:int = 0):Portal{
			var i:int, portal:Portal;
			// check that the portal is on a surface - if not cast downwards and put it on one
			while(!(game.world.map[mapY + 1][mapX] & Collider.UP)) mapY++;
			// check we're not obscuring the level stairs.
			// To avoid writing out the logic twice I'm popping an extra iteration in the loop to check the
			// MapTileManager tile position
			for(i = 0; i < game.portals.length + 1; i++){
				if(i < game.portals.length) portal = game.portals[i];
				else portal = game.mapTileManager.mapLayers[Map.ENTITIES][mapY][mapX] as Portal;
				if(portal && portal.type == STAIRS && portal.mapX == mapX && portal.mapY == mapY){
					// there will be a square to the side of the stairs free - that's the level generation logic
					// check there is floor there
					if(game.world.map[mapY + 1][mapX + 1] & Collider.UP){
						mapX++;
					// fuck it - they can jump for the portal, they should have the sense not to put it in front of stairs
					} else {
						mapX--;
					}
					break;
				}
			}
			var rect:Rectangle = new Rectangle(mapX * SCALE, mapY * SCALE, SCALE, SCALE);
			var mc:MovieClip = getPortalGfx(type, mapX, mapY, targetLevel, targetType, fromLevel, fromType);
			portal = new Portal(mc, rect, type, targetLevel, targetType, OPENING);
			portal.mapX = mapX;
			portal.mapY = mapY;
			portal.mapZ = Map.ENTITIES;
			portal.backgroundBuffer = new BitmapData(SCALE, SCALE, true, 0x0);
			portal.backgroundBuffer.copyPixels(renderer.blockBitmapData, rect, new Point);
			
			// the portal may have been generated outside of the mapRenderer zone
			if(!game.mapTileManager.intersects(portal.rect)){
				portal.remove();
			}
			
			// only one player portal of a kind per level, existing portals are closed
			if(type != MONSTER){
				if(game.portalHash[portal.hashKey]){
					game.portalHash[portal.hashKey].close();
				} else {
					// the portal may be on another level, clear this portal type from the content manager
					game.content.removePortal(targetLevel, targetType);
				}
				game.portalHash[portal.hashKey] = portal;
			}
			
			// retarget overworld or underworld portals
			if(targetType == Map.AREA){
				if(targetLevel == Map.OVERWORLD){
					Content.setOverworldPortal(game.map.level, game.map.type);
				} else if(targetLevel == Map.UNDERWORLD){
					Content.setUnderworldPortal(game.map.level, game.map.type);
				}
			}
			
			return portal;
		}
		
		public static function getPortalGfx(type:int, mapX:int, mapY:int, targetLevel:int, targetType:int, fromLevel:int, fromType:int):MovieClip{
			var mc:MovieClip = new PortalMC;
			mc.x = mapX * SCALE;
			mc.y = mapY * SCALE;
			if(type == MONSTER){
				mc.dest.gotoAndStop("monster");
				mc.dir.visible = false;
			} else if(type == MINION){
				mc.dest.gotoAndStop("underworld");
				mc.dir.visible = false;
			} else if(type == ENDING){
				mc.dest.gotoAndStop("home");
				mc.dir.gotoAndStop("up");
			} else {
				if(targetType == Map.AREA){
					if(targetLevel == Map.OVERWORLD){
						mc.dest.gotoAndStop("overworld");
						mc.dir.gotoAndStop("up");
					} else if(targetLevel == Map.UNDERWORLD){
						mc.dest.gotoAndStop("underworld");
						mc.dir.gotoAndStop("down");
					}
				} else if(targetType == Map.ITEM_DUNGEON){
					mc.dest.gotoAndStop("dungeon");
					mc.dir.gotoAndStop("down");
					
				} else if(targetType == Map.MAIN_DUNGEON){
					mc.dest.gotoAndStop("dungeon");
					if(fromType == Map.AREA){
						if(fromLevel == Map.OVERWORLD) mc.dir.gotoAndStop("down");
						else if(fromLevel == Map.UNDERWORLD) mc.dir.gotoAndStop("up");
						
					} else if(fromType == Map.ITEM_DUNGEON){
						mc.dir.gotoAndStop("up");
					}
				}
			}
			return mc;
		}
		
		/* Returns the report for the console when the player uses a given portal */
		public static function usageMsg(type:int, targetLevel:int, targetType:int):String{
			if(type == Portal.STAIRS){
				if(targetLevel == Map.OVERWORLD){
					return "ascended to overworld";
				} else {
					return (targetLevel > game.map.level ? "descended" : "ascended") + " to level " + targetLevel;
				}
			} else {
				if(targetType == Map.AREA){
					if(targetLevel == Map.OVERWORLD) return "travelled to overworld";
					else if(targetLevel == Map.UNDERWORLD)  return "travelled to underworld";
				} else if(targetType == Map.ITEM_DUNGEON){
					return "travelled to pocket dungeon";
				} else if(targetType == Map.MAIN_DUNGEON){
					return "returned to level " + targetLevel;
				}
			}
			return "went to fuck knows where";
		}
	}

}