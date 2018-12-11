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
      {oxed}
      uOXED, oxeduPlatform;

TYPE
   { oxedTLinuxPlatform }

   oxedTLinuxPlatform = class(oxedTPlatform)
      constructor Create; override;
   end;

IMPLEMENTATION

{ oxedTLinuxPlatform }

constructor oxedTLinuxPlatform.Create;
begin
   inherited;

   Name := 'Linux';
   id := 'linux';
   GlyphCode := $f17c;
end;

procedure init();
begin
   oxedPlatforms.Add(oxedTLinuxPlatform.Create());
end;

INITIALIZATION
   oxed.Init.iAdd('platform.linux', @init);

END.
