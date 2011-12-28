package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.dungeon.Map;
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
	import flash.geom.Rectangle;
	
	/**
	 * A wall that Characters can attack - either resulting in the wall being destroyed or other effects
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Stone extends Character{
		
		public var revealed:Boolean;
		
		private var minimapFeature:MinimapFX;
		private var hits:int;
		
		public static const SECRET_WALL:int = 0;
		public static const HEAL:int = 1;
		public static const GRIND:int = 2;
		public static const DEATH:int = 3;
		
		public static const SECRET_XP_REWARD:Number = 2;
		public static const GRIND_XP_REWARD:Number = 0.1;
		public static const DEATH_HITS:int = 3;
		
		public static const STONE_NAME_HEALTHS:Array = [
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
			health = STONE_NAME_HEALTHS[name];
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
		
		override public function createCollider(x:Number, y:Number, properties:int, ignoreProperties:int, state:int = 0, positionByBase:Boolean = true):void {
			if(name == DEATH){
				super.createCollider(x, y, Collider.CHARACTER | Collider.SOLID, Collider.CORPSE | Collider.ITEM, Collider.STACK, true);
			} else {
				collider = new Collider(x - 1, y, Game.SCALE + 2, Game.SCALE, Game.SCALE, Collider.CHARACTER | Collider.SOLID, Collider.CORPSE | Collider.ITEM, Collider.HOVER);
				collider.userData = this;
			}
			collider.pushDamping = 0;
		}
		
		override public function applyDamage(n:Number, source:String, knockback:Number = 0, critical:Boolean = false, aggressor:Character = null):void {
			var mc:MovieClip = gfx as MovieClip;
			if(name == SECRET_WALL){
				if(!revealed) reveal();
				super.applyDamage(n, source, 0, critical, aggressor);
				
			} else if(name == HEAL){
				if(game.minion){
					game.player.applyHealth(n * 0.5);
					game.minion.applyHealth(n * 0.5);
				} else {
					game.player.applyHealth(n);
				}
				mc.gotoAndPlay("hit");
				
			} else if(name == GRIND){
				game.player.addXP(GRIND_XP_REWARD);
				var frame:int = 1 + (mc.currentFrame  % mc.totalFrames);
				mc.gotoAndStop(frame);
				
			} else if(name == DEATH){
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
			active = false;
			renderer.createDebrisRect(collider, 0, 100, debrisType);
			game.console.print("secret revealed");
			renderer.shake(0, 3);
			game.soundQueue.add("kill");
			game.player.addXP(SECRET_XP_REWARD * game.dungeon.level);
			game.world.map[mapY][mapX] = 0;
			game.mapTileManager.removeTile(this, mapX, mapY, mapZ);
			renderer.blockBitmapData.fillRect(new Rectangle(mapX * SCALE, mapY * SCALE, SCALE, SCALE), 0x00000000);
			// adjust the mapRect to show new content
			if(mapX < game.player.mapX){
				game.mapTileManager.mapRect.x = 0;
				game.mapTileManager.mapRect.width += game.dungeon.bitmap.leftSecretWidth;
			} else if(mapX > game.player.mapX){
				game.mapTileManager.mapRect.width += game.dungeon.bitmap.rightSecretWidth;
			}
			if(minimapFeature) {
				minimapFeature.active = false;
				minimapFeature = null;
			}
			collider.world.removeCollider(collider);
			game.content.removeSecret(game.dungeon.level, game.dungeon.type);
		}
		
		/* A search action can reveal to the player where a secret wall is */
		public function reveal():void{
			var trapRevealedB:Bitmap = new game.library.TrapRevealedB();
			var matrix:Matrix = new Matrix();
			matrix.tx = -SCALE * 0.5;
			matrix.ty = -SCALE * 0.5;
			var side:int;
			if(mapX * SCALE >= game.mapTileManager.mapRect.x + game.mapTileManager.mapRect.width * 0.5){
				side = RIGHT;
			} else {
				side = LEFT;
			}
			matrix.rotate(side == RIGHT ? -Math.PI * 0.5 : Math.PI * 0.5);
			matrix.tx += side == RIGHT ? -((SCALE * 0.5) - 1) : 1 + (SCALE * 1.5);
			matrix.ty += SCALE * 0.5;
			trapRevealedB.transform.matrix = matrix;
			(gfx as Sprite).addChild(trapRevealedB);
			var bitmapData:BitmapData = new BitmapData(3, 3, true, 0x00000000);
			bitmapData.setPixel32(1, 0, 0xFFAA0000);
			bitmapData.fillRect(new Rectangle(0, 1, 3, 1), 0xFFAA0000);
			bitmapData.setPixel32(1, 2, 0xFFAA0000);
			minimapFeature = game.miniMap.addFeature(mapX, mapY, renderer.searchFeatureBlit, true);
			gfx.visible = true;
			revealed = true;
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