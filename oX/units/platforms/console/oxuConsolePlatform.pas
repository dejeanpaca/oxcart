{
   oxuConsolePlatform, console platform base functionality
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuConsolePlatform;

INTERFACE

   USES
      Keyboard, Mouse,
      uStd, uLog,
      {app}
      appuKeys, appuKeyEvents,
      {oX}
      oxuWindowTypes, oxuPlatform;

TYPE
   { oxTConsolePlatform }

   oxTConsolePlatform = class(oxTPlatform)
      constructor Create(); override;

      procedure ProcessEvents(); override;
      function MakeWindow({%H-}wnd: oxTWindow): boolean; override;
      function DestroyWindow({%H-}wnd: oxTWindow): boolean; override;
   end;

IMPLEMENTATION

{ oxTConsolePlatform }

constructor oxTConsolePlatform.Create();
begin
   Name := 'console';
   MultipleWindows := false;
end;

procedure oxTConsolePlatform.ProcessEvents();
var
   k: TKeyEvent;
   m: TMouseEvent;
   hasEvent: boolean;

   kE: appTKeyEvent;

begin
   ZeroOut(m, SizeOf(m));
   ZeroOut(k, SizEOf(k));

   repeat
      k := PollKeyEvent();

      if(k <> 0) then begin
        Keyboard.GetKeyEvent();

         appk.Init(kE);
         kE.Key.Code := kcESC;
         kE.PlatformScanCode := k;

         appKeyEvents.Queue(kE.Key);
      end;
   until (k = 0);

   repeat
      hasEvent := PollMouseEvent(m);

      if(hasEvent) then
         GetMouseEvent(m);
   until (not hasEvent);
end;

function oxTConsolePlatform.MakeWindow(wnd: oxTWindow): boolean;
var
   mouseOk: boolean;

begin
   InitKeyboard();

   InitMouse();
   mouseOk := DetectMouse() > 0;

   if(not mouseOk) then
      log.w('console > Seems we do not have mouse support');

   Result := true;
end;

function oxTConsolePlatform.DestroyWindow(wnd: oxTWindow): boolean;
begin
   DoneKeyboard();
   DoneMouse();
   Result := true;
end;

END.
