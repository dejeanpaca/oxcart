{
   oxeduProjectRunner, handles running the project
   Copyright (C) 2017. Dejan Boras

   Started On:    04.06.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduProjectRunner;

INTERFACE

   USES
      sysutils, uStd, appuRun, uTiming, uLog,
      {app}
      appuActionEvents,
      {ox}
      oxuRun, oxuWindows, oxuThreadTask,
      {oxed}
      oxeduProject, oxeduMessages, oxeduLib, oxeduActions, oxeduBuild, oxeduSettings;

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
   start: TDateTime;
   initialized: Boolean;

   procedure runInitialize();
   begin
      initialized := oxedLib.oxLib.Initialize();

      if(not initialized) then
         oxedMessages.e('Library engine failed to initialize');
   end;

   procedure runStart();
   begin
      initialized := oxedLib.oxLib.Start();

      if(not initialized) then
         oxedMessages.e('Library project failed to initialize');

   end;

begin
   if(not oxedProjectValid()) or (not CanRun()) then
      exit;

   oxedProjectRunner.RunAfterBuild := false;

   {if we need to do an initial build, then do it}
   if(not oxedProject.Session.InitialBuildDone) and (oxedSettings.RequireRebuildOnOpen) then begin
      oxedProjectRunner.RunAfterBuild := true;
      oxedBuild.RebuildTask();
      exit;
   end;

   start := Now();

   if(not oxedLib.Load()) then begin
      oxedMessages.e('Project dynamic library failed to load');
      exit;
   end;

   oxedProjectRunner.OnBeforeStart.Call();

   initialized := false;
   if(oxedSettings.HandleLibraryErrors) then begin
      try
         runInitialize();
      except
         on e: Exception do begin
            oxedMessages.e('Exception while initializing library engine');
            oxedMessages.e(e.ToString());

            initialized := false;
         end;
      end;
   end else
      runInitialize();

   oxedProjectRunner.OnAfterInitialize.Call();

   if(initialized) then begin
      if(oxedSettings.HandleLibraryErrors) then begin
         try
            runStart();
         except
            on e: Exception do begin
               oxedMessages.e('Exception while initializing library project');
               oxedMessages.e(e.ToString());

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

   oxedMessages.i('Start (elapsed: ' + start.ElapsedfToString(2) + 's)');
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

   oxedMessages.i('Stopped (elapsed: ' + start.ElapsedfToString(2) + 's)');
end;

class function oxedTProjectRunner.Loaded(): boolean;
begin
   Result := (oxedLib.oxLib <> nil);
end;

class function oxedTProjectRunner.Valid(): boolean;
begin
   Result := oxedProjectValid() and Loaded() and (not oxedProject.Paused) and (not oxedLib.oxLib.ErrorState);
end;

class function oxedTProjectRunner.CanRender(): boolean;
begin
   Result := oxedTProjectRunner.Valid() and (oxedLib.oxWindows <> nil);
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
   if(oxedTProjectRunner.Valid()) then begin
      try
         oxedLib.oxLib.Run();

         if(not oxedLib.oxLib.IsAppActive()) then
            appActionEvents.Queue(oxedActions.RUN_STOP);
      except
         on e: Exception do begin
            if(oxedSettings.HandleLibraryErrors) then begin
               oxedLib.oxLib.ErrorState := true;

               log.e('Exception while running ox library');
               log.e(DumpExceptionCallStack(e));
            end else
               raise e;
         end;
      end;
   end;
end;

procedure onStart();
begin
   oxedLib.oxWindows := oxTWindows(oxLibReferences.FindInstance('oxTWindows'));
end;

procedure onStop();
begin
   oxedLib.oxWindows := nil;
end;

procedure onBuildDone();
begin
   if(oxedProjectRunner.RunAfterBuild) then
      appActionEvents.Queue(oxedActions.RUN_PLAY);
end;

VAR
   projectRunRoutine: appTRunRoutine;

INITIALIZATION
   oxRun.AddRoutine(projectRunRoutine, 'oxed.project', @projectRun);

   TProcedures.Initialize(oxedProjectRunner.OnAfterInitialize);
   TProcedures.Initialize(oxedProjectRunner.OnStart);
   TProcedures.Initialize(oxedProjectRunner.OnBeforeStart);
   TProcedures.Initialize(oxedProjectRunner.OnPauseToggle);
   TProcedures.Initialize(oxedProjectRunner.OnBeforeStop);
   TProcedures.Initialize(oxedProjectRunner.OnStop);

   oxedActions.RUN_PLAY := appActionEvents.SetCallback(@oxedProjectRunner.Run);
   oxedActions.RUN_PAUSE := appActionEvents.SetCallback(@oxedProjectRunner.Pause);
   oxedActions.RUN_STOP := appActionEvents.SetCallback(@oxedProjectRunner.Stop);

   oxedProjectRunner.OnStart.Add(@onStart);
   oxedProjectRunner.OnStop.Add(@onStop);

   oxedBuild.OnBuildDone.Add(@onBuildDone);

END.
