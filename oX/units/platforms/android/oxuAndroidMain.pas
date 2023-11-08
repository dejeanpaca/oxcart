{
   oxuAndroidMain
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuAndroidMain;

INTERFACE

USES
   android_native_app_glue, android_log_helper, native_activity,
   StringUtils,
   {app}
   uApp,
   {ox}
   uOX, oxuRun, oxuPlatform, oxuAndroidPlatform, oxuInit;

procedure android_main(app: Pandroid_app); cdecl;

IMPLEMENTATION

procedure android_main(app: Pandroid_app); cdecl;
var
   finished: boolean;

begin
   AndroidApp := app;

   app^.onAppCmd := @AndroidHandleCommand;
   app^.onInputEvent := @AndroidHandleInput;

   finished := false;
   uApp.app.Active := true;

   repeat
      if(ox.Initialized) then begin
         if(not ox.Started) then
            oxRun.Start();

         oxRun.GoCycle(true)
      end else
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
