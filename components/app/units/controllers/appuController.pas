{
   appuController, input controller(gamepad, joystick) handling
   Copyright (C) 2016. Dejan Boras

   Started On:    08.09.2016.

   Axes are mapped from -1.0 to +1.0
}

{$INCLUDE oxdefines.inc}
UNIT appuController;

INTERFACE

   USES
      uStd, uLog, StringUtils,
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
   {no mapped function}
   appCONTROLLER_NONE = 0;

   {directional buttons}
   appCONTROLLER_DPAD_UP               = 1;
   appCONTROLLER_DPAD_DOWN             = 2;
   appCONTROLLER_DPAD_LEFT             = 3;
   appCONTROLLER_DPAD_RIGHT            = 4;

   appCONTROLLER_A                     = 5;
   appCONTROLLER_B                     = 6;
   appCONTROLLER_X                     = 7;
   appCONTROLLER_Y                     = 8;

   appCONTROLLER_BACK                  = 9;
   appCONTROLLER_START                 = 10;
   appCONTROLLER_HOME                  = 11;

   appCONTROLLER_LEFT_SHOULDER         = 12;
   appCONTROLLER_RIGHT_SHOULDER        = 13;

   appCONTROLLER_LEFT_STICK_CLICK      = 14;
   appCONTROLLER_LEFT_STICK_X          = 15;
   appCONTROLLER_LEFT_STICK_Y          = 16;

   appCONTROLLER_RIGHT_STICK_X         = 17;
   appCONTROLLER_RIGHT_STICK_Y         = 18;
   appCONTROLLER_RIGHT_STICK_CLICK     = 19;

   appCONTROLLER_LEFT_TRIGGER          = 20;
   appCONTROLLER_RIGHT_TRIGGER         = 21;

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

TYPE
   appTControllerEventType = (
      appCONTROLLER_EVENT_BUTTON,
      appCONTROLLER_EVENT_AXIS,
      appCONTROLLER_EVENT_TRIGGER
   );

   { appTControllerDevice }

   appTControllerDevice = class
      {device name}
      Name: string;

      {counts of axes and buttons}
      DeviceIndex,
      AxisCount,
      TriggerCount,
      HatCount,
      ButtonCount: longint;

      {dead zone for axis/trigger}
      DeadZone: single;
      DeadZoneStretch: boolean;

      {is the device valid (present)}
      Valid: boolean;

      State: record
         {state of all buttons, max 64 supported}
         KeyState: TBitSet64;
         {more detailed key state}
         Keys: appiTKeyStates;
         KeyProperties: array[0..appMAX_CONTROLLER_BUTTONS] of appiTKeyState;
         {state of all axes}
         Triggers: array[0..appMAX_CONTROLLER_AXES - 1] of appiTAxisState;
         {state of all axes}
         Axes: array[0..appMAX_CONTROLLER_AXES - 1] of appiTAxisState;
      end;

      Handler: TObject;

      constructor Create(); virtual;

      {log device properties}
      procedure LogDevice(); virtual;
      procedure DeInitialize(); virtual;

      {run individual devices (input collection, connection detection, ...)}
      procedure Run(); virtual;

      {called when the device is disconnected}
      procedure Disconnected();

      function GetName(): string;

      {get normalized value for axis or trigger}
      function GetNormalizedValue(rawValue: loopint): appiTAxisState;
   end;

   { appTControllerEvent }

   appTControllerEvent = record
      Device: appTControllerDevice;
      Typ: appTControllerEventType;

      {key number}
      KeyCode: loopint;
      {key value (non-zero means pressed)}
      Value: single;
      {which keys are being currently held}
      KeyState: TBitSet;

      {function to which this button/axis is mapped}
      MappedFunction: longint;

      Controller: appTControllerDevice;
   end;

   { appTControllerHandler }

   {a handler for controllers}
   appTControllerHandler = class
      {initialize all devices}
      procedure Initialize(); virtual;
      {initialize all devices}
      procedure DeInitialize(); virtual;
      {perform run operations}
      procedure Run(); virtual;
      {run individual controllers}
      procedure RunControllers();
      {reinitialize all devices}
      procedure Reset(); virtual;
   end;

   appTControllerDeviceList = specialize TSimpleList<appTControllerDevice>;

   appTOnControllerEventRoutine = procedure(var ev: appTControllerEvent);
   appTOnControllerEventRoutines = specialize TSimpleList<appTOnControllerEventRoutine>;

   { appTOnControllerEventRoutinesHelper }

   appTOnControllerEventRoutinesHelper = record helper for appTOnControllerEventRoutines
      procedure Call(var ev: appTControllerEvent);
   end;


   { appTControllers }
   appTControllers = record
      nHandlers: loopint;
      Handlers: array[0..appMAX_CONTROLLER_HANDLERS - 1] of appTControllerHandler;
      List: appTControllerDeviceList;

      OnEvent: appTOnControllerEventRoutines;
      PutInQueue: boolean;

      evh: appTEventHandler;
      evhp: appPEventHandler;

      procedure Queue(var ev: appTControllerEvent; controller: appTControllerDevice);

      procedure AddHandler(handler: appTControllerHandler);

      procedure Add(device: appTControllerDevice);
      procedure Reset();

      function GetMappedFunction(const name: string): longint;
   end;


VAR
   appControllers: appTControllers;

IMPLEMENTATION

{ appTOnControllerEventRoutinesHelper }

