{
   appuControllerXInput, xinput controller handling
   Copyright (C) 2019. Dejan Boras

   Started On:    19.09.2019.
}

{$INCLUDE oxdefines.inc}
UNIT appuControllerXInput;

INTERFACE

   USES
      uStd, uLog, StringUtils,
      appuController,
      {windows}
      windows, DX12.xinput;

TYPE

   { appTXInputControllerHandler }

   appTXInputControllerHandler = class(appTControllerHandler)
      public
         {XInput specific properties}

         {identifier}
         GUID: string;
         {is the controller a game controller (gamepad, joystick)}
         GameController: boolean;

      procedure Initialize(); override;
      procedure Reset(); override;
      procedure Run(); override;

      private
         function Add(index: loopint): boolean;
   end;

   { appTXInputControllerDevice }

   appTXInputControllerDevice = class(appTControllerDevice)
      XInputIndex: loopint;

      procedure Initialize(index: loopint; var capabilities: TXINPUT_CAPABILITIES);
      procedure Run(); override;
      procedure DeInitialize(); override;
   end;

IMPLEMENTATION

{ appTXInputControllerDevice }

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
   appControllerHandler := appTXInputControllerHandler.Create();

END.
