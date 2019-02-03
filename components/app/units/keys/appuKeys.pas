{
   appuKeys, keys
   Copyright (C) 2007. Dejan Boras

   Started On:    01.05.2007.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT appuKeys;

INTERFACE

   USES
      sysutils, StringUtils, uStd,
      {app}
      appukcNames, appuRun;

CONST
   {key state and modifier constants}
   kmNONE         = 0;
   kmSHIFT        = $01;
   kmCONTROL      = $02;
   kmALT          = $04;
   kmALTGR        = $08;
   kmCAPS         = $10;
   kmNUM          = $20;
   kmSCROLL       = $40;
   kmDOWN         = $80;
   kmEXTENDED     = $100;

   {key modifiers which are not relevant for comparison}
   kmCOMPARISON_IRRELEVANT = kmCAPS or kmNUM or kmSCROLL or kmDOWN;

   {key history size}
   appkcDEFAULT_LIST_SIZE     = 32;
   {keys pressed}
   appkcKEYS_PRESSED_SIZE     = 256;

   {list of keycodes}
   {$INCLUDE ./KeyCodes.inc}

TYPE
   TKeyCode = longint;
   TKeyState = TBitSet;

   {key}
   appPKey = ^appTKEyEvent;

   { appTKey }

   appTKey = record
      Code: longint;
      State: TBitSet;

      {assign keycode and state}
      procedure Assign(kc: longint; s: TBitSet);
      {set keycode and state from string}
      procedure FromString(const s: string);
      {get string representation of key}
      function ToString(kc: longint; st: TBitSet): string;
      {get string representation of key}
      function ToString(): string;
      {get list of modifiers as string}
      class function GetModifiersString(m: TBitSet): string; static;
      {get list of modifiers as string}
      function GetModifiersString(): string;
      {is the key pressed}
      function IsPressed(): boolean;
      {is the key released}
      function Released(): boolean;
      {does the key have any modifiers}
      function HasModifiers(): boolean;

      {is the key released}
      function IsContext(): boolean;

      {compare two keys for equality}
      function Equal(const otherKey: appTKey): boolean;
      {compare two keys for equality}
      function Equal(kc: LongInt; st: TBitSet = 0): boolean;
   end;

   {event}
   appPKeyEvent = ^appTKeyEvent;

   { appTKeyEvent }

   appTKeyEvent = record
      Key: appTKey;

      PlatformCode,
	   DeviceType,
      DeviceID: longint;
   end;

   {appTKey defined in appTypes.inc}
   appKeyCodes = array[0..255] of byte;

   appPKeyListItem = ^appTKeyListItem;
   appTKeyListItem = record
      Name: string;
      Key: appTKey;
      Next: appPKeyListItem;
   end;

   { appTKeyList }

   appTKeyList = class
      Name: string;
      Start,
      Last: appPKeyListItem;

      constructor Create(const n: string);

      procedure Add(var item: appTKeyListItem);
      function Find(keyCode: longint; state: TBitSet): appPKeyListItem;
      function Find(const k: appTKey): appPKeyListItem;
   end;

   appPKeyGlobal = ^appTKeyGlobal;

   { appTKeyGlobal }

   appTKeyGlobal = record
      {determines which modifiers are currently set}
      Modifiers: TBitSet;
      {determines which keys are pressed and which are not, keycode corresponds to
      a key in the array} {useful for games}
      Pressed: array[0..appkcKEYS_PRESSED_SIZE - 1] of boolean;
      {was the key pressed in the current cycle}
      CurrentCyclePressed: array[0..appkcKEYS_PRESSED_SIZE - 1] of boolean;
      {pressed and released in the same cycle}
      ReleasePressed: array[0..appkcKEYS_PRESSED_SIZE - 1] of boolean;
      {Previous state of Pressed array, for more advanced input handling}
      WasPressed: array[0..appkcKEYS_PRESSED_SIZE - 1] of boolean;

      {initialize a appTKey record}
      class procedure Init(out k: appTKey); static;
      {initialize a appTKey record}
      class procedure Init(out k: appTKeyEvent); static;
      {create a key from the given parameters}
      function Make(kc: longint; state: TBitSet): appTKey;

      { INPUT }
      {translate a key event into a character}
      function Translate(var k: appTKey): char;

      {KEYBOARD ROUTINES}
      {checks whether any of the SHIFT keys is being held or not}
      function Shift(): boolean;
      {checks whether any of the CONTROL keys is being held or not}
      function Control(): boolean;
      {checks whether any of the ALT keys is being held or not}
      function Alt(): boolean;
      {checks whether any of the OS(windows) keys is being held or not}
      function OS(): boolean;
      {checks whether any of the CONTEXT keys is being held or not}
      function Context(): boolean;
      {checks whether a key with the specified keycode is pressed}
      function IsPressed(KeyCode: longint): boolean;

      {get an interpolated value for keypressed}
      function Interpolated(kc: loopint): single;
      function Interpolated(kc, optionalKC: loopint): single;

      {update state of WasPressed array}
      procedure UpdatePressed();
   end;

VAR
   appk: appTKeyGlobal;

   {remap codes}
   {$IFNDEF ANDROID}{$INCLUDE ./kRemapCodes.inc}{$ENDIF}

operator = (const a: appTKey; const b: appTKey): boolean;

IMPLEMENTATION

operator = (const a: appTKey; const b: appTKey): boolean;
begin
   Result := (a.Code = b.Code) and (a.State = b.State);
end;

{ appTKey }

procedure appTKey.Assign(kc: longint; s: TBitSet);
begin
   Code := kc;
   State := s;
end;

procedure appTKey.FromString(const s: string);
var
   ks,
   keyCodeString: string;
   lastPos: longint = 0;

begin
   ks := LowerCase(s);

   Code := 0;
   State := 0;

   if(pos('alt', ks) > 0) then
      State.Prop(kmALT);

   if(pos('control', ks) > 0) then
      State.Prop(kmCONTROL);

   if(pos('shift', ks) > 0) then
      State.Prop(kmSHIFT);

   if(pos('altgr', ks) > 0) then
      State.Prop(kmALTGR);

   if(pos('extended', ks) > 0) then
      State.Prop(kmEXTENDED);

   lastPos := LastDelimiter('+', ks);

   keyCodeString := copy(ks, lastPos + 1, Length(ks));
   StripWhitespace(keyCodeString);

   if(keyCodeString <> '') then
      Code := appkNames.FindCode('kc' + keyCodeString);
end;

function appTKey.ToString(kc: longint; st: TBitSet): string;
var
   s: string = '';

begin
   if(kc <> 0) then begin
      if(st.IsSet(kmALT)) then
         s := s + 'ALT+';

      if(st.IsSet(kmCONTROL)) then
         s := s + 'CTRL+';

      if(st.IsSet(kmSHIFT)) then
         s := s + 'SHIFT+';

      if(st.IsSet(kmEXTENDED)) then
         s := s + 'EXTENDED+';

      s := s + appkNames.Get(kc);
   end;

   Result := s;
end;

function appTKey.ToString(): string;
begin
   Result := ToString(Code, State);
end;

class function appTKey.GetModifiersString(m: TBitSet): string;
var
   s: string = '';

begin
   if(m.IsSet(kmALT)) then
      s := s + 'ALT+';

   if(m.IsSet(kmCONTROL)) then
      s := s + 'CTRL+';

   if(m.IsSet(kmSHIFT)) then
      s := s + 'SHIFT+';

   if(m.IsSet(kmEXTENDED)) then
      s := s + 'EXTENDED+';

   Result := s;
end;

function appTKey.GetModifiersString(): string;
begin
   Result := GetModifiersString(State);
end;

function appTKey.IsPressed(): boolean;
begin
   Result := State.IsSet(kmDOWN);
end;

function appTKey.Released(): boolean;
begin
   Result := not State.IsSet(kmDOWN);
end;

function appTKey.HasModifiers(): boolean;
begin
   Result := State.IsSet(kmALT) or State.IsSet(kmCONTROL) or State.IsSet(kmEXTENDED) or State.IsSet(kmSHIFT);
end;

function appTKey.IsContext(): boolean;
begin
   Result := (Code = kcLCONTEXT) or (Code = kcRCONTEXT);
end;

function appTKey.Equal(const otherKey: appTKey): boolean;
var
   st1, st2: TBitSet;

begin
   st1 := State and (not kmCOMPARISON_IRRELEVANT);
   st2 := otherKey.State and (not kmCOMPARISON_IRRELEVANT);

   Result := (Code = otherKey.Code) and (st1 = st2);
end;

function appTKey.Equal(kc: LongInt; st: TBitSet): boolean;
var
   st1, st2: TBitSet;

begin
   st1 := State and (not kmCOMPARISON_IRRELEVANT);
   st2 := st and (not kmCOMPARISON_IRRELEVANT);

   Result := (Code = kc) and (st1 = st2);
end;

{KEY ROUTINES}

class procedure appTKeyGlobal.Init(out k: appTKey);
begin
   ZeroOut(k, SizeOf(k));
end;

class procedure appTKeyGlobal.Init(out k: appTKeyEvent);
begin
   ZeroOut(k, SizeOf(appTKeyEvent));
end;

function appTKeyGlobal.Make(kc: longint; state: TBitSet): appTKey;
var
   k: appTKey;

begin
   k.Code := kc;
   k.State := state;

   Result := k;
end;

{ INPUT }

function appTKeyGlobal.Translate(var k: appTKey): char;
var
   shiftPressed: boolean = false;
   isCaps: boolean = false;

begin
   Result := #0;

   shiftPressed := k.State.IsSet(kmSHIFT);
   isCaps := shiftPressed;

   if(k.State.IsSet(kmCAPS)) then
      isCaps := shiftPressed xor true;

   if (k.State.IsSet(kmCONTROL) or k.State.IsSet(kmALT)) then
      exit;

   case k.Code of
      kcA..kcZ:
         if(isCaps) then
            Result := char(k.Code)
         else
            Result := char(k.Code + $20);
      kcCOMMA:
         if(shiftPressed) then
            Result := '<'
         else
            Result := ',';
      kcPERIOD:
         if(shiftPressed) then
            Result := '>'
         else
            Result := '.';
      kcDASH:
         if(shiftPressed) then
            Result := '_'
         else
            Result := '-';
      kcNUMSUBTRACT:
         Result := '-';
      kcEQUAL:
         if(shiftPressed) then
            Result := '+'
         else
            Result := '=';
      kcLBRACKET:
         if(shiftPressed) then
            Result := '{'
         else
            Result := '[';
      kcRBRACKET:
         if(shiftPressed) then
            Result := '}'
         else
            Result := ']';
      kcSLASH:
         if(shiftPressed) then
            Result := '?'
         else
            Result := '/';
      kcNUMDIVIDE:
         Result := '/';
      kcBACKSLASH:
         if(shiftPressed) then
            Result := '|'
         else
            Result := '\';
      kcSPACE:
         Result := ' ';
      kcSEMICOLON:
         if(shiftPressed) then
            Result := ':' 
         else 
            Result := ';';
      kcAPOSTROPHE: 
         if(shiftPressed) then
            Result := '"' 
         else 
            Result := '''';
      kcNUMADD: 
         Result := '+';
      kcNUMMUL: 
         Result := '*';
      kc1..kc6:
         if(shiftPressed) then
            Result := char(k.Code - $10)
         else 
            Result := char(k.Code);
      kc7: 
         if(shiftPressed) then
            Result := '/' 
         else 
            Result := '7';
      kc8: 
         if(shiftPressed) then
            Result := '*' 
         else 
            Result := '8';
      kc9: 
         if(shiftPressed) then
            Result := '('
         else 
            Result := '9';
      kc0: 
         if(shiftPressed) then
            Result := ')'
         else 
            Result := '0';
   end;
end;

{ KEYBOARD ROUTINES }

function appTKeyGlobal.Shift(): boolean;
begin
   Result := appk.pressed[kcLSHIFT] or appk.pressed[kcRSHIFT];
end;

function appTKeyGlobal.Control(): boolean;
begin
   Result := appk.pressed[kcLCTRL] or appk.pressed[kcRCTRL];
end;

function appTKeyGlobal.Alt(): boolean;
begin
   Result := appk.pressed[kcLALT] or appk.pressed[kcRALT];
end;

function appTKeyGlobal.OS(): boolean;
begin
   Result := appk.pressed[kcLOS] or appk.pressed[kcROS];
end;

{checks whether any of the CONTEXT keys is being held or not}
function appTKeyGlobal.Context(): boolean;
begin
   Result := appk.pressed[kcLCONTEXT] or appk.pressed[kcRCONTEXT];
end;

{checks whether a key with the specified keycode is pressed}
function appTKeyGlobal.IsPressed(KeyCode: longint): boolean;
begin
   if(KeyCode >= -1) and (KeyCode < appkcKEYS_PRESSED_SIZE) then
      Result := appk.Pressed[KeyCode]
   else
      Result := false;
end;

function appTKeyGlobal.Interpolated(kc: loopint): single;
begin
   if(ReleasePressed[kc]) then
      Result := 0.25
   else if(Pressed[kc] and WasPressed[kc]) then
      Result := 1.0
   else if(WasPressed[kc] or (Pressed[kc])) then
      Result := 0.5
   else
      Result := 0;
end;

function appTKeyGlobal.Interpolated(kc, optionalKC: loopint): single;
begin
   Result := Interpolated(kc);
   if(Result = 0) then
      Result := Interpolated(optionalKC);
end;

procedure appTKeyGlobal.UpdatePressed();
begin
   WasPressed := Pressed;
end;

{ KEY LIST }

constructor appTKeyList.Create(const n: string);
begin
   name := n
end;

procedure appTKeyList.Add(var item: appTKeyListItem);
begin
   item.Next := nil;

   if(Start = nil) then
      Start := @item
   else
      Last^.next := @item;

   Last := @item;
end;

function appTKeyList.Find(keyCode: longint; state: TBitSet): appPKeyListItem;
var
   cur: appPKeyListItem;
   k: appTKey;

begin
   k.Assign(keyCode, state);

   cur := Start;
   if(cur <> nil) then repeat
      if(cur^.Key.Equal(k)) then
         exit(cur);

      cur := cur^.Next;
   until (cur = nil);

   Result := nil;
end;

function appTKeyList.Find(const k: appTKey): appPKeyListItem;
begin
   Result := Find(k.Code, k.State);
end;

procedure run();
begin
   {clear keypressed for current cycle}
   ZeroPtr(@appk.CurrentCyclePressed, SizeOf(appk.CurrentCyclePressed));
   {clear releasepressed for current cycle}
   ZeroPtr(@appk.ReleasePressed, SizeOf(appk.ReleasePressed));
   {move current cycle results to previous cycle results}
   appk.WasPressed := appk.Pressed;
end;

VAR
   runRoutine: appTRunRoutine;

INITIALIZATION
   appRun.AddRoutine(runRoutine, 'appKeys', @run);

END.
