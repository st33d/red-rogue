package com.robotacid.ui.menu {
	import com.robotacid.engine.Item;
	import com.robotacid.ui.menu.MenuList;
	
	/**
	 * Manages a dead list of enchantment names for the player to review an item's enchantments
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class EnchantmentList extends MenuList{
		
		public function EnchantmentList(options:Vector.<MenuOption> = null) {
			super(options);
		}
		
		public function update(item:Item):void{
			var i:int;
			
			// set options active/false
			if(pointers){
				for(i = 0; i < pointers.length; i++){
					pointers[i].active = Boolean(item.effects || item.holyState == Item.CURSE_REVEALED || item.holyState == Item.BLESSED);
				}
			}
			if(!item.effects && !(item.holyState == Item.CURSE_REVEALED || item.holyState == Item.BLESSED)) return;
			
			options = new Vector.<MenuOption>();
			
			// cursed?
			if(item.holyState == Item.CURSE_REVEALED) options.push(new MenuOption("cursed", null, false));
			else if(item.holyState == Item.BLESSED) options.push(new MenuOption("blessed", null, false));
			
			// enchantments?
			if(item.effects){
				var str:String;
				for(i = 0; i < item.effects.length; i++){
					str = item.effects[i].nameToString() + " " + item.effects[i].level;
					options.push(new MenuOption(str, null, false));
				}
			}
			
			selection = 0;
		}
		
	}

}