{
   appuKeyEvents, dApp key event management
   Copyright (C) 2009. Dejan Boras

   Started On:    14.03.2009.
}

{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH ADVANCEDRECORDS}
UNIT appuKeyEvents;

INTERFACE

   USES appuKeys, appuEvents;

CONST
   {event actions}
   appKEY_EVENT = $0001;

TYPE
   appTKeyEvents = record
     {event handler}
     evh: appTEventHandler;

     {default key event processing routine}
     ProcessingRoutine: procedure(var e: appTEvent);

     {queues a key event}
     function Queue(var k: appTKey; evID: longword = appKEY_EVENT): appPEvent;
   end;

VAR
   appKeyEvents: appTKeyEvents;

IMPLEMENTATION

function appTKeyEvents.Queue(var k: appTKey; evID: longword): appPEvent;
var
   event: appTEvent;
   kEvent: appTKeyEvent;

begin
   appEvents.Init(event, evID, @appKeyEvents.evh);
   appk.Init(kEvent);

   kEvent.Key := k;

   result := appEvents.Queue(event, kEvent, SizeOf(kEvent));
end;

procedure keyAction(var event: appTEvent);
begin
   if(appKeyEvents.ProcessingRoutine <> nil) then
      appKeyEvents.ProcessingRoutine(event);
end;

INITIALIZATION
   appEvents.AddHandler(appKeyEvents.evh, 'key', @keyAction);

END.
