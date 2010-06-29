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
		public var textHolder:Sprite;
		public var help:TextBox;
		public var _selection:int;
		public var selectionWindow:Bitmap;
		public var selectionWindowTaperPrevious:Bitmap;
		public var selectionWindowTaperNext:Bitmap;
		public var lineHeight:Number;
		
		public var branch:Vector.<MenuList>;
		public var branchStringCurrentOption:String;
		public var branchStringHistory:String;
		public var branchStringSeparator:String = "/";
		
		public var hotKeyMaps:Vector.<HotKeyMap>;
		public var hotKeyMapRecord:HotKeyMap;
		
		public var previousTextBox:TextBox;
		public var currentTextBox:TextBox;
		public var nextTextBox:TextBox;
		
		public var previousMenuList:MenuList;
		public var currentMenuList:MenuList;
		public var nextMenuList:MenuList;
		
		public static var keyChanger:MenuList;
		
		public var selectionWindowCol:uint = 0xFFEEEEEE;
		
		// display area that the menu takes up
		public var Width:Number;
		public var Height:Number;
		
		public var maskShape:Shape;
		
		public var keyCount:int;
		public var keyReset:int;
		public var keyLock:Boolean;
		
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
			Width = width;
			Height = height;
			
			// initialise the branch recorders - these will help examine the history of
			// menu usage
			branch = new Vector.<MenuList>();
			hotKeyMaps = new Vector.<HotKeyMap>();
			for(var i:int = 0; i < Key.hotKeyTotal; i++){
				hotKeyMaps.push(null);
			}
			
			// create a mask to contain the menu
			maskShape = new Shape();
			addChild(maskShape);
			maskShape.graphics.beginFill(0xFF0000);
			maskShape.graphics.drawRect(0, 0, width, height);
			maskShape.graphics.endFill();
			mask = maskShape;
			
			lineHeight = TextBox.lineHeight + 2;
			
			help = new TextBox(320, 3, 0x66111111, 0xFF999999, 0xFFDDDDDD);
			help.maxLines = 3;
			help.fixedHeight = true;
			
			// create TextBoxes to render the current state of the menu
			textHolder = new Sprite();
			addChild(textHolder);
			textHolder.x = -LIST_WIDTH * 0.5 + Width * 0.5;
			textHolder.y = (lineHeight * 3) + (Height - (lineHeight * 3)) * 0.5 - lineHeight * 0.5;
			
			previousTextBox = new TextBox(LIST_WIDTH, 1, 0x66010101, 0xFF666666, 0xFF999999);
			previousTextBox.alpha = 0.7;
			currentTextBox = new TextBox(LIST_WIDTH, 1, 0x66111111, 0xFF999999, 0xFFDDDDDD);
			nextTextBox = new TextBox(LIST_WIDTH, 1, 0x66010101, 0xFF666666, 0xFF999999);
			nextTextBox.alpha = 0.7;
			
			previousTextBox.x = -LIST_WIDTH;
			nextTextBox.x = LIST_WIDTH;
			
			textHolder.addChild(previousTextBox);
			textHolder.addChild(currentTextBox);
			textHolder.addChild(nextTextBox);
			
			previousTextBox.visible = false;
			nextTextBox.visible = false;
			
			// the selection window shows what option we are currently on
			selectionWindow = new Bitmap(new BitmapData(LIST_WIDTH, lineHeight));
			selectionWindow.x = -selectionWindow.width * 0.5 + Width * 0.5;
			selectionWindow.y = 1 + (lineHeight * 3) + (Height - (lineHeight * 3)) * 0.5 - lineHeight * 0.5;
			selectionWindowTaperNext = new Bitmap(new BitmapData(SELECTION_WINDOW_TAPER_WIDTH, lineHeight, true, 0x00000000));
			selectionWindowTaperNext.x = selectionWindow.x + selectionWindow.width;
			selectionWindowTaperNext.y = selectionWindow.y;
			selectionWindowTaperPrevious = new Bitmap(new BitmapData(SELECTION_WINDOW_TAPER_WIDTH, lineHeight, true, 0x00000000));
			selectionWindowTaperPrevious.x = selectionWindow.x - selectionWindowTaperPrevious.width;
			selectionWindowTaperPrevious.y = selectionWindow.y;
			drawSelectionWindow();
			addChild(selectionWindow);
			addChild(selectionWindowTaperNext);
			addChild(selectionWindowTaperPrevious);
			
			addChild(help);
			
			if(trunk) setTrunk(trunk);
			
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
			
		}
		
		/* The trunk is MenuList 0. All options and lists branch outwards like a tree
		 * from this list. Calling this method also moves the menu to the trunk and
		 * renders the current state
		 */
		public function setTrunk(menuList:MenuList):void{
			currentMenuList = menuList;
			previousMenuList = null;
			branch = new Vector.<MenuList>();
			branch.push(menuList);
			branchStringHistory = "";
			keyCount = KEY_DELAY;
			keyReset = 0
			keyLock = true;
			selection = menuList.selection;
		}
		
		/* Returns a string representation of the current menu history.
		 * Use this to debug the menu and to quickly identify traversed menu paths
		 */
		public function branchString():String{
			return branchStringHistory + (branchStringHistory.length > 0 ? branchStringSeparator : "") + branchStringCurrentOption;
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
			currentMenuList.selection = n;
			branchStringCurrentOption = currentMenuList.options[n].name;
			if(currentMenuList.options[n].next){
				nextMenuList = currentMenuList.options[n].next;
			} else {
				nextMenuList = null;
			}
			renderMenu();
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		/* Either walks forward to the MenuList pointed to by the current option
		 * or when there is no MenuList pointed to, fires the SELECT event and
		 * jumps the menu back to the trunk.
		 */
		public function stepForward():void{
			if(currentMenuList.options[currentMenuList.selection].active){
				// walk forward
				if(nextMenuList){
					// recording?
					if(hotKeyMapRecord){
						hotKeyMapRecord.push(currentMenuList, currentMenuList.options[currentMenuList.selection], currentMenuList.selection);
					}
					
					// options that are deactivated by walking this option are disabled here
					// such as setting hot keys allowing recursive walks
					if(currentMenuList.options[currentMenuList.selection].deactivates){
						var list:Vector.<MenuOption> = currentMenuList.options[currentMenuList.selection].deactivates;
						for(var i:int = 0; i < list.length; i++){
							list[i].active = false;
						}
					}
					
					// hot key? initialise a HotKeyMap
					if(currentMenuList.options[currentMenuList.selection].hotKeyOption){
						hotKeyMapRecord = new HotKeyMap(currentMenuList.selection, this);
						hotKeyMapRecord.init();
					}
					
					branchStringHistory += (branchStringHistory.length > 0 ? branchStringSeparator : "") + currentMenuList.options[_selection].name;
					
					branch.push(nextMenuList);
					
					previousMenuList = currentMenuList;
					currentMenuList = nextMenuList;
					if(currentMenuList == keyChanger) keyLock = true;
					// re-render using the selection getter/setter
					selection = currentMenuList.selection;
					
				// nothing to walk forward to - call the SELECT event
				} else {
					// if the Menu is recording a path for a hot key, then we store that
					// hot key here:
					if(hotKeyMapRecord){
						hotKeyMapRecord.push(currentMenuList, currentMenuList.options[currentMenuList.selection], currentMenuList.selection);
						
						hotKeyMaps[hotKeyMapRecord.key] = hotKeyMapRecord;
						
						hotKeyMapRecord = null;
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
		 * of their forebears, so the branch history and previousMenuList is used
		 */
		public function stepBack():void{
			if(previousMenuList){
				// are we recording?
				if(hotKeyMapRecord){
					hotKeyMapRecord.pop();
					if(hotKeyMapRecord.length == 0){
						hotKeyMapRecord = null;
					}
				}
				branch.pop();
				if(branch.length > 1){
					branchStringHistory = branchStringHistory.substr(0, branchStringHistory.lastIndexOf(branchStringSeparator));
				} else {
					branchStringHistory = "";
				}
				nextMenuList = currentMenuList;
				currentMenuList = previousMenuList;
				previousMenuList = branch.length > 1 ? branch[branch.length - 2] : null;
				
				// reactivate an option that recursively lead to the trunk
				if(currentMenuList.options[currentMenuList.selection].deactivates){
					var list:Vector.<MenuOption> = currentMenuList.options[currentMenuList.selection].deactivates;
					for(var i:int = 0; i < list.length; i++){
						list[i].active = true;
					}
				}
				

				// re-render using the selection getter/setter
				selection = currentMenuList.selection;
			}
		}
		
		/* This renders the current menu state, though it is better to use the selection
		 * getter setter, as it will also update the branchString property and update
		 * what MenuList leads from the currently selected MenuOption.
		 */
		public function renderMenu():void{
			if(previousMenuList){
				previousTextBox.text = previousMenuList.optionsToString();
				previousTextBox.y = -previousMenuList.selection * (lineHeight - TextBox.BORDER_ALLOWANCE);
				setDisabledLines(previousMenuList, previousTextBox);
				previousTextBox.visible = true;
				selectionWindowTaperPrevious.visible = true;
			} else {
				previousTextBox.visible = false;
				selectionWindowTaperPrevious.visible = false;
			}
			if(currentMenuList){
				if(currentMenuList == keyChanger){
					keyChanger.options[0].name = "press a key";
				}
				currentTextBox.text = currentMenuList.optionsToString();
				currentTextBox.y = -currentMenuList.selection * (lineHeight - TextBox.BORDER_ALLOWANCE);
				setDisabledLines(currentMenuList, currentTextBox);
			}
			if(currentMenuList.options[_selection].active && nextMenuList){
				if(nextMenuList == keyChanger){
					keyChanger.options[0].name = Key.keyString(Key.custom[_selection]);
				}
				nextTextBox.text = nextMenuList.optionsToString();
				nextTextBox.y = -nextMenuList.selection * (lineHeight - TextBox.BORDER_ALLOWANCE);
				setDisabledLines(nextMenuList, nextTextBox);
				nextTextBox.visible = true;
				selectionWindowTaperNext.visible = true;
			} else {
				nextTextBox.visible = false;
				selectionWindowTaperNext.visible = false;
			}
		}
		
		/* Updates the rendering of disabled MenuOptions */
		public function setDisabledLines(menuList:MenuList, textBox:TextBox):void{
			for(var i:int = 0; i < menuList.options.length; i++){
				if(!menuList.options[i].active) textBox.setDisabledLine(i);
			}
		}
		
		/* We listen for key input here, the keyLock property is used to stop the menu
		 * endlessly firing the same selection */
		public function onEnterFrame(e:Event = null):void{
			var i:int, j:int;
			// if the keyChanger is active, listen for keys to change the current key set
			if(!keyLock && keyChanger && currentMenuList == keyChanger){
				if(Key.keysPressed){
					var keyReserved:Boolean = Key.isDown(Keyboard.UP) || Key.isDown(Keyboard.DOWN) || Key.isDown(Keyboard.LEFT) || Key.isDown(Keyboard.RIGHT);
					for(i = 0; i < Key.custom.length; i++){
						if(Key.customDown(i)){
							keyReserved = true;
						}
					}
					if(!keyReserved){
						Key.custom[previousMenuList.selection] = Key.keyLog[Key.KEY_LOG_LENGTH - 1];
					}
					keyLock = true;
					stepBack();
				}
			}
			// track hot keys so they can instantly perform menu actions
			if(!keyLock && Key.keysPressed){
				for(i = 0; i < Key.hotKeyTotal; i++){
					if(hotKeyMaps[i] && Key.customDown(HOT_KEY_OFFSET + i)){
						hotKeyMaps[i].execute();
						keyLock = true;
						break;
					}
				}
			}
			if(Key.keysPressed){
				// bypass reading keys if the menu is not on the display list
				if(parent){
					if(!keyLock){
						if(keyCount == KEY_DELAY){
							if(selection > 0 && (Key.isDown(Keyboard.UP) || Key.customDown(UP_KEY)) && !(Key.isDown(Keyboard.DOWN) || Key.customDown(DOWN_KEY))){
								selection--;
							}
							if((Key.isDown(Keyboard.LEFT) || Key.customDown(LEFT_KEY)) && !(Key.isDown(Keyboard.RIGHT) || Key.customDown(RIGHT_KEY))){
								stepBack();
							}
							if((Key.isDown(Keyboard.RIGHT) || Key.customDown(RIGHT_KEY)) && !(Key.isDown(Keyboard.LEFT) || Key.customDown(LEFT_KEY))){
								stepForward();
							}
							if (selection < currentMenuList.options.length - 1 && (Key.isDown(Keyboard.DOWN) || Key.customDown(DOWN_KEY)) && !(Key.isDown(Keyboard.UP) || Key.customDown(UP_KEY))){
								selection++;
							}
						}
						keyCount--;
						if(keyCount <= keyReset){
							keyCount = KEY_DELAY;
							if(keyReset < KEY_DELAY) keyReset++;
						}
					}
				}
			} else {
				keyCount = KEY_DELAY;
				keyReset = 0;
				keyLock = false;
			}
		}
		
		/* Update the bitmapdata for the selection window */
		public function drawSelectionWindow():void{
			selectionWindow.bitmapData.fillRect(
				new Rectangle(
					selectionWindow.bitmapData.rect.x,
					selectionWindow.bitmapData.rect.y,
					selectionWindow.bitmapData.rect.width,
					selectionWindow.bitmapData.rect.height
				), selectionWindowCol);
			selectionWindow.bitmapData.fillRect(
				new Rectangle(
					selectionWindow.bitmapData.rect.x + 1,
					selectionWindow.bitmapData.rect.y + 1,
					selectionWindow.bitmapData.rect.width - 2,
					selectionWindow.bitmapData.rect.height- 2
				), 0x00000000);
				var step:int = 255 / SELECTION_WINDOW_TAPER_WIDTH;
			for(var c:uint = selectionWindowCol, n:int = 0; n < SELECTION_WINDOW_TAPER_WIDTH; c -= 0x01000000 * step, n++){
				selectionWindowTaperNext.bitmapData.setPixel32(n, 0, c);
				selectionWindowTaperNext.bitmapData.setPixel32(n, selectionWindow.height-1, c);
				selectionWindowTaperPrevious.bitmapData.setPixel32(SELECTION_WINDOW_TAPER_WIDTH - n, 0, c);
				selectionWindowTaperPrevious.bitmapData.setPixel32(SELECTION_WINDOW_TAPER_WIDTH - n, selectionWindow.height - 1, c);
			}
		}
		
		/* Returns a MenuOption that leads to a MenuList offering the ability to redefine keys. */
		public static function createChangeKeysMenuOption():MenuOption{
			var keyChangerOption:MenuOption = new MenuOption("no key data");
			var keyChangerOptions:Vector.<MenuOption> = new Vector.<MenuOption>();
			keyChangerOptions.push(keyChangerOption);
			keyChanger = new MenuList(keyChangerOptions);
			
			var changeKeysMenuOptions:Vector.<MenuOption> = new Vector.<MenuOption>();
			changeKeysMenuOptions.push(new MenuOption("up", keyChanger));
			changeKeysMenuOptions.push(new MenuOption("down", keyChanger));
			changeKeysMenuOptions.push(new MenuOption("left", keyChanger));
			changeKeysMenuOptions.push(new MenuOption("right", keyChanger));
			changeKeysMenuOptions.push(new MenuOption("menu", keyChanger));
			
			var changeKeysMenuList:MenuList = new MenuList(changeKeysMenuOptions);
			
			for(var i:int = 0; i < Key.hotKeyTotal; i++){
				changeKeysMenuList.options.push(new MenuOption("hot key " + (i + 1), keyChanger));
			}
			return new MenuOption("change keys", changeKeysMenuList);
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
			var hotKeyMenuList:MenuList = new MenuList();
			var option:MenuOption;
			var hotKeyOption:MenuOption = new MenuOption("set hot key");
			if(!deactivates){
				deactivates = new Vector.<MenuOption>();
			}
			deactivates.push(hotKeyOption);
			for(var i:int = 0; i < Key.hotKeyTotal; i++){
				option = new MenuOption("");
				option.name = "hot key " + (i + 1);
				option.help = "stepping right on the menu will begin recording\nexecute a menu option to bind it to this key\nthis will not actually execute the option"
				option.next = trunk;
				option.deactivates = deactivates;
				option.hotKeyOption = true;
				hotKeyMenuList.options.push(option);
			}
			hotKeyOption.next = hotKeyMenuList
			return hotKeyOption;
		}
		
		
	}

}