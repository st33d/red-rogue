package com.robotacid.ui.menu {
	import com.robotacid.engine.Item;
	import com.robotacid.ui.menu.MenuList;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class EnchantmentList extends MenuList{
		
		public function EnchantmentList(options:Vector.<MenuOption> = null) {
			super(options);
			
		}
		
		public function update(item:Item):void{
			var i:int;
			if(pointers){
				for(i = 0; i < pointers.length; i++){
					pointers[i].active = Boolean(item.effects || item.curse_state == Item.CURSE_REVEALED);
				}
			}
			
			if(!item.effects && item.curse_state != Item.CURSE_REVEALED) return;
			
			options = new Vector.<MenuOption>();
			if(item.curse_state == Item.CURSE_REVEALED) options.push(new MenuOption("cursed", null, false));
			var str:String;
			for(i = 0; i < item.effects.length; i++){
				str = item.effects[i].nameToString() + " " + item.effects[i].level;
				options.push(new MenuOption(str, null, false));
			}
			selection = 0;
		}
		
	}

}