package com.robotacid.ui.menu {
	import com.robotacid.engine.Character;
	import com.robotacid.level.Content;
	/**
	 * Describes a quest the player is currently undertaking
	 * 
	 * Quests are of the order type > subject
	 * 
	 * As of writing there is only gem collection quests, kill X quests and the macguffin quest
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class QuestMenuOption extends MenuOption {
		
		public static var game:Game;
		
		public var type:int;
		public var num:int;
		public var commissioner:String;
		public var xpReward:Number;
		
		public static const XP_REWARD:Number = 1 / 15;
		
		// quest types - a type of 0 is given when constructing from xml
		public static const COLLECT:int = 1;
		public static const KILL:int = 2;
		public static const MACGUFFIN:int = 3;
		
		public function QuestMenuOption(type:int = 0, commissioner:String = "", subject:Character = null) {
			this.type = type;
			this.commissioner = commissioner;
			if(type == COLLECT){
				num = 3 + game.random.rangeInt(3);
				name = "collect " + num + " gems";
				xpReward = Content.getLevelXp(game.map.level) * XP_REWARD;
				
			} else if(type == KILL){
				name = "kill " + subject.nameToString();
				num = subject.characterNum;
				subject.questTarget();
				xpReward = subject.xpReward;
				
			} else if(type == MACGUFFIN){
				name = "get the amulet of yendor";
				xpReward = 0;
			}
			super(name, null, false);
		}
		
		public function collect():void{
			num--;
			name = "collect " + num + " gems";
		}
		
		public function toXML():XML{
			return <quest name={name} type={type} num={num} commissioner={commissioner} xpReward={xpReward} />;
		}
		
		public static function fromXML(xml:XML):QuestMenuOption{
			var option:QuestMenuOption = new QuestMenuOption();
			option.name = xml.@name;
			option.type = xml.@type;
			option.num = xml.@num;
			option.commissioner = xml.@commissioner;
			option.xpReward = Number(xml.@xpReward);
			return option;
		}
		
	}

}