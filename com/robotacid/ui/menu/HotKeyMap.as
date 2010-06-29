package com.robotacid.ui.menu {
	/**
	 * This maps out a behaviour for a hot key
	 * 
	 * A hot key runs down a specific path to activate a menu option
	 * 
	 * However - as I decided to make the topology of the menu dynamic, it became apparent that the hot
	 * keys needed to seek alternative paths to similar goals when the current route became blocked
	 * 
	 * Thus when a hot key encounters a blocked path, or the path no longer appears to operate how it used
	 * to, then it will seek out MenuOptions in the current list that bear the same "context"
	 * 
	 * Consider setting up a key to consume health potions - you would want this key to remain in that
	 * "context" whether you have potions to spare or not
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class HotKeyMap{
		
		public var menu:Menu;
		public var active:Boolean;
		public var key:int;
		public var selectionBranch:Vector.<int>;
		public var listBranch:Vector.<MenuList>;
		public var optionBranch:Vector.<MenuOption>;
		public var branchString:String;
		
		public var length:int;
		
		public function HotKeyMap(key:int, menu:Menu) {
			this.menu = menu;
			this.key = key;
			active = false;
		}
		
		/* Clears all lists and prepares for a new recording */
		public function init():void{
			selectionBranch = new Vector.<int>();
			listBranch = new Vector.<MenuList>();
			optionBranch = new Vector.<MenuOption>();
			branchString = "";
			length = 0;
		}
		
		
		public function push(list:MenuList, option:MenuOption, selection:int):void{
			listBranch.push(list);
			optionBranch.push(option);
			selectionBranch.push(selection);
			length++;
		}
		
		public function pop(steps:int = 1):void{
			while(steps){
				listBranch.pop();
				optionBranch.pop();
				selectionBranch.pop();
				if(--length <= 0) break;
			}
		}
		
		public function execute():void{
			// first we need to walk back up the menu to the trunk before we can set off
			// down the hot key route
			trace("hot keyed");
			while(menu.branch.length > 1) menu.stepBack();
			
			var j:int;
			
			for(var i:int = 0; i < length; i++){
				
				// now here of course is where we verify our course of action
				// we know where we want to go, but are we headed down the right path?
				// if not then this map will modify itself first to match name and then to match context
				
				// option index correction
				if(
					selectionBranch[i] > menu.currentMenuList.options.length - 1 ||
					menu.currentMenuList.options[menu.currentMenuList.selection] != optionBranch[i]
				){
					for(j = 0; j < menu.currentMenuList.options.length; j++){
						if(menu.currentMenuList.options[j] == optionBranch[i]){
							selectionBranch[i] = j;
							menu.selection = j;
							break;
						}
					}
				}
				
				// option inactive - search for similar path
				if(!optionBranch[i].active){
					
					// get the actual name of this option
					var name:String = optionBranch[i].name;
					if(optionBranch[i] is MenuOptionStack) name = (optionBranch[i] as MenuOptionStack).singleName;
					
					for(j = 0; j < menu.currentMenuList.options.length; j++){
						// search for the same name
						if(
							menu.currentMenuList.options[j].name == name ||
							(
								menu.currentMenuList.options[j] is MenuOptionStack &&
								(menu.currentMenuList.options[j] as MenuOptionStack).singleName == name
							)
						){
							optionBranch[i] = menu.currentMenuList.options[j];
							selectionBranch[i] = j;
							menu.selection = j;
							break;
						}
					}
					// name search failed - search for context match
					if(j == menu.currentMenuList.options.length && optionBranch[i].context){
						for(j = 0; j < menu.currentMenuList.options.length; j++){
							// search for the same name
							if(menu.currentMenuList.options[j].context == optionBranch[i].context){
								optionBranch[i] = menu.currentMenuList.options[j];
								selectionBranch[i] = j;
								menu.selection = j;
								break;
							}
						}
					}
					// all searches blank, abort request
					if(j == menu.currentMenuList.options.length) return;
				}
				
				menu.selection = selectionBranch[i];
				menu.stepForward();
			}
		}
	}

}