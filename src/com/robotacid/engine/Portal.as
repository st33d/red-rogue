package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.dungeon.Content;
	import com.robotacid.dungeon.Map;
	import com.robotacid.engine.Entity;
	import com.robotacid.phys.Collider;
	import com.robotacid.ui.MinimapFeature;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
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
		
		private var minimapFeature:MinimapFeature;
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
		public static const ROGUE:int = 1;
		public static const ROGUE_RETURN:int = 2;
		public static const ITEM:int = 3;
		public static const ITEM_RETURN:int = 4;
		public static const MINION:int = 5;
		public static const MONSTER:int = 6;
		
		public static const GFX_CLASSES:Array = [, RoguePortalMC, DungeonPortalMC, DungeonPortalMC, DungeonPortalMC, MinionPortalMC, MonsterPortalMC];
		
		public static const OPEN_CLOSE_DELAY:int = 8;
		public static const SCALE_STEP:Number = 1.0 / OPEN_CLOSE_DELAY;
		public static const GFX_STEP:Number = (SCALE * 0.5) / OPEN_CLOSE_DELAY;
		public static const MONSTERS_PER_LEVEL:int = 2;
		public static const MONSTERS_ENTRY_DELAY:int = 8;
		public static const MINION_HEAL_RATE:Number = 0.05;
		
		public function Portal(gfx:DisplayObject, rect:Rectangle, type:int, targetLevel:int, state:int = OPEN, active:Boolean = true) {
			super(gfx, false, false);
			this.type = type;
			this.rect = rect;
			this.targetLevel = targetLevel;
			this.state = state;
			this.active = active;
			playerPortal = (type != MINION && type != MONSTER)
			callMain = true;
			seen = false;
			if(state == OPENING){
				gfx.scaleX = gfx.scaleY = 0;
				gfx.x += SCALE * 0.5;
				gfx.y += SCALE * 0.5;
				count = OPEN_CLOSE_DELAY;
			}
			if(active) g.portals.push(this);
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
					if(type == MONSTER){
						count = MONSTERS_PER_LEVEL * g.dungeon.level;
					}
				}
			} else if(state == OPEN){
				// if the portal is visible on the map - then make the portal icon on the map visible
				if(!seen && g.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000){
					seen = true;
					var bitmapData:BitmapData = new BitmapData(3, 3, true, 0x00000000);
					if(type == STAIRS){
						if(targetLevel < g.dungeon.level) {
							bitmapData.setPixel32(1, 0, 0xFFFFFFFF);
							bitmapData.fillRect(new Rectangle(0, 1, 3, 1), 0xFFFFFFFF);
						} else if(targetLevel > g.dungeon.level){
							bitmapData.setPixel32(1, 2, 0xFFFFFFFF);
							bitmapData.fillRect(new Rectangle(0, 1, 3, 1), 0xFFFFFFFF);
						}
					} else {
						bitmapData.setPixel32(1, 0, 0xFFFFFFFF);
						bitmapData.setPixel32(1, 2, 0xFFFFFFFF);
						bitmapData.fillRect(new Rectangle(0, 1, 3, 1), 0xFFFFFFFF);
					}
					minimapFeature = g.miniMap.addFeature(mapX, mapY, -1, -1, bitmapData);
				}
				if(type == MINION){
					// heal the minion
					if(g.minion){
						if(g.minion.health < g.minion.totalHealth && g.minion.collider.intersects(rect)){
							g.minion.applyHealth(g.minion.totalHealth * MINION_HEAL_RATE);
							renderer.createTeleportSparkRect(g.minion.collider, 5);
						}
					// or resurrect the minion
					} else {
						var mc:MovieClip = new MinionMC();
						g.minion = new Minion(mc, rect.x + rect.width * 0.5, rect.y + rect.height, Character.SKELETON);
						g.minion.enterLevel(this);
						g.console.print("undead minion returns");
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
								g.entities.push(monster);
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
					if(g.portalHash[type] == this){
						delete g.portalHash[type];
					}
				}
			}
		}
		
		public function close():void{
			g.mapManager.removeTile(this, mapX, mapY, mapZ);
			minimapFeature.active = false;
			free = false;
			state = CLOSING;
		}
		
		/* Creates a black bar over the bottom edge of the overworld return portal to make it neater */
		public function maskOverworldPortal():void{
			var blackOut:Shape = new Shape();
			blackOut.graphics.beginFill(0);
			blackOut.graphics.drawRect(-8, 16, 32, 8);
			blackOut.graphics.endFill();
			(gfx as MovieClip).addChild(blackOut);
		}
		
		/* Creates the type of monster that will pour out of the portal */
		public function setMonsterTemplate(monster:Monster):void{
			monsterTemplate = monster.toXML();
			// strip the monster of items - this is not an item farming spell
			delete monsterTemplate.item;
			monsterTotal = g.dungeon.level * MONSTERS_PER_LEVEL;
			monsterEntryCount = MONSTERS_ENTRY_DELAY;
		}
		
		override public function remove():void {
			g.portals.splice(g.portals.indexOf(this), 1);
			super.remove();
		}
		
		override public function toXML():XML {
			var xml:XML = <portal />;
			xml.@type = type;
			xml.@targetLevel = targetLevel;
			return xml;
		}
		
		/* Used by Map to create a way back to the main dungeon from an item portal */
		public static function getReturnPortalXML():XML{
			var xml:XML = <portal />;
			xml.@type = ITEM_RETURN;
			xml.@targetLevel = Player.previousLevel;
			return xml;
		}
		
		/* Generates a portal within a level - only one portal of each type is allowed in the game */
		public static function createPortal(type:int, mapX:int, mapY:int, targetLevel:int = 0):Portal{
			var i:int, portal:Portal;
			// check that the portal is on a surface - if not cast downwards and put it on one
			while(!(g.world.map[mapY + 1][mapX] & Collider.UP)) mapY++;
			// check we're not obscuring the level stairs.
			// To avoid writing out the logic twice I'm popping an extra iteration in the loop to check the
			// MapTileManager tile position
			for(i = 0; i < g.portals.length + 1; i++){
				if(i < g.portals.length) portal = g.portals[i];
				else portal = g.mapManager.mapLayers[Map.ENTITIES][mapY][mapX] as Portal;
				if(portal && portal.type == STAIRS && portal.mapX == mapX && portal.mapY == mapY){
					// there will be a square to the side of the stairs free - that's the level generation logic
					// check there is floor there
					if(g.world.map[mapY + 1][mapX + 1] & Collider.UP){
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
			if(!g.mapManager.intersects(portal.rect)){
				portal.remove();
			}
			
			// only one player portal of a kind per level, existing portals are closed
			if(type != MONSTER){
				if(g.portalHash[type]){
					g.portalHash[type].close();
				} else {
					// the portal may be on another level, clear this portal type from the content manager
					g.content.removePortalType(type);
				}
				g.portalHash[type] = portal;
			}
			
			// alter or create the opposite end of the rogue portal in the content manager if it doesn't already exist
			if(type == ROGUE){
				var xml:XML;
				if(g.content.portalsByLevel[0].length == 0){
					xml = <portal />;
					xml.@type = ROGUE_RETURN;
					g.content.portalsByLevel[0].push(xml);
				} else {
					xml = g.content.portalsByLevel[0][0];
				}
				xml.@targetLevel = g.dungeon.level;
			}
			
			return portal;
		}
	}

}