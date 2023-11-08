{
   oxuAndroidMain
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuAndroidMain;

INTERFACE

USES
   ctypes, looper, input, android_native_app_glue, android_keycodes,
   android_log_helper, StringUtils;

procedure android_main(app: Pandroid_app); cdecl;

IMPLEMENTATION

procedure handle_cmd(app: Pandroid_app; cmd: cint32);
begin
   logi('command: ' + sf(cmd));
end;

function handle_input(app: Pandroid_app; event: PAInputEvent): cint32;
var
   kc,
   action,
   etype: cint32;

begin
   etype := AInputEvent_getType(event);

   kc := AKeyEvent_getKeyCode(event);
   action := AKeyEvent_getAction(event);

   if(etype = AINPUT_EVENT_TYPE_KEY) then begin
      if(kc = AKEYCODE_BACK) then begin
         if(action = AKEY_STATE_UP) then
            app^.destroyRequested := true;
      end;
   end;

   Result := 0;
end;

procedure android_main(app: Pandroid_app); cdecl;
var
   ident,
   nEvents: cint;
   pSource: Pandroid_poll_source;

begin
   app^.onAppCmd := @handle_cmd;
   app^.onInputEvent := @handle_input;

   nEvents := 0;
   pSource := nil;

   repeat
      ident := ALooper_pollAll(-1, nil, @nEvents, @pSource);

      if(ident >= 0) then begin
         logi('event: ' + sf(ident));
         if(pSource <> nil) then begin
            logi('source: ' + sf(pSource^.id));
            pSource^.process(app, pSource);
         end;
      end;

      if(app^.destroyRequested) then
         exit;
   until false;
end;

END.
