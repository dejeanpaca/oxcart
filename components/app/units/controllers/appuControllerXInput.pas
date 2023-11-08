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
      windows, JwaWinError, DX12.XInput;

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
      XPacket: dword;

      constructor Create(); override;

      procedure Initialize(index: loopint; var capabilities: TXINPUT_CAPABILITIES);
      procedure Update(); override;
      procedure DeInitialize(); override;
   end;

VAR
   appXInputControllerHandler: appTXInputControllerHandler;

IMPLEMENTATION

{ appTXInputControllerDevice }

constructor appTXInputControllerDevice.Create();
begin
   inherited Create();

   TriggerValueRange := 255;
   AxisValueRange := 32767;
   Handler := @appXInputControllerHandler;
end;

procedure appTXInputControllerDevice.Initialize(index: loopint; var capabilities: TXINPUT_CAPABILITIES);

procedure setGamepad();
begin
   AxisCount := 4;
   TriggerCount := 2;
   DPadPresent := true;
   ButtonCount := 16;
   AxisGroupCount := 2;

   {left thumbstick}
   AxisGroups[0][0] := 0;
   AxisGroups[0][1] := 1;

   {right thumbstick}
   AxisGroups[1][0] := 2;
   AxisGroups[1][1] := 3;
end;

begin
   XInputIndex := index;
   ButtonCount := PopCnt(capabilities.Gamepad.wButtons);

   if(capabilities.SubType = XINPUT_DEVSUBTYPE_GAMEPAD) then
      Name := 'XInput Gamepad ' + sf(index)
   else
      Name := 'XInput Gamepad ' + sf(index);

   setGamepad();
end;

procedure appTXInputControllerDevice.Update();
var
   i: loopint;
   bState: TBitSet16;

   xstate: TXINPUT_STATE;
   gamepad: TXINPUT_GAMEPAD;

   error: loopint;

begin
   error := XInputGetState(XInputIndex, xstate);

   {device disconnected}
   if(error = ERROR_DEVICE_NOT_CONNECTED) then begin
      Disconnected();
      exit;
   end;

   {state has not changed, do nothing}
   if(XPacket = xstate.dwPacketNumber) then
      exit;

   Updated := true;

   XPacket := xstate.dwPacketNumber;
   gamepad := xstate.Gamepad;
   bState := gamepad.wButtons;

   {get button state}
   for i := 1 to 16 do begin
      SetButtonPressedState(i - 1, bState.GetBit(16 - i));
   end;

   {setup hat state from buttons}
   if(DPadPresent) then begin
      State.DPad[appbCONTROLLER_DPAD_UP]     := State.KeyProperties[15];
      State.DPad[appbCONTROLLER_DPAD_DOWN]   := State.KeyProperties[14];
      State.DPad[appbCONTROLLER_DPAD_LEFT]   := State.KeyProperties[13];
      State.DPad[appbCONTROLLER_DPAD_RIGHT]  := State.KeyProperties[12];
   end;

   if(TriggerCount > 0) then begin
      SetTriggerState(0, gamepad.bLeftTrigger);
      SetTriggerState(1, gamepad.bRightTrigger);
   end;

   if(AxisCount > 0) then begin
      SetAxisState(0, gamepad.sThumbLX);
      SetAxisState(1, gamepad.sThumbLY);
      SetAxisState(2, gamepad.sThumbRX);
      SetAxisState(3, gamepad.sThumbRY);
   end;
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
