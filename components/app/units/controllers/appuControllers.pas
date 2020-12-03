{
   appuControllers, handles input controllers
   Copyright (C) 2020. Dejan Boras

   Axes are mapped from -1.0 to +1.0
   Triggers are mapped from 0.0 to +1.0
   DPad is assumed to have up/down/left/right buttons (other directions are combined from this)
   Axis groups combine two axes for an X/Y with -1.0 .. 1.0 values assumed left to right, and down to up

   TODO: Implement force feedback support
}

{$INCLUDE oxheader.inc}
UNIT appuControllers;

INTERFACE

   USES
      uStd, uLog, vmMath, uTiming,
      {app}
      uApp, appuEvents, appuController,
      {ox}
      oxuRunRoutines, oxuRun;

TYPE
   appPControllerHandler = ^appTControllerHandler;

   { appTControllerHandler }

   {a handler for controllers}
   appTControllerHandler = object
      constructor Create();

      {initialize all devices}
      procedure Initialize(); virtual;
      {initialize all devices}
      procedure DeInitialize(); virtual;
      {perform run operations}
      procedure Run(); virtual;

      {reinitialize all devices}
      procedure Scan(); virtual;
      {periodically rescan for new devices}
      procedure Rescan(); virtual;

      {get a displayable name for this handler}
      function GetName(): StdString; virtual;

   end;


   { appTControllers }
   appTControllers = record
      {handler count}
      nHandlers: loopint;
      {a list of handlers}
      Handlers: array[0..appMAX_CONTROLLER_HANDLERS - 1] of appPControllerHandler;
      {device list}
      List: appTControllerDeviceList;

      {callbacks for controller events}
      OnEvent: appTOnControllerEventRoutines;
      {put events in the event queue (OnEvent will be called in any case)}
      PutInQueue: boolean;

      {interval to rescan devices}
      RescanInterval: TTimerInterval;

      {event handler}
      evh: appTEventHandler;
      evhp: appPEventHandler;

      {list of mapped devices}
      MappedDevices: record
         s,
         e: appPControllerDeviceMapping;
      end;

      {queue a controller event}
      procedure Queue(var ev: appTControllerEvent; controller: appTControllerDevice);

      {add handler to the list}
      procedure AddHandler(var handler: appTControllerHandler);
      {add a device to the list}
      procedure Add(device: appTControllerDevice);
      {reset all devices}
      procedure Scan();
      {periodically rescans for new devices}
      procedure Rescan();

      {run individual controllers}
      procedure UpdateControllers();

      {get device by index}
      function GetByIndex(index: loopint): appTControllerDevice;

      {add a device mappping to the list}
      procedure AddMapping(var mapping: appTControllerDeviceMapping);

      {get a mapped function}
      function GetMappedFunction(const name: string): longint;
      {get a mapped device by name (if none found, returns generic mapping)}
      function GetMappedDeviceByName(const name: StdString): appPControllerDeviceMapping;
   end;


VAR

   {controllers}
   appControllers: appTControllers;

IMPLEMENTATION

{ appTControllers }

procedure appTControllers.Queue(var ev: appTControllerEvent; controller: appTControllerDevice);
var
   event: appTEvent;

begin
   OnEvent.Call(ev);
   ev.Controller := controller;

   {associate controller with event so it can be removed by it}
   event.ExternalData := Controller;

   appEvents.Init(event, 0, appControllers.evhp);

   if(PutInQueue) then
      appEvents.Queue(event, ev, SizeOf(ev));
end;

procedure appTControllers.AddHandler(var handler: appTControllerHandler);
begin
   assert(nHandlers < appMAX_CONTROLLER_HANDLERS, 'Too many input controller handlers');

   Handlers[nHandlers] := @handler;
   Inc(nHandlers);
end;

procedure appTControllers.Add(device: appTControllerDevice);
var
   m: appPControllerDeviceMapping;
   ps: appTControllerDeviceSettings;

begin
   List.Add(device);
   device.DeviceIndex := List.n - 1;

   {try to find a better mapping if we have a generic one}
   if(device.Mapping = @appControllerDeviceGenericMapping) then
      device.Mapping := appControllers.GetMappedDeviceByName(device.Name);

   m := device.Mapping;

   {update device according to the device mapping}
   if(m <> @appControllerDeviceGenericMapping) then begin
      ps := device.Settings;
      device.Settings := m^.Settings;

      if(m^.Settings.ButtonCount = -1) then
         device.Settings.ButtonCount := ps.ButtonCount;
   end;

   if(device.GetMappingId() <> '') then
      log.Collapsed('Input controller device: ' + device.GetName() + ' (' + device.GetMappingId() + ')')
   else
      log.Collapsed('Input controller device: ' + device.GetName());

   device.LogDevice();
   log.Leave();
