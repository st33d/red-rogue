package com.robotacid.ui.menu {
	import com.robotacid.engine.ChaosWall;
	import com.robotacid.engine.FadeLight;
	import com.robotacid.engine.Gate;
	import com.robotacid.level.Content;
	import com.robotacid.level.MapBitmap;
	import com.robotacid.level.Map;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Entity;
	import com.robotacid.engine.MapTileConverter;
	import com.robotacid.engine.MapTileManager;
	import com.robotacid.geom.Pixel;
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.phys.Collider;
	import com.robotacid.ui.Editor;
	import flash.geom.Rectangle;
	/**
	 * A special diagnostic menu for modifying levels to find bugs
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class EditorMenuList extends MenuList {
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		public var menu:GameMenu;
		public var editor:Editor;
		
		public var createBlockList:MenuList;
		public var createObjectList:MenuList;
		
		public var raceList:MenuList;
		public var critterList:MenuList;
		public var gateList:MenuList;
		public var dungeonLevelList:MenuList;
		public var renderList:MenuList;
		
		public var renderCollisionList:MenuList;
		public var renderAIGraphList:MenuList;
		public var renderAIEscapeGraphList:MenuList;
		public var renderAIWallWalkGraphList:MenuList;
		public var renderAIWallWalkEscapeGraphList:MenuList;
		public var renderAIPathsList:MenuList;
		public var renderSurfacesList:MenuList;
		public var lightList:MenuList;
		
		public var blockLayerOption:MenuOption;
		public var objectLayerOption:MenuOption;
		public var dungeonLevelOption:MenuOption;
		public var renderOption:MenuOption;
		public var launchTestBedOption:MenuOption;
		public var remapAIGraphOption:MenuOption;
		public var teleportMinionOption:MenuOption;
		public var teleportBalrogOption:MenuOption;
		public var enterDungeonLevelOption:MenuOption;
		public var debugLightOption:MenuOption;
		public var chaosWallOption:MenuOption;
		public var chaosWallInvasionOption:MenuOption;
		
		public var deleteOption:MenuOption;
		public var onOption:MenuOption;
		public var offOption:MenuOption;
		
		public static const MOUSE_CLICK:int = 0;
		public static const MOUSE_HELD:int = 1;
		
		public static const OFF:int = 0;
		public static const ON:int = 1;
		
		public function EditorMenuList(menu:GameMenu, editor:Editor) {
			var i:int, option:MenuOption;
			this.menu = menu;
			this.editor = editor;
			editor.menuList = this;
			
			createBlockList = new MenuList();
			createObjectList = new MenuList();
			raceList = new MenuList();
			critterList = new MenuList();
			gateList = new MenuList();
			dungeonLevelList = new MenuList();
			renderList = new MenuList();
			renderCollisionList = new MenuList();
			renderAIGraphList = new MenuList();
			renderAIEscapeGraphList = new MenuList();
			renderAIWallWalkGraphList = new MenuList();
			renderAIWallWalkEscapeGraphList = new MenuList();
			renderAIPathsList = new MenuList();
			renderSurfacesList = new MenuList();
			lightList = new MenuList();
			
			blockLayerOption = new MenuOption("block layer", createBlockList);
			objectLayerOption = new MenuOption("object layer", createObjectList);
			dungeonLevelOption = new MenuOption("dungeon level", dungeonLevelList);
			renderOption = new MenuOption("render", renderList);
			launchTestBedOption = new MenuOption("launch test bed");
			launchTestBedOption.selectionStep = 1;
			enterDungeonLevelOption = new MenuOption("enter dungeon level");
			remapAIGraphOption = new MenuOption("remap ai graph");
			remapAIGraphOption.selectionStep = 1;
			teleportMinionOption = new MenuOption("teleport minion", null, false);
			teleportBalrogOption = new MenuOption("teleport balrog", null, false);
			
			deleteOption = new MenuOption("delete", null, false);
			
			var monsterOption:MenuOption = new MenuOption("monster", raceList);
			var critterOption:MenuOption = new MenuOption("critter", critterList);
			var gateOption:MenuOption = new MenuOption("gate", gateList);
			debugLightOption = new MenuOption("debug light", null, false);
			chaosWallOption = new MenuOption("chaos wall", null, false);
			chaosWallInvasionOption = new MenuOption("chaos wall invasion", null, false);
			
			var wallOption:MenuOption = new MenuOption("wall", null, false);
			var ladderOption:MenuOption = new MenuOption("ladder", null, false);
			var ladderLedgeOption:MenuOption = new MenuOption("ladder ledge", null, false);
			var ledgeOption:MenuOption = new MenuOption("ledge", null, false);
			
			var renderCollisionOption:MenuOption = new MenuOption("collision", renderCollisionList);
			var renderAIGraphOption:MenuOption = new MenuOption("ai graph", renderAIGraphList);
			var renderAIEscapeGraphOption:MenuOption = new MenuOption("ai escape graph", renderAIEscapeGraphList);
			var renderAIWallWalkGraphOption:MenuOption = new MenuOption("ai wall walk graph", renderAIWallWalkGraphList);
			var renderAIWallWalkEscapeGraphOption:MenuOption = new MenuOption("ai wall walk escape graph", renderAIWallWalkEscapeGraphList);
			var renderAIPathsOption:MenuOption = new MenuOption("ai paths", renderAIPathsList);
			var renderSurfacesOption:MenuOption = new MenuOption("surfaces", renderSurfacesList);
			var lightOption:MenuOption = new MenuOption("light", lightList);
			
			onOption = new MenuOption("on", null, false);
			offOption = new MenuOption("off", null, false);
			
			options.push(blockLayerOption);
			options.push(objectLayerOption);
			options.push(dungeonLevelOption);
			options.push(renderOption);
			options.push(remapAIGraphOption);
			options.push(teleportMinionOption);
			options.push(teleportBalrogOption);
			options.push(enterDungeonLevelOption);
			options.push(launchTestBedOption);
			
			createBlockList.options.push(deleteOption);
			createBlockList.options.push(wallOption);
			createBlockList.options.push(ladderOption);
			createBlockList.options.push(ladderLedgeOption);
			createBlockList.options.push(ledgeOption);
			
			createObjectList.options.push(monsterOption);
			createObjectList.options.push(critterOption);
			createObjectList.options.push(gateOption);
			createObjectList.options.push(debugLightOption);
			createObjectList.options.push(chaosWallOption);
			createObjectList.options.push(chaosWallInvasionOption);
			
			for(i = 1; i <= 20; i++){
				dungeonLevelList.options.push(new MenuOption(i + " (level)", null, false));
			}
			
			for(i = 0; i < Character.stats["names"].length; i++){
				raceList.options.push(new MenuOption(Character.stats["names"][i], null, false));
			}
			
			critterList.options.push(new MenuOption("spider", null, false));
			critterList.options.push(new MenuOption("rat", null, false));
			critterList.options.push(new MenuOption("bat", null, false));
			critterList.options.push(new MenuOption("cog", null, false));
			critterList.options.push(new MenuOption("cog_spider", null, false));
			critterList.options.push(new MenuOption("cog_rat", null, false));
			critterList.options.push(new MenuOption("cog_bat", null, false));
			
			gateList.options.push(new MenuOption("raise", null, false));
			gateList.options.push(new MenuOption("lock", null, false));
			gateList.options.push(new MenuOption("pressure", null, false));
			gateList.options.push(new MenuOption("chaos", null, false));
			
			// render settings
			renderList.options.push(renderCollisionOption);
			renderList.options.push(renderAIGraphOption);
			renderList.options.push(renderAIEscapeGraphOption);
			renderList.options.push(renderAIWallWalkGraphOption);
			renderList.options.push(renderAIWallWalkEscapeGraphOption);
			renderList.options.push(renderAIPathsOption);
			renderList.options.push(renderSurfacesOption);
			renderList.options.push(lightOption);
			
			renderCollisionList.options.push(offOption);
			renderCollisionList.options.push(onOption);
			renderAIGraphList.options.push(offOption);
			renderAIGraphList.options.push(onOption);
			renderAIEscapeGraphList.options.push(offOption);
			renderAIEscapeGraphList.options.push(onOption);
			renderAIWallWalkGraphList.options.push(offOption);
			renderAIWallWalkGraphList.options.push(onOption);
			renderAIWallWalkEscapeGraphList.options.push(offOption);
			renderAIWallWalkEscapeGraphList.options.push(onOption);
			renderAIPathsList.options.push(offOption);
			renderAIPathsList.options.push(onOption);
			renderSurfacesList.options.push(offOption);
			renderSurfacesList.options.push(onOption);
			lightList.options.push(offOption);
			lightList.options.push(onOption);
		}
		
		/* Performs an action at mapX, mapY based on the current configuration of the EditorMenuList */
		public function applySelection(mapX:int, mapY:int, type:int):void{
			var list:MenuList = menu.currentMenuList;
			var option:MenuOption = list.options[list.selection];
			var converter:MapTileConverter = game.mapTileManager.converter;
			var mapRect:Rectangle = new Rectangle(mapX * Game.SCALE, mapY * Game.SCALE, Game.SCALE, Game.SCALE);
			var id:int, blit:BlitRect, entity:Entity, xml:XML;
			
			if(type <= MOUSE_HELD){
				if(option == deleteOption){
					if(list == createBlockList){
						game.world.removeMapPosition(mapX, mapY);
						renderer.blockBitmapData.fillRect(mapRect, 0x0);
						game.map.bitmap.bitmapData.setPixel32(mapX, mapY, MapBitmap.EMPTY);
					}
				} else if(list == createBlockList){
					if(option.name == "wall"){
						id = MapTileConverter.WALL;
						game.map.bitmap.bitmapData.setPixel32(mapX, mapY, MapBitmap.WALL);
					} else if(option.name == "ladder"){
						id = MapTileConverter.LADDER;
						game.map.bitmap.bitmapData.setPixel32(mapX, mapY, MapBitmap.LADDER);
					} else if(option.name == "ledge"){
						id = MapTileConverter.LEDGE;
						game.map.bitmap.bitmapData.setPixel32(mapX, mapY, MapBitmap.LEDGE);
					} else if(option.name == "ladder ledge"){
						id = MapTileConverter.LADDER_LEDGE;
						game.map.bitmap.bitmapData.setPixel32(mapX, mapY, MapBitmap.LADDER_LEDGE);
					}
					game.world.map[mapY][mapX] = MapTileConverter.getMapProperties(id);
					game.mapTileManager.changeLayer(MapTileManager.BLOCK_LAYER);
					blit = converter.convertIndicesToObjects(mapX, mapY, id) as BlitRect;
					blit.x = mapX * Game.SCALE;
					blit.y = mapY * Game.SCALE;
					renderer.blockBitmapData.fillRect(mapRect, 0x0);
					blit.render(renderer.blockBitmapData);
				}
			}
			if(type == MOUSE_CLICK){
				if(list == critterList){
					if(option.name == "spider") id = MapTileConverter.SPIDER;
					else if(option.name == "rat") id = MapTileConverter.RAT;
					else if(option.name == "bat") id = MapTileConverter.BAT;
					else if(option.name == "cog") id = MapTileConverter.COG;
					else if(option.name == "cog_spider") id = MapTileConverter.COG_SPIDER;
					else if(option.name == "cog_rat") id = MapTileConverter.COG_RAT;
					else if(option.name == "cog_bat") id = MapTileConverter.COG_BAT;
					converter.convertIndicesToObjects(mapX, mapY, id);
					
				} else if(list == raceList){
					xml =<character characterNum={-1} name={raceList.selection} type={Character.MONSTER} level={dungeonLevelList.selection + 1} />;
					entity = Content.XMLToEntity(mapX, mapY, xml);
					converter.convertIndicesToObjects(mapX, mapY, entity);
					
				} else if(list == gateList){
					game.mapTileManager.mapLayers[MapTileManager.ENTITY_LAYER][mapY][mapX] = converter.convertIndicesToObjects(
						mapX, mapY, new Gate(mapX * Game.SCALE, mapY * Game.SCALE, gateList.selection)
					);
					
				} else if(option == chaosWallOption){
					if(!ChaosWall.chaosWalls[mapY][mapX]){
						game.world.map[mapY][mapX] = MapTileConverter.getMapProperties(MapTileConverter.WALL);
						game.mapTileManager.changeLayer(MapTileManager.BLOCK_LAYER);
						blit = converter.convertIndicesToObjects(mapX, mapY, MapTileConverter.WALL) as BlitRect;
						blit.x = mapX * Game.SCALE;
						blit.y = mapY * Game.SCALE;
						renderer.blockBitmapData.fillRect(mapRect, 0x0);
						blit.render(renderer.blockBitmapData);
						game.mapTileManager.mapLayers[MapTileManager.ENTITY_LAYER][mapY][mapX] = converter.convertIndicesToObjects(
							mapX, mapY, new ChaosWall(mapX, mapY)
						);
					}
					
				} else if(option == debugLightOption){
					var fadeLight:FadeLight = new FadeLight(FadeLight.DEBUG, mapX, mapY);
					
				} else if(option == chaosWallInvasionOption){
					ChaosWall.initInvasionSite(mapX, mapY);
					
				} else if(option == teleportMinionOption){
					if(game.minion) Effect.teleportCharacter(game.minion, new Pixel(mapX, mapY));
					
				} else if(option == teleportBalrogOption){
					if(game.balrog) Effect.teleportCharacter(game.balrog, new Pixel(mapX, mapY));
					
				}
			}
		}
		
		public function setLight(n:int):void{
			if(n == OFF){
				game.map.type = Map.AREA;
				renderer.lightBitmap.visible = false;
			
			} else if(n == ON){
				game.map.type = Map.MAIN_DUNGEON;
				renderer.lightBitmap.visible = true;
			}
		}
		
	}

}