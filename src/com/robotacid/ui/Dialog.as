package com.robotacid.ui {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	/**
	 * A pop up dialog
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Dialog extends Sprite{
		
		private var active:Boolean;
		private var okayCallback:Function;
		private var okayTextBox:TextBox;
		private var okayButton:Sprite;
		private var previousGameState:int;
		
		public static var game:Game;
		
		public static const WIDTH:Number = 200;
		public static const ROLL_OUT_COL:uint = 0xFF000000;
		public static const ROLL_OVER_COL:uint = 0xFF555555;
		
		public function Dialog(titleStr:String, text:String, okayCallback:Function = null) {
			this.okayCallback = okayCallback;
			active = true;
			alpha = 0;
			x = Game.WIDTH * 0.5;
			y = Game.HEIGHT * 0.5;
			var textBox:TextBox = new TextBox(WIDTH, 12, 0x00000000, 0x00000000);
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
			var titleBox:TextBox = new TextBox(WIDTH - 20, 12, ROLL_OUT_COL);
			titleBox.align = "center";
			titleBox.text = titleStr;
			titleBox.y = background.y + 2;
			titleBox.x = -(titleBox.width * 0.5) >> 0;
			addChild(titleBox);
			okayButton = new Sprite();
			okayTextBox = new TextBox(WIDTH - 20, 12, ROLL_OUT_COL);
			okayTextBox.align = "center";
			okayTextBox.text = "press menu key";
			okayButton.addChild(okayTextBox);
			okayButton.y = background.y + background.height - (okayTextBox.height + 2);
			okayButton.x = -(okayTextBox.width * 0.5) >> 0;
			addChild(okayButton);
			okayButton.addEventListener(MouseEvent.CLICK, okay, false, 0, true);
			okayButton.addEventListener(MouseEvent.ROLL_OVER, okayOver, false, 0, true);
			okayButton.addEventListener(MouseEvent.ROLL_OUT, okayOut, false, 0, true);
			game.stage.addEventListener(KeyboardEvent.KEY_DOWN, okay);
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
			if(e is KeyboardEvent){
				// we've locked out keys so we have to go for the Key class' internals
				if((e as KeyboardEvent).keyCode != Key.custom[Game.MENU_KEY]) return;
			}
			if(Boolean(okayCallback)) okayCallback();
			active = false;
			Key.lockOut = false;
			Game.dialog = null;
			game.stage.removeEventListener(KeyboardEvent.KEY_DOWN, okay);
			game.state = previousGameState;
		}
		
		private function okayOver(e:MouseEvent):void{
			okayTextBox.backgroundCol = ROLL_OVER_COL;
			okayTextBox.draw();
		}
		
		private function okayOut(e:MouseEvent):void{
			okayTextBox.backgroundCol = ROLL_OUT_COL;
			okayTextBox.draw();
		}
	}

}