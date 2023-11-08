{
   oxuRunRoutines, run routines
   Copyright (C) 2008. Dejan Boras

   Started On:    19.09.2008.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}
UNIT oxuRunRoutines;

INTERFACE

   USES
      uStd;

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

END.
