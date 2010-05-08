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
			
			super(mc, name, MINION, g.player.level, width, height, g);
			
			inventory = g.menu.inventory_list;
			
			holder = g.entities_holder;
			
			block.type |= Block.MINION;
			ignore |= Block.PLAYER | Block.MINION;
			missile_ignore |= Block.PLAYER | Block.MINION;
			
			brain = new Brain(this, Brain.PLAYER, g);
			
			Brain.player_characters.push(this);
			
			g.minion_health_bar.visible = true;
			g.console.print("undead minion summoned");
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
			g.minion_health_bar.setValue(health, total_health);
		}
		
		override public function applyHealth(n:Number):void {
			super.applyHealth(n);
			g.minion_health_bar.setValue(health, total_health);
		}
		
		
		
		/* This pulls the minion to the vicinity of the player */
		public function teleportToPlayer():void{
			g.createTeleportSparkRect(rect, 20);
			divorce();
			x = g.player.x;
			y = g.player.rect.y + g.player.rect.height - height * 0.5;
			updateRect();
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
				Brain.player_characters.splice(Brain.player_characters.indexOf(this), 1);
				g.minion = null;
				g.minion_health_bar.visible = false;
			} else {
				if(temp_weapon) equip(temp_weapon);
				if(temp_armour) equip(temp_armour);
			}
		}
		
	}

}