{
   oxeduAndroidPlatform, android platform build specifics
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAndroidPlatform;

INTERFACE

   USES
      uStd, udvars,
      {ox}
      oxuRunRoutines,
      {oxed}
      uOXED, oxeduPlatform, oxeduPlatformConfiguration, oxeduAndroidSettings;

TYPE
   { oxedTAndroidPlatform }

   oxedTAndroidPlatform = class(oxedTPlatform)
      constructor Create(); override;

      procedure ProjectReset(); override;
      function GetDvarGroup(): PDVarGroup; override;
   end;

VAR
   oxedAndroidPlatform: oxedTAndroidPlatform;

IMPLEMENTATION

{ oxedTAndroidPlatform }

constructor oxedTAndroidPlatform.Create();
begin
   inherited;

   Name := 'Android';
   Id := 'android';
   OS := 'android';
   GlyphName := 'brands:61819';

   Configuration := oxedTPlatformConfiguration.Create();

   AddArchitecture(oxedTPlatformArchitecture.Create('Android Arm x32', 'arm'));
   AddArchitecture(oxedTPlatformArchitecture.Create('Android Arm x64', 'aarch64'));
   AddArchitecture(oxedTPlatformArchitecture.Create('Android X86 x32', 'i386'));
   AddArchitecture(oxedTPlatformArchitecture.Create('Android X86 x64', 'x86_64'));
end;

procedure oxedTAndroidPlatform.ProjectReset();
begin
   oxedAndroidSettings.ProjectReset();
end;

function oxedTAndroidPlatform.GetDvarGroup(): PDVarGroup;
begin
   Result := @oxedAndroidSettings.Project.dvg;
end;

procedure init();
begin
   oxedAndroidPlatform := oxedTAndroidPlatform.Create();
   oxedPlatforms.Add(oxedAndroidPlatform);
end;

INITIALIZATION
   oxed.Init.Add('platform.android', @init);

END.
