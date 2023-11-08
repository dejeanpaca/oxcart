{
   appuKeyEvents, dApp key event management
   Copyright (C) 2009. Dejan Boras

   Started On:    14.03.2009.
}

{$INCLUDE oxdefines.inc}
UNIT appuKeyEvents;

INTERFACE

   USES
      uStd, appuKeys, appuEvents, appuInputTypes;

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
     function Queue(var k: appTKey; evID: longword = appKEY_EVENT; process: boolean = true): appPEvent;
   end;

VAR
   appKeyEvents: appTKeyEvents;

IMPLEMENTATION

function appTKeyEvents.Queue(var k: appTKey; evID: longword; process: boolean): appPEvent;
var
   event: appTEvent;
   kEvent: appTKeyEvent;

begin
   appEvents.Init(event, evID, @appKeyEvents.evh);
   appk.Init(kEvent);

   if(process) then begin
      appk.KeyProperties.Process(k.Code, k.IsPressed());

      {set modifiers and only modifiers to the existing state}
      k.State := k.State or (appk.Modifiers and kmMODIFIERS_MASK);
   end;

   kEvent.Key := k;

   Result := appEvents.Queue(event, kEvent, SizeOf(kEvent));
end;

procedure keyAction(var event: appTEvent);
begin
   if(appKeyEvents.ProcessingRoutine <> nil) then
      appKeyEvents.ProcessingRoutine(event);
end;

INITIALIZATION
   appEvents.AddHandler(appKeyEvents.evh, 'key', @keyAction);

END.
