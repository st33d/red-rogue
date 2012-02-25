package com.robotacid.ui.menu {
	import com.robotacid.ai.Brain;
	import com.robotacid.dungeon.Map;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Item;
	import com.robotacid.ui.Dialog;
	/**
	 * Lists and manages the quests the player is currently persuing.
	 * 
	 * There are two types of quest: COLLECT and KILL
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class QuestMenuList extends MenuList {
		
		public static var game:Game;
		
		private var menu:Menu;
		
		public function QuestMenuList(menu:Menu) {
			super(Vector.<MenuOption>([
				new QuestMenuOption(QuestMenuOption.MACGUFFIN)
			]));
			this.menu = menu;
		}
		
		public function createQuest():void{
			var i:int, subject:Character, targets:Vector.<Character>, option:QuestMenuOption;
			var type:int = game.random.value() < 0.5 ? QuestMenuOption.COLLECT : QuestMenuOption.KILL;
			if(type == QuestMenuOption.KILL){
				
				targets = new Vector.<Character>();
				
				// scrape the level for inactive monsters
				var r:int, c:int, tile:*, character:Character;
				for(r = 0; r < game.mapTileManager.height; r++){
					for(c = 0; c < game.mapTileManager.width; c++){
						tile = game.mapTileManager.mapLayers[Map.ENTITIES][r][c];
						if(tile){
							if(tile is Array){
								for(i = 0; i < tile.length; i++){
									if(tile[i] is Character){
										character = tile[i] as Character;
										if(
											character &&
											!character.questVictim &&
											character.brain &&
											character.brain.allegiance != Brain.PLAYER
										) targets.push(character);
									}
								}
							} else if(tile is Character){
								character = tile as Character;
								if(
									character &&
									!character.questVictim &&
									character.brain &&
									character.brain.allegiance != Brain.PLAYER
								) targets.push(character);
							}
						}
					}
				}
				// if we failed to get any, scrape the active monsters list
				if(targets.length == 0){
					for(i = 0; i < game.entities.length; i++){
						character = game.entities[i] as Character;
						if(
							character &&
							!character.questVictim &&
							character.brain &&
							character.brain.allegiance != Brain.PLAYER
						) targets.push(character);
					}
				}
				// if the level is empty of monsters, change the quest to a COLLECT
				if(targets.length == 0){
					type = QuestMenuOption.COLLECT;
				} else {
					subject = targets[game.random.rangeInt(targets.length)];
					option = new QuestMenuOption(type, subject);
					options.push(option);
				}
			}
			// quests need to fallback to COLLECT quests - do not refactor to else-if
			if(type == QuestMenuOption.COLLECT){
				game.dungeon.completionCount += option.num;
				game.dungeon.completionTotal += option.num;
				option = new QuestMenuOption(type);
				options.push(option);
				game.content.dropQuestGems(option.num, game.mapTileManager.mapLayers, game.dungeon.bitmap, true);
			}
			if(!Game.dialog){
				Game.dialog = new Dialog(
					"new quest",
					"@ has issued you a new quest.\n" + option.name
				);
			}
		}
		
		/* Queries the list of quests and tries to find a match for the conditions submitted */
		public function questCheck(type:int, subject:Character = null):void{
			var i:int = options.length, option:QuestMenuOption;
			if(type == QuestMenuOption.COLLECT){
				while(i--){
					option = options[i] as QuestMenuOption;
					if(option.type == QuestMenuOption.COLLECT){
						option.collect();
						if(--game.dungeon.completionCount == 0) game.levelCompleteMsg();
						if(option.num == 0){
							options.splice(i, 1);
							questComplete(option);
						}
						break;
					}
				}
			} else if(type == QuestMenuOption.KILL){
				while(i--){
					option = options[i] as QuestMenuOption;
					if(option.type == QuestMenuOption.KILL){
						if(option.num == subject.characterNum){
							options.splice(i, 1);
							questComplete(option);
							break;
						}
					}
				}
			}
			menu.update();
		}
		
		/* Reports the completion of a quest and gives the player the experience reward */
		public function questComplete(option:QuestMenuOption):void{
			var str:String;
			if(option.type == QuestMenuOption.COLLECT){
				str = "collect quest completed";
			} else if(option.type == QuestMenuOption.KILL){
				str = "kill quest completed";
			}
			game.console.print(str);
			game.player.addXP(option.xpReward);
			if(!Game.dialog){
				Game.dialog = new Dialog(
					"quest complete",
					str + "\n@'s love for you is justified"
				);
			}
		}
		
		/* Called when the target of a quest is polymorphed */
		public function updateName(character:Character):void{
			var option:QuestMenuOption;
			for(var i:int = 0; i < options.length; i++){
				option = options[i] as QuestMenuOption;
				if(option.num == character.characterNum){
					option.name = "kill " + character.nameToString();
					break;
				}
			}
			menu.update();
		}
		
		public function reset():void{
			options = Vector.<MenuOption>([options[0]]);
		}
		
	}

}