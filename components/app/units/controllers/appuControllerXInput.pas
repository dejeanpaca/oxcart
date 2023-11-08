{
   appuControllerXInput, xinput controller handling
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT appuControllerXInput;

INTERFACE

   USES
      uStd, uLog, StringUtils,
      appuController,
      {windows}
      windows, DX12.XInput;

TYPE
   { appTXInputControllerHandler }

   appTXInputControllerHandler = object(appTControllerHandler)
      public
         {XInput specific properties}

         {identifier}
         GUID: string;
         {is the controller a game controller (gamepad, joystick)}
         GameController: boolean;

      procedure Initialize(); virtual;
      procedure Reset(); virtual;
      procedure Run(); virtual;

      function GetName(): StdString; virtual;

      private
         function Add(index: loopint): boolean;
   end;

   { appTXInputControllerDevice }

   appTXInputControllerDevice = class(appTControllerDevice)
      XInputIndex: loopint;

      constructor Create(); override;

      procedure Initialize(index: loopint; var capabilities: TXINPUT_CAPABILITIES);
      procedure Run(); override;
      procedure DeInitialize(); override;
   end;

VAR
   appXInputControllerHandler: appTXInputControllerHandler;

IMPLEMENTATION

{ appTXInputControllerDevice }

constructor appTXInputControllerDevice.Create();
begin
  inherited Create();

  Handler := @appXInputControllerHandler;
end;

procedure appTXInputControllerDevice.Initialize(index: loopint; var capabilities: TXINPUT_CAPABILITIES);
begin
   XInputIndex := index;
   ButtonCount := PopCnt(capabilities.Gamepad.wButtons);

   if(capabilities.SubType = XINPUT_DEVSUBTYPE_GAMEPAD) then begin
      AxisCount := 4;
      TriggerCount := 2;
      HatCount := 1;
   end else
      Valid := false;

   Name := 'XInput ' + sf(index);
end;

procedure appTXInputControllerDevice.Run();
var
   xstate: TXINPUT_STATE;

begin
   XInputGetState(XInputIndex, xstate);

   // TODO: Process state
end;

procedure appTXInputControllerDevice.DeInitialize();
begin
   inherited;
end;

{ appTXInputControllerHandler }

procedure appTXInputControllerHandler.Initialize();
begin
   Reset();
end;

procedure appTXInputControllerHandler.Reset();
var
   i: loopint;

begin
   inherited;

   for i := 0 to 3 do begin
      if(not Add(i)) then begin
         if(i = 0) then
            log.v('No XInput devices detected');

         break;
      end;
   end;
end;

procedure appTXInputControllerHandler.Run();
begin
   inherited Run();
end;

function appTXInputControllerHandler.GetName(): StdString;
begin
   Result := 'XInput';
end;

function appTXInputControllerHandler.Add(index: loopint): boolean;
var
   device: appTXInputControllerDevice;
   capabilities: TXINPUT_CAPABILITIES;

begin
   if(XInputGetCapabilities(index, 0, capabilities) = ERROR_SUCCESS) then begin
      device := appTXInputControllerDevice.Create();

      device.Initialize(index, capabilities);

      appControllers.Add(device);

      log.Collapsed(device.Name);
      device.LogDevice();
      log.Leave();

      exit(true);
   end;

   Result := false;
end;

INITIALIZATION
   appXInputControllerHandler.Create();
   appControllers.AddHandler(appXInputControllerHandler);

END.
