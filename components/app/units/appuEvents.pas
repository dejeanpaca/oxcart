{
   appuEvents, application event management
   Copyright (C) 2008. Dejan Boras

   Started On:    16.12.2008.
}


{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH ADVANCEDRECORDS}
UNIT appuEvents;

INTERFACE

   USES sysutils, uStd, uApp;

CONST
   appEVENT_PROP_DISABLED                 = $0001;

TYPE
   appPEventHandler     = ^appTEventHandler;
   appPEvent            = ^appTEvent;

   TEventID = loopint;

   {individual event}

   { appTEvent }

   appTEvent = record
      {even Id}
      evID: TEventID;
      {event handler}
      hID: appPEventHandler;
      {window associated with the event}
      wnd: pointer;
      {data which is external and should not be freed}
      ExternalData,
      {data specific to the event which can be freed}
      Data: pointer;
      {additional parameters}
      Params: array[0..3] of loopint;
      {event properties}
      Properties: TBitSet;

      {get Data or ExternalData property based on what is not nil}
      function GetData(): Pointer;

      {dispose of the event data}
      procedure Dispose();

      {check if event has the specified handler}
      function IsHandler(var h): boolean;
      {check if the event has the specified handler and id}
      function IsEvent(var h; id: TEventId): boolean;
   end;

   {event handler routines}
   appevhTDisposeProc   = procedure(var event: appTEvent);
   appevhTActionProc    = procedure(var event: appTEvent);

   {event handler}
   appTEventHandler = record
      sName: string;

      Initialize: TProcedure;
      DeInitialize: TProcedure;

      Dispose: appevhTDisposeProc;
      Action:  appevhTActionProc;

      Next: appPEventHandler;
   end;


   { appTEventQueue }

   appTEventQueue = record
      Settings: record
         {starting event queue size}
         StartCount,
         {count to increase event queue size once more events are needed}
         IncreaseStep: loopint;
      end;

      NilHandler: appTEventHandler;

      Error,
      {queue}
      Allocated,
      Tail,
      Head,

      n: loopint;
      q: array of appTEvent;

      Handlers: record
         n: loopint;
         s,
         e: appPEventHandler;
      end;

      CS: TRTLCriticalSection;

      { GENERAL }

      {initialize records}
      procedure Init(out ev: appTEvent);
      procedure Init(out ev: appTEvent; evID: longword; hID: appPEventHandler);

      {dispose a event}
      procedure Dispose(var ev: appPEvent);

      {initialize the event handler record}
      procedure Init(out evh: appTEventHandler);

      { QUEUE }

      {gets a pointer to the last event placed in the queue}
      function Get(): appPEvent;
      {set queue list size}
      function SetSize(specificSize: loopint): boolean;
      {increase queue list size by a count}
      function IncreaseSize(count: loopint): boolean;
      {dispose of the event list}
      procedure Dispose();

      {queue an event onto the list}
      function Queue(var ev: appTEvent): appPEvent;
      function Queue(var ev: appTEvent; var eventData; dataSize: loopint): appPEvent;
      {dequeues an event off the list}
      procedure Dequeue(out ev: appTEvent);
      procedure Dequeue();
      {replaces the last queued event}
      procedure Replace(var ev: appTEvent);
      procedure Replace(var ev: appTEvent; var eventData; dataSize: loopint);

      procedure RemovedEvent();

      {check if an event with the specified ID been queued}
      function Queued(hID: appPEventHandler; evID: TEventID): boolean;

      {adds a event handler to the list}
      procedure AddHandler(var evh: appTEventHandler);
      function AddHandler(out evh: appTEventHandler; const name: string; action: appevhTActionProc = nil): appPEventHandler;
      {find handler with the given name}
      function FindHandler(const name: string): appPEventHandler;
      {initialize all event handlers}
      procedure InitializeHandlers();
      {deinitialize all event handlers}
      procedure DeInitializeHandlers();

      {disables events for a window}
      procedure DisableForWindow(wnd: pointer; hID: appPEventHandler = nil; evID: loopint = -1);
      {disables events with the specified data}
      procedure DisableWithData(data: pointer; hID: appPEventHandler = nil; evID: loopint = -1);

      { INITIALIZATION }

      {initialize the unit and resources}
      procedure Initialize();
      {de-initialize the unit and resources}
      procedure DeInitialize();
   end;

