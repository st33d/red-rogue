package com.robotacid.ui {
	import com.robotacid.ai.Brain;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.CharacterAttributes;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Item;
	import com.robotacid.sound.SoundManager;
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
			
			obj.customKeys = Key.custom;
			
			obj.sfx = SoundManager.sfx;
			
			if(playerData){
				obj.playerData = true;
				// we only save on stairs but the level doesn't change till the animation
				// finishes, so we have to take a reading from the player's state
				obj.dungeonLevel = g.dungeon.level + (g.player.state == Character.EXIT ? 1 : -1);
				obj.player = g.player.toXML();
				obj.minion = g.minion ? g.minion.toXML() : null;
				// here come the items
				var items:Vector.<XML> = new Vector.<XML>();
				for(var i:int = 0; i < g.menu.inventoryList.options.length; i++){
					items.push(g.menu.inventoryList.options[i].target.toXML());
				}
				obj.items = items;
				// now the content manager stocks
				obj.chestsByLevel = g.content.chestsByLevel;
				obj.monstersByLevel = g.content.monstersByLevel;
			}
			
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
					g.player.level = parseInt(playerXML.@level);
					// the character may have been reskinned, so we just force a reskin anyway
					var skin:Class = CharacterAttributes.NAME_SKINS[parseInt(playerXML.@name)];
					var skinMc:MovieClip = new skin();
					g.player.reskin(skinMc, parseInt(playerXML.@name), skinMc.width, skinMc.height);
					g.player.xp = parseFloat(playerXML.@xp);
					g.player.health = parseFloat(playerXML.@health);
					g.player.applyHealth(0);
					g.player.addXP(0);
					for each(enchantment in playerXML.effect){
						effect = new Effect(parseInt(enchantment.@name), parseInt(enchantment.@level), parseInt(enchantment.@source), g, g.player, parseInt(enchantment.@count));
					}
					if(obj.minion){
						var minonXML:XML = obj.minion;
						g.minion.level = parseInt(minonXML.@level);
						// the character may have been reskinned, so we just force a reskin anyway
						skin = CharacterAttributes.NAME_SKINS[parseInt(minonXML.@name)];
						skinMc = new skin();
						g.minion.reskin(skinMc, parseInt(minonXML.@name), skinMc.width, skinMc.height);
						g.minion.health = parseFloat(minonXML.@health);
						g.minion.applyHealth(0);
						for each(enchantment in minonXML.effect){
							effect = new Effect(parseInt(enchantment.@name), parseInt(enchantment.@level), parseInt(enchantment.@source), g, g.minion, parseInt(enchantment.@count));
						}
					} else {
						g.minion.active = false;
						Brain.playerCharacters.splice(Brain.playerCharacters.indexOf(g.minion), 1);
						g.minion = null;
						g.minionHealthBar.visible = false;
					}
					// rebuild the inventory and equip items
					var effect:Effect;
					var enchantment:XML;
					var mc:DisplayObject;
					var item:Item;
					var xml:XML;
					var name:int, level:int, type:int;
					var className:Class;
					for(var i:int = 0; i < obj.items.length; i++){
						g.menu.inventoryOption.active = true;
						xml = obj.items[i];
						name = xml.@name;
						level = xml.@level;
						type = xml.@type;
						if(type == Item.RUNE){
							mc = new g.library.RuneMC();
						} else if(type == Item.ARMOUR){
							className = g.library.armourNameToMCClass(name);
							mc = new className();
						} else if(type == Item.WEAPON){
							className = g.library.weaponNameToMCClass(name);
							mc = new className();
						} else if(type == Item.HEART){
							mc = new g.library.HeartMC();
						}
						item = new Item(mc, name, type, level, g);
						item.holder = g.itemsHolder;
						item.state = xml.@state;
						item.curseState = xml.@curseState;
						// is this item enchanted?
						for each(enchantment in xml.effect){
							effect = new Effect(enchantment.@name, enchantment.@level, 0, g);
							effect.enchant(item);
						}
						g.menu.inventoryList.addItem(item);
						if(item.state == Item.EQUIPPED){
							g.player.equip(item);
							g.player.updateMC();
						} else if(item.state == Item.MINION_EQUIPPED){
							g.minion.equip(item);
							g.minion.updateMC();
						}
					}
					// restock the content manager
					g.content.chestsByLevel = obj.chestsByLevel;
					g.content.monstersByLevel = obj.monstersByLevel;
					// call for a new level
					g.changeLevel(parseInt(obj.dungeonLevel));
				}
				
				g.console.print("loaded game data");
			} else {
				g.console.print("no save data");
			}
			
		}
		
	}

}