{
   oxeduBuildPlatform, handling build specifics for various platforms
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduPlatform;

INTERFACE

   USES
      uStd, udvars,
      uFPCHelpers,
      {ox}
      oxuRunRoutines,
      {oxed}
      uOXED, oxeduPlatformConfiguration;

TYPE

   { oxedTPlatformArchitecture }

   oxedTPlatformArchitecture = class
      Name,
      Architecture,
      {use an override for platform, if the platform string can't be formed via os-architecture,
      e.g. when the OS differs per platform (win32, win64)}
      Platform: StdString;

      {default cpu type}
      DefaultCPUType,
      {default fpu type}
      DefaultFPUType,
      {default fpu type}
      BinUtilsPrefix: StdString;

      {extension for the resulting executable}
      ExecutableExtension,
      {extension for the resulting library}
      LibraryExtension,
      {prefix for the resulting library}
      LibraryPrefix: StdString;

      PlatformObject: TObject;

      constructor Create(const newName, newArch: StdString); virtual;

      procedure Build(); virtual;
      function GetPlatformString(): TFPCPlatformString;
   end;

   oxedTPlatformArchitectureList = specialize TSimpleList<oxedTPlatformArchitecture>;

   { oxedTPlatform }
   oxedTPlatform = class
      {is this platform enabled}
      Enabled: boolean;

      {platform name}
      Name,
      {platform id, should match the fpc compiler define for the platform (windows, linux, android, darwin)}
      Id: StdString;

      OS: StdString;
      Architectures: oxedTPlatformArchitectureList;

      {does this platform require CMEM}
      RequireCMEM,
      {does this platform require PIC (true by default, but shoudl be false if FPC automatically builds as PIC)}
      RequiresPIC,
      {does this platform support external debug symbols}
      SupportsExternalDebugSymbols,
      {do not search default library path (-Xd)}
      ExcludeDefaultLibraryPath: boolean;

      GlyphName: StdString;
      GlyphCode: longword;

      Configuration: oxedTPlatformConfiguration;

      {symbols that should be defined when building for this platform}
      Symbols: TSimpleStringList;

      pDvg: PDVarGroup;

      constructor Create(); virtual;
      destructor Destroy; override;

      function AddArchitecture(arch: oxedTPlatformArchitecture): oxedTPlatformArchitecture;

      {reset when new project is created, opened or closed}
      procedure ProjectReset(); virtual;

      {called when the project is loaded}
      procedure Load(); virtual;
      {called when the project is saved}
      procedure Save(); virtual;
   end;

   oxedTPlatformsList = specialize TSimpleList<oxedTPlatform>;

   oxedTPlatformRoutine = procedure(platform: oxedTPlatform);
   oxedTPlatformRoutineList = specialize TSimpleList<oxedTPlatformRoutine>;

   { oxedTPlatformRoutineListHelper }

   oxedTPlatformRoutineListHelper = record helper for oxedTPlatformRoutineList
      procedure Call(platform: oxedTPlatform);
   end;

   { oxedTPlatforms }

   oxedTPlatforms = record
      List: oxedTPlatformsList;
      CurrentId: string;

      OnEnable,
      OnDisable: oxedTPlatformRoutineList;

      procedure Initialize();
      procedure DeInitialize();

      procedure Add(platform: oxedTPlatform);
      function FindById(const id: StdString): oxedTPlatform;
      procedure Dispose();

      procedure Enable(platform: oxedTPlatform);
      procedure Disable(platform: oxedTPlatform);
      procedure Enable(platform: oxedTPlatform; isEnabled: boolean);
   end;

VAR
   oxedPlatforms: oxedTPlatforms;

   {current platform on which the editor is running}
   oxedPlatform: oxedTPlatform;

IMPLEMENTATION

{ oxedTPlatformRoutineListHelper }

procedure oxedTPlatformRoutineListHelper.Call(platform: oxedTPlatform);
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i] <> nil) then
         List[i](platform);
   end;
end;

{ oxedTPlatformArchitecture }

