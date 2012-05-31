package com.robotacid.level {
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
	import com.robotacid.phys.Collider;
	import com.robotacid.util.array.randomiseArray;
	import com.robotacid.util.XorRandom;
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
		public var questGemsByLevel:Vector.<int>
		public var seedsByLevel:Vector.<uint>;
		public var monsterXpByLevel:Vector.<Number>;
		
		public static var xpTable:Vector.<Number>;
		
		public var itemDungeonContent:Object;
		public var areaContent:Array;
		
		public static var monsterNameDeck:Array;
		public static var weaponNameDeck:Array;
		public static var armourNameDeck:Array;
		public static var runeNameDeck:Array;
		
		// special items
		public var deathsScythe:Item;
		public var yendor:Item;
		
		public static const TOTAL_LEVELS:int = 20;
		public static const TOTAL_AREAS:int = 2;
		
		public static const CURSED_CHANCE:Number = 0.05;
		public static const BLESSED_CHANCE:Number = 0.95;
		public static const XP_TABLE_SEED:Number = 10;
		public static const XP_RATE:Number = 2;
		public static const MONSTER_XP_BY_LEVEL_RATE:Number = 1.2;
		
		public static const MONSTER_ZONE_DECKS:Array = [
			[Character.KOBOLD, Character.GOBLIN, Character.ORC, Character.TROLL, Character.GNOLL],
			[Character.DROW, Character.CACTUAR, Character.NYMPH, Character.VAMPIRE, Character.WEREWOLF],
			[Character.MIMIC, Character.NAGA, Character.GORGON, Character.UMBER_HULK, Character.GOLEM],
			[Character.BANSHEE, Character.WRAITH, Character.MIND_FLAYER, Character.RAKSHASA]
		];
		public static const WEAPON_ZONE_DECKS:Array = [
			[Item.KNIFE, Item.GAUNTLET, Item.DAGGER, Item.MACE, Item.SHORT_BOW],
			[Item.WHIP, Item.SWORD, Item.ARBALEST, Item.SPEAR, Item.CHAKRAM],
			[Item.STAFF, Item.BOMB, Item.ARQUEBUS, Item.HAMMER, Item.LONG_BOW],
			[Item.GUN_BLADE, Item.SCYTHE, Item.CHAOS_WAND, Item.LIGHTNING]
		];
		public static const ARMOUR_ZONE_DECKS:Array = [
			[Item.FLIES, Item.TIARA, Item.FEDORA, Item.TOP_HAT, Item.FIRE_FLIES],
			[Item.HALO, Item.BEES, Item.VIKING_HELM, Item.SKULL, Item.CROWN],
			[Item.BLOOD, Item.GOGGLES, Item.WIZARD_HAT, Item.HELMET, Item.INVISIBILITY],
			[Item.INDIFFERENCE, Item.CHAOS_HELM, Item.CHAOS_WAND, Item.FACE]
		];
		public static const RUNE_ZONE_DECKS:Array = [
			[Item.LIGHT, Item.HEAL, Item.POISON, Item.IDENTIFY, Item.UNDEAD],
			[Item.TELEPORT, Item.THORNS, Item.NULL, Item.PORTAL, Item.SLOW],
			[Item.HASTE, Item.HOLY, Item.PROTECTION, Item.STUN, Item.POLYMORPH],
			[Item.CONFUSION, Item.FEAR, Item.LEECH_RUNE, Item.XP, Item.CHAOS]
		];
		
		public function Content() {
			var obj:Object;
			var level:int;
			var i:int, j:int;
			
			// initialise the xp table
			xpTable = Vector.<Number>([0]);
			monsterXpByLevel = Vector.<Number>([0]);
			var xp:Number = XP_TABLE_SEED;
			var total:int = 0;
			for(level = 1; level <= Game.MAX_LEVEL; level++, xp *= XP_RATE){
				xpTable.push(xp);
				monsterXpByLevel.push(getLevelXp(level) * MONSTER_XP_BY_LEVEL_RATE);
				total += xp;
			}
			
			//trace("xp table", xpTable.length, xpTable);
			//trace("monster xp by level", monsterXpByLevel.length, monsterXpByLevel);
			
			// construct names by level decks in order of zone
			monsterNameDeck = [];
			weaponNameDeck = [];
			armourNameDeck = [];
			runeNameDeck = [];
			var monsterZoneDecks:Array = [MONSTER_ZONE_DECKS[Map.DUNGEONS].slice(), MONSTER_ZONE_DECKS[Map.SEWERS].slice(), MONSTER_ZONE_DECKS[Map.CAVES].slice(), MONSTER_ZONE_DECKS[Map.CHAOS].slice()];
			var weaponZoneDecks:Array = [WEAPON_ZONE_DECKS[Map.DUNGEONS].slice(), WEAPON_ZONE_DECKS[Map.SEWERS].slice(), WEAPON_ZONE_DECKS[Map.CAVES].slice(), WEAPON_ZONE_DECKS[Map.CHAOS].slice()];
			var armourZoneDecks:Array = [ARMOUR_ZONE_DECKS[Map.DUNGEONS].slice(), ARMOUR_ZONE_DECKS[Map.SEWERS].slice(), ARMOUR_ZONE_DECKS[Map.CAVES].slice(), ARMOUR_ZONE_DECKS[Map.CHAOS].slice()];
			var runeZoneDecks:Array = [RUNE_ZONE_DECKS[Map.DUNGEONS].slice(), RUNE_ZONE_DECKS[Map.SEWERS].slice(), RUNE_ZONE_DECKS[Map.CAVES].slice(), RUNE_ZONE_DECKS[Map.CHAOS].slice()];
			
			var templates:Array = [monsterZoneDecks, weaponZoneDecks, armourZoneDecks, runeZoneDecks];
			var targets:Array = [monsterNameDeck, weaponNameDeck, armourNameDeck, runeNameDeck];
			var template:Array;
			var target:Array;
			var zone:Array;
			
			// each zone's list is randomised and then added to the target levels
			for(i = 0; i < templates.length; i++){
				template = templates[i];
				target = targets[i];
				// level 1 always starts with the the first content to keep the entry point easy
				target.push(template[0].shift());
				for(j = 0; j < template.length; j++){
					zone = template[j];
					randomiseArray(zone, Map.random);
					while(target.length < Map.LEVELS_PER_ZONE * (j + 1)) target.push(zone.pop());
					
					// the remainder is added to the pool for the next zone
					if(j < template.length - 1){
						while(zone.length) template[j + 1].push(zone.pop());
						
					// the last zone is itself plus all the remainder
					} else {
						while(zone.length) target.push(zone.pop());
					}
				}
			}
			
			// initialise content lists
			Character.characterNumCount = 1;
			chestsByLevel = new Vector.<Vector.<XML>>(TOTAL_LEVELS + 1);
			monstersByLevel = new Vector.<Vector.<XML>>(TOTAL_LEVELS + 1);
			portalsByLevel = new Vector.<Vector.<XML>>(TOTAL_LEVELS + 1);
			trapsByLevel = new Vector.<int>();
			secretsByLevel = new Vector.<int>();
			questGemsByLevel = new Vector.<int>();
			seedsByLevel = new Vector.<uint>();
			for(level = 0; level <= TOTAL_LEVELS; level++){
				obj = getLevelContent(level);
				monstersByLevel[level] = obj.monsters;
				chestsByLevel[level] = obj.chests;
				portalsByLevel[level] = new Vector.<XML>();
				trapsByLevel[level] = trapQuantityPerLevel(level);
				secretsByLevel[level] = 2;
				questGemsByLevel[level] = 0;
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
			
			// set up underworld portal on level 16
			var portalXML:XML = <portal />;
			portalXML.@type = Portal.UNDERWORLD;
			portalXML.@targetLevel = Map.UNDERWORLD;
			portalsByLevel[16].push(portalXML);
			setUnderworldPortal(16);
			createUniqueItems();
		}
		
		/* All unique items exist in Content as well as outside */
		private function createUniqueItems():void{
			deathsScythe = new Item(new ScytheMC, Item.SCYTHE, Item.WEAPON, Game.MAX_LEVEL);
			deathsScythe.uniqueNameStr = "death's scythe";
			var effect:Effect = new Effect(Effect.UNDEAD, Game.MAX_LEVEL);
			effect.enchant(deathsScythe);
		}
		
		// Equations for quantities on levels
		
		public function equipmentQuantityPerLevel(level:int):int{
			if(level <= 0) return 0;
			if(level > TOTAL_LEVELS) level = TOTAL_LEVELS;
			var n:Number = (level + Map.random.range(3)) * 0.5;
			return n == (n >> 0) ? n : (n >> 0) + 1; // inline Math.ceil()
		}
		
		public function runeQuantityPerLevel(level:int):int{
			if(level <= 0) return 0;
			if(level > TOTAL_LEVELS) level = TOTAL_LEVELS;
			var n:Number = (level + Map.random.range(2)) * 0.5;
			return n == (n >> 0) ? n : (n >> 0) + 1; // inline Math.ceil()
		}
		
		public function monsterQuantityPerLevel(level:int):int{
			if(level <= 0) return 0;
			if(level > TOTAL_LEVELS) level = TOTAL_LEVELS;
			var n:Number = level * (2 + Map.random.range(2)) * 0.6;
			if(n > 24) n = 24;
			// I have no idea what this algorithm is doing anymore
			return 5 + Map.random.range(6) + n;
		}
		
		public function trapQuantityPerLevel(level:int):int{
			if(level > TOTAL_LEVELS) level = TOTAL_LEVELS;
			return 1 + Math.ceil(level / (2 + Map.random.rangeInt(3)));
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
				equipment.push(createItemXML(level, Map.random.value() <= 0.5 ? Item.WEAPON : Item.ARMOUR));
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
					if(Map.random.coinFlip()){
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
		
		/* Creates content for the enchanted item side-level */
		public function setItemDungeonContent(item:Item, level:int):void{
			itemDungeonContent = getLevelContent(level, item.toXML());
			itemDungeonContent.portals = Vector.<XML>([<portal type={Portal.ITEM_RETURN} targetLevel={level} />]);
			itemDungeonContent.secrets = 2;
			itemDungeonContent.traps = trapQuantityPerLevel(level);
			itemDungeonContent.seed = Math.random() * uint.MAX_VALUE;
			itemDungeonContent.questGems = 0;
			itemDungeonContent.monsterXp = getLevelXp(level);
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
		public function populateLevel(mapType:int, mapLevel:int, bitmap:MapBitmap, layers:Array, random:XorRandom):int{
			var r:int, c:int;
			var i:int, j:int, n:int;
			var chest:Chest;
			var monster:Monster;
			var item:Item;
			var list:Array;
			var minX:int, maxX:int;
			var monsters:Vector.<XML>;
			var chests:Vector.<XML>;
			var questGems:int = 0;
			var completionCount:int = 0;
			var room:Room;
			var surface:Surface;
			var name:int;
			var monsterXp:Number;
			var monsterXpSplit:Number;
			
			if(mapType == Map.MAIN_DUNGEON){
				if(mapLevel < monstersByLevel.length){
					monsters = monstersByLevel[mapLevel];
					chests = chestsByLevel[mapLevel];
					questGems = questGemsByLevel[mapLevel];
					monsterXp = monsterXpByLevel[mapLevel];
					questGemsByLevel[mapLevel] = 0;
					monsterXpByLevel[mapLevel] = 0;
				} else {
					var obj:Object = getLevelContent(mapLevel);
					monsters = monstersByLevel[mapLevel] = obj.monsters;
					chests = chestsByLevel[mapLevel] = obj.chests;
					questGemsByLevel[mapLevel] = 0;
					monsterXpByLevel[mapLevel] = 0;
					monsterXp = 0;
					questGems = 0;
				}
			} else if(mapType == Map.ITEM_DUNGEON){
				monsters = itemDungeonContent.monsters;
				chests = itemDungeonContent.chests;
				questGems = itemDungeonContent.questGems;
				monsterXp = itemDungeonContent.monsterXp;
				itemDungeonContent.questGems = 0;
				itemDungeonContent.monsterXp = 0;
			}
			
			// distribute
			
			if(mapType != Map.AREA){
				
				// get monster xp split
				if(monsterXp || monsters.length) monsterXpSplit = monsterXp / monsters.length;
				else monsterXpSplit = 0;
				
				completionCount += monsters.length;
				completionCount += chests.length;
				completionCount += questGems;
				
				var roomList:Vector.<Room> = bitmap.rooms.slice();
				var secretRoomList:Vector.<Room> = new Vector.<Room>();
				// remove the start room
				for(i = roomList.length - 1; i > -1; i--){
					if(roomList[i].start){
						roomList.splice(i, 1);
						break;
					}
				}
				if(bitmap.leftSecretRoom){
					roomList.push(bitmap.leftSecretRoom);
					secretRoomList.push(bitmap.leftSecretRoom);
				}
				if(bitmap.rightSecretRoom){
					roomList.push(bitmap.rightSecretRoom);
					secretRoomList.push(bitmap.rightSecretRoom);
				}
				// randomise
				for(i = roomList.length; i; j = random.rangeInt(i), room = roomList[--i], roomList[i] = roomList[j], roomList[j] = room){}
				
				// drop chests into rooms
				while(chests.length){
					room = roomList[random.rangeInt(roomList.length)];
					if(room.surfaces.length){
						surface = room.surfaces[random.rangeInt(room.surfaces.length)];
						// seems to be really keen on putting chests on ladders - I'm not keen on this
						if(surface.properties & Collider.LADDER) continue;
						chest = XMLToEntity(surface.x, surface.y, chests.shift());
						chest.mimicInit(mapType, mapLevel);
						layers[Map.ENTITIES][surface.y][surface.x] = chest;
						Surface.removeSurface(surface.x, surface.y);
					}
				}
				
				// sort monsters by racial group - packs of similar monsters look good
				var groups:Object = {};
				var group:String;
				for(i = 0; i < monsters.length; i++){
					name = monsters[i].@name;
					group = Character.stats["groups"][name];
					if(!groups[group]) groups[group] = [monsters[i]];
					else groups[group].push(monsters[i]);
				}
				
				// get the mean quantity of monsters per room
				var mean:Number = monsters.length / roomList.length;
				//trace("mean", mean);
				//trace("total", monsters.length);
				
				// tracking current room
				i = 0;
				// tracking monsters deployed (debugging)
				j = 0;
				
				
				var temp:Number = 0;
				
				var monsterGroup:Array;
				for(group in groups){
					monsterGroup = groups[group];
					room = roomList[i];
					while(monsterGroup.length){
						if(room.surfaces.length){
							n = (mean * 0.5) + random.range(mean * 1.5);
							if(n < 1) n = 1;
							if(n > monsterGroup.length) n = monsterGroup.length;
							if(n > room.surfaces.length) n = room.surfaces.length - 2;
							while(n-- > 0 && room.surfaces.length){
								j++;
								surface = room.surfaces[random.rangeInt(room.surfaces.length)];
								monster = XMLToEntity(surface.x, surface.y, monsterGroup.pop());
								monster.xpReward = monsterXpSplit;
								layers[Map.ENTITIES][surface.y][surface.x] = monster;
								Surface.removeSurface(surface.x, surface.y);
							}
							i++;
							if(i >= roomList.length) i = 0;
							room = roomList[i];
						} else {
							i++;
							if(i >= roomList.length) i = 0;
							room = roomList[i];
						}
					}
				}
				//trace("deployed", j);
				monsters.length = 0;
				
				if(questGems) dropQuestGems(questGems, layers, bitmap);
				
			} else {
				// on areas we just scatter objects left up there
				if(mapLevel == Map.OVERWORLD){
					minX = 2;
					maxX = bitmap.width - 2;
					r = bitmap.height - 2;
				} else if(mapLevel == Map.UNDERWORLD){
					minX = Map.UNDERWORLD_BOAT_MIN;
					maxX = Map.UNDERWORLD_BOAT_MAX;
					r = bitmap.height - 3;
				}
				while(areaContent[mapLevel].chests.length){
					chest = XMLToEntity(0, 0, areaContent[mapLevel].chests.shift());
					while(chest.contents.length){
						item = chest.contents.shift();
						c = minX + random.range(maxX - minX);
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
			
			return completionCount;
		}
		
		/* Distributes quest gems to the map */
		public function dropQuestGems(total:int, layers:Array, bitmap:MapBitmap, dropToMap:Boolean = false):void{
			
			var breaker:int = 1000;
			var r:int, c:int, item:Item;
			while(total){
				r = 1 + game.random.range(bitmap.height - 2);
				c = 1 + game.random.range(bitmap.width - 2);
				if(!layers[Map.ENTITIES][r][c] && layers[Map.BLOCKS][r][c] != MapTileConverter.WALL && layers[Map.BLOCKS][r + 1][c] == MapTileConverter.WALL){
					item = new Item(new QuestGemMC, 0, Item.QUEST_GEM, 0);
					item.dropToMap(c, r, dropToMap);
					if(dropToMap) renderer.createTeleportSparkRect(item.collider, 30);
					else layers[Map.ENTITIES][r][c] = item;
					total--;
				}
				if(breaker-- <= 0){
					trace("broken gem drop");
				}
			}
		}
		
		/* Fetch all portals on a level - used by Map to create portal access points */
		public function getPortals(level:int, mapType:int):Vector.<XML>{
			var list:Vector.<XML> = new Vector.<XML>();
			if(mapType == Map.MAIN_DUNGEON){
				if(level < portalsByLevel.length){
					while(portalsByLevel[level].length) list.push(portalsByLevel[level].pop());
				} else {
					portalsByLevel[level] = new Vector.<XML>()
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
		
		/* Returns the amount of secrets in this part of the level */
		public function getSecrets(dungeonLevel:int, dungeonType:int):int{
			if(dungeonType == Map.MAIN_DUNGEON){
				while(dungeonLevel >= secretsByLevel.length) secretsByLevel.push(2);
				return secretsByLevel[dungeonLevel];
			} else if(dungeonType == Map.ITEM_DUNGEON){
				return itemDungeonContent.secrets;
			}
			return 0;
		}
		
		/* Returns the amount of traps in this part of the level */
		public function getTraps(dungeonLevel:int, dungeonType:int):int{
			if(dungeonType == Map.MAIN_DUNGEON){
				while(dungeonLevel >= trapsByLevel.length) trapsByLevel.push(trapQuantityPerLevel(dungeonLevel));
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
			var level:int = game.map.level;
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
			//trace("recycling..." + game.map.level);
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
				// recycle xp
				if(mapType == Map.MAIN_DUNGEON) monsterXpByLevel[level] += (entity as Monster).xpReward;
				else if(mapType == Map.ITEM_DUNGEON) itemDungeonContent.monsterXp += (entity as Monster).xpReward;
				// do not recycle generated monsters
				if((entity as Monster).characterNum > -1) monsters.push(entity.toXML());
				
			} else if(entity is Item){
				item = entity as Item;
				// strip Death's Scythe from the level to return it to Death
				if(item == deathsScythe){
					item.location = Item.UNASSIGNED;
					return;
				}
				if(item.type == Item.QUEST_GEM){
					if(mapType == Map.ITEM_DUNGEON){
						itemDungeonContent.questGems++;
					} else if(mapType == Map.MAIN_DUNGEON){
						questGemsByLevel[level]++;
					}
				}
				if(item.type == Item.KEY){
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
					if((entity as Stone).weapon && (entity as Stone).weapon.uniqueNameStr == "death's scythe"){
						
					}
				}
			}
		}
		
		/* Create a random character appropriate for the dungeon level
		 * 
		 * Currently set up for just Monsters */
		public static function createCharacterXML(mapLevel:int, characterType:int):XML{
			var name:int;
			var level:int = mapLevel - 3;
			if(level < -1) level = -1;
			if(characterType == Character.MONSTER){
				var nameRange:int = mapLevel > monsterNameDeck.length ? monsterNameDeck.length : mapLevel;
				name = monsterNameDeck[Map.random.rangeInt(nameRange)];
			}
			return <character characterNum={(Character.characterNumCount++)} name={name} type={characterType} level={level} />;
		}
		
		/* Create a random item appropriate for the dungeon level */
		public static function createItemXML(mapLevel:int, type:int):XML{
			var enchantments:int = -2 + Map.random.range(mapLevel);
			var name:int;
			var level:int = Math.min(1 + Map.random.range(mapLevel), Game.MAX_LEVEL);
			
			var nameRange:int;
			if(type == Item.ARMOUR){
				nameRange = mapLevel > armourNameDeck.length ? armourNameDeck.length : mapLevel;
				name = armourNameDeck[Map.random.rangeInt(nameRange)];
			} else if(type == Item.WEAPON){
				nameRange = mapLevel > weaponNameDeck.length ? weaponNameDeck.length : mapLevel;
				name = weaponNameDeck[Map.random.rangeInt(nameRange)];
			} else if(type == Item.RUNE){
				nameRange = mapLevel > runeNameDeck.length ? runeNameDeck.length : mapLevel;
				name = runeNameDeck[Map.random.rangeInt(nameRange)];
				level = 0;
				enchantments = 0;
			} else if(type == Item.HEART){
				nameRange = mapLevel > monsterNameDeck.length ? monsterNameDeck.length : mapLevel;
				name = monsterNameDeck[Map.random.rangeInt(nameRange)];
				level = 0;
				enchantments = 0;
			}
			
			var itemXML:XML =<item name={name} type={type} level={level} />;
			
			// naturally occurring cursed and blessed items appear level 6+, at the point you can do something about them
			if((type == Item.ARMOUR || type == Item.WEAPON) && mapLevel >= 6){
				var holyState:int = 0;
				var roll:Number = Map.random.value();
				if(roll < CURSED_CHANCE) holyState = Item.CURSE_HIDDEN;
				else if(roll > BLESSED_CHANCE) holyState = Item.BLESSED;
				itemXML.@holyState = holyState;
			}

			if(enchantments > 0){
				var runeList:Vector.<int> = new Vector.<int>();
				var enchantmentName:int, enchantmentNameRange:int;
				while(enchantments--){
					enchantmentNameRange = Map.random.range(Game.MAX_LEVEL);
					if(enchantmentNameRange > mapLevel) enchantmentNameRange = mapLevel;
					enchantmentName = Map.random.range(enchantmentNameRange);
					// some enchantments confer multiple extra enchantments -
					// that can of worms will stay closed
					if(!Effect.BANNED_RANDOM_ENCHANTMENTS[enchantmentName]) runeList.push(enchantmentName);
					else enchantments++;
				}
				// each effect must now be given a level, for this we do a bucket sort
				// to stack the effects
				var bucket:Vector.<int> = new Vector.<int>(Game.MAX_LEVEL);
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
			// skull, chaos helm and fireflies always start with a free enchantment
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
				} else if(name == Item.CHAOS_HELM){
					enchantXMLList = itemXML..effect.(@["name"] == Effect.CHAOS)
					if(enchantXMLList.length()){
						enchantXMLList[0].@level = int(enchantXMLList[0].@level) + 1;
					} else {
						effectXML =<effect name={Effect.CHAOS} level="1" />
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
		public static function XMLToEntity(x:int, y:int, xml:XML):*{
			var objectType:String = xml.name();
			var i:int, children:XMLList, item:XML, mc:DisplayObject, obj:*;
			var name:int, level:int, type:int;
			var className:Class;
			var items:Vector.<Item>;
			if(objectType == "chest"){
				children = xml.children();
				items = new Vector.<Item>();
				for each(item in children){
					items.push(XMLToEntity(x, y, item));
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
					effect = new Effect(enchantment.@name, enchantment.@level);
					// chaos items use a loop hole in the enchant system to create a chaos effect spawner
					if(effect.name == Effect.CHAOS){
						effect.source = type;
						effect.addToItem(obj);
					} else {
						obj = effect.enchant(obj);
					}
				}
				
				// is this item cursed or blessed?
				obj.holyState = int(xml.@holyState);
				
				// does it have a name?
				if(xml.@uniqueNameStr && xml.@uniqueNameStr != "null") obj.uniqueNameStr = xml.@uniqueNameStr;
				
			} else if(objectType == "character"){
				name = xml.@name;
				level = xml.@level;
				type = xml.@type;
				if(xml.item.length()){
					items = new Vector.<Item>();
					for each(item in xml.item){
						items.push(XMLToEntity(x, y, item));
					}
				}
				if(type == Character.MONSTER){
					mc = game.library.getCharacterGfx(name);
					obj = new Monster(mc, (x + 0.5) * Game.SCALE, (y + 1) * Game.SCALE, name, level, items);
					obj.characterNum = xml.@characterNum;
					if(xml.@uniqueNameStr && xml.@uniqueNameStr != "null") obj.uniqueNameStr = xml.@uniqueNameStr;
					if(xml.@questVictim == "true") obj.questTarget();
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
		
		public static function getLevelXp(level:int):Number{
			if(level > Game.MAX_LEVEL) level = Game.MAX_LEVEL;
			return xpTable[level] - xpTable[level - 1];
		}
		
	}

}