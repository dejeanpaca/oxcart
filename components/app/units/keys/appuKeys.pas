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

   {list of modifiers}
   kmMODIFIERS_MASK = kmSHIFT or kmCONTROL or kmALT or kmALTGR or kmCAPS or kmNUM or kmSCROLL;

   {key modifiers which are not relevant for comparison}
   kmCOMPARISON_IRRELEVANT = kmCAPS or kmNUM or kmSCROLL or kmDOWN;

   {key history size}
   appkcDEFAULT_LIST_SIZE     = 32;
   {keys pressed}
   appkcKEYS_PRESSED_SIZE     = 256;

   { key properties }
   {key is pressed}
   kpPRESSED                  = $01;
   {key was pressed previous cycle}
   kpWAS_PRESSED              = $02;
   {key was just pressed in current cycle}
   kpCYCLE_PRESSED            = $04;
   {key was pressed and released in the same cycle}
   kpPRESSED_RELEASED         = $08;


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
      function ToString(kc: longint; st: TBitSet; extended: boolean = false): string;
      {get string representation of key}
      function ToString(extended: boolean = false): string;
      {get list of modifiers as string}
      class function GetModifiersString(m: TBitSet; extended: boolean = false): string; static;
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
      Properties: array[0..appkcKEYS_PRESSED_SIZE - 1] of TBitSet;

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
      {checks whether a key with the specified keycode was pressed}
      function WasPressed(KeyCode: longint): boolean;
      {checks whether a key with the specified keycode was pressed in this cycle}
      function CyclePressed(KeyCode: longint): boolean;
      {checks whether a key with the specified keycode was pressed/released in same cycle}
      function PressedReleases(KeyCode: longint): boolean;

      {get an interpolated value for keypressed}
      function Interpolated(kc: loopint): single;
      function Interpolated(kc, optionalKC: loopint): single;

      {update state per cycle}
      procedure UpdateCycle();
      {update state per cycle}
      procedure LogState();
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

function appTKey.ToString(kc: longint; st: TBitSet; extended: boolean): string;
var
   s: string = '';

begin
   if(kc <> 0) then begin
      s := GetModifiersString(st, extended);

      s := s + appkNames.Get(kc);
   end;

   Result := s;
end;

function appTKey.ToString(extended: boolean): string;
begin
   Result := ToString(Code, State, extended);
end;

class function appTKey.GetModifiersString(m: TBitSet; extended: boolean): string;
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

   if(extended) then begin
      if(m.IsSet(kmNUM)) then
         s := s + 'NUM+';

      if(m.IsSet(kmSCROLL)) then
         s := s + 'SCROLL+';

      if(m.IsSet(kmDOWN)) then
         s := s + 'DOWN+';
   end;

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
   Result := appk.IsPressed(kcLSHIFT) or appk.IsPressed(kcRSHIFT);
end;

function appTKeyGlobal.Control(): boolean;
begin
   Result := appk.IsPressed(kcLCTRL) or appk.IsPressed(kcRCTRL);
end;

function appTKeyGlobal.Alt(): boolean;
begin
   Result := appk.IsPressed(kcLALT) or appk.IsPressed(kcRALT);
end;

function appTKeyGlobal.OS(): boolean;
begin
   Result := appk.IsPressed(kcLOS) or appk.IsPressed(kcROS);
end;

{checks whether any of the CONTEXT keys is being held or not}
function appTKeyGlobal.Context(): boolean;
begin
   Result := appk.IsPressed(kcLCONTEXT) or appk.IsPressed(kcRCONTEXT);
end;

{checks whether a key with the specified keycode is pressed}
function appTKeyGlobal.IsPressed(KeyCode: longint): boolean;
begin
   if(KeyCode >= -1) and (KeyCode < appkcKEYS_PRESSED_SIZE) then
      Result := appk.Properties[KeyCode].IsSet(kpPRESSED)
   else
      Result := false;
end;

function appTKeyGlobal.WasPressed(KeyCode: longint): boolean;
begin
   if(KeyCode >= -1) and (KeyCode < appkcKEYS_PRESSED_SIZE) then
      Result := appk.Properties[KeyCode].IsSet(kpWAS_PRESSED)
   else
      Result := false;
end;

function appTKeyGlobal.CyclePressed(KeyCode: longint): boolean;
begin
   if(KeyCode >= -1) and (KeyCode < appkcKEYS_PRESSED_SIZE) then
      Result := appk.Properties[KeyCode].IsSet(kpCYCLE_PRESSED)
   else
      Result := false;
end;

function appTKeyGlobal.PressedReleases(KeyCode: longint): boolean;
begin
   if(KeyCode >= -1) and (KeyCode < appkcKEYS_PRESSED_SIZE) then
      Result := appk.Properties[KeyCode].IsSet(kpPRESSED_RELEASED)
   else
      Result := false;
end;

function appTKeyGlobal.Interpolated(kc: loopint): single;
begin
   if(Properties[kc].IsSet(kpPRESSED_RELEASED)) then
      Result := 0.25
   else if(Properties[kc].IsSet(kpPRESSED) and Properties[kc].IsSet(kpWAS_PRESSED)) then
      Result := 1.0
   else if(Properties[kc].IsSet(kpWAS_PRESSED) or Properties[kc].IsSet(kpPRESSED)) then
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

procedure appTKeyGlobal.UpdateCycle();
var
   i: loopint;

begin
   for i := Low(Properties) to High(Properties) do begin
      Properties[i].Clear(kpCYCLE_PRESSED or kpPRESSED_RELEASED);
      Properties[i].Prop(kpWAS_PRESSED, Properties[i].IsSet(kpPRESSED));
   end;
end;

procedure appTKeyGlobal.LogState();
var
   i: loopint;

begin
   for i := Low(appk.Properties) to High(appk.Properties) do begin
      if(appk.Properties[i].IsSet(kpPRESSED)) then
         writeln('Pressed: ', appkNames.Get(i));

      if(appk.Properties[i].IsSet(kpWAS_PRESSED)) then
         writeln('WasPressed: ', appkNames.Get(i));

      if(appk.Properties[i].IsSet(kpCYCLE_PRESSED)) then
         writeln('CyclePressed: ', appkNames.Get(i));

      if(appk.Properties[i].IsSet(kpPRESSED_RELEASED)) then
         writeln('PressedReleased: ', appkNames.Get(i));
   end;
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
   appk.UpdateCycle();
end;

VAR
   runRoutine: appTRunRoutine;

INITIALIZATION
   appRun.AddPreRoutine(runRoutine, 'appKeys', @run);

END.
