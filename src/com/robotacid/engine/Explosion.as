package com.robotacid.engine {
	import com.robotacid.gfx.BlitClip;
	import com.robotacid.phys.Collider;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * An entity that copies itself to adjacent squares like a flood fill, then applies effects to characters
	 * 
	 * With each copy, damage is applied, during expansion, push is applied
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Explosion extends Entity {
		
		public var id:int;
		public var damage:Number;
		public var sender:Character;
		public var item:Item;
		public var ignore:int;
		
		private var count:int;
		private var dirs:int;
		private var expandFrame:int;
		
		public static var idCount:int = 1;
		public static var mapWidth:int;
		public static var mapHeight:int;
		public static var map:Vector.<Vector.<int>>;
		
		// temp
		private static var i:int;
		private static var getRect:Rectangle = new Rectangle(0, 0, SCALE * 3, SCALE * 3);
		private static var pushRect:Rectangle = new Rectangle(0, 0, SCALE, SCALE);
		
		public static const WALL:int = -1;
		public static const EXPAND_SPAWN:int = 8;
		public static const EXPAND_TOTAL_FRAMES:int = 11;
		public static const EXPAND_SPEED:Number = 2;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		public static const SOUNDS:Array = ["bomb1", "bomb2", "bomb3"];
		
		public function Explosion(id:int, mapX:int, mapY:int, delay:int, damage:Number, sender:Character = null, item:Item = null, ignore:int = 0) {
			super(null, true, false);
			
			// initial blasts are submitted with the id:0 and generate light
			if(id == 0){
				id = idCount++;
				game.lightMap.setLight(this, EXPAND_TOTAL_FRAMES);
			}
			this.id = id;
			this.mapX = mapX;
			this.mapY = mapY;
			map[mapY][mapX] = id;
			count = delay;
			this.damage = damage;
			this.sender = sender;
			this.item = item;
			this.ignore = ignore;
			expandFrame = 0;
			callMain = true;
			active = true;
			
			// get available expansion sites
			if(delay > 0){
				if(mapY > 0 && !((game.world.map[mapY - 1][mapX] & DOWN) || map[mapY - 1][mapX] == id)) dirs |= UP;
				if(mapX < mapWidth - 1 && !((game.world.map[mapY][mapX + 1] & LEFT) || map[mapY][mapX + 1] == id)) dirs |= RIGHT;
				if(mapY < mapHeight - 1 && !((game.world.map[mapY + 1][mapX] & UP) || map[mapY + 1][mapX] == id)) dirs |= DOWN;
				if(mapX > 0 && !((game.world.map[mapY][mapX - 1] & RIGHT) || map[mapY][mapX - 1] == id)) dirs |= LEFT;
			}
			// apply effects / damage to characters in tile
			pushRect.x = mapX * SCALE;
			pushRect.y = mapY * SCALE;
			var colliders:Vector.<Collider> = game.world.getCollidersIn(pushRect, null, Collider.CHARACTER, Collider.HEAD | Collider.STONE | Collider.CHAOS | ignore);
			var character:Character, effect:Effect;
			for(i = 0; i < colliders.length; i++){
				character = colliders[i].userData as Character;
				if(character && character.active){
					if(character.type == Character.GATE){
						character.death("explosion");
						game.console.print("gate destroyed by explosion");
						
					} else if(
						character.state != Character.QUICKENING &&
						character.state != Character.ENTERING &&
						character.state != Character.EXITING
					){
						if(item && item.effects && character.active){
							character.applyWeaponEffects(item);
						}
						// damage
						var hitDamage:Number = damage;
						if(character.protectionModifier < 1){
							hitDamage *= character.protectionModifier < Character.MIN_PROTECTION_MODIFIER ? Character.MIN_PROTECTION_MODIFIER : character.protectionModifier;
						}
						// blessed weapon? roll for smite
						if(item && item.holyState == Item.BLESSED && game.random.value() < Character.SMITE_PER_LEVEL * item.level){
							character.smite((character.looking & Collider.LEFT) ? Collider.RIGHT : Collider.LEFT, hitDamage * 0.5);
							// half of hitDamage is transferred to the smite state
							hitDamage *= 0.5;
						}
						// leech
						if(sender && (sender.leech || (item && item.leech)) && !(character.armour && character.armour.name == Item.BLOOD)){
							var leechValue:Number = sender.leech + (item ? item.leech : 0);
							if(leechValue > 1) leechValue = 1;
							leechValue *= hitDamage;
							if(leechValue > character.health) leechValue = character.health;
							sender.applyHealth(leechValue);
						}
						// apply damage
						character.applyDamage(hitDamage, "explosion", 0, false, sender);
						// blood
						renderer.createDebrisExplosion(character.collider, 5, 20, character.debrisType);
					}
				}
			}
			game.explosions.push(this);
			renderer.shake(0, 5);
			game.soundQueue.addRandom("smite", SOUNDS, 10);
		}
		
		override public function main():void {
			if(expandFrame >= EXPAND_TOTAL_FRAMES){
				active = false;
			} else {
				if(light){
					game.lightMap.setLight(this, EXPAND_TOTAL_FRAMES - expandFrame);
				}
				if(dirs){
					// push colliders
					var colliders:Vector.<Collider>;
					var collider:Collider;
					getRect.x = (mapX - 1) * SCALE;
					getRect.y = (mapY - 1) * SCALE;
					colliders = game.world.getCollidersIn(getRect, null, Collider.CHARACTER, Collider.HEAD | Collider.STONE | Collider.CHAOS | Collider.GATE);
					for(i = 0; i < colliders.length; i++){
						collider = colliders[i];
						if(dirs & UP){
							pushRect.x = mapX * SCALE;
							pushRect.y = (mapY - 1) * SCALE;
							if(
								collider.x + collider.width > pushRect.x &&
								pushRect.x + pushRect.width > collider.x &&
								collider.y + collider.height > pushRect.y &&
								pushRect.y + pushRect.height > collider.y
							){
								collider.vy -= EXPAND_SPEED;
								collider.awake = Collider.AWAKE_DELAY;
							}
						}
						if(dirs & RIGHT){
							pushRect.x = (mapX + 1) * SCALE;
							pushRect.y = mapY * SCALE;
							if(
								collider.x + collider.width > pushRect.x &&
								pushRect.x + pushRect.width > collider.x &&
								collider.y + collider.height > pushRect.y &&
								pushRect.y + pushRect.height > collider.y
							){
								collider.vx += EXPAND_SPEED;
								collider.awake = Collider.AWAKE_DELAY;
							}
						}
						if(dirs & DOWN){
							pushRect.x = mapX * SCALE;
							pushRect.y = (mapY + 1) * SCALE;
							if(
								collider.x + collider.width > pushRect.x &&
								pushRect.x + pushRect.width > collider.x &&
								collider.y + collider.height > pushRect.y &&
								pushRect.y + pushRect.height > collider.y
							){
								collider.vy += EXPAND_SPEED;
								collider.awake = Collider.AWAKE_DELAY;
							}
						}
						if(dirs & LEFT){
							pushRect.x = (mapX - 1) * SCALE;
							pushRect.y = mapY * SCALE;
							if(
								collider.x + collider.width > pushRect.x &&
								pushRect.x + pushRect.width > collider.x &&
								collider.y + collider.height > pushRect.y &&
								pushRect.y + pushRect.height > collider.y
							){
								collider.vx -= EXPAND_SPEED;
								collider.awake = Collider.AWAKE_DELAY;
							}
						}
					}
					// create new explosions
					if(expandFrame == EXPAND_SPAWN){
						var explosion:Explosion;
						if(dirs & UP) explosion = new Explosion(id, mapX, mapY - 1, count - 1, damage, sender, item, ignore);
						if(dirs & RIGHT) explosion = new Explosion(id, mapX + 1, mapY, count - 1, damage, sender, item, ignore);
						if(dirs & DOWN) explosion = new Explosion(id, mapX, mapY + 1, count - 1, damage, sender, item, ignore);
						if(dirs & LEFT) explosion = new Explosion(id, mapX - 1, mapY, count - 1, damage, sender, item, ignore);
					}
				}
				expandFrame++;
			}
		}
		
		override public function render():void {
			var cx:Number = -renderer.bitmap.x + (mapX + 0.5) * SCALE;
			var cy:Number = -renderer.bitmap.y + (mapY + 0.5) * SCALE;
			renderer.explosionBlit.x = cx;
			renderer.explosionBlit.y = cy;
			renderer.explosionBlit.render(renderer.bitmapData, expandFrame);
			if(expandFrame < renderer.explosionDirBlits[0].totalFrames){
				if(dirs & UP){
					renderer.explosionDirBlits[0].x = cx;
					renderer.explosionDirBlits[0].y = cy - EXPAND_SPEED * expandFrame;
					renderer.explosionDirBlits[0].render(renderer.bitmapData, expandFrame);
				}
				if(dirs & RIGHT){
					renderer.explosionDirBlits[1].x = cx + EXPAND_SPEED * expandFrame;
					renderer.explosionDirBlits[1].y = cy;
					renderer.explosionDirBlits[1].render(renderer.bitmapData, expandFrame);
				}
				if(dirs & DOWN){
					renderer.explosionDirBlits[2].x = cx;
					renderer.explosionDirBlits[2].y = cy + EXPAND_SPEED * expandFrame;
					renderer.explosionDirBlits[2].render(renderer.bitmapData, expandFrame);
				}
				if(dirs & LEFT){
					renderer.explosionDirBlits[3].x = cx - EXPAND_SPEED * expandFrame;
					renderer.explosionDirBlits[3].y = cy;
					renderer.explosionDirBlits[3].render(renderer.bitmapData, expandFrame);
				}
			}
		}
		
		public static function initMap(width:int, height:int):void{
			map = new Vector.<Vector.<int>>();
			var r:int, c:int;
			for(r = 0; r < height; r++){
				map[r] = new Vector.<int>();
				for(c = 0; c < width; c++){
					map[r][c] = 0;
				}
			}
			mapWidth = width;
			mapHeight = height;
		}
		
	}

}