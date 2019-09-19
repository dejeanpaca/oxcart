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
      uApp, appuEvents,
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

   {maximum number of axes supported}
   appMAX_CONTROLLER_AXES = 32;

TYPE
   appTControllerEventType = (
      appCONTROLLER_EVENT_BUTTON,
      appCONTROLLER_EVENT_AXIS
   );

   { appTControllerDevice }

   appTControllerDevice = class
      {device name}
      Name: string;

      {counts of axes and buttons}
      AxisCount,
      HatCount,
      ButtonCount: longint;

      {is the device valid (present)}
      Valid: boolean;

      {state of all buttons, max 64 supported}
      KeyState: TBitSet64;
      {state of all axes}
      Axes: array[0..appMAX_CONTROLLER_AXES - 1] of single;

      {XInput specific properties}

      {identifier}
      GUID: string;
      {is the controller a game controller (gamepad, joystick)}
      GameController: boolean;

      constructor Create(); virtual;

      {log device properties}
      procedure LogDevice(); virtual;
      procedure DeInitialize(); virtual;

      {run individual devices (input collection, connection detection, ...)}
      procedure Run(); virtual;

      {called when the device is disconnected}
      procedure Disconnected();

      function GetName(): string;
   end;

   { appTControllerEvent }

   appTControllerEvent = record
      Typ: appTControllerEventType;

      {key number}
      Number: longint;
      {key value (non-zero means pressed)}
      Value: single;
      {which keys are being held}
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
      List: appTControllerDeviceList;

      OnEvent: appTOnControllerEventRoutines;
      PutInQueue: boolean;

      evh: appTEventHandler;
      evhp: appPEventHandler;

      procedure Queue(var ev: appTControllerEvent);

      procedure Add(device: appTControllerDevice);
      procedure Reset();

      function GetMappedFunction(const name: string): longint;
   end;


VAR
   appControllers: appTControllers;
   appControllerHandler: appTControllerHandler;

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

procedure appTControllers.Queue(var ev: appTControllerEvent);
var
   event: appTEvent;

begin
   OnEvent.Call(ev);

   appEvents.Init(event, 0, appControllers.evhp);

   if(PutInQueue) then
      appEvents.Queue(event, ev, SizeOf(ev));
end;

procedure appTControllers.Add(device: appTControllerDevice);
begin
   List.Add(device);
end;

procedure appTControllers.Reset;
begin
   List.Dispose();

   if(appControllerHandler <> nil) then
      appControllerHandler.Reset();
end;

function appTControllers.GetMappedFunction(const name: string): longint;
var
   i: loopint;
   lowerName: string;

begin
   lowerName := LowerCase(name);

   for i := 0 to high(appCONTROLLER_FUNCTIONS) do begin
      if(appCONTROLLER_FUNCTIONS[i].Name = lowerName) then
         exit(appCONTROLLER_FUNCTIONS[i].MappedFunction);
   end;

   result := -1;
end;

{ appTControllerDevice }

constructor appTControllerDevice.Create();
begin
   Valid := true;
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
begin
   if(appControllerHandler <> nil) then
      appControllerHandler.Run();

   checkForDisconnected();
end;

procedure initialize();
begin
   appControllers.List.Initialize(appControllers.List, 8);
   appControllers.OnEvent.Initialize(appControllers.OnEvent);

   if(appControllerHandler <> nil) then
      appControllerHandler.Initialize();
end;

procedure deinitialize();
var
   i: loopint;

begin
   for i := 0 to appControllers.List.n - 1 do begin
      FreeObject(appControllers.List.List[i]);
   end;

   if(appControllerHandler <> nil) then
      appControllerHandler.DeInitialize();
end;

VAR
   runRoutine,
   initRoutines: oxTRunRoutine;

INITIALIZATION
   oxRun.AddRoutine(runRoutine, 'input_controllers', @run);
   app.InitializationProcs.Add(initRoutines, 'input_controllers', @initialize, @deinitialize);

   appControllers.evhp := appEvents.AddHandler(appControllers.evh, 'input_controller');

END.
