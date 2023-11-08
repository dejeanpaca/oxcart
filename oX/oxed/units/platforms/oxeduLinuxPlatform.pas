{
   oxeduLinuxPlatform, linux platform build specifics
   Copyright (C) 2017. Dejan Boras

   Started On:    19.07.2017.
}

{$INCLUDE oxdefines.inc}
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
   GlyphName := 'brands:61820';

   Configuration := oxedTPlatformConfiguration.Create();

   AddArchitecture('x86', 'x86');
   AddArchitecture('x64', 'x86_x64');
end;

procedure init();
begin
   oxedPlatforms.Add(oxedTLinuxPlatform.Create());
end;

INITIALIZATION
   oxed.Init.Add('platform.linux', @init);

END.
