{
   oxuRun, runs the oX framework
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuRun;

INTERFACE

   USES
      uStd, uLog, sysutils, uTiming,
      {app}
      uApp, appuEvents, appuActionEvents,
      {oX}
      uOX, oxuInitialize, oxuWindows, oxuPlatform, oxuRunRoutines, oxuWindowRender, oxuProgramInitTask,
      oxuTimer;

TYPE
   { oxTRunGlobal }

   oxTRunGlobal = record
     {restart instead of quitting}
     RestartFlag: boolean;

     {perform initialization before running}
     function Initialize(): boolean;
     {start running}
     procedure Start();
     {done running}
     procedure Done();
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
   oxInitialization.Initialize();

   Result := ox.Error = 0;

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

procedure oxTRunGlobal.Done();
begin
   log.i('oX > Finished running the program...');
   ox.Started := false;
   log.Leave();
end;

procedure oxTRunGlobal.Go();
var
   initialized: boolean;

begin
   repeat
      initialized := Initialize();

      if(initialized) then begin
         app.Active := true;
         log.v('Active');

         {main loop}
         repeat
            if(ox.Initialized) then begin
               if(oxProgramInitTask.Task = nil) then
                  oxProgramInitTask.Go();
            end;

            if(ox.Initialized and oxProgramInitTask.Initialized) then begin
               if(not ox.Started) then
                  Start();
            end;

            GoCycle(true);
         until (not app.Active); {repeat until the application is no longer active}

         Done();
      end else
         log.v('Failed to initialize');

      oxInitialization.DeInitialize();
      {handle restart (if any) only if ran successfully}
   until (not initialized) or (not HandleRestart());
end;

procedure oxTRunGlobal.GoCycle(dosleep: boolean);
begin
   ox.OnPreEvents.Call();

   oxPlatform.ProcessEvents();
   ControlEvents();

   ox.OnRun.Call();

   {render stuff}
   {$IFNDEF OX_LIBRARY}
   if(IsReady()) then
      oxWindowRender.All();
   {$ENDIF}

   ox.OnRunAfter.Call();

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
   Result := ox.Initialized and oxProgramInitTask.Initialized;
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
