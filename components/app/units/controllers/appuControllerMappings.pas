{
   appuControllerMappings, integrated mappings for various controllers
   Copyright (C) 2020. Dejan Boras

   TODO: Allow for loading custom mappings from a file
}

{$INCLUDE oxheader.inc}
UNIT appuControllerMappings;

INTERFACE

   USES
      appuController;

VAR
   {xbox 360 gamepad}
   appControllerXBox360,
   {xbox one gamepad}
   appControllerXBoxOne,
   {twin usb joystick (generic ps1/ps2 usb adapter)}
   appControllerTwinUSBJoystick: appTControllerDeviceMapping;

IMPLEMENTATION

procedure initialize360(out m: appTControllerDeviceMapping);
begin
   appTControllerDeviceMapping.Initialize(m);

   m.Settings.AxisCount := 4;
   m.Settings.TriggerCount := 2;
   m.Settings.AxisGroupCount := 2;
   m.Settings.DPadPresent := true;

   m.Id := 'xbox360';
   m.RecognitionString := '360';

   {$IFDEF WINDOWS}
   m.Settings.ButtonCount := 16;
   {$ENDIF}

   m.ButtonFunctions[0] := appCONTROLLER_A;
   m.ButtonFunctions[1] := appCONTROLLER_B;
   m.ButtonFunctions[2] := appCONTROLLER_X;
   m.ButtonFunctions[3] := appCONTROLLER_Y;

   m.ButtonFunctions[4] := appCONTROLLER_LEFT_SHOULDER;
   m.ButtonFunctions[5] := appCONTROLLER_RIGHT_SHOULDER;

   m.ButtonFunctions[6] := appCONTROLLER_BACK;
   m.ButtonFunctions[7] := appCONTROLLER_MENU;

   m.ButtonFunctions[8] := appCONTROLLER_HOME;

   m.ButtonFunctions[9] := appCONTROLLER_LEFT_STICK_CLICK;
   m.ButtonFunctions[10] := appCONTROLLER_RIGHT_STICK_CLICK;


   {$IFDEF LINUX}
   m.Settings.ButtonCount := 16;
   m.Settings.RemappedAxisCount := 8;

   m.Settings.AxisGroups[0][0] := 0;
   m.Settings.AxisGroups[0][1] := 1;

   m.Settings.AxisGroups[1][0] := 2;
   m.Settings.AxisGroups[1][1] := 3;

   {left thumbstick}
   m.AxisRemaps[1].RemapType := appCONTROLLER_AXIS_IS_INVERTED;

   {left trigger}
   m.AxisRemaps[2].RemapType := appCONTROLLER_AXIS_IS_TRIGGER;
   m.AxisRemaps[2].Index := 0;
   m.AxisRemaps[2].Func := appCONTROLLER_LEFT_TRIGGER;

   {right thumbstick}
   m.AxisRemaps[3].Index := 2;
   m.AxisRemaps[4].RemapType := appCONTROLLER_AXIS_IS_INVERTED;
   m.AxisRemaps[4].Index := 3;

   m.AxisRemaps[3].Func := appCONTROLLER_RIGHT_STICK_X;
   m.AxisRemaps[4].Func := appCONTROLLER_RIGHT_STICK_Y;

   {right trigger}
   m.AxisRemaps[5].RemapType := appCONTROLLER_AXIS_IS_TRIGGER;
   m.AxisRemaps[5].Func := appCONTROLLER_RIGHT_TRIGGER;
   m.AxisRemaps[5].Index := 1;

   {dpad up/down}
   m.AxisRemaps[6].RemapType := appCONTROLLER_AXIS_IS_DPAD;
   m.AxisRemaps[6].Func := appCONTROLLER_DPAD_UP_DOWN;
   m.AxisRemaps[6].Index := 0;

   {dpad left/right}
   m.AxisRemaps[7].RemapType := appCONTROLLER_AXIS_IS_DPAD;
   m.AxisRemaps[7].Func := appCONTROLLER_DPAD_LEFT_RIGHT;
   m.AxisRemaps[7].Index := 1;


   m.RemapAxes := true;
   {$ENDIF}
end;

procedure initializeOne(out m: appTControllerDeviceMapping);
begin
   initialize360(m);

   m.Id := 'xbox-one';
   m.RecognitionString := 'X-Box One';
end;

procedure initializeTwinUSBJoystick(out m: appTControllerDeviceMapping);
begin
   appTControllerDeviceMapping.Initialize(m);

   m.Settings.AxisCount := 4;
   m.Settings.TriggerCount := 0;
   m.Settings.ButtonCount := -1;
   m.Settings.AxisGroupCount := 2;
   m.Settings.DPadPresent := true;

   m.Id := 'twin-usb-joystick';
   m.RecognitionString := 'Twin USB Joystick';

   {$IFDEF LINUX}
   m.Settings.RemappedAxisCount := 6;
   m.RemapAxes := true;

   m.ButtonFunctions[0] := appCONTROLLER_PS_TRIANGLE;
   m.ButtonFunctions[1] := appCONTROLLER_PS_O;
   m.ButtonFunctions[2] := appCONTROLLER_PS_X;
   m.ButtonFunctions[3] := appCONTROLLER_PS_SQUARE;
   m.ButtonFunctions[4] := appCONTROLLER_LEFT_SHOULDER;
   m.ButtonFunctions[5] := appCONTROLLER_RIGHT_SHOULDER;
   m.ButtonFunctions[6] := appCONTROLLER_LEFT_TRIGGER;
   m.ButtonFunctions[7] := appCONTROLLER_RIGHT_TRIGGER;
   m.ButtonFunctions[8] := appCONTROLLER_SELECT;
   m.ButtonFunctions[9] := appCONTROLLER_START;
   m.ButtonFunctions[10] := appCONTROLLER_LEFT_STICK_CLICK;
   m.ButtonFunctions[11] := appCONTROLLER_RIGHT_STICK_CLICK;

   m.AxisRemaps[0].Func := appCONTROLLER_LEFT_STICK_X;

   m.AxisRemaps[1].RemapType := appCONTROLLER_AXIS_IS_INVERTED;
   m.AxisRemaps[1].Func := appCONTROLLER_LEFT_STICK_Y;

   {for some reason, the right thumbstick has X/Y axes swapped}
   m.AxisRemaps[2].RemapType := appCONTROLLER_AXIS_IS_INVERTED;
   m.AxisRemaps[2].Index := 3;

   m.AxisRemaps[3].Index := 2;

   {dpad left/right}
   m.AxisRemaps[4].RemapType := appCONTROLLER_AXIS_IS_DPAD;
   m.AxisRemaps[4].Index := 0;
   {dpad up/down}
   m.AxisRemaps[5].RemapType := appCONTROLLER_AXIS_IS_DPAD;
   m.AxisRemaps[5].Index := 0;
   {$ENDIF}
end;

procedure initializeMappings();
begin
   initializeOne(appControllerXBoxOne);
   appControllers.AddMapping(appControllerXBoxOne);

   initialize360(appControllerXBox360);
   appControllers.AddMapping(appControllerXBox360);

   initializeTwinUSBJoystick(appControllerTwinUSBJoystick);
   appControllers.AddMapping(appControllerTwinUSBJoystick);
end;

INITIALIZATION
   initializeMappings();

END.
