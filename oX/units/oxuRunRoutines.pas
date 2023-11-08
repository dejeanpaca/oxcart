{
   oxuRunRoutines, run routines
   Copyright (C) 2008. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuRunRoutines;

INTERFACE

   USES
      uStd;

TYPE
   oxPRunRoutine = ^ oxTRunRoutine;
   oxPRunRoutines = ^oxTRunRoutines;

   { oxTRunRoutine }

   oxTRunRoutine = record
      Name: string;
      Exec,
      Secondary: TProcedure;
      Next: pointer;
   end;

   oxTRunRoutinePool = record
      Count: loopint;
      All: array[0..2047] of oxTRunRoutine;
   end;

   { oxTRunRoutines }

   oxTRunRoutines = record
      s,
      e:  oxPRunRoutine;

      class procedure Initialize(out r: oxTRunRoutines); static;

      procedure Call();
      procedure iCall();
      procedure dCall();
      class procedure CallNextReverse(current: oxPRunRoutine); static;
      procedure CallPrimary();
      procedure CallSecondary();
      function Find(const routine: oxTRunRoutine): boolean;
      function Find(const exec: TProcedure): oxPRunRoutine;
      procedure Add(var routine: oxTRunRoutine);
      procedure Add(out routine: oxTRunRoutine; exec: TProcedure);
      procedure dAdd(out routine: oxTRunRoutine; const name: string; exec: TProcedure);
      procedure Add(out routine: oxTRunRoutine; const name: string; exec: TProcedure);
      procedure Add(out routine: oxTRunRoutine; const name: string; init, deinit: TProcedure);

      function GetFromPool(): oxPRunRoutine;

      procedure dAdd(const name: string; exec: TProcedure);
      procedure Add(const name: string; exec: TProcedure);
      procedure Add(const name: string; init, deinit: TProcedure);
   end;

IMPLEMENTATION

VAR
   pool: oxTRunRoutinePool;

{ oxTRunRoutines }

class procedure oxTRunRoutines.Initialize(out r: oxTRunRoutines);
begin
   ZeroPtr(@r, SizeOf(r));
end;

procedure oxTRunRoutines.Call();
begin
   CallPrimary();
end;

procedure oxTRunRoutines.iCall();
begin
   CallPrimary();
end;

procedure oxTRunRoutines.dCall();
var
   current: oxPRunRoutine;

begin
   {call all pre-run routines}
   current := s;

   if(current <> nil) then begin
      if(current^.Next <> nil) then
         CallNextReverse(oxPRunRoutine(current^.Next));

      if(current^.Secondary <> nil) then
         current^.Secondary();
   end;
end;

class procedure oxTRunRoutines.CallNextReverse(current: oxPRunRoutine);
begin
   if(current^.Next <> nil) then
      CallNextReverse(current^.Next);

   if(current^.Secondary <> nil) then
      current^.Secondary();
end;

procedure oxTRunRoutines.CallPrimary();
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

procedure oxTRunRoutines.CallSecondary();
var
   current: oxPRunRoutine;

begin
   {call all pre-run routines}
   current := s;

   if(current <> nil) then repeat
      if(current^.Secondary <> nil) then
         current^.Secondary();

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

function oxTRunRoutines.Find(const exec: TProcedure): oxPRunRoutine;
var
   cur: oxPRunRoutine;

begin
   cur := s;

   if(cur <> nil) then begin
      repeat
         if(cur^.Exec = exec) then
            exit(cur);

         cur := cur^.Next;
      until (cur = nil);
   end;

   Result := nil;
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

procedure oxTRunRoutines.Add(out routine: oxTRunRoutine; exec: TProcedure);
begin
   Add(routine, '', exec);
end;

procedure oxTRunRoutines.dAdd(out routine: oxTRunRoutine; const name: string; exec: TProcedure);
begin
   Add(routine, name, nil, exec);
end;

procedure oxTRunRoutines.Add(out routine: oxTRunRoutine; const name: string; exec: TProcedure);
begin
   ZeroPtr(@routine, SizeOf(routine));
   routine.Name := name;
   routine.Exec := exec;

   Add(routine);
end;

procedure oxTRunRoutines.Add(out routine: oxTRunRoutine; const name: string; init, deinit: TProcedure);
begin
   Add(routine, name, init);
   routine.Secondary := deinit;
end;

function oxTRunRoutines.GetFromPool(): oxPRunRoutine;
begin
   Result := @pool.All[pool.Count];
   ZeroPtr(Result, SizeOf(oxTRunRoutine));
   inc(pool.Count);
end;

procedure oxTRunRoutines.dAdd(const name: string; exec: TProcedure);
var
   r: oxPRunRoutine;

begin
   r := GetFromPool();

   r^.Name := name;
   r^.Secondary := exec;

   Add(r^);
end;

procedure oxTRunRoutines.Add(const name: string; exec: TProcedure);
var
   r: oxPRunRoutine;

begin
   r := GetFromPool();

   r^.Name := name;
   r^.Exec := exec;

   Add(r^);
end;

procedure oxTRunRoutines.Add(const name: string; init, deinit: TProcedure);
var
   r: oxPRunRoutine;

begin
   r := GetFromPool();

   r^.Name := name;
   r^.Exec := init;
   r^.Secondary := deinit;

   Add(r^);
end;

END.
