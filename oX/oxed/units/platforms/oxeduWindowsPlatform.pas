{
   oxeduWindowsPlatform, windows platform build specifics
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduWindowsPlatform;

INTERFACE

   USES
      uStd,
      {ox}
      oxuRunRoutines,
      {oxed}
      uOXED, oxeduPlatform, oxeduPlatformConfiguration;

TYPE
   { oxedTWindowsPlatform }

   oxedTWindowsPlatform = class(oxedTPlatform)
      constructor Create(); override;
   end;

IMPLEMENTATION

{ oxedTWindowsPlatform }

constructor oxedTWindowsPlatform.Create();
begin
   inherited;

   Name := 'Windows';
   Id := 'windows';
   OS := 'windows';
   GlyphName := 'brands:61818';

   Configuration := oxedTPlatformConfiguration.Create();

   AddArchitecture(oxedTPlatformArchitecture.Create('Windows x32', 'i386'));
   AddArchitecture(oxedTPlatformArchitecture.Create('Windows x64', 'x86_64'));
end;

procedure init();
begin
   oxedPlatforms.Add(oxedTWindowsPlatform.Create());
end;

INITIALIZATION
   oxed.Init.Add('platform.windows', @init);

END.
