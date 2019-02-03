{
   oxuRun, runs the oX framework
   Copyright (c) 2011. Dejan Boras

   Started On:    09.02.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuRun;

INTERFACE

   USES
      uStd, uLog, sysutils, uTiming,
      {app}
      uApp, appuRun, appuActionEvents,
      {oX}
      uOX, oxuInit, oxuWindows, oxuPlatform;

TYPE

   { oxTRunGlobal }

   oxTRunGlobal = record
     {restart instead of quitting}
     RestartFlag: boolean;
     {Routine called when a cycle is performed (take care if you override this)}
     CycleRoutine: appTRunRoutine;

     {perform initialization before running}
     function Initialize(): boolean;
     {start running}
     procedure Start();
     {done running}
     procedure Done();
     {run the engine}
     procedure Go();
     {run a single cycle}
     procedure GoCycle();
     {run a restart}
     procedure Restart();
     {handle a restart}
     function HandleRestart(): boolean;
   end;

VAR
   oxRun: oxTRunGlobal;

{default cycle routine}
procedure oxCycle();

IMPLEMENTATION

VAR
   old: TBoolFunction = nil;
   ProgramInitStartTime: TDateTime;

procedure oxCycle();
begin
   if(old <> nil) then
      old();

   oxPlatform.ProcessEvents();

   appRun.Control();

   ox.OnRun.Call();

   {render stuff}
   {$IFNDEF OX_LIBRARY}
   oxWindows.Render();
   {$ENDIF}

   ox.OnRunAfter.Call();
end;

function Init(): boolean;
begin
   result := false;

   oxInitialization.Initialize();
   if(ox.Error <> 0) then
      exit;

   ProgramInitStartTime := Time();

   log.Enter('oX > Initializing the program...');

   ox.OnInitialize.Call();

   log.i('Program initialization done. Elapsed time: ' + ProgramInitStartTime.ElapsedfToString() + 's');
   log.Leave();

   log.i('Total startup time: ' + GlobalStartTime.ElapsedfToString() + 's');

   if(ox.Error = 0) then
      Result := true;
end;

function oxTRunGlobal.Initialize(): boolean;
begin
   result := Init();

   log.Flush();
end;

procedure oxTRunGlobal.Start();
var
   startTime: TDateTime;

begin
   startTime := Time();
   log.Enter('oX > Loading...');
   ox.OnLoad.Call();
   log.i('Loaded (Elapsed: ' + startTime.ElapsedfToString() + 's)');
   log.Leave();

   log.Enter('oX > Running...');

   appRun.AddRoutine(CycleRoutine);

   ox.Started := true;
   ox.OnStart.Call();
end;

procedure oxTRunGlobal.Done();
begin
   log.i('oX > Finished running the program...');
   log.Leave();
end;

procedure oxTRunGlobal.Go();
var
   initialized: boolean;

begin
   repeat
      initialized := Initialize();
      if(initialized) then begin
         Start();

         {run here...}
         appRun.Run();

         Done();
      end;

      oxInitialization.DeInitialize();
      {handle restart (if any) only if ran successfully}
   until (not initialized) or (not HandleRestart());
end;

procedure oxTRunGlobal.GoCycle();
begin
   appRun.Cycle(true);
end;

procedure oxTRunGlobal.Restart();
begin
   RestartFlag := true;
   appActionEvents.QueueQuitEvent();
end;

function oxTRunGlobal.HandleRestart(): boolean;
begin
   Result := RestartFlag;

   if(RestartFlag) then begin
      RestartFlag := false;
      app.Active := true;
   end;
end;

INITIALIZATION
   oxRun.CycleRoutine.Name := 'ox.cycle';
   oxRun.CycleRoutine.Exec := @oxCycle;
   oxRun.CycleRoutine.Next := nil;

END.
