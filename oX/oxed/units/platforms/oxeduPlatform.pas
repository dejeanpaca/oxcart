{
   oxeduBuildPlatform, handling build specifics for various platforms
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
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
      Architecture: StdString;
      {matches fpc platform}
      Platform: TFPCPlatformString;

      PlatformObject: TObject;

      constructor Create(); virtual;

      procedure Build(); virtual;
   end;

   oxedTPlatformArchitectureList = specialize TSimpleList<oxedTPlatformArchitecture>;

   { oxedTPlatform }
   oxedTPlatform = class
      {is this platform enabled}
      Enabled: boolean;

      {platform name}
      Name,
      {platform id, should match the fpc compiler define for the platform (windows, linux, android, darwin)}
      Id: string;

      Architectures: oxedTPlatformArchitectureList;

      GlyphName: string;
      GlyphCode: longword;

      Configuration: oxedTPlatformConfiguration;

      constructor Create(); virtual;
      destructor Destroy; override;

      procedure AddArchitecture(arch: oxedTPlatformArchitecture);

      {reset when new project is created, opened or closed}
      procedure ProjectReset(); virtual;
      {get settings group}
      function GetDvarGroup(): PDVarGroup; virtual;

      {called when the project is loaded}
      procedure Load(); virtual;
      {called when the project is saved}
      procedure Save(); virtual;
   end;

   oxedTPlatformsList = specialize TSimpleList<oxedTPlatform>;

   { oxedTPlatforms }

   oxedTPlatforms = record
      List: oxedTPlatformsList;
      CurrentId: string;

      procedure Initialize();
      procedure DeInitialize();

      procedure Add(platform: oxedTPlatform);
      function FindById(const id: string): oxedTPlatform;
      procedure Dispose();
   end;

VAR
   oxedPlatforms: oxedTPlatforms;

   {current platform on which the editor is running}
   oxedPlatform: oxedTPlatform;

IMPLEMENTATION

{ oxedTPlatformArchitecture }

constructor oxedTPlatformArchitecture.Create();
begin
   Name := 'unknown';
   Platform := 'unknown';
   Architecture := 'unknown';
end;

procedure oxedTPlatformArchitecture.Build();
begin

end;

{ oxedTPlatform }

constructor oxedTPlatform.Create();
begin
   Name := 'Unknown';
   id := 'unknown';

   Architectures.InitializeValues(Architectures);
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

procedure oxedTPlatform.AddArchitecture(arch: oxedTPlatformArchitecture);
begin
   Architectures.Add(arch);
   arch.PlatformObject := Self;
end;

procedure oxedTPlatform.ProjectReset();
begin

end;

function oxedTPlatform.GetDvarGroup(): PDVarGroup;
begin
   Result := nil;
end;

procedure oxedTPlatform.Load();
begin

end;

procedure oxedTPlatform.Save();
begin

end;

{ oxedTPlatforms }

procedure oxedTPlatforms.Initialize;
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

procedure oxedTPlatforms.DeInitialize;
begin
   if(oxedPlatform <> nil) and (oxedPlatform.Id = 'unknown') then
      FreeObject(oxedPlatform);
end;

procedure oxedTPlatforms.Add(platform: oxedTPlatform);
begin
   List.Add(platform);
end;

function oxedTPlatforms.FindById(const id: string): oxedTPlatform;
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

procedure deinit();
begin
   oxedPlatforms.Dispose();
end;

INITIALIZATION
   oxed.Init.dAdd('platforms', @deinit);

   oxedPlatforms.List.InitializeValues(oxedPlatforms.List);

END.
