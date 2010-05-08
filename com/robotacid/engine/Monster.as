package com.robotacid.engine {
	import com.robotacid.ai.Brain;
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Collider;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	/**
	 * This is the basic template for all monsters in the game.
	 * 
	 * Differences between them are determined by the reaction of code in the
	 * Brain and Character classes to the monster's "name" variable
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Monster extends Character{
		
		public var brain:Brain;
		
		// Heart items are this game's equivalent of health potions
		// they are harvested randomly during a kill
		// more likely is it that a bare handed player will pluck a heart
		public static const CARDIAC_SURGERY_CHANCE:Number = 0.1;
		public static const BARE_HANDED_CARDIAC_SURGERY_CHANCE:Number = 0.2;
		
		public function Monster(mc:DisplayObject, name:int, level:int, width:Number, height:Number, g:Game) {
			super(mc, name, MONSTER, level, width, height, g);
			
			block.type |= Block.MONSTER;
			missile_ignore |= Block.MONSTER;
			
			brain = new Brain(this, Brain.MONSTER, g);
			
			Brain.monster_characters.push(this);
			
			if(Math.random() > 0.4){
				
				var weapon_index:int = (Math.random() * 6);
				
				var weapon_mc_class:Class = g.library.weaponIndexToMCClass(weapon_index);
				var weapon_item:Item = new Item(new weapon_mc_class, weapon_index, Item.WEAPON, g.dungeon.level-1, g);
				weapon_item.collect(this);
				equip(weapon_item);
			}
			
			if(Math.random() > 0.4){
				var armour_index:int = (Math.random() * 6);
				var armour_mc_class:Class = g.library.armourIndexToMCClass(armour_index);
				var armour_item:Item = new Item(new armour_mc_class, armour_index, Item.ARMOUR, g.dungeon.level-1, g);
				armour_item.collect(this);
				equip(armour_item);
			}
			
		}
		
		override public function main():void {
			// offscreen check
			if(!g.renderer.intersects(rect, SCALE * 2)){
				remove();
				return;
			}
			brain.main();
			super.main();
		}
		
		override public function applyDamage(n:Number, source:String, critical:Boolean = false, aggressor:int = 0):void {
			super.applyDamage(n, source, critical);
			// poison effects on multiple characters could cause the bar to flicker between victims,
			// so we focus on the last person who was attacked physically
			if(active && this == g.player.victim){
				g.enemy_health_bar.setValue(health, total_health);
				g.enemy_health_bar.activate();
			}
		}
		
		override public function death(cause:String, decapitation:Boolean = false, aggressor:int = 0):void {
			if(!active) return;
			for(var i:int = 0; i < loot.length; i++){
				if(loot[i].state == Item.EQUIPPED){
					unequip(loot[i]);
				}
				loot[i].dropToMap(map_x, map_y);
				g.entities.push(loot[i]);
			}
			loot = new Vector.<Item>();
			super.death(cause, decapitation);
			g.enemy_health_bar.deactivate();
			
			if(aggressor == PLAYER){
				var surgery_chance:Number = CARDIAC_SURGERY_CHANCE + (g.player.weapon == null ? BARE_HANDED_CARDIAC_SURGERY_CHANCE : 0);
				if(Math.random() < surgery_chance){
					var heart_mc:Sprite = new g.library.HeartMC();
					var heart:Item = new Item(heart_mc, name, Item.HEART, level, g);
					heart.collect(g.player);
					g.console.print("rogue tore out a" + (name == CharacterAttributes.NAME_STRINGS[ORC] ? "n " : " ") + heart.nameToString());
				}
			}
			Brain.monster_characters.splice(Brain.monster_characters.indexOf(this), 1);
		}
		
		override public function remove():void {
			Brain.monster_characters.splice(Brain.monster_characters.indexOf(this), 1);
			super.remove();
		}
		
	}
	
}