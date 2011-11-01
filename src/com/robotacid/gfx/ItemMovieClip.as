package com.robotacid.gfx {
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Item;
	import com.robotacid.engine.Monster;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class ItemMovieClip extends MovieClip {
		
		public static var g:Game;
		public static var renderer:Renderer;
		
		// in extending MovieClip we get a conflict with "name"
		public var _name:int;
		public var _type:int;
		
		public var gfx:DisplayObject;
		public var buffer:BitmapData;
		private var bufferLoaded:Boolean;
		
		public static var bitmapData:BitmapData;
		public static var characterMask:BitmapData;
		public static var point:Point = new Point();
		public static var rect:Rectangle;
		public static var p:Point = new Point();
		public static var dx:Number;
		public static var dy:Number;
		
		public static var vx:Number;
		public static var vy:Number;
		
		public static const CAPTURE_WIDTH:int = 18;
		public static const CAPTURE_HEIGHT:int = 18;
		
		public function ItemMovieClip(name:int, type:int) {
			this._name = name;
			this._type = type;
			
			if(type == Item.ARMOUR){
				if(name == Item.BLOOD){
					gfx = new BloodMC();
					addChild(gfx);
				} else if(name == Item.SKULL){
					gfx = new SkullMC();
					addChild(gfx);
				} else if(name == Item.INVISIBILITY){
					buffer = new BitmapData(CAPTURE_WIDTH, CAPTURE_HEIGHT, true, 0x00000000);
					bufferLoaded = false;
				} else if(name == Item.GOGGLES){
					gfx = new GogglesMC();
					addChild(gfx);
				}
			} else if(type == Item.WEAPON){
				if(name == Item.SHORT_BOW){
					gfx = new ShortBowMC();
					addChild(gfx);
				} else if(name == Item.LEECH_WEAPON){
					gfx = new LeechMC();
					addChild(gfx);
				}
			}
		}
		
		public static function init():void{
			characterMask = new BitmapData(CAPTURE_WIDTH, CAPTURE_HEIGHT, true, 0x00000000);
			bitmapData = new BitmapData(CAPTURE_WIDTH, CAPTURE_HEIGHT, true, 0x00000000);
			rect = new Rectangle(0, 0, CAPTURE_WIDTH, CAPTURE_HEIGHT);
			dx = -CAPTURE_WIDTH * 0.5;
			dy = -CAPTURE_HEIGHT + 1;
		}
		
		/* Called before dropping the item to the floor */
		public function setDropRender():void{
			var mc:MovieClip = gfx as MovieClip;
			
			if(_type == Item.ARMOUR){
				if(_name == Item.SKULL){
					if(mc.currentLabel != "idle") mc.gotoAndStop("idle");
				} else if(_name == Item.GOGGLES){
					if(mc.currentLabel != "idle") mc.gotoAndStop("idle");
				}
			} else if(_type == Item.WEAPON){
				if(_name == Item.SHORT_BOW){
					if(mc.currentLabel != "idle") mc.gotoAndStop("idle");
				} else if(_name == Item.LEECH_WEAPON){
					if(mc.currentLabel != "idle") mc.gotoAndStop("idle");
				}
			}
		}
		
		/* Called before equipping the item to the floor */
		public function setEquipRender():void{
			if(_type == Item.ARMOUR){
				if(_name == Item.INVISIBILITY){
					bufferLoaded = false;
				}
			}
		}
		
		/* Called by the wielding Character.render() to apply the special animations the item requires */
		public function render(character:Character, characterMc:MovieClip):void{
			var mc:MovieClip = gfx as MovieClip;
			
			if(_type == Item.ARMOUR){
				if(_name == Item.BLOOD){
					if(character.state != Character.EXITING && character.state != Character.ENTERING){
						if(g.frameCount){
							var blit:BlitRect, print:BlitRect;
							if(g.random.value() < 0.5){
								blit = renderer.smallDebrisBlits[Renderer.BLOOD];
								print = renderer.smallFadeBlits[Renderer.BLOOD];
							} else {
								blit = renderer.bigDebrisBlits[Renderer.BLOOD];
								print = renderer.bigFadeBlits[Renderer.BLOOD];
							}
							renderer.addDebris(character.collider.x + character.collider.width * 0.5, (character.collider.y + character.collider.height) - g.random.range(gfx.height), blit, (-3 + g.random.range(6)), (-3 - g.random.range(5)), print, true);
						}
					}
				} else if(_name == Item.SKULL){
					if(mc.currentLabel != characterMc.currentLabel) mc.gotoAndStop(characterMc.currentLabel);
					
				} else if(_name == Item.GOGGLES){
					if(mc.currentLabel != characterMc.currentLabel) mc.gotoAndStop(characterMc.currentLabel);
					
				} else if(_name == Item.INVISIBILITY){
					if(character.state != Character.EXITING && character.state != Character.ENTERING){
						point.x = -renderer.bitmap.x + (parent.x + dx);
						point.y = -renderer.bitmap.y + (parent.y + dy);
						if(
							point.x + bitmapData.width > 0 && point.y + bitmapData.height > 0 &&
							point.x < renderer.bitmapData.width && point.y < renderer.bitmapData.height
						){
							parent.visible = true;
							characterMask.fillRect(characterMask.rect, 0x00000000);
							characterMask.draw(parent, new Matrix(parent.scaleX, 0, 0, 1, -dx, -dy));
							parent.visible = false;
							
							buffer.copyPixels(bitmapData, bitmapData.rect, p);
							rect.x = (parent.x + dx) - renderer.bitmap.x;
							rect.y = (parent.y + dy) - renderer.bitmap.y;
							bitmapData.draw(renderer.backgroundShape, new Matrix(1, 0, 0, 1, -rect.x, -rect.y));
							bitmapData.copyPixels(renderer.bitmapData, rect, p, null, null, true);
							bitmapData.copyChannel(characterMask, bitmapData.rect, p, BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
							
							if(bufferLoaded) renderer.bitmapData.copyPixels(buffer, bitmapData.rect, point, null, null, true);
							else bufferLoaded = true;
						}
					} else {
						parent.visible = false;
					}
				}
				
			} else if(_type == Item.WEAPON){
				if(_name == Item.SHORT_BOW){
					if(mc.currentLabel != characterMc.currentLabel) mc.gotoAndStop(characterMc.currentLabel);
					
				} else if(_name == Item.LEECH_WEAPON){
					if(mc.currentLabel != characterMc.currentLabel) mc.gotoAndStop(characterMc.currentLabel);
				}
			}
		}
		
	}

}