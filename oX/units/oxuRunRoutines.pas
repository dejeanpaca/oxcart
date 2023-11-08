{
   oxuRunRoutines, run routines
   Copyright (C) 2008. Dejan Boras

   Started On:    19.09.2008.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT oxuRunRoutines;

INTERFACE

   USES
      uStd,
      appuEvents;

TYPE
   oxPRunRoutine = ^ oxTRunRoutine;

   { oxTRunRoutine }

   oxTRunRoutine = record
      Name: string;
      Exec: TProcedure;
      Next: pointer;
   end;

   { oxTRunRoutines }

   oxTRunRoutines = record
      s,
      e:  oxPRunRoutine;

      procedure Call();
      function Find(const routine: oxTRunRoutine): boolean;
      procedure Add(var routine: oxTRunRoutine);
      procedure Add(out routine: oxTRunRoutine; const name: string; exec: TProcedure);
   end;

   { oxTRunRoutinesGlobal }

   oxTRunRoutinesGlobal = record
      {main ox control routine}
      procedure ControlEvents();
   end;

VAR
   oxRunRoutines: oxTRunRoutinesGlobal;

IMPLEMENTATION

{ oxTRunRoutines }

procedure oxTRunRoutines.Call();
var
   current: oxPRunRoutine;

begin
   {call all pre-run routines}
   current := s;

   if(current <> nil) then repeat
      if(current^.Exec <> nil) then
         current^.Exec();

      current := current^.Next;
   until (current = nil);
end;

function oxTRunRoutines.Find(const routine: oxTRunRoutine): boolean;
var
   cur: oxPRunRoutine;

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

procedure oxTRunRoutines.Add(var routine: oxTRunRoutine);
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

procedure oxTRunRoutines.Add(out routine: oxTRunRoutine; const name: string; exec: TProcedure);
begin
   ZeroPtr(@routine, SizeOf(routine));
   routine.Name := name;
   routine.Exec := exec;

   Add(routine);
end;

{main ox control routine}
procedure oxTRunRoutinesGlobal.ControlEvents();
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

END.
