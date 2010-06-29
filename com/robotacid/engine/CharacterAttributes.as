package com.robotacid.engine {
	/**
	 * The amount of constants for every type and name of character was too much to pack
	 * into the Character class, so it seemed easier to monitor in its own class.
	 * 
	 * I guess idealy I should be importing all this data from an xml file at compile
	 * time. It would look nicer, but I would have to do the same for items, and then
	 * I may get further carried away. It's a job for when managing this class file gets
	 * out of hand.
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class CharacterAttributes{
		
		public static const NAME_STRINGS:Array = [
			"rogue",
			"skeleton",
			"goblin",
			"orc"
		];
		
		public static const NAME_ATTACKS:Array = [
			0.3,
			0.15,
			0.15,
			0.2
		];
		
		public static const NAME_ATTACK_LEVELS:Array = [
			0.05,
			0.06,
			0.06,
			0.03
		];
		
		public static const NAME_DEFENCES:Array = [
			0.2,
			0.1,
			0.1,
			0.2
		];
		
		public static const NAME_DEFENCE_LEVELS:Array = [
			0.05,
			0.03,
			0.04,
			0.06
		];
		
		public static const NAME_HEALTHS:Array = [
			3,
			2.5,
			1.5,
			3.5
		];
		
		public static const NAME_HEALTH_LEVELS:Array = [
			1,
			0.5,
			0.75,
			1.1
		];
		
		public static const NAME_DAMAGES:Array = [
			1,
			0.6,
			0.5,
			1.1
		];
		
		public static const NAME_DAMAGE_LEVELS:Array = [
			0.2,
			0.1,
			0.08,
			0.25
		];
		
		public static const NAME_ATTACK_SPEEDS:Array = [
			0.05,
			0.055,
			0.06,
			0.03
		];
		
		public static const NAME_ATTACK_SPEED_LEVELS:Array = [
			0.002,
			0.002,
			0.003,
			0.001
		];
		
		public static const NAME_SPEEDS:Array = [
			2.5,
			2.5,
			3,
			2
		];
		
		public static const NAME_SPEED_LEVELS:Array = [
			0.03,
			0.03,
			0.04,
			0.02
		];
		
		public static const NAME_DEATH_STRINGS:Array = [
			"finished",
			"smashed",
			"killed",
			"beat"
		];
		
		public static const NAME_XP_REWARDS:Array = [
			2,
			1,
			1,
			2
		];
		
		public static const NAME_XP_REWARD_LEVELS:Array = [
			0.5,
			0.3,
			0.4,
			0.6
		];
		
		public static const NAME_PAUSES:Array = [
			20,
			20,
			30,
			60
		];
		
		public static const NAME_SKINS:Array = [
			Game.g.library.PlayerMC,
			Game.g.library.SkeletonMC,
			Game.g.library.GoblinMC,
			Game.g.library.OrcMC
		];
		
	}

}