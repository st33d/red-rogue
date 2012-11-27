package com.robotacid.engine {
	import com.robotacid.phys.Collider;
	import com.robotacid.ai.Brain;
	import flash.display.DisplayObject;
	
	/**
	 * A throwaway player ally
	 * 
	 * Just made this for shits and giggles really. Didn't want to break the game, just thought it would be
	 * awesome once in a while.
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class MinionClone extends Character {
		
		public function MinionClone(gfx:DisplayObject, x:Number, y:Number, name:int, type:int, level:int) {
			super(gfx, x, y, name, type, level, false);
			
			missileIgnore |= Collider.PLAYER | Collider.MINION | Collider.PLAYER_MISSILE;
			uniqueNameStr = "clone";
			brain = new Brain(this, Brain.PLAYER, game.player);
			brain.followChaseEdgeSq = Brain.FOLLOW_CHASE_EDGE * Brain.FOLLOW_CHASE_EDGE * Brain.playerCharacters.length;
			brain.followFleeEdgeSq = Brain.FOLLOW_FLEE_EDGE * Brain.FOLLOW_FLEE_EDGE * Brain.playerCharacters.length;
			Brain.playerCharacters.push(this);
		}
		
		override public function main():void {
			// offscreen check
			if(!game.mapTileManager.intersects(collider, SCALE * 2)){
				remove();
				return;
			}
			tileCenter = (mapX + 0.5) * SCALE;
			if(state == WALKING || state == LUNGING) brain.main();
			super.main();
		}
		
		override public function createCollider(x:Number, y:Number, properties:int, ignoreProperties:int, state:int = 0, positionByBase:Boolean = true):void {
			super.createCollider(x, y, properties, ignoreProperties, state, positionByBase);
			collider.properties |= Collider.MINION;
			collider.ignoreProperties |= Collider.PLAYER | Collider.MINION | Collider.PLAYER_MISSILE | Collider.HORROR;
			collider.stompProperties = Collider.MONSTER;
		}
		
		override public function remove():void {
			Brain.playerCharacters.splice(Brain.playerCharacters.indexOf(this), 1);
			super.remove();
		}
		
	}

}