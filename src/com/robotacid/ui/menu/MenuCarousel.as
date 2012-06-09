package com.robotacid.ui.menu {
	import flash.display.Sprite;
	
	/**
	 * Handles changeover between menus
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class MenuCarousel extends Sprite {
		
		public var menus:Vector.<Menu>;
		public var currentMenu:Menu;
		
		public function MenuCarousel() {
			menus = new Vector.<Menu>();
		}
		
		public function addMenu(menu:Menu):void{
			menus.push(menu);
			menu.carousel = this;
		}
		
		public function setCurrentMenu(menu:Menu):void{
			if(currentMenu == menu) return;
			if(currentMenu && currentMenu.parent){
				currentMenu.deactivate();
				menu.activate();
			}
			currentMenu = menu;
		}
		
		public function activate():void{
			currentMenu.activate();
		}
		
		public function deactivate():void{
			currentMenu.deactivate();
		}
	}

}