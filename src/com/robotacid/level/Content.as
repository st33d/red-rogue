package com.robotacid.level {
	import com.robotacid.ai.BalrogBrain;
	import com.robotacid.engine.Balrog;
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
		
		public var gameState:Object;
		
		// vars that were moved to gameState:
		//public var chestsByLevel:Array/*Array*/;
		//public var monstersByLevel:Array/*Array*/;
		//public var portalsByLevel:Array/*Array*/;
		//public var trapsByLevel:Array/*int*/;
		//public var secretsByLevel:Array/*int*/;
		//public var questGemsByLevel:Array/*int*/;
		//public var altarsByLevel:Array/*int*/;
		//public var seedsByLevel:Array/*uint*/;
		//public var monsterXpByLevel:Array/*Number*/;
		//public var clearedByLevel:Array/*Number*/;
		
		//private var levelZones:Array/*int*/;
		//private var zoneSizes:Array/*int*/;
		//private var eliteNames:Object;
		
		//public var itemDungeonContent:Object;
		
		public static var xpTable:Array/*Number*/;
		
		public static var monsterNameDeck:Array;
		public static var weaponNameDeck:Array;
		public static var armourNameDeck:Array;
		public static var runeNameDeck:Array;
		public static var sewersFirstLevel:int;
		
		// special items
		public var deathsScythe:Item;
		public var yendor:Item;
		
		public static const TOTAL_LEVELS:int = 20;
		public static const TOTAL_AREAS:int = 2;
		
		public static const CURSED_CHANCE:Number = 0.1;
		public static const BLESSED_CHANCE:Number = 0.9;
		public static const XP_TABLE_SEED:Number = 10;
		public static const XP_RATE:Number = 2;
		public static const MONSTER_XP_BY_LEVEL_RATE:Number = 1.2;
		public static const UNDERWORLD_PORTAL_LEVEL:int = 11;
		
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
			[Item.LIGHT, Item.HEAL, Item.BLEED, Item.IDENTIFY, Item.UNDEAD],
			[Item.TELEPORT, Item.THORNS, Item.NULL, Item.PORTAL, Item.SLOW],
			[Item.HASTE, Item.HOLY, Item.PROTECTION, Item.STUN, Item.POLYMORPH],
			[Item.CONFUSION, Item.FEAR, Item.LEECH_RUNE, Item.XP, Item.CHAOS]
		];
		
		public static const SPECIAL_ITEMS:Array = [
			<item name={Item.GUN_LEECH} type={Item.WEAPON} level={1} location={Item.UNASSIGNED} holyState={Item.NO_CURSE} />,
			<item name={Item.COG} type={Item.WEAPON} level={1} location={Item.UNASSIGNED} holyState={Item.NO_CURSE}>
				<effect name={Item.CHAOS} level={1} />
			</item>,
			<item name={Item.HARPOON} type={Item.WEAPON} level={1} location={Item.UNASSIGNED} holyState={Item.NO_CURSE} />,
			<item name={Item.FEZ} type={Item.ARMOUR} level={1} location={Item.UNASSIGNED} holyState={Item.NO_CURSE}>
				<effect name={Item.SLOW} level={2} />
				<effect name={Item.CONFUSION} level={2} />
				<effect name={Item.UNDEAD} level={2} />
				<effect name={Item.HEAL} level={2} />
			</item>
		];
		
		public function Content() {
			var obj:Object;
			var level:int;
			var i:int, j:int;
			
			gameState = UserData.gameState;
			
			// initialise the static xp table
			if(!xpTable){
				xpTable = [0];
				var xp:Number = XP_TABLE_SEED;
				for(level = 1; level <= Game.MAX_LEVEL; level++, xp *= XP_RATE){
					xpTable.push(xp);
				}
			}
			
			if(!gameState.monsterXpByLevel){
				gameState.monsterXpByLevel = [0];
				gameState.clearedByLevel = [false];
				for(level = 1; level <= Game.MAX_LEVEL; level++){
					gameState.monsterXpByLevel.push(getLevelXp(level) * MONSTER_XP_BY_LEVEL_RATE);
					gameState.clearedByLevel.push(false);
				}
			}
			
			// create the number of levels per zone
			if(!gameState.levelZones){
				gameState.levelZones = [];
				gameState.zoneSizes = [0,0,0,0];
				var zoneLevels:Array = [];
				var levelsInZone:Array;
				var pruneChoice:Array = [];
				var levelsPerZone:int;
				for(i = 0; i < 4; i++){
					levelsInZone = [];
					levelsPerZone = Map.LEVELS_PER_ZONE;
					// when the character is ascended the zones randomly become longer
					if(UserData.settings.ascended && Map.random.coinFlip()) levelsPerZone++;
					for(j = 0; j < levelsPerZone; j++){
						levelsInZone.push(i);
					}
					zoneLevels.push(levelsInZone);
					if(i < 3) pruneChoice.push(i);
				}
				// prune one level from the zones leading to chaos to make zone length vary
				randomiseArray(pruneChoice, Map.random);
				zoneLevels[pruneChoice[0]].pop();
				for(i = 0; i < zoneLevels.length - 1; i++){
					levelsInZone = zoneLevels[i];
					for(j = 0; j < levelsInZone.length; j++){
						gameState.levelZones.push(levelsInZone[j]);
						gameState.zoneSizes[levelsInZone[j]]++;
					}
				}
				// introduce more mechanics at the beginning of the sewers
				gameState.sewersFirstLevel = gameState.zoneSizes[0] + 1;
			}
			sewersFirstLevel = gameState.sewersFirstLevel;
			
			//trace(gameState.zoneSizes);
			
			//trace("xp table", xpTable.length, xpTable);
			//trace("monster xp by level", monsterXpByLevel.length, monsterXpByLevel);
			
			// construct names by level decks in order of zone
			if(!gameState.monsterNameDeck){
				gameState.monsterNameDeck = [];
				gameState.weaponNameDeck = [];
				gameState.armourNameDeck = [];
				gameState.runeNameDeck = [];
				var monsterZoneDecks:Array = [MONSTER_ZONE_DECKS[Map.DUNGEONS].slice(), MONSTER_ZONE_DECKS[Map.SEWERS].slice(), MONSTER_ZONE_DECKS[Map.CAVES].slice(), MONSTER_ZONE_DECKS[Map.CHAOS].slice()];
				var weaponZoneDecks:Array = [WEAPON_ZONE_DECKS[Map.DUNGEONS].slice(), WEAPON_ZONE_DECKS[Map.SEWERS].slice(), WEAPON_ZONE_DECKS[Map.CAVES].slice(), WEAPON_ZONE_DECKS[Map.CHAOS].slice()];
				var armourZoneDecks:Array = [ARMOUR_ZONE_DECKS[Map.DUNGEONS].slice(), ARMOUR_ZONE_DECKS[Map.SEWERS].slice(), ARMOUR_ZONE_DECKS[Map.CAVES].slice(), ARMOUR_ZONE_DECKS[Map.CHAOS].slice()];
				var runeZoneDecks:Array = [RUNE_ZONE_DECKS[Map.DUNGEONS].slice(), RUNE_ZONE_DECKS[Map.SEWERS].slice(), RUNE_ZONE_DECKS[Map.CAVES].slice(), RUNE_ZONE_DECKS[Map.CHAOS].slice()];
				
				var templates:Array = [monsterZoneDecks, weaponZoneDecks, armourZoneDecks, runeZoneDecks];
				var targets:Array = [gameState.monsterNameDeck, gameState.weaponNameDeck, gameState.armourNameDeck, gameState.runeNameDeck];
				var template:Array;
				var target:Array;
				var zone:Array;
				var zoneLevelsMax:int;
				
				// each zone's list is randomised and then added to the target levels
				for(i = 0; i < templates.length; i++){
					template = templates[i];
					target = targets[i];
					// level 1 always starts with the the first content to keep the entry point easy
					target.push(template[0].shift());
					zoneLevelsMax = 0;
					for(j = 0; j < template.length; j++){
						zone = template[j];
						randomiseArray(zone, Map.random);
						zoneLevelsMax += gameState.zoneSizes[j];
						while(target.length < zoneLevelsMax) target.push(zone.pop());
						
						// the remainder is added to the pool for the next zone
						if(j < template.length - 1){
							while(zone.length) template[j + 1].push(zone.pop());
							
						// the last zone is itself plus all the remainder
						} else {
							while(zone.length) target.push(zone.pop());
						}
					}
				}
			}
			monsterNameDeck = gameState.monsterNameDeck;
			weaponNameDeck = gameState.weaponNameDeck;
			armourNameDeck = gameState.armourNameDeck;
			runeNameDeck = gameState.runeNameDeck;
			
			// initialise content lists
			Character.characterNumCount = 1;
			
			if(!gameState.chestsByLevel){
				gameState.chestsByLevel = [];
				gameState.monstersByLevel = [];
				gameState.portalsByLevel = [];
				gameState.trapsByLevel = [];
				gameState.secretsByLevel = [];
				gameState.altarsByLevel = [];
				gameState.questGemsByLevel = [];
				gameState.seedsByLevel = [];
				for(level = 0; level <= TOTAL_LEVELS; level++){
					obj = getLevelContent(level);
					gameState.monstersByLevel[level] = obj.monsters;
					gameState.chestsByLevel[level] = obj.chests;
					gameState.portalsByLevel[level] = [];
					gameState.trapsByLevel[level] = trapQuantityPerLevel(level);
					gameState.secretsByLevel[level] = 2;
					gameState.altarsByLevel[level] = level >= sewersFirstLevel ? Map.random.rangeInt(3) : 0;
					gameState.questGemsByLevel[level] = 0;
					Map.random.value();
					gameState.seedsByLevel[level] = Map.random.r;
				}
				// getting here infers that the item dungeon no longer exists
				removeItemDungeonPortals();
				
				// insert the existing portal ends from the areaContent
				var areaPortalXML:XML;
				var areaContent:Array = UserData.settings.areaContent;
				var portalList:Array
				var targetLevel:int;
				for(i = 0; i < areaContent.length; i++){
					portalList = UserData.settings.areaContent[i].portals;
					for(j = 0; j < portalList.length; j++){
						areaPortalXML = portalList[j];
						targetLevel = areaPortalXML.@targetLevel;
						while(targetLevel >= gameState.portalsByLevel.length) gameState.portalsByLevel.push([]);
						gameState.portalsByLevel[targetLevel].push(<portal type={Portal.PORTAL} targetLevel={i} targetType={Map.AREA} />);
					}
				}
				
				// introduce the balrog in the first level of chaos
				gameState.balrog.mapLevel = gameState.zoneSizes[0] + gameState.zoneSizes[1] + gameState.zoneSizes[2] + 1 + (UserData.settings.ascended ? Map.random.rangeInt(2) : 0);
				// create the balrog
				gameState.balrog.xml = createBalrogXML();
				if(UserData.settings.playerConsumed) gameState.balrog.mapLevel = 1;
				//gameState.balrog.mapLevel = 1;
			
				// create the elite monsters
				var zoneNum:int = 0;
				if(!gameState.eliteNames){
					gameState.eliteNames = {};
					for(level = 1; level < TOTAL_LEVELS; level++){
						if(level >= gameState.levelZones.length || zoneNum < gameState.levelZones[level - 1]){
							zoneNum++;
							gameState.monstersByLevel[level - 1].push(createEliteXML(level - 1, gameState.eliteNames));
							if(zoneNum == Map.CHAOS) break;
						}
					}
				}
			}
			
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
		
		/* Returns the zone a level is in */
		public function getLevelZone(level:int):int{
			level--;
			if(level <= 0) return 0;
			if(level < gameState.levelZones.length) return gameState.levelZones[level];
			return Map.CHAOS;
		}
		
		/* Create a satisfactory amount of monsters and loot for a level
		 * 
		 * Returns a list of monster XMLs and chest XMLs with loot therein */
		public function getLevelContent(level:int, item:XML = null):Object{
			if(level > TOTAL_LEVELS) level = TOTAL_LEVELS;
			var monsters:Array = [];
			var chests:Array = [];
			var obj:Object = {monsters:monsters, chests:chests};
			if(level <= 0) return obj;
			
			var equipment:Array = [];
			var runes:Array = [];
			
			// if an item is fed into this level, add it to the equipment list
			if(item){
				equipment.push(item);
				// side dungeons require smaller quantities
				var sideDungeonLevel:int = 1 + (Number(level) / 10);
			}
			
			var quantity:int;
			quantity = equipmentQuantityPerLevel(item ? sideDungeonLevel : level);
			while(quantity--){
				equipment.push(createItemXML(level, Map.random.value() <= 0.5 ? Item.WEAPON : Item.ARMOUR));
			}
			quantity = runeQuantityPerLevel(item ? sideDungeonLevel : level);
			while(quantity--){
				runes.push(createItemXML(level, Item.RUNE));
			}
			quantity = monsterQuantityPerLevel(item ? sideDungeonLevel : level)
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
				
				// promote equipped monsters to champions
				monsters[equippedMonsters].@rank = Character.CHAMPION;
				
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
				while(level >= gameState.seedsByLevel.length) gameState.seedsByLevel.push(XorRandom.seedFromDate());
				return gameState.seedsByLevel[level];
			} else if(type == Map.ITEM_DUNGEON){
				return gameState.itemDungeonContent.seed;
			}
			return Math.random() * uint.MAX_VALUE;
		}
		
		/* Creates content for the enchanted item side-level */
		public function setItemDungeonContent(item:Item, level:int, type:int):void{
			// existing portals in a previous pocket dungeon need to be removed or reset
			if(gameState.itemDungeonContent){
				removeItemDungeonPortals();
			}
			gameState.itemDungeonContent = getLevelContent(level, item.toXML());
			gameState.itemDungeonContent.portals = [<portal type={Portal.PORTAL} targetLevel={level} targetType={type} />];
			gameState.itemDungeonContent.secrets = 2;
			gameState.itemDungeonContent.traps = trapQuantityPerLevel(level);
			gameState.itemDungeonContent.seed = XorRandom.seedFromDate();
			gameState.itemDungeonContent.questGems = 0;
			gameState.itemDungeonContent.altars = game.random.rangeInt(3);
			gameState.itemDungeonContent.monsterXp = getLevelXp(level);
		}
		
		/* Retargets the underworld portal */
		public static function setUnderworldPortal(level:int, type:int):void{
			UserData.settings.areaContent[Map.UNDERWORLD].portals = [<portal type={Portal.PORTAL} targetLevel={level} targetType={type} />];
		}
		
		/* Creates or retargets the overworld portal */
		public static function setOverworldPortal(level:int, type:int):void{
			UserData.settings.areaContent[Map.OVERWORLD].portals = [<portal type={Portal.PORTAL} targetLevel={level} targetType={type} />];
		}
		
		/* Remove any connections to an existing item dungeon */
		public static function removeItemDungeonPortals():void{
			var i:int, j:int, xml:XML;
			var areaContent:Array = UserData.settings.areaContent;
			for(i = 0; i < areaContent.length; i++){
				for(j = 0; j < areaContent[i].portals.length; j++){
					xml = areaContent[i].portals[j];
					if(int(xml.@targetType) == Map.ITEM_DUNGEON){
						areaContent[i].portals.splice(j);
						j--;
					}
				}
			}
			// repair the underworld portal if missing
			if(areaContent[Map.UNDERWORLD].portals.length == 0){
				// move back to UNDERWORLD_PORTAL_LEVEL, or UNDERWORLD_PORTAL_LEVEL+1 if we're on it already
				var targetLevel:int = UNDERWORLD_PORTAL_LEVEL;
				if(game && game.map && game.map.level == UNDERWORLD_PORTAL_LEVEL) targetLevel++;
				var portalXML:XML = <portal type={Portal.PORTAL} targetLevel={Map.UNDERWORLD} targetType={Map.AREA} />;
				UserData.gameState.portalsByLevel[targetLevel].push(portalXML);
				setUnderworldPortal(targetLevel, Map.MAIN_DUNGEON);
			}
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
			var monsters:Array/*XML*/;
			var chests:Array/*XML*/;
			var questGems:int = 0;
			var completionCount:int = 0;
			var cleared:Boolean;
			var room:Room;
			var surface:Surface;
			var name:int;
			var monsterXp:Number;
			var monsterXpSplit:Number;
			var xml:XML;
			
			if(mapType == Map.MAIN_DUNGEON){
				if(mapLevel < gameState.monstersByLevel.length){
					monsters = gameState.monstersByLevel[mapLevel];
					chests = gameState.chestsByLevel[mapLevel];
					questGems = gameState.questGemsByLevel[mapLevel];
					monsterXp = gameState.monsterXpByLevel[mapLevel];
					cleared = gameState.clearedByLevel[mapLevel];
					gameState.questGemsByLevel[mapLevel] = 0;
					gameState.monsterXpByLevel[mapLevel] = 0;
				} else {
					var obj:Object, fillLevel:int = gameState.monstersByLevel.length;
					while(mapLevel >= gameState.monstersByLevel.length){
						obj = getLevelContent(fillLevel);
						monsters = gameState.monstersByLevel[fillLevel] = obj.monsters;
						chests = gameState.chestsByLevel[fillLevel] = obj.chests;
						gameState.questGemsByLevel[fillLevel] = 0;
						gameState.monsterXpByLevel[fillLevel] = 0;
						gameState.clearedByLevel[fillLevel] = false;
						monsterXp = 0;
						questGems = 0;
						fillLevel = gameState.monstersByLevel.length;
					}
				}
			} else if(mapType == Map.ITEM_DUNGEON){
				monsters = gameState.itemDungeonContent.monsters;
				chests = gameState.itemDungeonContent.chests;
				questGems = gameState.itemDungeonContent.questGems;
				monsterXp = gameState.itemDungeonContent.monsterXp;
				cleared = gameState.itemDungeonContent.cleared;
				gameState.itemDungeonContent.questGems = 0;
				gameState.itemDungeonContent.monsterXp = 0;
			}
			
			// distribute
			
			if(mapType != Map.AREA){
				
				// is the balrog on this level?
				if(mapType == Map.MAIN_DUNGEON && gameState.balrog && gameState.balrog.mapLevel == mapLevel) monsters.push(gameState.balrog.xml);
				
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
				for(i = 0; i < chests.length; i++){
					room = roomList[random.rangeInt(roomList.length)];
					if(room.surfaces.length){
						surface = room.surfaces[random.rangeInt(room.surfaces.length)];
						// seems to be really keen on putting chests on ladders - I'm not keen on this
						if(surface.properties & Collider.LADDER){
							i--;
							continue;
						}
						chest = XMLToEntity(surface.x, surface.y, chests[i]);
						chest.mimicInit(mapType, mapLevel);
						layers[Map.ENTITIES][surface.y][surface.x] = chest;
						Surface.removeSurface(surface.x, surface.y);
					} else i--;
				}
				
				// sort monsters by racial group - packs of similar monsters look good
				var groups:Object = {};
				var group:String;
				for(i = 0; i < monsters.length; i++){
					name = monsters[i].@name;
					if(name == Character.BALROG){
						// the balrog manages its own entry point and location
						game.balrog = XMLToEntity(0, 0, monsters[i]);
					} else {
						group = Character.stats["groups"][name];
						if(!groups[group]) groups[group] = [monsters[i]];
						else groups[group].push(monsters[i]);
					}
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
				//monsters.length = 0;
				
				if(questGems) dropQuestGems(questGems, layers, bitmap);
				
			} else {
				// on areas we use the mapX and mapY properties to place items, falling back to scattering
				if(mapLevel == Map.OVERWORLD){
					minX = 2;
					maxX = bitmap.width - 2;
					r = bitmap.height - 2;
				} else if(mapLevel == Map.UNDERWORLD){
					minX = Map.UNDERWORLD_PORTAL_X - 2;
					maxX = Map.UNDERWORLD_BOAT_MAX;
					r = bitmap.height - 3;
				}
				var areaContent:Array = UserData.settings.areaContent;
				for(i = 0; i < areaContent[mapLevel].chests.length; i++){
					var children:XMLList = areaContent[mapLevel].chests[i].children();
					for each(xml in children){
						if(xml.hasOwnProperty("@mapX")){
							c = xml.@mapX;
						} else {
							c = minX + random.range(maxX - minX);
						}
						item = XMLToEntity(c, r, xml);
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
				if(mapLevel == Map.OVERWORLD){
					if(UserData.settings.specialItemChest){
						chest = XMLToEntity(bitmap.width - 2, bitmap.height - 3, UserData.settings.specialItemChest, mapLevel, mapType);
						layers[Map.ENTITIES][bitmap.height - 3][bitmap.width - 2] = chest;
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
					if(dropToMap) renderer.createSparkRect(item.collider, 30, 0, -1);
					else layers[Map.ENTITIES][r][c] = item;
					total--;
				}
				if(breaker-- <= 0){
					trace("broken gem drop");
				}
			}
		}
		
		/* Returns the level clearing marker */
		public function getCleared(dungeonLevel:int, dungeonType:int):Boolean{
			if(dungeonType == Map.MAIN_DUNGEON){
				while(dungeonLevel >= gameState.clearedByLevel.length) gameState.clearedByLevel.push(false);
				return gameState.clearedByLevel[dungeonLevel];
			} else if(dungeonType == Map.ITEM_DUNGEON){
				return gameState.itemDungeonContent.cleared;
			}
			return false;
		}
		
		/* Fetch all portals on a level - used by Map to create portal access points */
		public function getPortals(level:int, mapType:int):Array{
			var list:Array = [];
			if(mapType == Map.MAIN_DUNGEON){
				if(level < gameState.portalsByLevel.length){
					list = gameState.portalsByLevel[level].slice();
				} else {
					gameState.portalsByLevel[level] = list;
				}
				
			} else if(mapType == Map.ITEM_DUNGEON){
				list = gameState.itemDungeonContent.portals.slice();
				
			} else if(mapType == Map.AREA){
				list = UserData.settings.areaContent[level].portals.slice();
				
			}
			return list;
		}
		
		/* Search the levels for a given portal type and remove it - this prevents multiples of the same portal */
		public function removePortal(targetLevel:int, targetType:int):void{
			var i:int, j:int, xml:XML;
			for(i = 0; i < gameState.portalsByLevel.length; i++){
				for(j = 0; j < gameState.portalsByLevel[i].length; j++){
					xml = gameState.portalsByLevel[i][j];
					if(int(xml.@targetLevel) == targetLevel && int(xml.@targetType) == targetType){
						gameState.portalsByLevel[i].splice(j, 1);
						return;
					}
				}
			}
			// check the pocket
			if(gameState.itemDungeonContent){
				for(i = 0; i < gameState.itemDungeonContent.portals.length; i++){
					xml = gameState.itemDungeonContent.portals[i];
					if(int(xml.@targetLevel) == targetLevel && int(xml.@targetType) == targetType){
						gameState.itemDungeonContent.portals.splice(i, 1);
						return;
					}
				}
			}
		}
		
		/* Returns the amount of secrets in this level */
		public function getSecrets(dungeonLevel:int, dungeonType:int):int{
			if(dungeonType == Map.MAIN_DUNGEON){
				while(dungeonLevel >= gameState.secretsByLevel.length) gameState.secretsByLevel.push(2);
				return gameState.secretsByLevel[dungeonLevel];
			} else if(dungeonType == Map.ITEM_DUNGEON){
				return gameState.itemDungeonContent.secrets;
			}
			return 0;
		}
		
		/* Returns the amount of traps in this level */
		public function getTraps(dungeonLevel:int, dungeonType:int):int{
			if(dungeonType == Map.MAIN_DUNGEON){
				while(dungeonLevel >= gameState.trapsByLevel.length) gameState.trapsByLevel.push(trapQuantityPerLevel(dungeonLevel));
				return gameState.trapsByLevel[dungeonLevel];
			} else if(dungeonType == Map.ITEM_DUNGEON){
				return gameState.itemDungeonContent.traps;
			}
			return 0;
		}
		
		/* Returns the amount of altars in this level */
		public function getAltars(dungeonLevel:int, dungeonType:int):int{
			if(dungeonType == Map.MAIN_DUNGEON){
				while(dungeonLevel >= gameState.altarsByLevel.length) gameState.altarsByLevel.push(game.random.rangeInt(3));
				return gameState.altarsByLevel[dungeonLevel];
			} else if(dungeonType == Map.ITEM_DUNGEON){
				return gameState.itemDungeonContent.altars;
			}
			return 0;
		}
		
		/* Removes a secret for good */
		public function removeSecret(dungeonLevel:int, dungeonType:int):void{
			if(dungeonType == Map.MAIN_DUNGEON){
				gameState.secretsByLevel[dungeonLevel]--;
			} else if(dungeonType == Map.ITEM_DUNGEON){
				gameState.itemDungeonContent.secrets--;
			}
		}
		
		/* Removes a trap for good */
		public function removeTrap(dungeonLevel:int, dungeonType:int):void{
			if(dungeonType == Map.MAIN_DUNGEON){
				gameState.trapsByLevel[dungeonLevel]--;
			} else if(dungeonType == Map.ITEM_DUNGEON){
				gameState.itemDungeonContent.traps--;
			}
		}
		
		/* Removes an altar for good */
		public function removeAltar(dungeonLevel:int, dungeonType:int):void{
			if(dungeonType == Map.MAIN_DUNGEON){
				gameState.altarsByLevel[dungeonLevel]--;
			} else if(dungeonType == Map.ITEM_DUNGEON){
				gameState.itemDungeonContent.altars--;
			}
		}
		
		/* Removes traps and secrets to keep map identified */
		public function clearLevel(dungeonLevel:int, dungeonType:int):void{
			if(dungeonType == Map.MAIN_DUNGEON){
				gameState.trapsByLevel[dungeonLevel] = 0;
				gameState.secretsByLevel[dungeonLevel] = 0;
				gameState.clearedByLevel[dungeonLevel] = true;
			} else if(dungeonType == Map.ITEM_DUNGEON){
				gameState.itemDungeonContent.traps = 0;
				gameState.itemDungeonContent.secrets = 0;
				gameState.itemDungeonContent.cleared = true;
			}
		}
		
		/* This method tracks down monsters and items and pulls them back into the content manager to be sent out
		 * again if the level is re-visited */
		public function recycleLevel(mapLevel:int, mapType:int):void{
			var i:int;
			// no recycling debug
			if(mapLevel < 0) return;
			if(mapType == Map.MAIN_DUNGEON){
				// if we've gone past the total level limit we need to create new content reserves on the fly
				if(mapLevel == gameState.monstersByLevel.length){
					gameState.monstersByLevel.push([]);
					gameState.chestsByLevel.push([]);
					gameState.portalsByLevel.push([]);
				}
				gameState.monstersByLevel[mapLevel].length = 0;
				gameState.chestsByLevel[mapLevel].length = 0;
				gameState.portalsByLevel[mapLevel].length = 0;
			} else if(mapType == Map.ITEM_DUNGEON){
				gameState.itemDungeonContent.monsters.length = 0;
				gameState.itemDungeonContent.chests.length = 0;
				gameState.itemDungeonContent.portals.length = 0;
			} else if(mapType == Map.AREA){
				UserData.settings.areaContent[mapLevel].monsters.length = 0;
				UserData.settings.areaContent[mapLevel].chests.length = 0;
				UserData.settings.areaContent[mapLevel].portals.length = 0;
			}
			// first we check the active list of entities
			for(i = 0; i < game.entities.length; i++){
				recycleEntity(game.entities[i], mapLevel, mapType);
			}
			for(i = 0; i < game.items.length; i++){
				recycleEntity(game.items[i], mapLevel, mapType);
			}
			if(game.balrog){
				recycleEntity(game.balrog, mapLevel, mapType);
				game.balrog = null;
			}
			var portal:Portal;
			for(i = 0; i < game.portals.length; i++){
				portal = game.portals[i];
				if(portal.type != Portal.STAIRS && (portal.state == Portal.OPEN || portal.state == Portal.OPENING)){
					recycleEntity(portal, mapLevel, mapType);
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
									recycleEntity(tile[i], mapLevel, mapType);
								}
							}
						} else if(tile is Entity){
							recycleEntity(tile, mapLevel, mapType);
						}
					}
				}
			}
			//trace("recycling..." + game.map.level);
			//for(i = 0; i < monstersByLevel[level].length; i++){
				//trace(monstersByLevel[level][i].toXMLString());
			//}
			//for(i = 0; i < gameState.chestsByLevel[mapLevel].length; i++){
				//trace(gameState.chestsByLevel[mapLevel][i].toXMLString());
			//}
		}
		
		/* Used in concert with the recycleLevel() method to convert level assets to XML and store them */
		public function recycleEntity(entity:Entity, level:int, mapType:int):void{
			var i:int, item:Item, character:Character;
			var chest:XML;
			var monsters:Array;
			var chests:Array;
			var portals:Array;
			
			if(mapType == Map.MAIN_DUNGEON){
				monsters = gameState.monstersByLevel[level];
				chests = gameState.chestsByLevel[level];
				portals = gameState.portalsByLevel[level];
				
			} else if(mapType == Map.ITEM_DUNGEON){
				monsters = gameState.itemDungeonContent.monsters;
				chests = gameState.itemDungeonContent.chests;
				portals = gameState.itemDungeonContent.portals;
				
			} else if(mapType == Map.AREA){
				monsters = UserData.settings.areaContent[level].monsters;
				chests = UserData.settings.areaContent[level].chests;
				portals = UserData.settings.areaContent[level].portals;
			}
			
			if(entity is Stone && entity.name == Stone.DEATH){
				// collect the scythe for safekeeping
				character = entity as Character;
				if(character.weapon){
					deathsScythe = character.unequip(character.weapon);
					deathsScythe.location = Item.UNASSIGNED;
				}
				
			} else if(entity is Monster){
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
				if(mapType == Map.MAIN_DUNGEON) gameState.monsterXpByLevel[level] += (entity as Monster).xpReward;
				else if(mapType == Map.ITEM_DUNGEON) gameState.itemDungeonContent.monsterXp += (entity as Monster).xpReward;
				// do not recycle generated monsters
				if((entity as Monster).characterNum > -1) monsters.push(entity.toXML());
				
			} else if(entity is Balrog){
				// the balrog could only have been recycled from the player leaving the level before it did
				if((entity as Balrog).brain.state == BalrogBrain.TAUNT){
					(entity as Balrog).levelState = Balrog.STAIRS_DOWN_TAUNT;
				} else {
					(entity as Balrog).levelState = Balrog.WANDER_LEVEL;
				}
				gameState.balrog.xml = entity.toXML();
				gameState.balrog.health = (entity as Balrog).health;
				
			} else if(entity is Item){
				item = entity as Item;
				// strip Death's Scythe from the level to return it to Death
				if(item == deathsScythe){
					item.location = Item.UNASSIGNED;
					return;
				}
				if(item.type == Item.QUEST_GEM){
					if(mapType == Map.ITEM_DUNGEON){
						gameState.itemDungeonContent.questGems++;
					} else if(mapType == Map.MAIN_DUNGEON){
						gameState.questGemsByLevel[level]++;
					}
					return;
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
				// the only chest in the overworld is the special item chest
				if(level == Map.OVERWORLD && mapType == Map.AREA){
					UserData.settings.specialItemChest = chest ? chest :<chest />;
				} else if(chest){
					chests.push(chest);
				}
				
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
			// monsters become harder when ascended
			if(UserData.settings.ascended) level++;
			if(level < -1) level = -1;
			if(characterType == Character.MONSTER){
				var nameRange:int = mapLevel > monsterNameDeck.length ? monsterNameDeck.length : mapLevel;
				name = monsterNameDeck[Map.random.rangeInt(nameRange)];
			}
			return <character characterNum={(Character.characterNumCount++)} name={name} type={characterType} level={level} />;
		}
		
		/* Create a random elite mob */
		public static function createEliteXML(mapLevel:int, eliteNames:Object):XML{
			var name:int;
			var level:int = mapLevel - 2;
			var effectXML:XML;
			if(level < -1) level = 0;
			// monsters become harder when ascended
			if(UserData.settings.ascended) level++;
			// pick a random race, do not pick the same race twice
			do{
				name = monsterNameDeck[Map.random.rangeInt(monsterNameDeck.length)];
			} while(eliteNames[name]);
			eliteNames[name] = true;
			var xml:XML =<character characterNum={(Character.characterNumCount++)} name={name} type={Character.MONSTER} level={level} rank={Character.ELITE} />;
			
			// generate some powerful items
			var weaponXML:XML = createItemXML(mapLevel, Item.WEAPON);
			level = weaponXML.@level;
			level += 1 + Map.random.rangeInt(3);
			if(level > Game.MAX_LEVEL) level = Game.MAX_LEVEL;
			weaponXML.@level = level;
			// the elite orc (Lurtz) always has a bow
			if(name == Character.ORC){
				weaponXML.@name = [Item.SHORT_BOW, Item.LONG_BOW, Item.ARBALEST][Map.random.rangeInt(3)];
			// the elite rakshasa (Baihu) always has a blessed weapon
			} else if(name == Character.RAKSHASA){
				weaponXML.@holyState = Item.BLESSED;
			}
			
			var armourXML:XML = createItemXML(mapLevel, Item.ARMOUR);
			level = weaponXML.@level;
			level += 1 + Map.random.rangeInt(3);
			if(level > Game.MAX_LEVEL) level = Game.MAX_LEVEL;
			armourXML.@level = level;
			// the elite gnoll (Anubis) always has undead enchanted armour
			if(name == Character.GNOLL){
				effectXML = <effect name={Effect.UNDEAD} level={1 + Map.random.rangeInt(3)} />;
				armourXML.appendChild(effectXML);
			}
			
			xml.appendChild(weaponXML);
			xml.appendChild(armourXML);
			
			return xml;
		}
		
		/* Create xml for The Balrog */
		public static function createBalrogXML():XML{
			var xml:XML =<character characterNum={-1} name={Character.BALROG} type={Character.MONSTER} level={1} rank={Character.ELITE} levelState={Balrog.STAIRS_DOWN_TAUNT} />;
			var yendorXML:XML =<item name={Item.YENDOR} type={Item.ARMOUR} level={Game.MAX_LEVEL} />;
			xml.appendChild(yendorXML);
			var weaponXML:XML = createItemXML(UserData.gameState.balrog.mapLevel, Item.WEAPON);
			xml.appendChild(weaponXML);
			return xml;
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
			
			// naturally occurring cursed and blessed items appear sewers zone+, at the point you can do something about them
			if((type == Item.ARMOUR || type == Item.WEAPON) && mapLevel >= sewersFirstLevel){
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
		public static function XMLToEntity(x:int, y:int, xml:XML, mapLevel:int = 0, mapType:int = 0):*{
			var objectType:String = xml.name();
			var i:int, children:XMLList, item:XML, mc:DisplayObject, obj:*;
			var name:int, level:int, type:int, rank:int;
			var className:Class;
			var items:Vector.<Item>;
			if(objectType == "chest"){
				children = xml.children();
				items = new Vector.<Item>();
				for each(item in children){
					items.push(XMLToEntity(x, y, item));
				}
				if(items.length == 0) items = null;
				mc = (mapType == Map.AREA && mapLevel == Map.OVERWORLD) ? new ChestColMC() : new ChestMC();
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
				if(xml.hasOwnProperty("@uniqueNameStr") && xml.@uniqueNameStr != "null" && xml.@uniqueNameStr != ""){
					obj.uniqueNameStr = xml.@uniqueNameStr;
				}
				
			} else if(objectType == "character"){
				name = xml.@name;
				level = xml.@level;
				type = xml.@type;
				rank = xml.@rank;
				if(xml.item.length()){
					items = new Vector.<Item>();
					for each(item in xml.item){
						items.push(XMLToEntity(x, y, item));
					}
				}
				if(type == Character.MONSTER){
					mc = game.library.getCharacterGfx(name);
					if(name == Character.BALROG){
						obj = new Balrog(mc, items, int(xml.@levelState));
					} else {
						obj = new Monster(mc, (x + 0.5) * Game.SCALE, (y + 1) * Game.SCALE, name, level, items, rank);
					}
					obj.characterNum = xml.@characterNum;
					// does it have a name?
					if(xml.hasOwnProperty("@uniqueNameStr") && xml.@uniqueNameStr != "null" && xml.@uniqueNameStr != ""){
						obj.uniqueNameStr = xml.@uniqueNameStr;
					}
					if(xml.@questVictim == "true") obj.questTarget();
				}
				
			} else if(objectType == "portal"){
				mc = Portal.getPortalGfx(int(xml.@type), x, y, int(xml.@targetLevel), int(xml.@targetType), mapLevel, mapType)
				mc.x = x * Game.SCALE;
				mc.y = y * Game.SCALE;
				obj = new Portal(mc, new Rectangle(x * Game.SCALE, y * Game.SCALE, Game.SCALE, Game.SCALE), xml.@type, xml.@targetLevel, xml.@targetType, Portal.OPEN, false);
				obj.mapX = x;
				obj.mapY = y;
				if(Map.isPortalToPreviousLevel(x, y, xml.@type, xml.@targetLevel, xml.@targetType)) game.entrance = obj;
				
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