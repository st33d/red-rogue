package com.robotacid.engine {
	import com.robotacid.ai.BalrogBrain;
	import com.robotacid.ai.Brain;
	import com.robotacid.geom.Pixel;
	import com.robotacid.phys.Collider;
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
			
			var x:Number, y:Number;
			// levelState determines where the balrog will start in the level
			if(levelState == STAIRS_DOWN_TAUNT){
				x = (game.map.stairsDown.x + 0.5) * Game.SCALE;
				y = (game.map.stairsDown.y + 1) * Game.SCALE;
			} else if(levelState == ENTER_STAIRS_UP || levelState == WANDER_LEVEL){
				x = (game.map.stairsUp.x + 0.5) * Game.SCALE;
				y = (game.map.stairsUp.y + 1) * Game.SCALE;
			}
			
			super(gfx, x, y, BALROG, MONSTER, game.player.level, false);
			
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
			
			game.lightMap.setLight(this, DEFAULT_LIGHT_RADIUS);
			
			brain = new BalrogBrain(this);
			
			if(items) loot = items;
		}
		
		override public function main():void {
			if(!mapInitialised){
				mapInit();
			}
			// the balrog destroys chaos walls and gates he comes into contact with
			// this helps him escape as well as generate golems to harry the player
			var touching:Collider = collider.getContact();
			if(touching.properties & (Collider.CHAOS | Collider.GATE)){
				if(touching.userData is Gate){
					(touching.userData as Gate).death();
				} else if(touching.userData is ChaosWall){
					(touching.userData as ChaosWall).crumble();
				}
			}
			
			tileCenter = (mapX + 0.5) * SCALE;
			if(state == WALKING || state == LUNGING) brain.main();
			super.main();
		}
		
		/* Called on the balrog's first main() */
		public function mapInit():void{
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
			if(levelState == WANDER_LEVEL || levelState == STAIRS_DOWN_TAUNT){
				if(levelState == WANDER_LEVEL){
					// find a nice spot to initialise the balrog - not too near the player entering
					Effect.teleportCharacter(this, null, true);
				}
				game.world.restoreCollider(collider);
				collider.state = Collider.FALL;
				state = WALKING;
			}
			Brain.monsterCharacters.push(this);
		}
		
		override public function toXML():XML {
			var xml:XML = super.toXML();
			xml.@levelState = levelState;
			return xml;
		}
		
	}

}