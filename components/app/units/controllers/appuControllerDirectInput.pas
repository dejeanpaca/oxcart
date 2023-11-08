{
   appuControllerDirectInput, DirectInput controller handling
   Copyright (C) 2019. Dejan Boras

   TODO: Implement force feedback support
}

{$INCLUDE oxheader.inc}
UNIT appuControllerDirectInput;

INTERFACE

   USES
      sysutils, Types,
      uStd, uLog, uTiming,
      {app}
      appuController, appuControllers, appuControllerWindows,
      {ox}
      uOX, oxuWindow, oxuWindowsOS,
      {dx}
      windows, ComObj, DirectInput;

TYPE

   { appTDirectInputControllerHandler }

   appTDirectInputControllerHandler = object(appTControllerHandler)
      DIInterface: IID_IDirectInput8;

      constructor Create();

      procedure Initialize(); virtual;
      procedure Scan(); virtual;
      procedure Rescan(); virtual;

      procedure SetupDI();

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

function StringFromCLSID(const guid: TCLSID; out str: POLESTR): HRESULT; stdcall; external  'ole32.dll' name 'StringFromCLSID';
procedure CoTaskMemFree(p: PVOID); stdcall; external  'ole32.dll' name 'CoTaskMemFree';

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

constructor appTDirectInputControllerHandler.Create();
begin
   inherited;

   AutoRescan := false;
end;

procedure appTDirectInputControllerHandler.Initialize();
begin
   SetupDI();
end;

procedure appTDirectInputControllerHandler.Scan();
begin
   Rescan();
end;

function diCallback(var lpddi: TDIDeviceInstanceA; {%H-}pvRef: Pointer): windows.BOOL; stdcall;
begin
   if appDirectInputControllerHandler.Add(lpddi) then
      Result := DIENUM_CONTINUE
   else
      Result := DIENUM_STOP;
end;

procedure appTDirectInputControllerHandler.Rescan();
var
   time: TDateTime;

begin
   if(DIInterface = nil) then
      exit;

   time := Now();

   if(oxWindow.Current <> nil) then begin
      DIInterface.EnumDevices(DI8DEVCLASS_GAMECTRL, @diCallback, nil, DIEDFL_ATTACHEDONLY);

      log.v('DirectInput device enumeration elapsed: ' + time.ElapsedfToString(3));
   end;
end;

procedure appTDirectInputControllerHandler.SetupDI();
var
   error: HResult;

begin
   error := DirectInput8Create(system.MainInstance, DIRECTINPUT_VERSION, IID_IDirectInput8A, DIInterface, Nil);

   if(error <> DI_OK) then begin
      DIInterface := nil;
      log.e('Failed to initialize DirectInput 8: ' + winos.FormatMessage(windows.DWORD(error)));
   end else
      log.v('Initialized DirectInput');
end;

function appTDirectInputControllerHandler.Add(var lpddi: TDIDeviceInstanceA): boolean;
var
   device: appTDirectInputControllerDevice;
   diDevice: IDirectInputDevice8A;

   capabilities: DIDEVCAPS;

   pc: PWideChar;

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

   {we should not handle xinput devices if XInput handler is present}
   if(appControllerWindows.XInputHandlerPresent) then begin
      StringFromCLSID(lpddi.guidProduct, pc);

      if(appControllerWindows.IsXInputDevice(pc)) then begin
         CoTaskMemFree(pc);
         exit(true);
      end;

      CoTaskMemFree(pc);
   end;

   if failed(appDirectInputControllerHandler.DIInterface.CreateDevice(lpddi.guidInstance, diDevice, nil), 'Failed to create device') then
      exit(false);

   {use generic joystick data format}
   if failed(diDevice.SetDataFormat(c_dfDIJoystick), 'Failed to set data format') then
      exit(false);

   {get device updates when in background and exclusive access when in foreground}
   if failed(diDevice.SetCooperativeLevel(0,
      DISCL_BACKGROUND or DISCL_EXCLUSIVE), 'Failed to set cooperative level') then
      exit(false);

   {get device capabilities}
   ZeroOut(capabilities, SizeOf(capabilities));

   if failed(diDevice.GetCapabilities(capabilities), 'Failed to get capabilities') then begin
      exit(false);
   end;

   device := appTDirectInputControllerDevice.Create();

   device.Name := pchar(lpddi.tszProductName);
   device.GUID := lpddi.guidInstance;
   device.FFGUID := lpddi.guidFFDriver;

   device.Device := diDevice;

   {get number of axes and buttons}
   writeln(capabilities.dwAxes, ' ', capabilities.dwButtons);

   {TODO: Get the rest of this functional}

   appControllers.Add(device);
   Result := true;
end;

procedure init();
begin
   {we can only init a directinput device when we have a window}
   appDirectInputControllerHandler.Rescan();
end;

INITIALIZATION
   appDirectInputControllerHandler.Create();
   appControllers.AddHandler(appDirectInputControllerHandler);

   ox.OnInitialize.Add('directinput', @init);

END.
