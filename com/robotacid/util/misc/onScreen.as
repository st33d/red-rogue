package com.robotacid.util.misc {
	
	/* A check to see if (x,y) is on screen plus a border */
	public function onScreen(x:Number, y:Number, g:Game, border:Number):Boolean{
		return x + border >= -g.canvas.x && y + border >= -g.canvas.y && x - border < -g.canvas.x + Game.WIDTH && y - border < -g.canvas.y + Game.HEIGHT;
	}

}