constructor oxedTPlatformArchitecture.Create(const newName, newArch: StdString);
begin
   Name := newName;
   Architecture := newArch;
end;

procedure oxedTPlatformArchitecture.Build();
begin

end;

function oxedTPlatformArchitecture.GetPlatformString(): TFPCPlatformString;
begin
   if(Platform = '') then
      Result := Architecture + '-' + oxedTPlatform(PlatformObject).OS
   else
      Result := Platform;
end;

{ oxedTPlatform }

constructor oxedTPlatform.Create();
begin
   Name := 'Unknown';
   id := 'unknown';

   Architectures.InitializeValues(Architectures);
   TSimpleStringList.InitializeValues(Symbols);

   SupportsExternalDebugSymbols := true;
   RequiresPIC := false;
end;

destructor oxedTPlatform.Destroy;
var
   i: loopint;

begin
   inherited;

   for i := 0 to Architectures.n - 1 do begin
      FreeObject(Architectures.List[i]);
   end;

   Architectures.Dispose();
end;

function oxedTPlatform.AddArchitecture(arch: oxedTPlatformArchitecture): oxedTPlatformArchitecture;
begin
   Architectures.Add(arch);
   arch.PlatformObject := Self;
   Result := arch;
end;

procedure oxedTPlatform.ProjectReset();
begin

end;

procedure oxedTPlatform.Load();
begin

end;

procedure oxedTPlatform.Save();
begin

end;

{ oxedTPlatforms }

procedure oxedTPlatforms.Initialize();
begin
   CurrentId := 'none';

   {$IFDEF WINDOWS}
   CurrentId := 'windows';
   {$ENDIF}
   {$IFDEF LINUX}
   CurrentId := 'linux';
   {$ENDIF}
   {$IFDEF ANDROID}
   CurrentId := 'android';
   {$ENDIF}
   {$IFDEF DARWIN}
   CurrentId := 'darwin';
   {$ENDIF}

   oxedPlatform := FindById(CurrentId);

   if(oxedPlatform = nil) then
      oxedPlatform := oxedTPlatform.Create();
end;

procedure oxedTPlatforms.DeInitialize();
begin
   if(oxedPlatform <> nil) and (oxedPlatform.Id = 'unknown') then
      FreeObject(oxedPlatform);
end;

procedure oxedTPlatforms.Add(platform: oxedTPlatform);
begin
   List.Add(platform);
end;

function oxedTPlatforms.FindById(const id: StdString): oxedTPlatform;
var
   i: loopint;

begin
   for i := 0 to List.n - 1 do begin
      if(List.List[i].id = id) then
         exit(List.List[i]);
   end;

   Result := nil;
end;

procedure oxedTPlatforms.Dispose();
var
   i: loopint;

begin
   for i := 0 to (List.n - 1) do begin
      FreeObject(List.List[i]);
   end;

   List.Dispose();
end;

procedure oxedTPlatforms.Enable(platform: oxedTPlatform);
begin
   if(platform <> nil) and (not platform.Enabled) then begin
      platform.Enabled := true;
      OnEnable.Call(platform);
   end;
end;

procedure oxedTPlatforms.Disable(platform: oxedTPlatform);
begin
   if(platform <> nil) and (platform.Enabled) then begin
      platform.Enabled := false;
      OnDisable.Call(platform);
   end;
end;

procedure oxedTPlatforms.Enable(platform: oxedTPlatform; isEnabled: boolean);
begin
   if(platform <> nil) then begin
      if(isEnabled) then
         Enable(platform)
      else
         Disable(platform);
   end;
end;

procedure deinit();
begin
   oxedPlatforms.Dispose();
end;

INITIALIZATION
   oxed.Init.dAdd('platforms', @deinit);

   oxedPlatforms.List.InitializeValues(oxedPlatforms.List);

   oxedTPlatformRoutineList.Initialize(oxedPlatforms.OnEnable);
   oxedTPlatformRoutineList.Initialize(oxedPlatforms.OnDisable);

END.
