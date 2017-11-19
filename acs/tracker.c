#library "tracker"
#include "zcommon.acs"

int showSecretCount = 1;
int showItemCount = 1;
int showMonsterCount = 1;
int colorCompleteCounts = 1; // Color counts differently when complete

int showTime = 1;
int showParTime = 1;
int colorTimeForPar = 1; // Color the time according to how close it is to par

int showLevel = 1;



function int pad(int time) {
  if(time < 10) {
    return StrParam(s:"0", d:time);
  }
  else {
    return StrParam(d:time);
  }
  return 0;
}

function int timeColor(int time, int par) {
  int diff = par - time;
  int percent = (diff*100) / par;
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
  return 1;
}

function int timeToStr(int time) {
  int secs = time % 60;
  int mins = (time / 60) % 60;
  int hours = mins / 60;
  if (hours > 0) {
    return StrParam(s:pad(hours), s:":", s:pad(mins), s:":", s:pad(secs));
  }
  else {
    return StrParam(s:pad(mins), s:":", s:pad(secs));
  }
  return 0;
  
}

script 400 ENTER clientside
{
  int tagColor = "g";
  int dataColor = "d";
  int completeColor = "n";
  while(true) {
    int countColor = 0;
    int fullMessage = "";
    if(showSecretCount) {
      int ts = GetLevelInfo(LEVELINFO_TOTAL_SECRETS);
      int fs = GetLevelInfo(LEVELINFO_FOUND_SECRETS);
      countColor = dataColor;
      if(colorCompleteCounts && fs >= ts) {
        countColor = completeColor;
      }
      int secretMsg = StrParam(s:"\c", s:tagColor, s:"s: \t\t", s:"\c", s:countColor, d:fs, s:"/", d:ts);
      fullMessage = StrParam(s:fullMessage, s:secretMsg, s:"\n");
    }
    if(showItemCount) {
      int ti = GetLevelInfo(LEVELINFO_TOTAL_ITEMS);
      int fi = GetLevelInfo(LEVELINFO_FOUND_ITEMS);
      countColor = dataColor;
      if(colorCompleteCounts && fi >= ti) {
        countColor = completeColor;
      }
      fullMessage = StrParam(s:fullMessage, s:"\c", s:tagColor, s:"i: \t\t\t", s:"\c", s:countColor, d:fi, s:"/", d:ti, s:"\n");
    }
    if(showMonsterCount) {
      int tm = GetLevelInfo(LEVELINFO_TOTAL_MONSTERS);
      int km = GetLevelInfo(LEVELINFO_KILLED_MONSTERS);
      countColor = dataColor;
      if(colorCompleteCounts && km >= tm) {
        countColor = completeColor;
      }
      fullMessage = StrParam(s:fullMessage, s:"\c", s:tagColor, s:"k: \t\t", s:"\c", s:countColor, d:km, s:"/", d:tm, s:"\n");
    }
    if(showTime) {
      int time = Timer()/35;
      int par = GetLevelInfo(LEVELINFO_PAR_TIME);
      int timeTag = "t: ";
      int timeStr = StrParam(s:timeToStr(time));
      int parStr = StrParam(s:timeToStr(par));
      int col = dataColor;
      if(colorTimeForPar) {
        col = timeColor(time, par);  
      }

      fullMessage = StrParam(s:fullMessage, s:"\c", s:tagColor, s:"t: \t\t", s:"\c", s:col, s:timeStr, s:"\n");

      if(showParTime) {
        fullMessage = StrParam(s:fullMessage, s:"\t\t\t\t\t\t", s:"\cj", s:parStr, s:"\n");
      }
    }
    if(showLevel) {

      fullMessage = StrParam(s:fullMessage, s:"\cu", n:PRINTNAME_LEVEL, s:"\n");
      fullMessage = StrParam(s:fullMessage, s:"\cc", n:PRINTNAME_LEVELNAME, s:"\n");
    }
    HudMessage(l:fullMessage; HUDMSG_PLAIN | HUDMSG_NOTWITHFULLMAP, 400, CR_WHITE, 1.0, 0.0, 1873);
    Delay(1);
  }
}