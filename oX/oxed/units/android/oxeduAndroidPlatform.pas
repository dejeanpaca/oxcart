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

   { oxedTAndroidPlatformArchitecture }

   oxedTAndroidPlatformArchitecture = class(oxedTPlatformArchitecture)
      constructor Create(); override;
   end;

VAR
   oxedAndroidPlatform: oxedTAndroidPlatform;

IMPLEMENTATION

{ oxedTAndroidPlatformArchitecture }

constructor oxedTAndroidPlatformArchitecture.Create();
begin
   Name := 'Android';
   Architecture := 'android';
   Platform := 'arm-android';
end;

{ oxedTAndroidPlatform }

constructor oxedTAndroidPlatform.Create();
begin
   inherited;

   Name := 'Android';
   id := 'android';
   GlyphName := 'brands:61819';

   Configuration := oxedTPlatformConfiguration.Create();

   AddArchitecture(oxedTAndroidPlatformArchitecture.Create()).Architecture := 'arm';
   AddArchitecture(oxedTAndroidPlatformArchitecture.Create()).Architecture := 'aarch64';
   AddArchitecture(oxedTAndroidPlatformArchitecture.Create()).Architecture := 'i386';
   AddArchitecture(oxedTAndroidPlatformArchitecture.Create()).Architecture := 'x86_64';
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
