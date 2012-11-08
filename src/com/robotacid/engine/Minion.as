package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.ai.PlayerBrain;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Item;
	import com.robotacid.geom.Pixel;
	import com.robotacid.level.Map;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.menu.GameMenu;
	import com.robotacid.ui.menu.InventoryMenuList;
	import com.robotacid.ui.MinimapFX;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	
	/**
	 * This is an undead character that follows the player around and attacks monsters on sight.
	 *
	 * Due to how annoying an obstruction the minion could be, at a point in development I set
	 * the minion to pass through the player. The minion then changed from barely useful and hazardous
	 * (crushing) to a welcome ally.
	 *
	 * options to customise your minion through spells and and equipment are in the InventoryMenuList and GameMenu
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Minion extends Character{
		
		public var inventory:InventoryMenuList;
		
		public var enterCount:int;
		public var queueSummons:Boolean;
		
		public var canMenuAction:Boolean;
		
		private var minimapFX:MinimapFX;
		
		public static const ENTER_DELAY:int = 30;
		public static const DEFAULT_UNIQUE_NAME_STR:String = "the minion";
		public static const REVEALED_UNIQUE_NAME_STR:String = "@";
		
		public function Minion(gfx:DisplayObject, x:Number, y:Number, name:int) {
			
			super(gfx, x, y, name, MINION, game.player.level, false);
			
			inventory = game.gameMenu.inventoryList;
			
			missileIgnore |= Collider.PLAYER | Collider.MINION | Collider.PLAYER_MISSILE;
			uniqueNameStr = Boolean(UserData.settings.loreUnlocked.races[SKELETON]) ? REVEALED_UNIQUE_NAME_STR : DEFAULT_UNIQUE_NAME_STR;
			
			//brain = game.multiplayer ? new PlayerBrain(this, game.player) : new Brain(this, Brain.PLAYER, game.player);
			setMultiplayer();
			Brain.playerCharacters.push(this);
			
			game.minionHealthBar.visible = true;
			game.minionHealthBar.setValue(health, totalHealth);
			game.gameMenu.summonOption.active = true;
			queueSummons = false;
			game.gameMenu.update();
		}
		
		public function addMinimapFeature():void{
			minimapFX = game.miniMap.addFeature(mapX, mapY, renderer.minionFeatureBlit);
		}
		
		override public function createCollider(x:Number, y:Number, properties:int, ignoreProperties:int, state:int = 0, positionByBase:Boolean = true):void {
			super.createCollider(x, y, properties, ignoreProperties, state, positionByBase);
			collider.properties |= Collider.MINION;
			collider.ignoreProperties |= Collider.PLAYER | Collider.MINION | Collider.PLAYER_MISSILE | Collider.HORROR;
			collider.stompProperties = Collider.MONSTER;
		}
		
		override public function main():void {
			if(enterCount){
				enterCount--;
				if(enterCount == 0){
					enterLevel(portal, Player.previousLevel < game.map.level ? Collider.RIGHT : Collider.LEFT);
				} else {
					return;
				}
			}
			// summons check
			if(state == WALKING && game.player.active && (queueSummons || !game.mapTileManager.intersects(collider, Game.SCALE * 2))){
				teleportToPlayer();
			}
			tileCenter = (mapX + 0.5) * SCALE;
			if((state == WALKING || state == LUNGING) && !asleep) brain.main();
			super.main();
			minimapFX.x = mapX;
			minimapFX.y = mapY;
			
			if(game.multiplayer){
				// check for menu action locking
				if(state == WALKING && attackCount >= 1){
					if(!canMenuAction) unlockMenuActions();
				} else {
					if(canMenuAction) lockMenuActions();
				}
			}
		}
		
		/* The minion waits for the player to finish using the stairs */
		public function prepareToEnter(portal:Portal):void{
			enterCount = ENTER_DELAY;
			this.portal = portal;
		}
		
		/* Select an item as a weapon or armour */
		override public function equip(item:Item, throwing:Boolean = false):Item {
			super.equip(item, throwing);
			if(item.holyState == Item.CURSE_HIDDEN) item.revealCurse();
			if(game.multiplayer){
				// set the active state and name of the minion missile option in the menu
				if(item.type == Item.WEAPON){
					game.gameMenu.minionMissileOption.active = (
						!indifferent && canMenuAction &&
						(
							(weapon && weapon.range & Item.MISSILE) ||
							(throwable && !(throwable.holyState == Item.CURSE_REVEALED && !undead))
						)
					);
					if(game.gameMenu.minionMissileOption.active){
						game.gameMenu.minionMissileOption.state = throwable ? GameMenu.THROW : GameMenu.SHOOT;
					}
				} else if(item.type == Item.ARMOUR){
					// update the menu if jumping is unlocked
					game.gameMenu.minionJumpOption.active = canJump;
				}
			}
			inventory.updateItem(item);
			return item;
		}
		
		/* Unselect item as equipped */
		override public function unequip(item:Item):Item{
			super.unequip(item);
			if(game.multiplayer && item.type == Item.ARMOUR){
				game.gameMenu.minionJumpOption.active = canJump;
			}
			inventory.updateItem(item);
			return item;
		}
		
		override public function applyDamage(n:Number, source:String, knockback:Number = 0, critical:Boolean = false, aggressor:Character = null, defaultSound:Boolean = true):void {
			super.applyDamage(n, source, knockback, critical, aggressor, defaultSound);
			game.minionHealthBar.setValue(health, totalHealth);
		}
		
		override public function applyHealth(n:Number):void {
			super.applyHealth(n);
			game.minionHealthBar.setValue(health, totalHealth);
		}
		
		override public function setAsleep(value:Boolean):void {
			super.setAsleep(value);
			if(!value && game.player.asleep){
				game.console.print("your minion is in danger");
				game.player.setAsleep(false);
			}
		}
		
		override public function finishQuicken():void {
			// the minion's transformation event ends at the end of a quickening
			super.finishQuicken();
		}
		
		/* This pulls the minion to the vicinity of the player */
		public function teleportToPlayer():void{
			queueSummons = false;
			Effect.teleportCharacter(this, new Pixel(game.player.mapX, game.player.mapY));
		}
		
		override public function death(cause:String = "crushing", decapitation:Boolean = false, aggressor:Character = null):void {
			if(!active) return;
			var temp_weapon:Item;
			var temp_throwable:Item;
			var temp_armour:Item;
			if(weapon) temp_weapon = unequip(weapon);
			if(throwable) temp_throwable = unequip(throwable);
			if(armour) temp_armour = unequip(armour);
			super.death(cause, decapitation);
			if(!active){
				Brain.playerCharacters.splice(Brain.playerCharacters.indexOf(this), 1);
				game.minion = null;
				game.minionHealthBar.visible = false;
				game.gameMenu.summonOption.active = false;
				game.gameMenu.update();
				minimapFX.active = false;
				var mapNameStr:String = Map.getName(game.map.type, game.map.level);
				if(game.map.type == Map.MAIN_DUNGEON) mapNameStr += ":" + game.map.level;
				// save minion death by making tests for the minion data object return false
				UserData.gameState.minion = false;
				game.trackEvent("minion death", mapNameStr);
			} else {
				if(temp_weapon) equip(temp_weapon);
				if(temp_throwable) equip(temp_throwable);
				if(temp_armour) equip(temp_armour);
			}
		}
		
		/* Prepares for the current state of multiplayer */
		public function setMultiplayer():void{
			if(game.multiplayer){
				brain = new PlayerBrain(this, game.player);
				canMenuAction = attackCount >= 1;
				if(canMenuAction) unlockMenuActions();
				game.gameMenu.minionJumpOption.active = canJump;
			} else {
				brain = new Brain(this, Brain.PLAYER, game.player);
				game.gameMenu.minionMissileOption.active = false;
				game.gameMenu.minionJumpOption.active = false;
			}
		}
		
		/* Prevents the player from gaming the state machine with state changing menu actions */
		public function lockMenuActions():void{
			canMenuAction = false;
			game.gameMenu.minionMissileOption.active = false;
			game.gameMenu.update();
		}
		
		/* Releases the lockout on locked menu actions */
		public function unlockMenuActions():void{
			canMenuAction = true;
			game.gameMenu.minionMissileOption.active = (
				!indifferent &&
				(
					(weapon && weapon.range & Item.MISSILE) ||
					(throwable && !(throwable.holyState == Item.CURSE_REVEALED && !undead))
				)
			);
			game.gameMenu.update();
		}
		
	}

}