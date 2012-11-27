package com.robotacid.engine {
	import com.robotacid.gfx.Renderer;
	import com.robotacid.level.Content;
	import com.robotacid.level.Map;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	/**
	 * Effectively a slot machine
	 * 
	 * In game mythology - an altar to Rng, the god of chaos - who grants prayers to the brave
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Altar extends Entity{
		
		public var twinkleCount:int;
		public var rect:Rectangle;
		public var prayerDelay:int;
		public var state:int;
		public var target:Character;
		
		private var count:int;
		
		// states
		public static const IDLE:int = 0;
		public static const ACTIVE:int = 1;
		public static const EMPTY:int = 2;
		
		public static const TWINKLE_DELAY:int = 20;
		public static const ACTIVE_DELAY:int = 60;
		
		// later zones include the selection of miracles from the one before
		public static const MIRACLE_ZONES:Array = [
			["item", "explosion", "cog", "quest", "heal"],
			["overworldPortal", "underworldPortal", "horror", "polymorph", "clones"],
			["identify", "monsterPortal", "xp"],
			["chaos"]
		];
		
		public function Altar(gfx:DisplayObject, mapX:int, mapY:int) {
			super(gfx, false, false);
			gfx.x = mapX * SCALE;
			gfx.y = mapY * SCALE;
			this.mapX = mapX;
			this.mapY = mapY;
			mapZ = MapTileManager.ENTITY_LAYER;
			rect = new Rectangle(mapX * SCALE, mapY * SCALE, SCALE, SCALE);
			callMain = true;
		}
		
		override public function main():void {
			
			if(state == IDLE){
				// concealing the twinkle in the dark will help avoid showing a clipped effect on the edge
				// of the light map
				
				if(game.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000){
					// create a twinkle twinkle effect so the player considers this collectable
					if(twinkleCount-- <= 0){
						renderer.addFX(rect.x + 7, rect.y + 6, renderer.twinkleBlit);
						twinkleCount = TWINKLE_DELAY + game.random.range(TWINKLE_DELAY);
					}
				}
				
				if(
					!game.player.indifferent &&
					(game.player.actions & Collider.UP) &&
					rect.x + rect.width > game.player.collider.x &&
					game.player.collider.x + game.player.collider.width > rect.x &&
					rect.y + rect.height > game.player.collider.y &&
					game.player.collider.y + game.player.collider.height > rect.y
				){
					pray(game.player);
				}
			} else if(state == ACTIVE){
				count--;
				if(count <= 0){
					if(target.active){
						// wait until the character is stable before applying effects
						if(target.state == Character.WALKING){
							miracle();
						}
					} else {
						kill();
					}
				}
			}
		}
		
		/* Activates the altar */
		public function pray(character:Character):void{
			game.console.print(character.nameToString() + " prays to rng, god of chaos...");
			target = character;
			state = ACTIVE;
			count = ACTIVE_DELAY;
			renderer.createDebrisExplosion(new Rectangle(rect.x + 4, rect.y-2, 12, 12), 10, 20, Renderer.STONE);
			game.createDistSound(mapX, mapY, "altar", Critter.COG_DEATH_SOUNDS);
			
			// no sound?
		}
		
		/* Here is where great Rng chooses the fate of those who call to it */
		public function miracle():void{
			
			var effect:Effect, portal:Portal;
			var list:Array = [], i:int, choice:String;
			for(i = 0; i < MIRACLE_ZONES.length; i++){
				if(i <= game.map.zone) list = list.concat(MIRACLE_ZONES[i]);
			}
			
			choice = list[game.random.rangeInt(list.length)];
			
			if(choice == "item"){
				// create a random item
				var type:int = [Item.WEAPON, Item.ARMOUR, Item.RUNE, Item.HEART][game.random.rangeInt(4)];
				var item:Item = Content.XMLToEntity(0, 0, Content.createItemXML(game.map.level, type));
				game.console.print("rng gives you this " + item.nameToString());
				item.collect(target, false);
				
			} else if(choice == "explosion"){
				// create a target-friendly explosion using thier hit damage
				var explosion:Explosion = new Explosion(0, mapX, mapY, 3 + game.random.rangeInt(3), target.damage, target, null, target.missileIgnore);
				game.console.print("rng explodes for " + target.nameToString());
			} else if(choice == "cog"){
				// create a cog critter
				game.mapTileManager.converter.convertIndicesToObjects(mapX, mapY, MapTileConverter.COG_BAT);
				game.console.print("this altar is broken");
			} else if(choice == "quest"){
				// give the player a quest
				game.gameMenu.loreList.questsList.createQuest("rng");
				game.console.print("rng demands a quest of " + target.nameToString());
			} else if(choice == "heal"){
				// heal the target
				target.applyHealth(target.totalHealth);
				if(game.minion) game.minion.applyHealth(game.minion.totalHealth);
				game.console.print("rng grants health");
			} else if(choice == "overworldPortal"){
				// open the overworld portal
				game.console.print("rng opens the overworld portal");
				Portal.createPortal(Portal.PORTAL, mapX, mapY, Map.OVERWORLD, Map.AREA, game.map.level, game.map.type);
			} else if(choice == "underworldPortal"){
				// open the underworld portal
				game.console.print("rng opens the underworld portal");
				Portal.createPortal(Portal.PORTAL, mapX, mapY, Map.UNDERWORLD, Map.AREA, game.map.level, game.map.type);
			} else if(choice == "horror"){
				// summon a horror to chase the target
				effect = new Effect(Effect.FEAR, game.map.level <= Game.MAX_LEVEL ? game.map.level : Game.MAX_LEVEL, Effect.EATEN, target);
			} else if(choice == "polymorph"){
				// polymorph the target
				game.console.print("rng dislikes " + target.nameStr + "s");
				effect = new Effect(Effect.POLYMORPH, target.level, Effect.EATEN, target);
			} else if(choice == "identify"){
				// cast EAT IDENTIFY on the target
				game.console.print("rng grants wisdom to " + target.nameToString());
				effect = new Effect(Effect.IDENTIFY, target.level, Effect.EATEN, target);
			} else if(choice == "monsterPortal"){
				// open a monster portal
				game.console.print("rng likes conflict");
				portal = Portal.createPortal(Portal.MONSTER, mapX, mapY);
				portal.setCloneTemplate(Content.createCharacterXML(game.map.level, Character.MONSTER));
			} else if(choice == "xp"){
				// quicken the target
				if(target.level < Game.MAX_LEVEL) effect = new Effect(Effect.XP, target.level, Effect.EATEN, target);
				else target.quicken();
				game.console.print("rng quickens " + target.nameToString());
			} else if(choice == "chaos"){
				// ?
				game.console.print("rng grants chaos");
				effect = new Effect(Effect.CHAOS, target.level, Effect.EATEN, target);
			} else if(choice == "clones"){
				// open a clone portal
				game.console.print("rng likes minions");
				portal = Portal.createPortal(Portal.MINION, game.player.mapX, game.player.mapY);
				portal.setCloneTemplate();
			}
			renderer.createSparkRect(new Rectangle(rect.x + 4, rect.y-2, 12, 12), 10, 1, 1);
			renderer.createSparkRect(new Rectangle(rect.x + 4, rect.y-2, 12, 12), 10, -1, -1);
			renderer.createSparkRect(new Rectangle(rect.x + 4, rect.y-2, 12, 12), 10, 1, -1);
			renderer.createSparkRect(new Rectangle(rect.x + 4, rect.y-2, 12, 12), 10, -1, 1);
			game.createDistSound(mapX, mapY, "miracle", ["Prayer01", "Prayer02", "Prayer03"]);
			kill();
		}
		
		/* Destroy the altar, but print the cog holder to the background */
		public function kill():void{
			renderer.createDebrisExplosion(new Rectangle(rect.x + 4, rect.y-2, 12, 12), 10, 20, Renderer.STONE);
			game.createDistSound(mapX, mapY, "altar", Critter.COG_DEATH_SOUNDS);
			(gfx as MovieClip).gotoAndStop("empty");
			renderer.backBitmapData.draw(gfx, gfx.transform.matrix, gfx.transform.colorTransform);
			renderer.blockBitmapData.draw(gfx, gfx.transform.matrix, gfx.transform.colorTransform);
			active = false;
			game.mapTileManager.removeTile(this, mapX, mapY, mapZ);
			game.content.removeAltar(game.map.level, game.map.type);
		}
		
		override public function nameToString():String {
			return "?";
		}
		
		override public function remove():void {
			super.remove();
			var n:int = game.items.indexOf(this);
			if(n > -1) game.items.splice(n, 1);
		}
		
		override public function render():void {
			var mc:MovieClip = gfx as MovieClip;
			if(state == IDLE){
				if(mc.currentLabel != "idle") mc.gotoAndStop("idle");
			} else if(state == ACTIVE){
				if(mc.currentLabel != "active") mc.gotoAndStop("active");
			}
			super.render();
		}
		
	}

}