procedure appTOnControllerEventRoutinesHelper.Call(var ev: appTControllerEvent);
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      List[i](ev);
   end;
end;

{ appTControllers }

procedure appTControllers.Queue(var ev: appTControllerEvent; controller: appTControllerDevice);
var
   event: appTEvent;

begin
   OnEvent.Call(ev);
   ev.Controller := controller;

   appEvents.Init(event, 0, appControllers.evhp);

   if(PutInQueue) then
      appEvents.Queue(event, ev, SizeOf(ev));
end;

procedure appTControllers.AddHandler(handler: appTControllerHandler);
begin
   assert(nHandlers < appMAX_CONTROLLER_HANDLERS, 'Too many input controller handlers');

   Handlers[nHandlers] := handler;
   Inc(nHandlers);
end;

procedure appTControllers.Add(device: appTControllerDevice);
begin
   List.Add(device);
   device.DeviceIndex := List.n - 1;
end;

procedure appTControllers.Reset();
var
   i: loopint;

begin
   List.Dispose();

   for i := 0 to nHandlers - 1 do begin
      if(Handlers[i] <> nil) then
         Handlers[i].Reset();
   end;
end;

function appTControllers.GetMappedFunction(const name: string): longint;
var
   i: loopint;

begin
   for i := 0 to high(appCONTROLLER_FUNCTIONS) do begin
      if(appCONTROLLER_FUNCTIONS[i].Name = name) then
         exit(appCONTROLLER_FUNCTIONS[i].MappedFunction);
   end;

   result := -1;
end;

{ appTControllerDevice }

constructor appTControllerDevice.Create();
begin
   Valid := true;
   DeadZone := 0.1;
   DeadZoneStretch := true;
   State.Keys.SetupKeys(appMAX_CONTROLLER_BUTTONS, @State.KeyProperties);
end;

procedure appTControllerDevice.LogDevice();
begin
   log.i('Button count: ' + sf(ButtonCount));
   log.i('Axis count: ' + sf(AxisCount));
end;

procedure appTControllerDevice.DeInitialize();
begin

end;

procedure appTControllerDevice.Run();
begin

end;

procedure appTControllerDevice.Disconnected();
begin
   log.w('Input controller device seems disconnected: ' + Name);
   Valid := false;
end;

function appTControllerDevice.GetName(): string;
begin
   if(Name <> '') then
      Result := Name
   else
      Result := 'Unknown';
end;

function appTControllerDevice.GetNormalizedValue(rawValue: loopint): appiTAxisState;
begin
   {get positive raw value}
   Result := appiTAxisState.GetRaw(abs(rawValue), 32767);

   {dead zone means 0}
   if(Result < DeadZone) then begin
      Result := 0;
   end else begin
      {correct for strech}
      if(DeadZoneStretch) then begin
         Result := (1 / DeadZone) * Result;
      end;
   end;

   {correct if we went over}
   if(Result > 1) then
      Result := 1;

   {we convert to negative value if raw value was negative}
   if(rawValue < 0) then
      Result := Result * -1;
end;

{ appTControllerHandler }

procedure appTControllerHandler.Initialize();
begin

end;

procedure appTControllerHandler.DeInitialize();
begin

end;

procedure appTControllerHandler.Run();
begin
   RunControllers();
end;

procedure appTControllerHandler.RunControllers();
var
   i: loopint;

begin
   if(appControllers.List.n > 0) then begin
      for i := 0 to (appControllers.List.n - 1) do begin
         appControllers.List.List[i].Run();
      end;
   end;
end;

procedure appTControllerHandler.Reset();
begin
end;

procedure checkForDisconnected();
var
   i: loopint;

begin
   for i := 0 to appControllers.List.n - 1 do begin
      if(not appControllers.List.List[i].Valid) then begin
         FreeObject(appControllers.List.List[i]);

         appControllers.List.Remove(i);

         {check recursively until all disconnected devices are removed}
         checkForDisconnected();
         break;
      end;
   end;
end;

procedure run();
var
   i: loopint;

begin
   for i := 0 to appControllers.nHandlers - 1 do begin
      if(appControllers.Handlers[i] <> nil) then
         appControllers.Handlers[i].Run();
   end;

   checkForDisconnected();
end;

procedure initialize();
var
   i: loopint;

begin
   appControllers.List.Initialize(appControllers.List, 8);
   appControllers.OnEvent.Initialize(appControllers.OnEvent);

   for i := 0 to appControllers.nHandlers - 1 do begin
      if(appControllers.Handlers[i] <> nil) then
         appControllers.Handlers[i].Initialize();
   end;
end;

procedure deinitialize();
var
   i: loopint;

begin
   for i := 0 to appControllers.List.n - 1 do begin
      FreeObject(appControllers.List.List[i]);
   end;

   for i := 0 to appControllers.nHandlers - 1 do begin
      if(appControllers.Handlers[i] <> nil) then
         appControllers.Handlers[i].DeInitialize();

      FreeObject(appControllers.Handlers[i]);
   end;
end;

VAR
   runRoutine,
   initRoutines: oxTRunRoutine;

INITIALIZATION
   oxRun.AddRoutine(runRoutine, 'input_controllers', @run);
   app.InitializationProcs.Add(initRoutines, 'input_controllers', @initialize, @deinitialize);

   appControllers.evhp := appEvents.AddHandler(appControllers.evh, 'input_controller');

END.
