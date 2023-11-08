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
      uOX, oxuInit, oxuWindows, oxuPlatform, oxuRunRoutines, oxuWindowRender,
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

   ox.OnInitialize.iCall();

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
         Start();

         app.Active := true;

         {main loop}
         repeat
            GoCycle(true);
         until (not app.Active); {repeat until the application is no longer active}

         Done();
      end;

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
