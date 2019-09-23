{
   appuControllerLinux, input controller handling for Linux
   Copyright (C) 2016. Dejan Boras

   Started On:    08.09.2016.
}

{$INCLUDE oxdefines.inc}
UNIT appuControllerLinux;

INTERFACE

   USES baseunix, sysutils, uStd, uLog, StringUtils, uLinux,
      appuController;

TYPE

   { appTLinuxControllerHandler }

   appTLinuxControllerHandler = class(appTControllerHandler)
      procedure Initialize(); override;
      procedure Reset(); override;
      procedure Run(); override;

      private
         procedure Add(const fn: string);
   end;

   { appTLinuxControllerDevice }

   appTLinuxControllerDevice = class(appTControllerDevice)
      FileName: string;

      procedure Initialize(const fn: string);
      procedure Run(); override;
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

procedure appTLinuxControllerDevice.Run();
var
   jsevent: js_event;
   count: int64;
   error: longint;

   event: appTControllerEvent;

begin
   {$IFDEF DEBUG}
   jsevent.typ := 0;
   {$ENDIF}

   repeat
      {no need for event to be initialized, since we read it}
      count := fpRead(fileHandle, {%H-}jsevent, SizeOf(js_event));

      if(count > 0) then begin
         event.MappedFunction := appCONTROLLER_NONE;
         event.Controller := Self;
         event.Number := jsevent.number;

         if(jsevent.typ and JS_EVENT_BUTTON > 0) then begin
            event.Typ := appCONTROLLER_EVENT_BUTTON;
            State.Keys := State.Keys or (1 shr jsevent.number);
         end else
            event.Typ := appCONTROLLER_EVENT_AXIS;

         if(jsevent.value = 0) then begin
            event.Value := 0;

            if(jsevent.typ and JS_EVENT_AXIS > 0) then
               State.Axes[jsevent.number] := 0;
         end else begin
            if(jsevent.typ and JS_EVENT_AXIS > 0) then begin
               State.Axes[jsevent.number] := 1 / 32767 * jsevent.value;
               event.Value := State.Axes[jsevent.number];
            end else
               event.Value := jsevent.value;
         end;

         event.Keys := State.Keys;
         event.Value := jsevent.value;

         if(jsevent.typ and JS_EVENT_INIT = 0) then
            appControllers.Queue(event);
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
   appControllerHandler := appTLinuxControllerHandler.Create();

END.
