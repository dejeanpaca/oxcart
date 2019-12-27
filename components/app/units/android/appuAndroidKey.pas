{
   appuAndroidKey.pas, android key event handling and key remaps
   Copyright (C) 2009. Dejan Boras

   Started On:    31.12.2011.

   TODO: Remap the rest of the keycodes.
}

{$INCLUDE oxdefines.inc}
UNIT appuAndroidKey;

INTERFACE

   USES appuEvents, appuKeys, appuKeyEvents;

CONST
   ANDROID_KEY_ACTION_DOWN    = 0000;
   ANDROID_KEY_ACTION_UP      = 0001;

   androidKeyRemaps: array[0..255] of longint = (
{000} 0,
{001} 0,
{002} 0,
{003} kcSYSHOME, {AKEYCODE_HOME}
{004} kcSYSBACK, {AKEYCODE_BACK}
{005} 0,
{006} 0,
{007} 0,
{008} 0,
{009} 0,

{010} 0,
{011} 0,
{012} 0,
{013} 0,
{014} 0,
{015} 0,
{016} 0,
{017} 0,
{018} 0,
{019} kcUP, {AKEYCODE_DPAD_UP}

{020} kcDOWN, {AKEYCODE_DPAD_DOWN}
{021} kcLEFT, {AKEYCODE_DPAD_LEFT}
{022} kcRIGHT, {AKEYCODE_DPAD_RIGHT}
{023} 0,
{024} 0,
{025} 0,
{026} 0,
{027} 0,
{028} 0,
{029} kcA, {AKEYCODE_A}

{030} kcB, {AKEYCODE_B}
{031} kcC, {AKEYCODE_C}
{032} kcD, {AKEYCODE_D}
{033} kcE, {AKEYCODE_E}
{034} kcF, {AKEYCODE_F}
{035} kcG, {AKEYCODE_G}
{036} kcH, {AKEYCODE_H}
{037} kcI, {AKEYCODE_I}
{038} kcJ, {AKEYCODE_J}
{039} kcK, {AKEYCODE_K}

{040} kcL, {AKEYCODE_L}
{041} kcM, {AKEYCODE_M}
{042} kcN, {AKEYCODE_N}
{043} kcO, {AKEYCODE_O}
{044} kcP, {AKEYCODE_P}
{045} kcQ, {AKEYCODE_Q}
{046} kcR, {AKEYCODE_R}
{047} kcS, {AKEYCODE_S}
{048} kcT, {AKEYCODE_T}
{049} kcU, {AKEYCODE_U}

{050} kcV, {AKEYCODE_V}
{051} kcW, {AKEYCODE_W}
{052} kcX, {AKEYCODE_X}
{053} kcY, {AKEYCODE_Y}
{054} kcZ, {AKEYCODE_Z}
{055} 0,
{056} 0,
{057} 0,
{058} 0,
{059} 0,

{060} 0,
{061} 0,
{062} 0,
{063} 0,
{064} 0,
{065} 0,
{066} 0,
{067} 0,
{068} 0,
{069} 0,

{070} 0,
{071} 0,
{072} 0,
{073} 0,
{074} 0,
{075} 0,
{076} 0,
{077} 0,
{078} 0,
{079} 0,

{080} 0,
{081} 0,
{082} kcSYSMENU, {AKEYCODE_MENU}
{083} 0,
{084} kcSYSSEARCH, {AKEYCODE_SEARCH}
{085} 0,
{086} 0,
{087} 0,
{088} 0,
{089} 0,

{090} 0,
{091} 0,
{092} 0,
{093} 0,
{094} 0,
{095} 0,
{096} 0,
{097} 0,
{098} 0,
{099} 0,

{100} 0,
{101} 0,
{102} 0,
{103} 0,
{104} 0,
{105} 0,
{106} 0,
{107} 0,
{108} 0,
{109} 0,

{110} 0,
{111} 0,
{112} 0,
{113} 0,
{114} 0,
{115} 0,
{116} 0,
{117} 0,
{118} 0,
{119} 0,

{120} 0,
{121} 0,
{122} 0,
{123} 0,
{124} 0,
{125} 0,
{126} 0,
{127} 0,
{128} 0,
{129} 0,

{130} 0,
{131} 0,
{132} 0,
{133} 0,
{134} 0,
{135} 0,
{136} 0,
{137} 0,
{138} 0,
{139} 0,

{140} 0,
{141} 0,
{142} 0,
{143} 0,
{144} 0,
{145} 0,
{146} 0,
{147} 0,
{148} 0,
{149} 0,

{150} 0,
{151} 0,
{152} 0,
{153} 0,
{154} 0,
{155} 0,
{156} 0,
{157} 0,
{158} 0,
{159} 0,

{160} 0,
{161} 0,
{162} 0,
{163} 0,
{164} 0,
{165} 0,
{166} 0,
{167} 0,
{168} 0,
{169} 0,

{170} 0,
{171} 0,
{172} 0,
{173} 0,
{174} 0,
{175} 0,
{176} 0,
{177} 0,
{178} 0,
{179} 0,

{180} 0,
{181} 0,
{182} 0,
{183} 0,
{184} 0,
{185} 0,
{186} 0,
{187} 0,
{188} 0,
{189} 0,

{190} 0,
{191} 0,
{192} 0,
{193} 0,
{194} 0,
{195} 0,
{196} 0,
{197} 0,
{198} 0,
{199} 0,

{200} 0,
{201} 0,
{202} 0,
{203} 0,
{204} 0,
{205} 0,
{206} 0,
{207} 0,
{208} 0,
{209} 0,

{210} 0,
{211} 0,
{212} 0,
{213} 0,
{214} 0,
{215} 0,
{216} 0,
{217} 0,
{218} 0,
{219} 0,

{220} 0,
{221} 0,
{222} 0,
{223} 0,
{224} 0,
{225} 0,
{226} 0,
{227} 0,
{228} 0,
{229} 0,

{230} 0,
{231} 0,
{232} 0,
{233} 0,
{234} 0,
{235} 0,
{236} 0,
{237} 0,
{238} 0,
{239} 0,

{240} 0,
{241} 0,
{242} 0,
{243} 0,
{244} 0,
{245} 0,
{246} 0,
{247} 0,
{248} 0,
{249} 0,

{250} 0,
{251} 0,
{252} 0,
{253} 0,
{254} 0,
{255} 0
);

