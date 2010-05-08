﻿package com.robotacid.engine {
	import com.robotacid.engine.Entity;
	import com.robotacid.phys.Block;
	import com.robotacid.phys.Cast;
	import com.robotacid.ui.menu.InventoryMenuList;
	import com.robotacid.ui.menu.MenuOptionStack;
	import com.robotacid.util.HiddenInt;
	import com.robotacid.geom.Rect;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.filters.GlowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	
	/**
	* The usable item object -
	* 
	* These are equippable, and usable in numerous ways.
	* This objects serves to bring all items in the game under one roof.
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class Item extends Entity{
		
		public var type:int;
		public var level:int;
		
		// states
		public var state:int;
		public var dropped:Boolean;
		public var stacked:Boolean;
		public var curse_state:int;
		public var temp_y:Number;
		public var py:Number;
		public var floor_y:Number;
		public var twinkle_count:int;
		
		// attributes
		public var damage:Number;
		public var attack:Number;
		public var defense:Number;
		
		public var effects:Vector.<Effect>;
		
		public static const TWINKLE_DELAY:int = 20;
		
		// type flags
		public static const WEAPON:int = 0;
		public static const ARMOUR:int = 1;
		public static const RUNE:int = 2;
		public static const MACGUFFIN:int = 3;
		public static const SHOES:int = 4;
		public static const HEART:int = 5;
		
		// state flags
		public static const INVENTORY:int = 1;
		public static const EQUIPPED:int = 2;
		public static const MINION_EQUIPPED:int = 3;
		
		public static const WEAPON_NAMES:Array = [
			"dagger", "mace", "sword", "staff", "bow", "hammer"
		];
		
		public static const ARMOUR_NAMES:Array = [
			"flies", "fedora", "viking helm", "skull", "blood", ""
		];
		
		public static const RUNE_NAMES:Array = [
			"light",
			"heal",
			"poison",
			"teleport",
			"undead",
			"polymorph",
			"xp"
		];
		
		public static const RUNE_DESCRIPTIONS:Array = [
			"casts a bright light on all things",
			"mends wounds over time",
			"causes sickness and death",
			"appears and disappears in your hand",
			"gives life after death",
			"changes the shape of things",
			"grants wisdom and strength"
		];
		
		public static var rune_names:Array;
		
		// Attributes
		
		// the level attributes are multiplied per level of the item and added to the base score
		
		public static const WEAPON_DAMAGES:Array = [
			0.25,
			0.5,
			1,
			1.5,
			0.25,
			2
		];
		
		public static const WEAPON_DAMAGE_LEVELS:Array = [
			0.05,
			0.05,
			0.1,
			0.1,
			0.05,
			0.15
		];
		
		public static const WEAPON_ATTACKS:Array = [
			0.01,
			0.01,
			0.05,
			0.03,
			0.01,
			0.04
		];
		
		public static const WEAPON_ATTACK_LEVELS:Array = [
			0.01,
			0.01,
			0.02,
			0.02,
			0.01,
			0.02
		];
		
		public static const ARMOUR_DEFENSES:Array = [
			0.01,
			0.015,
			0.02,
			0.03,
			0.04,
			0.01
		];
		
		public static const ARMOUR_DEFENSE_LEVELS:Array = [
			0.01,
			0.01,
			0.015,
			0.02,
			0.02,
			0.01
		];
		
		// item names
		
		// weapons
		public static const DAGGER:int = 0;
		public static const MACE:int = 1;
		public static const SWORD:int = 2;
		public static const STAFF:int = 3;
		public static const BOW:int = 4;
		public static const HAMMER:int = 5;
		
		public static function randomWeapon():int{
			return int(Math.random() * 6);
		}
		
		// armour
		public static const FLIES:int = 0;
		public static const FEDORA:int = 1;
		public static const VIKING_HELM:int = 2;
		public static const SKULL:int = 3;
		public static const BLOOD:int = 4;
		public static const INVISIBILITY:int = 5;
		
		public static function randomArmour():int{
			return int(Math.random() * 6);
		}
		
		// runes
		public static const LIGHT:int = 0;
		public static const HEAL:int = 1;
		public static const POISON:int = 2;
		public static const TELEPORT:int = 3;
		public static const UNDEAD:int = 4;
		public static const POLYMORPH:int = 5;
		public static const XP:int = 6;
		
		// curse states
		public static const NO_CURSE:int = 0;
		public static const CURSE_HIDDEN:int = 1;
		public static const CURSE_REVEALED:int = 2;
		
		public static const CURSE_CHANCE:Number = 0.05;
		
		public static var bounds:Rectangle;
		
		public static const MAX_LEVEL:int = 20;
		
		public function Item(mc:DisplayObject, name:int, type:int, level:int, g:Game) {
			super(mc, g, false, false);
			this.type = type;
			if(type == WEAPON){
				damage = WEAPON_DAMAGES[name] + WEAPON_DAMAGE_LEVELS[name] * level;
				attack = WEAPON_ATTACKS[name] + WEAPON_ATTACK_LEVELS[name] * level;
			} else if(type == ARMOUR){
				defense = ARMOUR_DEFENSES[name] + ARMOUR_DEFENSE_LEVELS[name] * level;
			}
			this.name = name;
			this.level = level;
			curse_state = NO_CURSE;
			holder = g.items_holder;
			state = 0;
			stacked = false;
			collision = true;
			call_main = true;
			twinkle_count = TWINKLE_DELAY + Math.random() * TWINKLE_DELAY;
		}
		override public function main():void {
			// drop to the floor if hanging in the air
			if(y < floor_y){
				temp_y = y;
				y += 0.98 * (y - py) + 1.0;
				py = temp_y;
				if(y > floor_y) y = floor_y;
				mc.y = y >> 0;
				updateRect();
				map_y = y * Game.INV_SCALE;
				if(y == floor_y){
					// if on the renderer we need to add this to the scroller, otherwise we take it off
					// the map to reduce the load
					if(g.renderer.contains(x, y)) g.renderer.addToRenderedArray(map_x, map_y, layer, this);
					else remove();
				}
			}
			// concealing the item in the dark will help avoid showing a clipped effect on the edge
			// of the light map
			if(g.light_map.dark_image.getPixel32(map_x, map_y) != 0xFF000000) mc.visible = true;
			else mc.visible = false;
			if(mc.visible){
				// create a twinkle twinkle effect when the item is on the map to collect
				if(twinkle_count-- <= 0){
					g.addFX(rect.x + Math.random() * rect.width, rect.y + Math.random() * rect.height, g.twinkle_bc, g.back_fx_image, g.back_fx_image_holder);
					twinkle_count = TWINKLE_DELAY + Math.random() * TWINKLE_DELAY;
				}
			}
			
		}
		public function collect(character:Character):void{
			if(state == 0){
				kill();
			}
			state = INVENTORY;
			if(character is Player){
				g.menu.inventory_list.addItem(this);
			} else character.loot.push(this);
			mc.filters = [];
			mc.visible = true;
		}
		/* Puts this item on the map */
		public function dropToMap(mx:int, my:int):void{
			active = true;
			state = 0;
			map_x = mx;
			map_y = my;
			mc.x = -((mc.width * 0.5) >> 0) + (mx + 0.5) * Game.SCALE;
			mc.y = - ((mc.height * 0.5) >> 0) + (my + 0.5) * Game.SCALE;
			var bounds:Rectangle = mc.getBounds(mc);
			mc.x += -bounds.left;
			mc.y += -bounds.top;
			x = mc.x;
			y = py = floor_y = mc.y;
			layer = MapRenderer.GAME_OBJECT_LAYER;
			g.items_holder.addChild(mc);
			updateRect();
			g.items.push(this);
			dropGlow();
			
			// drop to the floor if hanging in the air - we pre raycast to find floor below
			if(!(g.block_map[map_y + 1][map_x] & Rect.UP)){
				var cast:Cast = Cast.vert(x, y, 1, g.block_map.length, g.block_map, Block.CHARACTER | Block.HEAD, g);
				floor_y = (cast.block.y - Game.SCALE) + (y - (map_y * Game.SCALE));
			} else {
				g.renderer.addToRenderedArray(map_x, map_y, layer, this);
			}
		}
		public function kill():void{
			if(!active) return;
			var n:int = g.items.indexOf(this);
			if(n > -1) g.items.splice(n, 1);
			
			if(g.items.indexOf(this) > -1) throw new Error("item has double entry on the map-items list");
			
			// is this item on the map?
			if(mc.parent == g.items_holder){
				g.renderer.map_array_layers[layer][map_y][map_x] = null;
				g.renderer.removeFromRenderedArray(map_x, map_y, layer, this);
			}
			active = false;
		}
		/* Increases current level of item and sets attributes accordingly */
		public function levelUp(n:int = 1):void{
			if(!(type == WEAPON || type == ARMOUR)) return;
			if(level + n < Game.MAX_LEVEL){
				level += 1;
			}
			if(type == WEAPON){
				damage = WEAPON_DAMAGES[name] + WEAPON_DAMAGE_LEVELS[name] * level;
				attack = WEAPON_ATTACKS[name] + WEAPON_ATTACK_LEVELS[name] * level;
			} else if(type == ARMOUR){
				defense = ARMOUR_DEFENSES[name] + ARMOUR_DEFENSE_LEVELS[name] * level;
			}
		}
		public function dropGlow():void{
			var glow:GlowFilter = new GlowFilter(0xFFFFFF, 0.5, 4, 4, 4);
			if(type == WEAPON && name == BOW){
				(mc as MovieClip).gotoAndStop(1);
			}
			mc.filters = [glow];
		}
		
		public function enchantable(rune_name:int):Boolean{
			if(rune_name == XP && level == Game.MAX_LEVEL) return false;
			if(!effects) return true;
			for(var i:int = 0; i < effects.length; i++){
				if(effects[i].name == rune_name && effects[i].level >= Game.MAX_LEVEL) return false;
			}
			return true;
		}
		
		public function revealCurse():void{
			g.console.print("the " + nameToString() + " is cursed!");
			curse_state = CURSE_REVEALED;
		}
		
		override public function toString():String {
			return nameToString();
		}
		
		override public function nameToString():String {
			var str:String = "";
			if(state == EQUIPPED) str += "w: ";
			else if(state == MINION_EQUIPPED) str += "m: ";
			//if(stack > 0) str += stack + "x ";
			//if(level > 0) str += "+" + level + " ";
			
			if(curse_state == CURSE_REVEALED) str += "- ";
			else if(effects) str += "+ ";
			
			if(type == RUNE) return str + "rune of "+rune_names[name];
			if(type == MACGUFFIN) return str + "macguffin";
			if(type == ARMOUR) return str + ARMOUR_NAMES[name];
			if(type == WEAPON) return str + WEAPON_NAMES[name];
			if(type == HEART) return CharacterAttributes.NAME_STRINGS[name] + " heart";
			//if(effect) str += effect.toString();
			return str
		}
		public function updateRect():void{
			bounds = mc.getBounds(g.canvas);
			rect = new Rect(bounds.x, bounds.y, bounds.width, bounds.height);
			if(rect.width + rect.height == 0){
				rect.x = x - 5;
				rect.y = y - 5;
				rect.width = rect.height = 10;
			}
		}
		public static function revealName(n:int, inventory_list:InventoryMenuList):void{
			if(rune_names[n] != "?") return;
			rune_names[n] = RUNE_NAMES[n];
			for(var i:int = 0; i < inventory_list.options.length; i++){
				if((inventory_list.options[i].target as Item).type == RUNE && (inventory_list.options[i].target as Item).name == n){
					(inventory_list.options[i] as MenuOptionStack).single_name = (inventory_list.options[i].target as Item).nameToString();
					(inventory_list.options[i] as MenuOptionStack).total = (inventory_list.options[i] as MenuOptionStack).total;
				}
			}
		}
		override public function remove():void {
			super.remove();
			var n:int = g.items.indexOf(this);
			if(n > -1) g.items.splice(n, 1);
		}
		/* Is 'item' essentially identical to this Item, suggesting we can stack the two */
		public function stackable(item:Item):Boolean{
			return item != this && item.type == type && item.name == name && !(type == ARMOUR || type == WEAPON);
		}
		
		public function copy():Item{
			return new Item(new (Object(mc).constructor as Class), name, type, level, g);
		}
		
		public function getHelpText():String{
			var str:String = "";
			if(type == RUNE){
				str += "this rune ";
				if(rune_names[name] == "?"){
					str += "is unknown\nuse it to discover its power";
				} else {
					str += RUNE_DESCRIPTIONS[name];
				}
				str += "\nrunes can be cast on items, monsters and yourself"
			} else if(type == ARMOUR){
				str += "this armour is a \nlevel " + level + " ";
				if(curse_state == CURSE_REVEALED) str += "cursed ";
				else if(effects) str += "enchanted ";
				str += ARMOUR_NAMES[name];
			} else if(type == WEAPON){
				str += "this weapon is a \nlevel " + level + " ";
				if(curse_state == CURSE_REVEALED) str += "cursed ";
				else if(effects) str += "enchanted ";
				str += WEAPON_NAMES[name];
			} else if(type == HEART){
				str += "this level " + level + " " + CharacterAttributes.NAME_STRINGS[name] + " heart\nrestores health when eaten";
			}
			return str;
		}
	}
	
}