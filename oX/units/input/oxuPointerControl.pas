{
   oxuMouseControl, oX pointing device input control
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuPointerControl;

INTERFACE

   USES
      appuMouse, appuEvents, appuMouseEvents,
   	{oX}
	   oxuPlatform, oxuUI, oxuGlobalInstances, oxuWindow,
      {ui}
      uiuUI, uiuPointerEvents;

TYPE
   { oxTPointerGlobal }

   oxTPointerGlobal = class
      procedure Handle(oxui: uiTUI; var e: appTEvent); virtual;
      procedure Handle(oxui: uiTUI; var m: appTMouseEvent); virtual;
   end;

VAR
   oxPointer: oxTPointerGlobal;

IMPLEMENTATION

procedure oxTPointerGlobal.Handle(oxui: uiTUI; var e: appTEvent);
begin
   uiPointerEvents.Action(oxui, e);
end;

procedure oxTPointerGlobal.Handle(oxui: uiTUI; var m: appTMouseEvent);
var
   e: appTEvent;

begin
   appEvents.Init(e, appMOUSE_EVENT, @appMouseEvents.evh);
   e.ExternalData := @m;
   e.wnd := oxWindow.Current;

   Handle(oxui, e);
end;

procedure processPointer(var e: appTEvent);
var
   data: pointer;

begin
   data := e.GetData();

  if(data <> nil) and (e.wnd <> nil) then
      oxPointer.Handle(oxui, e);
end;

function instance(): TObject;
begin
   Result := oxTPointerGlobal.Create();
end;

INITIALIZATION
   appMouseEvents.ProcessingRoutine := @processPointer;

   oxGlobalInstances.Add(oxTPointerGlobal, @oxPointer, @instance);

END.
