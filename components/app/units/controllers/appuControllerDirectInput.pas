{
   appuControllerDirectInput, DirectInput controller handling
   Copyright (C) 2019. Dejan Boras
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

      private
         procedure Add();
   end;

   { appTDirectInputControllerDevice }

   appTDirectInputControllerDevice = class(appTControllerDevice)
      FileName: string;

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

function diCallback(var lpddi: TDIDeviceInstanceA; pvRef: Pointer): windows.BOOL; stdcall;
begin
   writeln('instance: ', pchar(lpddi.tszInstanceName));
   writeln('product: ', pchar(lpddi.tszProductName));

   Result := false;
end;

procedure appTDirectInputControllerHandler.Reset();
begin
   DIInterface.EnumDevices(DI8DEVCLASS_GAMECTRL, @diCallback, nil, DIEDFL_ATTACHEDONLY);
end;

procedure appTDirectInputControllerHandler.Run();
begin
   inherited Run();
end;

procedure appTDirectInputControllerHandler.Add();
var
   device: appTDirectInputControllerDevice;

begin
   device := appTDirectInputControllerDevice.Create();

   appControllers.Add(device);
end;

INITIALIZATION
   appDirectInputControllerHandler.Create();
   appControllers.AddHandler(appDirectInputControllerHandler);

END.
