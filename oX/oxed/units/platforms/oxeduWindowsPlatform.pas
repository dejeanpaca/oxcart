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
      {oxed}
      uOXED, oxeduPlatform;

TYPE
   { oxedTWindowsPlatform }

   oxedTWindowsPlatform = class(oxedTPlatform)
      constructor Create; override;
   end;

IMPLEMENTATION

{ oxedTWindowsPlatform }

constructor oxedTWindowsPlatform.Create;
begin
   inherited;

   Name := 'Windows';
   id := 'windows';
   GlyphName := 'brands:61818';
end;

procedure init();
begin
   oxedPlatforms.Add(oxedTWindowsPlatform.Create());
end;

INITIALIZATION
   oxed.Init.iAdd('platform.windows', @init);

END.
