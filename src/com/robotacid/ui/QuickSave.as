package com.robotacid.ui {
	import com.robotacid.ai.Brain;
	import com.robotacid.level.Content;
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
	 * ****************************************************************************************
	 * 					DEPRECATED
	 * 
	 * TOP LEVEL CLASS UserData NOW PERFORMS THIS TASK
	 * THIS CODE IS HERE UNTIL ALL TOOLS WITHIN ARE
	 * TRANSFERRED
	 * ****************************************************************************************
	 * 
	 * Provides an interface for storing game data in a shared object and restoring the game from
	 * the shared object
	 *
	 * Games are saved when going down stairs and through the menu. The difference being that
	 * a menu save will only capture the current state of the menu - not the player.
	 *
	 * The data we capture is as follows:
	 *
	 * 	menu state
	 * 	key definitions
	 * 	player and minion status
	 * 	inventory
	 * 	hot key bindings
	 * 	content manager stocks
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class QuickSave{
		
		public static function save(game:Game, playerData:Boolean = false):void{
			
			var customKeys:Array = Key.custom;
			
			var obj:Object = {};
			var i:int, j:int;
			
			obj.customKeys = Key.custom;
			
			obj.sfx = SoundManager.sfx;
			
			if(playerData){
				obj.playerData = true;
				// we only save on stairs but the level doesn't change till the animation
				// finishes, so we have to take a reading from the player's state
				obj.dungeonLevel = game.map.level + (Player.previousLevel < Player.previousLevel ? 1 : -1);
				obj.previousLevel = Player.previousLevel;
				obj.previousPortalType = Player.previousPortalType;
				obj.player = game.player.toXML();
				obj.minion = game.minion ? game.minion.toXML() : null;
				// here come the items
				var items:Vector.<XML> = new Vector.<XML>();
				/*for(i = 0; i < game.menu.inventoryList.options.length; i++){
					// item may be stacked - load into XML as separate items
					for(j = 0; j < (game.menu.inventoryList.options[i] as MenuOptionStack).total; j++){
						items.push(game.menu.inventoryList.options[i].userData.toXML());
					}
				}*/
				obj.items = items;
				// now the content manager stocks
				obj.chestsByLevel = game.content.chestsByLevel;
				obj.monstersByLevel = game.content.monstersByLevel;
				obj.portalsByLevel = game.content.portalsByLevel;
				obj.itemDungeonContent = game.content.itemDungeonContent;
				// runes revealed
				obj.runeNames = Item.runeNames;
			}
			
			// save the hotkeymaps
			var hotKeyMaps:Vector.<XML> = new Vector.<XML>();
			for(i = 0; i < game.gameMenu.hotKeyMaps.length; i++){
				if(game.gameMenu.hotKeyMaps[i]) hotKeyMaps.push(game.gameMenu.hotKeyMaps[i].toXML());
				else hotKeyMaps.push(null);
			}
			obj.hotKeyMaps = hotKeyMaps;
			
			var byteArray:ByteArray = new ByteArray();
			byteArray.writeObject(obj);
			//trace("before compression:"+byteArray.length);
			byteArray.compress();
			//trace("after compression:"+byteArray.length);
			
			var sharedObject:SharedObject = SharedObject.getLocal("red_rogue");
			sharedObject.data.byteArray = byteArray;
			sharedObject.flush();
			sharedObject.close();
			game.console.print("saved game data");
		}
		
		public static function load(game:Game):void{
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
					game.gameMenu.inventoryList.reset();
					game.gameMenu.inventoryOption.active = false;
					game.reset();
					// then restructure player and the minion
					var playerXML:XML = obj.player;
					// the character may have been reskinned, so we just force a reskin anyway
					game.player.changeName(int(playerXML.@name));
					game.player.level = int(playerXML.@level);
					game.player.xp = Number(playerXML.@xp);
					game.player.health = Number(playerXML.@health);
					game.player.applyHealth(0);
					game.player.addXP(0);
					
					for each(enchantment in playerXML.effect){
						effect = new Effect(int(enchantment.@name), int(enchantment.@level), int(enchantment.@source), game.player, int(enchantment.@count));
					}
					if(obj.minion){
						var minonXML:XML = obj.minion;
						game.minion.level = int(minonXML.@level);
						// the character may have been reskinned, so we just force a reskin anyway
						game.minion.changeName(int(minonXML.@name));
						game.minion.health = Number(minonXML.@health);
						game.minion.applyHealth(0);
						for each(enchantment in minonXML.effect){
							effect = new Effect(int(enchantment.@name), int(enchantment.@level), int(enchantment.@source), game.minion, int(enchantment.@count));
						}
					} else {
						game.minion.active = false;
						Brain.playerCharacters.splice(Brain.playerCharacters.indexOf(game.minion), 1);
						game.minion = null;
						game.minionHealthBar.visible = false;
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
						game.gameMenu.inventoryOption.active = true;
						xml = obj.items[i];
						name = xml.@name;
						level = xml.@level;
						type = xml.@type;
						item = new Item(game.library.getItemGfx(name, type), name, type, level);
						item.location = xml.@location;
						item.holyState = xml.@holyState;
						// is this item enchanted?
						for each(enchantment in xml.effect){
							effect = new Effect(enchantment.@name, enchantment.@level);
							effect.enchant(item);
						}
						game.gameMenu.inventoryList.addItem(item);
						if(xml.@user == "rogue"){
							game.player.equip(item);
						} else if(xml.@user == "minion"){
							game.minion.equip(item);
						}
					}
					// restock the content manager
					// The Vectors in obj have been recast as Vector.<Vector.<Object>> as they went
					// into storage... Thanks Adobe!
					// so we have to reconstruct the content manager item by item
					for(i = 0; i < Content.TOTAL_LEVELS; i++){
						game.content.chestsByLevel[i].length = 0;
						game.content.monstersByLevel[i].length = 0;
						game.content.portalsByLevel[i].length = 0;
						for(j = 0; j < obj.chestsByLevel[i].length; j++){
							game.content.chestsByLevel[i].push(obj.chestsByLevel[i][j]);
						}
						for(j = 0; j < obj.monstersByLevel[i].length; j++){
							game.content.monstersByLevel[i].push(obj.monstersByLevel[i][j]);
						}
						for(j = 0; j < obj.portalsByLevel[i].length; j++){
							game.content.portalsByLevel[i].push(obj.portalsByLevel[i][j]);
						}
					}
					game.content.itemDungeonContent = obj.itemDungeonContent;
					
					Player.previousLevel = obj.previousLevel;
					Player.previousPortalType = obj.previousPortalType;
					// infer last used portal type
					var portalType:int;
					if(Player.previousPortalType == Portal.STAIRS){
						portalType = Portal.STAIRS;
					} else if(Player.previousPortalType == Portal.OVERWORLD){
						portalType = Portal.OVERWORLD_RETURN;
					} else if(Player.previousPortalType == Portal.OVERWORLD_RETURN){
						portalType = Portal.OVERWORLD;
					} else if(Player.previousPortalType == Portal.ITEM){
						portalType = Portal.ITEM_RETURN;
					} else if(Player.previousPortalType == Portal.ITEM_RETURN){
						portalType = Portal.ITEM;
					}
					// call for a new level
					game.setLevel(int(obj.dungeonLevel), portalType, true);
				}
				
				// load the hotkeymaps
				for(i = 0; i < obj.hotKeyMaps.length; i++){
					if(obj.hotKeyMaps[i]){
						var hotKeyMap:HotKeyMap = new HotKeyMap(i, game.gameMenu);
						hotKeyMap.init(obj.hotKeyMaps[i]);
						game.gameMenu.hotKeyMaps[i] = hotKeyMap;
					}
					else game.gameMenu.hotKeyMaps[i] = null;
				}
				
				game.console.print("loaded game data");
			} else {
				game.console.print("no save data");
			}
			
		}
		
	}

}