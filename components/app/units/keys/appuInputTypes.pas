{
   appuInputTypes, input types
   Copyright (C) 2019. Dejan Boras

   Started On:    23.09.2019.
}

{$INCLUDE oxdefines.inc}
UNIT appuInputTypes;

INTERFACE

   USES uStd;

CONST
   { key properties }
   {key is pressed}
   kpPRESSED                  = $01;
   {key was pressed previous cycle}
   kpWAS_PRESSED              = $02;
   {key was just pressed in current cycle}
   kpCYCLE_PRESSED            = $04;
   {key was pressed and released in the same cycle}
   kpPRESSED_RELEASED         = $08;

TYPE
   appiTAxis = word;
   appiTTrigger = word;

   appiPKeyState = ^appiTKeyState;
   appiTKeyState = TBitSet;

   { appiTKeyStates }

   appiTKeyStates = record
      nKeys: loopint;
      pKeys: appiPKeyState;

      procedure SetupKeys(count: loopint; where: appiPKeyState);

      {checks whether a key with the specified keycode is pressed}
      function IsPressed(KeyCode: longint): boolean;
      {checks whether a key with the specified keycode was just released}
      function Released(KeyCode: longint): boolean;
      {checks whether a key with the specified keycode was just pressed}
      function JustPressed(KeyCode: longint): boolean;
      {checks whether a key with the specified keycode was pressed}
      function WasPressed(KeyCode: longint): boolean;
      {checks whether a key with the specified keycode was pressed in this cycle}
      function CyclePressed(KeyCode: longint): boolean;
      {checks whether a key with the specified keycode was pressed/released in same cycle}
      function PressedReleased(KeyCode: longint): boolean;

      {get an interpolated value for keypressed}
      function Interpolated(kc: loopint): single;
      function Interpolated(kc, optionalKC: loopint): single;

      procedure UpdateCycle();

      procedure Process(keyCode: loopint; pressed: boolean);
   end;

IMPLEMENTATION

{ appiTKeyStates }

procedure appiTKeyStates.SetupKeys(count: loopint; where: appiPKeyState);
begin
   nKeys := count;
   pKeys := where;
end;

function appiTKeyStates.IsPressed(KeyCode: longint): boolean;
begin
   if(KeyCode >= -1) and (KeyCode < nKeys) then
      Result := pKeys[KeyCode].IsSet(kpPRESSED)
   else
      Result := false;
end;

function appiTKeyStates.Released(KeyCode: longint): boolean;
begin
   if(KeyCode >= -1) and (KeyCode < nKeys) then
      Result := pKeys[KeyCode].IsSet(kpWAS_PRESSED) and (not pKeys[KeyCode].IsSet(kpPRESSED))
   else
      Result := false;
end;

function appiTKeyStates.JustPressed(KeyCode: longint): boolean;
begin
   if(KeyCode >= -1) and (KeyCode < nKeys) then
      Result := (not pKeys[KeyCode].IsSet(kpWAS_PRESSED)) and pKeys[KeyCode].IsSet(kpPRESSED)
   else
      Result := false;
end;

function appiTKeyStates.WasPressed(KeyCode: longint): boolean;
begin
   if(KeyCode >= -1) and (KeyCode < nKeys) then
      Result := pKeys[KeyCode].IsSet(kpWAS_PRESSED)
   else
      Result := false;
end;

function appiTKeyStates.CyclePressed(KeyCode: longint): boolean;
begin
   if(KeyCode >= -1) and (KeyCode < nKeys) then
      Result := pKeys[KeyCode].IsSet(kpCYCLE_PRESSED)
   else
      Result := false;
end;

function appiTKeyStates.PressedReleased(KeyCode: longint): boolean;
begin
   if(KeyCode >= -1) and (KeyCode < nKeys) then
      Result := pKeys[KeyCode].IsSet(kpPRESSED_RELEASED)
   else
      Result := false;
end;

function appiTKeyStates.Interpolated(kc: loopint): single;
begin
   if(pKeys[kc].IsSet(kpPRESSED_RELEASED)) then
      Result := 0.25
   else if(pKeys[kc].IsSet(kpPRESSED) and pKeys[kc].IsSet(kpWAS_PRESSED)) then
      Result := 1.0
   else if(pKeys[kc].IsSet(kpWAS_PRESSED) or pKeys[kc].IsSet(kpPRESSED)) then
      Result := 0.5
   else
      Result := 0;
end;

function appiTKeyStates.Interpolated(kc, optionalKC: loopint): single;
begin
   Result := Interpolated(kc);

   if(Result = 0) then
      Result := Interpolated(optionalKC);
end;

procedure appiTKeyStates.UpdateCycle();
var
   i: loopint;

begin
   for i := 0 to nKeys do begin
      pKeys[i].Clear(kpCYCLE_PRESSED or kpPRESSED_RELEASED);
      pKeys[i].Prop(kpWAS_PRESSED, pKeys[i].IsSet(kpPRESSED));
   end;
end;

procedure appiTKeyStates.Process(keyCode: loopint; pressed: boolean);
begin
   {determine if key was pressed in this cycle}
   if((not pKeys[keyCode].IsSet(kpPRESSED)) and pressed) then
      pKeys[keyCode].Prop(kpCYCLE_PRESSED);

   {is the key still pressed}
   pKeys[keyCode].Prop(kpPRESSED, pressed);

   if pKeys[keyCode].IsSet(kpCYCLE_PRESSED) and (not pressed) then
      pKeys[keyCode].Prop(kpPRESSED_RELEASED);
end;


END.
