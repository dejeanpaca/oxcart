{
   appuMouse, mouse input management
   Copyright (C) 2007. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT appuMouse;

INTERFACE

   USES
      uLog, uStd, StringUtils;

CONST
   {mouse event history size}
   appmcDEFAULT_EVENT_LIST_SIZE     = 32;
   {mouse keys pressed}
   appmcKEYS_PRESSED_LIST_SIZE      = 8;

   {mouse button bit-masks for the ButtonStates variable}
   appmc1 = $01;   
   appmcLEFT   = appmc1;
   appmc2 = $02;   
   appmcRIGHT  = appmc2;
   appmc3 = $04;   
   appmcMIDDLE = appmc3;
   appmc4 = $08;
   appmc5 = $10;
   appmc6 = $20;
   appmc7 = $40;
   appmc8 = $80;
   appmc9 = $100;
   appmcA = $200;
   appmcB = $400;
   appmcC = $800;
   appmcD = $1000;
   appmcE = $2000;
   appmcF = $4000;
   
   {mouse action type}
   appmcPRESSED         = $01;
   appmcRELEASED        = $02;
   appmcMOVED           = $04;
   appmcWHEEL           = $08;

   {determines whether the mouse driver is initialized}
   appmcMouseInitialized: boolean = false;

   {maximum pointer devices supported}
   MAX_POINTER_DEVICES  = 8;
   MAX_POINTER_DEVICE   = MAX_POINTER_DEVICES - 1;

TYPE
   appPMouseEvent = ^appTMouseEvent;

   { appTMouseEvent }

   appTMouseEvent = record
      x, y: single;
      Action, 
      bState, 
      Button: TBitSet;
      Value: longint;
      DevID: longint;

      function IsPressed(): boolean; inline;
      function IsReleased(): boolean; inline;
      function IsMoved(): boolean; inline;
      function IsWheel(): boolean; inline;

      function IsButtonAction(): boolean; inline;

      function ToString(): string;
   end;

   {mouse driver implementation}

   { appTPointerDriver }

   appTPointerDriver = class
      public
         Name: string;

      constructor Create();

      procedure GetXY(devID: longint; {%H-}wnd: pointer; out x, y: single); virtual;
      procedure SetXY(devID: longint; {%H-}wnd: pointer; x, y: single); virtual;
      procedure Grab(devID: longint; {%H-}wnd: pointer); virtual;
      procedure Release(devID: longint; {%H-}wnd: pointer); virtual;
      function Grabbed(devID: longint; {%H-}wnd: pointer): boolean; virtual;
      procedure Hide(devID: longint; {%H-}wnd: pointer); virtual;
      procedure Show(devID: longint; {%H-}wnd: pointer); virtual;
      function Shown(devID: longint; {%H-}wnd: pointer): boolean; virtual;
      function ButtonState(devID: longint; {%H-}wnd: pointer): longword; virtual;
   end;

   appPPointerState = ^appTPointerState;
   appTPointerState = record
      nButtons: longint;
      ButtonState: longint;
      x,
      y,
      mx,
      my: single;
      Shown: longint;
      Grabbed: boolean;
   end;

   appTMouseGlobal = record
      Pointer: array[0..MAX_POINTER_DEVICE] of appTPointerState;

      {pointer driver}
      DummyPointerDriver: appTPointerDriver;
      PointerDriver: appTPointerDriver;

      { GENERAL }
      {initialize a appTMouseEvent record}
      procedure Init(out h: appTMouseEvent);

      {set pointer position to x, y coordinates}
      procedure SetPosition(devID: longint; wnd: pointer; x, y: single);
      procedure SetPosition(wnd: pointer; x, y: single);
      {get pointer position}
      procedure GetPosition(devID: longint; wnd: pointer; out x, y: single);
      procedure GetPosition(wnd: pointer; out x, y: single);
      {hide and show the pointer}
      procedure Hide(devID: longint; wnd: pointer);
      procedure Hide(wnd: pointer);
      procedure Show(devID: longint; wnd: pointer);
      procedure Show(wnd: pointer);
      {check if the pointer is show}
      function Shown(devID: longint; wnd: pointer): boolean;
      function Shown(wnd: pointer): boolean;

      {grab and release pointer control}
      procedure Grab(devID: longint; wnd: pointer);
      procedure Grab(wnd: pointer);
      procedure Release(devID: longint; wnd: pointer);
      procedure Release(wnd: pointer);

      {check if the pointer control is grabbed}
      function Grabbed(devID: longint; wnd: pointer): boolean;
      function Grabbed(wnd: pointer): boolean;

      { POINTER DRIVER }
      procedure SetDriver(drv: appTPointerDriver);
   end;

VAR
   appm: appTMouseGlobal;

IMPLEMENTATION

{ appTMouseEvent }

function appTMouseEvent.IsPressed(): boolean;
begin
   Result := Action = appmcPRESSED;
end;

function appTMouseEvent.IsReleased(): boolean;
begin
   Result := Action = appmcRELEASED;
end;

function appTMouseEvent.IsMoved(): boolean;
begin
   Result := Action = appmcMOVED;
end;

function appTMouseEvent.IsWheel(): boolean;
begin
   Result := Action = appmcWHEEL;
end;

function appTMouseEvent.IsButtonAction(): boolean;
begin
   Result := IsPressed() or IsMoved() or IsReleased();
end;

function appTMouseEvent.ToString(): string;
var
   actionString,
     buttonString: TAppendableString;

begin
   actionString := '';
   buttonString := '';

   if(Action.IsSet(appmcPRESSED)) then
      actionString.Add('PRESSED', ',');

   if(Action.IsSet(appmcRELEASED)) then
      actionString.Add('RELEASED', ',');

   if(Action.IsSet(appmcMOVED)) then
      actionString.Add('MOVED', ',');

   if(Action.IsSet(appmcWHEEL)) then
      actionString.Add('WHEEL', ',');

   if(button.IsSet(appmcLEFT)) then
      buttonString.Add('LEFT', ',');

   if(button.IsSet(appmcRIGHT)) then
      buttonString.Add('RIGHT', ',');

   if(button.IsSet(appmcMIDDLE)) then
      buttonString.Add('MIDDLE', ',');

   if(button.IsSet(appmc4)) then
      buttonString.Add('4', ',');

   if(button.IsSet(appmc5)) then
      buttonString.Add('5', ',');

   Result := sf(x, 0) + 'x' + sf(y, 0) + ' ' + actionString + ' - ' + buttonString;
end;

{ GENERAL }

procedure appTMouseGlobal.Init(out h: appTMouseEvent);
begin
   ZeroOut(h, SizeOf(h));
end;

procedure appTMouseGlobal.SetPosition(devID: longint; wnd: pointer; x, y: single);
begin
   if(devID >= 0) and (devID < MAX_POINTER_DEVICES) then
      appm.PointerDriver.SetXY(devID, wnd, x, y);
end;

procedure appTMouseGlobal.SetPosition(wnd: pointer; x, y: single);
begin
   SetPosition(0, wnd, x, y);
end;

procedure appTMouseGlobal.GetPosition(devID: longint; wnd: pointer; out x, y: single);
begin
   if(devID >= 0) and (devID < MAX_POINTER_DEVICES) then
      appm.PointerDriver.GetXY(devID, wnd, x, y);
end;

procedure appTMouseGlobal.GetPosition(wnd: pointer; out x, y: single);
begin
   GetPosition(0, wnd, x, y);
end;

procedure appTMouseGlobal.Hide(devID: longint; wnd: pointer);
begin
   if(devID >= 0) and (devID < MAX_POINTER_DEVICES) then
      appm.PointerDriver.Hide(devID, wnd);
end;

procedure appTMouseGlobal.Hide(wnd: pointer);
begin
   Hide(0, wnd);
end;

procedure appTMouseGlobal.Show(devID: longint; wnd: pointer);
begin
   if(devID >= 0) and (devID < MAX_POINTER_DEVICES) then
      appm.PointerDriver.Show(devID, wnd);
end;

procedure appTMouseGlobal.Show(wnd: pointer);
begin
   Show(0, wnd);
end;

function appTMouseGlobal.Shown(devID: longint; wnd: pointer): boolean;
begin
   if(devID >= 0) and (devID < MAX_POINTER_DEVICES) then
      Result := appm.PointerDriver.Shown(devID, wnd)
   else
      Result := true;
end;

function appTMouseGlobal.Shown(wnd: pointer): boolean;
begin
   Result := Shown(0, wnd);
end;


procedure appTMouseGlobal.Grab(devID: longint; wnd: pointer);
begin
   if(devID >= 0) and (devID < MAX_POINTER_DEVICES) then
      appm.PointerDriver.Grab(devID, wnd);
end;

procedure appTMouseGlobal.Grab(wnd: pointer);
begin
   Grab(0, wnd);
end;

procedure appTMouseGlobal.Release(devID: longint; wnd: pointer);
begin
   if(devID >= 0) and (devID < MAX_POINTER_DEVICES) then
      appm.PointerDriver.Release(devID, wnd);
end;

procedure appTMouseGlobal.Release(wnd: pointer);
begin
   Release(0, wnd);
end;

function appTMouseGlobal.Grabbed(devID: longint; wnd: pointer): boolean;
begin
   if(devID >= 0) and (devID < MAX_POINTER_DEVICES) then
      Result := appm.PointerDriver.Grabbed(devID, wnd)
   else
      Result := false;
end;

function appTMouseGlobal.Grabbed(wnd: pointer): boolean;
begin
   Result := Grabbed(0, wnd);
end;

{ POINTER DRIVER }

procedure appTMouseGlobal.SetDriver(drv: appTPointerDriver);
begin
   ZeroOut(appm.Pointer, SizeOf(appm.Pointer));

   if(drv <> nil) then begin
      appm.PointerDriver := drv;
      log.v('Set ' + appm.PointerDriver.ClassName + ' pointer driver');
   end else begin
      appm.PointerDriver := appm.DummyPointerDriver;
      log.v('Cleared pointer driver');
   end;
end;

constructor appTPointerDriver.Create();
begin
   Name := 'virtual';
end;

procedure appTPointerDriver.GetXY(devID: longint; wnd: pointer; out x, y: single);
begin
   x := appm.Pointer[devID].x;
   y := appm.Pointer[devID].y;
end;

procedure appTPointerDriver.SetXY(devID: longint; wnd: pointer; x, y: single);
begin
   appm.Pointer[devID].x := x;
   appm.Pointer[devID].y := y;
end;

procedure appTPointerDriver.Grab(devID: longint; wnd: pointer);
begin
   appm.Pointer[devID].Grabbed := true;
end;

procedure appTPointerDriver.Release(devID: longint; wnd: pointer);
begin
   appm.Pointer[devID].Grabbed := true;
end;

function appTPointerDriver.Grabbed(devID: longint; wnd: pointer): boolean;
begin
   Result := appm.Pointer[devID].Grabbed;
end;

procedure appTPointerDriver.Hide(devID: longint; wnd: pointer);
begin
   dec(appm.Pointer[devID].Shown);
end;

procedure appTPointerDriver.Show(devID: longint; wnd: pointer);
begin
   inc(appm.Pointer[devID].Shown);
end;

function appTPointerDriver.Shown(devID: longint; wnd: pointer): boolean;
begin
   Result := appm.Pointer[devID].Shown >= 0;
end;

function appTPointerDriver.ButtonState(devID: longint; wnd: pointer): longword;
begin
   Result := appm.Pointer[devID].ButtonState;
end;

INITIALIZATION
   appm.DummyPointerDriver := appTPointerDriver.Create();
   appm.PointerDriver := appm.DummyPointerDriver;

FINALIZATION
   FreeObject(appm.DummyPointerDriver);

END.

