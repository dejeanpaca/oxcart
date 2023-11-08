{
   oxuKeyboardControl, oX keyboard input control
   Copyright (C) 2010. Dejan Boras

   Started On:    25.08.2010.
}

{$INCLUDE oxdefines.inc}
UNIT oxuKeyboardControl;

INTERFACE

   USES
      uStd,
      appuKeys, appuEvents, appuKeyEvents,
      {oX}
      oxuWindowTypes, oxuGlobalKeys, oxuGlobalInstances, oxuWindow,
      {ui}
      oxuUI, uiuKeyEvents;

TYPE
   oxTKeyRoutine = function(var key: appTKeyEvent; wnd: oxTWindow): boolean;

   { oxTKeyGlobal }

   oxTKeyGlobal = class
      Routine,
      UpRoutine: oxTKeyRoutine;

      function Handle(var {%H-}e: appTEvent; var k: appTKeyEvent; wnd: oxTWindow): boolean; virtual;
      function Handle(var k: appTKeyEvent): boolean; virtual;
   end;

VAR
   oxKey: oxTKeyGlobal;

IMPLEMENTATION

function oxTKeyGlobal.Handle(var {%H-}e: appTEvent; var k: appTKeyEvent; wnd: oxTWindow): boolean;
begin
   {let the ui process keys}
   Result := uiKeyEvents.Action(oxui, e);

   if(not Result) then begin
      {If there is a global key handler then we should call them.}
      if(not oxGlobalKeys.Call(k.Key, wnd)) then begin
         {if no global key then call the callback routine}
         if(Routine <> nil) and (k.Key.IsPressed()) then
            Result := Routine(k, wnd);

         if(UpRoutine <> nil) and (k.Key.Released()) then
            Result := UpRoutine(k, wnd)
      end;
   end;
end;

function oxTKeyGlobal.Handle(var k: appTKeyEvent): boolean;
var
   e: appTEvent;

begin
   appEvents.Init(e, appKEY_EVENT, @appKeyEvents.evh);
   e.ExternalData := @k;

   Result := Handle(e, k, oxWindow.Current);
end;

procedure processKey(var e: appTEvent);
var
   data: Pointer;

begin
   data := e.GetData();

   if(data <> nil) and (oxKey <> nil) then
      oxKey.Handle(e, appPKeyEvent(data)^, oxTWindow(e.wnd))
end;

function instance(): TObject;
begin
   Result := oxTKeyGlobal.Create();
end;

INITIALIZATION
   appKeyEvents.ProcessingRoutine := @processKey;

   oxGlobalInstances.Add(oxTKeyGlobal, @oxKey, @instance);

END.
