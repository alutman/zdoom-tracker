class ZTracker : StaticEventHandler {
	ui HUDFont s_font;
	ui int s_lineHeight;

	ui HUDFont b_font;
	ui int b_lineHeight;

	Array<string> title;

	// wrap titles when too long
	const titleCharsPerLine = 14;
	const padding = 2;

	// TODO find a gzdoom const for this
	const ticRate = 35;

	ui PlayerInfo player;

	const TRACKER_ENABLED_CVAR = "tr_li_enabled";
	const TRACKER_AUTOMAP_CVAR = "tr_li_automap";
	const SHOW_SECRET_CVAR = "tr_li_show_secret";
	const SHOW_ITEM_CVAR = "tr_li_show_item";
	const SHOW_MONSTER_CVAR = "tr_li_show_monster";
	const COLOR_COUNTS_CVAR = "tr_li_color_counts"; // Color counts differently when complete
	const SHOW_TIME_CVAR = "tr_li_show_time";
	const SHOW_PAR_TIME_CVAR = "tr_li_show_par_time";
	const COLOR_TIME_CVAR = "tr_li_color_time"; // Color the time according to how close it is to par
	const SHOW_LEVEL_CVAR = "tr_li_show_level";
	const X_POS_CVAR = "tr_li_x_pos";
	const Y_POS_CVAR = "tr_li_y_pos";

	const POWERUP_TIMER_CVAR = "tr_pt_enabled";
	const POWERUP_X_POS_CVAR = "tr_pt_x_pos";
	const POWERUP_Y_POS_CVAR = "tr_pt_y_pos";


	ui string getCounterString(string name, int count, int total) {
		name fColor = "d"; //green
		if (cvarEnabled(COLOR_COUNTS_CVAR) && count >= total) {
			fColor = "n"; //cyan
		}

		return String.format("\cg%s: \c%s%d/%d", name, fColor, count, total);
	}

	ui string formatSeconds(int seconds) {
		int s = seconds % 60;
		int m = seconds / 60;
		int h = seconds / 3600;

		if (h > 0) {
			return String.format("%.2d:%.2d:%.2d", h, m ,s);
		}
		return String.format("%.2d:%.2d", m ,s);
	}

	ui name timeColor(int time, int par) {
	  if(par <= 0) {
	    return "d"; // Impossible par, just leave green
	  }
	  int diff = par - time;
	  int percent = (diff * 100) / par;
	  if(diff < 0) {
	    return "j";
	    // return CR_WHITE;
	  }
	  else if(percent < 15) {
	    return "g";
	    // return CR_RED;
	  }
	  else if(percent < 30) {
	    return "f";
	    // return CR_GOLD;
	  }
	  else {
	    return "d"; //green
	  }
	  return "d";
	}

	ui string getMapTimeString() {
		name fColor = "d";
		if (cvarEnabled(COLOR_TIME_CVAR)) {
			fColor = timeColor(level.MapTime/ticRate, level.ParTime);
		}

		return String.format("\cgt: \c%s%s", fColor, formatSeconds(level.MapTime/ticRate));
	}

	ui string getParTimeString() {
		return String.format("\cgp: \cd%s", formatSeconds(level.ParTime));
	}

	// translate (0.0, 1.0) floats to x and y screen coords
	// padding stops the coord going out of the padding bounds
	ui Vector2 scale(float xPosAdjust, float yPosAdjust, int xPadding, int yPadding, int xNegPadding, int yNegPadding) {
		Vector2 hudScale = statusbar.GetHUDScale();
		int screenWidth = screen.GetWidth() / hudScale.x;
		int screenHeight = screen.GetHeight() / hudScale.y;
		
		int xPos = screenWidth * xPosAdjust;
		if (xPos > screenWidth -padding + -xPadding) {
			xPos = screenWidth -padding + -xPadding;
		}
		if (xPos < padding + xNegPadding) {
			xPos = padding + xNegPadding;
		}

		int yPos = screenHeight * yPosAdjust;
		if (yPos > screenHeight -padding + -yPadding) {
			yPos = screenHeight -padding + -yPadding;
		}
		if (yPos < padding + yNegPadding) {
			yPos = padding + yNegPadding;
		}

		return (xPos, yPos);
	}

	// todo clean, there's probably a standard way to word split
	void wrapWord(out Array<string> lines, string word, int lengthLimit) {
		if (word.Length() <= lengthLimit) {
			lines.Push(word);
			return;
		}

		Array<string> words;
		word.Split(words, " ");

		string curWord = "";
		string nextWord = "";
		int count = 0;

		for(int i = 0; i < words.Size(); i++) {
			if (++count == 1) {
				nextWord = words[i];
			} else {
				nextWord = String.format("%s %s", curWord, words[i]);
			}
			
			if (nextWord.Length() > lengthLimit) {
				count = 0;
				if(count == 1) {
					lines.Push(nextWord);	
					continue;
				}
				i--;
				lines.Push(curWord);
				curWord = "";
			} else {
				curWord = nextWord;
			}
		}
		lines.Push(curWord);
	}

	override void WorldLoaded (WorldEvent e) {
		// only calculate this on world load, it doesn't change
		title.clear();
		wrapWord(title, level.Levelname, titleCharsPerLine);
	}


	ui void renderTracker () {
		Array<string> lines;
		if (cvarEnabled(SHOW_MONSTER_CVAR)) {
			lines.Push(getCounterString("k", level.Killed_Monsters, level.Total_Monsters));
		}
		
		if (cvarEnabled(SHOW_ITEM_CVAR)) {
			lines.Push(getCounterString("i", level.Found_Items, level.Total_Items));
		}

		if (cvarEnabled(SHOW_SECRET_CVAR)) {
			lines.Push(getCounterString("s", level.Found_Secrets, level.Total_Secrets));
		}

		if (cvarEnabled(SHOW_TIME_CVAR)) {
			lines.Push(getMapTimeString());
		}

		if (cvarEnabled(SHOW_PAR_TIME_CVAR)) {
			lines.Push(getParTimeString());
		}

		if (cvarEnabled(SHOW_LEVEL_CVAR)) {
			// lazy: extra colors just so all text has exactly 4 color characters
			lines.Push(String.format("\cu\cu%s", level.Mapname));


			for(int i = 0; i < title.size(); i++) {
				lines.push(String.format("\cc\cc%s", title[i]));
			}
		}


		// lazy: 2nd loop is easier
		int maxChars = 0;
		// lazy: all text has 4 chars dedicated to color
		int numColorCode = 4;
		for(int i = 0; i < lines.Size(); i++) {
			if(lines[i].Length() - numColorCode > maxChars) {
				maxChars = lines[i].Length() - numColorCode ;
			}
		}

		int characterPadding = maxChars * smallfont.GetCharWidth("0");
		Vector2 pos = scale(cvarFloat(X_POS_CVAR), cvarFloat(Y_POS_CVAR), characterPadding, lines.Size() * s_lineHeight, 0, 0);


		int yPos = pos.y;
		for(int i = 0; i < lines.Size(); i++) {
			statusbar.DrawString(s_font, lines[i], 
				(pos.x, yPos), statusbar.DI_TEXT_ALIGN_LEFT);
			yPos += s_lineHeight;
		}
	}


	ui int getPowerupSecond(string name) {
		Inventory i = player.mo.FindInventory(name);
		if (i != null) {
			Powerup p = Powerup(i);	
			if (p != null) {
				return p.EffectTics / ticRate;
			}
		}
		return 0;
	}

	ui void renderPowerupTimer() {
		int maxPowerups = 4;
		int activePowerups = 0;

		Vector2 pos = scale(cvarFloat(POWERUP_X_POS_CVAR), cvarFloat(POWERUP_Y_POS_CVAR), 
			// - to account for line gap at bottom, matters for large text
			bigfont.GetCharWidth("0"), b_lineHeight - padding, 
			// char 0,0 is top left
			bigfont.GetCharWidth("0"), (maxPowerups-1) * b_lineHeight);

		int yPos = pos.y;

		int ghostTicks = getPowerupSecond("PowerInvisibility");
		if(ghostTicks > 0) {
			statusbar.DrawString(b_font, String.format("\cu%d", ghostTicks), 
				(pos.x, yPos + activePowerups * -b_lineHeight), 
				statusbar.DI_TEXT_ALIGN_CENTER);	
			activePowerups += 1;
		}

		int godTicks = getPowerupSecond("PowerInvulnerable");
		if(godTicks > 0) {
			statusbar.DrawString(b_font, String.format("\cq%d", godTicks),
				(pos.x, yPos + activePowerups * -b_lineHeight), 
				statusbar.DI_TEXT_ALIGN_CENTER);	
			activePowerups += 1;
		}

		int nvTicks = getPowerupSecond("PowerLightAmp");
		if(nvTicks > 0) {
			statusbar.DrawString(b_font, String.format("\cj%d", nvTicks),
				(pos.x, yPos + activePowerups * -b_lineHeight), 
				statusbar.DI_TEXT_ALIGN_CENTER);	
			activePowerups += 1;
		}

		int radSuitTicks = getPowerupSecond("PowerIronFeet");
		if(radSuitTicks > 0) {
			statusbar.DrawString(b_font, String.format("\cd%d", radSuitTicks),
				(pos.x, yPos+ activePowerups * -b_lineHeight), 
				statusbar.DI_TEXT_ALIGN_CENTER);	
			activePowerups += 1;
		}
		
	}

	ui bool cvarEnabled(string cvarName) {
		CVar cvarVal = CVar.GetCVar(cvarName, player);
		return cvarVal != null && cvarVal.GetBool();
	}

	ui float cvarFloat(string cvarName) {
		CVar cvarVal = CVar.GetCVar(cvarName, player);
		if (cvarVal != null) {
			return cvarVal.GetFloat();
		}
		return 0.0f;
	}


	override void RenderOverlay(RenderEvent e) {
		// some mods use "levels" for the main screen at num 0, assume this isn't a real level
		if(level.LevelNum == 0) {
			return;
		}

		player = players[consoleplayer];
		// hudfont create is ui scope only, can't put this in register
		if (s_font == null) {
			// -1 to compact the text a little
			s_lineHeight = smallfont.GetHeight() - 1;
			s_font = HUDFont.Create(smallfont, smallfont.GetCharWidth("0"), Mono_CellCenter);
		}
		if (b_font == null) {
			b_lineHeight = bigfont.GetHeight() - 1;
			b_font = HUDFont.Create(bigfont, bigfont.GetCharWidth("0"), Mono_CellCenter);
		}

		// be nice and set this back to whatever it was
		bool initialVal = statusbar.fullscreenOffsets;
		// todo why isn't this set properly? it's needed for the DI_ vars to work
		statusbar.fullscreenOffsets = true;

		if (cvarEnabled(TRACKER_ENABLED_CVAR)) {
			if (cvarEnabled(TRACKER_AUTOMAP_CVAR)) {
				if (automapactive) {
					renderTracker();					
				}
			}
			else {
				renderTracker();
			}
		}

		if(cvarEnabled(POWERUP_TIMER_CVAR)) {
			renderPowerupTimer();			
		}

		statusbar.fullscreenOffsets = initialVal;
	}
}
