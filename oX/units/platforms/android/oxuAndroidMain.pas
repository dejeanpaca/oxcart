{
   oxuAndroidMain
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuAndroidMain;

INTERFACE

USES
   android_native_app_glue, android_log_helper, native_activity, android_native_activity_helper,
   android_window, android_layout_params,
   ctypes, looper, jni, uAndroid,
   uLog, uUnix, StringUtils,
   {assets}
   oxuAndroidAssets, uAndroidAssets,
   {app}
   uApp, appuLog,
   {ox}
   uOX, oxuRun, oxuInitialize, oxuPlatform,
   oxuAndroidPlatform;

procedure android_main(app: Pandroid_app); cdecl;

IMPLEMENTATION

TYPE
   TState = (
      {we're just starting initialization}
      STATE_INITIALIZE,
      {wait for window to be ready (all changes applied before proceeding)}
      STATE_WAIT_FOR_WINDOW,
      {window is ready, and we can initialize the engine}
      STATE_WINDOW_READY,
      {we're all set up and running}
      STATE_RUNNING
   );

VAR
   mainThreadLooper: PALooper;
   mainThreadMessagePipe: unxTPipe;
   State: TState;

procedure hideNavbar();
begin
   androidAutoHideNavBar(AndroidApp^.activity);
   oxAndroidPlatform.fHideNavbar := false;
end;

function mainThreadLooperCallback(fd: cint; events: cint; data: pointer): cint; cdecl;
var
   msg: char;

begin
   unxFpread(fd, @msg, 1);
   Result := 1;

   if(AndroidApp = nil) or (msg <> '@') then
      exit;

   {initialize jni constructs if we haven't already}
   if(androidWindow.windowClass = nil) then
      androidWindow.Initialize();

   {hide navbar if requested}
   if(oxAndroidPlatform.fHideNavbar) then
      hideNavbar();

   if(State = STATE_WAIT_FOR_WINDOW) then begin
      if(AndroidApp^.activity <> nil) then
         androidWindow.SetLayoutInDisplayCutoutMode(AndroidApp^.activity, LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES);

      State := STATE_INITIALIZE;
   end;
end;

procedure signalMainThread();
var
   msg: char;

begin
   msg := '@';

   unxFpWrite(mainThreadMessagePipe[1], @msg, 1);
end;

procedure getMainThreadLooper();
begin
   {setup a message pipe for the UI thread}
   mainThreadLooper := ALooper_forThread();

   if(mainThreadLooper <> nil) then begin
      ALooper_acquire(mainThreadLooper);
      unxFpPipe(mainThreadMessagePipe);

      ALooper_addFd(mainThreadLooper, mainThreadMessagePipe[0], 0, ALOOPER_EVENT_INPUT, @mainThreadLooperCallback, nil);
      logv('Got main thread looper');
   end else
      loge('Failed to get main thread looper');
end;

procedure android_main(app: Pandroid_app); cdecl;
var
   cycledEvents: boolean;
   finished: boolean;

begin
   AndroidApp := app;

   app^.onAppCmd := @AndroidHandleCommand;
   app^.onInputEvent := @AndroidHandleInput;

   finished := false;
   uApp.app.Active := true;

   appLog.Initialize();

   androidAssetManager.Get(app^.activity);
   oxAndroidAssets.Initialize();

   oxAndroidPlatform.Startup();
   State := STATE_INITIALIZE;

   repeat
      cycledEvents := false;

      if(oxAndroidPlatform.fSignalMainThread) then begin
         oxAndroidPlatform.fSignalMainThread := false;
         signalMainThread();
      end;

      if(not ox.Initialized) and (not ox.InitializationFailed) then begin
         if(not ox.Started) and (oxAndroidPlatform.fInitWindow) then begin
            if(oxAndroidPlatform.AutoHideNavBar) and (State = STATE_INITIALIZE) then begin
               State := STATE_WAIT_FOR_WINDOW;
               oxAndroidPlatform.HideNavBar();
            end else
               State := STATE_WINDOW_READY;

            if(State = STATE_WINDOW_READY) then begin
               oxRun.Initialize();
               oxAndroidPlatform.fInitWindow := false;

               if(not ox.InitializationFailed) then
                  State := STATE_RUNNING;
            end;
         end;
      end;

      if(oxAndroidPlatform.fDone) then begin
         oxRun.Done();
         oxInitialization.Deinitialize();
         oxAndroidPlatform.fDone := false;
      end;

      if(ox.Initialized) and (not finished) then begin
         if(not ox.Started) then begin
            oxRun.Start();
         end else begin
            if(oxAndroidPlatform.fLostWindow) then begin
               oxAndroidPlatform.DestroyWindow();
            end;

            if(not finished) then begin
               oxRun.GoCycle(true);
               cycledEvents := true;
            end;
         end;
      end;

      if(ox.Started) then begin
         if(oxAndroidPlatform.fRegainedFocus) then begin
            if(not oxAndroidPlatform.fHaveFocus) then begin
               oxAndroidPlatform.fRecreateSurface := true;
               oxAndroidPlatform.RecreateSurface();
               oxAndroidPlatform.RegainedFocus();
               oxAndroidPlatform.fRegainedFocus := false;
            end;
         end;
      end;

      if(not cycledEvents) then
         AndroidProcessEvents();

      if ox.InitializationFailed or (not uApp.app.Active) then begin
         if(not finished) then begin
            finished := true;
            logv('Closing activity: ' + sf(app^.activity));
            ANativeActivity_finish(app^.activity);
         end;
      end;

      if(AndroidApp^.destroyRequested) then
         break;
   until false;

   oxAndroidAssets.DeInitialize();
end;

procedure androidAppCreate(var app: android_app);
begin
   app.activity^.vm^^.GetEnv(app.activity^.vm, @mainThreadEnv, JNI_VERSION_1_6);

   getMainThreadLooper();
end;

INITIALIZATION
   onAndroidAppCreate := @androidAppCreate;

END.
