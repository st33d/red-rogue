package com.robotacid.ui {
	import com.robotacid.ui.menu.Menu;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	/**
	 * A pop up dialog
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Dialog extends Sprite{
		
		private var active:Boolean;
		private var okayCallback:Function;
		private var cancelCallback:Function;
		private var okayTextBox:TextBox;
		private var cancelTextBox:TextBox;
		private var okayButton:Sprite;
		private var cancelButton:Sprite;
		private var previousGameState:int;
		
		public static var game:Game;
		
		public static const WIDTH:Number = 220;
		public static const ROLL_OUT_COL:uint = 0xFF000000;
		public static const ROLL_OVER_COL:uint = 0xFF555555;
		
		public function Dialog(titleStr:String, text:String, okayCallback:Function = null, cancelCallback:Function = null) {
			this.okayCallback = okayCallback;
			this.cancelCallback = cancelCallback;
			active = true;
			alpha = 0;
			x = Game.WIDTH * 0.5;
			y = Game.HEIGHT * 0.5;
			
			// create background and text
			var textBox:TextBox = new TextBox(WIDTH, 12, 0x0, 0x0);
			textBox.align = "center";
			textBox.alignVert = "center";
			textBox.text = text;
			// resize TextBox to match text
			textBox.setSize(WIDTH, 2 + textBox.lines.length * textBox.lineSpacing);
			textBox.x = -(textBox.width * 0.5) >> 0;
			textBox.y = -(textBox.height * 0.5) >> 0;
			var background:Bitmap = new Bitmap(new BitmapData(WIDTH, textBox.height + 48, true, 0xFF999999));
			background.bitmapData.fillRect(new Rectangle(1, 1, background.width - 2, background.height - 2), 0xFF111111);
			background.x = -(background.width * 0.5) >> 0;
			background.y = -(background.height * 0.5) >> 0;
			addChild(background);
			addChild(textBox);
			
			// create title
			var titleBox:TextBox = new TextBox(WIDTH - 20, 12, ROLL_OUT_COL);
			titleBox.align = "center";
			titleBox.text = titleStr;
			titleBox.y = background.y + 2;
			titleBox.x = -(titleBox.width * 0.5) >> 0;
			addChild(titleBox);
			
			// buttons:
			// there is always an okay button
			okayButton = new Sprite();
			okayTextBox = new TextBox(Menu.LIST_WIDTH, 12, ROLL_OUT_COL);
			okayTextBox.align = "center";
			okayButton.addChild(okayTextBox);
			addChild(okayButton);
			okayButton.addEventListener(MouseEvent.CLICK, okay, false, 0, true);
			okayButton.addEventListener(MouseEvent.ROLL_OVER, okayOver, false, 0, true);
			okayButton.addEventListener(MouseEvent.ROLL_OUT, okayOut, false, 0, true);
			game.stage.addEventListener(KeyboardEvent.KEY_DOWN, okay);
			
			if(!Boolean(cancelCallback)){
				// create singular okay button
				okayTextBox.text = "press menu key";
				okayButton.y = background.y + background.height - (okayTextBox.height + 2);
				okayButton.x = -(okayTextBox.width * 0.5) >> 0;
				
			} else {
				// create two buttons
				cancelButton = new Sprite();
				cancelTextBox = new TextBox(Menu.LIST_WIDTH, 12, ROLL_OUT_COL);
				cancelTextBox.align = "center";
				cancelButton.addChild(cancelTextBox);
				addChild(cancelButton);
				cancelButton.addEventListener(MouseEvent.CLICK, cancel, false, 0, true);
				cancelButton.addEventListener(MouseEvent.ROLL_OVER, cancelOver, false, 0, true);
				cancelButton.addEventListener(MouseEvent.ROLL_OUT, cancelOut, false, 0, true);
				game.stage.addEventListener(KeyboardEvent.KEY_DOWN, cancel);
				
				okayTextBox.text = "right to accept";
				cancelTextBox.text = "left to cancel";
				
				okayButton.y = background.y + background.height - (okayTextBox.height + 2);
				okayButton.x = 1;
				cancelButton.y = background.y + background.height - (cancelTextBox.height + 2);
				cancelButton.x = -(cancelButton.width + 1);
			}
			
			// launch dialog
			addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
			game.addChild(this);
			Key.lockOut = true;
			previousGameState = game.state;
			game.state = Game.DIALOG;
		}
		
		private function onEnterFrame(e:Event):void{
			if(active){
				if(alpha < 1) alpha += 0.1;
			} else {
				if(alpha > 0){
					alpha -= 0.1;
				} else {
					removeEventListener(Event.ENTER_FRAME, onEnterFrame);
					if(parent) parent.removeChild(this);
				}
			}
		}
		
		private function okay(e:Event):void{
			if(!active) return;
			if(e is KeyboardEvent){
				// we've locked out keys so we have to go for the Key class' internals
				if(!Boolean(cancelCallback)){
					if((e as KeyboardEvent).keyCode != Key.custom[Game.MENU_KEY]) return;
				} else {
					if(!((e as KeyboardEvent).keyCode == Key.custom[Game.RIGHT_KEY] || (e as KeyboardEvent).keyCode == Keyboard.RIGHT)) return;
				}
			}
			active = false;
			Key.lockOut = false;
			game.stage.removeEventListener(KeyboardEvent.KEY_DOWN, okay);
			game.state = previousGameState;
			if(Boolean(okayCallback)) okayCallback();
			Game.dialog = null;
		}
		
		private function cancel(e:Event):void{
			if(!active) return;
			if(e is KeyboardEvent){
				// we've locked out keys so we have to go for the Key class' internals
				if(!((e as KeyboardEvent).keyCode == Key.custom[Game.LEFT_KEY] || (e as KeyboardEvent).keyCode == Keyboard.LEFT)) return;
			}
			active = false;
			Key.lockOut = false;
			game.stage.removeEventListener(KeyboardEvent.KEY_DOWN, okay);
			game.stage.removeEventListener(KeyboardEvent.KEY_DOWN, cancel);
			game.state = previousGameState;
			cancelCallback();
			Game.dialog = null;
		}
		
		private function okayOver(e:MouseEvent):void{
			okayTextBox.backgroundCol = ROLL_OVER_COL;
			okayTextBox.draw();
		}
		
		private function okayOut(e:MouseEvent):void{
			okayTextBox.backgroundCol = ROLL_OUT_COL;
			okayTextBox.draw();
		}
		
		private function cancelOver(e:MouseEvent):void{
			cancelTextBox.backgroundCol = ROLL_OVER_COL;
			cancelTextBox.draw();
		}
		
		private function cancelOut(e:MouseEvent):void{
			cancelTextBox.backgroundCol = ROLL_OUT_COL;
			cancelTextBox.draw();
		}
		
		/* Fills in for all the empty callbacks fed to the Dialog */
		public static function emptyCallback():void{
			//
		}
	}

}