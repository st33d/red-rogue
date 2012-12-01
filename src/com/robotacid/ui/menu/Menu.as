package com.robotacid.ui.menu {
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.CaptureBitmap;
	import com.robotacid.gfx.DebrisFX;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.Key;
	import com.robotacid.ui.TextBox;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
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
	 * There are two methods to override:
	 *
	 * executeSelection: The user has traversed right until they have reached a MenuOption that does
	 * not point to a MenuList. Steping right from that option fires the execute method.
	 * Listening to this event gives the programmer the opportunity to examine the "branch"
	 * property of the Menu and see what the user selected. An appropriate method can then
	 * be called.
	 *
	 * changeSelection: Every time the menu is moved, change is called. The programmer may want to
	 * emit a noise for this, or deactivate/reactivate options based on where the user has
	 * walked to. Bear in mind that MenuOptions are already capable of deactivating other
	 * options when stepped forward through (this is to prevent infinite menu walks, whilst
	 * allowing a recursive path to define hot keys).
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class Menu extends Sprite{
		
		public static var game:Game;
		
		// gfx
		public var carousel:MenuCarousel;
		public var textHolder:Sprite;
		public var help:TextBox;
		public var selectionWindow:Bitmap;
		public var selectionWindowTaperPrevious:Bitmap;
		public var selectionWindowTaperNext:Bitmap;
		public var previousTextBox:TextBox;
		public var currentTextBox:TextBox;
		public var nextTextBox:TextBox;
		public var infoTextBox:TextBox;
		public var capture:CaptureBitmap;
		public var selectionCopyBitmap:Bitmap;
		public var selectText:TextBox;
		
		public var selection:int;
		public var hideChangeSelection:Boolean;
		
		public var branch:Vector.<MenuList>;
		public var branchStringCurrentOption:String;
		public var branchStringHistory:String;
		public var branchStringSeparator:String = "/";
		
		public var hotKeyMaps:Vector.<HotKeyMap>;
		public var hotKeyMapRecord:HotKeyMap;
		public var changeKeysOption:MenuOption;
		public var hotKeyOption:MenuOption;
		public var inputOption:MenuOption;
		
		public var previousMenuList:MenuList;
		public var currentMenuList:MenuList;
		public var nextMenuList:MenuList;
		
		public static var keyChanger:MenuList;
		
		// display area that the menu takes up
		public var _width:Number;
		public var _height:Number;
		
		public var maskShape:Shape;
		
		// animation and key states - move delay is consistent through all menus
		public var keyLock:Boolean;
		public static var moveDelay:int = 4;
		
		private var dirStack:Vector.<int>;
		private var dir:int;
		private var moveCount:int;
		private var moveReset:int;
		private var vx:Number;
		private var vy:Number;
		private var previousAlphaStep:Number;
		private var currentAlphaStep:Number;
		private var nextAlphaStep:Number;
		private var captureAlphaStep:Number;
		private var helpVy:Number;
		private var alphaStep:Number;
		private var keysDown:int;
		private var hotKeyDown:Vector.<Boolean>;
		private var keysLocked:int;
		private var keysHeldCount:int;
		private var stackCount:int;
		private var movementMovieClips:Vector.<MovieClip>;
		private var movementGuideCount:int;
		private var animatingSelection:Boolean;
		private var notVistitedColFrame:int;
		private var inputKeyPressed:Boolean;
		
		public static const LIST_WIDTH:Number = 100;
		public static const LINE_SPACING:Number = 11;
		public static const SELECTION_WINDOW_TAPER_WIDTH:Number = 50;
		public static const INFO_TEXT_BOX_WIDTH:Number = 110;
		public static const SIDE_ALPHAS:Number = 0.7;
		public static const SELECTION_WINDOW_COL:uint = 0xFFEEEEEE;
		public static const KEYS_HELD_DELAY:int = 5;
		public static const MOVEMENT_GUIDE_DELAY:int = 30;
		public static const DISABLED_COL:ColorTransform = new ColorTransform(1, 1, 1, 1, -100, -100, -100);
		public static const BACKGROUND_COL:uint = 0x66111111;
		public static const BORDER_COL:uint = 0xFF999999;
		
		public static var NOT_VISITED_COLS:Vector.<ColorTransform>;
		
		// game key properties
		public static const UP_KEY:int = 0;
		public static const DOWN_KEY:int = 1;
		public static const LEFT_KEY:int = 2;
		public static const RIGHT_KEY:int = 3;
		public static const MENU_KEY:int = 4;
		
		// infoTextBox states
		public static const HIDDEN:int = 0;
		public static const PREVIEW:int = 1;
		public static const EXPANDED:int = 2;
		
		public static const HOT_KEY_OFFSET:int = 5;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		public static const UP_MOVE:int = 0;
		public static const RIGHT_MOVE:int = 1;
		public static const DOWN_MOVE:int = 2;
		public static const LEFT_MOVE:int = 3;
		
		public function Menu(width:Number, height:Number, trunk:MenuList = null):void{
			_width = width;
			_height = height;
			
			var i:int;
			dirStack = new Vector.<int>();
			dir = 0;
			vx = vy = 0;
			moveCount = 0;
			moveReset = moveDelay;
			keysHeldCount = KEYS_HELD_DELAY;
			movementGuideCount = MOVEMENT_GUIDE_DELAY;
			hideChangeSelection = false;
			animatingSelection = false;
			
			// initialise NOT_VISITED_COLS
			initNotVisitedCols();
			
			// initialise the branch recorders - these will help examine the history of
			// menu usage
			branch = new Vector.<MenuList>();
			hotKeyMaps = new Vector.<HotKeyMap>();
			hotKeyDown = new Vector.<Boolean>();
			for(i = 0; i < Key.hotKeyTotal; i++){
				hotKeyMaps.push(null);
				hotKeyDown[i] = false;
			}
			
			// create a mask to contain the menu
			maskShape = new Shape();
			addChild(maskShape);
			maskShape.graphics.beginFill(0xFF0000);
			maskShape.graphics.drawRect(0, 0, _width, _height);
			maskShape.graphics.endFill();
			mask = maskShape;
			
			help = new TextBox(320, 36, BACKGROUND_COL, BORDER_COL);
			
			// create TextBoxes to render the current state of the menu
			textHolder = new Sprite();
			addChild(textHolder);
			textHolder.x = (-LIST_WIDTH * 0.5 + _width * 0.5) >> 0;
			textHolder.y = ((LINE_SPACING * 3) + (_height - (LINE_SPACING * 3)) * 0.5 - LINE_SPACING * 0.5) >> 0;
			
			previousTextBox = new TextBox(LIST_WIDTH, 1 + LINE_SPACING + TextBox.BORDER_ALLOWANCE * 2, BACKGROUND_COL, BORDER_COL);
			previousTextBox.alpha = 0.7;
			previousTextBox.wordWrap = false;
			previousTextBox.marquee = true;
			currentTextBox = new TextBox(LIST_WIDTH, 1 + LINE_SPACING + TextBox.BORDER_ALLOWANCE * 2, BACKGROUND_COL, BORDER_COL);
			currentTextBox.wordWrap = false;
			currentTextBox.marquee = true;
			nextTextBox = new TextBox(LIST_WIDTH, 1 + LINE_SPACING + TextBox.BORDER_ALLOWANCE * 2, BACKGROUND_COL, BORDER_COL);
			nextTextBox.alpha = 0.7;
			nextTextBox.wordWrap = false;
			nextTextBox.marquee = true;
			infoTextBox = new TextBox(INFO_TEXT_BOX_WIDTH, 169, BACKGROUND_COL, BORDER_COL);
			infoTextBox.wordWrap = false;
			infoTextBox.marquee = true;
			infoTextBox.visible = false;
			capture = new CaptureBitmap();
			capture.visible = false;
			
			previousTextBox.x = -LIST_WIDTH;
			nextTextBox.x = LIST_WIDTH;
			infoTextBox.x = LIST_WIDTH;
			infoTextBox.y = -77;
			
			textHolder.addChild(previousTextBox);
			textHolder.addChild(currentTextBox);
			textHolder.addChild(nextTextBox);
			textHolder.addChild(infoTextBox);
			textHolder.addChild(capture);
			
			previousTextBox.visible = false;
			nextTextBox.visible = false;
			
			// the selection window shows what option we are currently on
			selectionWindow = new Bitmap(new BitmapData(LIST_WIDTH, LINE_SPACING));
			selectionCopyBitmap = new Bitmap(selectionWindow.bitmapData.clone());
			selectionCopyBitmap.visible = false;
			selectionWindow.x = -selectionWindow.width * 0.5 + _width * 0.5;
			selectionWindow.y = 1 + ((LINE_SPACING * 3) + (_height - (LINE_SPACING * 3)) * 0.5 - LINE_SPACING * 0.5 - TextBox.BORDER_ALLOWANCE) >> 0;
			selectionCopyBitmap.x = selectionWindow.x;
			selectionCopyBitmap.y = selectionWindow.y;
			selectionWindowTaperNext = new Bitmap(new BitmapData(SELECTION_WINDOW_TAPER_WIDTH, LINE_SPACING, true, 0x0));
			selectionWindowTaperNext.x = selectionWindow.x + selectionWindow.width;
			selectionWindowTaperNext.y = selectionWindow.y;
			selectionWindowTaperPrevious = new Bitmap(new BitmapData(SELECTION_WINDOW_TAPER_WIDTH, LINE_SPACING, true, 0x0));
			selectionWindowTaperPrevious.x = selectionWindow.x - selectionWindowTaperPrevious.width;
			selectionWindowTaperPrevious.y = selectionWindow.y;
			drawSelectionWindow();
			addChild(selectionCopyBitmap);
			addChild(selectionWindow);
			addChild(selectionWindowTaperNext);
			addChild(selectionWindowTaperPrevious);
			
			// selection prompt
			selectText = new TextBox(LIST_WIDTH, 1 + LINE_SPACING + TextBox.BORDER_ALLOWANCE * 2, 0x0, 0x0);
			selectText.text = "select";
			selectText.x = textHolder.x + nextTextBox.x;
			selectText.y = -(TextBox.BORDER_ALLOWANCE + 1) + textHolder.y + nextTextBox.y;
			selectText.alpha = 0;
			addChild(selectText);
			// movement arrows illustate where we can progress on the menu
			movementMovieClips = new Vector.<MovieClip>(4, true);
			for(i = 0; i < movementMovieClips.length; i++){
				movementMovieClips[i] = new MenuArrowMC();
				addChild(movementMovieClips[i]);
				movementMovieClips[i].visible = false;
			}
			movementMovieClips[UP_MOVE].x = (selectionWindow.x + selectionWindow.width * 0.5) >> 0;
			movementMovieClips[UP_MOVE].y = selectionWindow.y;
			movementMovieClips[RIGHT_MOVE].x = selectionWindow.x + selectionWindow.width;
			movementMovieClips[RIGHT_MOVE].y = (selectionWindow.y + selectionWindow.height * 0.5) >> 0;
			movementMovieClips[RIGHT_MOVE].rotation = 90;
			movementMovieClips[DOWN_MOVE].x = 1 + (selectionWindow.x + selectionWindow.width * 0.5) >> 0;
			movementMovieClips[DOWN_MOVE].y = selectionWindow.y + selectionWindow.height;
			movementMovieClips[DOWN_MOVE].rotation = 180;
			movementMovieClips[LEFT_MOVE].x = selectionWindow.x;
			movementMovieClips[LEFT_MOVE].y = 1 + (selectionWindow.y + selectionWindow.height * 0.5) >> 0;
			movementMovieClips[LEFT_MOVE].rotation = -90;
			
			addChild(help);
			
			if(trunk) setTrunk(trunk);
		}
		
		/* Overridden to perform actions the menu selects */
		public function executeSelection():void{
			
		}
		
		/* Overridden to change states of options as selections change */
		public function changeSelection():void{
			if(currentMenuList.options.length == 0) return;
			var option:MenuOption = currentMenuList.options[selection];
			if(parent && option.help){
				help.text = option.help;
			}
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
			moveReset = moveDelay;
			keysHeldCount = KEYS_HELD_DELAY;
			keyLock = true;
			update();
		}
		
		/* Returns a string representation of the current menu history.
		 * Use this to debug the menu and to quickly identify traversed menu paths
		 */
		public function branchString():String{
			return branchStringHistory + (branchStringHistory.length > 0 ? branchStringSeparator : "") + branchStringCurrentOption;
		}
		
		/* Sets the current MenuList selection, re-renders the menu and calls
		 * changeSelection()
		 */
		public function select(n:int):void{
			selection = n;
			currentMenuList.selection = n;
			if(currentMenuList.options.length){
				branchStringCurrentOption = currentMenuList.options[n].name;
				if(currentMenuList.options[n].target){
					nextMenuList = currentMenuList.options[n].target;
				} else {
					nextMenuList = null;
				}
			} else {
				nextMenuList = null;
			}
			if(parent) renderMenu();
			if(!hideChangeSelection) changeSelection();
		}
		
		/* Either walks forward to the MenuList pointed to by the current option
		 * or when there is no MenuList pointed to, fires the executeSelection method and
		 * jumps the menu back to the trunk.
		 */
		public function stepRight():void{
			if(
				!(nextMenuList && !nextMenuList.accessible) && (
					(hotKeyMapRecord && currentMenuList.options[selection].recordable) ||
					(!hotKeyMapRecord && currentMenuList.options[selection].active)
				)
			){
				// walk forward
				if(nextMenuList){
					// recording?
					if(hotKeyMapRecord){
						hotKeyMapRecord.push(currentMenuList.options[currentMenuList.selection], currentMenuList.selection);
					}
					
					// hot key? initialise a HotKeyMap
					if(currentMenuList.options[currentMenuList.selection].hotKeyOption){
						hotKeyMapRecord = new HotKeyMap(currentMenuList.selection, this);
						hotKeyMapRecord.init();
					}
					
					branchStringHistory += (branchStringHistory.length > 0 ? branchStringSeparator : "") + currentMenuList.options[selection].name;
					
					branch.push(nextMenuList);
					
					previousMenuList = currentMenuList;
					currentMenuList = nextMenuList;
					if(currentMenuList == keyChanger) keyLock = true;
					if(currentMenuList is MenuInputList) (currentMenuList as MenuInputList).begin();
					update();
					
				// nothing to walk forward to - call the executeSelection
				} else {
					dirStack.length = 0;
					// if the Menu is recording a path for a hot key, then we store that
					// hot key here:
					if(hotKeyMapRecord){
						hotKeyMapRecord.push(currentMenuList.options[currentMenuList.selection], currentMenuList.selection);
						hotKeyMaps[hotKeyMapRecord.key] = hotKeyMapRecord;
						hotKeyMapRecord = null;
						// because recording a hot key involves deactivating recursive MenuOptions
						// we have to return to the trunk by foot.
						hideChangeSelection = true;
						while(branch.length > 1) stepLeft();
						hideChangeSelection = false;
					} else {
						executeSelection();
						
						var selectionStep:int = currentMenuList.options[currentMenuList.selection].selectionStep;
						if(selectionStep == MenuOption.TRUNK) setTrunk(branch[0]);
						else {
							if(selectionStep == MenuOption.EXIT_MENU){
								setTrunk(branch[0]);
								if(Game.game.state == Game.MENU){
									Game.game.pauseGame();
								}
							} else {
								// inspect the branch list for empty menu lists that will crash the walk back
								// upon finding one we drop out to the root menu
								for(var i:int = branch.length - 1; i > -1; i--){
									if(branch[i].options.length == 0){
										setTrunk(branch[0]);
										return;
									}
								}
								// the step back and forth shakes out select events and updates the labels
								while(selectionStep--){
									stepLeft();
								}
								stepRight();
							}
						}
					}
				}
			}
		}
		
		/* Walk back to the previous MenuList. MenuLists and MenuOptions have no memory
		 * of their forebears, so the branch history and previousMenuList is used
		 */
		public function stepLeft():void{
			if(previousMenuList){
				// are we recording?
				if(hotKeyMapRecord){
					hotKeyMapRecord.pop();
					if(hotKeyMapRecord.length < 0){
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
				
				update();
			}
		}
		
		/* This renders the current menu state, though it is better to use select()
		 * as it will also update the branchString property and update
		 * what MenuList leads from the currently selected MenuOption.
		 */
		public function renderMenu():void{
			currentTextBox.visible = true;
			selectionWindow.visible = true;
			if(previousMenuList){
				previousTextBox.setSize(LIST_WIDTH, LINE_SPACING * previousMenuList.options.length + TextBox.BORDER_ALLOWANCE);
				previousTextBox.text = previousMenuList.optionsToString("\n", HotKeyMap.getOptionsHotKeyed(previousMenuList, hotKeyMaps));
				previousTextBox.y = -previousMenuList.selection * LINE_SPACING - TextBox.BORDER_ALLOWANCE;
				setLineCols(previousMenuList, previousTextBox);
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
				currentTextBox.setSize(LIST_WIDTH, LINE_SPACING * currentMenuList.options.length + TextBox.BORDER_ALLOWANCE);
				currentTextBox.text = currentMenuList.optionsToString("\n", HotKeyMap.getOptionsHotKeyed(currentMenuList, hotKeyMaps));
				currentTextBox.y = -currentMenuList.selection * LINE_SPACING - TextBox.BORDER_ALLOWANCE;
				setLineCols(currentMenuList, currentTextBox);
			}
			if(currentMenuList.options.length == 0){
				// assuming this is a MenuInfo being expanded
				if(currentMenuList is MenuInfo){
					(currentMenuList as MenuInfo).renderCallback();
					infoTextBox.visible = true;
					selectionWindowTaperNext.visible = false;
					nextTextBox.visible = false;
					currentTextBox.visible = false;
					selectionWindow.visible = false;
				}
				
			} else if(currentMenuList.options[selection].active && nextMenuList){
				if(nextMenuList is MenuInfo){
					(nextMenuList as MenuInfo).renderCallback();
					infoTextBox.visible = true;
					selectionWindowTaperNext.visible = false;
					nextTextBox.visible = false;
				} else {
					if(nextMenuList == keyChanger){
						keyChanger.options[0].name = Key.keyString(Key.custom[selection]);
					}
					nextTextBox.setSize(LIST_WIDTH, LINE_SPACING * nextMenuList.options.length + TextBox.BORDER_ALLOWANCE);
					nextTextBox.text = nextMenuList.optionsToString("\n", HotKeyMap.getOptionsHotKeyed(nextMenuList, hotKeyMaps));
					nextTextBox.y = -nextMenuList.selection * LINE_SPACING - TextBox.BORDER_ALLOWANCE;
					setLineCols(nextMenuList, nextTextBox);
					nextTextBox.visible = true;
					selectionWindowTaperNext.visible = true;
					infoTextBox.visible = false;
				}
			} else {
				infoTextBox.visible = false;
				nextTextBox.visible = false;
				selectionWindowTaperNext.visible = false;
			}
		}
		
		/* Updates the rendering of coloured MenuOptions (disabled and not-visited) */
		public function setLineCols(menuList:MenuList, textBox:TextBox):void{
			var menuOption:MenuOption;
			for(var i:int = 0; i < menuList.options.length; i++){
				menuOption = menuList.options[i];
				// disabled
				if(
					!(
						(hotKeyMapRecord && menuOption.recordable) ||
						(!hotKeyMapRecord && menuOption.active)
					)
				) textBox.setLineCol(i, DISABLED_COL);
				// not visited
				if(!menuOption.visited){
					textBox.setLineCol(i, NOT_VISITED_COLS[notVistitedColFrame]);
				}
			}
		}
		
		private function animateUp():void{
			//if((dir & UP) && moveReset > 2) moveReset--;
			
			// capture the next menu
			capture.capture(nextTextBox);
			capture.visible = nextTextBox.visible;
			capture.alpha = nextTextBox.alpha;
			nextTextBox.alpha = 0;
			infoTextBox.alpha = 0;
			nextAlphaStep = SIDE_ALPHAS / moveReset;
			captureAlphaStep = -SIDE_ALPHAS / moveReset;
			
			var currentY:Number = currentTextBox.y;
			select(selection - 1);
			vy = (currentTextBox.y - currentY) / moveReset;
			currentTextBox.y = currentY;
			
			SoundManager.playSound("step");
			
			dir |= UP;
			dir &= ~DOWN;
		}
		
		private function animateDown():void{
			//if((dir & DOWN) && moveReset > 2) moveReset--;
			
			// capture the next menu
			capture.capture(nextTextBox);
			capture.visible = nextTextBox.visible;
			capture.alpha = nextTextBox.alpha;
			nextTextBox.alpha = 0;
			infoTextBox.alpha = 0;
			nextAlphaStep = SIDE_ALPHAS / moveReset;
			captureAlphaStep = -SIDE_ALPHAS / moveReset;
			
			var currentY:Number = currentTextBox.y;
			select(selection + 1);
			vy = (currentTextBox.y - currentY) / moveReset;
			currentTextBox.y = currentY;
			
			SoundManager.playSound("step");
			
			dir |= DOWN;
			dir &= ~UP;
		}
		
		private function animateRight():void{
			if(nextMenuList){
				if(nextMenuList.accessible){
					// capture the previous menu
					capture.capture(previousTextBox);
					capture.visible = previousTextBox.visible;
					capture.alpha = previousTextBox.alpha;
					stepRight();
					
					previousTextBox.x += LIST_WIDTH;
					currentTextBox.x += LIST_WIDTH;
					nextTextBox.x += LIST_WIDTH;
					if(nextMenuList){
						infoTextBox.x += LIST_WIDTH;
						infoTextBox.alpha = 0;
					}
					previousTextBox.alpha = 1;
					currentTextBox.alpha = SIDE_ALPHAS;
					nextTextBox.alpha = 0;
					
					previousAlphaStep = (SIDE_ALPHAS - 1.0) / moveReset;
					currentAlphaStep = (1.0 - SIDE_ALPHAS) / moveReset;
					nextAlphaStep = 1.0 / moveReset;
					captureAlphaStep = -SIDE_ALPHAS / moveReset;
					vx = -LIST_WIDTH / moveReset;
			
					SoundManager.playSound("miss", 0.2);
				}
				
			// initialise and launch menu selection animation
			} else {
				// capture an image of the current menu state
				capture.capture(textHolder, new Matrix(1, 0, 0, 1, textHolder.x, textHolder.y), _width, _height);
				capture.x = -textHolder.x;
				capture.y = -textHolder.y;
				capture.alpha = 1;
				capture.visible = true;
				
				// copy, brighten, then erase the text of the selected item
				var selectionWindowRect:Rectangle = new Rectangle(selectionWindow.x, selectionWindow.y, selectionWindow.width, selectionWindow.height);
				selectionCopyBitmap.bitmapData.copyPixels(capture.bitmapData, selectionWindowRect, new Point());
				capture.bitmapData.fillRect(selectionWindowRect, 0x0);
				selectionCopyBitmap.visible = true;
				
				stepRight();
				// hide the advanced menu
				previousTextBox.alpha = 0;
				currentTextBox.alpha = 0;
				nextTextBox.alpha = 0;
			
				moveReset = moveDelay * 3;
				moveCount = moveReset;
				
				previousAlphaStep = SIDE_ALPHAS / moveReset;
				currentAlphaStep = 1.0 / moveReset;
				nextAlphaStep = SIDE_ALPHAS / moveReset;
				captureAlphaStep = -1.0 / moveReset;
				vx = -LIST_WIDTH / moveReset;
				
				animatingSelection = true;
				selectionWindowTaperNext.visible = false;
			
				SoundManager.playSound("click");
			}
			
			dir |= RIGHT;
			dir &= ~LEFT;
		}
		
		private function animateLeft():void{
			// capture the next menu
			if(infoTextBox.visible){
				capture.capture(infoTextBox);
				capture.visible = infoTextBox.visible;
				capture.alpha = 1;
			} else {
				capture.capture(nextTextBox);
				capture.visible = nextTextBox.visible;
				capture.alpha = previousTextBox.alpha;
			}
			stepLeft();
			
			previousTextBox.x -= LIST_WIDTH;
			currentTextBox.x -= LIST_WIDTH;
			nextTextBox.x -= LIST_WIDTH;
			previousTextBox.alpha = 0;
			currentTextBox.alpha = SIDE_ALPHAS;
			nextTextBox.alpha = 1;
			infoTextBox.alpha = 1;
			
			previousAlphaStep = 1.0 / moveReset;
			currentAlphaStep = (1.0 - SIDE_ALPHAS) / moveReset;
			nextAlphaStep = (SIDE_ALPHAS - 1.0) / moveReset;
			captureAlphaStep = -SIDE_ALPHAS / moveReset;
			vx = LIST_WIDTH / moveReset;
			
			SoundManager.playSound("miss", 0.2);
			
			dir |= LEFT;
			dir &= ~RIGHT;
		}
		
		/* We listen for key input here, the keyLock property is used to stop the menu
		 * endlessly firing the same selection */
		public function main(e:Event = null):void{
			var i:int, j:int, newKey:int, inputList:MenuInputList, menuInfo:MenuInfo
			
			// handle menu opening animation
			if(help.y < 0){
				help.y += helpVy;
				if(help.y >= 0) help.y = 0;
			}
			if(alpha < 1){
				alpha += alphaStep;
				if(alpha >= 1) alpha = 1;
			}
			
			// if we are listening for input:
			if(currentMenuList is MenuInputList){
				inputList = currentMenuList as MenuInputList;
				if(Key.keysPressed){
					if(!inputKeyPressed){
						newKey = Key.keyLog[Key.KEY_LOG_LENGTH - 1];
						if(inputList.newLineFinish && newKey == Keyboard.ENTER) inputList.finish();
						else if(newKey == Keyboard.DELETE || newKey == Keyboard.BACKSPACE) inputList.removeChar();
						else inputList.addChar(Key.keyString(newKey));
						inputKeyPressed = true;
						renderMenu();
					}
				} else {
					inputKeyPressed = false;
				}
				keyLock = true;
				if(inputList.done) stepLeft();
			}
			// if the keyChanger is active, listen for keys to change the current key set
			if(!keyLock && currentMenuList == keyChanger){
				if(Key.keysPressed){
					// ignore cursor keys - some idiot will try to brick the menu for themselves
					if(!(Key.isDown(Keyboard.UP) || Key.isDown(Keyboard.RIGHT) || Key.isDown(Keyboard.DOWN) || Key.isDown(Keyboard.LEFT))){
						newKey = Key.keyLog[Key.KEY_LOG_LENGTH - 1];
						Key.custom[previousMenuList.selection] = newKey;
						// change the menu names of the affected keys
						changeKeyName(changeKeysOption.target.options[previousMenuList.selection], newKey);
						if(previousMenuList.selection >= HOT_KEY_OFFSET){
							changeKeyName(hotKeyOption.target.options[previousMenuList.selection - HOT_KEY_OFFSET], newKey);
						}
						keyLock = true;
						stepLeft();
					} else {
						game.console.print("that would potentially break the menu");
					}
				}
			}
			// track hot keys so they can instantly perform menu actions
			// hot keys are accessible only when the keyLock is off or the menu is hidden
			if((parent && !keyLock) || !parent){
				for(i = 0; i < Key.hotKeyTotal; i++){
					if(hotKeyMaps[i]){
						if(Key.customDown(HOT_KEY_OFFSET + i)){
							if(!hotKeyDown[i]){
								hotKeyMaps[i].execute();
								keyLock = true;
								hotKeyDown[i] = true;
								break;
							}
						} else if(hotKeyDown[i]){
							hotKeyDown[i] = false;
						}
					}
				}
			}
			// load key inputs into a single variable
			var lastKeysDown:int = keysDown;
			keysDown = 0;
			if(Key.keysPressed){
				// bypass reading keys if the menu is not on the display list
				if(parent){
					if(!keyLock){
						
						if(
							((!game.multiplayer && Key.isDown(Keyboard.UP)) || Key.customDown(Game.UP_KEY)) &&
							!((!game.multiplayer && Key.isDown(Keyboard.DOWN)) || Key.customDown(Game.DOWN_KEY))
						){
							keysDown |= UP;
							keysDown &= ~DOWN;
						} else {
							keysLocked &= ~UP;
						}
						if (
							((!game.multiplayer && Key.isDown(Keyboard.DOWN)) || Key.customDown(Game.DOWN_KEY)) &&
							!((!game.multiplayer && Key.isDown(Keyboard.UP)) || Key.customDown(Game.UP_KEY))
						){
							keysDown |= DOWN;
							keysDown &= ~UP;
						} else {
							keysLocked &= ~DOWN;
						}
						if(
							((!game.multiplayer && Key.isDown(Keyboard.LEFT)) || Key.customDown(Game.LEFT_KEY)) &&
							!((!game.multiplayer && Key.isDown(Keyboard.RIGHT)) || Key.customDown(Game.RIGHT_KEY))
						){
							keysDown |= LEFT;
							keysDown &= ~RIGHT;
						} else {
							keysLocked &= ~LEFT;
						}
						if(
							((!game.multiplayer && Key.isDown(Keyboard.RIGHT)) || Key.customDown(Game.RIGHT_KEY)) &&
							!((!game.multiplayer && Key.isDown(Keyboard.LEFT)) || Key.customDown(Game.LEFT_KEY))
						){
							keysDown |= RIGHT;
							keysDown &= ~LEFT;
						} else {
							keysLocked &= ~RIGHT;
						}
					}
				} else {
					keyLock = true;
				}
				if(lastKeysDown & keysDown){
					if(keysHeldCount) keysHeldCount--;
				}
			} else {
				keyLock = false;
				keysLocked = 0;
				lastKeysDown = 0;
				moveReset = moveDelay;
				keysHeldCount = KEYS_HELD_DELAY;
			}
			// load directions in - keys are locked out of new input unless held down till
			// keysHeldCount reaches zero - then fast browsing is activated
			if(keysDown){
				if(!(keysDown & keysLocked)){
					dirStack.push(keysDown);
					keysLocked |= keysDown;
				} else if(keysHeldCount == 0 && moveCount == 0){
					dirStack.push(keysDown);
				}
			}
				
			// animate marquees and movement guides
			if(parent){
				if(dir == 0 && dirStack.length == 0){
					if(previousTextBox.visible){
						previousTextBox.updateMarquee();
						setLineCols(previousMenuList, previousTextBox);
					}
					if(currentTextBox.visible){
						currentTextBox.updateMarquee();
						setLineCols(currentMenuList, currentTextBox);
					}
					if(nextTextBox.visible){
						nextTextBox.updateMarquee();
						setLineCols(nextMenuList, nextTextBox);
					}
					if(infoTextBox.visible){
						menuInfo = (nextMenuList as MenuInfo) || (currentMenuList as MenuInfo);
						if(menuInfo.update){
							menuInfo.renderCallback();
						} else {
							infoTextBox.updateMarquee();
						}
					}
					// update the visited glow frame
					notVistitedColFrame++;
					if(notVistitedColFrame >= NOT_VISITED_COLS.length) notVistitedColFrame = 0;
					
					if(movementGuideCount){
						if(currentMenuList != keyChanger && !(currentMenuList is MenuInputList)) movementGuideCount--;
						if(movementGuideCount == 0){
							for(i = 0; i < movementMovieClips.length; i++) movementMovieClips[i].gotoAndPlay(1);
						}
					} else {
						movementMovieClips[UP_MOVE].visible = currentMenuList.selection > 0;
						movementMovieClips[DOWN_MOVE].visible = currentMenuList.selection < currentMenuList.options.length - 1;
						movementMovieClips[RIGHT_MOVE].visible = currentMenuList.options.length && currentMenuList.options[selection].active && !(nextMenuList && !nextMenuList.accessible);
						movementMovieClips[LEFT_MOVE].visible = Boolean(previousMenuList);
					}
					if(
						currentMenuList.options.length &&
						currentMenuList.options[selection].active &&
						!nextMenuList &&
						!(currentMenuList is MenuInputList) &&
						selectText.alpha < 1
					){
						selectText.alpha += 0.1;
					}
				} else {
					movementGuideCount = MOVEMENT_GUIDE_DELAY;
					for(i = 0; i < movementMovieClips.length; i++) movementMovieClips[i].visible = false;
					selectText.alpha = 0;
				}
			}
			// check if there are directions loaded into the dirStack
			if(dir == 0){
				do{
					if(dirStack.length){
						dir = dirStack.shift();
						if((dir & UP) && selection > 0) animateUp();
						else if((dir & DOWN) && selection < currentMenuList.options.length - 1) animateDown();
						else if(
							(dir & RIGHT) &&
							(
								currentMenuList.options.length &&
								!(nextMenuList && !nextMenuList.accessible) && (
									(hotKeyMapRecord && currentMenuList.options[selection].recordable) ||
									(!hotKeyMapRecord && currentMenuList.options[selection].active)
								)
							)
						){
							animateRight();
						}
						else if((dir & LEFT) && previousMenuList) animateLeft();
						else {
							// illegal move
							dir = 0;
						}
						// mark option visited
						if(currentMenuList.options.length) currentMenuList.options[currentMenuList.selection].visited = true;
						
					} else break;
				} while(dir == 0);
				if(dir) moveCount = moveReset;
				
			// animate the menu
			} else {
				// selection animation
				if(animatingSelection){
					capture.alpha += captureAlphaStep;
					capture.x += vx;
					if(capture.alpha <= 0){
						selectionCopyBitmap.visible = false;
						animatingSelection = false;
						moveReset = moveDelay;
						vx = 0;
						// flush the direction stack again to avoid leaping off selecting things after the anim
						dirStack.length = 0;
					}
				} else {
					// browsing animation
					if(moveCount){
						if(dir & (UP | DOWN)){
							currentTextBox.y += vy;
							nextTextBox.alpha += nextAlphaStep;
							infoTextBox.alpha += nextAlphaStep;
							capture.alpha += captureAlphaStep;
						}
						if(dir & (RIGHT | LEFT)){
							previousTextBox.x += vx;
							currentTextBox.x += vx;
							nextTextBox.x += vx;
							infoTextBox.x += vx;
							capture.x += vx;
							previousTextBox.alpha += previousAlphaStep;
							currentTextBox.alpha += currentAlphaStep;
							nextTextBox.alpha += nextAlphaStep;
							infoTextBox.alpha += nextAlphaStep;
							capture.alpha += captureAlphaStep;
							
							if(infoTextBox.visible){
								menuInfo = (currentMenuList as MenuInfo) || (nextMenuList as MenuInfo);
								if(menuInfo == currentMenuList || (menuInfo == nextMenuList && (dir & LEFT))){
									infoTextBox.setSize(infoTextBox.width - vx, infoTextBox.height);
								}
							}
						}
						
						moveCount--;
						// animation over
						if(moveCount == 0){
							// force everything into its right place to flush floating point errors
							currentTextBox.x = 0;
							previousTextBox.x = -LIST_WIDTH;
							nextTextBox.x = LIST_WIDTH;
							infoTextBox.x = (currentMenuList is MenuInfo) ? 0 : LIST_WIDTH;
							currentTextBox.alpha = 1;
							previousTextBox.alpha = nextTextBox.alpha = SIDE_ALPHAS;
							infoTextBox.alpha = 1;
							capture.alpha = 0;
							dir = 0;
							// reduce the animation time when holding down keys for fast browsing
							if(keysDown && keysHeldCount == 0){
								if(moveReset > 1) moveReset--;
							} else {
								moveReset = moveDelay;
							}
							if(menuInfo){
								if(currentMenuList == menuInfo){
									infoTextBox.setSize(INFO_TEXT_BOX_WIDTH + LIST_WIDTH, infoTextBox.height);
								} else if(nextMenuList == menuInfo){
									infoTextBox.setSize(INFO_TEXT_BOX_WIDTH, infoTextBox.height);
								}
							}
							update();
						}
					}
				}
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
				), SELECTION_WINDOW_COL);
			selectionWindow.bitmapData.fillRect(
				new Rectangle(
					selectionWindow.bitmapData.rect.x + 1,
					selectionWindow.bitmapData.rect.y + 1,
					selectionWindow.bitmapData.rect.width - 2,
					selectionWindow.bitmapData.rect.height- 2
				), 0x0);
				var step:int = 255 / SELECTION_WINDOW_TAPER_WIDTH;
			for(var c:uint = SELECTION_WINDOW_COL, n:int = 0; n < SELECTION_WINDOW_TAPER_WIDTH; c -= 0x01000000 * step, n++){
				selectionWindowTaperNext.bitmapData.setPixel32(n, 0, c);
				selectionWindowTaperNext.bitmapData.setPixel32(n, selectionWindow.height-1, c);
				selectionWindowTaperPrevious.bitmapData.setPixel32(SELECTION_WINDOW_TAPER_WIDTH - n, 0, c);
				selectionWindowTaperPrevious.bitmapData.setPixel32(SELECTION_WINDOW_TAPER_WIDTH - n, selectionWindow.height - 1, c);
			}
		}
		
		/* Short hand for calling select(currentMenuList.selection) - and more obvious */
		public function update():void{
			select(currentMenuList.selection);
		}
		
		/* Called when opening the menu */
		public function activate():void{
			update();
			help.y = -help.height;
			helpVy = help.height / (moveDelay * 2);
			alpha = 0;
			alphaStep = 1.0 / moveDelay;
			renderMenu();
			carousel.addChild(this);
		}
		
		/* Called when closing the menu */
		public function deactivate():void{
			if(parent) parent.removeChild(this);
		}
		
		/* Inits a MenuOption that leads to a MenuList offering the ability to redefine keys. */
		public function initChangeKeysMenuOption():void{
			var keyChangerOption:MenuOption = new MenuOption("no key data");
			var keyChangerOptions:Vector.<MenuOption> = new Vector.<MenuOption>();
			keyChangerOptions.push(keyChangerOption);
			keyChanger = new MenuList(keyChangerOptions);
			
			var changeKeysMenuOptions:Vector.<MenuOption> = new Vector.<MenuOption>();
			changeKeysMenuOptions.push(new MenuOption("up:" + Key.keyString(Key.custom[0]), keyChanger));
			changeKeysMenuOptions.push(new MenuOption("down:" + Key.keyString(Key.custom[1]), keyChanger));
			changeKeysMenuOptions.push(new MenuOption("left:" + Key.keyString(Key.custom[2]), keyChanger));
			changeKeysMenuOptions.push(new MenuOption("right:" + Key.keyString(Key.custom[3]), keyChanger));
			changeKeysMenuOptions.push(new MenuOption("menu:" + Key.keyString(Key.custom[4]), keyChanger));
			
			var changeKeysMenuList:MenuList = new MenuList(changeKeysMenuOptions);
			
			for(var i:int = 0; i < Key.hotKeyTotal; i++){
				changeKeysMenuList.options.push(new MenuOption("hot key:" + Key.keyString(Key.custom[HOT_KEY_OFFSET + i]), keyChanger));
			}
			changeKeysOption = new MenuOption("change keys", changeKeysMenuList);
			changeKeysOption.recordable = false;
		}
		
		/* Returns a MenuOption that leads to a MenuList offering the ability to create "hot keys"
		 *
		 * Recording a hot key involves walking from the trunk out and firing a executeSelection
		 * method. This will not fire the method, but store the selections made and bind
		 * them to that hot key. Pressing the hot key will then walk the menu back to the trunk
		 * and out to the selected option for that hot key.
		 *
		 * This feature requires submitting the trunk MenuList and a MenuOption that can be
		 * deactivated to prevent the user from walking out to the hot key menu again or
		 * doing another menu activity like redefining keys. I will expand the deactivation
		 * reference to an array at a later date.
		 */
		public function initHotKeyMenuOption(trunk:MenuList):void{
			var hotKeyMenuList:MenuList = new MenuList();
			var option:MenuOption;
			hotKeyOption = new MenuOption("set hot key");
			hotKeyOption.recordable = false;
			for(var i:int = 0; i < Key.hotKeyTotal; i++){
				option = new MenuOption("");
				option.name = "hot key:" + Key.keyString(Key.custom[HOT_KEY_OFFSET + i]);
				option.help = "pressing right on the menu will begin recording. execute a menu option to bind it to this key. this will not actually execute the option"
				option.target = trunk;
				option.hotKeyOption = true;
				hotKeyMenuList.options.push(option);
			}
			hotKeyOption.target = hotKeyMenuList
		}
		
		/* Initialise the glow on non visited options */
		private function initNotVisitedCols():void{
			NOT_VISITED_COLS = new Vector.<ColorTransform>();
			var colSteps:Number = 30;
			var step:Number = Math.PI / colSteps;
			var colMax:Number = 100;
			var colTransform:ColorTransform;
			for(var i:int = 0; i < colSteps; i++){
				colTransform = new ColorTransform(1, 1, 1, 1, colMax * Math.sin(step * i), colMax * Math.sin(step * i), colMax * Math.sin(step * i), colMax * Math.sin(step * i));
				NOT_VISITED_COLS.push(colTransform);
			}
		}
		
		/* Changes the name of a menu option associated with a key to a given keyCode */
		private function changeKeyName(option:MenuOption, newKey:int):void{
			var str:String = option.name.substr(0, option.name.indexOf(":") + 1) + Key.keyString(newKey);
			option.name = str;
		}
		
		/* Checks the branch array for the presence of a MenuList */
		public function listInBranch(list:MenuList):Boolean{
			for(var i:int = 0; i < branch.length; i++){
				if(branch[i] == list){
					return true;
				}
			}
			return false;
		}
		
	}

}