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
		
		public var active:Boolean;
		
		public function MenuCarousel() {
			menus = new Vector.<Menu>();
			active = false;
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
			active = true;
			currentMenu.activate();
		}
		
		public function deactivate():void{
			active = false;
			currentMenu.deactivate();
		}
	}

}