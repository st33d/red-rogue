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
		public var selection_branch:Vector.<int>;
		public var list_branch:Vector.<MenuList>;
		public var option_branch:Vector.<MenuOption>;
		public var branch_string:String;
		
		public var length:int;
		
		public function HotKeyMap(key:int, menu:Menu) {
			this.menu = menu;
			this.key = key;
			active = false;
		}
		
		/* Clears all lists and prepares for a new recording */
		public function init():void{
			selection_branch = new Vector.<int>();
			list_branch = new Vector.<MenuList>();
			option_branch = new Vector.<MenuOption>();
			branch_string = "";
			length = 0;
		}
		
		
		public function push(list:MenuList, option:MenuOption, selection:int):void{
			list_branch.push(list);
			option_branch.push(option);
			selection_branch.push(selection);
			length++;
		}
		
		public function pop(steps:int = 1):void{
			while(steps){
				list_branch.pop();
				option_branch.pop();
				selection_branch.pop();
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
					selection_branch[i] > menu.current_menu_list.options.length - 1 ||
					menu.current_menu_list.options[menu.current_menu_list.selection] != option_branch[i]
				){
					for(j = 0; j < menu.current_menu_list.options.length; j++){
						if(menu.current_menu_list.options[j] == option_branch[i]){
							selection_branch[i] = j;
							menu.selection = j;
							break;
						}
					}
				}
				
				// option inactive - search for similar path
				if(!option_branch[i].active){
					
					// get the actual name of this option
					var name:String = option_branch[i].name;
					if(option_branch[i] is MenuOptionStack) name = (option_branch[i] as MenuOptionStack).single_name;
					
					for(j = 0; j < menu.current_menu_list.options.length; j++){
						// search for the same name
						if(
							menu.current_menu_list.options[j].name == name ||
							(
								menu.current_menu_list.options[j] is MenuOptionStack &&
								(menu.current_menu_list.options[j] as MenuOptionStack).single_name == name
							)
						){
							option_branch[i] = menu.current_menu_list.options[j];
							selection_branch[i] = j;
							menu.selection = j;
							break;
						}
					}
					// name search failed - search for context match
					if(j == menu.current_menu_list.options.length && option_branch[i].context){
						for(j = 0; j < menu.current_menu_list.options.length; j++){
							// search for the same name
							if(menu.current_menu_list.options[j].context == option_branch[i].context){
								option_branch[i] = menu.current_menu_list.options[j];
								selection_branch[i] = j;
								menu.selection = j;
								break;
							}
						}
					}
					// all searches blank, abort request
					if(j == menu.current_menu_list.options.length) return;
				}
				
				menu.selection = selection_branch[i];
				menu.stepForward();
			}
		}
	}

}