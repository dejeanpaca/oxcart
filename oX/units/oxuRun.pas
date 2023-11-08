{
   oxuRun, runs the oX framework
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuRun;

INTERFACE

   USES
      uStd, uLog, sysutils, uTiming, StringUtils,
      {app}
      uApp, appuEvents, appuActionEvents,
      {oX}
      uOX,
      oxuInitialize, oxuWindows, oxuPlatform, oxuRunRoutines, oxuWindowRender,
      oxuMainInitTask, oxuProgramInitTask,
      oxuTimer, oxuRenderingContext, oxuRenderer;

TYPE
   { oxTRunGlobal }

   oxTRunGlobal = record
     {restart instead of quitting}
     RestartFlag,
     {debug log enabled}
     LogDebugCycle,
     {is the ox.Initialize() step complete successful}
     PreInitializeSuccess: boolean;

     {perform initialization before running}
     function Initialize(): boolean;
     {start running}
     procedure Start();
     {call any deinitialization tasks and call Done()}
     procedure Teardown();
     {run the engine}
     procedure Go();
     {run a single cycle}
     procedure GoCycle(dosleep: boolean = true);
     {run a restart}
     procedure Restart();
     {handle a restart}
     function HandleRestart(): boolean;

     {control events}
     procedure ControlEvents();

     {are we loaded and ready}
     function IsReady(): boolean;

     {adds a run routine to the execution list}
     procedure AddRoutine(var routine: oxTRunRoutine);
     procedure AddRoutine(out routine: oxTRunRoutine; const name: string; exec: TProcedure);
     procedure AddRoutine(const name: string; exec: TProcedure);
     procedure AddPreRoutine(var routine: oxTRunRoutine);
     procedure AddPreRoutine(out routine: oxTRunRoutine; const name: string; exec: TProcedure);
     procedure AddPreRoutine(const name: string; exec: TProcedure);
   end;

VAR
   oxRun: oxTRunGlobal;

IMPLEMENTATION

function oxTRunGlobal.Initialize(): boolean;
begin
   Result := oxInitialization.Initialize();
   PreInitializeSuccess := Result;

   Result := Result and (ox.Error = 0);
   app.Active := Result;

   log.Flush();
end;

procedure oxTRunGlobal.Start();
var
   startTime: TDateTime;

begin
   startTime := Now();
   log.Enter('oX > Loading...');
   ox.OnLoad.Call();
   log.i('Loaded (Elapsed: ' + startTime.ElapsedfToString() + 's)');
   log.Leave();

   log.Enter('oX > Running...');

   ox.Started := true;

   startTime := Now();
   ox.OnStart.Call();
   log.v('OnStart (Elapsed: ' + startTime.ElapsedfToString() + 's)');
end;

procedure oxTRunGlobal.Teardown();
begin
   oxProgramInitTask.StopWait();
   oxMainInitTask.StopWait();

   if(PreInitializeSuccess) then begin
      log.i('oX > Finished running the program...');
      ox.Started := false;
      log.Leave();
   end;

   PreInitializeSuccess := false;

   oxInitialization.DeInitialize();
   {handle restart (if any) only if ran successfully}
end;

procedure oxTRunGlobal.Go();
var
   initialized: boolean;

begin
   repeat
      initialized := Initialize();

      if(initialized) then begin
         {main loop}
         repeat
            GoCycle(true);
         until (not app.Active); {repeat until the application is no longer active}
      end else
         log.v('Failed to initialize');

      Teardown();
      {handle restart (if any) only if ran successfully}
   until (not initialized) or (not HandleRestart());
end;

procedure oxTRunGlobal.GoCycle(dosleep: boolean);
begin
   {are we waiting for initialization}
   if(ox.Initialized and PreInitializeSuccess) then begin
      if(oxMainInitTask.IsFinished()) then begin
         if(oxProgramInitTask.Task = nil) then
            oxProgramInitTask.Go();
      end;

      if(oxProgramInitTask.IsFinished()) then begin
         if(not ox.Started) then
            Start();
      end;
   end;

   {cycle stuff}
   if(LogDebugCycle) then
      log.d('oxRun > PreEvents');
   ox.OnPreEvents.LogVerbose := LogDebugCycle;
   ox.OnPreEvents.Call();

   if(LogDebugCycle) then
      log.d('oxRun > ProcessEvents');
   oxPlatform.ProcessEvents();

   if(LogDebugCycle) then
      log.d('oxRun > ControlEvents');
   ControlEvents();

   if(LogDebugCycle) then
      log.d('oxRun > OnRun');
   ox.OnRun.LogVerbose := LogDebugCycle;
   ox.OnRun.Call();

   {render stuff}
   {$IFNDEF OX_LIBRARY}
   if(IsReady()) then begin
      if(LogDebugCycle) then
         log.d('oxRun > Render');

      oxWindowRender.All();
   end;
   {$ENDIF}

   {after}
   if(LogDebugCycle) then
      log.d('oxRun > OnAfter');

   ox.OnRunAfter.LogVerbose := LogDebugCycle;
   ox.OnRunAfter.Call();

   if(LogDebugCycle) then
      log.d('oxRun > Sleep');

   {give the system a break}
   if(dosleep) then
      oxTimer.Sleep();
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

{main ox control routine}
procedure oxTRunGlobal.ControlEvents();
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

function oxTRunGlobal.IsReady(): boolean;
begin
   Result := ox.Initialized and oxProgramInitTask.Initialized and ox.Started;
end;

procedure oxTRunGlobal.AddRoutine(var routine: oxTRunRoutine);
begin
   ox.OnRun.Add(routine);
end;

procedure oxTRunGlobal.AddRoutine(out routine: oxTRunRoutine; const name: string; exec: TProcedure);
begin
   ox.OnRun.Add(routine, name, exec);
end;

procedure oxTRunGlobal.AddRoutine(const name: string; exec: TProcedure);
begin
   ox.OnRun.Add(name, exec);
end;

procedure oxTRunGlobal.AddPreRoutine(var routine: oxTRunRoutine);
begin
   ox.OnPreEvents.Add(routine);
end;

procedure oxTRunGlobal.AddPreRoutine(out routine: oxTRunRoutine; const name: string; exec: TProcedure);
begin
   ox.OnPreEvents.Add(routine, name, exec);
end;

procedure oxTRunGlobal.AddPreRoutine(const name: string; exec: TProcedure);
begin
   ox.OnPreEvents.Add(name, exec);
end;

END.
