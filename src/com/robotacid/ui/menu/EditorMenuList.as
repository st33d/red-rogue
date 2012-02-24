package com.robotacid.ui.menu {
	import com.robotacid.dungeon.Content;
	import com.robotacid.dungeon.DungeonBitmap;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Entity;
	import com.robotacid.engine.MapTileConverter;
	import com.robotacid.engine.MapTileManager;
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.phys.Collider;
	import com.robotacid.ui.Editor;
	import flash.geom.Rectangle;
	/**
	 * ...
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
		public var dungeonLevelList:MenuList;
		public var renderList:MenuList;
		
		public var renderCollisionList:MenuList;
		public var renderAIGraphList:MenuList;
		
		public var blockLayerOption:MenuOption;
		public var objectLayerOption:MenuOption;
		public var dungeonLevelOption:MenuOption;
		public var renderOption:MenuOption;
		public var launchTestBedOption:MenuOption;
		public var remapAIGraphOption:MenuOption;
		
		public var renderCollisionOption:MenuOption;
		public var renderAIGraphOption:MenuOption;
		
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
			dungeonLevelList = new MenuList();
			renderList = new MenuList();
			renderCollisionList = new MenuList();
			renderAIGraphList = new MenuList();
			
			blockLayerOption = new MenuOption("block layer", createBlockList);
			objectLayerOption = new MenuOption("object layer", createObjectList);
			dungeonLevelOption = new MenuOption("dungeon level", dungeonLevelList);
			renderOption = new MenuOption("render", renderList);
			launchTestBedOption = new MenuOption("launch test bed");
			launchTestBedOption.selectionStep = 1;
			remapAIGraphOption = new MenuOption("remap ai graph");
			remapAIGraphOption.selectionStep = 1;
			
			deleteOption = new MenuOption("delete", null, false);
			
			var monsterOption:MenuOption = new MenuOption("monster", raceList);
			var critterOption:MenuOption = new MenuOption("critter", critterList);
			
			var wallOption:MenuOption = new MenuOption("wall", null, false);
			var ladderOption:MenuOption = new MenuOption("ladder", null, false);
			var ladderLedgeOption:MenuOption = new MenuOption("ladder ledge", null, false);
			var ledgeOption:MenuOption = new MenuOption("ledge", null, false);
			
			renderCollisionOption = new MenuOption("collision", renderCollisionList);
			renderAIGraphOption = new MenuOption("ai graph", renderAIGraphList);
			
			onOption = new MenuOption("on", null, false);
			offOption = new MenuOption("off", null, false);
			
			options.push(blockLayerOption);
			options.push(objectLayerOption);
			options.push(dungeonLevelOption);
			options.push(renderOption);
			options.push(launchTestBedOption);
			options.push(remapAIGraphOption);
			
			createBlockList.options.push(deleteOption);
			createBlockList.options.push(wallOption);
			createBlockList.options.push(ladderOption);
			createBlockList.options.push(ladderLedgeOption);
			createBlockList.options.push(ledgeOption);
			
			createObjectList.options.push(monsterOption);
			createObjectList.options.push(critterOption);
			
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
			
			// render settings
			renderList.options.push(renderCollisionOption);
			renderList.options.push(renderAIGraphOption);
			
			renderCollisionList.options.push(offOption);
			renderCollisionList.options.push(onOption);
			renderAIGraphList.options.push(offOption);
			renderAIGraphList.options.push(onOption);
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
						renderer.blockBitmapData.fillRect(mapRect, 0x00000000);
					}
				} else if(list == createBlockList){
					if(option.name == "wall"){
						id = MapTileConverter.WALL;
						game.dungeon.bitmap.bitmapData.setPixel32(mapX, mapY, DungeonBitmap.WALL);
					} else if(option.name == "ladder"){
						id = MapTileConverter.LADDER;
						game.dungeon.bitmap.bitmapData.setPixel32(mapX, mapY, DungeonBitmap.LADDER);
					} else if(option.name == "ledge"){
						id = MapTileConverter.LEDGE;
						game.dungeon.bitmap.bitmapData.setPixel32(mapX, mapY, DungeonBitmap.LEDGE);
					} else if(option.name == "ladder ledge"){
						id = MapTileConverter.LADDER_LEDGE;
						game.dungeon.bitmap.bitmapData.setPixel32(mapX, mapY, DungeonBitmap.LADDER_LEDGE);
					}
					game.world.map[mapY][mapX] = MapTileConverter.getMapProperties(id);
					game.mapTileManager.changeLayer(MapTileManager.BLOCK_LAYER);
					blit = converter.convertIndicesToObjects(mapX, mapY, id) as BlitRect;
					blit.x = mapX * Game.SCALE;
					blit.y = mapY * Game.SCALE;
					renderer.blockBitmapData.fillRect(mapRect, 0x00000000);
					blit.render(renderer.blockBitmapData);
				}
			}
			if(type == MOUSE_CLICK){
				if(list == critterList){
					if(option.name == "spider") id = MapTileConverter.SPIDER;
					else if(option.name == "rat") id = MapTileConverter.RAT;
					else if(option.name == "bat") id = MapTileConverter.BAT;
					else if(option.name == "cog") id = MapTileConverter.COG;
					converter.convertIndicesToObjects(mapX, mapY, id);
					
				} else if(list == raceList){
					xml =<character characterNum={-1} name={raceList.selection} type={Character.MONSTER} level={dungeonLevelList.selection + 1} />;
					entity = Content.convertXMLToEntity(mapX, mapY, xml);
					converter.convertIndicesToObjects(mapX, mapY, entity);
				}
			}
		}
		
	}

}