(*

  AKEYCODE_SOFT_LEFT = 1;
  AKEYCODE_SOFT_RIGHT = 2;
  AKEYCODE_HOME = 3;
  AKEYCODE_BACK = 4;
  AKEYCODE_CALL = 5;
  AKEYCODE_ENDCALL = 6;
  AKEYCODE_0 = 7;
  AKEYCODE_1 = 8;
  AKEYCODE_2 = 9;
  AKEYCODE_3 = 10;
  AKEYCODE_4 = 11;
  AKEYCODE_5 = 12;
  AKEYCODE_6 = 13;
  AKEYCODE_7 = 14;
  AKEYCODE_8 = 15;
  AKEYCODE_9 = 16;
  AKEYCODE_STAR = 17;
  AKEYCODE_POUND = 18;
  AKEYCODE_DPAD_UP = 19;
  AKEYCODE_DPAD_DOWN = 20;
  AKEYCODE_DPAD_LEFT = 21;
  AKEYCODE_DPAD_RIGHT = 22;
  AKEYCODE_DPAD_CENTER = 23;
  AKEYCODE_VOLUME_UP = 24;
  AKEYCODE_VOLUME_DOWN = 25;
  AKEYCODE_POWER = 26;
  AKEYCODE_CAMERA = 27;
  AKEYCODE_CLEAR = 28;
  AKEYCODE_A = 29;
  AKEYCODE_B = 30;
  AKEYCODE_C = 31;
  AKEYCODE_D = 32;
  AKEYCODE_E = 33;
  AKEYCODE_F = 34;
  AKEYCODE_G = 35;
  AKEYCODE_H = 36;
  AKEYCODE_I = 37;
  AKEYCODE_J = 38;
  AKEYCODE_K = 39;
  AKEYCODE_L = 40;
  AKEYCODE_M = 41;
  AKEYCODE_N = 42;
  AKEYCODE_O = 43;
  AKEYCODE_P = 44;
  AKEYCODE_Q = 45;
  AKEYCODE_R = 46;
  AKEYCODE_S = 47;
  AKEYCODE_T = 48;
  AKEYCODE_U = 49;
  AKEYCODE_V = 50;
  AKEYCODE_W = 51;
  AKEYCODE_X = 52;
  AKEYCODE_Y = 53;
  AKEYCODE_Z = 54;
  AKEYCODE_COMMA = 55;
  AKEYCODE_PERIOD = 56;
  AKEYCODE_ALT_LEFT = 57;
  AKEYCODE_ALT_RIGHT = 58;
  AKEYCODE_SHIFT_LEFT = 59;
  AKEYCODE_SHIFT_RIGHT = 60;
  AKEYCODE_TAB = 61;
  AKEYCODE_SPACE = 62;
  AKEYCODE_SYM = 63;
  AKEYCODE_EXPLORER = 64;
  AKEYCODE_ENVELOPE = 65;
  AKEYCODE_ENTER = 66;
  AKEYCODE_DEL = 67;
  AKEYCODE_GRAVE = 68;
  AKEYCODE_MINUS = 69;
  AKEYCODE_EQUALS = 70;
  AKEYCODE_LEFT_BRACKET = 71;
  AKEYCODE_RIGHT_BRACKET = 72;
  AKEYCODE_BACKSLASH = 73;
  AKEYCODE_SEMICOLON = 74;
  AKEYCODE_APOSTROPHE = 75;
  AKEYCODE_SLASH = 76;
  AKEYCODE_AT = 77;
  AKEYCODE_NUM = 78;
  AKEYCODE_HEADSETHOOK = 79;
  AKEYCODE_FOCUS = 80;  // *Camera* focus
  AKEYCODE_PLUS = 81;
  AKEYCODE_MENU = 82;
  AKEYCODE_NOTIFICATION = 83;
  AKEYCODE_SEARCH = 84;
  AKEYCODE_MEDIA_PLAY_PAUSE = 85;
  AKEYCODE_MEDIA_STOP = 86;
  AKEYCODE_MEDIA_NEXT = 87;
  AKEYCODE_MEDIA_PREVIOUS = 88;
  AKEYCODE_MEDIA_REWIND = 89;
  AKEYCODE_MEDIA_FAST_FORWARD = 90;
  AKEYCODE_MUTE = 91;
  AKEYCODE_PAGE_UP = 92;
  AKEYCODE_PAGE_DOWN = 93;
  AKEYCODE_PICTSYMBOLS = 94;
  AKEYCODE_SWITCH_CHARSET = 95;
  AKEYCODE_BUTTON_A = 96;
  AKEYCODE_BUTTON_B = 97;
  AKEYCODE_BUTTON_C = 98;
  AKEYCODE_BUTTON_X = 99;
  AKEYCODE_BUTTON_Y = 100;
  AKEYCODE_BUTTON_Z = 101;
  AKEYCODE_BUTTON_L1 = 102;
  AKEYCODE_BUTTON_R1 = 103;
  AKEYCODE_BUTTON_L2 = 104;
  AKEYCODE_BUTTON_R2 = 105;
  AKEYCODE_BUTTON_THUMBL = 106;
  AKEYCODE_BUTTON_THUMBR = 107;
  AKEYCODE_BUTTON_START = 108;
  AKEYCODE_BUTTON_SELECT = 109;
  AKEYCODE_BUTTON_MODE = 110;
*)

{creates a key record using android keycode and action}
procedure androidGetKey(keyCode, action: longint; var event: appTKey);
{queues a key event constructed from android keycode and action}
function androidQueueKeyEvent(keyCode, action: longint): appPEvent;

IMPLEMENTATION

{creates a key record using android keycode and action}
procedure androidGetKey(keyCode, action: longint; var event: appTKey);
begin
   if(keyCode > 0) and (keyCode < 256) then
      event.keyCode := androidKeyRemaps[keyCode]
   else
      event.keyCode := 0;

   if(action = ANDROID_KEY_ACTION_DOWN) then
      event.State := event.state or appkcDOWN;

   event.platformCode := keyCode;
end;

{queues a key event constructed from android keycode and action}
function androidQueueKeyEvent(keyCode, action: longint): appPEvent;
var
   k: appTKey;

begin
   appk.Init(k);

   androidGetKey(keyCode, action, k);
   result := appQueueKeyEvent(appKEY_EVENT, k);
end;

END.
