package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Item;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.menu.InventoryMenuList;
	import com.robotacid.ui.MinimapFeature;
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
		
		private var minimapFeature:MinimapFeature;
		
		public static const ENTER_DELAY:int = 30;
		
		public function Minion(mc:DisplayObject, x:Number, y:Number, name:int) {
			
			super(mc, x, y, name, MINION, g.player.level);
			
			inventory = g.menu.inventoryList;
			
			missileIgnore |= Collider.PLAYER | Collider.MINION;
			
			brain = new Brain(this, Brain.PLAYER, g.player);
			
			Brain.playerCharacters.push(this);
			
			g.minionHealthBar.visible = true;
			g.menu.summonOption.active = true;
			g.menu.update();
			
			addMinimapFeature();
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
			if(!g.mapRenderer.intersects(collider, Game.SCALE * 2)){
				teleportToPlayer();
			}
			if(state == WALKING) brain.main();
			super.main();
			minimapFeature.x = mapX;
			minimapFeature.y = mapY;
		}
		
		/* The minion waits for the player to finish using the stairs */
		public function prepareToEnter(portal:Portal):void{
			enterCount = ENTER_DELAY;
			this.portal = portal;
		}
		
		/* Select an item as a weapon or armour */
		override public function equip(item:Item):Item {
			if(item.curseState == Item.CURSE_HIDDEN){
				item.revealCurse();
				g.console.print("but the minion is unaffected...");
			}
			item = inventory.unstack(item);
			super.equip(item);
			item.location = Item.MINION_EQUIPPED;
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
		
		override public function applyDamage(n:Number, source:String, knockback:Number = 0, critical:Boolean = false, aggressor:int = PLAYER):void {
			super.applyDamage(n, source, knockback, critical, knockback);
			g.minionHealthBar.setValue(health, totalHealth);
		}
		
		override public function applyHealth(n:Number):void {
			super.applyHealth(n);
			g.minionHealthBar.setValue(health, totalHealth);
		}
		
		/* This pulls the minion to the vicinity of the player */
		public function teleportToPlayer():void{
			renderer.createTeleportSparkRect(collider, 20);
			collider.divorce();
			collider.x = -collider.width * 0.5 + g.player.collider.x + g.player.collider.width * 0.5;
			collider.y = -collider.height + g.player.collider.y + g.player.collider.height;
			mapX = (collider.x + collider.width * 0.5) * INV_SCALE;
			mapY = (collider.y + collider.height * 0.5) * INV_SCALE;
			renderer.createTeleportSparkRect(collider, 20);
			g.soundQueue.add("teleport");
		}
		
		/* Adds a MinimapFeature to the minimap, allowing the Player to track the Minion */
		public function addMinimapFeature():void {
			var bitmapData:BitmapData = new BitmapData(3, 3, true, 0x00000000);
			bitmapData.setPixel32(1, 0, 0xCCFFFFFF);
			bitmapData.setPixel32(0, 1, 0xCCFFFFFF);
			bitmapData.setPixel32(2, 1, 0xCCFFFFFF);
			bitmapData.setPixel32(1, 2, 0xCCFFFFFF);
			minimapFeature = g.miniMap.addFeature(mapX, mapY, -1, -1, bitmapData);
		}
		
		override public function death(cause:String = "crushing", decapitation:Boolean = false, aggressor:int = 0):void {
			if(!active) return;
			var temp_weapon:Item;
			var temp_armour:Item;
			if(weapon) temp_weapon = unequip(weapon);
			if(armour) temp_armour = unequip(armour);
			super.death(cause, decapitation);
			if(!active){
				Brain.playerCharacters.splice(Brain.playerCharacters.indexOf(this), 1);
				g.minion = null;
				g.minionHealthBar.visible = false;
				g.menu.summonOption.active = false;
				g.menu.update();
				minimapFeature.active = false;
			} else {
				if(temp_weapon) equip(temp_weapon);
				if(temp_armour) equip(temp_armour);
			}
		}
		
	}

}