{
   appuMouseEvents, mouse events
   Copyright (C) 2009 Dejan Boras

   Started On:    14.03.2009.
}

{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH ADVANCEDRECORDS}
UNIT appuMouseEvents;

INTERFACE

   USES
      appuMouse, appuEvents;

CONST
   {event actions}
   appMOUSE_EVENT = $001;

TYPE
   appTMouseEvents = record
      {event handler}
      evh: appTEventHandler;

      {mouse event processing routine}
      ProcessingRoutine: procedure(var e: appTEvent);

      {queue a mouse event}
      function Queue(var m: appTMouseEvent; evID: longword = appMOUSE_EVENT): appPEvent;
   end;

VAR
   appMouseEvents: appTMouseEvents;

IMPLEMENTATION

function appTMouseEvents.Queue(var m: appTMouseEvent; evID: longword): appPEvent;
var
   event: appTEvent;

begin
   appEvents.Init(event, evID, @evh);

   Result := appEvents.Queue(event, m, SizeOf(m));
end;

procedure mouseAction(var event: appTEvent);
begin
   if(appMouseEvents.ProcessingRoutine <> nil) then
      appMouseEvents.ProcessingRoutine(event);
end;

INITIALIZATION
   appEvents.AddHandler(appMouseEvents.evh, 'mouse', @mouseAction);

END.
