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
		
		private var minimapFX:MinimapFX;
		
		public static const DEFAULT_LIGHT_RADIUS:int = 5;
		public static const DEFAULT_UNIQUE_NAME_STR:String = "the balrog";
		
		// level states
		public static const STAIRS_DOWN_TAUNT:int = 0;
		public static const ENTER_STAIRS_UP:int = 1;
		public static const WANDER_LEVEL:int = 2;
		
		// to do
		// set stairs down taunt from content - set to wander level during level - set to enter stairs up when escaped
		
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
			
			brain = new BalrogBrain(this);
			
			if(items) loot = items;
		}
		
		public function addMinimapFeature():void{
			minimapFX = game.miniMap.addFeature(mapX, mapY, renderer.minionFeatureBlit);
		}
		
		override public function main():void {
			if(!mapInitialised){
				mapInit();
			}
			// the balrog destroys chaos walls and gates he comes into contact with
			// this helps him escape as well as generate golems to harry the player
			var touching:Collider = collider.getContact();
			if(touching && (touching.properties & (Collider.CHAOS | Collider.GATE))){
				if(touching.userData is Gate){
					(touching.userData as Gate).death();
				} else if(touching.userData is ChaosWall){
					(touching.userData as ChaosWall).crumble();
				}
			}
			
			tileCenter = (mapX + 0.5) * SCALE;
			if(state == WALKING || state == LUNGING) brain.main();
			super.main();
			
			/*
			// update exiting a level
			if(state == EXITING){
				// capture the exit direction before we clear the reference to the portal
				var exitDir:int = portal.targetLevel > game.map.level ? 1 : -1;
				var portalType:int = portal.type;
				var portalTargetLevel:int = portal.targetLevel;
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
				// LEVEL TRANSITION CODE ====================================================================================
				// 
				// This occurs in the player class because the player is the one who has control over the game visiting levels
				//
				if(!portal){
					
					// tell the player about the new level / area
					game.console.print(Portal.usageMsg(portalType, portalTargetLevel));
					var targetArea:int = Map.MAIN_DUNGEON;
					if((portalType == Portal.STAIRS && portalTargetLevel == 0) || portalType == Portal.OVERWORLD || portalType == Portal.UNDERWORLD) targetArea = Map.AREA;
					else if(portalType == Portal.ITEM) targetArea = Map.ITEM_DUNGEON;
					var levelName:String = Map.getName(targetArea, portalTargetLevel);
					if(!game.visitedHash[levelName]) game.visitedHash[levelName] = true;
					else levelName = "";
					
					game.transition.init(function():void{
						game.setLevel(portalTargetLevel, portalType);
						// warm up the renderer
						renderer.main();
						if(game.map.type != Map.AREA){
							for(i = 0; i < 8; i++){
								game.lightMap.main();
							}
							game.miniMap.render();
						}
					}, null, levelName);
				}
			} else {
				if(portalContact){
					// restore access to menu after entering level
					if(collider.world && !game.gameMenu.actionsOption.active){
						game.gameMenu.actionsOption.active = true;
						game.gameMenu.inventoryOption.active = Boolean(game.gameMenu.inventoryList.options.length);
						game.gameMenu.update();
					}
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
						// Cave Story style doorway access - clean down press
						if(dir == DOWN && exitKeyPressReady){
							openExitDialog();
						}
					}
					
				} else {
					// check for portals
					var portal:Portal;
					
					for(i = 0; i < game.portals.length; i++){
						portal = game.portals[i];
						if(
							portal.playerPortal &&
							state == Character.WALKING &&
							portal.rect.x + portal.rect.width > collider.x &&
							collider.x + collider.width > portal.rect.x &&
							portal.rect.y + portal.rect.height > collider.y &&
							collider.y + collider.height > portal.rect.y
						){
							if(!portalContact){
								portalContact = portal;
								break;
							}
						}
					}
				}
			}*/
		}
		
		/* Called on the balrog's first main() after all initialisation is done */
		public function mapInit():void{
			mapInitialised = true;
			level = game.player.level;
			setStats();
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
			// levelState determines where the balrog will start in the level
			// Game.setLevel handles the ENTER_STAIRS_UP state, sending the balrog into the
			// level before the player to emphasise the chase
			if(levelState == WANDER_LEVEL || levelState == STAIRS_DOWN_TAUNT){
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
			game.lightMap.setLight(this, DEFAULT_LIGHT_RADIUS);
			Brain.monsterCharacters.push(this);
		}
		
		override public function toXML():XML {
			var xml:XML = super.toXML();
			xml.@levelState = levelState;
			return xml;
		}
		
	}

}