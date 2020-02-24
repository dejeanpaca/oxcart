{
   Copyright (C) 2013. Dejan Boras
}

{$MODE OBJFPC}{$H+}
PROGRAM eventsTest;

USES
   uStd, uAppInfo, uLog, appuLog,
   appuEvents, appuConfigDir, StringUtils;

TYPE
   TEventData = record
      nope: longint;
   end;

CONST
   EVENT_COUNT                = 512;

VAR
   event: appTEvent;
   eventData: TEventData;
   i: longint;
   unfreedEvents: longint     = 0;
   dqEvent: appTEvent;
   pEvent: appPEvent;

procedure testFail(const s: string);
begin
   if(s <> '') then
      writeln(s);
   halt(1);
end;

BEGIN
   appInfo.setName('Events Test');

   appCreateConfigDir();
   appInitializeLogging();

   appuEventInitialize();
   if(appEvents.error <> eNONE) then begin
      testFail('Fatal: Failed to initialize event queue-');
   end;

   {prepare event}
   appInitEventRecord(event);
   ZeroOut(eventData, SizeOf(eventData));

   {queue it}
   writeln('queuing...');
   for i := 0 to EVENT_COUNT - 1 do begin
      pEvent := appEvents.Queue(event, eventData, SizeOf(eventData));
      if(pEvent = nil) then begin
         testFail('Fatal: Failed to queue an event.');
      end;
   end;

   {check if there are any skipped events}
   for i := 0 to appEvents.n - 1 do begin
      if(appEvents.q[i] = nil) then begin
         testFail('Fatal: There is a hole in the event queue at position ' + sf(i) + ' with ' + sf(appEvents.n) + ' events.');
      end;
   end;


   {take off all events}
   writeln('dequeuing...');
   repeat
      appEvents.Dequeue(dqEvent);
      dqEvent.Dispose();
   until (appEvents.Get() = nil);

   {check if there is a count mismatch}
   if(appEvents.queuedEvents <> appEvents.dequeuedEvents) then begin
      writeln('Fatal: queued/dequeued event count mismatch (',appEvents.queuedEvents,', ',appEvents.dequeuedEvents,').');
      writeln('Remaining event count: ', appEvents.n, ' | Allocated: ', appEvents.allocated,' | Head: ', appEvents.head, ' | Tail: ', appEvents.tail);
      testFail('');
   end;

   {check if there are any events leftover}
   for i := 0 to appEvents.allocated - 1 do begin
      if(appEvents.q[i] <> nil) then
         inc(unfreedEvents);
   end;

   if(unfreedEvents > 0) then begin
      testFail('Fatal: There are ' + sf(unfreedEvents) + 'unfreed events.');
   end;

   appuEventDeInitialize();

   writeln('done');
END.
