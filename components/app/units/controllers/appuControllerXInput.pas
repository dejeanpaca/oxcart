{
   appuControllerXInput, xinput controller handling
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT appuControllerXInput;

INTERFACE

   USES
      uStd, uLog, StringUtils,
      {app}
      appuController, appuControllers, appuControllerWindows,
      {windows}
      windows, JwaWinError, DX12.XInput;

TYPE
   { appTXInputControllerDevice }

   appTXInputControllerDevice = class(appTControllerDevice)
      XInputIndex: loopint;
      XPacket: dword;

      constructor Create(); override;

      procedure Initialize(index: loopint; var capabilities: TXINPUT_CAPABILITIES);
      procedure Update(); override;
      procedure DeInitialize(); override;
   end;

   { appTXInputControllerHandler }

   appTXInputControllerHandler = object(appTControllerHandler)
      public
         {XInput specific properties}

         {identifier}
         GUID: string;
         {is the controller a game controller (gamepad, joystick)}
         GameController: boolean;

      procedure Scan(); virtual;
      procedure Rescan(); virtual;

      function GetName(): StdString; virtual;

      private
         function Add(index: loopint): boolean;
         function FindByXIndex(index: loopint): appTXInputControllerDevice;
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
   Settings.AxisCount := 4;
   Settings.TriggerCount := 2;
   Settings.DPadPresent := true;
   Settings.ButtonCount := 16;
   Settings.AxisGroupCount := 2;

   {left thumbstick}
   Settings.AxisGroups[0][0] := 0;
   Settings.AxisGroups[0][1] := 1;

   {right thumbstick}
   Settings.AxisGroups[1][0] := 2;
   Settings.AxisGroups[1][1] := 3;
end;

begin
   XInputIndex := index;
   Settings.ButtonCount := PopCnt(capabilities.Gamepad.wButtons);

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
   if(Settings.DPadPresent) then begin
      State.DPad[appbCONTROLLER_DPAD_UP]     := State.KeyProperties[15];
      State.DPad[appbCONTROLLER_DPAD_DOWN]   := State.KeyProperties[14];
      State.DPad[appbCONTROLLER_DPAD_LEFT]   := State.KeyProperties[13];
      State.DPad[appbCONTROLLER_DPAD_RIGHT]  := State.KeyProperties[12];
   end;

   if(Settings.TriggerCount > 0) then begin
      SetTriggerState(0, gamepad.bLeftTrigger);
      SetTriggerState(1, gamepad.bRightTrigger);
   end;

   if(Settings.AxisCount > 0) then begin
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

procedure appTXInputControllerHandler.Scan();
begin
   Rescan();
end;

procedure appTXInputControllerHandler.Rescan();
var
   i: loopint;

begin
   for i := 0 to 3 do begin
      if FindByXIndex(i) = nil then begin
         if(not Add(i)) then
            break;
      end;
   end;
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

      exit(true);
   end;

   Result := false;
end;

function appTXInputControllerHandler.FindByXIndex(index: loopint): appTXInputControllerDevice;
var
   i: loopint;

begin
   for i := 0 to appControllers.List.n - 1 do begin
      if(appControllers.List[i].ClassType = appTXInputControllerDevice.ClassType) then begin
         if(appTXInputControllerDevice(appControllers.List[i]).XInputIndex = index) then
            exit(appTXInputControllerDevice(appControllers.List[i]));
      end;
   end;

   Result := nil;
end;

INITIALIZATION
   appControllerWindows.XInputHandlerPresent := true;
   appXInputControllerHandler.Create();
   appControllers.AddHandler(appXInputControllerHandler);

END.
