package com.robotacid.engine {
	import com.robotacid.ai.Brain;
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
		
		// Heart items are this game's equivalent of health potions
		// they are harvested randomly during a kill
		// more likely is it that a bare handed player will pluck a heart
		public static const CARDIAC_SURGERY_CHANCE:Number = 0.1;
		public static const BARE_HANDED_CARDIAC_SURGERY_CHANCE:Number = 0.2;
		
		public function Monster(mc:DisplayObject, x:Number, y:Number, name:int, level:int, items:Vector.<Item>){
			super(mc, x, y, name, MONSTER, level, false);
			
			// we do want monsters on the Entities list, but not just yet
			addToEntities = true;
			
			missileIgnore |= Collider.MONSTER;
			
			brain = new Brain(this, Brain.MONSTER);
			
			Brain.monsterCharacters.push(this);
			
			// tool up
			if(items){
				loot = items;
				for(var i:int = 0; i < loot.length; i++){
					if((!weapon && loot[i].type == Item.WEAPON) || (!armour && loot[i].type == Item.ARMOUR)){
						equip(loot[i]);
						if(weapon && armour) break;
					}
				}
			}
		}
		
		override public function createCollider(x:Number, y:Number, properties:int, ignoreProperties:int, state:int = 0, positionByBase:Boolean = true):void {
			super.createCollider(x, y, properties, ignoreProperties, state, positionByBase);
			collider.properties |= Collider.MONSTER;
			collider.stompProperties = Collider.PLAYER | Collider.MINION;
		}
		
		override public function main():void {
			// offscreen check
			if(!g.mapTileManager.intersects(collider, SCALE * 2)){
				remove();
				return;
			}
			if(state == WALKING) brain.main();
			super.main();
		}
		
		override public function applyDamage(n:Number, source:String, knockback:Number = 0, critical:Boolean = false, aggressor:int = 0):void {
			super.applyDamage(n, source, knockback, critical, aggressor);
			// poison effects on multiple characters could cause the bar to flicker between victims,
			// so we focus on the last person who was attacked physically
			if(active && this == g.player.victim){
				g.enemyHealthBar.setValue(health, totalHealth);
				g.enemyHealthBar.activate();
			}
		}
		
		override public function death(cause:String = "crushing", decapitation:Boolean = false, aggressor:int = 0):void {
			if(!active) return;
			for(var i:int = 0; i < loot.length; i++){
				if(loot[i].location == Item.EQUIPPED){
					unequip(loot[i]);
				}
				loot[i].dropToMap(mapX, mapY);
			}
			loot = new Vector.<Item>();
			super.death(cause, decapitation);
			g.enemyHealthBar.deactivate();
			if(aggressor == PLAYER){
				var surgeryChance:Number = CARDIAC_SURGERY_CHANCE + (g.player.weapon == null ? BARE_HANDED_CARDIAC_SURGERY_CHANCE : 0);
				if(g.random.value() < surgeryChance){
					var heartMc:Sprite = new HeartMC();
					var heart:Item = new Item(heartMc, name, Item.HEART, level);
					heart.collect(g.player);
					var victimName:String = Character.stats["names"][name];
					g.console.print("rogue tore out a" + ((victimName.charAt(0).search(/[aeiou]/i) == 0) ? "n " : " ") + heart.nameToString());
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