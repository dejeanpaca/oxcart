{
   oxuInit, oX de/initialization
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuInit;

INTERFACE

   USES
     sysutils, uStd, uLog, uTiming, ParamUtils,
     {app}
     uAppInfo, uApp, appuLog, appudvarConfiguration,
     {oX}
     uOX, oxuWindow, oxuWindows,
     oxuPlatform, oxuUIHooks, oxuGlobalInstances, oxuPlatforms,
     oxuRenderer, oxuRenderers,
     {$IFNDEF OX_LIBRARY}
     oxuContextWindow,
     {$ENDIF}
     uiuBase;

TYPE

   { oxTInitializationGlobal }

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

      function RaiseError(const description: string = ''; error: loopint = oxeGENERAL): loopint;
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

function oxTInitializationGlobal.RaiseError(const description: string; error: loopint): loopint;
begin
   ErrorDescription := description;

   if(ox.Error = 0) and (error <> 0) then
      ox.Error := error;

   Result := error;

   ox.InitializationFailed := true;
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
   Result := eERR;
   GlobalStartTime := Time();
   ox.InitializationFailed := false;

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

   if(ox.Error <> 0) then
      exit(RaiseError('Pre-initialization step failed'));

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
   ui.BaseInitialize();

   log.i('Pre-initialization done (Elapsed: ' + GlobalStartTime.ElapsedfToString() + 's)');

   elapsedTime := Time();

   {$IFNDEF OX_LIBRARY}
   {create a context window and gather information if required}
   if(oxContextWindow.Required()) then begin
      log.v('Will create a context window');
      if(not oxContextWindow.Create()) then
         exit(RaiseError('Failed to create context window'));
   end;
   {$ENDIF}

   oxRenderers.PostContext();

   {create windows}
   if(not oxWindows.Initialize()) then begin
      RaiseError('Failed to create windows');
      {we'll still let the renderer do anything it needs to in case of initialization failure}
      oxRenderer.AfterInitialize();
      exit(oxeGENERAL);
   end;

   {finish renderer initialization}
   oxRenderers.Use(oxRenderer);
   oxRenderer.AfterInitialize();

   {$IFNDEF NO_THREADS}
   {get an additional rendering context}
   oxRenderer.GetContext(oxWindow.Current);
   {$ENDIF}

   {$IFNDEF OX_LIBRARY}
   if(oxContextWindow.Require) then begin
      oxContextWindow.Destroy();
      oxWindows.SetCurrent(oxWindows.w[0]);
   end;
   {$ENDIF}

   log.i('Window setup done (Elapsed: ' + elapsedTime.ElapsedfToString() + 's)');

   elapsedTime := Time();

   oxRenderers.Startup();

   {call base initialization routines}
   ox.BaseInit.iCall();

   if(ox.Error <> 0) then begin
      RaiseError('Base initialization failed');
   end;

   log.i('Base initialization done (Elapsed: ' + elapsedTime.ElapsedfToString() + 's)');

   elapsedTime := Time();

   ox.OnPreInitialize.Call();

   log.i('OnPreInitialize called (Elapsed: ' + elapsedTime.ElapsedfToString() + 's)');

   elapsedTime := Time();

   {call initialization routines}
   ox.Init.iCall();
   if(ox.Error <> 0) then begin
      exit(RaiseError('Initialization failed'));
   end;

   log.i('Called all initialization routines (elapsed: ' + elapsedTime.ElapsedfToString() + 's)');

   {call UI initialization routines}
   ui.Initialize();

   {success}
   log.i('Initialization done. Elapsed: ' + GlobalStartTime.ElapsedfToString() + 's');
   log.Leave();

   ox.Initialized := true;

   Result := eNONE;
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

      if(oxWindows.LastErrorDescription <> '') then
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

procedure oxTInitializationGlobal.Deinitialize();
var
   startTime: TDateTime;

begin
   if(not Started) then
      exit;

   Started := false;
   startTime := Time();

   log.Enter('oX > De-initializing...');

   {perform initial de-initialization step}
   ox.OnInitialize.dCall();
   log.i('oxDeinitialize complete');

   {save configuration only if we were initialized}
   if(ox.Initialized) then begin
      {$IFNDEF OX_LIBRARY}
         {save window configuration}
         oxWindows.StoreConfiguration();
      {$ENDIF}

      {save configuration before objects are destroyed}
      appdvarConfiguration.DvarFile.Save();
   end;

   {do not destroy}
   oxWindows.DisposeExceptPrimary();

   {destroy ui objects in primary window}
   if(oxWindows.w[0] <> nil) then
      oxUIHooks.DestroyWindow(oxWindows.w[0]);

   {done with UI}
   ui.Deinitialize();

   {call any de-initializers}
   ox.Init.dCall();

   {de-initialize UI}
   ui.BaseDeInitialize();

   ox.BaseInit.dCall();
   log.i('Called de-initialization routines');

   {done with renderer}
   oxRenderer.AfterDeinitialize();

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
   oxGlobalInstances.Deinitialize();
   {$ENDIF}

   {done}
   log.i('Done. Elapsed: ' + startTime.ElapsedfToString() + 's');
   log.Leave();

   ox.Initialized := false;
end;

INITIALIZATION
   appdvarConfiguration.AutoSave := false;

END.
