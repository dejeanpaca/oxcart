{
   oxuInit, oX de/initialization
   Copyright (c) 2011. Dejan Boras

   Started On:    09.02.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuInit;

INTERFACE

   USES
     sysutils, uStd, uLog, uTiming, ParamUtils,
     {app}
     uAppInfo, uApp, appudvarConfiguration,
     {oX}
     uOX, oxuPlatform, oxuWindows, oxuUIHooks, oxuUI, oxuGlobalInstances, oxuPlatforms,
     oxuRenderer, oxuRenderers
     {$IFNDEF OX_LIBRARY}
     , oxuContextWindow
     {$ENDIF};

TYPE
   oxTInitializationGlobal = record
      ErrorDescription: string;
      Started,
      StartedAppInitialize: boolean;

      private
      function InitializeInternal(): TError;
      function InitializePlatforms(): boolean;

      public
      procedure Initialize();
      procedure Deinitialize();

      procedure LogInformation();
   end;

VAR
   oxInitialization: oxTInitializationGlobal;

IMPLEMENTATION

procedure oxTInitializationGlobal.LogInformation();
var
   s: string;

begin
   log.Enter(oxEngineName + ' (oX) Engine v' + oxsVersion);
      log.i('Copyright (c) Dejan Boras 2007.');
      log.i('All rights reserved.');
   log.Leave();

   log.Enter('Build Information');
      log.i('FreePascal Compiler Version: ' + {$I %FPCVERSION%});
      {$IFDEF ANDROID}s := '(Android)'{$ELSE}s := ''{$ENDIF};
      log.i('Target: ' + {$I %FPCTARGETCPU%} + '-' + {$I %FPCTARGETOS%}+s);
      log.i('Date: ' + {$I %DATE%} + ', Time: ' + {$I %TIME%});
   log.Leave();

   log.Flush();
end;

function oxTInitializationGlobal.InitializePlatforms(): boolean;
begin
   if(oxPlatforms.Initialize()) then
      Result := true
   else begin
      ErrorDescription := 'Failed to initialize platform: ' + oxPlatform.Name;

      Result := false;
   end;
end;

function oxTInitializationGlobal.InitializeInternal(): TError;
var
   elapsedTime: TDateTime;

procedure loge(const s: string);
begin
   log.e(s);
   log.Leave();
end;

begin
   result := eERR;
   GlobalStartTime := Time();

   {initialize app}
   {$IFDEF OX_LIBRARY}
   {in library mode, the pacing is determined by the host}
   app.IdleTime := 0;
   {$ENDIF}

   if(not parameters.Process()) then
      exit(eINVALID_ARG);

   Started := true;

   StartedAppInitialize := true;
   app.Initialize();

   log.i('Initialized application');

   {$IFNDEF OX_LIBRARY}
   log.Enter('Initializing oX engine ...');
   {$ELSE}
   log.Enter('Initializing oX engine library ...');
   {$ENDIF}

   oxGlobalInstances.Initialize();

   { start initializing the engine }

   {$IFNDEF OX_LIBRARY}
   if(not InitializePlatforms()) then
      exit(oxePLATFORM_INITIALIZATION);
   {$ENDIF}

   {call UI initialization procedures}
   oxUIHooks := oxUIHooksInstance.Create();

   {call pre-initialization routines}
   ox.PreInit.iCall();
   if(ox.Error <> 0) then begin
      ErrorDescription := 'Pre-initialization step failed';
      exit(oxeGENERAL);
   end;

   log.i('Called pre-initialization routines');

   {initialize renderers}
   oxRenderers.Initialize();

   { set renderer to be used }
   oxRenderers.SetRenderer();

   assert(oxRenderer <> nil, 'ox renderer is not set during initialization');

   {$IFNDEF OX_LIBRARY}
   {set platform to be used}
   if(not oxPlatforms.SetPlatform()) then
      exit(oxePLATFORM_INITIALIZATION);
   {$ENDIF}

   {initialize UI}
   oxui.BaseInitialize();

   log.i('Pre-initialization done (Elapsed: ' + GlobalStartTime.ElapsedfToString() + 's)');

   elapsedTime := Time();

   {$IFNDEF OX_LIBRARY}
   {determine if context window is required}
   oxContextWindow.Required();

   {create a test window and gather information}
   if(oxContextWindow.Require) then begin
      if(not oxContextWindow.Create()) then begin
         ErrorDescription := 'Failed to create context window';
         exit;
      end;
   end;
   {$ENDIF}

   {create windows}
   if(not oxWindows.Initialize()) then begin
      ErrorDescription := 'Failed to create windows';
      exit;
   end;

   {finish renderer initialization}
   oxRenderers.Use(oxRenderer);

   {$IFNDEF OX_LIBRARY}
   if(oxContextWindow.Require) then begin
      oxContextWindow.Destroy();
      oxWindows.SetCurrent(oxWindows.w[0]);
   end;
   {$ENDIF}

   log.i('Window setup done (Elapsed: ' + elapsedTime.ElapsedfToString() + 's)');

   elapsedTime := Time();

   oxRenderers.StartRoutines.Call();
   oxRenderer.StartRoutines.Call();

   {call base initialization routines}
   ox.BaseInit.iCall();
   if(ox.Error <> 0) then begin
      ErrorDescription := 'Base initialization failed';
      exit(oxeGENERAL);
   end;

   log.i('Base initialization done (Elapsed: ' + elapsedTime.ElapsedfToString() + 's)');

   elapsedTime := Time();

   ox.OnPreInitialize.Call();

   log.i('OnPreInitialize called (Elapsed: ' + elapsedTime.ElapsedfToString() + 's)');

   elapsedTime := Time();

   {call initialization routines}
   ox.Init.iCall();
   if(ox.Error <> 0) then begin
      ErrorDescription := 'Initialization failed';
      exit(oxeGENERAL);
   end;

   log.i('Called all initialization routines (elapsed: ' + elapsedTime.ElapsedfToString() + 's)');

   {call UI initialization routines}
   oxui.Initialize();

   {call application initialization routines}
   if(ox.AppProcs.iList.n > 0) then begin
      elapsedTime := Time();
      ox.AppProcs.iCall();

      if(ox.Error <> 0) then begin
         ErrorDescription := 'Application initialization failed';
         exit(oxeGENERAL);
      end;

      log.i('Called all application initialization routines (elapsed: ' + elapsedTime.ElapsedfToString() + 's)');
   end;

   {success}
   log.i('Initialization done. Elapsed: ' + GlobalStartTime.ElapsedfToString() + 's');
   log.Leave();

   ox.Initialized := true;

   result := eNONE;
end;

procedure oxTInitializationGlobal.Initialize();
var
   errDescription: TErrorString;

begin
   ox.Error := InitializeInternal();

   if(ox.Error <> eNONE) then begin
      errDescription := '';

      if(ErrorDescription <> '') then begin
         log.e(ErrorDescription);

         errDescription.Add(ErrorDescription);
      end;

      if(oxWindows <> nil) and (oxWindows.LastErrorDescription <> '') then
         errDescription.Add(oxWindows.LastErrorDescription);

      errDescription.Add('');
      errDescription.Add('More details can (probably) be found in the log: ' + stdlog.FileName);

      log.e('oX > Failed to initialize the engine. (Error: ' + ox.GetErrorDescription(ox.Error) + ')');
      log.Leave();

      {$IFNDEF OX_LIBRARY}
      if(oxPlatform <> nil) then
         oxPlatform.ErrorMessageBox(appInfo.GetVersionString() + ' (Initialization Failed)', errDescription);
      {$ENDIF}
   end;
end;

procedure oxTInitializationGlobal.DeInitialize();
var
   startTime: TDateTime;

begin
   if(not Started) then
      exit;

   Started := false;
   startTime := Time();

   log.Enter('oX > De-initializing...');

   {save configuration only if we were initialized}
   if(ox.Initialized) then begin
      {$IFNDEF OX_LIBRARY}
         {save window configuration}
         oxWindows.StoreConfiguration();
      {$ENDIF}

      {save configuration before objects are destroyed}
      appDVarTextConfiguration.Save();
   end;

   {perform initial de-initialization step}
   ox.OnDeinitialize.Call();
   log.i('oxDeinitialize complete');

   if(ox.AppProcs.dlist.n > 0) then begin
      ox.AppProcs.dCall();
      log.i('Called all application de-initialization routines');
   end;

   {dispose all windows except primary}
   if(oxWindows <> nil) then begin
      {do not destroy}
      oxWindows.DisposeExceptPrimary();

      {destroy ui objects in primary window}
      if(oxWindows.w[0] <> nil) then
         oxUIHooks.DestroyWindow(oxWindows.w[0]);
   end;

   {done with UI}
   if(oxui <> nil) then
      oxui.Deinitialize();

   {call any de-initializers}
   ox.Init.dCall();

   {de-initialize UI}
   if(oxui <> nil) then
      oxui.BaseDeInitialize();

   ox.BaseInit.dCall();
   log.i('Called de-initialization routines');

   {destroy the remaining primary window}
   oxWindows.Dispose();
   log.i('Destroyed all windows');

   {done with UI}
   FreeObject(oxUIHooks);

   {de-initialize renderers}
   oxRenderers.DeInitialize();

   {$IFNDEF OX_LIBRARY}
   oxPlatforms.Deinitialize();
   {$ENDIF}

   {call preinit deinitializers}
   ox.PreInit.dCall();

   {de-initialize application}
   if(StartedAppInitialize) then begin
      app.DeInitialize();
      log.i('Deinitialized application');
   end;

   {$IFNDEF OX_LIBRARY}
   if(oxGlobalInstances <> nil) then
      oxGlobalInstances.Deinitialize();
   {$ENDIF}

   {done}
   log.i('Done. Elapsed: ' + startTime.ElapsedfToString() + 's');
   log.Leave();

   ox.Initialized := false;
end;

INITIALIZATION
   appDVarTextConfiguration.AutoSave := false;

END.
