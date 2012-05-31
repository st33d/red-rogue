package com.robotacid.ui {
	import com.robotacid.engine.Character;
	import com.robotacid.engine.Chest;
	import com.robotacid.engine.Entity;
	import com.robotacid.engine.Item;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.phys.Collider;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	/**
	 * Suggests courses of action to the player
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Suggestion {
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		public var active:Boolean;
		public var known:int;
		public var teach:int;
		public var skill:int;
		
		private var showCount:int;
		private var skillPrompt:TextBox;
		private var menuPrompt:TextBox;
		private var movementMovieClips:Vector.<MovieClip>;
		private var sprite:Sprite;
		
		private var entity:Entity;
		
		private var i:int, movieClip:MovieClip;
		
		public static const SHOW_DELAY:int = 30;
		public static const TEXT_BACKGROUND_COL:uint = 0x99000000;
		public static var col:ColorTransform = new ColorTransform(1, 0, 0);
		
		// character movement
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		// guide movement
		public static const UP_MOVE:int = 0;
		public static const RIGHT_MOVE:int = 1;
		public static const DOWN_MOVE:int = 2;
		public static const LEFT_MOVE:int = 3;
		
		// skills
		public static const MOVE:int = 1 << 0;
		public static const CLIMB:int = 1 << 1;
		public static const DROP:int = 1 << 2;
		public static const KILL:int = 1 << 3;
		public static const EXIT:int = 1 << 4;
		public static const COLLECT:int = 1 << 5;
		public static const READ:int = 1 << 6;
		public static const DISARM:int = 1 << 7;
		
		public function Suggestion() {
			
			
			active = false;
			
			
			sprite = new Sprite();
			skillPrompt = new TextBox(100, 13, TEXT_BACKGROUND_COL, TEXT_BACKGROUND_COL);
			skillPrompt.x = - skillPrompt.width * 0.5;
			skillPrompt.y = -(Game.SCALE + skillPrompt.height);
			skillPrompt.align = "center";
			skillPrompt.alignVert = "center";
			skillPrompt.wordWrap = false;
			sprite.addChild(skillPrompt);
			menuPrompt = new TextBox(Game.WIDTH, 13, TEXT_BACKGROUND_COL, TEXT_BACKGROUND_COL);
			menuPrompt.y = Game.HEIGHT - (Console.HEIGHT + menuPrompt.height);
			movementMovieClips = new Vector.<MovieClip>(4, true);
			for(i = 0; i < movementMovieClips.length; i++){
				movementMovieClips[i] = new MenuArrowMC();
				movementMovieClips[i].visible = false;
				sprite.addChild(movementMovieClips[i]);
			}
			movementMovieClips[UP_MOVE].y = -Game.SCALE;
			movementMovieClips[RIGHT_MOVE].x = Game.SCALE * 0.5;
			movementMovieClips[RIGHT_MOVE].y = -Game.SCALE * 0.5;
			movementMovieClips[RIGHT_MOVE].rotation = 90;
			movementMovieClips[DOWN_MOVE].rotation = 180;
			movementMovieClips[LEFT_MOVE].x = -Game.SCALE * 0.5;
			movementMovieClips[LEFT_MOVE].y = -Game.SCALE * 0.5;
			movementMovieClips[LEFT_MOVE].rotation = -90;
			showCount = SHOW_DELAY;
			teach = MOVE | CLIMB | DROP | KILL | EXIT | COLLECT | COLLECT | DISARM;
		}
		
		public function render():void{
			if(!game.player.active || game.player.indifferent || game.player.asleep) return;
			
			// combat involves a lot of state changes, we monitor exiting it from within the teach
			if(skill != KILL && game.player.state != Character.WALKING) return;
			
			if(showCount) showCount--;
			else {
				if(skill == 0){
					
					hideGfx();
					
					// the order of checks sets the order we teach
					
					if(teach & MOVE){
						skill = MOVE;
						movementMovieClips[LEFT_MOVE].visible = true;
						movementMovieClips[RIGHT_MOVE].visible = true;
						skillPrompt.visible = true;
						skillPrompt.text = "walk";
						skillPrompt.setSize(skillPrompt.lineWidths[0] + 6, 13);
						skillPrompt.x = -(skillPrompt.width * 0.5) >> 0;
						
					} else {
						if((teach & CLIMB) && game.player.canClimb()){
							skill = CLIMB;
							movementMovieClips[UP_MOVE].visible = true;
							movementMovieClips[DOWN_MOVE].visible = true;
							skillPrompt.visible = true;
							skillPrompt.text = "climb";
							
						} else if(
							(teach & DROP) &&
							game.player.collider.parent &&
							(game.player.collider.parent.properties & Collider.LEDGE)
						){
							skill = DROP;
							movementMovieClips[DOWN_MOVE].visible = true;
							skillPrompt.visible = true;
							skillPrompt.text = "drop";
						} else if(
							(teach & KILL) &&
							(
								(
									game.player.collider.leftContact &&
									(game.player.collider.leftContact.properties & Collider.CHARACTER) &&
									game.player.enemy(game.player.collider.leftContact.userData)
								) || (
									game.player.collider.rightContact &&
									(game.player.collider.rightContact.properties & Collider.CHARACTER) &&
									game.player.enemy(game.player.collider.rightContact.userData)
								)
							)
							){
								skill = KILL;
								skillPrompt.visible = true;
								skillPrompt.text = "kill";
							if(
								game.player.collider.leftContact &&
								(game.player.collider.leftContact.properties & Collider.CHARACTER) &&
								game.player.enemy(game.player.collider.leftContact.userData)
							){
								movementMovieClips[LEFT_MOVE].visible = true;
								entity = game.player.collider.leftContact.userData;
							} else if(
								game.player.collider.rightContact &&
								(game.player.collider.rightContact.properties & Collider.CHARACTER) &&
								game.player.enemy(game.player.collider.rightContact.userData)
							){
								movementMovieClips[RIGHT_MOVE].visible = true;
								entity = game.player.collider.rightContact.userData;
							}
							
						} else if((teach & EXIT) && game.player.portalContact){
							skill = EXIT;
							movementMovieClips[DOWN_MOVE].visible = true;
							skillPrompt.visible = true;
							skillPrompt.text = "exit";
							
						} else {
							if(teach & COLLECT){
								for(i = 0; i < game.items.length; i++){
									entity = game.items[i];
									if(
										(
											(entity is Item) &&
											(entity as Item).collider.intersects(game.player.collider)
										) || (
											(entity is Chest) &&
											(entity as Chest).mimicState == Chest.NONE &&
											(entity as Chest).rect.intersects(game.player.collider)
										)
									){
										skill = COLLECT;
										movementMovieClips[UP_MOVE].visible = true;
										skillPrompt.visible = true;
										skillPrompt.text = "collect";
										break;
									}
								}
								if(i == game.items.length) entity = null;
							}
							if(skill == 0 && (teach & (READ | DISARM))){
								
								
								
								
								
								
								// to do
								
								
								
								
								
								
								
								
							}
						}
					}
					if(skill && skillPrompt.visible){
						skillPrompt.setSize(skillPrompt.lineWidths[0] + 6, 13);
						skillPrompt.x = -(skillPrompt.width * 0.5) >> 0;
					}
					
				} else {
					var needsTeaching:Boolean = true;
					if(skill == MOVE){
						if(game.player.actions){
							known |= MOVE;
							teach &= ~MOVE;
							needsTeaching = false;
						}
					} else if(skill == CLIMB){
						if(game.player.collider.state == Collider.HOVER){
							known |= CLIMB;
							teach &= ~CLIMB;
							needsTeaching = false;
						} else if(!game.player.canClimb()){
							needsTeaching = false;
						}
					} else if(skill == DROP){
						if(game.player.dir & DOWN){
							known |= DROP;
							teach &= ~DROP;
							needsTeaching = false;
						} else if(
							game.player.collider.parent &&
							!(game.player.collider.parent.properties & Collider.LEDGE)
						){
							needsTeaching = false;
						}
					} else if(skill == KILL){
						var character:Character = entity as Character;
						if(!character.active){
							needsTeaching = false;
							// was the player trying to kill them?
							if(
								(movementMovieClips[LEFT_MOVE].visible && (game.player.actions & LEFT)) ||
								(movementMovieClips[RIGHT_MOVE].visible && (game.player.actions & RIGHT))
							){
								known |= KILL;
								teach &= ~KILL;
								entity = null;
							}
						} else {
							// if they are too far away,
							// have changed which side of the player they are on
							// or the player is in a state where they can't attack, abort
							if(
								character.mapY != game.player.mapY ||
								Math.abs(character.mapX - game.player.mapX) > 1 ||
								(movementMovieClips[LEFT_MOVE].visible && (game.player.mapX < character.mapX)) ||
								(movementMovieClips[RIGHT_MOVE].visible && (game.player.mapX > character.mapX)) ||
								game.player.state == Character.QUICKENING ||
								game.player.state == Character.EXITING ||
								game.player.state == Character.ENTERING
							){
								needsTeaching = false;
								entity = null;
							}
						}
					} else if(skill == EXIT){
						if(!game.player.portalContact) needsTeaching = false;
						else if(game.player.portal || (game.player.actions & DOWN)){
							needsTeaching = false;
							known |= EXIT;
							teach &= ~EXIT;
						}
						
					} else if(skill == COLLECT){
						if(
							(
								entity is Item &&
								!(entity as Item).collider.intersects(game.player.collider)
							) || (
								entity is Chest &&
								!(entity as Chest).rect.intersects(game.player.collider)
							)
						) needsTeaching = false;
						else if(game.player.actions & UP){
							needsTeaching = false;
							known |= COLLECT;
							teach &= ~COLLECT;
						}
					}
					
					if(!needsTeaching){
						skill = 0;
						showCount = SHOW_DELAY;
						
					} else {
						// render
						if(col.alphaMultiplier < 1) col.alphaMultiplier += 0.1;
						else if(col.alphaMultiplier > 1) col.alphaMultiplier = 1;
						sprite.x = -renderer.bitmap.x + game.player.gfx.x;
						sprite.y = -renderer.bitmap.y + game.player.gfx.y;
						renderer.bitmapData.draw(sprite, sprite.transform.matrix, col);
						if(menuPrompt.visible){
							renderer.bitmapData.draw(menuPrompt, menuPrompt.transform.matrix, col);
						}
					}
				}
			}
		}
		
		/* Set all prompt graphics invisible */
		public function hideGfx():void{
			skillPrompt.visible = false;
			menuPrompt.visible = false;
			col.alphaMultiplier = 0;
			movementMovieClips[UP_MOVE].visible = false;
			movementMovieClips[DOWN_MOVE].visible = false;
			movementMovieClips[LEFT_MOVE].visible = false;
			movementMovieClips[RIGHT_MOVE].visible = false;
		}
		
	}

}