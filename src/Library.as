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
		[Embed(source = "assets/banner-fail.png")] public var BannerFailB:Class;
		[Embed(source = "assets/banner-complete.png")] public var BannerCompleteB:Class;
		
		[Embed(source = "assets/background/dungeon1.png")] public var BackB1:Class;
		[Embed(source = "assets/background/dungeon2.png")] public var BackB2:Class;
		[Embed(source = "assets/background/dungeon3.png")] public var BackB3:Class;
		[Embed(source = "assets/background/dungeon4.png")] public var BackB4:Class;
		[Embed(source = "assets/background/sewer1.png")] public var BackB5:Class;
		[Embed(source = "assets/background/sewer2.png")] public var BackB6:Class;
		[Embed(source = "assets/background/sewer3.png")] public var BackB7:Class;
		[Embed(source = "assets/background/sewer4.png")] public var BackB8:Class;
		[Embed(source = "assets/background/cave1.png")] public var BackB9:Class;
		[Embed(source = "assets/background/cave2.png")] public var BackB10:Class;
		[Embed(source = "assets/background/cave3.png")] public var BackB11:Class;
		[Embed(source = "assets/background/cave4.png")] public var BackB12:Class;
		
		[Embed(source = "assets/background/pipe1.png")] public var PipeB1:Class; // corner: right, down
		[Embed(source = "assets/background/pipe2.png")] public var PipeB2:Class; // horiz
		[Embed(source = "assets/background/pipe3.png")] public var PipeB3:Class; // cross
		[Embed(source = "assets/background/pipe4.png")] public var PipeB4:Class; // T: left, down, right
		[Embed(source = "assets/background/pipe5.png")] public var PipeB5:Class; // T: up, right, down
		[Embed(source = "assets/background/pipe6.png")] public var PipeB6:Class; // horiz
		[Embed(source = "assets/background/pipe7.png")] public var PipeB7:Class; // corner: left, up
		[Embed(source = "assets/background/pipe8.png")] public var PipeB8:Class; // vert
		[Embed(source = "assets/background/pipe9.png")] public var PipeB9:Class; // T: left, up, down
		[Embed(source = "assets/background/pipe10.png")] public var PipeB10:Class; // vert
		[Embed(source = "assets/background/pipe11.png")] public var PipeB11:Class; // T: right, up, left
		[Embed(source = "assets/background/pipe12.png")] public var PipeB12:Class; // corner: left, down
		[Embed(source = "assets/background/pipe13.png")] public var PipeB13:Class; // corner: up, right
		
		[Embed(source = "assets/overworld.png")] public var OverworldB:Class;
		[Embed(source = "assets/underworld.png")] public var UnderworldB:Class;
		
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
		
		[Embed(source = 'assets/mhp-small.png')] public var MHPB:Class;
		[Embed(source = 'assets/hp.png')] public var HPB:Class;
		[Embed(source = 'assets/act.png')] public var ACT:Class;
		
		[Embed(source = 'assets/wave.png')] public var WaveB:Class;
		
		[Embed(source = "assets/hurt-red.png")] public var HurtB:Class;
		
		public const WEAPON_GFX_CLASSES:Array = [KnifeMC, ItemMovieClip, DaggerMC, MaceMC, ItemMovieClip, ItemMovieClip, SwordMC, ArbalestMC, SpearMC, ItemMovieClip, StaffMC, BombMC, ArquebusMC, HammerMC, ItemMovieClip, GunBladeMC, ScytheMC, ChaosWandMC, LightningMC, ItemMovieClip, GunLeechMC, CogMC, FishbaneMC];
		public const ARMOUR_GFX_CLASSES:Array = [FliesMC, ItemMovieClip, FedoraMC, TopHatMC, FirefliesMC, ItemMovieClip, BeesMC, VikingHelmMC, ItemMovieClip, ItemMovieClip, ItemMovieClip, ItemMovieClip, WizardHatMC, ItemMovieClip, ItemMovieClip, KnivesMC, ItemMovieClip, ItemMovieClip, Sprite, ItemMovieClip, ItemMovieClip];
		public const CHARACTER_GFX_CLASSES:Array = [RogueMC, KoboldMC, GoblinMC, OrcMC, TrollMC, GnollMC, DrowMC, CactuarMC, NymphMC, VampireMC, WerewolfMC, MimicMC, NagaMC, GorgonMC, UmberHulkMC, GolemMC, BansheeMC, WraithMC, MindFlayerMC, RakshasaMC, BalrogMC, SkeletonMC, AtMC];
		public const CHARACTER_HEAD_GFX_CLASSES:Array = [RogueHeadMC, KoboldHeadMC, GoblinHeadMC, OrcHeadMC, TrollHeadMC, GnollHeadMC, DrowHeadMC, CactuarHeadMC, NymphHeadMC, VampireHeadMC, WerewolfHeadMC, MimicHeadMC, NagaHeadMC, MedusaHeadMC, UmberHulkHeadMC, GolemHeadMC, BansheeHeadMC, WraithHeadMC, MindFlayerHeadMC, RakshasaHeadMC, BalrogHeadMC, MinionHeadMC, AtHeadMC];
		
		/* Return the graphics for a given item, some items use the ItemMovieClip to manage rendering */
		public function getItemGfx(name:int, type:int, curseState:int = 0):DisplayObject{
			var c:Class;
			
			if(type == Item.ARMOUR){
				c = ARMOUR_GFX_CLASSES[name];
			} else if(type == Item.WEAPON){
				c = WEAPON_GFX_CLASSES[name];
			} else if(type == Item.HEART){
				return new HeartMC;
			} else if(type == Item.RUNE){
				return new RuneMC;
			} else if(type == Item.QUEST_GEM){
				return new QuestGemMC;
			} else if(type == Item.KEY){
				return new KeyMC;
			}
			if(c == ItemMovieClip){
				return new c(name, type, curseState);
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