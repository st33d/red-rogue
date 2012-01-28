package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.dungeon.Content;
	import com.robotacid.dungeon.Map;
	import com.robotacid.engine.Entity;
	import com.robotacid.gfx.BlitClip;
	import com.robotacid.phys.Collider;
	import com.robotacid.ui.MinimapFX;
	import flash.display.Bitmap;
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
		public var playerPortal:Boolean;
		
		public var rect:Rectangle;
		
		private var count:int;
		
		private var minimapFX:MinimapFX;
		private var monsterTemplate:XML;
		private var monsterEntryCount:int;
		private var monsterTotal:int;
		private var monster:Monster;
		
		// states
		public static const OPEN:int = 0;
		public static const OPENING:int = 1;
		public static const CLOSING:int = 2;
		
		// types
		public static const STAIRS:int = 0;
		public static const OVERWORLD:int = 1;
		public static const OVERWORLD_RETURN:int = 2;
		public static const ITEM:int = 3;
		public static const ITEM_RETURN:int = 4;
		public static const UNDERWORLD:int = 5;
		public static const UNDERWORLD_RETURN:int = 6;
		public static const MONSTER:int = 7;
		
		public static const GFX_CLASSES:Array = [, OverworldPortalMC, DungeonPortalMC, DungeonPortalMC, DungeonPortalMC, UnderworldPortalMC, DungeonPortalMC, MonsterPortalMC];
		
		public static const OPEN_CLOSE_DELAY:int = 8;
		public static const SCALE_STEP:Number = 1.0 / OPEN_CLOSE_DELAY;
		public static const GFX_STEP:Number = (SCALE * 0.5) / OPEN_CLOSE_DELAY;
		public static const MONSTERS_ENTRY_DELAY:int = 8;
		public static const UNDEAD_HEAL_RATE:Number = 0.05;
		
		public function Portal(gfx:DisplayObject, rect:Rectangle, type:int, targetLevel:int, state:int = OPEN, active:Boolean = true) {
			super(gfx, false, false);
			this.type = type;
			this.rect = rect;
			this.targetLevel = targetLevel;
			this.state = state;
			this.active = active;
			playerPortal = type != MONSTER;
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
			if(state == OPENING){
				if(count){
					count--;
					gfx.scaleX += SCALE_STEP;
					gfx.scaleY += SCALE_STEP;
					gfx.x -= GFX_STEP;
					gfx.y -= GFX_STEP;
				} else {
					gfx.scaleX = gfx.scaleY = 1;
					gfx.x = mapX * SCALE;
					gfx.y = mapY * SCALE;
					state = OPEN;
				}
			} else if(state == OPEN){
				// if the portal is visible on the map - then make the portal icon on the map visible
				if(!seen && game.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000){
					seen = true;
					var blit:BlitClip;
					if(type == STAIRS){
						if(targetLevel < game.dungeon.level) {
							blit = renderer.stairsUpFeatureBlit;
						} else if(targetLevel > game.dungeon.level){
							blit = renderer.stairsDownFeatureBlit;
						}
					} else {
						blit = renderer.portalFeatureBlit;
					}
					minimapFX = game.miniMap.addFeature(mapX, mapY, blit, this != game.entrance);
				}
				if(type == UNDERWORLD){
					// heal the undead
					if(game.player.undead && game.player.health < game.player.totalHealth && game.player.collider.intersects(rect)){
						game.player.applyHealth(game.player.totalHealth * UNDEAD_HEAL_RATE);
						renderer.createTeleportSparkRect(game.player.collider, 5);
					}
					var character:Character;
					for(var i:int = 0; i < game.entities.length; i++){
						character = game.entities[i] as Character;
						if(character && character.undead && character.health < character.totalHealth && character.collider.intersects(rect)){
							character.applyHealth(character.totalHealth * UNDEAD_HEAL_RATE);
							renderer.createTeleportSparkRect(character.collider, 5);
						}
					}
					// resurrect the minion if dead
					if(!game.minion){
						var mc:MovieClip = new SkeletonMC();
						game.minion = new Minion(mc, rect.x + rect.width * 0.5, rect.y + rect.height, Character.SKELETON);
						game.minion.enterLevel(this);
						game.console.print("undead minion returns");
					}
					
				} else if(type == MONSTER){
					// shit out monsters
					if(monsterEntryCount) monsterEntryCount--;
					else{
						if(monster){
							if(monster.state != Character.ENTERING) monster = null;
						} else {
							if(monsterTotal){
								monsterTotal--;
								monster = Content.convertXMLToEntity(mapX, mapY, monsterTemplate);
								game.entities.push(monster);
								Brain.monsterCharacters.push(monster);
								monster.enterLevel(this);
								monsterEntryCount = MONSTERS_ENTRY_DELAY;
							} else {
								close();
							}
						}
					}
				}
			} else if(state == CLOSING){
				if(count){
					count--;
					gfx.scaleX -= SCALE_STEP;
					gfx.scaleY -= SCALE_STEP;
					gfx.x += GFX_STEP;
					gfx.y += GFX_STEP;
				} else {
					active = false;
					if(game.portalHash[type] == this){
						delete game.portalHash[type];
					}
				}
			}
		}
		
		public function close():void{
			game.mapTileManager.removeTile(this, mapX, mapY, mapZ);
			minimapFX.active = false;
			free = false;
			state = CLOSING;
			count = OPEN_CLOSE_DELAY;
			game.soundQueue.add("portalClose");
		}
		
		/* Covers the bottom edge of a portal to make it neater in outside areas */
		public function maskPortalBase():void{
			var blackOut:Shape = new Shape();
			var bitmap:Bitmap;
			if(type == OVERWORLD_RETURN) bitmap = new game.library.OverworldB();
			else if(type == UNDERWORLD_RETURN) bitmap = new game.library.UnderworldB();
			blackOut.graphics.beginBitmapFill(bitmap.bitmapData, new Matrix(1, 0, 0, 1, -mapX * Game.SCALE, -mapY * Game.SCALE), false);
			blackOut.graphics.drawRect(-8, 16, 32, 8);
			blackOut.graphics.endFill();
			(gfx as MovieClip).addChild(blackOut);
		}
		
		/* Creates the type of monster that will pour out of the portal */
		public function setMonsterTemplate(xml:XML):void{
			monsterTemplate = xml;
			// strip the monster of items - this is not an item farming spell
			delete monsterTemplate.item;
			monsterTotal = game.dungeon.level < Game.MAX_LEVEL ? game.dungeon.level : Game.MAX_LEVEL;
			monsterEntryCount = MONSTERS_ENTRY_DELAY;
		}
		
		override public function remove():void {
			game.portals.splice(game.portals.indexOf(this), 1);
			super.remove();
		}
		
		override public function toXML():XML {
			return <portal type={type} targetLevel={targetLevel} />;
		}
		
		/* Used by Map to create a way back to the main dungeon from an item portal */
		public static function getItemReturnPortalXML():XML{
			return <portal type={ITEM_RETURN} targetLevel={Player.previousLevel}/>;
		}
		
		/* Generates a portal within a level - only one portal of each type is allowed in the game */
		public static function createPortal(type:int, mapX:int, mapY:int, targetLevel:int = 0):Portal{
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
			var mc:MovieClip = new GFX_CLASSES[type]();
			mc.x = mapX * SCALE;
			mc.y = mapY * SCALE;
			portal = new Portal(mc, new Rectangle(mapX * SCALE, mapY * SCALE, SCALE, SCALE), type, targetLevel, OPENING);
			portal.mapX = mapX;
			portal.mapY = mapY;
			portal.mapZ = Map.ENTITIES;
			
			// the portal may have been generated outside of the mapRenderer zone
			if(!game.mapTileManager.intersects(portal.rect)){
				portal.remove();
			}
			
			// only one player portal of a kind per level, existing portals are closed
			if(type != MONSTER){
				if(game.portalHash[type]){
					game.portalHash[type].close();
				} else {
					// the portal may be on another level, clear this portal type from the content manager
					game.content.removePortalType(type);
				}
				game.portalHash[type] = portal;
			}
			
			// retarget overworld or underworld portals
			if(type == OVERWORLD){
				game.content.setOverworldPortal(game.dungeon.level);
			} else if(type == UNDERWORLD){
				game.content.setUnderworldPortal(game.dungeon.level);
			}
			
			return portal;
		}
		
		/* Returns the report for the console when the player uses a given portal */
		public static function usageMsg(type:int, targetLevel:int):String{
			if(type == Portal.STAIRS){
				if(targetLevel == Map.OVERWORLD){
					return "ascended to overworld";
				} else {
					return (targetLevel > game.dungeon.level ? "descended" : "ascended") + " to level " + targetLevel;
				}
			} else if(type == Portal.OVERWORLD){
				return "travelled to overworld";
			} else if(
				type == Portal.OVERWORLD_RETURN ||
				type == Portal.ITEM_RETURN ||
				type == Portal.UNDERWORLD_RETURN
			) return "returned to level " + targetLevel;
			else if(type == Portal.ITEM) return "travelled to retrieve item";
			else if(type == Portal.UNDERWORLD) return "travelled to underworld";
			return "fuck knows where you're going now";
		}
	}

}