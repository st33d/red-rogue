package  {
	import com.robotacid.engine.CharacterAttributes;
	import com.robotacid.gfx.BlitBackgroundClip;
	import com.robotacid.gfx.BloodClip;
	
	/**
	 * Here's where I'm sticking all of the imported assets.
	 *
	 * All in one place as opposed to all over the fucking shop.
	 *
	 * @author steed
	 */
	public class Library {
		
		[Embed(source = "assets/banner.png")] public var BannerB:Class;
		
		[Embed(source = "assets/assets.swf", symbol = "PlayerMC")] public var PlayerMC:Class;
		
		[Embed(source = "assets/assets.swf", symbol = "JumpSound")] public var JumpSound:Class;
		[Embed(source = "assets/assets.swf", symbol = "StepsSound")] public var StepsSound:Class;
		[Embed(source = "assets/assets.swf", symbol = "RogueDeathSound")] public var RogueDeathSound:Class;
		[Embed(source = "assets/assets.swf", symbol = "MissSound")] public var MissSound:Class;
		[Embed(source = "assets/assets.swf", symbol = "KillSound")] public var KillSound:Class;
		[Embed(source = "assets/assets.swf", symbol = "ThudSound")] public var ThudSound:Class;
		[Embed(source = "assets/assets.swf", symbol = "BowShootSound")] public var BowShootSound:Class;
		[Embed(source = "assets/assets.swf", symbol = "ThrowSound")] public var ThrowSound:Class;
		[Embed(source = "assets/assets.swf", symbol = "ChestOpenSound")] public var ChestOpenSound:Class;
		[Embed(source = "assets/assets.swf", symbol = "RuneHitSound")] public var RuneHitSound:Class;
		[Embed(source = "assets/assets.swf", symbol = "TeleportSound")] public var TeleportSound:Class;
		
		[Embed(source = "assets/assets.swf", symbol = "HitSound")] public var HitSound:Class;
		[Embed(source = "assets/background/backwall1.png")] public var BackB1:Class;
		[Embed(source = "assets/background/backwall2.png")] public var BackB2:Class;
		[Embed(source = "assets/background/backwall3.png")] public var BackB3:Class;
		[Embed(source = "assets/background/backwall4.png")] public var BackB4:Class;
		[Embed(source = "assets/midground/ladder_top.png")] public var LadderTopB:Class;
		[Embed(source = "assets/midground/ladder.png")] public var LadderB:Class;
		
		[Embed(source = "assets/midground/ledge.png")] public var LedgeB:Class;
		[Embed(source = "assets/midground/ledge_middle.png")] public var LedgeMiddleB:Class;
		[Embed(source = "assets/midground/ledge_start_right.png")] public var LedgeStartRightB:Class;
		[Embed(source = "assets/midground/ledge_start_left.png")] public var LedgeStartLeftB:Class;
		[Embed(source = "assets/midground/ledge_single.png")] public var LedgeSingleB:Class;
		[Embed(source = "assets/midground/ledge_end_right.png")] public var LedgeEndRightB:Class;
		[Embed(source = "assets/midground/ledge_end_left.png")] public var LedgeEndLeftB:Class;
		[Embed(source = "assets/midground/ledge_start_right_end.png")] public var LedgeStartRightEndB:Class;
		[Embed(source = "assets/midground/ledge_start_left_end.png")] public var LedgeStartLeftEndB:Class;
		
		[Embed(source = "assets/midground/stairs_down.png")] public var StairsDownB:Class;
		[Embed(source = "assets/midground/stairs_up.png")] public var StairsUpB:Class;
		[Embed(source = "assets/midground/stairs_mask.png")] public var StairsMaskB:Class;
		
		[Embed(source = "assets/assets.swf", symbol = "SkeletonMC")] public var SkeletonMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "KoboldMC")] public var KoboldMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "GoblinMC")] public var GoblinMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "OrcMC")] public var OrcMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "TrollMC")] public var TrollMC:Class;
		
		[Embed(source = "assets/assets.swf", symbol = "RatMC")] public var RatMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "SpiderMC")] public var SpiderMC:Class;
		
		[Embed(source = "assets/assets.swf", symbol = "DartMC")] public var DartMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "ArrowMC")] public var ArrowMC:Class;
		
		[Embed(source = "assets/assets.swf", symbol = "BowMC")] public var BowMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "ChestMC")] public var ChestMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "DaggerMC")] public var DaggerMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "HammerMC")] public var HammerMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "MaceMC")] public var MaceMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "StaffMC")] public var StaffMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "SwordMC")] public var SwordMC:Class;
		
		[Embed(source = "assets/assets.swf", symbol = "RuneMC")] public var RuneMC:Class;
		
		[Embed(source = "assets/assets.swf", symbol = "ThrownRuneMC")] public var ThrownRuneMC:Class;
		
		[Embed(source = "assets/assets.swf", symbol = "HeartMC")] public var HeartMC:Class;
		
		[Embed(source = "assets/assets.swf", symbol = "TwinkleMC")] public var TwinkleMC:Class;
		
		[Embed(source = "assets/assets.swf", symbol = "FliesMC")] public var FliesMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "FedoraMC")] public var FedoraMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "VikingHelmMC")] public var VikingHelmMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "SkullMC")] public var SkullMC:Class;
		
		[Embed(source = 'assets/trap_revealed.png')] public var TrapRevealedB:Class;
		
		
		public function armourNameToMCClass(n:int):Class{
			var list:Array = [FliesMC, FedoraMC, VikingHelmMC, SkullMC, BloodClip, BlitBackgroundClip];
			return list[n];
		}
		public function weaponNameToMCClass(n:int):Class{
			var list:Array = [DaggerMC, MaceMC, SwordMC, StaffMC, BowMC, HammerMC];
			return list[n];
		}
		public function characterNameToMcClass(n:int):Class{
			var list:Array = CharacterAttributes.NAME_SKINS;
			return list[n];
		}
	}
	
}