{
   oxuAndroidMain
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuAndroidMain;

INTERFACE

USES
   ctypes, looper, input, android_native_app_glue, android_keycodes,
   uLog, ulogAndroid, StringUtils,
   uApp, appuActionEvents;

procedure android_main(app: Pandroid_app); cdecl;

IMPLEMENTATION

procedure handle_cmd(app: Pandroid_app; cmd: cint32); cdecl;
begin
   logi('command: ' + sf(command));
end;

function handle_input(app: Pandroid_app; event: PAInputEvent): cint32; cdecl;
var
   kc,
   action: cint32;

begin
   kc := AKeyEvent_getKeyCode(event);
   action := AKeyEvent_getAction(event);

   if(kc = AKEYCODE_BACK) then begin
      if(action = AKEY_STATE_UP) then begin
         uApp.app.Active := false;
         appActionEvents.QueueQuitEvent();

         exit(1);
      end;
   end;

   Result := 0;
end;

procedure android_main(app: Pandroid_app); cdecl;
var
   nEvents: cint;
   pSource: Pandroid_poll_source;

begin
   app^.onAppCmd := @handle_cmd;
   app^.onInputEvent := @handle_input;

   nEvents := 0;
   pSource := nil;

   repeat
      if(ALooper_pollAll(0, nil, @nEvents, @pSource) >= 0) then begin
         if(pSource <> nil) then begin
            pSource^.process(app, pSource);
         end;
      end;
   until (app^.destroyRequested > 0) or (not uApp.app.Active);
end;

END.