VAR
   {event queue}
   appEvents: appTEventQueue;

IMPLEMENTATION

{INITIALIZE}
procedure appTEventQueue.Init(out ev: appTEvent);
begin
   ZeroOut(ev, SizeOf(ev));
end;

procedure appTEventQueue.Init(out ev: appTEvent; evID: longword; hID: appPEventHandler);
begin
   ZeroOut(ev, SizeOf(ev));
   ev.evID  := evID;
   ev.hID   := hID;
end;

function appTEvent.GetData(): Pointer;
begin
   if(Data <> nil) then
      Result := Data
   else
      Result := ExternalData;
end;

{EVENT HELPER}
procedure appTEvent.Dispose();
begin
   if(hID <> nil) then begin
      if(hID^.Dispose <> nil) then
         hID^.Dispose(Self);
   end;

   XFreeMem(Data);
end;

function appTEvent.IsHandler(var h): boolean;
begin
   Result := hID = @h;
end;

function appTEvent.IsEvent(var h; id: TEventId): boolean;
begin
   Result := (hID = @h) and (evID = id);
end;

procedure appTEventQueue.Dispose(var ev: appPEvent);
begin
   if(ev <> nil) then begin
      ev^.Dispose();
      ev := nil;
   end;
end;

{ QUEUE }

function appTEventQueue.SetSize(specificSize: loopint): boolean;
begin
   {$IFNDEF NO_THREADS}
   EnterCriticalsection(CS);
   {$ENDIF}

   Allocated := specificSize;
   try
      SetLength(q, Allocated);

      if(Allocated > 0) then
         ZeroOut(q[0], SizeOf(appPEvent) * int64(Allocated));

      Result := true;
   except
      error := eNO_MEMORY;
      exit(false);
   end;

   n     := 0;
   Tail  := 0;
   Head  := 0;

   {$IFNDEF NO_THREADS}
   LeaveCriticalsection(CS);
   {$ENDIF}
end;

function appTEventQueue.IncreaseSize(count: loopint): boolean;
var
   i,
   pi,
   pn: loopint;
   nq: array of appTEvent;

begin
   {$IFNDEF NO_THREADS}
   EnterCriticalsection(CS);
   {$ENDIF}

   nq := nil;

   if(count > 0) then begin
      pn := Allocated;
      inc(Allocated, count);

      try
         SetLength(nq, Allocated);

         ZeroOut(nq[0], SizeOf(appPEvent) * int64(Allocated));

         {reorder elements into the new array}
         pi := 0;
         if(n > 0) then begin
            i := Head;

            repeat
               nq[pi] := q[i];

               inc(i);
               if(i > pn) then
                  i := 0;

               inc(pi);
            until(i = Tail);
         end;

         {replace old array with new one}
         SetLength(q, 0);
         q := nq;

         Result := true;
      except
         error := eNO_MEMORY;
         Result := false;
      end;
   end else
      Result := true;

   {$IFNDEF NO_THREADS}
   LeaveCriticalsection(CS);
   {$ENDIF}
end;

procedure appTEventQueue.Dispose();
var
   ev: appTEvent;

begin
   if(n > 0) then
      repeat
         Dequeue(ev);
         ev.Dispose();
      until (n = 0);

   appEvents.SetSize(0);
end;

function appTEventQueue.Get(): appPEvent;
begin
   if(n > 0) then
      Result := @q[Head]
   else
      Result := nil;
end;

