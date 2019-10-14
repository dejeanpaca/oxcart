{
   oxeduAndroidPlatform, android platform build specifics
   Copyright (C) 2019. Dejan Boras

   Started On:    10.06.2019.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduAndroidPlatform;

INTERFACE

   USES
      uStd,
      {ox}
      oxuRunRoutines,
      {oxed}
      uOXED, oxeduPlatform;

TYPE
   { oxedTAndroidPlatform }

   oxedTAndroidPlatform = class(oxedTPlatform)
      constructor Create(); override;
   end;

IMPLEMENTATION

{ oxedTAndroidPlatform }

constructor oxedTAndroidPlatform.Create;
begin
   inherited;

   Name := 'Android';
   id := 'android';
   GlyphName := 'brands:61819';

   AddArchitecture('Default', '');
end;

procedure init();
begin
   oxedPlatforms.Add(oxedTAndroidPlatform.Create());
end;

INITIALIZATION
   oxed.Init.Add('platform.android', @init);

END.
