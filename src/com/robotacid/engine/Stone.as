package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.level.Content;
	import com.robotacid.level.Map;
	import com.robotacid.engine.Character;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.MinimapFX;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * A wall that Characters can attack - either resulting in the wall being destroyed or other effects
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Stone extends Character{
		
		public var side:int;
		public var revealed:Boolean;
		
		private var minimapFeature:MinimapFX;
		private var hits:int;
		private var endGameEventData:Object;
		
		// names
		public static const SECRET_WALL:int = 0;
		public static const HEAL:int = 1;
		public static const GRIND:int = 2;
		public static const DEATH:int = 3;
		public static const LIGHT:int = 4;
		
		public static const SECRET_XP_REWARD:Number = 1 / 30;
		public static const GRIND_XP_RATE:Number = 0.5;
		public static const DEATH_HITS:int = 3;
		
		public static const HEAL_STONE_HIT_SOUNDS:Array = ["healStoneHit1", "healStoneHit2", "healStoneHit3", "healStoneHit4"];
		public static const DEATH_SOUNDS:Array = ["stoneDeath1", "stoneDeath2", "stoneDeath3", "stoneDeath4"];
		
		public static const NAME_HEALTHS:Array = [
			5,
			0,
			0
		];
		
		public function Stone(x:Number, y:Number, name:int, side:int = 0) {
			if(name == HEAL) gfx = new HeartFadeMC();
			else if(name == GRIND){
				gfx = new GrindWheelMC();
				(gfx as MovieClip).stop();
			} else if(name == DEATH){
				gfx = new DeathMC();
				state = WALKING;
				dir = 0;
				looking = RIGHT;
				hits = 0;
			} else {
				gfx = new MovieClip();
			}
			gfx.x = x;
			gfx.y = y;
			super(gfx, x, y, name, STONE, 0, false);
			this.side = side;
			health = NAME_HEALTHS[name];
			defence = 0;
			callMain = false;
			if(name == HEAL) debrisType = Renderer.BLOOD;
			else debrisType = Renderer.STONE;
			free = false;
			addToEntities = true;
			if(name == SECRET_WALL){
				revealed = false;
				// the 1px edge the collider needs to be attackable can be stood upon unless the vertical
				// surfaces are turned off
				collider.properties &= ~(UP | DOWN);
				gfx.visible = false;
			} else {
				revealed = true;
				if(name == HEAL || name == GRIND) game.entities.push(this);
				else if(name == DEATH){
					if(game.content.deathsScythe.location == Item.UNASSIGNED){
						game.content.deathsScythe.collect(this, false);
						equip(game.content.deathsScythe);
					}
				}
			}
		}
		
		/* This is used by the Death character during an end-game event */
		override public function main():void {
			// sanity check
			if(!game.minion){
				game.endGameEvent = false;
				state = WALKING;
				callMain = false;
				endGameEventData = null;
				move();
			}
			
			var i:int, item:Item;
			var mc:MovieClip = gfx as MovieClip;
			if(!endGameEventData.gotYendor){
				if(endGameEventData.count){
					endGameEventData.count--;
				} else {
					endGameEventData.yendor = game.gameMenu.inventoryList.getItem(Item.YENDOR, Item.ARMOUR);
					// player has yendor, take it manually
					if(endGameEventData.yendor){
						endGameEventData.playerX = game.player.collider.x + game.player.collider.width * 0.5
						endGameEventData.deathX = collider.x + collider.width * 0.5
						if(endGameEventData.deathX > endGameEventData.playerX){
							dir = looking = LEFT;
						} else {
							dir = looking = RIGHT;
						}
						endGameEventData.charContact = null;
						if(collider.leftContact) endGameEventData.charContact = collider.leftContact.userData as Character;
						if(!endGameEventData.charContact && collider.rightContact) endGameEventData.charContact = collider.rightContact.userData as Character;
						if(endGameEventData.charContact == game.player){
							if(endGameEventData.yendor.user) endGameEventData.yendor = endGameEventData.yendor.user.unequip(endGameEventData.yendor);
							game.gameMenu.inventoryList.removeItem(endGameEventData.yendor);
							game.soundQueue.add("pickUp");
							endGameEventData.gotYendor = true;
						}
					// player may have dropped yendor - teleport it (a cheeky player may try to drop it into the water)
					} else {
						item = game.getFloorItem(Item.YENDOR, Item.ARMOUR);
						if(item){
							if(item.mapX < mapX) dir = looking = LEFT;
							else if(item.mapY > mapY) dir = looking = RIGHT;
							if(collider.intersects(item.collider)){
								item.destroyOnMap(true);
								game.createDistSound(item.mapX, item.mapY, "teleportYendor", Effect.TELEPORT_SOUNDS);
								endGameEventData.gotYendor = true;
							}
						}
					}
					move();
					if(endGameEventData.gotYendor){
						game.console.print("death takes yendor");
						endGameEventData.count = 60;
					}
				}
			} else if(!endGameEventData.transformedMinion){
				if(collider.x > endGameEventData.startX){
					dir = looking = LEFT;
					move();
				} else {
					dir = 0;
					if(game.minion.mapX < mapX){
						looking = LEFT;
					} else {
						looking = RIGHT;
					}
					if(endGameEventData.count){
						if(game.minion.state == Character.WALKING) endGameEventData.count--;
						move();
						if(endGameEventData.count == 0){
							game.minion.quicken();
						}
					} else {
						state = LUNGING;
						p.x = mc.x + mc.weapon.x;
						p.y = mc.y + mc.weapon.y;
						if(weapon) p.x += weapon.gfx.getBounds(weapon.gfx).right;
						for(i = 0; i < 3; i++){
							game.lightning.strike(
								renderer.lightningShape.graphics, game.world.map, p.x, p.y,
								game.minion.collider.x + game.minion.collider.width * 0.5,
								game.minion.collider.y + game.minion.collider.height * 0.5
							);
						}
						if(game.minion.state == Character.WALKING){
							game.endGameEvent = false;
							state = WALKING;
							callMain = false;
							endGameEventData = null;
							move();
						} else if(game.minion.state == Character.QUICKENING){
							if(game.minion.quickeningCount == 10){
								var explosion:Explosion = new Explosion(0, game.minion.mapX, game.minion.mapY, 3, 0, game.player, null, game.player.missileIgnore);
								game.minion.changeName(Character.HUSBAND);
								game.console.print(game.minion.nameToString() + " became husband");
								UserData.gameState.husband = true;
			
								var mapNameStr:String = Map.getName(game.map.level, game.map.type);
								if(game.map.type == Map.MAIN_DUNGEON) mapNameStr += ":" + game.map.level;
								game.trackEvent("husband", mapNameStr);
							}
						}
					}
				}
			}
		}
		
		override public function createCollider(x:Number, y:Number, properties:int, ignoreProperties:int, state:int = 0, positionByBase:Boolean = true):void {
			if(name == DEATH){
				super.createCollider(x, y, Collider.CHARACTER | Collider.SOLID, Collider.CORPSE | Collider.ITEM, Collider.STACK, true);
			} else {
				collider = new Collider(x - 1, y, Game.SCALE + 2, Game.SCALE, Game.SCALE, Collider.CHARACTER | Collider.SOLID | Collider.STONE, Collider.CORPSE | Collider.ITEM, Collider.HOVER);
				collider.userData = this;
			}
			collider.pushDamping = 0;
		}
		
		override public function applyDamage(n:Number, source:String, knockback:Number = 0, critical:Boolean = false, aggressor:Character = null, defaultSound:Boolean = true):void {
			var mc:MovieClip = gfx as MovieClip;
			if(name == SECRET_WALL){
				if(!revealed){
					// give experience for not using search skill
					game.player.addXP(SECRET_XP_REWARD * Content.getLevelXp(game.map.level));
					game.console.print("secret expertly discovered +xp");
					reveal();
				}
				super.applyDamage(n, source, 0, critical, aggressor, defaultSound);
				
			} else if(name == HEAL){
				if(game.minion){
					game.player.applyHealth(n * 0.5);
					game.minion.applyHealth(n * 0.5);
				} else {
					game.player.applyHealth(n);
				}
				mc.gotoAndPlay("hit");
				game.soundQueue.addRandom("healStone", HEAL_STONE_HIT_SOUNDS);
				
			} else if(name == GRIND){
				game.player.addXP(GRIND_XP_RATE);
				var frame:int = 1 + (mc.currentFrame  % mc.totalFrames);
				mc.gotoAndStop(frame);
				game.soundQueue.addRandom("grindStone", HIT_SOUNDS[Renderer.STONE]);
				
			} else if(name == DEATH){
				game.soundQueue.addRandom("grindStone", HIT_SOUNDS[Renderer.BONE]);
				hits++;
				if(hits > DEATH_HITS){
					if(aggressor){
						Map.underworldWaterCallback(aggressor);
					}
				}
			}
		}
		
		/* The secret wall is the only stone that can be destroyed, so only its death is dealt with here */
		override public function death(cause:String = "crushed", decapitation:Boolean = false, aggressor:Character = null):void {
			if(!active) return;
			active = false;
			renderer.createDebrisRect(collider, 0, 100, debrisType);
			game.console.print("secret revealed +xp");
			renderer.shake(0, 3);
			game.soundQueue.addRandom("stoneDeath", DEATH_SOUNDS);
			game.player.addXP(SECRET_XP_REWARD * Content.getLevelXp(game.map.level));
			game.world.removeMapPosition(mapX, mapY);
			game.mapTileManager.removeTile(this, mapX, mapY, mapZ);
			renderer.blockBitmapData.copyPixels(renderer.backBitmapData, new Rectangle(mapX * SCALE, mapY * SCALE, SCALE, SCALE), new Point(mapX * SCALE, mapY * SCALE));
			// adjust the mapRect to show new content
			if(side == LEFT){
				game.mapTileManager.mapRect.x = 0;
				game.mapTileManager.mapRect.width += game.map.bitmap.leftSecretWidth;
			} else if(side == RIGHT){
				game.mapTileManager.mapRect.width += game.map.bitmap.rightSecretWidth;
			}
			if(minimapFeature) {
				minimapFeature.active = false;
				minimapFeature = null;
			}
			collider.world.removeCollider(collider);
			game.content.removeSecret(game.map.level, game.map.type);
			if(--game.map.completionCount == 0) game.levelComplete();
		}
		
		/* A search action can reveal to the player where a secret wall is */
		public function reveal():void{
			var revealedGfx:MovieClip = new SecretMC();
			if(side == RIGHT){
				revealedGfx.scaleX = -1;
				renderer.addFX(gfx.x - SCALE, gfx.y, renderer.secretRevealRightBlit);
			} else if(side == LEFT){
				revealedGfx.x = SCALE;
				renderer.addFX(gfx.x + SCALE, gfx.y, renderer.secretRevealLeftBlit);
			}
			(gfx as Sprite).addChild(revealedGfx);
			minimapFeature = game.miniMap.addFeature(mapX, mapY, renderer.searchFeatureBlit, true);
			gfx.visible = true;
			revealed = true;
		}
		
		/* Set up Death for the end game event of transforming the minion */
		public function setEndGameEvent():void{
			callMain = true;
			endGameEventData = {
				gotYendor:false,
				transformedMinion:false,
				startX:collider.x,
				count:30,
				charContact:null
			}
		}
		
		/* Called to make this object visible */
		override public function render():void{
			if(name == DEATH){
				super.render();
				return;
			}
			matrix = gfx.transform.matrix;
			matrix.tx -= renderer.bitmap.x;
			matrix.ty -= renderer.bitmap.y;
			renderer.bitmapData.draw(gfx, matrix, gfx.transform.colorTransform);
		}
		
	}

}