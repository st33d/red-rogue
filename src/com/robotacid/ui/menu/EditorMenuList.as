package com.robotacid.ui.menu {
	import com.robotacid.engine.Character;
	import com.robotacid.engine.MapTileConverter;
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
		
		public var blockList:MenuList;
		public var objectList:MenuList;
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
		
		public var renderCollisionOption:MenuOption;
		public var renderAIGraphOption:MenuOption;
		
		public var createBlockOption:MenuOption;
		public var createObjectOption:MenuOption;
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
			blockList = new MenuList();
			objectList = new MenuList();
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
			
			createBlockOption = new MenuOption("create", blockList);
			createObjectOption = new MenuOption("create", objectList);
			deleteOption = new MenuOption("delete", null, false);
			
			var monsterOption:MenuOption = new MenuOption("monster", raceList);
			var critterOption:MenuOption = new MenuOption("critter", critterList);
			
			var wallOption:MenuOption = new MenuOption("wall", null, false);
			var ladderOption:MenuOption = new MenuOption("laddder", null, false);
			var ladderLedgeOption:MenuOption = new MenuOption("laddder ledge", null, false);
			var ledgeOption:MenuOption = new MenuOption("ledge", null, false);
			
			renderCollisionOption = new MenuOption("collision", renderCollisionList);
			renderAIGraphOption = new MenuOption("ai graph", renderAIGraphList);
			
			onOption = new MenuOption("on", null, false);
			offOption = new MenuOption("off", null, false);
			
			options.push(blockLayerOption);
			options.push(objectLayerOption);
			options.push(dungeonLevelOption);
			options.push(renderOption);
			
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
			var mapRect:Rectangle = new Rectangle(mapX * Game.SCALE, mapY * Game.SCALE, Game.SCALE, Game.SCALE);
			
			if(type <= MOUSE_HELD){
				if(option == deleteOption){
					if(list == createBlockList){
						game.world.removeMapPosition(mapX, mapY);
						renderer.blockBitmapData.fillRect(mapRect, 0x00000000);
					}
				}
			}
			if(type == MOUSE_CLICK){
				if(list == critterList){
					if(option.name == "spider") game.mapTileManager.converter.convertIndicesToObjects(mapX, mapY, MapTileConverter.SPIDER);
					else if(option.name == "rat") game.mapTileManager.converter.convertIndicesToObjects(mapX, mapY, MapTileConverter.RAT);
					else if(option.name == "bat") game.mapTileManager.converter.convertIndicesToObjects(mapX, mapY, MapTileConverter.BAT);
					else if(option.name == "cog") game.mapTileManager.converter.convertIndicesToObjects(mapX, mapY, MapTileConverter.COG);
				} else if(list == raceList){
					
				}
			}
		}
		
	}

}