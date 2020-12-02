{
   appuController, input controller(gamepad, joystick) handling
   Copyright (C) 2016. Dejan Boras

   Axes are mapped from -1.0 to +1.0
   Triggers are mapped from 0.0 to +1.0
   DPad is assumed to have up/down/left/right buttons (other directions are combined from this)
   Axis groups combine two axes for an X/Y with -1.0 .. 1.0 values assumed left to right, and down to up

   TODO: Implement force feedback support
}

{$INCLUDE oxheader.inc}
UNIT appuController;

INTERFACE

   USES
      uStd, uLog, StringUtils, vmMath, vmVector, uTiming,
      {app}
      uApp, appuEvents, appuInputTypes,
      {ox}
      oxuRunRoutines, oxuRun;

TYPE
   appTControllerFunctionDescriptor = record
      Name: string;
      MappedFunction: longint;
   end;

CONST
   {controller direction}
   appCONTROLLER_DIRECTION_NONE        = 0;

   appCONTROLLER_DIRECTION_UP          = 1;
   appCONTROLLER_DIRECTION_DOWN        = 2;
   appCONTROLLER_DIRECTION_LEFT        = 4;
   appCONTROLLER_DIRECTION_RIGHT       = 8;

   appCONTROLLER_DIRECTION_UP_LEFT     = appCONTROLLER_DIRECTION_UP or appCONTROLLER_DIRECTION_LEFT;
   appCONTROLLER_DIRECTION_UP_RIGHT    = appCONTROLLER_DIRECTION_UP or appCONTROLLER_DIRECTION_RIGHT;
   appCONTROLLER_DIRECTION_DOWN_LEFT   = appCONTROLLER_DIRECTION_DOWN or appCONTROLLER_DIRECTION_LEFT;
   appCONTROLLER_DIRECTION_DOWN_RIGHT  = appCONTROLLER_DIRECTION_DOWN or appCONTROLLER_DIRECTION_RIGHT;

   {dpad buttons}
   appbCONTROLLER_DPAD_UP     = 0;
   appbCONTROLLER_DPAD_RIGHT  = 1;
   appbCONTROLLER_DPAD_DOWN   = 2;
   appbCONTROLLER_DPAD_LEFT   = 3;

   {controller functions}

   {no mapped function}
   appCONTROLLER_NONE = 0;

   {directional buttons}
   appCONTROLLER_DPAD_UP               = 1;
   appCONTROLLER_DPAD_DOWN             = 2;
   appCONTROLLER_DPAD_LEFT             = 3;
   appCONTROLLER_DPAD_RIGHT            = 4;

   {combined directions}
   appCONTROLLER_DPAD_UP_DOWN          = 5;
   appCONTROLLER_DPAD_LEFT_RIGHT       = 6;

   {buttons}
   appCONTROLLER_A                     = 5;
   appCONTROLLER_PS_X                  = 5;
   appCONTROLLER_B                     = 6;
   appCONTROLLER_PS_O                  = 6;
   appCONTROLLER_X                     = 7;
   appCONTROLLER_PS_SQUARE             = 7;
   appCONTROLLER_Y                     = 8;
   appCONTROLLER_PS_TRIANGLE           = 8;

   appCONTROLLER_BACK                  = 9;
   appCONTROLLER_SELECT                = 9;
   appCONTROLLER_START                 = 10;
   appCONTROLLER_MENU                  = 10;
   appCONTROLLER_HOME                  = 11;

   appCONTROLLER_LEFT_SHOULDER         = 12;
   appCONTROLLER_L1                    = 12;
   appCONTROLLER_RIGHT_SHOULDER        = 13;
   appCONTROLLER_R1                    = 13;

   appCONTROLLER_LEFT_STICK_CLICK      = 14;
   appCONTROLLER_LEFT_STICK_X          = 15;
   appCONTROLLER_LEFT_STICK_Y          = 16;

   appCONTROLLER_RIGHT_STICK_X         = 17;
   appCONTROLLER_RIGHT_STICK_Y         = 18;
   appCONTROLLER_RIGHT_STICK_CLICK     = 19;

   appCONTROLLER_LEFT_TRIGGER          = 20;
   appCONTROLLER_L2                    = 20;
   appCONTROLLER_RIGHT_TRIGGER         = 21;
   appCONTROLLER_R2                    = 21;

   {namings for functions}
   appCONTROLLER_FUNCTIONS: array[0..41] of appTControllerFunctionDescriptor = (
      (Name: 'none'; MappedFunction: appCONTROLLER_NONE),

      (Name: 'dpad_up'; MappedFunction: appCONTROLLER_DPAD_UP),
      (Name: 'dpad_down'; MappedFunction: appCONTROLLER_DPAD_DOWN),
      (Name: 'dpad_left'; MappedFunction: appCONTROLLER_DPAD_LEFT),
      (Name: 'dpad_right'; MappedFunction: appCONTROLLER_DPAD_RIGHT),

      (Name: 'up'; MappedFunction: appCONTROLLER_DPAD_UP),
      (Name: 'down'; MappedFunction: appCONTROLLER_DPAD_DOWN),
      (Name: 'left'; MappedFunction: appCONTROLLER_DPAD_LEFT),
      (Name: 'right'; MappedFunction: appCONTROLLER_DPAD_RIGHT),

      (Name: 'a'; MappedFunction: appCONTROLLER_A),
      (Name: 'b'; MappedFunction: appCONTROLLER_B),
      (Name: 'x'; MappedFunction: appCONTROLLER_X),
      (Name: 'y'; MappedFunction: appCONTROLLER_Y),

      (Name: 'ps_x'; MappedFunction: appCONTROLLER_A),
      (Name: 'ps_circle'; MappedFunction: appCONTROLLER_B),
      (Name: 'ps_square'; MappedFunction: appCONTROLLER_X),
      (Name: 'ps_triangle'; MappedFunction: appCONTROLLER_Y),

      (Name: 'back'; MappedFunction: appCONTROLLER_BACK),
      (Name: 'select'; MappedFunction: appCONTROLLER_BACK),
      (Name: 'start'; MappedFunction: appCONTROLLER_START),
      (Name: 'home'; MappedFunction: appCONTROLLER_HOME),
      (Name: 'guide'; MappedFunction: appCONTROLLER_HOME),

      (Name: 'left_shoulder'; MappedFunction: appCONTROLLER_LEFT_SHOULDER),
      (Name: 'right_shoulder'; MappedFunction: appCONTROLLER_RIGHT_SHOULDER),

      (Name: 'r1'; MappedFunction: appCONTROLLER_LEFT_SHOULDER),
      (Name: 'r2'; MappedFunction: appCONTROLLER_RIGHT_SHOULDER),

      (Name: 'left_stick_click'; MappedFunction: appCONTROLLER_LEFT_STICK_CLICK),
      (Name: 'l3'; MappedFunction: appCONTROLLER_LEFT_STICK_CLICK),
      (Name: 'left_stick_x'; MappedFunction: appCONTROLLER_LEFT_STICK_X),
      (Name: 'left_stick_y'; MappedFunction: appCONTROLLER_LEFT_STICK_Y),
      (Name: 'left_x'; MappedFunction: appCONTROLLER_LEFT_STICK_X),
      (Name: 'left_y'; MappedFunction: appCONTROLLER_LEFT_STICK_Y),

      (Name: 'right_stick_click'; MappedFunction: appCONTROLLER_RIGHT_STICK_CLICK),
      (Name: 'l3'; MappedFunction: appCONTROLLER_RIGHT_STICK_CLICK),
      (Name: 'right_stick_x'; MappedFunction: appCONTROLLER_RIGHT_STICK_X),
      (Name: 'right_stick_y'; MappedFunction: appCONTROLLER_RIGHT_STICK_Y),
      (Name: 'right_x'; MappedFunction: appCONTROLLER_RIGHT_STICK_X),
      (Name: 'right_y'; MappedFunction: appCONTROLLER_RIGHT_STICK_Y),

      (Name: 'left_trigger'; MappedFunction: appCONTROLLER_LEFT_TRIGGER),
      (Name: 'right_trigger'; MappedFunction: appCONTROLLER_RIGHT_TRIGGER),
      (Name: 'l2'; MappedFunction: appCONTROLLER_LEFT_TRIGGER),
      (Name: 'r2'; MappedFunction: appCONTROLLER_RIGHT_TRIGGER)
   );

   {maximum number of controller handlers}
   appMAX_CONTROLLER_HANDLERS = 4;

   {maximum number of buttons supported}
   appMAX_CONTROLLER_BUTTONS = 32;
   {maximum number of axes supported}
   appMAX_CONTROLLER_AXES = 16;
   {maximum number of triggers supported}
   appMAX_CONTROLLER_TRIGGERS = 8;
   {maximum number of axis groups}
   appMAX_CONTROLLER_AXIS_GROUPS = 8;

