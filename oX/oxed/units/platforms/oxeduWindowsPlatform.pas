{
   oxeduWindowsPlatform, windows platform build specifics
   Copyright (C) 2017. Dejan Boras

   Started On:    19.07.2017.
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
   id := 'windows';
   GlyphName := 'brands:61818';

   Configuration := oxedTPlatformConfiguration.Create();

   AddArchitecture('x86', 'x86');
   AddArchitecture('x64', 'x86_x64');
end;

procedure init();
begin
   oxedPlatforms.Add(oxedTWindowsPlatform.Create());
end;

INITIALIZATION
   oxed.Init.Add('platform.windows', @init);

END.
