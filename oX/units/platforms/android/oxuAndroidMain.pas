{
   oxuAndroidMain
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuAndroidMain;

INTERFACE

USES
   uLog,
   jni, looper, android_native_app_glue;

procedure android_main(app: Pandroid_app); cdecl;

IMPLEMENTATION

procedure handle_cmd(app: Pandroid_app; cmd: longint); cdecl;
begin
end;

procedure android_main(app: Pandroid_app); cdecl;
var
   nEvents: longint;
   pSource: Pandroid_poll_source;

begin
   app^.onAppCmd := @handle_cmd;

   repeat
      if(ALooper_pollAll(0, nil, @nEvents, @pSource) >= 0) then begin
         if(pSource <> nil) then begin
            pSource^.process(app, pSource);
         end;
      end;
   until (app^.destroyRequested > 0);
end;

END.
