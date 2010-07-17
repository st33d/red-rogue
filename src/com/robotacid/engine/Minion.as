package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Item;
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.menu.InventoryMenuList;
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
		
		public var brain:Brain;
		public var inventory:InventoryMenuList;
		
		public function Minion(mc:DisplayObject, name:int, width:int, height:int, g:Game) {
			
			super(mc, name, MINION, g.player.level, width, height, g, true);
			
			inventory = g.menu.inventoryList;
			
			holder = g.entitiesHolder;
			
			block.type |= Block.MINION;
			ignore |= Block.PLAYER | Block.MINION;
			missileIgnore |= Block.PLAYER | Block.MINION;
			
			brain = new Brain(this, Brain.PLAYER, g);
			
			Brain.playerCharacters.push(this);
			
			g.minionHealthBar.visible = true;
		}
		
		override public function main():void {
			// offscreen check
			if(!g.renderer.intersects(rect, Game.SCALE * 2)){
				teleportToPlayer();
			}
			brain.main();
			super.main();
		}
		/* Select an item as a weapon or armour */
		override public function equip(item:Item):Item {
			item = inventory.unstack(item);
			super.equip(item);
			item.state = Item.MINION_EQUIPPED;
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
		
		override public function applyDamage(n:Number, source:String, critical:Boolean = false, aggressor:int = PLAYER):void {
			super.applyDamage(n, source, critical);
			g.minionHealthBar.setValue(health, totalHealth);
		}
		
		override public function applyHealth(n:Number):void {
			super.applyHealth(n);
			g.minionHealthBar.setValue(health, totalHealth);
		}
		
		
		
		/* This pulls the minion to the vicinity of the player */
		public function teleportToPlayer():void{
			g.createTeleportSparkRect(rect, 20);
			divorce();
			x = g.player.x;
			y = g.player.rect.y + g.player.rect.height - height * 0.5;
			updateRect();
			mapX = (rect.x + rect.width * 0.5) * INV_SCALE;
			mapY = (rect.y + rect.height * 0.5) * INV_SCALE;
			updateMC();
			awake = Collider.AWAKE_DELAY;
			g.createTeleportSparkRect(rect, 20);
			SoundManager.playSound(g.library.TeleportSound);
		}
		
		override public function death(cause:String, decapitation:Boolean = false, aggressor:int = 0):void {
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
			} else {
				if(temp_weapon) equip(temp_weapon);
				if(temp_armour) equip(temp_armour);
			}
		}
		
	}

}