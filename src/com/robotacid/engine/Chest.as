package com.robotacid.engine {
	import com.robotacid.dungeon.Content;
	import com.robotacid.phys.Collider;
	import com.robotacid.sound.SoundManager;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	/**
	 * Item container
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Chest extends Entity{
		
		public var twinkleCount:int;
		public var rect:Rectangle;
		public var contents:Vector.<Item>;
		
		public static const TWINKLE_DELAY:int = 20;
		public static const OPEN_ID:int = 53;
		public static const GNOLL_SCAVENGER_RATE:Number = 1.0 / 20;
		
		public function Chest(mc:DisplayObject, x:Number, y:Number, items:Vector.<Item>) {
			super(mc, false, false);
			
			mc.x = x;
			mc.y = y;
			
			mapX = x * Game.INV_SCALE;
			mapY = y * Game.INV_SCALE;
			
			// for the sake of brevity - an open chest is an empty chest
			if(items){
				contents = items;
				rect = mc.getBounds(mc);
				rect.x += x;
				rect.y += y;
				callMain = true;
			}
			(mc as MovieClip).gotoAndStop(contents ? "closed" : "open");
		}
		
		override public function main():void {
			// concealing the twinkle in the dark will help avoid showing a clipped effect on the edge
			// of the light map
			if(game.lightMap.darkImage.getPixel32(mapX, mapY) != 0xFF000000){
				// create a twinkle twinkle effect so the player knows this is a collectable
				if(twinkleCount-- <= 0){
					renderer.addFX(rect.x + game.random.range(rect.width), rect.y + game.random.range(rect.height), renderer.twinkleBlit);
					twinkleCount = TWINKLE_DELAY + game.random.range(TWINKLE_DELAY);
				}
			}
			
			// check for collection by player
			if((game.player.actions & Collider.UP) && rect.intersects(game.player.collider) && !game.player.indifferent){
				collect(game.player);
			}
		}
		
		public function collect(character:Character):void{
			(gfx as MovieClip).gotoAndStop("open");
			tileId = ""+OPEN_ID;
			for(var i:int = 0; i < contents.length; i++){
				contents[i].collect(character);
			}
			// if the character is currently a gnoll they can roll for bonus treasure
			if(character.name == Character.GNOLL && game.random.value() < GNOLL_SCAVENGER_RATE * character.level){
				var type:int = [Item.WEAPON, Item.ARMOUR, Item.RUNE, Item.HEART][game.random.rangeInt(4)];
				var item:Item = Content.XMLToEntity(0, 0, Content.createItemXML(game.map.level, type));
				item.collect(character, false);
				if(character is Player) game.console.print("scavenged " + item.nameToString());
			}
			game.soundQueue.add("chestOpen");
			contents = null;
			callMain = false;
			if(--game.map.completionCount == 0) game.levelCompleteMsg();
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