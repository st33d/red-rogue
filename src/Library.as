package {
	import com.robotacid.engine.Item;
	import com.robotacid.gfx.ItemMovieClip;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	/**
	 * Here's where I'm sticking all of the imported assets.
	 *
	 * All in one place as opposed to all over the fucking shop.
	 *
	 * @author steed
	 */
	public class Library {
		
		[Embed(source = "assets/banner.png")] public var BannerB:Class;
		
		[Embed(source = "assets/background/backwall1.png")] public var BackB1:Class;
		[Embed(source = "assets/background/backwall2.png")] public var BackB2:Class;
		[Embed(source = "assets/background/backwall3.png")] public var BackB3:Class;
		[Embed(source = "assets/background/backwall4.png")] public var BackB4:Class;
		
		[Embed(source = "assets/overworld.png")] public var OverworldB:Class;
		
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
		
		[Embed(source = 'assets/trap_revealed.png')] public var TrapRevealedB:Class;
		
		public const WEAPON_GFX_CLASSES:Array = [KnifeMC, ItemMovieClip, DaggerMC, MaceMC, ItemMovieClip, ItemMovieClip, SwordMC, ArbalestMC, SpearMC, ItemMovieClip, StaffMC, BombMC, ArquebusMC, HammerMC, ItemMovieClip, GunBladeMC, AxeMC, ChaosWandMC, LightningMC, ItemMovieClip];
		public const ARMOUR_GFX_CLASSES:Array = [FliesMC, ItemMovieClip, FedoraMC, TopHatMC, FirefliesMC, ItemMovieClip, BeesMC, VikingHelmMC, ItemMovieClip, ItemMovieClip, ItemMovieClip, ItemMovieClip, ItemMovieClip, WizardHatMC, ItemMovieClip, ItemMovieClip, KnivesMC, ItemMovieClip, Sprite, ItemMovieClip];
		public const CHARACTER_GFX_CLASSES:Array = [RogueMC, KoboldMC, GoblinMC, OrcMC, TrollMC, GnollMC, DrowMC, CactuarMC, NymphMC, VampireMC, WerewolfMC, RogueMC, NagaMC, MedusaMC, UmberHulkMC, GolemMC, BansheeMC, WraithMC, MindFlayerMC, RakshasaMC, BalrogMC, MinionMC];
		public const CHARACTER_HEAD_GFX_CLASSES:Array = [RogueHeadMC, KoboldHeadMC, GoblinHeadMC, OrcHeadMC, TrollHeadMC, GnollHeadMC, DrowHeadMC, CactuarHeadMC, NymphHeadMC, VampireHeadMC, WerewolfHeadMC, RogueHeadMC, NagaHeadMC, MedusaHeadMC, UmberHulkHeadMC, GolemHeadMC, BansheeHeadMC, WraithHeadMC, MindFlayerHeadMC, RakshasaHeadMC, BalrogHeadMC, MinionHeadMC];
		
		/* Return the graphics for a given item, some items use the ItemMovieClip to manage rendering */
		public function getItemGfx(name:int, type:int):DisplayObject{
			var c:Class;
			
			if(type == Item.ARMOUR){
				c = ARMOUR_GFX_CLASSES[name];
			} else if(type == Item.WEAPON){
				c = WEAPON_GFX_CLASSES[name];
			} else if(type == Item.HEART){
				return new HeartMC;
			} else if(type == Item.RUNE){
				return new RuneMC;
			}
			if(c == ItemMovieClip){
				return new c(name, type);
			} else {
				return new c;
			}
		}
		
		public function getCharacterGfx(n:int):MovieClip{
			return new CHARACTER_GFX_CLASSES[n];
		}
		public function getCharacterHeadGfx(n:int):DisplayObject{
			return new CHARACTER_HEAD_GFX_CLASSES[n];
		}
	}
}