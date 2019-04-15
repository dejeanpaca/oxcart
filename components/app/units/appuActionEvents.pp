{
   appuActionEvents, application action events
   Copyright (C) 2009. Dejan Boras

   Started On:    27.12.2009.

   NOTE: An action with value 0 indicates no action.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT appuActionEvents;

INTERFACE

   USES
      uStd,
      uApp, appuEvents;

TYPE
   {callback routines}
   apphTActionHandlerCallback = function(const event: appTEvent): boolean;

   {action handler record}
   appPActionHandler = ^appTActionHandler;
   appTActionHandler = record
      call: apphTActionHandlerCallback;
      next: appPActionHandler;
   end;

   appPActionCallback = ^appTActionCallback;

   { appTActionCallback }

   appTActionCallback = record
      Action: longint;
      Callback: TProcedure;
      ObjectCallback: TObjectProcedure;

      procedure Call();
   end;

   appTActionCallbacks = specialize TPreallocatedArrayList<appTActionCallback>;

   { appTActionEvents }

   appTActionEvents = record
      evh: appTEventHandler;

      Callbacks: appTActionCallbacks;

      {queues a action event}
      function Queue(evID: longword; prm: longword = 0; wnd: pointer = nil): appPEvent;
      {returns an unique ID for the specified action event}
      function GetID(): longint;
      {registers an action handler}
      procedure Register(var ah: appTActionHandler);

      {register a callback associated with the given action}
      procedure SetCallback(action: TEventID; callback: TProcedure);
      {register a callback associated with the given action}
      procedure SetCallback(action: TEventID; callback: TObjectProcedure);
      {register a callback and return an event ID for it}
      function SetCallback(callback: TProcedure): TEventID;
      {register a callback and return an event ID for it}
      function SetCallback(callback: TObjectProcedure): TEventID;

      function FindCallback(action: TEventID): appPActionCallback;
      {replace an existing callback with the specified one}
      function ReplaceCallback(action: TEventID; callback: TProcedure): boolean;

      {queue an application quit event}
      procedure QueueQuitEvent();

      class procedure Initialize(out events: appTActionEvents); static;
   end;

VAR
   appActionEvents: appTActionEvents;
   evhpACTION_EVENTS: appPEventHandler;
   appACTION_QUIT: TEventID;

IMPLEMENTATION

VAR
   first,
   last: appPActionHandler;

VAR
   UniqueActionEventID: longint = 0;

{ appTActionCallback }

procedure appTActionCallback.Call();
begin
   if(Callback <> nil) then
      Callback();

   if(ObjectCallback <> nil) then
      ObjectCallback();
end;

function appTActionEvents.Queue(evID: longword; prm: longword; wnd: pointer): appPEvent;
var
   event: appTEvent;

begin
   appEvents.Init(event, evID, @evh);

   event.Params[0]   := prm;

   result := appEvents.Queue(event);
   result^.wnd := wnd;
end;

function appTActionEvents.GetID(): longint;
begin
   inc(UniqueActionEventID);
   result := UniqueActionEventID;
end;

procedure appTActionEvents.Register(var ah: appTActionHandler);
begin
   ah.next := nil;

   if(first <> nil) then
      last^.next := @ah
   else
     first := @ah;

   last := @ah;
end;

procedure appTActionEvents.SetCallback(action: TEventID; callback: TProcedure);
var
   c: appTActionCallback;

begin
   if(callback <> nil) then begin
      c.Action := action;
      c.Callback := callback;
      c.ObjectCallback := nil;

      Callbacks.Add(c);
   end;
end;

procedure appTActionEvents.SetCallback(action: TEventID; callback: TObjectProcedure);
var
   c: appTActionCallback;

begin
   if(callback <> nil) then begin
      c.Action := action;
      c.Callback := nil;
      c.ObjectCallback := callback;

      Callbacks.Add(c);
   end;
end;

function appTActionEvents.SetCallback(callback: TProcedure): TEventID;
var
   action: TEventID;

begin
   action := GetID();
   SetCallback(action, callback);

   Result := action;
end;

function appTActionEvents.SetCallback(callback: TObjectProcedure): TEventID;
var
   action: TEventID;

begin
   action := GetID();
   SetCallback(action, callback);

   Result := action;
end;

function appTActionEvents.FindCallback(action: TEventID): appPActionCallback;
var
   i: loopint;

begin
   for i := 0 to Callbacks.n - 1 do begin
      if(Callbacks.List[i].Action = action) then
         exit(@Callbacks.List[i]);
   end;

   Result := nil;
end;

function appTActionEvents.ReplaceCallback(action: TEventID; callback: TProcedure): boolean;
var
   pCallback: appPActionCallback;

begin
   pCallback := FindCallback(action);
   if(pCallback <> nil) then begin
      pCallback^.Callback := callback;
      exit(true);
   end;

   Result := false;
end;

procedure appTActionEvents.QueueQuitEvent();
begin
   Queue(appACTION_QUIT);
end;

class procedure appTActionEvents.Initialize(out events: appTActionEvents);
begin
   ZeroOut(events, SizeOf(events));
   appTActionCallbacks.Initialize(events.Callbacks);
end;

{this routine calls the respective handlers for an action}
procedure actionAction(var event: appTEvent);
var
   cur: appPActionHandler;
   i: longint;

begin
   if(event.evID <> 0) then begin
      {if it's an action we can handle}
      if(event.evID = appACTION_QUIT) then
         app.Active := false
      else begin
         {find in callbacks first}
         if(appActionEvents.Callbacks.n > 0) then
            for i := 0 to (appActionEvents.Callbacks.n - 1) do begin
              if(appActionEvents.Callbacks.List[i].Action = event.evID) then begin
                 appActionEvents.Callbacks.List[i].Call();
                 exit;
              end;
            end;

         {go through handlers}
         cur := first;

         if(cur <> nil) then repeat
            if(cur^.call <> nil) and (cur^.call(event)) then
               break;

            cur := cur^.next;
         until (cur = nil);
      end;
   end;
end;

procedure quitApp();
begin
   app.active := false;
end;

INITIALIZATION
   appTActionEvents.Initialize(appActionEvents);

   evhpACTION_EVENTS := appEvents.AddHandler(appActionEvents.evh, 'action', @actionAction);

   appACTION_QUIT := appActionEvents.SetCallback(@quitApp);
END.
