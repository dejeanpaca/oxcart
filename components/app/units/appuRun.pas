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
   appTRunRoutine = record
      Name: string;
      Exec: TProcedure;
      Next: pointer;
   end;

   { appTRunGlobal }

   appTRunGlobal = record
      PreRunRoutines,
      RunRoutines: record
         s,
         e: appPRunRoutine;
      end;

      {main app control routine}
      procedure Control();

      {app cycle}
      function Cycle(dosleep: boolean): boolean;
      procedure Sleep(time: longint = -1);

      {runs the application}
      procedure Run();

      {adds a run routine to the execution list}
      function FindRoutine(var routine: appTRunRoutine): Boolean;
      procedure AddRoutine(var routine: appTRunRoutine);
      procedure AddRoutine(out routine: appTRunRoutine; const name: string; exec: TProcedure);
   end;

VAR
   appRun: appTRunGlobal;

IMPLEMENTATION

{main app control routine}
procedure appTRunGlobal.Control();
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

{Application Run}
function appTRunGlobal.Cycle(dosleep: boolean): boolean;
var
   curRoutine: appPRunRoutine;

begin
   Result := true;

   {call all pre-run routines}
   curRoutine := PreRunRoutines.s;
   if(curRoutine <> nil) then repeat
      if(curRoutine^.Exec <> nil) then
         curRoutine^.Exec();

      curRoutine := curRoutine^.Next;
   until (curRoutine = nil);

   {call all run routines}
   curRoutine := RunRoutines.s;
   if(curRoutine <> nil) then repeat
      if(curRoutine^.Exec <> nil) then
         curRoutine^.Exec();

      curRoutine := curRoutine^.Next;
   until (curRoutine = nil);

   if(dosleep) then
      Sleep();
end;

procedure appTRunGlobal.Sleep(time: longint);
begin
   if(time = -1) then
      time := app.IdleTime;

   if(time > 0) then
      SysUtils.Sleep(time);
end;

procedure appTRunGlobal.Run();
begin
   app.Active := true;

   {main loop}
   repeat
      if(not Cycle(true)) then
         break;
   until (not app.Active); {repeat until the application is no longer active}
end;

function appTRunGlobal.FindRoutine(var routine: appTRunRoutine): Boolean;
var
   cur: appPRunRoutine;

begin
   cur := RunRoutines.s;
   if(cur <> nil) then begin
      repeat
         if(cur = @routine) then
            exit(true);

         cur := cur^.Next;
      until (cur = nil);
   end;

   Result := false;
end;

procedure appTRunGlobal.AddRoutine(var routine: appTRunRoutine);
begin
   {do not add same routine multiple times}
   if(FindRoutine(routine)) then
      exit;

   routine.Next := nil;

   if(RunRoutines.s = nil) then
      RunRoutines.s := @routine
   else
      RunRoutines.e^.Next := @routine;

   RunRoutines.e := @routine;
end;

procedure appTRunGlobal.AddRoutine(out routine: appTRunRoutine; const name: string; exec: TProcedure);
begin
   ZeroPtr(@routine, SizeOf(routine));
   routine.Name := name;
   routine.Exec := exec;

   AddRoutine(routine);
end;

END.
