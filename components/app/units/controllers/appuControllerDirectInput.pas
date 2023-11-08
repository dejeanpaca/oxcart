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
   DIInterface.EnumDevices(DI8DEVCLASS_GAMECTRL, @diCallback, nil, DIEDFL_ATTACHEDONLY);
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

begin
   Result := false;
   error := appDirectInputControllerHandler.DIInterface.CreateDevice(lpddi.guidInstance, diDevice, nil);

   {only create our own device if DI created a device}
   if(error = DI_OK) then begin
      device := appTDirectInputControllerDevice.Create();

      device.Name := pchar(lpddi.tszProductName);
      device.GUID := lpddi.guidInstance;
      device.FFGUID := lpddi.guidFFDriver;

      appControllers.Add(device);
      Result := true;
   end else
      log.e('Failed to create DirectInput device for: ' + pchar(lpddi.tszInstanceName) + ' (' + pchar(lpddi.tszProductName) + ')');
end;

INITIALIZATION
   appDirectInputControllerHandler.Create();
   appControllers.AddHandler(appDirectInputControllerHandler);

END.
