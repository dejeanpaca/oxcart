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
   appControllerXBox360,
   appControllerXBoxOne: appTControllerDeviceMapping;

IMPLEMENTATION

procedure initialize360(out m: appTControllerDeviceMapping);
begin
   appTControllerDeviceMapping.Initialize(m);

   m.Settings.AxisCount := 4;
   m.Settings.TriggerCount := 2;
   m.Settings.AxisGroupCount := 2;
   m.Settings.DPadPresent := true;

   {$IFDEF WINDOWS}
   m.Settings.ButtonCount := 16;
   {$ENDIF}
   {$IFDEF LINUX}
   m.Settings.ButtonCount := 10;
   m.Settings.RemappedAxisCount := 8;

   m.Settings.AxisGroups[0][0] := 0;
   m.Settings.AxisGroups[0][1] := 1;

   m.Settings.AxisGroups[1][0] := 2;
   m.Settings.AxisGroups[1][1] := 3;
   {$ENDIF}

   m.Id := 'xbox360';
   m.RecognitionString := '360';

   {$IFDEF LINUX}
   {left thumbstick}
   m.AxisRemaps[1].RemapType := appCONTROLLER_AXIS_IS_INVERTED;

   {left trigger}
   m.AxisRemaps[2].RemapType := appCONTROLLER_AXIS_IS_TRIGGER;
   m.AxisRemaps[2].Index := 0;

   {right thumbstick}
   m.AxisRemaps[3].Index := 2;
   m.AxisRemaps[4].RemapType := appCONTROLLER_AXIS_IS_INVERTED;
   m.AxisRemaps[4].Index := 3;

   {right trigger}
   m.AxisRemaps[5].RemapType := appCONTROLLER_AXIS_IS_TRIGGER;
   m.AxisRemaps[5].Index := 1;

   {dpad up/down}
   m.AxisRemaps[6].RemapType := appCONTROLLER_AXIS_IS_DPAD;
   m.AxisRemaps[6].Index := 0;

   {dpad left/right}
   m.AxisRemaps[7].RemapType := appCONTROLLER_AXIS_IS_DPAD;
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

procedure initializeMappings();
begin
   initializeOne(appControllerXBoxOne);
   appControllers.AddMapping(appControllerXBoxOne);

   initialize360(appControllerXBox360);
   appControllers.AddMapping(appControllerXBox360);
end;

INITIALIZATION
   initializeMappings();

END.
