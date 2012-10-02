package com.robotacid.engine {
	import com.robotacid.level.Content;
	import com.robotacid.level.Map;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	/**
	 * Item container
	 * 
	 * On later levels becomes a random trap that spawns a MIMIC Monster
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Chest extends Entity{
		
		public var twinkleCount:int;
		public var rect:Rectangle;
		public var twinkleRect:Rectangle;
		public var contents:Vector.<Item>;
		public var mimicState:int;
		
		private var count:int;
		
		public static const TWINKLE_DELAY:int = 20;
		public static const OPEN_ID:int = 53;
		public static const GNOLL_SCAVENGER_RATE:Number = 1.0 / 20;
		public static const MIMIC_RATE:Number = 1.0 / 5;
		public static const TRANSFORM_DELAY:int = 9;
		public static const MIMIC_XP_REWARD:Number = 1 / 30;
		public static const MIMIC_TEMPLATE_XML:XML = <character characterNum={-1} name={Character.MIMIC} type={Character.MONSTER} />;;
		
		// mimic states
		public static const NONE:int = 0;
		public static const WAITING:int = 1;
		public static const TRANSFORM:int = 2;
		
		public function Chest(gfx:DisplayObject, x:Number, y:Number, items:Vector.<Item>) {
			super(gfx, false, false);
			
			gfx.x = x;
			gfx.y = y;
			
			mapX = x * INV_SCALE;
			mapY = (y - 1) * INV_SCALE;
			mapZ = MapTileManager.ENTITY_LAYER;
			
			// for the sake of brevity - an open chest is an empty chest
			if(items){
				contents = items;
				rect = gfx.getBounds(gfx);
				rect.x += x;
				rect.y += y;
				twinkleRect = rect.clone();
				callMain = true;
			}
			(gfx as MovieClip).gotoAndStop(contents ? "closed" : "open");
			
		}
		
		/* Initialise whether the chest is a mimic or not during level population */
		public function mimicInit(mapType:int, mapLevel:int):void{
			if((mapType == Map.MAIN_DUNGEON || mapType == Map.ITEM_DUNGEON) && mapLevel >= 6){
				mimicState = (game.random.value() < MIMIC_RATE) ? WAITING : NONE;
				if(mimicState == WAITING){
					rect.x = (mapX - 1) * SCALE;
					rect.y = (mapY - 1) * SCALE;
					rect.width = 3 * SCALE;
					rect.height = 3 * SCALE;
				}
			}
		}
		
		override public function main():void {
			
			if(mimicState == TRANSFORM){
				count--;
				if(count <= 0) createMimic();
				
			} else {
				// concealing the twinkle in the dark will help avoid showing a clipped effect on the edge
				// of the light map
				
				var playerIntersectsRect:Boolean = 	rect.x + rect.width > game.player.collider.x &&
													game.player.collider.x + game.player.collider.width > rect.x &&
													rect.y + rect.height > game.player.collider.y &&
													game.player.collider.y + game.player.collider.height > rect.y;
				
				if(game.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000){
					// create a twinkle twinkle effect so the player knows this is a collectable
					if(twinkleCount-- <= 0){
						renderer.addFX(twinkleRect.x + game.random.range(twinkleRect.width), twinkleRect.y + game.random.range(twinkleRect.height), renderer.twinkleBlit);
						twinkleCount = TWINKLE_DELAY + game.random.range(TWINKLE_DELAY);
					}
					// detect the player for transform
					if(mimicState == WAITING){
						if(playerIntersectsRect && !game.player.indifferent){
							mimicState = TRANSFORM;
							(gfx as MovieClip).gotoAndPlay("mimic");
							game.createDistSound(mapX, mapY, "MimicTransform", ["MimicTransform1", "MimicTransform2"]);
							count = TRANSFORM_DELAY;
						}
					}
				}
				
				// check for collection by player
				if(mimicState == NONE && (game.player.actions & Collider.UP) && playerIntersectsRect && !game.player.indifferent){
					collect(game.player);
				}
			}
		}
		
		public function collect(character:Character):void{
			(gfx as MovieClip).gotoAndStop("open");
			tileId = ""+OPEN_ID;
			for(var i:int = 0; i < contents.length; i++){
				contents[i].collect(character);
			}
			// if the character is currently a gnoll they can roll for bonus treasure
			if(character.name == Character.GNOLL){
				if(game.random.value() < GNOLL_SCAVENGER_RATE * character.level){
					var type:int = [Item.WEAPON, Item.ARMOUR, Item.RUNE, Item.HEART][game.random.rangeInt(4)];
					var item:Item = Content.XMLToEntity(0, 0, Content.createItemXML(game.map.level, type));
					item.collect(character, false);
					if(character is Player) game.console.print("scavenged " + item.nameToString());
				} else {
					if(character is Player) game.console.print("scavenge failed");
				}
			}
			game.soundQueue.add("chestOpen");
			contents = null;
			callMain = false;
			if(--game.map.completionCount == 0) game.levelComplete();
		}
		
		/* Replaces this Entity with a Monster */
		public function createMimic():void{
			var xml:XML = MIMIC_TEMPLATE_XML.copy();
			xml.@level = game.map.level;
			for(var i:int = 0; i < contents.length; i++){
				xml.appendChild(contents[i].toXML());
			}
			var n:int = game.items.indexOf(this);
			if(n > -1) game.items.splice(n, 1);
			game.mapTileManager.removeTile(this, mapX, mapY, mapZ);
			var monster:Monster = Content.XMLToEntity(mapX, mapY, xml);
			monster.xpReward = MIMIC_XP_REWARD * Content.getLevelXp(game.map.level);
			game.mapTileManager.converter.convertIndicesToObjects(mapX, mapY, monster);
		}
		
		override public function nameToString():String {
			var str:String = "";
			if(contents){
				for(var i:int = 0; i < contents.length; i++){
					str += contents[i].nameToString();
					if(i < contents.length - 1){
						str += "\nand ";
					}
				}
			}
			return str;
		}
		
		override public function remove():void {
			super.remove();
			var n:int = game.items.indexOf(this);
			if(n > -1) game.items.splice(n, 1);
		}
		
		override public function toXML():XML {
			if(contents){
				var xml:XML = <chest />;
				for(var i:int = 0; i < contents.length; i++){
					xml.appendChild(contents[i].toXML());
				}
				return xml;
			}
			return null;
			
		}
		
	}

}