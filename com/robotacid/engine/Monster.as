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
		
		public function Monster(mc:DisplayObject, name:int, level:int, items:Vector.<Item>, width:Number, height:Number, g:Game) {
			super(mc, name, MONSTER, level, width, height, g);
			
			block.type |= Block.MONSTER;
			missileIgnore |= Block.MONSTER;
			
			brain = new Brain(this, Brain.MONSTER, g);
			
			Brain.monsterCharacters.push(this);
			
			if(items){
				loot = items;
				for(var i:int = 0; i < loot.length; i++){
					if(loot[i].type == Item.WEAPON || loot[i].type == Item.ARMOUR){
						equip(loot[i]);
					}
				}
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
			super.applyDamage(n, source, critical, aggressor);
			// poison effects on multiple characters could cause the bar to flicker between victims,
			// so we focus on the last person who was attacked physically
			if(active && this == g.player.victim){
				g.enemyHealthBar.setValue(health, totalHealth);
				g.enemyHealthBar.activate();
			}
		}
		
		override public function death(cause:String, decapitation:Boolean = false, aggressor:int = 0):void {
			if(!active) return;
			for(var i:int = 0; i < loot.length; i++){
				if(loot[i].state == Item.EQUIPPED){
					unequip(loot[i]);
				}
				loot[i].dropToMap(mapX, mapY);
				g.entities.push(loot[i]);
			}
			loot = new Vector.<Item>();
			super.death(cause, decapitation);
			g.enemyHealthBar.deactivate();
			if(aggressor == PLAYER){
				var surgeryChance:Number = CARDIAC_SURGERY_CHANCE + (g.player.weapon == null ? BARE_HANDED_CARDIAC_SURGERY_CHANCE : 0);
				if(Math.random() < surgeryChance){
					var heartMc:Sprite = new g.library.HeartMC();
					var heart:Item = new Item(heartMc, name, Item.HEART, level, g);
					heart.collect(g.player);
					g.console.print("rogue tore out a" + (name == CharacterAttributes.NAME_STRINGS[ORC] ? "n " : " ") + heart.nameToString());
				}
			}
			Brain.monsterCharacters.splice(Brain.monsterCharacters.indexOf(this), 1);
		}
		
		override public function remove():void {
			Brain.monsterCharacters.splice(Brain.monsterCharacters.indexOf(this), 1);
			super.remove();
		}
		
		override public function toXML():XML {
			var xml:XML = super.toXML();
			if(loot.length){
				for(var i:int = 0; i < loot.length; i++){
					xml.appendChild(loot[i].toXML());
				}
			}
			return xml;
		}
		
	}
	
}