{
   oxuPlatforms, platform interface
   Copyright (c) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuPlatforms;

INTERFACE

   USES
      uLog, uStd, appuMouse,
      {ox}
      oxuPlatform, oxuRenderer, oxuRunRoutines;

TYPE
   oxTPlatformInstancesList = specialize TSimpleList<oxTPlatformClass>;
   oxTPlatformList = specialize TSimpleList<oxTPlatform>;

   { oxTPlatforms }

   oxTPlatforms = record
      Instances: oxTPlatformInstancesList;
      List: oxTPlatformList;

      OnComponent: oxTRunRoutines;

      procedure Register(platform: oxTPlatformClass);

      function Initialize(): boolean;
      procedure Deinitialize();

      function Initialize(platform: oxTPlatform): boolean;
      procedure DeInitialize(platform: oxTPlatform);

      function Find(classType: TClass): oxTPlatform;
      function SetPlatform(): boolean;
      procedure Use(platform: oxTPlatform);
   end;

VAR
   oxPlatforms: oxTPlatforms;

IMPLEMENTATION

{ oxTPlatforms }

procedure oxTPlatforms.Register(platform: oxTPlatformClass);
begin
   Instances.Add(platform);
end;

function oxTPlatforms.Initialize(): boolean;
var
   i: loopint;

begin
   Result := true;

   {instance all platforms}
   for i := 0 to Instances.n - 1 do begin
      List.Add(Instances.List[i].Create());
   end;

   {initialize all platforms}
   for i := 0 to List.n - 1 do begin
      oxPlatform := List.List[i];

      Result := Initialize(oxPlatform);
      if(not Result) then
         exit;
   end;

   log.i('Initialized platforms');

   OnComponent.iCall();
end;

procedure oxTPlatforms.Deinitialize();
var
   i: loopint;

begin
   OnComponent.dCall();

   {deinitialize all platforms}
   for i := 0 to List.n - 1 do begin
      Deinitialize(List.List[i]);
   end;

   {destroy all objects}
   for i := 0 to List.n - 1 do begin
      FreeObject(List.List[i]);
   end;

   List.Dispose();

   log.i('Deinitialized platforms');
end;

function oxTPlatforms.Initialize(platform: oxTPlatform): boolean;
begin
   Result := platform.Initialize();

   if(Result) then
      appm.SetDriver(platform.PointerDriver);
end;

procedure oxTPlatforms.DeInitialize(platform: oxTPlatform);
begin
   platform.DeInitialize();

   if(platform.PointerDriver <> nil) then
      FreeObject(platform.PointerDriver);

   appm.SetDriver(nil);
end;

function oxTPlatforms.Find(classType: TClass): oxTPlatform;
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i].ClassType = classType) then begin
         exit(List.List[i]);
      end;
   end;

   Result := nil;
end;

function oxTPlatforms.SetPlatform(): boolean;
var
   platform: oxTPlatform;

begin
   {if something uses the base platform instance, we'll add it to the list}
   if(oxRenderer.PlatformInstance = oxTPlatform) then begin
      oxPlatforms.Register(oxTPlatform);
      oxPlatforms.List.Add(oxTPlatform.Create());
   end;

   platform := Find(oxRenderer.PlatformInstance);

   if(platform <> nil) then begin
      Use(platform);
      Result := true;
   end else begin
      log.e('Failed to find the platform ' + oxRenderer.PlatformInstance.ClassName + ' used by renderer ' + oxRenderer.Name);
      Result := false;
   end;
end;

procedure oxTPlatforms.Use(platform: oxTPlatform);
begin
   oxPlatform := platform;

   log.i('Using platform: ' + oxPlatform.Name);
end;

INITIALIZATION
   oxTPlatformInstancesList.Initialize(oxPlatforms.Instances);
   oxTPlatformList.Initialize(oxPlatforms.List);

END.
