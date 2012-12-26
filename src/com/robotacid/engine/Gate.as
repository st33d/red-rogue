package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.CogRectBlit;
	import com.robotacid.gfx.FadingBlitRect;
	import com.robotacid.level.Map;
	import com.robotacid.engine.Character;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.level.Surface;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.MinimapFX;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	/**
	 * A standing collider that can be raised or destroyed
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Gate extends Character{
		
		private var minimapFeature:MinimapFX;
		private var openY:Number;
		private var raiseHits:int;
		private var holdCount:int;
		private var fleeRect:Rectangle;
		private var cogDisplacement:int;
		private var cogFrame:int;
		
		public var gateState:int;
		
		private var i:Number;
		
		private static var dist:Number;
		
		// gate states
		public static const OPEN:int = 1;
		public static const OPENING:int = 2;
		public static const CLOSED:int = 3;
		public static const CLOSING:int = 4;
		public static const RETIRING:int = 5;
		
		// names
		public static const RAISE:int = 0;
		public static const LOCK:int = 1;
		public static const PRESSURE:int = 2;
		public static const CHAOS:int = 3;
		
		public static const HIT_SOUNDS:Array = ["stoneHit1", "stoneHit2", "stoneHit3", "stoneHit4"];
		public static const DEATH_SOUNDS:Array = ["stoneDeath1", "stoneDeath2", "stoneDeath3", "stoneDeath4"];
		public static const PRY_SOUNDS:Array = ["gatePry1", "gatePry2", "gatePry3", "gatePry4"];
		
		public static const SPEED:Number = 2;
		public static const RAISE_HIT_TOTAL:int = 4;
		public static const RAISE_STEP:Number = SCALE / RAISE_HIT_TOTAL;
		public static const HOLD_DELAY:int = 30;
		public static const STOMP_DAMAGE_RATIO:Number = 1 / 10;
		
		public function Gate(x:Number, y:Number, name:int) {
			
			if(name == RAISE) gfx = new RaiseGateMC();
			else if(name == LOCK) gfx = new LockGateMC();
			else if(name == PRESSURE) gfx = new PressureGateMC();
			else if(name == CHAOS) gfx = new ChaosGateMC();
			gfx.x = x;
			gfx.y = y;
			super(gfx, x, y, name, GATE, 0, false);
			
			gateState = CLOSED;
			openY = y - SCALE;
			fleeRect = new Rectangle(x, y, SCALE, SCALE);
			
			defence = 0;
			callMain = false;
			if(name == CHAOS){
				callMain = true;
				holdCount = HOLD_DELAY;
				
			}
			debrisType = Renderer.STONE;
			free = false;
			addToEntities = true;
		}
		
		override public function createCollider(x:Number, y:Number, properties:int, ignoreProperties:int, state:int = 0, positionByBase:Boolean = true):void {
			collider = new Collider(x, y, Game.SCALE, Game.SCALE, Game.SCALE, Collider.CHARACTER | Collider.SOLID | Collider.GATE, Collider.CORPSE | Collider.ITEM | Collider.WALL | Collider.CHAOS | Collider.GATE | Collider.HORROR, Collider.HOVER);
			collider.userData = this;
			collider.pushDamping = 0;
			collider.dampingX = collider.dampingY = 1;
			collider.stackable = false;
			mapX = x * INV_SCALE;
			mapY = y * INV_SCALE;
		}
		
		override public function main():void {
			
			dist = collider.y - openY;
			if(gateState == OPENING){
				collider.vy = dist < SPEED ? -dist : -SPEED;
				if(name == RAISE){
					if(dist <= ((RAISE_HIT_TOTAL - raiseHits) * RAISE_STEP) + Collider.MOVEMENT_TOLERANCE){
						holdCount = HOLD_DELAY + HOLD_DELAY * 0.5;
						gateState = OPEN;
						collider.vy = 0;
					}
				} else if(dist < Collider.MOVEMENT_TOLERANCE){
					collider.vy = 0;
					game.createDistSound(mapX, mapY, "chaosWallStop");
					renderer.shake(0, -2);
					gateState = OPEN;
					if(name == CHAOS){
						holdCount = HOLD_DELAY * 2 + game.random.range(HOLD_DELAY * 2);
					} else if(name == LOCK){
						gateState = RETIRING;
					}
				}
				
			} else if(gateState == OPEN){
				if(name == RAISE || name == CHAOS){
					holdCount--;
					if(holdCount <= 0){
						gateState = CLOSING;
						raiseHits = 0;
						collider.awake = Collider.AWAKE_DELAY;
						game.createDistSound(mapX, mapY, "gateShut");
					}
				}
				
			} else if(gateState == CLOSING){
				collider.vy = SCALE-dist < speed ? SCALE-dist : SPEED;
				// get all characters with brains to get out of the way
				var character:Character;
				var colliders:Vector.<Collider> = game.world.getCollidersIn(fleeRect, collider, Collider.CHARACTER, Collider.GATE | Collider.STONE);
				for(i = 0; i < colliders.length; i++){
					character = colliders[i].userData as Character;
					if(character && character.brain) character.brain.flee(this);
				}
				if(collider.pressure & DOWN){
					game.createDistSound(mapX, mapY, "thud");
					if(collider.downContact){
						character = collider.downContact.userData as Character;
						if(character){
							character.applyDamage(character.totalHealth * STOMP_DAMAGE_RATIO, "gate", 0, false, this);
						}
					}
					if(name == RAISE) raiseHits = RAISE_HIT_TOTAL;
					gateState = OPENING;
					collider.vy = 0;
					
				} else if(dist >= SCALE - Collider.MOVEMENT_TOLERANCE){
					gateState = CLOSED;
					collider.vy = 0;
					game.createDistSound(mapX, mapY, "chaosWallStop");
					if(name == CHAOS){
						holdCount = HOLD_DELAY * 2 + game.random.range(HOLD_DELAY * 2);
					} else {
						callMain = false;
					}
				}
				
			} else if(gateState == CLOSED){
				// only CHAOS should be getting here
				holdCount--;
				if(holdCount <= 0){
					gateState = OPENING;
					collider.awake = Collider.AWAKE_DELAY;
					game.createDistSound(mapX, mapY, "gateOpen");
				}
				
			} else if(gateState == RETIRING){
				if(cogDisplacement <= 0){
					if(name == LOCK){
						// Surface.fragmentationMap is no longer necessary - delete it
						Surface.fragmentationMap = null;
						death();
					}
				}
			}
			//Game.debug.drawRect(collider.x, collider.y, collider.width, collider.height);
		}
		
		override public function applyDamage(n:Number, source:String, knockback:Number = 0, critical:Boolean = false, aggressor:Character = null, defaultSound:Boolean = true):void {
			var mc:MovieClip = gfx as MovieClip;
			
			if(name == RAISE){
				if(raiseHits < RAISE_HIT_TOTAL){
					raiseHits++;
					game.createDistSound(mapX, mapY, "gatePry", PRY_SOUNDS);
				}
				open();
				
			} else if(name == LOCK){
				if(gateState == CLOSED){
					renderer.createSparkRect(collider, 20, 0, -1);
					if(aggressor == game.player){
						if(game.player.keyItem){
							open();
							game.player.setKeyItem(false);
							game.console.print("unlocked gate");
							game.soundQueue.add("gateUnlock");
						} else {
							game.console.print("find a key");
						}
					}
				}
				
			} else if(name == PRESSURE){
				if(gateState == CLOSED){
					renderer.createSparkRect(collider, 20, 0, -1);
					if(aggressor == game.player) game.console.print("find a pressure pad");
				}
				
			} else if(name == CHAOS){
				if(aggressor == game.player) game.console.print("?");
			}
			game.soundQueue.addRandom("gateHit", HIT_SOUNDS);
			
			if(!minimapFeature){
				minimapFeature = game.miniMap.addFeature(mapX, mapY, renderer.gateFeatureBlit, true);
			} else return;
		}
		
		/* Just in case */
		override public function applyStun(delay:Number):void {
			return;
		}
		override public function applyWeaponEffects(item:Item):void {
			return;
		}
		
		public function open():void{
			if(!callMain){
				callMain = true;
				if(gateState == CLOSED || gateState == CLOSING || gateState == OPEN){
					collider.vy = 0;
					if(name != RAISE) game.createDistSound(mapX, mapY, "gateOpen");
				}
			}
			collider.awake = Collider.AWAKE_DELAY;
			holdCount = 0;
			gateState = OPENING;
		}
		
		/* Called to destroy a gate */
		override public function death(cause:String = "crushing", decapitation:Boolean = false, aggressor:Character = null):void {
			if(!active) return;
			active = false;
			renderer.shake(0, 3);
			game.mapTileManager.removeTile(this, mapX, mapY, mapZ);
			if(minimapFeature) {
				minimapFeature.active = false;
				minimapFeature = null;
			}
			collider.world.removeCollider(collider);
			if(minimapFeature) {
				minimapFeature.active = false;
				minimapFeature = null;
			}
			renderer.createDebrisRect(collider, 0, 50, debrisType);
		}
		
		/* Called to make this object visible */
		override public function render():void{
			// spawn small debris when opening and closing
			if(collider.vy){
				var blit:BlitRect;
				var print:FadingBlitRect;
				if(game.random.coinFlip()){
					blit = renderer.smallDebrisBlits[Renderer.STONE];
					print = renderer.smallFadeBlits[Renderer.STONE];
				} else {
					blit = renderer.bigDebrisBlits[Renderer.STONE];
					print = renderer.bigFadeBlits[Renderer.STONE];
				}
				renderer.addDebris(collider.x + game.random.range(collider.width), 1 + mapY * SCALE, blit, 0, game.random.range(3), print, true);
			}
			gfx.x = (collider.x + 0.5) >> 0;
			gfx.y = (collider.y + 0.5) >> 0;
			matrix = gfx.transform.matrix;
			matrix.tx -= renderer.bitmap.x;
			matrix.ty -= renderer.bitmap.y;
			renderer.bitmapData.draw(gfx, matrix, gfx.transform.colorTransform);
			if(gateState == OPENING || gateState == OPEN){
				if(cogDisplacement < SCALE * 0.5){
					cogDisplacement++;
				}
				renderer.cogRectBlit.dirs[CogRectBlit.BOTTOM_RIGHT] = 1;
				renderer.cogRectBlit.dirs[CogRectBlit.BOTTOM_LEFT] = -1;
			} else if(gateState == CLOSED || gateState == CLOSING || gateState == RETIRING){
				if(cogDisplacement > 0){
					cogDisplacement--;
				}
				renderer.cogRectBlit.dirs[CogRectBlit.BOTTOM_RIGHT] = -1;
				renderer.cogRectBlit.dirs[CogRectBlit.BOTTOM_LEFT] = 1;
			}
			if(cogDisplacement > 0){
				if(gateState == OPENING || gateState == CLOSING){
					cogFrame++;
					if(cogFrame >= renderer.cogRectBlit.totalFrames) cogFrame = 0;
				}
				
				renderer.cogRectBlit.allVisible = false;
				renderer.cogRectBlit.visibles[CogRectBlit.TOP_LEFT] = false;
				renderer.cogRectBlit.visibles[CogRectBlit.TOP_RIGHT] = false;
				renderer.cogRectBlit.visibles[CogRectBlit.BOTTOM_LEFT] = true;
				renderer.cogRectBlit.visibles[CogRectBlit.BOTTOM_RIGHT] = true;
				renderer.cogRectBlit.displacement = cogDisplacement;
				renderer.cogRectBlit.x = -renderer.bitmap.x + collider.x + SCALE * 0.5;
				renderer.cogRectBlit.y = -renderer.bitmap.y + openY + SCALE * 0.5;
				renderer.cogRectBlit.render(renderer.bitmapData, cogFrame);
			}
		}
		
	}

}