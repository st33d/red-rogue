package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.dungeon.Map;
	import com.robotacid.engine.Character;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.MinimapFeature;
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
		
		private var minimapFeature:MinimapFeature;
		
		public static const SECRET_WALL:int = 0;
		public static const HEALTH:int = 1;
		public static const GRIND:int = 2;
		
		public static const SECRET_XP_REWARD:Number = 2;
		public static const GRIND_XP_REWARD:Number = 0.1;
		
		public static const STONE_NAME_HEALTHS:Array = [
			5,
			0,
			0
		];
		
		public function Stone(x:Number, y:Number, name:int, side:int = 0) {
			if(name == HEALTH) gfx = new HeartFadeMC();
			else if(name == GRIND){
				gfx = new GrindWheelMC();
				(gfx as MovieClip).stop();
			}
			else gfx = new MovieClip();
			gfx.x = x;
			gfx.y = y;
			super(gfx, x, y, name, STONE, 0, false);
			health = STONE_NAME_HEALTHS[name];
			defence = 0;
			callMain = false;
			debrisType = name == HEALTH ? Renderer.BLOOD : Renderer.STONE;
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
				g.entities.push(this);
			}
		}
		
		override public function createCollider(x:Number, y:Number, properties:int, ignoreProperties:int, state:int = 0, positionByBase:Boolean = true):void {
			collider = new Collider(x - 1, y, Game.SCALE + 2, Game.SCALE, Game.SCALE, Collider.CHARACTER | Collider.SOLID, Collider.CORPSE | Collider.ITEM, Collider.HOVER);
			collider.userData = this;
			collider.pushDamping = 0;
		}
		
		override public function applyDamage(n:Number, source:String, knockback:Number = 0, critical:Boolean = false, aggressor:Character = null):void {
			var mc:MovieClip = gfx as MovieClip;
			if(name == SECRET_WALL){
				if(!revealed) reveal();
				super.applyDamage(n, source, 0, critical, aggressor);
				
			} else if(name == HEALTH){
				if(g.minion){
					g.player.applyHealth(n * 0.5);
					g.minion.applyHealth(n * 0.5);
				} else {
					g.player.applyHealth(n);
				}
				mc.gotoAndPlay("hit");
			} else if(name == GRIND){
				g.player.addXP(GRIND_XP_REWARD);
				var frame:int = 1 + (mc.currentFrame  % mc.totalFrames);
				mc.gotoAndStop(frame);
			}
		}
		
		/* The secret wall is the only stone that can be destroyed, so only its death is dealt with here */
		override public function death(cause:String = "crushed", decapitation:Boolean = false, aggressor:Character = null):void {
			active = false;
			renderer.createDebrisRect(collider, 0, 100, debrisType);
			g.console.print("secret revealed");
			renderer.shake(0, 3);
			g.soundQueue.add("kill");
			g.player.addXP(SECRET_XP_REWARD * g.dungeon.level);
			g.world.map[mapY][mapX] = 0;
			g.mapTileManager.removeTile(this, mapX, mapY, mapZ);
			renderer.blockBitmapData.fillRect(new Rectangle(mapX * SCALE, mapY * SCALE, SCALE, SCALE), 0x00000000);
			// adjust the mapRect to show new content
			if(mapX < g.player.mapX){
				g.mapTileManager.mapRect.x = 0;
				g.mapTileManager.mapRect.width += g.dungeon.bitmap.leftSecretWidth;
			} else if(mapX > g.player.mapX){
				g.mapTileManager.mapRect.width += g.dungeon.bitmap.rightSecretWidth;
			}
			if(minimapFeature) {
				minimapFeature.active = false;
				minimapFeature = null;
			}
			collider.world.removeCollider(collider);
			g.content.removeSecret(g.dungeon.level, g.dungeon.type);
		}
		
		/* A search action can reveal to the player where a secret wall is */
		public function reveal():void{
			var trapRevealedB:Bitmap = new g.library.TrapRevealedB();
			var matrix:Matrix = new Matrix();
			matrix.tx = -SCALE * 0.5;
			matrix.ty = -SCALE * 0.5;
			var side:int;
			if(mapX * SCALE >= g.mapTileManager.mapRect.x + g.mapTileManager.mapRect.width * 0.5){
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
			minimapFeature = g.miniMap.addFeature(mapX, mapY, renderer.searchFeatureBlit, true);
			gfx.visible = true;
			revealed = true;
		}
		
		/* Called to make this object visible */
		override public function render():void{
			matrix = gfx.transform.matrix;
			matrix.tx -= renderer.bitmap.x;
			matrix.ty -= renderer.bitmap.y;
			renderer.bitmapData.draw(gfx, matrix, gfx.transform.colorTransform);
		}
		
	}

}