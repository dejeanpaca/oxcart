{
   appuControllerLinux, input controller handling for Linux
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT appuControllerLinux;

INTERFACE

   USES
      baseunix, sysutils,
      uUnix, uStd, uLog, StringUtils, uLinux,
      {app}
      appuController, appuControllers;

TYPE
   { appTLinuxControllerDevice }

   appTLinuxControllerDevice = class(appTControllerDevice)
      FileName: string;

      constructor Create(); override;

      procedure Initialize(const fn: string);
      procedure Update(); override;
      procedure DeInitialize(); override;

      private
         fileHandle: longint;
   end;

   { appTLinuxControllerHandler }

   appTLinuxControllerHandler = object(appTControllerHandler)
      procedure Scan(); virtual;
      procedure Rescan(); virtual;

      protected
         procedure Add(const fn: string);
         function FindByFn(const fn: string): appTLinuxControllerDevice;

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

constructor appTLinuxControllerDevice.Create();
begin
   inherited Create();

   TriggerValueRange := 32767;
   AxisValueRange := 32767;
   Handler := @appLinuxControllerHandler;
end;

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

   fileHandle := unxFpOpen(FileName, O_RdOnly or O_NonBlock, MODE_FPOPEN);

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

      error := fpIOCtl(fileHandle, linux._ior('j', JSIOCGAXES, sizeof(nAxes)), @nAxes);

      if(error = 0) then begin
         Settings.AxisCount := nAxes;

         if(Settings.AxisCount >= 2) then begin
            Settings.AxisGroupCount := 1;
            Settings.AxisGroups[0][0] := 0;
            Settings.AxisGroups[0][1] := 1;
         end;

         if(Settings.AxisCount >= 4) then begin
            Settings.AxisGroupCount := 2;
            Settings.AxisGroups[1][0] := 3;
            Settings.AxisGroups[1][1] := 4;
         end;
      end else
         log.w('Failed to get number of axes: ' + linux.GetErrorString(fpgeterrno()));

      error := fpIOCtl(fileHandle, linux._ior('j', JSIOCGBUTTONS, sizeof(nButtons)), @nButtons);

      if(error = 0) then
         Settings.ButtonCount := nButtons
      else
         log.w('Failed to get number of buttons: ' + linux.GetErrorString(fpgeterrno()));
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
      count := unxFpRead(fileHandle, @jsevent, SizeOf(js_event));

      if(count = SizeOf(js_event)) then begin
         event.MappedFunction := appCONTROLLER_NONE;
         event.Controller := Self;
         event.KeyCode := jsevent.number;

         if(jsevent.typ and JS_EVENT_BUTTON > 0) then begin
            event.Typ := appCONTROLLER_EVENT_BUTTON;

            SetButtonPressedState(jsevent.number, jsevent.value > 0);
         end else  if(jsevent.typ and JS_EVENT_AXIS > 0) then begin
            event.Typ := appCONTROLLER_EVENT_AXIS;

            SetAxisState(jsevent.number, jsevent.value);
         end;

         event.KeyState := State.KeyState;
         event.Value := jsevent.value;

         if(jsevent.typ and JS_EVENT_INIT = 0) then
            appControllers.Queue(event, Self);

         Updated := true;
      end else begin
         error := fpgeterrno();

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

procedure appTLinuxControllerHandler.Scan();
begin
   Rescan();
end;

procedure appTLinuxControllerHandler.Rescan();
var
   fSearch: TSearchRec;
   err: longint;
   fn: string;

begin
   {find all devices}
   err := FindFirst('/dev/input/js*', faAnyFile, fSearch);

   if(err = 0) then begin
      repeat
         fn := '/dev/input/' + fSearch.Name;

         if(FindByFn(fn) = nil) then begin
            {device found, add it}
            Add(fn);
         end;

         err := FindNext(fSearch);
      until (err <> 0);
   end;

   FindClose(fSearch);

   ioErrorIgn();
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

function appTLinuxControllerHandler.FindByFn(const fn: string): appTLinuxControllerDevice;
var
   i: loopint;

begin
   for i := 0 to appControllers.List.n - 1 do begin
      if(appControllers.List[i].ClassType = appTLinuxControllerDevice.ClassType) then begin
         if(appTLinuxControllerDevice(appControllers.List[i]).FileName = fn) then
            exit(appTLinuxControllerDevice(appControllers.List[i]));
      end;
   end;

   Result := nil;
end;

INITIALIZATION
   appLinuxControllerHandler.Create();
   appControllers.AddHandler(appLinuxControllerHandler);

END.
