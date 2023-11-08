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

     PreRunRoutines,
     RunRoutines: appTRunRoutines;

     {perform initialization before running}
     function Initialize(): boolean;
     {start running}
     procedure Start();
     {done running}
     procedure Done();
     {run the engine}
     procedure Go();
     {run a single cycle}
     function GoCycle(dosleep: boolean = true): boolean;
     {app cycle}
     procedure Sleep(time: longint = -1);
     {run a restart}
     procedure Restart();
     {handle a restart}
     function HandleRestart(): boolean;

     {adds a run routine to the execution list}
     procedure AddRoutine(var routine: appTRunRoutine);
     procedure AddRoutine(out routine: appTRunRoutine; const name: string; exec: TProcedure);
     procedure AddPreRoutine(var routine: appTRunRoutine);
     procedure AddPreRoutine(out routine: appTRunRoutine; const name: string; exec: TProcedure);
   end;

VAR
   oxRun: oxTRunGlobal;

IMPLEMENTATION

VAR
   ProgramInitStartTime: TDateTime;


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

         app.Active := true;

         {main loop}
         repeat
            if(not GoCycle(true)) then
               break;
         until (not app.Active); {repeat until the application is no longer active}

         Done();
      end;

      oxInitialization.DeInitialize();
      {handle restart (if any) only if ran successfully}
   until (not initialized) or (not HandleRestart());
end;

function oxTRunGlobal.GoCycle(dosleep: boolean): boolean;
begin
   Result := true;

   PreRunRoutines.Call();

   oxPlatform.ProcessEvents();
   RunRoutines.Call();

   appRun.ControlEvents();

   ox.OnRun.Call();

   {render stuff}
   {$IFNDEF OX_LIBRARY}
   oxWindows.Render();
   {$ENDIF}

   ox.OnRunAfter.Call();

   if(dosleep) then
      Sleep();
end;

procedure oxTRunGlobal.Sleep(time: longint);
begin
   if(time = -1) then
      time := app.IdleTime;

   if(time > 0) then
      SysUtils.Sleep(time);
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

procedure oxTRunGlobal.AddRoutine(var routine: appTRunRoutine);
begin
   RunRoutines.Add(routine);
end;

procedure oxTRunGlobal.AddRoutine(out routine: appTRunRoutine; const name: string; exec: TProcedure);
begin
   RunRoutines.Add(routine, name, exec);
end;

procedure oxTRunGlobal.AddPreRoutine(var routine: appTRunRoutine);
begin
   PreRunRoutines.Add(routine);
end;

procedure oxTRunGlobal.AddPreRoutine(out routine: appTRunRoutine; const name: string; exec: TProcedure);
begin
   PreRunRoutines.Add(routine, name, exec);
end;

END.
