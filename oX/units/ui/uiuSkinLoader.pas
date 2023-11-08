{
   uiuSkin, UI skin management
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT uiuSkinLoader;

INTERFACE

   USES
      uiuSkin, uiuSkinTypes;

TYPE
   { uiTSkinLoader }

   uiTSkinLoader = record
      class procedure Load(skin: uiTSkin); static;
   end;

IMPLEMENTATION

{ uiTSkinLoader }

class procedure uiTSkinLoader.Load(skin: uiTSkin);
begin

end;

INITIALIZATION
   uiSkin.Loader := @uiTSkinLoader.Load;

END.
