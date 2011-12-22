package com.robotacid.util.misc {
	
	/* A check to see if (x,y) is on screen plus a border */
	public function onScreen(x:Number, y:Number, game:Game, border:Number):Boolean{
		return x + border >= -game.canvas.x && y + border >= -game.canvas.y && x - border < -game.canvas.x + Game.WIDTH && y - border < -game.canvas.y + Game.HEIGHT;
	}

}