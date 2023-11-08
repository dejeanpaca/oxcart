{
   oxuConsolePlatform, console platform base functionality
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuConsolePlatform;

INTERFACE

   USES
      Keyboard, Mouse,
      uStd, uLog,
      {oX}
      oxuWindowTypes, oxuPlatform;

TYPE
   { oxTConsolePlatform }

   oxTConsolePlatform = class(oxTPlatform)
      constructor Create(); override;

      procedure ProcessEvents(); override;
      function MakeWindow(wnd: oxTWindow): boolean; override;
      function DestroyWindow(wnd: oxTWindow): boolean; override;
   end;

IMPLEMENTATION

{ oxTConsolePlatform }

constructor oxTConsolePlatform.Create();
begin
   Name := 'console';
end;

procedure oxTConsolePlatform.ProcessEvents();
var
   k: TKeyEvent;
   m: TMouseEvent;
   hasEvent: boolean;

begin
   ZeroOut(m, SizeOf(m));
   ZeroOut(k, SizEOf(k));

   repeat
     k := PollKeyEvent();

     if(k <> 0) then
        Keyboard.GetKeyEvent();
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
