{
   oxeduLinuxPlatform, linux platform build specifics
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduLinuxPlatform;

INTERFACE

   USES
      uStd,
      {ox}
      oxuRunRoutines,
      {oxed}
      uOXED, oxeduPlatform, oxeduPlatformConfiguration;

TYPE
   { oxedTLinuxPlatform }

   oxedTLinuxPlatform = class(oxedTPlatform)
      constructor Create(); override;
   end;


IMPLEMENTATION

{ oxedTLinuxPlatform }

constructor oxedTLinuxPlatform.Create();
begin
   inherited;

   Name := 'Linux';
   Id := 'linux';
   OS := 'linux';
   GlyphName := 'brands:61820';

   Configuration := oxedTPlatformConfiguration.Create();

   AddArchitecture(oxedTPlatformArchitecture.Create('linux x32', 'i386'));
   AddArchitecture(oxedTPlatformArchitecture.Create('linux x64', 'x86_64'));
end;

procedure init();
begin
   oxedPlatforms.Add(oxedTLinuxPlatform.Create());
end;

INITIALIZATION
   oxed.Init.Add('platform.linux', @init);

END.
