package  {
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
		
		[Embed(source="assets/fff_Quadratis.ttf",fontFamily="FFF Quadratis")] public var font_name:String;
		[Embed(source = "assets/assets.swf", symbol = "PlayerMC")] public var PlayerMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "BackMC1")] public var BackMC1:Class;
		
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
		[Embed(source = "assets/foreground/pillar_bottom.png")] public var PillarBottomB:Class;
		[Embed(source = "assets/foreground/pillar_top.png")] public var PillarTopB:Class;
		[Embed(source = "assets/foreground/pillar_middle.png")] public var PillarMiddleB:Class;
		[Embed(source = "assets/background/backwall1.png")] public var BackB1:Class;
		[Embed(source = "assets/background/backwall2.png")] public var BackB2:Class;
		[Embed(source = "assets/background/backwall3.png")] public var BackB3:Class;
		[Embed(source = "assets/background/backwall4.png")] public var BackB4:Class;
		[Embed(source = "assets/midground/ladder_top.png")] public var LadderTopB:Class;
		[Embed(source = "assets/midground/ladder.png")] public var LadderMiddleB:Class;
		[Embed(source = "assets/midground/ledge_left.png")] public var LedgeLeftB:Class;
		[Embed(source = "assets/midground/ledge_middle.png")] public var LedgeMiddleB:Class;
		[Embed(source = "assets/midground/ledge_right.png")] public var LedgeRightB:Class;
		[Embed(source = "assets/midground/ledge_ladder.png")] public var LedgeLadderMiddleB:Class;
		[Embed(source = "assets/midground/wall.png")] public var WallB:Class;
		[Embed(source = "assets/midground/stairs_down.png")] public var StairsDownB:Class;
		[Embed(source = "assets/midground/stairs_up.png")] public var StairsUpB:Class;
		[Embed(source = "assets/midground/stairs_mask.png")] public var StairsMaskB:Class;
		
		
		[Embed(source = "assets/assets.swf", symbol = "SkeletonMC")] public var SkeletonMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "GoblinMC")] public var GoblinMC:Class;
		[Embed(source = "assets/assets.swf", symbol = "OrcMC")] public var OrcMC:Class;
		
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
		
		
		[Embed(source = 'assets/midground/walls/wall_bottom.png')] public var WallBottomB:Class;
		[Embed(source = 'assets/midground/walls/wall_bottom_left.png')] public var WallBottomLeftB:Class;
		[Embed(source = 'assets/midground/walls/wall_bottom_right.png')] public var WallBottomRightB:Class;
		[Embed(source = 'assets/midground/walls/wall_center.png')] public var WallCenterB:Class;
		[Embed(source = 'assets/midground/walls/wall_left.png')] public var WallLeftB:Class;
		[Embed(source = 'assets/midground/walls/wall_right.png')] public var WallRightB:Class;
		[Embed(source = 'assets/midground/walls/wall_top.png')] public var WallTopB:Class;
		[Embed(source = 'assets/midground/walls/wall_top_left.png')] public var WallTopLeftB:Class;
		[Embed(source = 'assets/midground/walls/wall_top_right.png')] public var WallTopRightB:Class;
		[Embed(source = 'assets/midground/walls/wall_top_bottom.png')] public var WallTopBottomB:Class;
		[Embed(source = 'assets/midground/walls/wall_left_right.png')] public var WallLeftRightB:Class;
		[Embed(source = 'assets/midground/walls/wall_top_right_bottom.png')] public var WallTopRightBottomB:Class;
		[Embed(source = 'assets/midground/walls/wall_right_bottom_left.png')] public var WallRightBottomLeftB:Class;
		[Embed(source = 'assets/midground/walls/wall_bottom_left_top.png')] public var WallBottomLeftTopB:Class;
		[Embed(source = 'assets/midground/walls/wall_left_top_right.png')] public var WallLeftTopRightB:Class;
		
		
		public function armourIndexToMCClass(n:int):Class{
			var list:Array = [FliesMC, FedoraMC, VikingHelmMC, SkullMC, BloodClip, BlitBackgroundClip];
			return list[n];
		}
		public function weaponIndexToMCClass(n:int):Class{
			var list:Array = [DaggerMC, MaceMC, SwordMC, StaffMC, BowMC, HammerMC];
			return list[n];
		}
	}
	
}