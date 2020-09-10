{
   oxeduProjectRunner, handles running the project
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduProjectRunner;

INTERFACE

   USES
      sysutils, uStd, uError, uTiming, uLog,
      {app}
      appuActionEvents,
      {ox}
      oxuRun, oxuRunRoutines, oxuWindows, oxuThreadTask,
      {oxed}
      oxeduProject, oxeduConsole, oxeduLib, oxeduActions, oxeduBuild, oxeduSettings;

TYPE
   { oxedTProjectRunner }

   oxedTProjectRunner = record
      {called after initialization is done}
      OnAfterInitialize,
      {called when the project is started}
      OnStart,
      {called before the project is started}
      OnBeforeStart,
      {called when the project pause state is toggled}
      OnPauseToggle,
      {called before the project is to be stopped}
      OnBeforeStop,
      {called when the project is stopped}
      OnStop: TProcedures;

      {if set to true, it'll run the project after the build is done}
      RunAfterBuild: boolean;

      class procedure Run(); static;
      class procedure Pause(); static;
      class procedure Stop(); static;

      class function Loaded(): boolean; static;
      class function Valid(): boolean; static;
      class function CanRender(): boolean; static;
      class function CanRun(): boolean; static;

      class function IsRunning(): boolean; static;
   end;

VAR
   oxedProjectRunner: oxedTProjectRunner;

IMPLEMENTATION

{ oxedTProjectRunner }

class procedure oxedTProjectRunner.Run();
var
   start,
   timing: TDateTime;
   initialized: Boolean;

   procedure runInitialize();
   begin
      initialized := oxedLib.oxLib.Initialize();

      if(not initialized) then
         oxedConsole.e('Library engine failed to initialize');
   end;

   procedure runStart();
   begin
      timing := Now();

      initialized := oxedLib.oxLib.Start();

      if(not initialized) then
         oxedConsole.e('Library project failed to initialize');

      log.v('runStart() elapsed: ' + timing.ElapsedfToString(3) + 's');
   end;

begin
   if(not oxedProjectValid()) or (not CanRun()) then
      exit;

   oxedProjectRunner.RunAfterBuild := false;

   {if we need to do an initial build, then do it}
   if(not oxedProject.Session.InitialBuildDone) and (oxedSettings.RequireRebuildOnOpen) then begin
      oxedProjectRunner.RunAfterBuild := true;
      appActionEvents.Queue(oxedActions.REBUILD);
      exit;
   end;

   start := Now();

   if(not oxedLib.Load()) then begin
      oxedConsole.e('Project dynamic library failed to load');
      exit;
   end;

   timing := Now();
   oxedProjectRunner.OnBeforeStart.Call();
   log.v('OnBeforeStart() elapsed: ' + timing.ElapsedfToString(3) + 's');

   initialized := false;
   if(oxedSettings.HandleLibraryErrors) then begin
      try
         runInitialize();
      except
         on e: Exception do begin
            oxedConsole.e('Exception while initializing library engine');
            oxedConsole.e(DumpExceptionCallStack(e));

            initialized := false;
         end;
      end;
   end else
      runInitialize();

   timing := Now();
   oxedProjectRunner.OnAfterInitialize.Call();
   log.v('OnAfterInitialize() elapsed: ' + timing.ElapsedfToString(3) + 's');

   if(initialized) then begin
      if(oxedSettings.HandleLibraryErrors) then begin
         try
            runStart();
         except
            on e: Exception do begin
               oxedConsole.e('Exception while initializing library project');
               oxedConsole.e(DumpExceptionCallStack(e));

               initialized := false;
            end;
         end;
      end else
         runStart();
   end;

   if(not initialized) then begin
      oxedProject.Running := true;
      Stop();
      exit;
   end;

   oxedConsole.i('Start (elapsed: ' + start.ElapsedfToString(2) + 's)');
   oxedProject.Running := true;

   oxedProjectRunner.OnStart.Call();
end;

class procedure oxedTProjectRunner.Pause();
begin
   if(oxedProjectValid()) then begin
      oxedProject.Paused := not oxedProject.Paused;
      oxedProjectRunner.OnPauseToggle.Call();
   end;
end;

class procedure oxedTProjectRunner.Stop();
var
   start: TDateTime;

begin
   if(not Loaded()) or (not oxedProject.Running) then
      exit;

   start := Now();

   oxedProjectRunner.OnBeforeStop.Call();

   oxedLib.Unload();

   oxedProject.Running := false;
   oxedProject.Paused := false;

   oxedProjectRunner.OnPauseToggle.Call();
   oxedProjectRunner.OnStop.Call();

   oxedConsole.i('Stopped (elapsed: ' + start.ElapsedfToString(2) + 's)');
end;

class function oxedTProjectRunner.Loaded(): boolean;
begin
   Result := (oxedLib.oxLib <> nil);
end;

class function oxedTProjectRunner.Valid(): boolean;
begin
   Result := oxedProjectValid() and Loaded() and (not oxedLib.oxLib.ErrorState);
end;

class function oxedTProjectRunner.CanRender(): boolean;
begin
   Result := oxedTProjectRunner.Valid() and (oxedLib.oxWindowRender <> nil) and (oxedLib.oxWindows <> nil);
end;

class function oxedTProjectRunner.CanRun(): boolean;
begin
   Result := oxedBuild.Buildable() and (not Loaded()) and (not IsRunning());
end;

class function oxedTProjectRunner.IsRunning(): boolean;
begin
   Result := oxedProjectValid() and Valid() and oxedProject.Running;
end;

procedure projectRun();
begin
   if oxedTProjectRunner.Valid() and (not oxedProject.Paused) then begin
      try
         oxedLib.oxLib.Run();

         if(not oxedLib.oxLib.IsAppActive()) then
            appActionEvents.Queue(oxedActions.RUN_STOP);
      except
         on e: Exception do begin
            if(oxedSettings.HandleLibraryErrors) then begin
               oxedLib.oxLib.ErrorState := true;

               oxedConsole.e('Exception while running ox library');
               oxedConsole.e(DumpExceptionCallStack(e));
            end else
               raise e;
         end;
      end;
   end;
end;

procedure onStart();
begin
   oxedLib.oxWindowRender := oxLibReferences^.FindInstancePtr('oxTWindowRender');
   oxedLib.oxWindows := oxLibReferences^.FindInstancePtr('oxTWindows');
end;

procedure onStop();
begin
   oxedLib.oxWindowRender := nil;
   oxedLib.oxWindows := nil;
end;

procedure onBuildDone();
begin
   if(oxedProjectRunner.RunAfterBuild) then
      appActionEvents.Queue(oxedActions.RUN_PLAY);
end;

INITIALIZATION
   oxRun.AddRoutine('oxed.project', @projectRun);

   TProcedures.InitializeValues(oxedProjectRunner.OnAfterInitialize);
   TProcedures.InitializeValues(oxedProjectRunner.OnStart);
   TProcedures.InitializeValues(oxedProjectRunner.OnBeforeStart);
   TProcedures.InitializeValues(oxedProjectRunner.OnPauseToggle);
   TProcedures.InitializeValues(oxedProjectRunner.OnBeforeStop);
   TProcedures.InitializeValues(oxedProjectRunner.OnStop);

   oxedActions.RUN_PLAY := appActionEvents.SetCallback(@oxedProjectRunner.Run);
   oxedActions.RUN_PAUSE := appActionEvents.SetCallback(@oxedProjectRunner.Pause);
   oxedActions.RUN_STOP := appActionEvents.SetCallback(@oxedProjectRunner.Stop);

   oxedProjectRunner.OnStart.Add(@onStart);
   oxedProjectRunner.OnStop.Add(@onStop);

   oxedBuild.OnDone.Add(@onBuildDone);

END.
