{
   oxuRunRoutines, run routines
   Copyright (C) 2008. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuRunRoutines;

INTERFACE

   USES
      sysutils, uStd, uTiming, StringUtils, uLog;

CONST
   oxcRunRoutineVerbose: boolean = false;

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
      PoolName: string;
      s,
      e:  oxPRunRoutine;
      UnusualTime: single;

      class procedure Initialize(out r: oxTRunRoutines; const usePoolName: string = ''); static;

      function GetName(const methodName: string): string;

      procedure Call();
      procedure iCall();
      procedure dCall();
      class procedure CallNextReverse(current: oxPRunRoutine); static;
      procedure Call(start: oxPRunRoutine; primary: boolean);
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

class procedure oxTRunRoutines.Initialize(out r: oxTRunRoutines; const usePoolName: string);
begin
   ZeroPtr(@r, SizeOf(r));
   r.UnusualTime := 0.5;
   r.PoolName := usePoolName;
end;

function oxTRunRoutines.GetName(const methodName: string): string;
begin
   if(PoolName <> '') then
      Result := '[' + PoolName + ', ' + methodName + ']'
   else
      Result := '[' + methodName + ']';
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

procedure oxTRunRoutines.Call(start: oxPRunRoutine; primary: boolean);
var
   current: oxPRunRoutine;
   elapsed: single;
   time: TDateTime;

begin
   {call all pre-run routines}
   current := start;

   if(current <> nil) then repeat
      time := Now();

      if oxcRunRoutineVerbose then
         log.v('Calling ' + GetName(current^.name));

      if(primary) then begin
         if(current^.Exec <> nil) then
            current^.Exec();
      end else begin
        if(current^.Secondary <> nil) then
           current^.Secondary();
      end;

      elapsed := time.Elapsedf();

      if oxcRunRoutineVerbose then
         log.v('Called ' + GetName(current^.name) + ', elapsed: ' + sf(elapsed, 5));

      if(elapsed > UnusualTime) then
         log.d('Initialization method (' + PoolName + ', ' + current^.Name + ' ) took unusual time: ' + sf(elapsed, 5));

      current := current^.Next;
   until (current = nil);
end;

procedure oxTRunRoutines.CallPrimary();
begin
   call(s, true);
end;

procedure oxTRunRoutines.CallSecondary();
begin
   call(s, false)
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
