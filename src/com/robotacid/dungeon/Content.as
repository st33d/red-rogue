package com.robotacid.dungeon {
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Chest;
	import com.robotacid.engine.ColliderEntity;
	import com.robotacid.engine.Effect;
	import com.robotacid.engine.Entity;
	import com.robotacid.engine.Face;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.MapTileConverter;
	import com.robotacid.engine.Monster;
	import com.robotacid.engine.Player;
	import com.robotacid.engine.Portal;
	import com.robotacid.engine.Stone;
	import com.robotacid.gfx.Renderer;
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	/**
	 * Creates content to place on the map for the first 20 levels to create structured
	 * play, then returns random content from the entire selection afterwards
	 *
	 * You'll notice that I'm shifting between XML and normal objects a lot. The logic behind this
	 * is that if I need to find out what's going on in a level, a quick print out of the XML renders
	 * an easily readable itinerary. And it takes up less room in the shared object.
	 * 
	 * (On a recent project I've switched to JSON, but it's a lot of work to switch and
	 * I think the XML node structure probably suits this game)
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Content{
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		public var chestsByLevel:Vector.<Vector.<XML>>;
		public var monstersByLevel:Vector.<Vector.<XML>>;
		public var portalsByLevel:Vector.<Vector.<XML>>;
		public var trapsByLevel:Vector.<int>;
		public var secretsByLevel:Vector.<int>;
		public var seedsByLevel:Vector.<uint>;
		
		public var itemDungeonContent:Object;
		public var areaContent:Array;
		
		// special items
		public var deathsScythe:Item;
		public var yendor:Item;
		
		public static const TOTAL_LEVELS:int = 20;
		public static const TOTAL_AREAS:int = 2;
		
		public function Content() {
			var obj:Object;
			var level:int;
			chestsByLevel = new Vector.<Vector.<XML>>(TOTAL_LEVELS + 1);
			monstersByLevel = new Vector.<Vector.<XML>>(TOTAL_LEVELS + 1);
			portalsByLevel = new Vector.<Vector.<XML>>(TOTAL_LEVELS + 1);
			trapsByLevel = new Vector.<int>();
			secretsByLevel = new Vector.<int>();
			seedsByLevel = new Vector.<uint>();
			for(level = 0; level <= TOTAL_LEVELS; level++){
				obj = getLevelContent(level);
				monstersByLevel[level] = obj.monsters;
				chestsByLevel[level] = obj.chests;
				portalsByLevel[level] = new Vector.<XML>();
				trapsByLevel[level] = level * 2;
				secretsByLevel[level] = 2;
				Map.random.value();
				seedsByLevel[level] = Map.random.r;
			}
			areaContent = [];
			for(level = 0; level < TOTAL_AREAS; level++){
				areaContent.push({
					chests:new Vector.<XML>,
					monsters:new Vector.<XML>,
					portals:new Vector.<XML>
				});
			}
			// set up underworld portal on level 20
			var portalXML:XML = <portal />;
			portalXML.@type = Portal.UNDERWORLD;
			portalXML.@targetLevel = Map.UNDERWORLD;
			portalsByLevel[20].push(portalXML);
			setUnderworldPortal(20);
			createUniqueItems();
		}
		
		/* All unique items exist in Content as well as outside */
		private function createUniqueItems():void{
			deathsScythe = new Item(new ScytheMC, Item.SCYTHE, Item.WEAPON, Game.MAX_LEVEL);
			deathsScythe.uniqueName = "death's scythe";
			var effect:Effect = new Effect(Effect.UNDEAD, Game.MAX_LEVEL);
			effect.enchant(deathsScythe);
		}
		
		// Equations for quantities on levels
		
		// min: level / 2, max: (level + 2) / 2
		public function equipmentQuantityPerLevel(level:int):int{
			if(level <= 0) return 0;
			if(level > TOTAL_LEVELS) level = TOTAL_LEVELS;
			var n:Number = (level + Map.random.range(3)) * 0.5;
			return n == (n >> 0) ? n : (n >> 0) + 1; // inline Math.ceil()
		}
		
		// min: level / 2, max: (level + 1) / 2
		public function runeQuantityPerLevel(level:int):int{
			if(level <= 0) return 0;
			if(level > TOTAL_LEVELS) level = TOTAL_LEVELS;
			var n:Number = (level + Map.random.range(2)) * 0.5;
			return n == (n >> 0) ? n : (n >> 0) + 1; // inline Math.ceil()
		}
		
		// min: 5 + level * 2, max: 10 + level 3
		public function monsterQuantityPerLevel(level:int):int{
			if(level <= 0) return 0;
			if(level > TOTAL_LEVELS) level = TOTAL_LEVELS;
			return 5 + Map.random.range(6) + level * (2 + Map.random.range(2));
		}
		
		/* Create a satisfactory amount of monsters and loot for a level
		 * 
		 * Returns a list of monster XMLs and chest XMLs with loot therein */
		public function getLevelContent(level:int, item:XML = null):Object{
			if(level > TOTAL_LEVELS) level = TOTAL_LEVELS;
			var monsters:Vector.<XML> = new Vector.<XML>();
			var chests:Vector.<XML> = new Vector.<XML>();
			var obj:Object = {monsters:monsters, chests:chests};
			if(level <= 0) return obj;
			
			var equipment:Vector.<XML> = new Vector.<XML>();
			var runes:Vector.<XML> = new Vector.<XML>();
			
			// if an item is fed into this level, add it to the equipment list
			if(item) equipment.push(item);
			
			var quantity:int;
			quantity = equipmentQuantityPerLevel(level);
			while(quantity--){
				equipment.push(createItemXML(level, Map.random.value() < 0.5 ? Item.WEAPON : Item.ARMOUR));
			}
			quantity = runeQuantityPerLevel(level);
			while(quantity--){
				runes.push(createItemXML(level, Item.RUNE));
			}
			quantity = monsterQuantityPerLevel(level)
			while(quantity--){
				monsters.push(createCharacterXML(level, Character.MONSTER));
			}
			
			// equipment needs to be distributed amongst monsters and
			// runes need to go in chests
			var equippedMonsters:int = 1 + Map.random.range(equipment.length - 1);
			if(monsters.length < equippedMonsters) equippedMonsters = monsters.length;
			var loot:XML;
			while(equippedMonsters--){
				loot = equipment.shift();
				
				// never give monsters armour of indifference - there's no way to get it off them
				if(int(loot.@type) == Item.ARMOUR && int(loot.@name) == Item.INDIFFERENCE) continue;
				
				monsters[equippedMonsters].appendChild(loot);
				
				// bonus equipment - if the order of the items alternates between
				// weapons and armour, we take it as a sign to double equip the monster
				if((equippedMonsters) && loot.@type != equipment[0].@type){
					monsters[equippedMonsters].appendChild(equipment.shift());
					equippedMonsters--;
				}
			}
			// the rest goes in chests, upto 3 items can go in a chest
			while(equipment.length || runes.length){
				var chestQuantity:int = 1 + Map.random.range(3);
				if(chestQuantity > equipment.length + runes.length) chestQuantity = equipment.length + runes.length;
				var chest:XML = <chest />;
				while(chestQuantity){
					if(Map.random.value() < 0.5){
						if(runes.length){
							chest.appendChild(runes.shift());
							chestQuantity--;
						}
					} else {
						if(equipment.length){
							chest.appendChild(equipment.shift());
							chestQuantity--;
						}
					}
				}
				chests.push(chest);
			}
			return obj;
		}
		
		/* Return the pre-generated seed value for creating a given level */
		public function getSeed(level:int, type:int):uint{
			if(type == Map.MAIN_DUNGEON){
				while(level >= seedsByLevel.length) seedsByLevel.push(Math.random() * uint.MAX_VALUE);
				return seedsByLevel[level];
			} else if(type == Map.ITEM_DUNGEON){
				return itemDungeonContent.seed;
			}
			return Math.random() * uint.MAX_VALUE;
		}
		
		/* Creates content for the enchanted item side-dungeon */
		public function setItemDungeonContent(item:Item, level:int):void{
			itemDungeonContent = getLevelContent(level, item.toXML());
			itemDungeonContent.portals = Vector.<XML>([<portal type={Portal.ITEM_RETURN} targetLevel={level} />]);
			itemDungeonContent.secrets = 2;
			itemDungeonContent.traps = 2 * (level <= TOTAL_LEVELS ? level : TOTAL_LEVELS);
			itemDungeonContent.seed = Math.random() * uint.MAX_VALUE;
		}
		
		/* Retargets the underworld portal */
		public function setUnderworldPortal(level:int):void{
			areaContent[Map.UNDERWORLD].portals = Vector.<XML>([<portal type={Portal.UNDERWORLD_RETURN} targetLevel={level} />]);
		}
		
		/* Creates or retargets the overworld portal */
		public function setOverworldPortal(level:int):void{
			var portalXML:XML
			if(areaContent[Map.OVERWORLD].portals.length == 0){
				portalXML = <portal type={Portal.OVERWORLD_RETURN} />;
				areaContent[Map.OVERWORLD].portals = Vector.<XML>([portalXML]);
			} else {
				portalXML = areaContent[Map.OVERWORLD].portals[0];
			}
			portalXML.@targetLevel = level;
		}
		
		/* Distributes content across a level
		 * 
		 * Portals we leave alone for the Map to request when it needs to create access points */
		public function populateLevel(level:int, bitmap:DungeonBitmap, layers:Array, mapType:int):void{
			var r:int, c:int;
			var i:int;
			var monsters:Vector.<XML>;
			var chests:Vector.<XML>;
			if(mapType == Map.MAIN_DUNGEON){
				if(level <= TOTAL_LEVELS){
					monsters = monstersByLevel[level];
					chests = chestsByLevel[level];
				} else {
					var obj:Object = getLevelContent(level);
					monsters = obj.monsters;
					chests = obj.chests;
				}
			} else if(mapType == Map.ITEM_DUNGEON){
				monsters = itemDungeonContent.monsters;
				chests = itemDungeonContent.chests;
			}
			
			// distribute
			
			if(mapType != Map.AREA){
				// just going to go for a random drop for now.
				// I intend to figure out a distribution pattern later
				while(monsters.length){
					r = 1 + Map.random.range(bitmap.height - 1);
					c = 1 + Map.random.range(bitmap.width - 1);
					if(!layers[Map.ENTITIES][r][c] && layers[Map.BLOCKS][r][c] != 1 && (bitmap.bitmapData.getPixel32(c, r + 1) == DungeonBitmap.LEDGE || layers[Map.BLOCKS][r + 1][c] == 1)){
						//trace(monstersByLevel[level][0].toXMLString());
						layers[Map.ENTITIES][r][c] = convertXMLToEntity(c, r, monsters.shift());
					}
				}
				while(chests.length){
					r = 1 + Map.random.range(bitmap.height - 2);
					c = 1 + Map.random.range(bitmap.width - 2);
					if(!layers[Map.ENTITIES][r][c] && layers[Map.BLOCKS][r][c] != 1 && (bitmap.bitmapData.getPixel32(c, r + 1) == DungeonBitmap.LEDGE || layers[Map.BLOCKS][r + 1][c] == 1)){
						//trace(chestsByLevel[level][0].toXMLString());
						layers[Map.ENTITIES][r][c] = convertXMLToEntity(c, r, chests.shift());
					}
				}
			} else {
				// on areas we just scatter objects left up there
				var chest:Chest;
				var item:Item;
				var list:Array;
				var minX:int, maxX:int;
				if(level == Map.OVERWORLD){
					minX = 2;
					maxX = bitmap.width - 2;
					r = bitmap.height - 2;
				} else if(level == Map.UNDERWORLD){
					minX = Map.UNDERWORLD_BOAT_MIN;
					maxX = Map.UNDERWORLD_BOAT_MAX;
					r = bitmap.height - 3;
				}
				while(areaContent[level].chests.length){
					chest = convertXMLToEntity(0, 0, areaContent[level].chests.shift());
					while(chest.contents.length){
						item = chest.contents.shift();
						c = minX + Map.random.range(maxX - minX);
						item.dropToMap(c, r, false);
						if(layers[Map.ENTITIES][r][c]){
							if(layers[Map.ENTITIES][r][c] is Array){
								layers[Map.ENTITIES][r][c].push(item);
							} else {
								layers[Map.ENTITIES][r][c] = [layers[Map.ENTITIES][r][c], item];
							}
						} else {
							layers[Map.ENTITIES][r][c] = item;
						}
					}
				}
			}
		}
		
		/* Fetch all portals on a level - used by Map to create portal access points */
		public function getPortals(level:int, mapType:int):Vector.<XML>{
			var list:Vector.<XML> = new Vector.<XML>();
			if(mapType == Map.MAIN_DUNGEON){
				if(level < portalsByLevel.length){
					while(portalsByLevel[level].length) list.push(portalsByLevel[level].pop());
				}
				
			} else if(mapType == Map.ITEM_DUNGEON){
				while(itemDungeonContent.portals.length) list.push(itemDungeonContent.portals.pop());
				
			} else if(mapType == Map.AREA){
				while(areaContent[level].portals.length) list.push(areaContent[level].portals.pop());
				
			}
			return list;
		}
		
		/* Search the levels for a given portal type and remove it - this prevents multiples of the same portal */
		public function removePortalType(type:int):void{
			var i:int, j:int, xml:XML;
			for(i = 0; i < portalsByLevel.length; i++){
				for(j = 0; j < portalsByLevel[i].length; j++){
					xml = portalsByLevel[i][j];
					if(int(xml.@type) == type){
						portalsByLevel[i].splice(j, 1);
						return;
					}
				}
			}
		}
		
		/* Returns the amount of secrets in this part of the dungeon */
		public function getSecrets(dungeonLevel:int, dungeonType:int):int{
			if(dungeonType == Map.MAIN_DUNGEON){
				while(dungeonLevel >= secretsByLevel.length) secretsByLevel.push(2);
				return secretsByLevel[dungeonLevel];
			} else if(dungeonType == Map.ITEM_DUNGEON){
				return itemDungeonContent.secrets;
			}
			return 0;
		}
		
		/* Returns the amount of traps in this part of the dungeon */
		public function getTraps(dungeonLevel:int, dungeonType:int):int{
			if(dungeonType == Map.MAIN_DUNGEON){
				while(dungeonLevel >= trapsByLevel.length) trapsByLevel.push(TOTAL_LEVELS * 2);
				return trapsByLevel[dungeonLevel];
			} else if(dungeonType == Map.ITEM_DUNGEON){
				return itemDungeonContent.traps;
			}
			return 0;
		}
		
		/* Removes a secret for good */
		public function removeSecret(dungeonLevel:int, dungeonType:int):void{
			if(dungeonType == Map.MAIN_DUNGEON){
				secretsByLevel[dungeonLevel]--;
			} else if(dungeonType == Map.ITEM_DUNGEON){
				itemDungeonContent.secrets--;
			}
		}
		
		/* Removes a trap for good */
		public function removeTrap(dungeonLevel:int, dungeonType:int):void{
			if(dungeonType == Map.MAIN_DUNGEON){
				trapsByLevel[dungeonLevel]--;
			} else if(dungeonType == Map.ITEM_DUNGEON){
				itemDungeonContent.traps--;
			}
		}
		
		/* This method tracks down monsters and items and pulls them back into the content manager to be sent out
		 * again if the level is re-visited */
		public function recycleLevel(mapType:int):void{
			var i:int;
			var level:int = game.dungeon.level;
			// no recycling debug
			if(level < 0) return;
			if(mapType == Map.MAIN_DUNGEON){
				// if we've gone past the total level limit we need to create new content reserves on the fly
				if(level == monstersByLevel.length){
					monstersByLevel.push(new Vector.<XML>());
					chestsByLevel.push(new Vector.<XML>());
					portalsByLevel.push(new Vector.<XML>());
				}
			}
			// first we check the active list of entities
			for(i = 0; i < game.entities.length; i++){
				recycleEntity(game.entities[i], level, mapType);
			}
			for(i = 0; i < game.items.length; i++){
				recycleEntity(game.items[i], level, mapType);
			}
			var portal:Portal;
			for(i = 0; i < game.portals.length; i++){
				portal = game.portals[i];
				if(portal.type != Portal.STAIRS && (portal.state == Portal.OPEN || portal.state == Portal.OPENING)){
					recycleEntity(portal, level, mapType);
				}
			}
			// now we scour the entities layer of the renderer for more entities to convert to XML
			var r:int, c:int, tile:*;
			for(r = 0; r < game.mapTileManager.height; r++){
				for(c = 0; c < game.mapTileManager.width; c++){
					tile = game.mapTileManager.mapLayers[Map.ENTITIES][r][c];
					if(tile){
						if(tile is Array){
							for(i = 0; i < tile.length; i++){
								if(tile[i] is Entity){
									recycleEntity(tile[i], level, mapType);
								}
							}
						} else if(tile is Entity){
							recycleEntity(tile, level, mapType);
						}
					}
				}
			}
			//trace("recycling..." + game.dungeon.level);
			//for(i = 0; i < monstersByLevel[level].length; i++){
				//trace(monstersByLevel[level][i].toXMLString());
			//}
			//for(i = 0; i < chestsByLevel[level].length; i++){
				//trace(chestsByLevel[level][i].toXMLString());
			//}
		}
		
		/* Used in concert with the recycleLevel() method to convert level assets to XML and store them */
		public function recycleEntity(entity:Entity, level:int, mapType:int):void{
			var i:int, item:Item, character:Character;
			var chest:XML;
			var monsters:Vector.<XML>;
			var chests:Vector.<XML>;
			var portals:Vector.<XML>;
			
			if(mapType == Map.MAIN_DUNGEON){
				monsters = monstersByLevel[level];
				chests = chestsByLevel[level];
				portals = portalsByLevel[level];
				
			} else if(mapType == Map.ITEM_DUNGEON){
				monsters = itemDungeonContent.monsters;
				chests = itemDungeonContent.chests;
				portals = itemDungeonContent.portals;
				
			} else if(mapType == Map.AREA){
				monsters = areaContent[level].monsters;
				chests = areaContent[level].chests;
				portals = areaContent[level].portals;
			}
			
			if(entity is Monster){
				// strip Death's Scythe from the level to return it to Death
				if(deathsScythe.location != Item.UNASSIGNED){
					character = entity as Character;
					for(i = character.loot.length - 1; i > -1 ; i--){
						item = character.loot[i];
						if(item == deathsScythe){
							character.dropItem(item);
							item.location = Item.UNASSIGNED;
							break;
						}
					}
				}
				monsters.push(entity.toXML());
				
			} else if(entity is Item){
				item = entity as Item;
				// strip Death's Scythe from the level to return it to Death
				if(item == deathsScythe){
					item.location = Item.UNASSIGNED;
					return;
				}
				if(chests.length > 0){
					chest = chests[chests.length - 1];
					if(chest.item.length < 1 + Map.random.range(3)){
						chest.appendChild(entity.toXML());
					} else {
						chest = <chest />;
						chest.appendChild(entity.toXML());
						chests.push(chest);
					}
				} else {
					chest = <chest />;
					chest.appendChild(entity.toXML());
					chests.push(chest);
				}
				
			} else if(entity is Chest){
				chest = entity.toXML();
				if(chest) chests.push(entity.toXML());
				
			} else if(entity is Portal){
				if((entity as Portal).type != Portal.STAIRS){
					portals.push(entity.toXML());
				}
				
			} else if(entity is Stone){
				if((entity as Stone).name == Stone.DEATH){
					if((entity as Stone).weapon && (entity as Stone).weapon.uniqueName == "death's scythe"){
						
					}
				}
			}
		}
		
		/* Create a random character appropriate for the dungeon level
		 * 
		 * Currently set up for just Monsters */
		public static function createCharacterXML(dungeonLevel:int, type:int):XML{
			var name:int;
			var level:int = -1 + Map.random.range(dungeonLevel);
			if(type == Character.MONSTER){
				var range:int = dungeonLevel + 2;
				if(dungeonLevel > Game.MAX_LEVEL) range = Game.MAX_LEVEL + 2;
				while(name < 1 || name > dungeonLevel || name >= Game.MAX_LEVEL){
					name = Map.random.range(range);
					if(name > dungeonLevel) name = dungeonLevel;
					if(name >= Game.MAX_LEVEL) continue;
				}
			}
			return <character name={name} type={type} level={level} />;
		}
		
		/* Create a random item appropriate for the dungeon level */
		public static function createItemXML(dungeonLevel:int, type:int):XML{
			var enchantments:int = -2 + Map.random.range(dungeonLevel);
			var name:int;
			var level:int = Math.min(1 + Map.random.range(dungeonLevel), Game.MAX_LEVEL);
			var nameRange:int;
			if(type == Item.ARMOUR){
				nameRange = Item.ITEM_MAX;
			} else if(type == Item.WEAPON){
				nameRange = Item.ITEM_MAX;
			} else if(type == Item.RUNE){
				nameRange = Item.stats["rune names"].length;
				level = 0;
				enchantments = 0;
			} else if(type == Item.HEART){
				nameRange = Game.MAX_LEVEL
				level = 0;
				enchantments = 0;
			}
			if(nameRange > dungeonLevel) nameRange = dungeonLevel;
			name = Map.random.range(nameRange);
			
			var itemXML:XML = <item name={name} type={type} level={level} />;

			if(enchantments > 0){
				var runeList:Vector.<int> = new Vector.<int>();
				var enchantmentName:int, enchantmentNameRange:int;
				while(enchantments--){
					enchantmentNameRange = Map.random.range(Item.stats["rune names"].length);
					if(enchantmentNameRange > dungeonLevel) enchantmentNameRange = dungeonLevel;
					enchantmentName = Map.random.range(enchantmentNameRange);
					// some enchantments confer multiple extra enchantments -
					// that can of worms will stay closed
					if(!Effect.BANNED_RANDOM_ENCHANTMENTS[enchantmentName]) runeList.push(enchantmentName);
					else enchantments++;
				}
				// each effect must now be given a level, for this we do a bucket sort
				// to stack the effects
				var bucket:Vector.<int> = new Vector.<int>(Item.stats["rune names"].length);
				var i:int;
				for(i = 0; i < runeList.length; i++){
					bucket[runeList[i]]++;
				}
				for(i = 0; i < bucket.length; i++){
					if(bucket[i]){
						var effectXML:XML = <effect name={i} level={bucket[i]} />;
						itemXML.appendChild(effectXML);
					}
				}
			}
			// skull armour and fireflies always start with a free enchantment
			var enchantXMLList:XMLList;
			if(type == Item.ARMOUR){
				if(name == Item.FIRE_FLIES){
					enchantXMLList = itemXML..effect.(@["name"] == Effect.LIGHT)
					if(enchantXMLList.length()){
						enchantXMLList[0].@level = int(enchantXMLList[0].@level) + 1;
					} else {
						effectXML =<effect name={Effect.LIGHT} level="1" />
						itemXML.appendChild(effectXML);
					}
				} else if(name == Item.SKULL){
					enchantXMLList = itemXML..effect.(@["name"] == Effect.UNDEAD)
					if(enchantXMLList.length()){
						enchantXMLList[0].@level = int(enchantXMLList[0].@level) + 1;
					} else {
						effectXML =<effect name={Effect.UNDEAD} level="1" />
						itemXML.appendChild(effectXML);
					}
				}
			}
			return itemXML;
		}
		
		/* Converts xml to entities
		 * 
		 * All Entities have a toXML() method that allows a snapshot of the object to be taken for storage in the
		 * game save, or as a template for copies of that object. This method converts the xml into objects for
		 * use in the engine. */
		public static function convertXMLToEntity(x:int, y:int, xml:XML):*{
			var objectType:String = xml.name();
			var i:int, children:XMLList, item:XML, mc:DisplayObject, obj:*;
			var name:int, level:int, type:int;
			var className:Class;
			var items:Vector.<Item>;
			if(objectType == "chest"){
				children = xml.children();
				items = new Vector.<Item>();
				for each(item in children){
					items.push(convertXMLToEntity(x, y, item));
				}
				mc = new ChestMC();
				obj = new Chest(mc, x * Game.SCALE + Game.SCALE * 0.5, (y + 1) * Game.SCALE, items);
				
			} else if(objectType == "item"){
				name = xml.@name;
				level = xml.@level;
				type = xml.@type;
				mc = game.library.getItemGfx(name, type);
				if(type == Item.ARMOUR && name == Item.FACE){
					obj = new Face(mc, level);
				} else {
					obj = new Item(mc, name, type, level);
				}
				
				// is this item enchanted?
				var effect:Effect;
				for each(var enchantment:XML in xml.effect){
					effect = new Effect(enchantment.@name, enchantment.@level, 0);
					obj = effect.enchant(obj);
				}
				
				// is this item cursed?
				obj.curseState = int(xml.@curseState);
				
			} else if(objectType == "character"){
				name = xml.@name;
				level = xml.@level;
				type = xml.@type;
				if(xml.item.length()){
					items = new Vector.<Item>();
					for each(item in xml.item){
						items.push(convertXMLToEntity(x, y, item));
					}
				}
				if(type == Character.MONSTER){
					mc = game.library.getCharacterGfx(name);
					obj = new Monster(mc, (x + 0.5) * Game.SCALE, (y + 1) * Game.SCALE, name, level, items);
				}
				
			} else if(objectType == "portal"){
				type = xml.@type;
				level = xml.@targetLevel;
				mc = new Portal.GFX_CLASSES[type];
				mc.x = x * Game.SCALE;
				mc.y = y * Game.SCALE;
				obj = new Portal(mc, new Rectangle(x * Game.SCALE, y * Game.SCALE, Game.SCALE, Game.SCALE), type, xml.@targetLevel, Portal.OPEN, false);
				obj.mapX = x;
				obj.mapY = y;
				if(Map.isPortalToPreviousLevel(x, y, type, level)) game.entrance = obj;
				
			}
			
			obj.mapZ = Map.ENTITIES;
			
			return obj;
		}
		
	}

}