package com.robotacid.ui {
	import com.robotacid.ai.Brain;
	import com.robotacid.dungeon.Content;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.Player;
	import com.robotacid.engine.Portal;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.menu.HotKeyMap;
	import com.robotacid.ui.menu.MenuOptionStack;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	/**
	 * Provides an interface for storing game data in a shared object and restoring the game from
	 * the shared object
	 *
	 * Games are saved when going down stairs and through the menu. The difference being that
	 * a menu save will only capture the current state of the menu - not the player.
	 *
	 * The data we capture is as follows:
	 *
	 * 	key definitions
	 * 	player and minion status
	 * 	inventory
	 * 	hot key bindings
	 * 	content manager stocks
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class QuickSave{
		
		public static function save(g:Game, playerData:Boolean = false):void{
			
			var customKeys:Array = Key.custom;
			
			var obj:Object = {};
			var i:int, j:int;
			
			obj.customKeys = Key.custom;
			
			obj.sfx = SoundManager.sfx;
			
			if(playerData){
				obj.playerData = true;
				// we only save on stairs but the level doesn't change till the animation
				// finishes, so we have to take a reading from the player's state
				obj.dungeonLevel = g.dungeon.level + (Player.previousLevel < Player.previousLevel ? 1 : -1);
				obj.previousLevel = Player.previousLevel;
				obj.player = g.player.toXML();
				obj.minion = g.minion ? g.minion.toXML() : null;
				// here come the items
				var items:Vector.<XML> = new Vector.<XML>();
				for(i = 0; i < g.menu.inventoryList.options.length; i++){
					// item may be stacked - load into XML as separate items
					for(j = 0; j < (g.menu.inventoryList.options[i] as MenuOptionStack).total; j++){
						items.push(g.menu.inventoryList.options[i].userData.toXML());
					}
				}
				obj.items = items;
				// now the content manager stocks
				obj.chestsByLevel = g.content.chestsByLevel;
				obj.monstersByLevel = g.content.monstersByLevel;
				// runes revealed
				obj.runeNames = Item.runeNames;
			}
			
			// save the hotkeymaps
			var hotKeyMaps:Vector.<XML> = new Vector.<XML>();
			for(i = 0; i < g.menu.hotKeyMaps.length; i++){
				if(g.menu.hotKeyMaps[i]) hotKeyMaps.push(g.menu.hotKeyMaps[i].toXML());
				else hotKeyMaps.push(null);
			}
			obj.hotKeyMaps = hotKeyMaps;
			
			var byteArray:ByteArray = new ByteArray();
			byteArray.writeObject(obj);
			trace("before compression:"+byteArray.length);
			byteArray.compress();
			trace("after compression:"+byteArray.length);
			
			var sharedObject:SharedObject = SharedObject.getLocal("red_rogue");
			sharedObject.data.byteArray = byteArray;
			sharedObject.flush();
			sharedObject.close();
			g.console.print("saved game data");
		}
		
		public static function load(g:Game):void{
			var sharedObject:SharedObject = SharedObject.getLocal("red_rogue");
			var exists:Boolean = false;
			for each(var a:* in sharedObject.data) {
				exists = true;
				break;
			}
			if(exists){
				var i:int, j:int;
				
				var byteArray:ByteArray = sharedObject.data.byteArray as ByteArray;
				byteArray.uncompress();
				
				var obj:Object = byteArray.readObject();
				// flash annoyingly maintains connection with the shared object whether you
				// like it or not, thus we have to re-compress to avoid an error which
				// would arise from calling uncompress() twice in a row when calling this
				// method twice in a row
				byteArray.compress();
				
				Key.custom = obj.customKeys;
			
				SoundManager.sfx = obj.sfx;
				
				if(obj.playerData){
					// first reset the game
					g.menu.inventoryList.reset();
					g.menu.inventoryOption.active = false;
					g.reset();
					// then restructure player and the minion
					var playerXML:XML = obj.player;
					// the character may have been reskinned, so we just force a reskin anyway
					g.player.changeName(int(playerXML.@name));
					g.player.level = int(playerXML.@level);
					g.player.xp = Number(playerXML.@xp);
					g.player.health = Number(playerXML.@health);
					g.player.applyHealth(0);
					g.player.addXP(0);
					
					for each(enchantment in playerXML.effect){
						effect = new Effect(int(enchantment.@name), int(enchantment.@level), int(enchantment.@source), g.player, int(enchantment.@count));
					}
					if(obj.minion){
						var minonXML:XML = obj.minion;
						g.minion.level = int(minonXML.@level);
						// the character may have been reskinned, so we just force a reskin anyway
						g.minion.changeName(int(minonXML.@name));
						g.minion.health = Number(minonXML.@health);
						g.minion.applyHealth(0);
						for each(enchantment in minonXML.effect){
							effect = new Effect(int(enchantment.@name), int(enchantment.@level), int(enchantment.@source), g.minion, int(enchantment.@count));
						}
					} else {
						g.minion.active = false;
						Brain.playerCharacters.splice(Brain.playerCharacters.indexOf(g.minion), 1);
						g.minion = null;
						g.minionHealthBar.visible = false;
					}
					// runes revealed
					Item.runeNames = obj.runeNames;
					// rebuild the inventory and equip items
					var effect:Effect;
					var enchantment:XML;
					var mc:DisplayObject;
					var item:Item;
					var xml:XML;
					var name:int, level:int, type:int;
					var className:Class;
					for(i = 0; i < obj.items.length; i++){
						g.menu.inventoryOption.active = true;
						xml = obj.items[i];
						name = xml.@name;
						level = xml.@level;
						type = xml.@type;
						item = new Item(g.library.getItemGfx(name, type), name, type, level);
						item.location = xml.@location;
						item.curseState = xml.@curseState;
						// is this item enchanted?
						for each(enchantment in xml.effect){
							effect = new Effect(enchantment.@name, enchantment.@level, 0);
							effect.enchant(item);
						}
						g.menu.inventoryList.addItem(item);
						if(xml.@user == "rogue"){
							g.player.equip(item);
						} else if(xml.@user == "minion"){
							g.minion.equip(item);
						}
					}
					// restock the content manager
					// The Vectors in obj have been recast as Vector.<Vector.<Object>> as they went
					// into storage... Thanks Adobe!
					// so we have to reconstruct the content manager item by item
					for(i = 0; i < Content.TOTAL_LEVELS; i++){
						g.content.chestsByLevel[i].length = 0;
						g.content.monstersByLevel[i].length = 0;
						for(j = 0; j < obj.chestsByLevel[i].length; j++){
							g.content.chestsByLevel[i].push(obj.chestsByLevel[i][j]);
						}
						for(j = 0; j < obj.monstersByLevel[i].length; j++){
							g.content.monstersByLevel[i].push(obj.monstersByLevel[i][j]);
						}
					}
					
					Player.previousLevel = obj.previousLevel;
					// call for a new level
					g.changeLevel(int(obj.dungeonLevel), true);
				}
				
				// load the hotkeymaps
				for(i = 0; i < obj.hotKeyMaps.length; i++){
					if(obj.hotKeyMaps[i]){
						var hotKeyMap:HotKeyMap = new HotKeyMap(i, g.menu);
						hotKeyMap.init(obj.hotKeyMaps[i]);
						g.menu.hotKeyMaps[i] = hotKeyMap;
					}
					else g.menu.hotKeyMaps[i] = null;
				}
				
				g.console.print("loaded game data");
			} else {
				g.console.print("no save data");
			}
			
		}
		
	}

}