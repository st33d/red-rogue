package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.level.Content;
	import com.robotacid.level.Map;
	import com.robotacid.geom.Pixel;
	import com.robotacid.gfx.BlitSprite;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.MinimapFX;
	import com.robotacid.util.HiddenInt;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Various entities that will attack the player when triggered
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Trap extends Entity{
		
		public var rect:Rectangle;
		public var type:int;
		public var contact:Boolean;
		public var revealed:Boolean;
		public var dartGun:Point;
		public var count:int;
		public var xpReward:Number;
		
		public var disarmingRect:Rectangle;
		public var disarmingContact:Boolean;
		
		private var minimapFX:MinimapFX;
		
		// type flags
		public static const PIT:int = 0;
		public static const POISON_DART:int = 1;
		public static const TELEPORT_DART:int = 2;
		public static const STUN_DART:int = 3;
		public static const MONSTER_PORTAL:int = 4;
		public static const CONFUSION_DART:int = 5;
		public static const FEAR_DART:int = 6;
		
		public static const PIT_COVER_DELAY:int = 7;
		public static const DISARM_XP_REWARD:Number = 1 / 30;
		
		public function Trap(gfx:DisplayObject, mapX:int, mapY:int, type:int, dartPos:Pixel = null) {
			super(gfx, false, false);
			this.type = type;
			revealed = false;
			if(type == PIT){
				rect = new Rectangle(mapX * Game.SCALE, -1 + mapY * Game.SCALE, SCALE, SCALE);
			} else {
				rect = new Rectangle(mapX * Game.SCALE, -1 + mapY * Game.SCALE, SCALE, 5);
				if(dartPos){
					dartGun = new Point((dartPos.x + 0.5) * Game.SCALE, (dartPos.y + 1) * Game.SCALE);
				}
			}
			disarmingRect = new Rectangle((mapX - 1) * Game.SCALE, -1 + (mapY * Game.SCALE), SCALE * 3, 5);
			callMain = true;
			contact = false;
			disarmingContact = false;
			addToEntities = true;
			xpReward = 0;
		}
		
		override public function main():void {
			//Game.debug.drawRect(rect.x, rect.y, rect.width, rect.height);
			// check the player is fully on the trap before springing it
			if(
				game.player.collider.x >= rect.x &&
				game.player.collider.x + game.player.collider.width <= rect.x + rect.width &&
				game.player.collider.y < rect.y + rect.height &&
				game.player.collider.y + game.player.collider.height > rect.y &&
				!game.player.indifferent
			){
				if(!contact){
					contact = true;
					resolveCollision();
				}
			} else if(contact){
				contact = false;
			}
			if(revealed && disarmingRect.intersects(game.player.collider)){
				if(!disarmingContact){
					disarmingContact = true;
					game.player.addDisarmableTrap(this);
				}
			} else if(disarmingContact){
				disarmingContact = false;
				game.player.removeDisarmableTrap(this);
			}
			if(count){
				count--;
				if(count == 0){
					if(type == PIT){
						active = false;
						game.world.map[mapY][mapX] = Collider.UP | Collider.LEDGE;
					}
				}
			}
		}
		
		public function resolveCollision():void {
			
			game.console.print(getName(type) + " trap triggered");
			
			if(type == PIT){
				if(count) return;
				count = PIT_COVER_DELAY;
				renderer.createDebrisRect(rect, 0, 100, Renderer.STONE);
				renderer.shake(0, 3);
				game.soundQueue.addRandom("pitTrap", Stone.DEATH_SOUNDS);
				game.world.removeMapPosition(mapX, mapY);
				game.mapTileManager.removeTile(this, mapX, mapY, mapZ);
				renderer.blockBitmapData.fillRect(new Rectangle(mapX * SCALE, mapY * SCALE, SCALE, SCALE), 0x0);
				var blit:BlitSprite = MapTileConverter.ID_TO_GRAPHIC[MapTileConverter.LEDGE_SINGLE];
				blit.x = mapX * SCALE;
				blit.y = mapY * SCALE;
				blit.render(renderer.blockBitmapData);
				// check to see if any colliders are on this and drop them
				var dropped:Vector.<Collider> = game.world.getCollidersIn(rect);
				var dropCollider:Collider;
				for(var i:int = 0; i < dropped.length; i++){
					dropCollider = dropped[i];
					dropCollider.divorce();
				}
				// make sure the player can't disarm a trap that no longer exists
				if(game.player.disarmableTraps.indexOf(this) > -1){
					game.player.removeDisarmableTrap(this);
				}
				disarmingRect = new Rectangle(0, 0, 1, 1);
				// the map graph is currently unaware of a new route
				// we need to educate it by looking down from the node that must be above the
				// pit to the node that must be below it
				var r:int;
				for(r = mapY; r < game.map.height; r++){
					if(Brain.mapGraph.nodes[r][mapX]){
						Brain.mapGraph.nodes[mapY - 1][mapX].connections.push(Brain.mapGraph.nodes[r][mapX]);
						break;
					}
				}
				// the wall walk graph needs connecting separately - its nodes are different
				for(r = mapY; r < game.map.height; r++){
					if(Brain.walkWalkGraph.nodes[r][mapX]){
						Brain.walkWalkGraph.nodes[mapY - 1][mapX].connections.push(Brain.walkWalkGraph.nodes[r][mapX]);
						break;
					}
				}
				if(!minimapFX) game.miniMap.addFX(mapX, mapY, renderer.featureRevealedBlit);
				else{
					minimapFX.active = false;
					minimapFX = null;
				}
				if(--game.map.completionCount == 0) game.levelCompleteMsg();
				
			} else if(type == POISON_DART){
				shootDart(new Effect(Effect.POISON, game.map.level < Game.MAX_LEVEL ? game.map.level : Game.MAX_LEVEL, Effect.THROWN));
			} else if(type == STUN_DART){
				shootDart(new Effect(Effect.STUN, game.map.level < Game.MAX_LEVEL ? game.map.level : Game.MAX_LEVEL, Effect.THROWN));
			} else if(type == TELEPORT_DART){
				shootDart(new Effect(Effect.TELEPORT, Game.MAX_LEVEL, Effect.THROWN));
				
			} else if(type == CONFUSION_DART){
				shootDart(new Effect(Effect.CONFUSION, game.map.level < Game.MAX_LEVEL ? game.map.level : Game.MAX_LEVEL, Effect.THROWN));
				
			} else if(type == FEAR_DART){
				shootDart(new Effect(Effect.FEAR, game.map.level < Game.MAX_LEVEL ? game.map.level : Game.MAX_LEVEL, Effect.THROWN));
				
			} else if(type == MONSTER_PORTAL){
				var portal:Portal = Portal.createPortal(Portal.MONSTER, mapX, mapY - 1, game.map.level);
				portal.setMonsterTemplate(Content.createCharacterXML(game.map.level < Game.MAX_LEVEL ? game.map.level : Game.MAX_LEVEL, Character.MONSTER));
				// monster portal traps are triggered once and then destroy themselves
				active = false;
				if(!minimapFX) game.miniMap.addFX(mapX, mapY, renderer.featureRevealedBlit);
				else{
					minimapFX.active = false;
					minimapFX = null;
				}
				return;
			}
			// a trap that still exists after being triggered gets revealed
			if(!revealed && active && type != PIT){
				reveal();
			}
		}
		
		/* Adds a graphic to this trap to show the player where it is and adds a feature to the minimap */
		public function reveal():void{
			var trapRevealedGfx:MovieClip = new TrapMC();
			trapRevealedGfx.y = -SCALE;
			(gfx as Sprite).addChild(trapRevealedGfx);
			minimapFX = game.miniMap.addFeature(mapX, mapY, renderer.searchFeatureBlit, true);
			revealed = true;
			renderer.addFX(gfx.x, gfx.y - SCALE, renderer.trapRevealBlit);
		}
		
		/* Destroys this object and gives xp */
		public function disarm():void{
			if(!active) return;
			active = false;
			if(minimapFX) {
				minimapFX.active = false;
				minimapFX = null;
			}
			game.player.addXP(DISARM_XP_REWARD * Content.getLevelXp(game.map.level));
			game.content.removeTrap(game.map.level, game.map.type);
			if(--game.map.completionCount == 0) game.levelCompleteMsg();
		}
		
		/* Launches a missile from the ceiling that bears a magic effect */
		public function shootDart(effect:Effect):void{
			game.soundQueue.add("throw");
			var missileMc:DisplayObject = new DartMC();
			var clipRect:Rectangle = new Rectangle(dartGun.x - Game.SCALE * 0.5, dartGun.y, Game.SCALE, (rect.y + 1) - dartGun.y);
			var missile:Missile = new Missile(missileMc, dartGun.x, dartGun.y, Missile.DART, null, 0, 1, 5, Collider.LADDER | Collider.LEDGE | Collider.HEAD | Collider.ITEM | Collider.CORPSE, effect, null, clipRect);
		}
		
		public static function getName(type:int):String{
			if(type == PIT) return "pit";
			else if(type == TELEPORT_DART) return "teleport";
			else if(type == STUN_DART) return "stun";
			else if(type == MONSTER_PORTAL) return "monster";
			else if(type == CONFUSION_DART) return "confusion";
			else if(type == FEAR_DART) return "fear";
			return "";
		}
		
	}
	
}