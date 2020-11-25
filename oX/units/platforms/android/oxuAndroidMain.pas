{
   oxuAndroidMain
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuAndroidMain;

INTERFACE

USES
   android_native_app_glue, android_log_helper, native_activity, android_native_activity_helper,
   StringUtils,
   {app}
   uApp,
   {ox}
   uOX, oxuRun, oxuInitialize, oxuPlatform, oxuAndroidPlatform;

procedure android_main(app: Pandroid_app); cdecl;

IMPLEMENTATION

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
         if(oxAndroidPlatform.HideNavbar) then begin
            androidAutoHideNavBar(app);
            oxAndroidPlatform.HideNavbar := false;
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

END.
