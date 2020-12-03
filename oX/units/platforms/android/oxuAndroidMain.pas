{
   oxuAndroidMain
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuAndroidMain;

INTERFACE

USES
   android_native_app_glue, android_log_helper, native_activity, android_native_activity_helper, android_env,
   ctypes, looper, jni,
   uLog, uUnix, StringUtils,
   {app}
   uApp,
   {ox}
   uOX, oxuRun, oxuInitialize, oxuPlatform, oxuAndroidPlatform;

procedure android_main(app: Pandroid_app); cdecl;

IMPLEMENTATION

VAR
   mainThreadLooper: PALooper;
   mainThreadMessagePipe: unxTPipe;

function mainThreadLooperCallback(fd: cint; events: cint; data: pointer): cint; cdecl;
var
   msg: char;

begin
   unxFpread(fd, @msg, 1);
   Result := 1;

   if(AndroidApp = nil) or (msg <> '@') then
      exit;

   if(oxAndroidPlatform.fHideNavbar) then begin
      androidAutoHideNavBar(AndroidApp^);
      oxAndroidPlatform.fHideNavbar := false;
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

   oxAndroidPlatform.fStarted := true;

   repeat
      cycledEvents := false;

      if(not ox.Initialized) and (not ox.InitializationFailed) then begin
         if(not ox.Started) and (oxAndroidPlatform.fInitWindow) then begin
            oxRun.Initialize();
            oxAndroidPlatform.fInitWindow := false;
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
         if(oxAndroidPlatform.fSignalMainThread) then begin
            oxAndroidPlatform.fSignalMainThread := false;
            signalMainThread();
         end;

         if(oxAndroidPlatform.fRegainedFocus) then begin
            if(oxAndroidPlatform.fStarted) then begin
               oxAndroidPlatform.fRegainedFocus := false;
            end else begin
               oxAndroidPlatform.fRecreateSurface := true;
               oxAndroidPlatform.RecreateSurface();
               oxAndroidPlatform.RegainedFocus();
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
end;

procedure androidAppCreate(var app: android_app);
begin
   app.activity^.vm^^.GetEnv(app.activity^.vm, @mainThreadEnv, JNI_VERSION_1_6);

   getMainThreadLooper();
end;

INITIALIZATION
   onAndroidAppCreate := @androidAppCreate;

END.
