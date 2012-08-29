package com.robotacid.engine {
	import com.robotacid.ai.BalrogBrain;
	import com.robotacid.ai.Brain;
	import com.robotacid.geom.Pixel;
	import com.robotacid.phys.Collider;
	import com.robotacid.ui.MinimapFX;
	import flash.display.DisplayObject;
	
	/**
	 * The end game boss
	 * 
	 * Designed to kill the player indirectly
	 * 
	 * Can destroy Gates and ChaosWalls on contact
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Balrog extends Character {
		
		public var mapInitialised:Boolean;
		public var levelState:int;
		public var portalContact:Portal;
		public var exitLevelCount:int;
		public var consumedPlayer:Boolean;
		
		private var minimapFX:MinimapFX;
		
		public static const DEFAULT_LIGHT_RADIUS:int = 3;
		public static const DEFAULT_UNIQUE_NAME_STR:String = "the balrog";
		
		// level states
		public static const STAIRS_DOWN_TAUNT:int = 0;
		public static const ENTER_STAIRS_UP:int = 1;
		public static const WANDER_LEVEL:int = 2;
		public static const RESURRECT:int = 3;
		
		public function Balrog(gfx:DisplayObject, items:Vector.<Item>, levelState:int){
			rank = ELITE;
			
			super(gfx, SCALE, SCALE, BALROG, MONSTER, 1, false);
			
			// init states
			this.levelState = levelState;
			dir = RIGHT;
			actions = 0;
			looking = RIGHT;
			active = true;
			callMain = false;
			uniqueNameStr = DEFAULT_UNIQUE_NAME_STR;
			missileIgnore |= Collider.MONSTER | Collider.MONSTER_MISSILE;
			addToEntities = true;
			gfx.visible = false;
			
			brain = new BalrogBrain(this);
			
			if(items) loot = items;
		}
		
		/* Called on the balrog's first main() after all initialisation is done */
		public function mapInit():void{
			mapInitialised = true;
			if(game.player.active) level = game.player.level;
			else{
				levelState = RESURRECT;
				brain.state = Brain.PATROL;
			}
			setStats();
			if(UserData.gameState.balrog.health) health = UserData.gameState.balrog.health;
			// levelState determines where the balrog will start in the level
			// Game.setLevel handles the ENTER_STAIRS_UP state, sending the balrog into the
			// level before the player to emphasise the chase
			if(levelState != ENTER_STAIRS_UP){
				if(levelState == STAIRS_DOWN_TAUNT){
					Effect.teleportCharacter(this, game.map.stairsDown, true);
				} else if(levelState == WANDER_LEVEL){
					Effect.teleportCharacter(this, game.map.stairsUp, true);
					Effect.teleportCharacter(this, null, true);
				}
				game.world.restoreCollider(collider);
				collider.state = Collider.FALL;
				state = WALKING;
			}
			if(loot){
				var item:Item;
				for(var i:int = 0; i < loot.length; i++){
					item = loot[i];
					if((!weapon && item.type == Item.WEAPON) || (!armour && item.type == Item.ARMOUR && item.name != Item.INDIFFERENCE)){
						equip(item);
					} else if(!throwable && item.type == Item.WEAPON && (item.range & Item.THROWN)){
						equip(item, true);
					}
					if(weapon && armour && throwable) break;
				}
			}
			game.lightMap.setLight(this, DEFAULT_LIGHT_RADIUS);
			Brain.monsterCharacters.push(this);
		}
		
		override public function createCollider(x:Number, y:Number, properties:int, ignoreProperties:int, state:int = 0, positionByBase:Boolean = true):void {
			super.createCollider(x, y, properties, ignoreProperties, state, positionByBase);
			collider.properties |= Collider.MONSTER | Collider.BALROG;
			collider.ignoreProperties |= Collider.MONSTER_MISSILE | Collider.HORROR | Collider.MONSTER;
			collider.stompProperties = Collider.PLAYER | Collider.MINION;
		}
		
		public function addMinimapFeature():void{
			minimapFX = game.miniMap.addFeature(mapX, mapY, renderer.balrogFeatureBlit);
		}
		
		override public function main():void {
			var i:int;
			
			if(!mapInitialised){
				mapInit();
			}
			// the balrog destroys gates he comes into contact with
			// this helps him escape
			var touching:Collider = collider.leftContact || collider.rightContact;
			if(touching && (touching.properties & Collider.GATE)){
				(touching.userData as Gate).death();
			}
			
			tileCenter = (mapX + 0.5) * SCALE;
			if(state == WALKING || state == LUNGING) brain.main();
			super.main();
			minimapFX.x = mapX;
			minimapFX.y = mapY;
			
			// update exiting a level
			if(state == EXITING){
				// capture the exit direction before we clear the reference to the portal
				var exitDir:int = portal.targetLevel > game.map.level ? 1 : -1;
				var portalType:int = portal.type;
				var portalTargetLevel:int = portal.targetLevel;
				var portalTargetType:int = portal.targetType;
				moving = true;
				if(portal.type == Portal.STAIRS){
					if(portal.targetLevel > game.map.level){
						if(moveCount){
							if(dir == RIGHT) gfx.x += STAIRS_SPEED;
							else if(dir == LEFT) gfx.x -= STAIRS_SPEED;
							gfx.y += STAIRS_SPEED;
						}
						if(gfx.y >= (portal.mapY + 1) * Game.SCALE + PORTAL_DISTANCE) portal = null;
					} else if(portal.targetLevel < game.map.level){
						if(moveCount){
							if(dir == RIGHT) gfx.x += STAIRS_SPEED;
							else if(dir == LEFT) gfx.x -= STAIRS_SPEED;
							gfx.y -= STAIRS_SPEED;
						}
						if(gfx.y <= (portal.mapY + 1) * Game.SCALE - PORTAL_DISTANCE) portal = null;
					}
				} else {
					if(dir == RIGHT){
						gfx.x += speed * collider.dampingX;
						if(gfx.x > (portal.mapX + 1) * Game.SCALE + PORTAL_DISTANCE) portal = null;
					} else if(dir == LEFT){
						gfx.x -= speed * collider.dampingX;
						if(gfx.x < portal.mapX * Game.SCALE - PORTAL_DISTANCE) portal = null;
					}
				}
				// LEVEL TRANSITION CODE ====================================================================
				// 
				// This occurs in the balrog class because he is an asshole that doesn't like to fight fair
				
				if(!portal){
					
					// tell the player about the balrog's escape
					game.console.print(nameToString() + " " + Portal.usageMsg(portalType, portalTargetLevel, portalTargetType));
					game.balrog.active = false;
					minimapFX.active = false;
					game.balrog = null;
					return;
					
				}
			} else {
				if(portalContact){
					if(
						state != Character.WALKING ||
						!(
							portalContact.rect.x + portalContact.rect.width > collider.x &&
							collider.x + collider.width > portalContact.rect.x &&
							portalContact.rect.y + portalContact.rect.height > collider.y &&
							collider.y + collider.height > portalContact.rect.y
						)
					){
						portalContact = null;
					} else {
						// the decision to exit is made in BalrogBrain
						if(exitLevelCount == game.frameCount){
							exitLevel(portalContact);
						}
					}
					
				} else {
					// check for portals
					var portalCheck:Portal;
					
					for(i = 0; i < game.portals.length; i++){
						portalCheck = game.portals[i];
						if(
							portalCheck.type == Portal.STAIRS &&
							portalCheck.targetLevel > game.map.level &&
							state == Character.WALKING &&
							portalCheck.rect.x + portalCheck.rect.width > collider.x &&
							collider.x + collider.width > portalCheck.rect.x &&
							portalCheck.rect.y + portalCheck.rect.height > collider.y &&
							collider.y + collider.height > portalCheck.rect.y
						){
							if(!portalContact){
								portalContact = portalCheck;
								break;
							}
						}
					}
				}
			}
		}
		
		public function exitLevel(portal:Portal):void{
			this.portal = portal;
			gfx.x = (portal.mapX + 0.5) * Game.SCALE;
			state = EXITING;
			// prepare content state for next level
			levelState = ENTER_STAIRS_UP;
			UserData.gameState.balrog.mapLevel++;
			UserData.gameState.balrog.xml = toXML();
			UserData.gameState.balrog.health = health;
			if(portal.targetLevel < game.map.level){
				dir = looking = LEFT;
			} else if(portal.targetLevel > game.map.level){
				dir = looking = RIGHT;
			} else {
				dir = looking & (LEFT | RIGHT);
			}
			game.world.removeCollider(collider);
			// stop the player ledge-dropping when entering the new area
			collider.ignoreProperties &= ~Collider.LEDGE;
		}
		
		override public function applyDamage(n:Number, source:String, knockback:Number = 0, critical:Boolean = false, aggressor:Character = null, defaultSound:Boolean = true):void {
			super.applyDamage(n, source, knockback, critical, aggressor, defaultSound);
			// bleed effects on multiple characters could cause the bar to flicker between victims,
			// so we focus on the last person who was attacked physically
			if(active && this == game.player.victim){
				game.enemyHealthBar.setValue(health, totalHealth);
				game.enemyHealthBar.activate();
			}
		}
		
		override public function death(cause:String = "crushing", decapitation:Boolean = false, aggressor:Character = null):void {
			if(!active) return;
			for(var i:int = 0; i < loot.length; i++){
				if(loot[i].location == Item.EQUIPPED){
					unequip(loot[i]);
				}
				loot[i].dropToMap(mapX, mapY);
			}
			loot = new Vector.<Item>();
			
			// the balrog is always decapitated - his face is a magic item: it bricks the game if you wear it
			super.death(cause, true);
			
			// the balrog explodes on death
			var explosion:Explosion = new Explosion(0, mapX, mapY, 5, totalHealth, game.player, null, game.player.missileIgnore);
			
			game.enemyHealthBar.deactivate();
			
			Brain.monsterCharacters.splice(Brain.monsterCharacters.indexOf(this), 1);
			if(--game.map.completionCount == 0) game.levelComplete();
			
			minimapFX.active = false;
			game.balrog = null;
			UserData.gameState.balrog = false;
		}
		
		public function snapCamera():void{
			renderer.camera.setTarget(
				collider.x + collider.width * 0.5,
				collider.y
			);
			renderer.camera.skipPan();
		}
		
		override public function toXML():XML {
			var xml:XML = super.toXML();
			if(loot.length){
				for(var i:int = 0; i < loot.length; i++){
					xml.appendChild(loot[i].toXML());
				}
			}
			xml.@levelState = levelState;
			return xml;
		}
		
	}

}