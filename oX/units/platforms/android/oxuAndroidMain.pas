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
   uOX, oxuRun, oxuPlatform, oxuAndroidPlatform, oxuInit;

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

   repeat
      cycledEvents := false;

      if(ox.Initialized) and (not finished) then begin
         if(not ox.Started) then
            oxRun.Start();

         if(not finished) then begin
            oxRun.GoCycle(true);
            cycledEvents := true;
         end;
      end;

      if(ox.Started) then begin
         if(app^.hideNavbar) then begin
            androidAutoHideNavBar(app);
            app^.hideNavbar := false;
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