TYPE
   appTControllerEventType = (
      appCONTROLLER_EVENT_BUTTON,
      appCONTROLLER_EVENT_AXIS,
      appCONTROLLER_EVENT_TRIGGER
   );

   appTControllerInputFunction = loopint;

   {what does an axis represent}
   appTControllerAxisRemapType = (
      {it's an actual axis}
      appCONTROLLER_AXIS_IS_AXIS,
      {the axis has an inverted direction}
      appCONTROLLER_AXIS_IS_INVERTED,
      {this is actually a trigger}
      appCONTROLLER_AXIS_IS_TRIGGER,
      {axis is actually a dpad}
      appCONTROLLER_AXIS_IS_DPAD
   );

   {remap for an individual axis}
   appTControllerAxisRemap = record
      {remap to which axis/trigger/dpad index}
      Index: loopint;
      {type of remap}
      RemapType: appTControllerAxisRemapType;
      {axis function}
      Func: loopint;
   end;

   appPControllerDeviceMapping = ^appTControllerDeviceMapping;

   appTControllerDeviceSettings = record
      {how many axes this device has}
      AxisCount,
      {how many buttons this device has}
      ButtonCount,
      {how many triggers this device has}
      TriggerCount,
      {how many remapped axes we have}
      RemappedAxisCount,
      {number of axis groups}
      AxisGroupCount: loopint;

      {axis groups with X/Y coordinates (thumbsticks)}
      AxisGroups: array[0..appMAX_CONTROLLER_AXIS_GROUPS] of appiTAxisGroup;

      {is the dpad present}
      DPadPresent: boolean;
   end;

   {controller mapping, represents a specific type of controller (xbox, ps)}

   { appTControllerDeviceMapping }

   appTControllerDeviceMapping = record
      {Id}
      Id,
      {string used to recognize this device (from the controller device name)}
      RecognitionString: StdString;

      {device settings for this mapping}
      Settings: appTControllerDeviceSettings;

      {should we remap axes (if true, also need to set RemappedAxisCount to the proper value)}
      RemapAxes: boolean;

      {axis remappings, to invert axes or convert to trigger or dpad}
      AxisRemaps: array[0..appMAX_CONTROLLER_AXES - 1] of appTControllerAxisRemap;
      {button functions}
      ButtonFunctions: array[0..appMAX_CONTROLLER_BUTTONS - 1] of appTControllerInputFunction;

      {next mapping in the mappings list}
      Next: appPControllerDeviceMapping;

      class procedure Initialize(out m: appTControllerDeviceMapping); static;
   end;

   { appTControllerDevice }

   appTControllerDevice = class
      {device name}
      Name: string;

      {counts of axes and buttons}
      DeviceIndex,
      {trigger value range}
      TriggerValueRange,
      {axis value range}
      AxisValueRange: longint;

      {dead zone for axis}
      DeadZone,
      {dead zone for trigger}
      TriggerDeadZone: single;
      {stretch non dead zone value to full range}
      DeadZoneStretch,
      {stretch trigger non dead zone value to full range}
      TriggerDeadZoneStretch: boolean;

      Settings: appTControllerDeviceSettings;

      {has the device state been updated}
      Updated,
      {is the device valid (present)}
      Valid: boolean;

      {mapping for this device (if no mapping this should point to generic map)}
      Mapping: appPControllerDeviceMapping;

      State: record
         {pressed state of all buttons, max 64 supported}
         KeyState: TBitSet64;
         {more detailed key state}
         Keys: appiTKeyStates;
         {detailed dpad key state}
         DPadKeys: appiTKeyStates;

         {dpad state}
         DPad: array[0..3] of appiTKeyState;
         {key properties}
         KeyProperties: array[0..appMAX_CONTROLLER_BUTTONS] of appiTKeyState;
         {state of all axes}
         Triggers: array[0..appMAX_CONTROLLER_AXES - 1] of appiTAxisState;
         {state of all axes}
         Axes: array[0..appMAX_CONTROLLER_AXES - 1] of appiTAxisState;
      end;

      Handler: POObject;

      constructor Create(); virtual;

      {log device properties}
      procedure LogDevice(); virtual;
      procedure DeInitialize(); virtual;

      {prepare state to update this device}
      procedure UpdateStart();
      {run individual devices (input collection, connection detection, ...)}
      procedure Update(); virtual;

      {called when the device is disconnected}
      procedure Disconnected();

      {get name of the device}
      function GetName(): string;
      {get the id of the device mapping}
      function GetMappingId(): string;

      {get button pressure (how pressed it is)}
      function GetButtonPressure(index: loopint): single;
      {is a button pressed}
      function IsButtonPressed(index: loopint): boolean;
      {is a dpad button pressed}
      function IsDPadPressed(direction: loopint): boolean;
      {get axis value}
      function GetAxisValue(index: loopint): single;
      {get axis value}
      function GetUnitAxisValue(index: loopint): single;
      {get trigger value}
      function GetTriggerValue(index: loopint): single;

      {get normalized value for axis}
      function GetNormalizedAxisTriggerValue(value: single; dZ: single; stretch: boolean): appiTAxisState;

      {get normalized value for axis}
      function GetNormalizedAxisValue(rawValue: loopint): appiTAxisState;
      {get normalized value for axis ()}
      function GetNormalizedAxisValue(value: single): appiTAxisState;

      {get normalized value for trigger}
      function GetNormalizedTriggerValue(rawValue: loopint): appiTAxisState;
      {get normalized value for trigger}
      function GetNormalizedTriggerValue(value: single): appiTAxisState;

      {set the pressed state of a button}
      procedure SetButtonPressedState(index: loopint; pressed: boolean);
      {set the pressed state of a trigger}
      procedure SetTriggerState(index: loopint; raw: loopint);
      {set the state of an axis}
      procedure SetAxisState(index: loopint; raw: loopint);
      {set dpad pressed state}
      procedure SetDPadPressed(button: loopint; pressed: boolean);

      {get direction of the dpad}
      function GetDPadDirection(): loopint;
      {get the dpad direction vector for a given direction}
      class function GetDPadDirectionVector(direction: loopint): TVector2;
      {get the dpad direction vector for this device}
      function GetDPadDirectionVector(): TVector2;

      {get vector for an axis group (unnormalized position)}
      function GetAxisGroupVector(group: loopint): TVector2;
      {get direction vector for an axis group (normalized to unit length)}
      function GetAxisGroupDirectionVector(group: loopint): TVector2;
      {get direction vector magnitude (0.0 - 1.0)}
      function GetAxisGroupDirectionMagnitude(group: loopint): single;
   end;

   { appTControllerEvent }

   appTControllerEvent = record
      Device: appTControllerDevice;
      Typ: appTControllerEventType;

      {button/axis/trigger number}
      KeyCode: loopint;
      {key value (non-zero means pressed)}
      Value: single;
      {which keys are being currently held}
      KeyState: TBitSet;

      {function to which this button/trigger/axis is mapped}
      MappedFunction: longint;

      {device associated with this event}
      Controller: appTControllerDevice;
   end;

   appTControllerDeviceList = specialize TSimpleList<appTControllerDevice>;

   appTOnControllerEventRoutine = procedure(var ev: appTControllerEvent);
   appTOnControllerEventRoutines = specialize TSimpleList<appTOnControllerEventRoutine>;

   { appTOnControllerEventRoutinesHelper }

   appTOnControllerEventRoutinesHelper = record helper for appTOnControllerEventRoutines
      procedure Call(var ev: appTControllerEvent);
   end;


VAR
   {generic device mapping }
   appControllerDeviceGenericMapping: appTControllerDeviceMapping;


IMPLEMENTATION

{ appTControllerDeviceMapping }

class procedure appTControllerDeviceMapping.Initialize(out m: appTControllerDeviceMapping);
begin
   m := appControllerDeviceGenericMapping;
   m.Settings.ButtonCount := -1;
end;

{ appTOnControllerEventRoutinesHelper }

procedure appTOnControllerEventRoutinesHelper.Call(var ev: appTControllerEvent);
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      List[i](ev);
   end;
end;


{ appTControllerDevice }

constructor appTControllerDevice.Create();
begin
   Valid := true;
   DeviceIndex := -1;
   DeadZone := 0.15;
   DeadZoneStretch := true;
   TriggerDeadZone := 0.15;
   TriggerDeadZoneStretch := true;
   TriggerValueRange := 32767;

   Mapping := @appControllerDeviceGenericMapping;

   State.Keys.SetupKeys(appMAX_CONTROLLER_BUTTONS, @State.KeyProperties);
   State.DPadKeys.SetupKeys(4, @State.DPad);
end;

procedure appTControllerDevice.LogDevice();
begin
   log.i('Button count: ' + sf(Settings.ButtonCount));
   log.i('Axis count: ' + sf(Settings.AxisCount));
   log.i('Trigger count: ' + sf(Settings.TriggerCount));
   log.i('DPad prsent: ' + sf(Settings.DPadPresent));
end;

procedure appTControllerDevice.DeInitialize();
begin

end;

procedure appTControllerDevice.UpdateStart();
begin
   State.Keys.UpdateCycle();
   State.DPadKeys.UpdateCycle();
   Updated := false;
end;

procedure appTControllerDevice.Update();
begin

end;

procedure appTControllerDevice.Disconnected();
begin
   log.w('Input controller device seems disconnected: ' + Name);
   Valid := false;

   {disable events associated with this device, as it may be removed}
   appEvents.DisableWithExternalData(Self);
end;

function appTControllerDevice.GetName(): string;
begin
   if(Name <> '') then
      Result := Name
   else
      Result := 'Unknown';
end;

function appTControllerDevice.GetMappingId(): string;
begin
   if(Mapping <> @appControllerDeviceGenericMapping) then
      Result := Mapping^.Id
   else
      Result := '';
end;

function appTControllerDevice.GetButtonPressure(index: loopint): single;
begin
   Result := 0;

   if(index >= 0) and (index < Settings.ButtonCount) then begin
      if(State.KeyState.GetBit(index)) then
         Result := 1.0;
   end;
end;

function appTControllerDevice.IsButtonPressed(index: loopint): boolean;
begin
   Result := false;

   if(index > 0) and (index < Settings.ButtonCount) then begin
      if(State.KeyState.GetBit(index)) then
         Result := true;
   end;
end;

function appTControllerDevice.IsDPadPressed(direction: loopint): boolean;
begin
   Result := State.DPad[direction].IsSet(kpPRESSED);
end;

function appTControllerDevice.GetAxisValue(index: loopint): single;
begin
   Result := 0;

   if(index >= 0) and (index < Settings.AxisCount) then
      Result := GetNormalizedAxisValue(State.Axes[index]);
end;

function appTControllerDevice.GetUnitAxisValue(index: loopint): single;
begin
   Result := 0.5;

   if(index >= 0) and (index < Settings.AxisCount) then
      Result := GetNormalizedAxisValue(State.Axes[index]) + 1.0 / 2;
end;

function appTControllerDevice.GetTriggerValue(index: loopint): single;
begin
   Result := 0;

   if(index >= 0) and (index < Settings.TriggerCount) then
      Result := GetNormalizedTriggerValue(State.Triggers[index]);
end;

function appTControllerDevice.GetNormalizedAxisTriggerValue(value: single; dZ: single; stretch: boolean): appiTAxisState;
begin
   Result := abs(value);

   {dead zone means 0}
   if(Result < dZ) then begin
      Result := 0;
   end else begin
      {correct for strech}
      if(stretch) then
         Result := (1 / (1 - dZ)) * (Result - dZ);
   end;

   {clamp value so we don't go out of bounds}
   vmClamp(Result, 0.0, 1.0);

   {we convert to negative value if raw value was negative}
   if(value < 0) then
      Result := -Result;
end;

function appTControllerDevice.GetNormalizedAxisValue(rawValue: loopint): appiTAxisState;
begin
   Result := appiTAxisState.GetRaw(abs(rawValue), AxisValueRange);
   Result := GetNormalizedAxisValue(Result);
end;

function appTControllerDevice.GetNormalizedAxisValue(value: single): appiTAxisState;
begin
   Result := GetNormalizedAxisTriggerValue(value, DeadZone, DeadZoneStretch);
end;

function appTControllerDevice.GetNormalizedTriggerValue(rawValue: loopint): appiTAxisState;
begin
   Result := appiTAxisState.GetRaw(abs(rawValue), TriggerValueRange);
   Result := GetNormalizedTriggerValue(Result);
end;

function appTControllerDevice.GetNormalizedTriggerValue(value: single): appiTAxisState;
begin
   Result := GetNormalizedAxisTriggerValue(value, TriggerDeadZone, TriggerDeadZoneStretch);
end;

procedure appTControllerDevice.SetButtonPressedState(index: loopint; pressed: boolean);
begin
   if(index >= 0) and (index < Settings.ButtonCount) then begin
      if(pressed) then
         State.KeyState.SetBit(index)
      else
         State.KeyState.ClearBit(index);

      State.Keys.Process(index, pressed);
   end;
end;

procedure appTControllerDevice.SetTriggerState(index: loopint; raw: loopint);
begin
   if(index >= 0) and (index < Settings.TriggerCount) then begin
      State.Triggers[index].AssignRaw(raw, TriggerValueRange);
      vmClamp(State.Triggers[index], -1.0, 1.0);
   end;
end;

procedure appTControllerDevice.SetAxisState(index: loopint; raw: loopint);
var
   rm: appTControllerAxisRemap;
   pressed: boolean;

begin
   if(Mapping^.RemapAxes) then begin
      {nothing to do here}
      if(index < 0) or (index >= Settings.RemappedAxisCount) then
         exit();

      rm := Mapping^.AxisRemaps[index];

      {remap axis to axis}
      if(rm.RemapType = appCONTROLLER_AXIS_IS_AXIS) then begin
         State.Axes[rm.Index].AssignRaw(raw, AxisValueRange);
         vmClamp(State.Axes[rm.Index], -1.0, 1.0);
      {remap inverted axis to axis}
      end else if(rm.RemapType = appCONTROLLER_AXIS_IS_INVERTED) then begin
         State.Axes[rm.Index].AssignRaw(-raw, AxisValueRange);
         vmClamp(State.Axes[rm.Index], -1.0, 1.0);
      {axis is actually a trigger}
      end else if(rm.RemapType = appCONTROLLER_AXIS_IS_TRIGGER) then begin
         raw := (raw + AxisValueRange) div 2;
         SetTriggerState(rm.Index, raw);
      {the axis is a dpad axis}
      end else if(rm.RemapType = appCONTROLLER_AXIS_IS_DPAD) then begin
         pressed := raw <> 0;

         if(rm.Index = 0) then begin
            if(raw < 0) then
               SetDPadPressed(appbCONTROLLER_DPAD_UP, pressed)
            else if(raw > 0) then
               SetDPadPressed(appbCONTROLLER_DPAD_DOWN, pressed);
         end else if(rm.Index = 1) then begin
            if(raw < 0) then
               SetDPadPressed(appbCONTROLLER_DPAD_LEFT, pressed)
            else if(raw > 0) then
               SetDPadPressed(appbCONTROLLER_DPAD_RIGHT, pressed);
         end;
      end;
   end else begin
      if(index >= 0) and (index < Settings.AxisCount) then begin
         State.Axes[index].AssignRaw(raw, AxisValueRange);
         vmClamp(State.Axes[index], -1.0, 1.0);
      end;
   end;
end;

procedure appTControllerDevice.SetDPadPressed(button: loopint; pressed: boolean);
begin
   State.DPadKeys.Process(button, pressed);
end;

function appTControllerDevice.GetDPadDirection(): loopint;
begin
   Result := 0;

   if(Settings.DPadPresent) then begin
      if(IsDPadPressed(appbCONTROLLER_DPAD_UP)) then begin
         Result := appCONTROLLER_DIRECTION_UP;

         if(IsDPadPressed(appbCONTROLLER_DPAD_LEFT)) then
            Result := appCONTROLLER_DIRECTION_UP_LEFT
         else if(IsDPadPressed(appbCONTROLLER_DPAD_RIGHT)) then
            Result := appCONTROLLER_DIRECTION_UP_RIGHT;
      end else if(IsDPadPressed(appbCONTROLLER_DPAD_DOWN)) then begin
         Result := appCONTROLLER_DIRECTION_DOWN;

         if(IsDPadPressed(appbCONTROLLER_DPAD_LEFT)) then
            Result := appCONTROLLER_DIRECTION_DOWN_LEFT
         else if(IsDPadPressed(appbCONTROLLER_DPAD_RIGHT)) then
            Result := appCONTROLLER_DIRECTION_DOWN_RIGHT;
      end else if(IsDPadPressed(appbCONTROLLER_DPAD_LEFT)) then
         Result := appCONTROLLER_DIRECTION_LEFT
      else if(IsDPadPressed(appbCONTROLLER_DPAD_RIGHT)) then
         Result := appCONTROLLER_DIRECTION_RIGHT;
   end;
end;

class function appTControllerDevice.GetDPadDirectionVector(direction: loopint): TVector2;
var
   v: TVector2;

begin
   if(direction <> appCONTROLLER_DIRECTION_NONE) then begin
      v := vmvZero2;

      if(direction and appCONTROLLER_DIRECTION_UP > 0) then
         v[1] := +1;

      if(direction and appCONTROLLER_DIRECTION_DOWN > 0) then
         v[1] := -1;

      if(direction and appCONTROLLER_DIRECTION_LEFT > 0) then
         v[0] := -1;

      if(direction and appCONTROLLER_DIRECTION_RIGHT > 0) then
         v[0] := +1;

      Result := v.Normalized();
   end else
      Result := vmvZero2;
end;

function appTControllerDevice.GetDPadDirectionVector(): TVector2;
var
   direction: loopint;

begin
   direction := GetDPadDirection();
   Result := GetDPadDirectionVector(direction);
end;

function appTControllerDevice.GetAxisGroupVector(group: loopint): TVector2;
var
   axisGroup: appiTAxisGroup;

begin
   Result := vmvZero2;

   if(group >= 0) and (group < Settings.AxisGroupCount) then begin
      axisGroup := Settings.AxisGroups[group];

      Result[0] := GetNormalizedAxisValue(State.Axes[axisGroup[0]]);
      Result[1] := GetNormalizedAxisValue(State.Axes[axisGroup[1]]);
   end;
end;

function appTControllerDevice.GetAxisGroupDirectionVector(group: loopint): TVector2;
begin
   Result := vmvZero2;

   if(group >= 0) and (group < Settings.AxisGroupCount) then
      Result := GetAxisGroupVector(group).Normalized();
end;

function appTControllerDevice.GetAxisGroupDirectionMagnitude(group: loopint): single;
begin
   Result := 0;

   if(group >= 0) and (group < Settings.AxisGroupCount) then
      Result := GetAxisGroupVector(group).Magnitude();
end;

procedure initializeGenericMapping(var m: appTControllerDeviceMapping);
var
   i: loopint;

begin
   ZeroOut(m, SizeOf(m));

   for i := 0 to appMAX_CONTROLLER_AXES - 1 do begin
      m.AxisRemaps[i].RemapType := appCONTROLLER_AXIS_IS_AXIS;
      m.AxisRemaps[i].Index := i;
   end;

   m.Settings.DPadPresent := true;

   m.Settings.AxisGroupCount := 2;

   m.Settings.AxisGroups[0][0] := 0;
   m.Settings.AxisGroups[0][1] := 1;

   m.Settings.AxisGroups[1][0] := 2;
   m.Settings.AxisGroups[1][1] := 3;

   m.AxisRemaps[0].Func := appCONTROLLER_LEFT_STICK_X;
   m.AxisRemaps[1].Func := appCONTROLLER_LEFT_STICK_Y;

   m.AxisRemaps[2].Func := appCONTROLLER_RIGHT_STICK_X;
   m.AxisRemaps[3].Func := appCONTROLLER_RIGHT_STICK_Y;
end;

INITIALIZATION
   {initialize generic mapping}
   initializeGenericMapping(appControllerDeviceGenericMapping);

END.
