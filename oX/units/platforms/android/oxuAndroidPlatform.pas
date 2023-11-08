{
   oxuAndroidPlatform, android platform
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuAndroidPlatform;

INTERFACE

   USES
      ctypes, looper, input, android_native_app_glue, android_keycodes, android_log_helper,
      uStd, StringUtils,
      {app}
      uApp, appuMouse,
      {oX}
      oxuPlatform, oxuPlatforms, oxuWindowTypes;

TYPE
   { oxTAndroidPlatform }

   oxTAndroidPlatform = class(oxTPlatform)
      constructor Create(); override;
      function Initialize(): boolean; override;

      function MakeWindow({%H-}wnd: oxTWindow): boolean; override;

      procedure ProcessEvents(); override;
   end;

   { TAndroidPointerDriver }

   TAndroidPointerDriver = class(appTPointerDriver)
      LastX,
      LastY: loopint;

      constructor Create();

      procedure getXY({%H-}devID: longint; wnd: pointer; out x, y: single); override;
      procedure setXY({%H-}devID: longint; wnd: pointer; x, y: single); override;
      procedure hide(devID: longint; {%H-}wnd: pointer); override;
      procedure show(devID: longint; {%H-}wnd: pointer); override;
   end;

VAR
   AndroidApp: Pandroid_app;

procedure AndroidHandleCommand(app: Pandroid_app; cmd: cint32);
function AndroidHandleInput(app: Pandroid_app; event: PAInputEvent): cint32;

IMPLEMENTATION

procedure AndroidHandleCommand(app: Pandroid_app; cmd: cint32);
begin
   writeln(sf(cmd));
end;

function AndroidHandleInput(app: Pandroid_app; event: PAInputEvent): cint32;
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

{ TAndroidPointerDriver }

constructor TAndroidPointerDriver.Create();
begin
   Name := 'android';
end;

procedure TAndroidPointerDriver.getXY(devID: longint; wnd: pointer; out x, y: single);
begin
   inherited getXY(devID, wnd, x, y);
end;

procedure TAndroidPointerDriver.setXY(devID: longint; wnd: pointer; x, y: single);
begin
   inherited setXY(devID, wnd, x, y);
end;

procedure TAndroidPointerDriver.hide(devID: longint; wnd: pointer);
begin
   inherited hide(devID, wnd);
end;

procedure TAndroidPointerDriver.show(devID: longint; wnd: pointer);
begin
   inherited show(devID, wnd);
end;

{ oxTAndroidPlatform }

constructor oxTAndroidPlatform.Create();
begin
   Name := 'android';
end;

function oxTAndroidPlatform.Initialize(): boolean;
begin
   { pointer driver }
   PointerDriver := TAndroidPointerDriver.Create();

   Result := true;
end;

function oxTAndroidPlatform.MakeWindow(wnd: oxTWindow): boolean;
begin
   Result := true;
end;

procedure oxTAndroidPlatform.ProcessEvents();
var
   ident,
   nEvents: cint;
   pSource: Pandroid_poll_source;

begin
   nEvents := 0;
   pSource := nil;

   repeat
      ident := ALooper_pollAll(-1, nil, @nEvents, @pSource);

      if(ident >= 0) then begin
         logi('event: ' + sf(ident));

         if(pSource <> nil) then begin
            logi('source: ' + sf(pSource^.id));
            pSource^.process(AndroidApp, pSource);
         end;
      end;

      if(AndroidApp^.destroyRequested) or (not app.Active) then
         exit;
   until false;
end;

INITIALIZATION
   oxPlatforms.Register(oxTAndroidPlatform);

END.
