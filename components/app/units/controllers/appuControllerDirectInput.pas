{
   appuControllerDirectInput, DirectInput controller handling
   Copyright (C) 2019. Dejan Boras

   TODO: Implement force feedback support
}

{$INCLUDE oxheader.inc}
UNIT appuControllerDirectInput;

INTERFACE

   USES
      uStd, uLog, StringUtils,
      {app}
      appuController,
      {ox}
      uOX, oxuWindow, oxuWindowsOS,
      {dx}
      windows, DirectInput;

TYPE

   { appTDirectInputControllerHandler }

   appTDirectInputControllerHandler = object(appTControllerHandler)
      DIInterface: IID_IDirectInput8;

      procedure Initialize(); virtual;
      procedure Reset(); virtual;
      procedure Run(); virtual;

      protected
         function Add(var lpddi: TDIDeviceInstanceA): boolean;
   end;

   { appTDirectInputControllerDevice }

   appTDirectInputControllerDevice = class(appTControllerDevice)
      Device: IDirectInputDevice8A;

      GUID,
      FFGUID: windows.TGUID;

      procedure Update(); override;
      procedure DeInitialize(); override;
   end;

IMPLEMENTATION

VAR
   appDirectInputControllerHandler: appTDirectInputControllerHandler;

{ appTDirectInputControllerDevice }

procedure appTDirectInputControllerDevice.Update();
begin
end;

procedure appTDirectInputControllerDevice.DeInitialize();
begin
   inherited;
end;

{ appTDirectInputControllerHandler }

procedure appTDirectInputControllerHandler.Initialize();
var
   error: HResult;

begin
   if(not LoadDirectInput()) then begin
      log.e('Failed to load DirectInput');
      exit;
   end;

   error := DirectInput8Create(system.MainInstance, DIRECTINPUT_VERSION, IID_IDirectInput8A, DIInterface, Nil);

   if(error <> DI_OK) then begin
      log.e('Failed to initialize DirectInput 8 (error: ' + sf(error) + ')');
      exit;
   end;

   Reset();
end;

function diCallback(var lpddi: TDIDeviceInstanceA; {%H-}pvRef: Pointer): windows.BOOL; stdcall;
begin
   appDirectInputControllerHandler.Add(lpddi);

   Result := DIENUM_CONTINUE;
end;

procedure appTDirectInputControllerHandler.Reset();
begin
   if(oxWindow.Current <> nil) then begin
      DIInterface.EnumDevices(DI8DEVCLASS_GAMECTRL, @diCallback, nil, DIEDFL_ATTACHEDONLY);
   end;
end;

procedure appTDirectInputControllerHandler.Run();
begin
   inherited Run();
end;

function appTDirectInputControllerHandler.Add(var lpddi: TDIDeviceInstanceA): boolean;
var
   device: appTDirectInputControllerDevice;
   diDevice: IDirectInputDevice8A;
   error: HRESULT;

   capabilities: DIDEVCAPS;

   procedure logError(const what: string);
   begin
      log.e('DirectInput > ' + what + ' Device: ' + pchar(lpddi.tszInstanceName) + ' (' + pchar(lpddi.tszProductName) + ')');
   end;

   function failed(err_what: HRESULT; const what: string): boolean;
   begin
      Result := err_what <> DI_OK;

      if(Result) then
         logError(what + '. ' + winos.FormatMessage(dword(err_what)));
   end;

begin
   Result := false;
   error := appDirectInputControllerHandler.DIInterface.CreateDevice(lpddi.guidInstance, diDevice, nil);

   {only create our own device if DI created a device}
   if(error = DI_OK) then begin
      device := appTDirectInputControllerDevice.Create();

      device.Name := pchar(lpddi.tszProductName);
      device.GUID := lpddi.guidInstance;
      device.FFGUID := lpddi.guidFFDriver;

      device.Device := diDevice;

      {get device updates when in background and exclusive access when in foreground}
      if failed(diDevice.SetCooperativeLevel(winosTWindow(oxWindow.Current).wd.h,
         DISCL_BACKGROUND or DISCL_EXCLUSIVE), 'Failed to set cooperative level') then begin
         FreeObject(device);
         exit(false);
      end;

      {use generic joystick data format}
      if failed(diDevice.SetDataFormat(c_dfDIJoystick), 'Failed to set data format') then begin
         FreeObject(device);
         exit(false);
      end;

      {get device capabilities}
      ZeroOut(capabilities, SizeOf(capabilities));

      if failed(diDevice.GetCapabilities(capabilities), 'Failed to get capabilities') then begin
         FreeObject(device);
         exit(false);
      end;

      {get number of axes and buttons}
      writeln(capabilities.dwAxes, ' ', capabilities.dwButtons);

      {TODO: Get the rest of this functional}

      appControllers.Add(device);
      Result := true;
   end else
      logError('Failed to create device.');
end;

procedure init();
begin
   {we can only init a directinput device when we have a window}
   appDirectInputControllerHandler.Reset();
end;

INITIALIZATION
   appDirectInputControllerHandler.Create();
   appControllers.AddHandler(appDirectInputControllerHandler);

   ox.OnInitialize.Add('directinput', @init);

END.
