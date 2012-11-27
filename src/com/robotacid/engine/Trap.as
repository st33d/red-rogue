package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.gfx.BlitClip;
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
		public var xpReward:Number;
		
		public var disarmingRect:Rectangle;
		public var disarmingContact:Boolean;
		
		private var effectName:int;
		private var pitCoverCount:int;
		private var gasRect:Rectangle;
		private var gasCount:int;
		private var minimapFX:MinimapFX;
		private var targets:Vector.<Effect>;
		private var mushroomPoints:Vector.<Point>;
		private var mushroomFrames:Vector.<int>;
		
		
		// type flags
		public static const PIT:int = 0;
		public static const TELEPORT_DART:int = 1;
		public static const STUN_MUSHROOM:int = 2;
		public static const BLEED_DART:int = 3;
		public static const CONFUSION_MUSHROOM:int = 4;
		public static const FEAR_MUSHROOM:int = 5;
		public static const MONSTER_PORTAL:int = 6;
		public static const HEAL_MUSHROOM:int = 7;
		
		public static const PIT_COVER_DELAY:int = 7;
		public static const GAS_DELAY:Number = 60;
		public static const DISARM_XP_REWARD:Number = 1 / 30;
		public static const MUSHROOMS_WIDTH:Number = SCALE * 1.5;
		public static const MUSHROOMS_HEIGHT:Number = SCALE;
		
		public function Trap(gfx:DisplayObject, mapX:int, mapY:int, type:int, dartPos:Pixel = null) {
			super(gfx, false, false);
			this.mapX = mapX;
			this.mapY = mapY;
			mapZ = MapTileManager.ENTITY_LAYER;
			this.type = type;
			revealed = false;
			var sprite:Sprite = gfx as Sprite;
			if(type == PIT){
				rect = new Rectangle(mapX * Game.SCALE, -1 + mapY * Game.SCALE, SCALE, SCALE);
			} else if(
				type == TELEPORT_DART ||
				type == BLEED_DART ||
				type == MONSTER_PORTAL
			){
				if(type == TELEPORT_DART) effectName = Effect.TELEPORT;
				else if(type == TELEPORT_DART) effectName = Effect.BLEED;
				rect = new Rectangle(mapX * Game.SCALE, -1 + mapY * Game.SCALE, SCALE, 1);
				if(dartPos){
					dartGun = new Point((dartPos.x + 0.5) * Game.SCALE, (dartPos.y + 1) * Game.SCALE);
					var dartTrapGfx:DisplayObject = new DartTrapMC();
					dartTrapGfx.x = -gfx.x + dartGun.x - 0.5 * Game.SCALE;
					dartTrapGfx.y = -gfx.y + dartGun.y;
					sprite.addChild(dartTrapGfx);
				}
			} else if(
				type == CONFUSION_MUSHROOM ||
				type == FEAR_MUSHROOM ||
				type == STUN_MUSHROOM ||
				type == HEAL_MUSHROOM
			){
				if(type == CONFUSION_MUSHROOM) effectName = Effect.CONFUSION;
				else if(type == FEAR_MUSHROOM) effectName = Effect.FEAR;
				else if(type == STUN_MUSHROOM) effectName = Effect.STUN;
				else if(type == HEAL_MUSHROOM) effectName = Effect.HEAL;
				rect = new Rectangle((mapX - 1) * Game.SCALE, -1 + (mapY * Game.SCALE), SCALE * 3, 1);
				gasRect = new Rectangle(mapX * Game.SCALE, (mapY - 1) * Game.SCALE, SCALE, SCALE);
				targets = new Vector.<Effect>();
				mushroomPoints = new Vector.<Point>();
				mushroomFrames = new Vector.<int>();
				(gfx as Sprite).addChild(createMushroomGfx(mushroomPoints, mushroomFrames));
			}
			disarmingRect = new Rectangle((mapX - 1) * Game.SCALE, -1 + (mapY * Game.SCALE), SCALE * 3, 1);
			callMain = true;
			contact = false;
			disarmingContact = false;
			addToEntities = true;
			xpReward = 0;
		}
		
		override public function main():void {
			var i:int;
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
			
			// check for mushroom targets
			if(gasCount){
				gasCount--;
				renderer.addFX(gasRect.x + game.random.range(gasRect.width), gasRect.y + game.random.range(gasRect.width), renderer.redRingBlit, new Point( -1 + game.random.range(2), -1 + game.random.range(2)), game.random.rangeInt(3));
				checkGasTargets();
				if(gasCount == 0){
					// garbage collect target list
					if(targets && targets.length){
						var effect:Effect;
						for(i = targets.length - 1; i > -1; i--){
							effect = targets[i];
							if(!effect.active || !effect.target) targets.splice(i, 1);
						}
					}
				}
			}
			
			// disarm check - intersection check
			if(
				disarmingRect.x + disarmingRect.width > game.player.collider.x &&
				game.player.collider.x + game.player.collider.width > disarmingRect.x &&
				disarmingRect.y + disarmingRect.height > game.player.collider.y &&
				game.player.collider.y + game.player.collider.height > disarmingRect.y
			){
				if(!disarmingContact){
					disarmingContact = true;
					game.player.addDisarmableTrap(this);
				}
			} else if(disarmingContact){
				disarmingContact = false;
				game.player.removeDisarmableTrap(this);
			}
			
			// count down pit deletion
			if(pitCoverCount){
				pitCoverCount--;
				if(pitCoverCount == 0){
					if(type == PIT){
						active = false;
						game.world.map[mapY][mapX] = Collider.UP | Collider.LEDGE;
					}
				}
			}
		}
		
		/* Look for targets to hit with an effect */
		public function checkGasTargets():void{
			var i:int, j:int;
			var effect:Effect;
			var colliders:Vector.<Collider>;
			var character:Character;
			// check for new targets
			colliders = game.world.getCollidersIn(gasRect, null, Collider.PLAYER | Collider.MINION | Collider.MONSTER);
			for(i = 0; i < colliders.length; i++){
				character = colliders[i].userData as Character;
				if(
					character &&
					character.active &&
					!character.indifferent &&
					character.state == Character.WALKING
				){
					
					for(j = 0; j < targets.length; j++){
						effect = targets[j];
						if(effect.target == character) break;
					}
					if(j == targets.length){
						targets.push(new Effect(effectName, game.map.level < Game.MAX_LEVEL ? game.map.level : Game.MAX_LEVEL, Effect.THROWN, character));
						game.console.print(getName(type) + " gas touches " + character.nameToString());
					}
				}
			}
		}
		
		public function resolveCollision():void {
			
			game.console.print(getName(type) + " trap triggered");
			
			if(type == PIT){
				if(pitCoverCount) return;
				pitCoverCount = PIT_COVER_DELAY;
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
				if(--game.map.completionCount == 0) game.levelComplete();
				
			} else if(type == FEAR_MUSHROOM || type == CONFUSION_MUSHROOM || type == STUN_MUSHROOM || type == HEAL_MUSHROOM){
				if(gasCount == 0) gasCount = GAS_DELAY;
				game.soundQueue.add("mushroom");
				
			} else if(type == BLEED_DART || type == TELEPORT_DART){
				shootDart(new Effect(effectName, game.map.level < Game.MAX_LEVEL ? game.map.level : Game.MAX_LEVEL, Effect.THROWN));
				
			} else if(type == MONSTER_PORTAL){
				var portal:Portal = Portal.createPortal(Portal.MONSTER, mapX, mapY - 1, game.map.level);
				portal.setCloneTemplate(Content.createCharacterXML(game.map.level < Game.MAX_LEVEL ? game.map.level : Game.MAX_LEVEL, Character.MONSTER));
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
			var sprite:Sprite = (gfx as Sprite);
			revealed = true;
			minimapFX = game.miniMap.addFeature(mapX, mapY, renderer.searchFeatureBlit, true);
			renderer.addFX(gfx.x, gfx.y - SCALE, renderer.trapRevealBlit);
			if(
				type == CONFUSION_MUSHROOM ||
				type == STUN_MUSHROOM ||
				type == FEAR_MUSHROOM ||
				type == HEAL_MUSHROOM
			){
				while(sprite.numChildren) sprite.removeChildAt(0);
				for(var i:int = 0; i < mushroomFrames.length; i++){
					mushroomFrames[i]++;
				}
				sprite.addChild(createMushroomGfx(mushroomPoints, mushroomFrames));
			} else {
				var trapRevealedGfx:MovieClip = new TrapMC();
				trapRevealedGfx.y = -SCALE;
				sprite.addChild(trapRevealedGfx);
			}
		}
		
		/* Destroys this object and gives xp */
		public function disarm():void{
			if(!active) return;
			active = false;
			if(minimapFX) {
				minimapFX.active = false;
				minimapFX = null;
			}
			if(game.player.disarmTrapCount == 0) game.player.addXP(DISARM_XP_REWARD * Content.getLevelXp(game.map.level) * (revealed ? 2 : 1));
			game.content.removeTrap(game.map.level, game.map.type);
			if(--game.map.completionCount == 0) game.levelComplete();
			renderer.createDebrisRect(new Rectangle(mapX * SCALE, -6 + mapY * SCALE, SCALE, 6), 0, 20, Renderer.STONE);
			if(
				type == CONFUSION_MUSHROOM ||
				type == STUN_MUSHROOM ||
				type == FEAR_MUSHROOM ||
				type == HEAL_MUSHROOM
			){
				// mutilate gasRect for rendering
				gasRect.y += SCALE * 0.5;
				gasRect.height = SCALE * 0.5;
				renderer.createDebrisRect(gasRect, 0, 10, Renderer.BLOOD);
				
			} else if(type == BLEED_DART || type == TELEPORT_DART){
				renderer.createDebrisRect(new Rectangle(dartGun.x - 2, dartGun.y, 4, 2), 0, 10, Renderer.STONE);
			}
			game.mapTileManager.removeTile(this, mapX, mapY, mapZ);
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
			else if(type == STUN_MUSHROOM) return "stun";
			else if(type == BLEED_DART) return "bleed";
			else if(type == CONFUSION_MUSHROOM) return "confusion";
			else if(type == FEAR_MUSHROOM) return "fear";
			else if(type == MONSTER_PORTAL) return "monster";
			return "";
		}
		
		/* Assemble a mushroom graphic based on input */
		public function createMushroomGfx(points:Vector.<Point>, frames:Vector.<int>):Bitmap{
			var point:Point;
			var bitmapData:BitmapData = new BitmapData(MUSHROOMS_WIDTH, MUSHROOMS_HEIGHT, true, 0x0);
			
			// check if points are initialised
			if(points.length == 0){
				var x:int, y:int;
				var frame:int;
				var num:int = 2 + game.random.range(2);
				while(num--){
					frame = game.random.rangeInt(3) * 2;
					x = 8 + game.random.range(MUSHROOMS_WIDTH - 16);
					y = game.random.range(4) + SCALE;
					frames.push(frame);
					points.push(new Point(x, y));
				}
			}
			
			// render to a bitmap
			for(var i:int = 0; i < points.length; i++){
				point = points[i];
				renderer.mushroomBlit.x = point.x;
				renderer.mushroomBlit.y = point.y;
				renderer.mushroomBlit.render(bitmapData, frames[i]);
			}
			var bitmap:Bitmap = new Bitmap(bitmapData);
			bitmap.x = -SCALE * 0.25;
			bitmap.y = -SCALE;
			return bitmap;
		}
		
	}
	
}