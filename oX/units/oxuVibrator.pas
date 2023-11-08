{
   oxuVibrator, vibrator general device support
   Copyright (C) 2013. Dejan Boras

   NOTE: This is just an abstraction. Requires per platform implementation (for platforms that support it).
   
   Started On:    25.11.2013.
}

{$INCLUDE oxdefines.inc}
UNIT oxuVibrator;

INTERFACE
   USES uStd, StringUtils, uLog;

CONST
   oxcVibratorEnabled: boolean         = true;
   oxcVibratorInitialized: boolean     = false;

TYPE
   { oxTVibratorDevice }

   oxTVibratorDevice = class
      public
      function supported(): boolean; virtual;
      procedure vibrate(pattern: array of longint; rep: longint); virtual;
      procedure vibrate(duration: longint); virtual;
      procedure stop(); virtual;
   end;

VAR
   oxVibrator: oxTVibratorDevice;
   oxpGetVibrator: function(): oxTVibratorDevice;
   oxonVibratorSetHandler: TProcedure;

procedure oxVibratorInitialize();
procedure oxVibratorDeInitialize();
procedure oxVibratorDestroyHandler();
function oxGetVibrator(): oxTVibratorDevice;

IMPLEMENTATION

procedure oxVibratorInitialize();
begin
  if(oxcVibratorEnabled) then begin
     log.Enter('oxVibrator Initialization');
     if (oxonVibratorSetHandler) <> nil then
        oxonVibratorSetHandler();

     if(oxVibrator <> nil) then
        log.i('Vibrator supported: ' + sf(oxVibrator.supported()));

     oxcVibratorInitialized := true;

     log.Leave();
  end;
end;

procedure oxVibratorDeInitialize();
begin
  if(oxcVibratorInitialized) then begin
     log.Enter('oxVibrator deinitialized');

     oxVibratorDestroyHandler();

     log.i('Done');
     log.Leave();
  end;
end;

procedure oxVibratorDestroyHandler();
begin
  FreeObject(oxVibrator);
end;

function oxGetVibrator(): oxTVibratorDevice;
begin
  if(oxcVibratorEnabled) then begin
     if(oxpGetVibrator <> nil) then
        result := oxpGetVibrator()
     else
        result := oxTVibratorDevice.Create();
  end else
     result := nil;
end;

procedure setDefaultHandler();
begin
   oxVibratorDestroyHandler();
   oxVibrator := oxTVibratorDevice.Create();
end;

{ oxTVibratorDevice }

function oxTVibratorDevice.supported(): boolean;
begin
   result := false;
end;

procedure oxTVibratorDevice.vibrate(pattern: array of longint; rep: longint);
begin

end;

procedure oxTVibratorDevice.vibrate(duration: longint);
begin

end;

procedure oxTVibratorDevice.stop();
begin

end;

INITIALIZATION
   oxonVibratorSetHandler := @setDefaultHandler;

   oxiProcs.Add('vibrator', @oxVibratorInitialize, @oxVibratorDeInitialize);
END.
