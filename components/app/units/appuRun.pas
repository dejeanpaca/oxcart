{
   appuRun, application running
   Copyright (C) 2008. Dejan Boras

   Started On:    19.09.2008.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT appuRun;

INTERFACE

   USES
      sysutils, uStd,
      uApp, appuEvents;

TYPE
   appPRunRoutine = ^appTRunRoutine;

   { appTRunRoutine }

   appTRunRoutine = record
      Name: string;
      Exec: TProcedure;
      Next: pointer;
   end;

   { appTRunRoutines }

   appTRunRoutines = record
      s,
      e: appPRunRoutine;

      procedure Call();
      function Find(const routine: appTRunRoutine): boolean;
      procedure Add(var routine: appTRunRoutine);
      procedure Add(out routine: appTRunRoutine; const name: string; exec: TProcedure);
   end;

   { appTRunGlobal }

   appTRunGlobal = record
      PreRunRoutines,
      RunRoutines: appTRunRoutines;

      {main app control routine}
      procedure ControlEvents();

      {adds a run routine to the execution list}
      procedure AddRoutine(var routine: appTRunRoutine);
      procedure AddRoutine(out routine: appTRunRoutine; const name: string; exec: TProcedure);
      procedure AddPreRoutine(var routine: appTRunRoutine);
      procedure AddPreRoutine(out routine: appTRunRoutine; const name: string; exec: TProcedure);
   end;

VAR
   appRun: appTRunGlobal;

IMPLEMENTATION

{ appTRunRoutines }

procedure appTRunRoutines.Call();
var
   current: appPRunRoutine;

begin
   {call all pre-run routines}
   current := s;

   if(current <> nil) then repeat
      if(current^.Exec <> nil) then
         current^.Exec();

      current := current^.Next;
   until (current = nil);
end;

function appTRunRoutines.Find(const routine: appTRunRoutine): boolean;
var
   cur: appPRunRoutine;

begin
   cur := s;

   if(cur <> nil) then begin
      repeat
         if(cur = @routine) then
            exit(true);

         cur := cur^.Next;
      until (cur = nil);
   end;

   Result := false;
end;

procedure appTRunRoutines.Add(var routine: appTRunRoutine);
begin
   {do not add same routine multiple times}
   if(Find(routine)) then
      exit;

   routine.Next := nil;

   if(s = nil) then
      s := @routine
   else
      e^.Next := @routine;

   e := @routine;
end;

procedure appTRunRoutines.Add(out routine: appTRunRoutine; const name: string; exec: TProcedure);
begin
   ZeroPtr(@routine, SizeOf(routine));
   routine.Name := name;
   routine.Exec := exec;

   Add(routine);
end;

{main app control routine}
procedure appTRunGlobal.ControlEvents();
var
   event: appTEvent;
   evh: appPEventHandler;
   result: longint = 0;

begin
   {process all events}
   if(appEvents.n > 0) then repeat
      {get the event and the event handler}
      appEvents.Init(event);
      appEvents.Dequeue(event);

      if(event.hID <> nil) then begin
         evh := event.hID;

         result := 0;
         if(not event.Properties.IsSet(appEVENT_PROP_DISABLED)) then begin
            {if a event handler is set}
            if(evh <> nil) and (result <> -1) then begin
               {action}
               if(evh^.Action <> nil) then
                  evh^.Action(event);
            end;
         end;

         {done with this event}
         event.Dispose();
      end;
   {if uinEvents is 0 then there are no more events}
   until(appEvents.n = 0);
end;

procedure appTRunGlobal.AddRoutine(var routine: appTRunRoutine);
begin
   RunRoutines.Add(routine);
end;

procedure appTRunGlobal.AddRoutine(out routine: appTRunRoutine; const name: string; exec: TProcedure);
begin
   RunRoutines.Add(routine, name, exec);
end;

procedure appTRunGlobal.AddPreRoutine(var routine: appTRunRoutine);
begin
   PreRunRoutines.Add(routine);
end;

procedure appTRunGlobal.AddPreRoutine(out routine: appTRunRoutine; const name: string; exec: TProcedure);
begin
   PreRunRoutines.Add(routine, name, exec);
end;

END.
