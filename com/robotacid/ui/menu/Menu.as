package com.robotacid.ui.menu {
	import com.robotacid.ui.Key;
	import com.robotacid.ui.TextBox;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.TextLineMetrics;
	import flash.ui.Keyboard;
	
	/**
	 * This is a key based menu system, designed to allow the player to maintain
	 * preferences and player inventory / skills from one place. The ability to
	 * modify key inputs and setting up of "hot keys" that activate user defined
	 * menu options has been implemented.
	 *
	 * To use: Define MenuLists and MenuOptions. MenuOptions can be pointers to MenuLists
	 * or when they are not, an attempt to traverse right from them will fire an event.
	 *
	 * There are two events:
	 *
	 * SELECT: The user has traversed right until they have reached a MenuOption that does
	 * not point to a MenuList. Steping right from that option fires the SELECT event.
	 * Listening to this event gives the programmer the opportunity to examine the "branch"
	 * property of the Menu and see what the user selected. An appropriate method can then
	 * be called.
	 *
	 * CHANGE: Every time the menu is moved, change is called. The programmer may want to
	 * emit a noise for this, or deactivate/reactivate options based on where the user has
	 * walked to. Bear in mind that MenuOptions are already capable of deactivating other
	 * options when stepped forward through (this is to prevent infinite menu walks, whilst
	 * allowing a recursive path to define hot keys).
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Menu extends Sprite{
		
		public var holder:DisplayObjectContainer;
		public var text_holder:Sprite;
		public var help:TextBox;
		public var _selection:int;
		public var selection_window:Bitmap;
		public var selection_window_taper_previous:Bitmap;
		public var selection_window_taper_next:Bitmap;
		public var line_height:Number;
		
		public var branch:Vector.<MenuList>;
		public var branch_string_current_option:String;
		public var branch_string_history:String;
		public var branch_string_separator:String = "/";
		
		public var hot_key_maps:Vector.<HotKeyMap>;
		public var hot_key_map_record:HotKeyMap;
		
		public var previous_text_box:TextBox;
		public var current_text_box:TextBox;
		public var next_text_box:TextBox;
		
		public var previous_menu_list:MenuList;
		public var current_menu_list:MenuList;
		public var next_menu_list:MenuList;
		
		public static var key_changer:MenuList;
		
		public var selection_window_col:uint = 0xFFEEEEEE;
		
		// display area that the menu takes up
		public var _width:Number;
		public var _height:Number;
		
		public var mask_shape:Shape;
		
		public var key_count:int;
		public var key_reset:int;
		public var key_lock:Boolean;
		
		public static const LIST_WIDTH:Number = 100;
		public static const SELECTION_WINDOW_TAPER_WIDTH:Number = 50;
		public static const KEY_DELAY:int = 5;
		
		// game key properties
		public static const UP_KEY:int = 0;
		public static const DOWN_KEY:int = 1;
		public static const LEFT_KEY:int = 2;
		public static const RIGHT_KEY:int = 3;
		public static const MENU_KEY:int = 4;
		
		public static const HOT_KEY_OFFSET:int = 5;
		
		public function Menu(width:Number, height:Number, trunk:MenuList = null):void{
			_width = width;
			_height = height;
			
			// initialise the branch recorders - these will help examine the history of
			// menu usage
			branch = new Vector.<MenuList>();
			hot_key_maps = new Vector.<HotKeyMap>();
			for(var i:int = 0; i < Key.hot_key_total; i++){
				hot_key_maps.push(null);
			}
			
			// create a mask to contain the menu
			mask_shape = new Shape();
			addChild(mask_shape);
			mask_shape.graphics.beginFill(0xFF0000);
			mask_shape.graphics.drawRect(0, 0, width, height);
			mask_shape.graphics.endFill();
			mask = mask_shape;
			
			line_height = new TextBox(10, 1).line_metrics.height;
			
			help = new TextBox(320, 3, 0x111111, 0x999999, 0xDDDDDD, 0.6);
			help.max_lines = 3;
			help.fixed_height = true;
			
			// create TextBoxes to render the current state of the menu
			text_holder = new Sprite();
			addChild(text_holder);
			text_holder.x = -LIST_WIDTH * 0.5 + _width * 0.5;
			text_holder.y = (line_height * 3) + (_height - (line_height * 3)) * 0.5 - line_height * 0.5;
			
			previous_text_box = new TextBox(LIST_WIDTH, 1, 0x010101, 0x666666, 0x999999, 0.6);
			current_text_box = new TextBox(LIST_WIDTH, 1, 0x111111, 0x999999, 0xDDDDDD, 0.6);
			next_text_box = new TextBox(LIST_WIDTH, 1, 0x010101, 0x666666, 0x999999, 0.6);
			
			previous_text_box.x = -LIST_WIDTH;
			next_text_box.x = LIST_WIDTH;
			
			text_holder.addChild(previous_text_box);
			text_holder.addChild(current_text_box);
			text_holder.addChild(next_text_box);
			
			previous_text_box.visible = false;
			next_text_box.visible = false;
			
			// the selection window shows what option we are currently on
			selection_window = new Bitmap(new BitmapData(LIST_WIDTH, line_height));
			selection_window.x = -LIST_WIDTH * 0.5 + _width * 0.5;
			selection_window.y = (line_height * 3) + (_height - (line_height * 3)) * 0.5 - line_height * 0.5;
			selection_window_taper_next = new Bitmap(new BitmapData(SELECTION_WINDOW_TAPER_WIDTH, line_height, true, 0x00000000));
			selection_window_taper_next.x = selection_window.x + selection_window.width;
			selection_window_taper_next.y = selection_window.y;
			selection_window_taper_previous = new Bitmap(new BitmapData(SELECTION_WINDOW_TAPER_WIDTH, line_height, true, 0x00000000));
			selection_window_taper_previous.x = selection_window.x - selection_window_taper_previous.width;
			selection_window_taper_previous.y = selection_window.y;
			drawSelectionWindow();
			addChild(selection_window);
			addChild(selection_window_taper_next);
			addChild(selection_window_taper_previous);
			
			addChild(help);
			
			if(trunk) setTrunk(trunk);
			
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
			
		}
		
		/* The trunk is MenuList 0. All options and lists branch outwards like a tree
		 * from this list. Calling this method also moves the menu to the trunk and
		 * renders the current state
		 */
		public function setTrunk(menu_list:MenuList):void{
			current_menu_list = menu_list;
			previous_menu_list = null;
			branch = new Vector.<MenuList>();
			branch.push(menu_list);
			branch_string_history = "";
			key_count = KEY_DELAY;
			key_reset = 0
			key_lock = true;
			selection = menu_list.selection;
		}
		
		/* Returns a string representation of the current menu history.
		 * Use this to debug the menu and to quickly identify traversed menu paths
		 */
		public function branchString():String{
			return branch_string_history + (branch_string_history.length > 0 ? branch_string_separator : "") + branch_string_current_option;
		}
		
		/* Returns the current MenuList selection */
		public function get selection():int{
			return _selection;
		}
		
		/* Sets the current MenuList selection, re-renders the menu and fires
		 * the CHANGE event
		 */
		public function set selection(n:int):void{
			_selection = n;
			current_menu_list.selection = n;
			branch_string_current_option = current_menu_list.options[n].name;
			if(current_menu_list.options[n].next){
				next_menu_list = current_menu_list.options[n].next;
			} else {
				next_menu_list = null;
			}
			renderMenu();
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		/* Either walks forward to the MenuList pointed to by the current option
		 * or when there is no MenuList pointed to, fires the SELECT event and
		 * jumps the menu back to the trunk.
		 */
		public function stepForward():void{
			if(current_menu_list.options[current_menu_list.selection].active){
				// walk forward
				if(next_menu_list){
					// recording?
					if(hot_key_map_record){
						hot_key_map_record.push(current_menu_list, current_menu_list.options[current_menu_list.selection], current_menu_list.selection);
					}
					
					// options that are deactivated by walking this option are disabled here
					// such as setting hot keys allowing recursive walks
					if(current_menu_list.options[current_menu_list.selection].deactivates){
						var list:Vector.<MenuOption> = current_menu_list.options[current_menu_list.selection].deactivates;
						for(var i:int = 0; i < list.length; i++){
							list[i].active = false;
						}
					}
					
					// hot key? initialise a HotKeyMap
					if(current_menu_list.options[current_menu_list.selection].hot_key_option){
						hot_key_map_record = new HotKeyMap(current_menu_list.selection, this);
						hot_key_map_record.init();
					}
					
					branch_string_history += (branch_string_history.length > 0 ? branch_string_separator : "") + current_menu_list.options[_selection].name;
					
					branch.push(next_menu_list);
					
					previous_menu_list = current_menu_list;
					current_menu_list = next_menu_list;
					if(current_menu_list == key_changer) key_lock = true;
					// re-render using the selection getter/setter
					selection = current_menu_list.selection;
					
				// nothing to walk forward to - call the SELECT event
				} else {
					// if the Menu is recording a path for a hot key, then we store that
					// hot key here:
					if(hot_key_map_record){
						hot_key_map_record.push(current_menu_list, current_menu_list.options[current_menu_list.selection], current_menu_list.selection);
						
						hot_key_maps[hot_key_map_record.key] = hot_key_map_record;
						
						hot_key_map_record = null;
						// because recording a hot key involves deactivating recursive MenuOptions
						// we have to return to the trunk by foot. It's on my todo list to
						// deactivate all the CHANGE events fired when doing this
						while(branch.length > 1) stepBack();
					} else {
						dispatchEvent(new Event(Event.SELECT));
						setTrunk(branch[0]);
					}
				}
			}
		}
		
		/* Walk back to the previous MenuList. MenuLists and MenuOptions have no memory
		 * of their forebears, so the branch history and previous_menu_list is used
		 */
		public function stepBack():void{
			if(previous_menu_list){
				// are we recording?
				if(hot_key_map_record){
					hot_key_map_record.pop();
					if(hot_key_map_record.length == 0){
						hot_key_map_record = null;
					}
				}
				branch.pop();
				if(branch.length > 1){
					branch_string_history = branch_string_history.substr(0, branch_string_history.lastIndexOf(branch_string_separator));
				} else {
					branch_string_history = "";
				}
				next_menu_list = current_menu_list;
				current_menu_list = previous_menu_list;
				previous_menu_list = branch.length > 1 ? branch[branch.length - 2] : null;
				
				// reactivate an option that recursively lead to the trunk
				if(current_menu_list.options[current_menu_list.selection].deactivates){
					var list:Vector.<MenuOption> = current_menu_list.options[current_menu_list.selection].deactivates;
					for(var i:int = 0; i < list.length; i++){
						list[i].active = true;
					}
				}
				

				// re-render using the selection getter/setter
				selection = current_menu_list.selection;
			}
		}
		
		/* This renders the current menu state, though it is better to use the selection
		 * getter setter, as it will also update the branch_string property and update
		 * what MenuList leads from the currently selected MenuOption.
		 */
		public function renderMenu():void{
			if(previous_menu_list){
				previous_text_box.text = previous_menu_list.optionsToString();
				previous_text_box.y = -previous_menu_list.selection * line_height;
				setDisabledLines(previous_menu_list, previous_text_box);
				previous_text_box.visible = true;
				selection_window_taper_previous.visible = true;
			} else {
				previous_text_box.visible = false;
				selection_window_taper_previous.visible = false;
			}
			if(current_menu_list){
				if(current_menu_list == key_changer){
					key_changer.options[0].name = "press a key";
				}
				current_text_box.text = current_menu_list.optionsToString();
				current_text_box.y = -current_menu_list.selection * line_height;
				setDisabledLines(current_menu_list, current_text_box);
			}
			if(current_menu_list.options[_selection].active && next_menu_list){
				if(next_menu_list == key_changer){
					key_changer.options[0].name = Key.keyString(Key.custom[_selection]);
				}
				next_text_box.text = next_menu_list.optionsToString();
				next_text_box.y = -next_menu_list.selection * line_height;
				setDisabledLines(next_menu_list, next_text_box);
				next_text_box.visible = true;
				selection_window_taper_next.visible = true;
			} else {
				next_text_box.visible = false;
				selection_window_taper_next.visible = false;
			}
		}
		
		/* Updates the rendering of disabled MenuOptions */
		public function setDisabledLines(menu_list:MenuList, text_box:TextBox):void{
			text_box.disabled_shape.graphics.clear();
			for(var i:int = 0; i < menu_list.options.length; i++){
				if(!menu_list.options[i].active) text_box.setDisabledLine(i);
			}
		}
		
		/* We listen for key input here, the key_lock property is used to stop the menu
		 * endlessly firing the same selection */
		public function onEnterFrame(e:Event = null):void{
			var i:int, j:int;
			// if the key_changer is active, listen for keys to change the current key set
			if(!key_lock && key_changer && current_menu_list == key_changer){
				if(Key.keys_pressed){
					var key_reserved:Boolean = Key.isDown(Keyboard.UP) || Key.isDown(Keyboard.DOWN) || Key.isDown(Keyboard.LEFT) || Key.isDown(Keyboard.RIGHT);
					for(i = 0; i < Key.custom.length; i++){
						if(Key.customDown(i)){
							key_reserved = true;
						}
					}
					if(!key_reserved){
						Key.custom[previous_menu_list.selection] = Key.key_log[Key.KEY_LOG_LENGTH - 1];
					}
					key_lock = true;
					stepBack();
				}
			}
			// track hot keys so they can instantly perform menu actions
			if(!key_lock && Key.keys_pressed){
				for(i = 0; i < Key.hot_key_total; i++){
					if(hot_key_maps[i] && Key.customDown(HOT_KEY_OFFSET + i)){
						hot_key_maps[i].execute();
						key_lock = true;
						break;
					}
				}
			}
			if(Key.keys_pressed){
				// bypass reading keys if the menu is not on the display list
				if(parent){
					if(!key_lock){
						if(key_count == KEY_DELAY){
							if(selection > 0 && (Key.isDown(Keyboard.UP) || Key.customDown(UP_KEY)) && !(Key.isDown(Keyboard.DOWN) || Key.customDown(DOWN_KEY))){
								selection--;
							}
							if((Key.isDown(Keyboard.LEFT) || Key.customDown(LEFT_KEY)) && !(Key.isDown(Keyboard.RIGHT) || Key.customDown(RIGHT_KEY))){
								stepBack();
							}
							if((Key.isDown(Keyboard.RIGHT) || Key.customDown(RIGHT_KEY)) && !(Key.isDown(Keyboard.LEFT) || Key.customDown(LEFT_KEY))){
								stepForward();
							}
							if (selection < current_menu_list.options.length - 1 && (Key.isDown(Keyboard.DOWN) || Key.customDown(DOWN_KEY)) && !(Key.isDown(Keyboard.UP) || Key.customDown(UP_KEY))){
								selection++;
							}
						}
						key_count--;
						if(key_count <= key_reset){
							key_count = KEY_DELAY;
							if(key_reset < KEY_DELAY) key_reset++;
						}
					}
				}
			} else {
				key_count = KEY_DELAY;
				key_reset = 0;
				key_lock = false;
			}
		}
		
		/* Update the bitmapdata for the selection window */
		public function drawSelectionWindow():void{
			selection_window.bitmapData.fillRect(
				new Rectangle(
					selection_window.bitmapData.rect.x,
					selection_window.bitmapData.rect.y,
					selection_window.bitmapData.rect.width,
					selection_window.bitmapData.rect.height
				), selection_window_col);
			selection_window.bitmapData.fillRect(
				new Rectangle(
					selection_window.bitmapData.rect.x + 1,
					selection_window.bitmapData.rect.y + 1,
					selection_window.bitmapData.rect.width - 2,
					selection_window.bitmapData.rect.height- 2
				), 0x00000000);
				var step:int = 255 / SELECTION_WINDOW_TAPER_WIDTH;
			for(var c:uint = selection_window_col, n:int = 0; n < SELECTION_WINDOW_TAPER_WIDTH; c -= 0x01000000 * step, n++){
				selection_window_taper_next.bitmapData.setPixel32(n, 0, c);
				selection_window_taper_next.bitmapData.setPixel32(n, selection_window.height-1, c);
				selection_window_taper_previous.bitmapData.setPixel32(SELECTION_WINDOW_TAPER_WIDTH - n, 0, c);
				selection_window_taper_previous.bitmapData.setPixel32(SELECTION_WINDOW_TAPER_WIDTH - n, selection_window.height - 1, c);
			}
		}
		
		/* Returns a MenuOption that leads to a MenuList offering the ability to redefine keys. */
		public static function createChangeKeysMenuOption():MenuOption{
			var key_changer_option:MenuOption = new MenuOption("no key data");
			var key_changer_options:Vector.<MenuOption> = new Vector.<MenuOption>();
			key_changer_options.push(key_changer_option);
			key_changer = new MenuList(key_changer_options);
			
			var change_keys_menu_options:Vector.<MenuOption> = new Vector.<MenuOption>();
			change_keys_menu_options.push(new MenuOption("up", key_changer));
			change_keys_menu_options.push(new MenuOption("down", key_changer));
			change_keys_menu_options.push(new MenuOption("left", key_changer));
			change_keys_menu_options.push(new MenuOption("right", key_changer));
			change_keys_menu_options.push(new MenuOption("menu", key_changer));
			
			var change_keys_menu_list:MenuList = new MenuList(change_keys_menu_options);
			
			for(var i:int = 0; i < Key.hot_key_total; i++){
				change_keys_menu_list.options.push(new MenuOption("hot key " + (i + 1), key_changer));
			}
			return new MenuOption("change keys", change_keys_menu_list);
		}
		
		/* Returns a MenuOption that leads to a MenuList offering the ability to create "hot keys"
		 *
		 * Recording a hot key involves walking from the trunk out and firing a SELECT
		 * event. This will not fire the event, but store the selections made and bind
		 * them to that hot key. Pressing the hot key will then walk the menu back to the trunk
		 * and out to the selected option for that hot key.
		 *
		 * This feature requires submitting the trunk MenuList and a MenuOption that can be
		 * deactivated to prevent the user from walking out to the hot key menu again or
		 * doing another menu activity like redefining keys. I will expand the deactivation
		 * reference to an array at a later date.
		 */
		public static function createHotKeyMenuOption(trunk:MenuList, deactivates:Vector.<MenuOption> = null):MenuOption{
			var hot_key_menu_list:MenuList = new MenuList();
			var option:MenuOption;
			var hot_key_option:MenuOption = new MenuOption("set hot key");
			if(!deactivates){
				deactivates = new Vector.<MenuOption>();
			}
			deactivates.push(hot_key_option);
			for(var i:int = 0; i < Key.hot_key_total; i++){
				option = new MenuOption("");
				option.name = "hot key " + (i + 1);
				option.help = "stepping right on the menu will begin recording\nexecute a menu option to bind it to this key\nthis will not actually execute the option"
				option.next = trunk;
				option.deactivates = deactivates;
				option.hot_key_option = true;
				hot_key_menu_list.options.push(option);
			}
			hot_key_option.next = hot_key_menu_list
			return hot_key_option;
		}
		
		
	}

}