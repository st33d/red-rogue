﻿package com.robotacid.gfx {	import com.robotacid.geom.Pixel;	import com.robotacid.level.Content;	import com.robotacid.level.Map;	import com.robotacid.engine.Effect;	import com.robotacid.engine.Entity;	import com.robotacid.engine.Item;	import com.robotacid.engine.MapTileConverter;	import com.robotacid.phys.Collider;	import com.robotacid.ui.Console;	import com.robotacid.ui.menu.EditorMenuList;	import com.robotacid.ui.ProgressBar;	import com.robotacid.ui.Suggestion;	import flash.display.Bitmap;	import flash.display.BitmapData;	import flash.display.BlendMode;	import flash.display.Graphics;	import flash.display.MovieClip;	import flash.display.Shape;	import flash.display.Sprite;	import flash.display.Stage;	import flash.events.Event;	import flash.filters.ColorMatrixFilter;	import flash.geom.ColorTransform;	import flash.geom.Matrix;	import flash.geom.Point;	import flash.geom.Rectangle;	import flash.utils.getDefinitionByName;		/**	 * Manages all graphics rendering	 *	 * @author Aaron Steed, robotacid.com	 */	public class Renderer{				public var game:Game;		public var camera:CanvasCamera;		public var sceneManager:SceneManager;				public var gifBuffer:GifBuffer;				// gfx holders		public var canvas:Sprite;		public var lightningShape:Shape		public var bitmapData:BitmapData;		public var bitmap:Bitmap;		public var lightBitmap:Bitmap;		public var backgroundShape:Shape;		public var backgroundBitmapData:BitmapData;		public var blockBitmapData:BitmapData;		public var backBitmapData:BitmapData;		public var hurtShape:Shape;		public var hurtBitmapData:BitmapData;		public var blockRect:Rectangle;				// blits		public var sparkBlit:BlitRect;		public var twinkleBlit:BlitClip;		public var teleportSparkBigFadeBlit:FadingBlitRect;		public var teleportSparkSmallFadeBlit:FadingBlitRect;		public var stunBlit:BlitClip;		public var novaBlit:BlitClip;		public var insertionPointBlit:BlitClip;		public var smallDebrisBlits:Vector.<BlitRect>;		public var bigDebrisBlits:Vector.<BlitRect>;		public var smallFadeBlits:Vector.<FadingBlitRect>;		public var bigFadeBlits:Vector.<FadingBlitRect>;		public var stairsUpFeatureBlit:BlitClip;		public var stairsDownFeatureBlit:BlitClip;		public var portalFeatureBlit:BlitClip;		public var searchFeatureBlit:BlitClip;		public var featureRevealedBlit:BlitClip;		public var minionFeatureBlit:BlitClip;		public var gateFeatureBlit:BlitClip;		public var keyFeatureBlit:BlitClip;		public var trapRevealBlit:BlitClip;		public var secretRevealLeftBlit:BlitClip;		public var secretRevealRightBlit:BlitClip;		public var smiteLeftBlit:BlitClip;		public var smiteRightBlit:BlitClip;		public var plateauBlit:BlitClip;		public var explosionBlit:BlitClip;		public var explosionDirBlits:Vector.<BlitClip>;		public var cogRectBlit:CogRectBlit;		public var blackWritingUnderBlit:WritingBlit;		public var blackWritingOverBlit:WritingBlit;		public var redWritingUnderBlit:WritingBlit;		public var redWritingOverBlit:WritingBlit;		public var redRingBlit:BlitClip;		public var mushroomBlit:BlitClip;				public var zoneBackgroundBitmaps:Vector.<Vector.<Bitmap>>;		public var pipeBitmaps:Vector.<Bitmap>;				// self maintaining animations		public var fx:Vector.<FX>;		public var fxSpawn:Vector.<FX>; // fx generated during the filter callback must be added to a waiting list		public var fxFilterCallBack:Function;				// states		public var shakeOffset:Point;		public var shakeDirX:int;		public var shakeDirY:int;		public var fireBallAngle:int;		public var lockFrame:int;		public var painHurtAlpha:Number;						// temp variables		private var i:int;				public static var point:Point = new Point();		public static var matrix:Matrix = new Matrix();				// measurements from Game.as		public static const SCALE:Number = Game.SCALE;		public static const INV_SCALE:Number = Game.INV_SCALE;		public static const WIDTH:Number = Game.WIDTH;		public static const HEIGHT:Number = Game.HEIGHT;				public static const SHAKE_DIST_MAX:int = 12;		public static const INV_SHAKE_DIST_MAX:Number = 1.0 / SHAKE_DIST_MAX;				// debris types		public static const BLOOD:int = 0;		public static const BONE:int = 1;		public static const STONE:int = 2;				public function Renderer(game:Game){			this.game = game;		}				/* Initialisation is separated from the constructor to allow reference paths to be complete before all		 * of the graphics are generated - an object is null until its constructor has been exited */		public function init():void{						Entity.renderer = this;			LightMap.renderer = this;			Effect.renderer = this;			FX.renderer = this;			Map.renderer = this;			Content.renderer = this;			ItemMovieClip.renderer = this;			SceneManager.renderer = this;			EditorMenuList.renderer = this;			Suggestion.renderer = this;						ItemMovieClip.init();						// init debris particles			smallDebrisBlits = Vector.<BlitRect>([				new BlitRect(0, 0, 1, 1, 0xffAA0000),				new BlitRect(0, 0, 1, 1, 0xffffffff),				new BlitRect(0, 0, 1, 1, 0xff000000)			]);			bigDebrisBlits = Vector.<BlitRect>([				new BlitRect(-1, -1, 2, 2, 0xffAA0000),				new BlitRect(-1, -1, 2, 2, 0xFFFFFFFF),				new BlitRect( -1, -1, 2, 2, 0xff000000)			]);			smallFadeBlits = Vector.<FadingBlitRect>([				new FadingBlitRect(0, 0, 1, 1, 30, 0xffAA0000),				new FadingBlitRect(0, 0, 1, 1, 30, 0xffffffff),				new FadingBlitRect(0, 0, 1, 1, 30, 0xff000000)			]);			bigFadeBlits = Vector.<FadingBlitRect>([				new FadingBlitRect( -1, -1, 2, 2, 30, 0xffAA0000),				new FadingBlitRect( -1, -1, 2, 2, 30, 0xffffffff),				new FadingBlitRect( -1, -1, 2, 2, 30, 0xff000000)			]);			stairsUpFeatureBlit = new BlitClip(new StairsUpFeatureMC);			stairsDownFeatureBlit = new BlitClip(new StairsDownFeatureMC);			portalFeatureBlit = new BlitClip(new PortalFeatureMC);			searchFeatureBlit = new BlitClip(new SearchFeatureMC);			featureRevealedBlit = new BlitClip(new FeatureRevealedMC);			gateFeatureBlit = new BlitClip(new GateFeatureMC);			keyFeatureBlit = new BlitClip(new KeyFeatureMC);			minionFeatureBlit = new BlitClip();			minionFeatureBlit.totalFrames = 1;			minionFeatureBlit.data = new BitmapData(3, 3, true, 0x0);			minionFeatureBlit.frames = Vector.<BitmapData>([minionFeatureBlit.data]);			minionFeatureBlit.rect = minionFeatureBlit.data.rect;			minionFeatureBlit.dx = minionFeatureBlit.dy = -1;			minionFeatureBlit.width = minionFeatureBlit.height = 3;			minionFeatureBlit.data.setPixel32(1, 0, 0xCCFFFFFF);			minionFeatureBlit.data.setPixel32(0, 1, 0xCCFFFFFF);			minionFeatureBlit.data.setPixel32(2, 1, 0xCCFFFFFF);			minionFeatureBlit.data.setPixel32(1, 2, 0xCCFFFFFF);			trapRevealBlit = new BlitClip(new TrapRevealMC);			secretRevealLeftBlit = new BlitClip(new SecretRevealLeftMC);			secretRevealRightBlit = new BlitClip(new SecretRevealRightMC);			smiteLeftBlit = new BlitClip(new SmiteLeftMC);			smiteRightBlit = new BlitClip(new SmiteRightMC);			plateauBlit = new BlitClip(new PlateauMC);			explosionBlit = new BlitClip(new ExplosionMC);			cogRectBlit = new CogRectBlit();			blackWritingUnderBlit = new WritingBlit(new BlackWritingUnderMC);			blackWritingOverBlit = new WritingBlit(new BlackWritingOverMC);			redWritingUnderBlit = new WritingBlit(new RedWritingUnderMC);			redWritingOverBlit = new WritingBlit(new RedWritingOverMC);			redRingBlit = new BlitClip(new RedRingMC, new ColorTransform(1, 1, 1, 0.5));			mushroomBlit = new BlitClip(new MushroomMC);						explosionDirBlits = Vector.<BlitClip>([				new BlitClip(new ExplosionUpMC),				new BlitClip(new ExplosionRightMC),				new BlitClip(new ExplosionDownMC),				new BlitClip(new ExplosionLeftMC)			]);									zoneBackgroundBitmaps = Vector.<Vector.<Bitmap>>([				Vector.<Bitmap>([					new game.library.BackB1,					new game.library.BackB2,					new game.library.BackB3,					new game.library.BackB4				]),				Vector.<Bitmap>([					new game.library.BackB5,					new game.library.BackB6,					new game.library.BackB7,					new game.library.BackB8				]),				Vector.<Bitmap>([					new game.library.BackB9,					new game.library.BackB10,					new game.library.BackB11,					new game.library.BackB12				]),			]);			zoneBackgroundBitmaps.push(zoneBackgroundBitmaps[0].concat(zoneBackgroundBitmaps[1]));						pipeBitmaps = Vector.<Bitmap>([				new game.library.PipeB1,				new game.library.PipeB2,				new game.library.PipeB3,				new game.library.PipeB4,				new game.library.PipeB5,				new game.library.PipeB6,				new game.library.PipeB7,				new game.library.PipeB8,				new game.library.PipeB9,				new game.library.PipeB10,				new game.library.PipeB11,				new game.library.PipeB12,				new game.library.PipeB13			]);						sparkBlit = smallDebrisBlits[BONE];			teleportSparkSmallFadeBlit = smallFadeBlits[BONE];			teleportSparkBigFadeBlit = bigFadeBlits[BONE];						twinkleBlit = new BlitClip(new TwinkleMC);			stunBlit = new BlitClip(new StunMC);			novaBlit = new BlitClip(new NovaMC);						insertionPointBlit = new BlitClip(new InsertionPointMC);						blockRect = new Rectangle(0, 0, Game.WIDTH, Game.HEIGHT - Console.HEIGHT);						fxFilterCallBack = function(item:FX, index:int, list:Vector.<FX>):Boolean{				item.main();				return item.active;			};		}				/* Prepares sprites and bitmaps for a game session */		public function createRenderLayers(holder:Sprite = null):void{						if(!holder) holder = game;						canvas = new Sprite();			holder.addChild(canvas);						backgroundShape = new Shape();			backgroundBitmapData = new BitmapData(1, 1, true, 0x0);						bitmapData = new BitmapData(WIDTH, HEIGHT, true, 0x0);			bitmap = new Bitmap(bitmapData);						var debugShape:Shape = new Shape();			Game.debug = debugShape.graphics;			var debugStayShape:Shape = new Shape();			Game.debugStay = debugStayShape.graphics;			Game.debugStay.lineStyle(2, 0xFF0000);						lightningShape = new Shape();			lightBitmap = new Bitmap(new BitmapData(1, 1, true, 0x0));			lightBitmap.scaleX = lightBitmap.scaleY = Game.SCALE;						hurtShape = new Shape();			hurtBitmapData = new game.library.HurtB().bitmapData;						//lightBitmap.visible = false;						canvas.addChild(backgroundShape);			canvas.addChild(bitmap);			canvas.addChild(lightningShape);			canvas.addChild(lightBitmap);			canvas.addChild(hurtShape);			canvas.addChild(debugShape);			canvas.addChild(debugStayShape);						fx = new Vector.<FX>();			fxSpawn = new Vector.<FX>();						camera = new CanvasCamera(canvas, this);						shakeOffset = new Point();			shakeDirX = 0;			shakeDirY = 0;			fireBallAngle = 0;			lockFrame = 0;			painHurtAlpha = 0;						gifBuffer = new GifBuffer(160, 120, 90, canvas, game);			//gifBuffer = new GifBuffer(80, 60, 90, canvas, game);			if(game.gameMenu && game.gameMenu.saveGifOption.active) gifBuffer.activate();		}				/* Tries to free memory by orphaning the graphics layers - this in theory should give the		 * garbage collector a kick up the bum - I gather this seems overkill, but Flash's garbage		 * collector is actually notoriously ropey, and this is a static object which I don't want		 * to reinitialise because of all the blitting objects. So ner. */		public function clearAll():void{			while(canvas.numChildren > 0){				canvas.removeChildAt(0);			}			bitmap = null;			bitmapData.dispose();			bitmapData = null;			fx = null;			game = null;		}				/* ================================================================================================		 * MAIN		 * Updates all of the rendering 		 * ================================================================================================		 */		public function main():void {						updateShaker();						if(game.player.collider){				camera.setTarget(					game.player.collider.x + game.player.collider.width * 0.5 + game.player.cameraDisplacement.x,					game.player.collider.y + game.player.collider.height * 0.5 + game.player.cameraDisplacement.y				);			}						if(game.state == Game.GAME) camera.main();						// clear bitmapDatas			bitmapData.fillRect(bitmapData.rect, 0x0);			bitmap.x = -canvas.x;			bitmap.y = -canvas.y;						// black border around small levels			if(canvas.x > camera.mapRect.x){				bitmapData.fillRect(new Rectangle(0, 0, canvas.x, Game.HEIGHT - Console.HEIGHT), 0xFF000000);			}			if(canvas.x + camera.mapRect.x + camera.mapRect.width < Game.WIDTH){				bitmapData.fillRect(new Rectangle(canvas.x + camera.mapRect.x + camera.mapRect.width, 0, Game.WIDTH - (canvas.x + camera.mapRect.x + camera.mapRect.width), Game.HEIGHT - Console.HEIGHT), 0xFF000000);			}			if(canvas.y > 0){				bitmapData.fillRect(new Rectangle(0, 0, Game.WIDTH, canvas.y), 0xFF000000);			}			if(canvas.y + camera.mapRect.height < Game.HEIGHT - Console.HEIGHT){				bitmapData.fillRect(new Rectangle(0, canvas.y + camera.mapRect.height, Game.WIDTH, (Game.HEIGHT - Console.HEIGHT) - (canvas.y + camera.mapRect.height)), 0xFF000000);			}						// render parallax layer			backgroundShape.x = -canvas.x;			backgroundShape.y = -canvas.y;			backgroundShape.graphics.clear();			matrix.identity();			matrix.tx = canvas.x;			matrix.ty = canvas.y;			backgroundShape.graphics.beginBitmapFill(backgroundBitmapData, matrix);			backgroundShape.graphics.drawRect(0, 0, Game.WIDTH, Game.HEIGHT - Console.HEIGHT);						// render hurt			if(game.player.active && (painHurtAlpha || game.playerHealthBar.glowActive)){				if(painHurtAlpha){					painHurtAlpha -= 0.02;					if(painHurtAlpha <= 0){						painHurtAlpha = 0;					}				}				hurtShape.alpha = painHurtAlpha + (game.playerHealthBar.glowActive ? ProgressBar.glowTable[ProgressBar.glowCount] * 0.05 + 0.45: 0);				if(hurtShape.alpha > 0){					hurtShape.x = -canvas.x;					hurtShape.y = -canvas.y;					hurtShape.graphics.clear();					matrix.identity();					matrix.translate(-(hurtBitmapData.width * 0.5) >> 0, -(hurtBitmapData.height * 0.5) >> 0);					matrix.scale(16, 16);					matrix.translate(game.player.mapX * SCALE-hurtShape.x, game.player.mapY * SCALE-hurtShape.y);					hurtShape.graphics.beginBitmapFill(hurtBitmapData, matrix);					hurtShape.graphics.drawRect(0, 0, Game.WIDTH, Game.HEIGHT - Console.HEIGHT);					hurtShape.visible = true;									} else hurtShape.visible = false;							} else if(hurtShape.visible) hurtShape.visible = false;						if(sceneManager) sceneManager.renderBackground();						var entity:Entity;						for(i = 0; i < game.portals.length; i++){				entity = game.portals[i];				if(entity.gfx.visible) entity.render();			}						blockRect.x = bitmap.x;			blockRect.y = bitmap.y;			point.x = point.y = 0;			bitmapData.copyPixels(blockBitmapData, blockRect, point, null, null, true);						for(i = 0; i < game.chaosWalls.length; i++){				entity = game.chaosWalls[i];				if(entity.gfx.visible) entity.render();			}						game.mapTileManager.main();						if(game.map.type != Map.AREA) game.lightMap.main();						for(i = 0; i < game.items.length; i++){				entity = game.items[i];				if(entity.gfx.visible) entity.render();			}						for(i = 0; i < game.entities.length; i++){				entity = game.entities[i];				if(entity.gfx.visible) entity.render();			}						game.player.render();						for(i = 0; i < game.explosions.length; i++){				entity = game.explosions[i];				entity.render();			}						if(sceneManager) sceneManager.renderForeground();						if(fxSpawn.length){				fx = fx.concat(fxSpawn);				fxSpawn.length = 0;			}			if(fx.length) fx = fx.filter(fxFilterCallBack);						if(game.suggestion.active) game.suggestion.render();						if(game.editor.active) game.editor.render();						if(gifBuffer.active) gifBuffer.record(				game.player.gfx.x - 40,				game.player.gfx.y - 38			);					}				/* Shake the screen in any direction */		public function shake(x:int, y:int, shakeSource:Pixel = null):void {			// sourced shakes drop off in intensity by distance			// it stops the player feeling like they're in a cocktail shaker			if(shakeSource){				var dist:Number = Math.abs(game.player.mapX - shakeSource.x) + Math.abs(game.player.mapY - shakeSource.y);				if(dist >= SHAKE_DIST_MAX) return;				x = x * (SHAKE_DIST_MAX - dist) * INV_SHAKE_DIST_MAX;				y = y * (SHAKE_DIST_MAX - dist) * INV_SHAKE_DIST_MAX;				if(x == 0 && y == 0) return;			}			// ignore lesser shakes			if(Math.abs(x) < Math.abs(shakeOffset.x)) return;			if(Math.abs(y) < Math.abs(shakeOffset.y)) return;			shakeOffset.x = x;			shakeOffset.y = y;			shakeDirX = x > 0 ? 1 : -1;			shakeDirY = y > 0 ? 1 : -1;		}				/* resolve the shake */		private function updateShaker():void {			// shake first			if(shakeOffset.y != 0){				shakeOffset.y = -shakeOffset.y;				if(shakeDirY == 1 && shakeOffset.y > 0) shakeOffset.y--;				if(shakeDirY == -1 && shakeOffset.y < 0) shakeOffset.y++;			}			if(shakeOffset.x != 0){				shakeOffset.x = -shakeOffset.x;				if(shakeDirX == 1 && shakeOffset.x > 0) shakeOffset.x--;				if(shakeDirX == -1 && shakeOffset.x < 0) shakeOffset.x++;			}		}				/* Add to list */		public function addFX(x:Number, y:Number, blit:BlitRect, dir:Point = null, delay:int = 0, spawn:Boolean = false):FX{			var item:FX = new FX(x, y, blit, bitmapData, bitmap, dir, delay);			if(spawn) fxSpawn.push(item);			else fx.push(item);			return item;		}		/* Add to list */		public function addDebris(x:Number, y:Number, blit:BlitRect, vx:Number = 0, vy:Number = 0, print:BlitRect = null, smear:Boolean = false, spawn:Boolean = false):DebrisFX{			var item:DebrisFX;			item = new DebrisFX(x, y, blit, bitmapData, bitmap, print, smear);			item.addVelocity(vx, vy);			if(spawn) fx.push(item);			else fxSpawn.push(item);			return item;		}				/* Fill a rect with fading teleport sparks that drift upwards */		public function createSparkRect(rect:Rectangle, quantity:int):void{			var x:Number, y:Number, spark:FadingBlitRect, item:FX;			for(var i:int = 0; i < quantity; i++){				x = rect.x + game.random.range(rect.width);				y = rect.y + game.random.range(rect.height);				spark = game.random.coinFlip() ? teleportSparkSmallFadeBlit : teleportSparkBigFadeBlit;				item = addFX(x, y, spark, new Point(0, -game.random.value()));				item.frame = game.random.range(spark.totalFrames);			}		}				/* Fill a rect with debris particles */		public function createDebrisRect(rect:Rectangle, vx:Number, quantity:int, type:int):void{			var x:Number, y:Number, blit:BlitRect, print:BlitRect;			for(var i:int = 0; i < quantity; i++){				x = rect.x + game.random.range(rect.width);				y = rect.y + game.random.range(rect.height);				if(game.random.coinFlip()){					blit = smallDebrisBlits[type];					print = smallFadeBlits[type];				} else {					blit = bigDebrisBlits[type];					print = bigFadeBlits[type];				}				addDebris(x, y, blit, vx + game.random.range(vx) , -game.random.range(5.5), print, true);			}		}				/* Fill a rect with particles and let them fly */		public function createDebrisExplosion(rect:Rectangle, speed:Number, quantity:int, type:int):void{			var x:Number, y:Number, vx:Number, vy:Number, blit:BlitRect, print:BlitRect;			for(var i:int = 0; i < quantity; i++){				x = rect.x + game.random.range(rect.width);				y = rect.y + game.random.range(rect.height);				if(game.random.coinFlip()){					blit = smallDebrisBlits[type];					print = smallFadeBlits[type];				} else {					blit = bigDebrisBlits[type];					print = bigFadeBlits[type];				}				vx = game.random.coinFlip() ? -speed : speed;				vy = game.random.coinFlip() ? -speed : speed;				addDebris(x, y, blit, game.random.range(vx), -3.5 + game.random.range(vy), print, true);			}		}				/* Throw some debris particles out */		public function createDebrisSpurt(x:Number, y:Number, vx:Number, quantity:int, type:int):void{			var blit:BlitRect, print:BlitRect;			for(var i:int = 0; i < quantity; i++){				if(game.random.coinFlip()){					blit = smallDebrisBlits[type];					print = smallFadeBlits[type];				} else {					blit = bigDebrisBlits[type];					print = bigFadeBlits[type];				}				addDebris(x, y, blit, vx + game.random.range(vx) , -game.random.range(4.5), print, true);			}		}		/* Throw some sparks out */		public function createSparks(x:Number, y:Number, dx:Number, dy:Number, quantity:int):void{			for(var i:int = 0; i < quantity; i++){				addDebris(x, y, sparkBlit,					dx + (-dy + game.random.range(dy * 2) * game.random.range(5)),					dy + ( -dx + game.random.range(dx * 2) * game.random.range(5))				);			}		}				/* Add to list */		public function addDripFX(rect:Rectangle, quantity:int, type:int):void{			var blit:BlitRect, print:BlitRect, item:DripFX;			for(var i:int = 0; i < quantity; i++){				if(game.random.coinFlip()){					blit = smallDebrisBlits[type];					print = smallFadeBlits[type];				} else {					blit = bigDebrisBlits[type];					print = bigFadeBlits[type];				}				fx.push(new DripFX(rect.x + game.random.range(rect.width), rect.y + game.random.range(rect.height), blit, bitmapData, bitmap, print, rect));			}		}				/* Throw some fireballs out		public function createFireBalls(x:Number, y:Number, quantity:int):void{			var step:int = 360 / quantity;			while(quantity--){				fireBallAngle += step + Math.random() * step;				if(fireBallAngle >= 360) fireBallAngle -= 360;				addDebris(x, y, fireBallBlit, Trig.cos[fireBallAngle] * 5, -5 + Trig.sin[fireBallAngle] * 5, true, false, true);			}		}*/			}}