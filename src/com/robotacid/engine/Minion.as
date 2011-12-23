package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Item;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
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
		
		private var minimapFX:MinimapFX;
		
		public static const ENTER_DELAY:int = 30;
		
		public function Minion(gfx:DisplayObject, x:Number, y:Number, name:int) {
			
			super(gfx, x, y, name, MINION, game.player.level);
			
			inventory = game.menu.inventoryList;
			
			missileIgnore |= Collider.PLAYER | Collider.MINION;
			
			brain = new Brain(this, Brain.PLAYER, game.player);
			Brain.playerCharacters.push(this);
			
			game.minionHealthBar.visible = true;
			game.minionHealthBar.setValue(health, totalHealth);
			game.menu.summonOption.active = true;
			game.menu.update();
			
			addMinimapFeature();
		}
		
		public function addMinimapFeature():void{
			minimapFX = game.miniMap.addFeature(mapX, mapY, renderer.minionFeatureBlit);
		}
		
		override public function createCollider(x:Number, y:Number, properties:int, ignoreProperties:int, state:int = 0, positionByBase:Boolean = true):void {
			super.createCollider(x, y, properties, ignoreProperties, state, positionByBase);
			collider.properties |= Collider.MINION;
			collider.ignoreProperties |= Collider.PLAYER | Collider.MINION;
			collider.stompProperties = Collider.MONSTER;
		}
		
		override public function main():void {
			if(enterCount){
				enterCount--;
				if(enterCount == 0){
					enterLevel(portal);
				} else {
					return;
				}
			}
			// offscreen check
			if(!game.mapTileManager.intersects(collider, Game.SCALE * 2)){
				teleportToPlayer();
			}
			if(state == WALKING) brain.main();
			super.main();
			minimapFX.x = mapX;
			minimapFX.y = mapY;
		}
		
		/* The minion waits for the player to finish using the stairs */
		public function prepareToEnter(portal:Portal):void{
			enterCount = ENTER_DELAY;
			this.portal = portal;
		}
		
		/* Select an item as a weapon or armour */
		override public function equip(item:Item):Item {
			item = inventory.unstack(item);
			super.equip(item);
			if(item.curseState == Item.CURSE_HIDDEN) item.revealCurse();
			inventory.updateItem(item);
			return item;
		}
		/* Unselect item as equipped */
		override public function unequip(item:Item):Item{
			super.unequip(item);
			item = inventory.stack(item);
			inventory.updateItem(item);
			return item;
		}
		
		override public function applyDamage(n:Number, source:String, knockback:Number = 0, critical:Boolean = false, aggressor:Character = null):void {
			super.applyDamage(n, source, knockback, critical, aggressor);
			game.minionHealthBar.setValue(health, totalHealth);
		}
		
		override public function applyHealth(n:Number):void {
			super.applyHealth(n);
			game.minionHealthBar.setValue(health, totalHealth);
		}
		
		/* This pulls the minion to the vicinity of the player */
		public function teleportToPlayer():void{
			renderer.createTeleportSparkRect(collider, 20);
			collider.divorce();
			collider.x = -collider.width * 0.5 + game.player.collider.x + game.player.collider.width * 0.5;
			collider.y = -collider.height + game.player.collider.y + game.player.collider.height;
			mapX = (collider.x + collider.width * 0.5) * INV_SCALE;
			mapY = (collider.y + collider.height * 0.5) * INV_SCALE;
			renderer.createTeleportSparkRect(collider, 20);
			brain.clear();
			game.soundQueue.add("teleport");
		}
		
		override public function death(cause:String = "crushing", decapitation:Boolean = false, aggressor:Character = null):void {
			if(!active) return;
			var temp_weapon:Item;
			var temp_armour:Item;
			if(weapon) temp_weapon = unequip(weapon);
			if(armour) temp_armour = unequip(armour);
			super.death(cause, decapitation);
			if(!active){
				Brain.playerCharacters.splice(Brain.playerCharacters.indexOf(this), 1);
				game.minion = null;
				game.minionHealthBar.visible = false;
				game.menu.summonOption.active = false;
				game.menu.update();
				minimapFX.active = false;
			} else {
				if(temp_weapon) equip(temp_weapon);
				if(temp_armour) equip(temp_armour);
			}
		}
		
	}

}