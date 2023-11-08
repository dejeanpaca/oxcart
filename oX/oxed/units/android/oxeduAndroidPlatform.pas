{
   oxeduAndroidPlatform, android platform build specifics
   Copyright (C) 2019. Dejan Boras

   Started On:    10.06.2019.
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


IMPLEMENTATION

{ oxedTAndroidPlatformArchitecture }

constructor oxedTAndroidPlatformArchitecture.Create();
begin
   Name := 'Android';
   Architecture := '';
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

   AddArchitecture(oxedTAndroidPlatformArchitecture.Create());
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
   oxedPlatforms.Add(oxedTAndroidPlatform.Create());
end;

INITIALIZATION
   oxed.Init.Add('platform.android', @init);

END.