function appTEventQueue.Queue(var ev: appTEvent): appPEvent;
begin
   {$IFNDEF NO_THREADS}
   EnterCriticalsection(CS);
   {$ENDIF}

   {if we're out of memory, increase the event queue}
   if(n >= Allocated - 1) then
      IncreaseSize(settings.IncreaseStep);

   {if the event can fit into the queue}
   if(n < Allocated) then begin
      q[Tail]  := ev;
      Result   := @q[Tail];

      inc(n);
      inc(Tail);

      if(Tail > Allocated - 1) then
         Tail := 0;
   end else
      Result := nil;

   {$IFNDEF NO_THREADS}
   LeaveCriticalsection(CS);
   {$ENDIF}
end;

function appTEventQueue.Queue(var ev: appTEvent; var eventData; dataSize: loopint): appPEvent;
begin
   {get memory for the data and place it}
   if(dataSize > 0) then begin
      GetMem(ev.Data, dataSize);

      if(ev.Data <> nil) then
         Move(eventData, ev.Data^, dataSize)
      else begin
         error := eNO_MEMORY;
         exit(nil);
      end;
   end;

   {queue the event}
   Result := Queue(ev);
end;

procedure appTEventQueue.Dequeue(out ev: appTEvent);
begin
   {$IFNDEF NO_THREADS}
   EnterCriticalsection(CS);
   {$ENDIF}

   if(n > 0) then begin
      ev := q[Head];

      RemovedEvent();
   end;

   {$IFNDEF NO_THREADS}
   LeaveCriticalsection(CS);
   {$ENDIF}
end;

procedure appTEventQueue.Dequeue();
begin
   {$IFNDEF NO_THREADS}
   EnterCriticalsection(CS);
   {$ENDIF}

   if(n > 0) then
      RemovedEvent();

   {$IFNDEF NO_THREADS}
   LeaveCriticalsection(CS);
   {$ENDIF}
end;

procedure appTEventQueue.Replace(var ev: appTEvent);
var
   pev: appPEvent;

begin
   {$IFNDEF NO_THREADS}
   EnterCriticalsection(CS);
   {$ENDIF}

   pev := Get();
   if(pev <> nil) then begin
      pev^.Dispose();
      pev^ := ev;
   end;

   {$IFNDEF NO_THREADS}
   LeaveCriticalsection(CS);
   {$ENDIF}
end;

procedure appTEventQueue.Replace(var ev: appTEvent; var eventData; dataSize: loopint);
var
   pev: appPEvent;

begin
   {$IFNDEF NO_THREADS}
   EnterCriticalsection(CS);
   {$ENDIF}

   pev := Get();
   if(pev <> nil) then begin
      {dispose the previous event}
      pev^.Dispose();

      {get memory for the data and place it}
      GetMem(ev.Data, dataSize);
      if(ev.Data <> nil) then
         move(eventData, ev.Data^, dataSize)
      else
         error := eNO_MEMORY;

      {replace the event}
      pev^ := ev;
   end;

   {$IFNDEF NO_THREADS}
   LeaveCriticalsection(CS);
   {$ENDIF}
end;

procedure appTEventQueue.RemovedEvent();
begin
   dec(n);
   inc(Head);

   if(Head > Allocated - 1) then
      Head := 0;
end;

function appTEventQueue.Queued(hID: appPEventHandler; evID: TEventID): boolean;
var
   i: loopint;

begin
   {$IFNDEF NO_THREADS}
   EnterCriticalsection(CS);
   {$ENDIF}

   if(n > 0) then begin
      i := Head;

      repeat
         if((q[i].evID = evID) and (q[i].hID = hID)) then begin
            {$IFNDEF NO_THREADS}
            LeaveCriticalsection(CS);
            {$ENDIF}
            exit(True);
         end;

         inc(i);
         if(i >= Allocated) then
            i := 0;
      until(i = Tail);
   end;

   Result := false;
   {$IFNDEF NO_THREADS}
   LeaveCriticalsection(CS);
   {$ENDIF}
end;

{ DUMMY EVENT HANDLER }

{$PUSH}{$HINTS OFF}
procedure nilInitialize(); begin end;
procedure nilDispose(var ev: appTEvent); begin end;
procedure nilAction(var ev: appTEvent); begin end;
{$POP}

procedure nilHandlerInitialize();
begin
   ZeroOut(appEvents.NilHandler, SizeOf(appEvents.NilHandler));

   appEvents.NilHandler.sName          := 'NIL';

   appEvents.NilHandler.Initialize     := @nilInitialize;
   appEvents.NilHandler.DeInitialize   := @nilInitialize;
   appEvents.NilHandler.Dispose        := @nilDispose;
   appEvents.NilHandler.Action         := @nilAction;
end;

{ EVENT HANDLERS}

procedure appTEventQueue.Init(out evh: appTEventHandler);
begin
   evh := appEvents.NilHandler;
end;

procedure appTEventQueue.AddHandler(var evh: appTEventHandler);
begin
   assert(FindHandler(evh.sName) = nil, 'Event handler with name ' + evh.sName + ' already exists');

   evh.Next := nil;

   if(handlers.s = nil) then
      handlers.s := @evh
   else
      handlers.e^.Next := @evh;

   handlers.e := @evh;
end;

function appTEventQueue.AddHandler(out evh: appTEventHandler; const name: string; action: appevhTActionProc): appPEventHandler;
begin
   Init(evh);
   evh.sName := name;
   evh.Action := action;
   AddHandler(evh);

   Result := @evh;
end;

function appTEventQueue.FindHandler(const name: string): appPEventHandler;
var
   cur: appPEventHandler;

begin
   Result := nil;
   cur := Handlers.s;

   if(cur <> nil) then repeat
      if(cur^.sName = name) then
         exit(cur);

      cur := cur^.Next;
   until (cur = nil);
end;

procedure appTEventQueue.InitializeHandlers();
var
   cur: appPEventHandler;

begin
   cur := Handlers.s;

   if(cur <> nil) then repeat
      cur^.Initialize();

      cur := cur^.Next;
   until (cur = nil);
end;

procedure appTEventQueue.DeInitializeHandlers();
var
   cur: appPEventHandler;

begin
   cur := Handlers.s;

   if(cur <> nil) then repeat
      cur^.DeInitialize();
      cur := cur^.Next;
   until (cur = nil);
end;

procedure appTEventQueue.DisableForWindow(wnd: pointer; hID: appPEventHandler; evID: loopint);
var
   i,
   c: loopint;

begin
   i := 0;

   if(n > 0) then repeat
      c := (i + Head) mod Allocated;

      if(q[c].wnd = wnd) and ((hID = nil) or (q[c].hID = hID)) and ((evID = -1) or (q[c].evID = evID)) then begin
         q[c].Properties := q[c].Properties or appEVENT_PROP_DISABLED;
      end;

      inc(i);
   until (i >= n);
end;

procedure appTEventQueue.DisableWithData(data: pointer; hID: appPEventHandler;
   evID: loopint);
var
   i,
   c: loopint;

begin
   i := 0;

   if(n > 0) then repeat
      c := (i + Head) mod Allocated;

      if((hID = nil) or (q[c].hID = hID)) and (data = q[c].Data) and ((evID = -1) or (q[c].evID = evID)) then begin
         q[c].Properties := q[c].Properties or appEVENT_PROP_DISABLED;
      end;

      inc(i);
   until (i >= n);
end;

{ INITIALIZATION }

procedure appTEventQueue.Initialize();
begin
   {$IFNDEF NO_THREADS}
   InitCriticalSection(CS);
   {$ENDIF}

   {set the queue to the default queue size}
   SetSize(settings.StartCount);

   {initialize all event handlers}
   InitializeHandlers();
end;

procedure appTEventQueue.DeInitialize();
begin
   DeInitializeHandlers();
   Dispose();

   {$IFNDEF NO_THREADS}
   DoneCriticalsection(CS);
   {$ENDIF}
end;

procedure initialize();
begin
   appEvents.Initialize();
end;

procedure deinitialize();
begin
   appEvents.DeInitialize();
end;

INITIALIZATION
   appEvents.Settings.StartCount   := 64;
   appEvents.Settings.IncreaseStep := 128;

   app.InitializationProcs.Add('events', @initialize, @deinitialize);

   {setup the nil event handler}
   nilHandlerInitialize();
END.

