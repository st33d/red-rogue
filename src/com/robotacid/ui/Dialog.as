package com.robotacid.ui {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	/**
	 * A pop up dialog for those moments where the disconnect between the mouse and keyboard events and my
	 * code causes a security error
	 * 
	 * There should only be ONE dialog at a time, using Game.dialog as its reference to avoid stacking dialogs
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Dialog extends Sprite{
		
		private var active:Boolean;
		private var okayCallback:Function;
		private var okayTextBox:TextBox;
		private var okayButton:Sprite;
		
		private static const ROLL_OUT_COL:uint = 0xFF000000;
		private static const ROLL_OVER_COL:uint = 0xFF555555;
		
		public function Dialog(titleStr:String, text:String, width:Number, height:Number, okayCallback:Function = null) {
			this.okayCallback = okayCallback;
			active = true;
			alpha = 0;
			x = Game.WIDTH * 0.5;
			y = Game.HEIGHT * 0.5;
			var textBox:TextBox = new TextBox(width, height);
			textBox.align = "center";
			textBox.alignVert = "center";
			textBox.text = text;
			textBox.x = -width * 0.5;
			textBox.y = -height * 0.5;
			addChild(textBox);
			var titleBox:TextBox = new TextBox(width * 0.8, 12, ROLL_OUT_COL);
			titleBox.align = "center";
			titleBox.text = titleStr;
			titleBox.y = textBox.y + 2;
			titleBox.x = -(titleBox.width * 0.5) >> 0;
			addChild(titleBox);
			okayButton = new Sprite();
			okayTextBox = new TextBox(100, 12, ROLL_OUT_COL);
			okayTextBox.align = "center";
			okayTextBox.text = "okay";
			okayButton.addChild(okayTextBox);
			okayButton.y = textBox.y + textBox.height - (okayTextBox.height + 2);
			okayButton.x = -(okayTextBox.width * 0.5) >> 0;
			addChild(okayButton);
			okayButton.addEventListener(MouseEvent.CLICK, okay, false, 0, true);
			okayButton.addEventListener(MouseEvent.ROLL_OVER, okayOver, false, 0, true);
			okayButton.addEventListener(MouseEvent.ROLL_OUT, okayOut, false, 0, true);
			addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
			Game.g.addChild(this);
			Key.forceClearKeys();
			Key.lockOut = true;
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
		
		private function okay(e:MouseEvent):void{
			if(Boolean(okayCallback)) okayCallback();
			active = false;
			Key.lockOut = false;
			Game.dialog = null;
			Key.forceClearKeys();
			stage.focus = stage;
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