end;

procedure appTControllers.Scan();
var
   i: loopint;

begin
   List.Dispose();

   for i := 0 to nHandlers - 1 do begin
      if(Handlers[i] <> nil) then
         Handlers[i]^.Scan();
   end;
end;

procedure appTControllers.Rescan();
var
   i: loopint;

begin
   {check for new/reconnected devices}
   if(appControllers.RescanInterval.Elapsed()) then begin
      for i := 0 to appControllers.nHandlers - 1 do begin
         if(appControllers.Handlers[i] <> nil) then
            appControllers.Handlers[i]^.Rescan();
      end;
   end;
end;

procedure appTControllers.UpdateControllers();
var
   i: loopint;

begin
   if(appControllers.List.n > 0) then begin
      for i := 0 to (appControllers.List.n - 1) do begin
         appControllers.List.List[i].UpdateStart();
         appControllers.List.List[i].Update();
      end;
   end;
end;

function appTControllers.GetByIndex(index: loopint): appTControllerDevice;
begin
   if(index >= 0) and (index < List.n) then
      Result := List.List[index]
   else
      Result := nil;
end;

procedure appTControllers.AddMapping(var mapping: appTControllerDeviceMapping);
begin
   mapping.Next := nil;

   if(MappedDevices.s = nil) then
      MappedDevices.s := @mapping
   else
      MappedDevices.e^.Next := @mapping;

   MappedDevices.e := @mapping;
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

function appTControllers.GetMappedDeviceByName(const name: StdString): appPControllerDeviceMapping;
var
   cur: appPControllerDeviceMapping;
   i: loopint;

begin
   cur := MappedDevices.s;

   if(cur <> nil) then repeat

      for i := 0 to High(cur^.RecognitionStrings) do begin
         if(pos(cur^.RecognitionStrings[i], name) > 0) then
            exit(cur);
      end;

      cur := cur^.Next;
   until (cur = nil);

   Result := @appControllerDeviceGenericMapping;
end;

{ appTControllerHandler }

constructor appTControllerHandler.Create();
begin

end;

procedure appTControllerHandler.Initialize();
begin

end;

procedure appTControllerHandler.DeInitialize();
begin

end;

procedure appTControllerHandler.Run();
begin
end;

procedure appTControllerHandler.Scan();
begin
end;

procedure appTControllerHandler.Rescan();
begin

end;

function appTControllerHandler.GetName(): StdString;
begin
   Result := 'Unknown';
end;

procedure checkForDisconnected();
var
   i: loopint;

begin
   for i := 0 to appControllers.List.n - 1 do begin
      if(not appControllers.List.List[i].Valid) then begin
         {disable events associated with this device, as it may be removed}
         appEvents.DisableWithExternalData(appControllers.List[i]);

         {remove object}
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
   {run all handlers}
   for i := 0 to appControllers.nHandlers - 1 do begin
      if(appControllers.Handlers[i] <> nil) then
         appControllers.Handlers[i]^.Run();
   end;

   {update all devices}
   appControllers.UpdateControllers();

   {check if any devices disconnected}
   checkForDisconnected();

   appControllers.Rescan();
end;

procedure initialize();
var
   i: loopint;

begin
   appControllers.List.Initialize(appControllers.List, 8);
   appControllers.OnEvent.Initialize(appControllers.OnEvent);

   for i := 0 to appControllers.nHandlers - 1 do begin
      if(appControllers.Handlers[i] <> nil) then
         appControllers.Handlers[i]^.Initialize();
   end;

   for i := 0 to appControllers.nHandlers - 1 do begin
      if(appControllers.Handlers[i] <> nil) then
         appControllers.Handlers[i]^.Scan();
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
         appControllers.Handlers[i]^.DeInitialize();
   end;
end;

INITIALIZATION
   oxRun.AddRoutine('input_controllers', @run);
   app.InitializationProcs.Add('input_controllers', @initialize, @deinitialize);

   appControllers.evhp := appEvents.AddHandler(appControllers.evh, 'input_controller');
   TTimerInterval.Initializef(appControllers.RescanInterval, 5.0);

END.
