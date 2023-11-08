{
   appuControllerLinux, input controller handling for Linux
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT appuControllerLinux;

INTERFACE

   USES baseunix, sysutils, uStd, uLog, StringUtils, uLinux,
      appuInputTypes, appuController;

TYPE

   { appTLinuxControllerHandler }

   appTLinuxControllerHandler = object(appTControllerHandler)
      procedure Initialize(); virtual;
      procedure Reset(); virtual;
      procedure Run(); virtual;

      private
         procedure Add(const fn: string);
   end;

   { appTLinuxControllerDevice }

   appTLinuxControllerDevice = class(appTControllerDevice)
      FileName: string;

      procedure Initialize(const fn: string);
      procedure Update(); override;
      procedure DeInitialize(); override;

      private
         fileHandle: longint;
   end;

IMPLEMENTATION

{API: https://www.kernel.org/doc/Documentation/input/joystick-api.txt}

CONST
   JS_EVENT_BUTTON   = $01; {button pressed/released}
   JS_EVENT_AXIS     = $02; {joystick moved}
   JS_EVENT_INIT     = $80; {initial state of device}

   {ioctls}
   JSIOCGVERSION     = $01; {get driver version}
   JSIOCGAXES        = $11; {get number of axes)}
   JSIOCGBUTTONS     = $12; {get number of buttons}
   JSIOCGNAME        = $13; {get identifier string}


TYPE
   js_event = packed record
      time: longword;
      value: Smallint;
      typ: byte;
      number: byte;
   end;

   { js_event_helper }

   js_event_helper = record helper for js_event
      function GetTypeString(): string;
   end;

VAR
   appLinuxControllerHandler: appTLinuxControllerHandler;

{ js_event_helper }

function js_event_helper.GetTypeString: string;
begin
   if(typ and JS_EVENT_INIT = 0) then
      Result := ''
   else
      Result := 'init ';

   if(typ and JS_EVENT_BUTTON > 0) then
      Result := Result + 'button'
   else if(typ and JS_EVENT_AXIS > 0) then
      Result := Result + 'axis'
   else
      Result := 'unknown';
end;

{ appTLinuxControllerDevice }

procedure appTLinuxControllerDevice.Initialize(const fn: string);
var
   pname: array[0..129] of char;
   error: longint;
   version: longint = 0;
   version_bytes: packed array[0..3] of byte absolute version;
   nAxes,
   nButtons: byte;

begin
   FileName := fn;

   fileHandle := fpOpen(FileName, O_RdOnly or O_NonBlock);

   if(fileHandle > 0) then begin
      log.i('Successfully opened device: ' + fn);

      error := fpIOCtl(fileHandle, linux._ior('j', JSIOCGVERSION, sizeof(version)), @version);

      if(error = 0) then begin
         log.i('Driver version: ' + sf(version) + ' (' + sf(version_bytes[1]) + '.' + sf(version_bytes[2]) + '.' + sf(version_bytes[3]) + '.' + sf(version_bytes[0]) + ')');
      end else
         log.w('Failed to get driver version: ' + linux.GetErrorString(fpgeterrno()));

      fpgeterrno();

      error := fpIOCtl(fileHandle, linux._ior('j', JSIOCGNAME, sizeof(pname)), @pname);

      if(error > 0) then
         Name := pchar(pname)
      else begin
         Name := FileName;

         error := fpgeterrno();
         if(error <> 0) then
            log.w('Failed getting device name: ' + linux.GetErrorString(error));
      end;

      log.Collapsed(Name);

      error := fpIOCtl(fileHandle, linux._ior('j', JSIOCGAXES, sizeof(nAxes)), @nAxes);

      if(error = 0) then
         AxisCount := nAxes
      else
         log.w('Failed to get number of axes: ' + linux.GetErrorString(fpgeterrno()));

      error := fpIOCtl(fileHandle, linux._ior('j', JSIOCGBUTTONS, sizeof(nButtons)), @nButtons);

      if(error = 0) then
         ButtonCount := nButtons
      else
         log.w('Failed to get number of buttons: ' + linux.GetErrorString(fpgeterrno()));

      LogDevice();
      log.Leave();
   end else
      log.e('Failed adding device: ' + fn + '. Unix error: ' + sf(ioerror()));
end;

procedure appTLinuxControllerDevice.Update();
var
   jsevent: js_event;
   count: int64;
   error: longint;

   event: appTControllerEvent;

begin
   ZeroPtr(@jsevent, SizeOf(jsevent));

   repeat
      {no need for event to be initialized, since we read it}
      count := {%H-}FpRead(fileHandle, jsevent, SizeOf(js_event));

      if(count > 0) then begin
         event.MappedFunction := appCONTROLLER_NONE;
         event.Controller := Self;
         event.KeyCode := jsevent.number;

         if(jsevent.typ and JS_EVENT_BUTTON > 0) then begin
            event.Typ := appCONTROLLER_EVENT_BUTTON;
            State.KeyState := State.KeyState or (1 shr jsevent.number);

            if(jsevent.value = 0) then
               event.Value := 0
            else
               event.Value := 1.0;

            State.Keys.Process(jsevent.number, event.Value > 0);
         end else  if(jsevent.typ and JS_EVENT_AXIS > 0) then begin
            event.Typ := appCONTROLLER_EVENT_AXIS;
            State.Axes[jsevent.number] := jsevent.value;
            event.Value := State.Axes[jsevent.number];
         end;

         event.KeyState := State.KeyState;
         event.Value := jsevent.value;

         if(jsevent.typ and JS_EVENT_INIT = 0) then
            appControllers.Queue(event, Self);
      end else begin
         error := fpgeterrno;

         if(error = ESysENODEV) then
            Disconnected();

         break;
      end;
   until (true);
end;

procedure appTLinuxControllerDevice.DeInitialize();
begin
   inherited DeInitialize;

   fpClose(fileHandle);
   ioErrorIgn();
end;

{ appTLinuxControllerHandler }

procedure appTLinuxControllerHandler.Initialize();
begin
   Reset();
end;

procedure appTLinuxControllerHandler.Reset();
var
   fSearch: TSearchRec;
   err: longint;

begin
   inherited Reset;

   {find all devices}
   err := FindFirst('/dev/input/js*', faAnyFile, fSearch);

   if(err = 0) then begin
      log.Collapsed('Controller initialization (reset)');
      repeat
         {device found, add it}
         Add('/dev/input/' + fSearch.Name);

         err := FindNext(fSearch);
      until (err <> 0);
      log.Leave();
   end else
      log.v('No controllers found');

   FindClose(fSearch);

   ioErrorIgn();
end;

procedure appTLinuxControllerHandler.Run();
begin
   inherited Run();
end;

procedure appTLinuxControllerHandler.Add(const fn: string);
var
   device: appTLinuxControllerDevice;

begin
   device := appTLinuxControllerDevice.Create();
   device.Initialize(fn);

   appControllers.Add(device);
   ioErrorIgn();
end;

INITIALIZATION
   appLinuxControllerHandler.Create();
   appControllers.AddHandler(appLinuxControllerHandler);

END.
