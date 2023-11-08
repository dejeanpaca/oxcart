{
   uiuSkin, UI skin management
   Copyright (C) 2011. Dejan Boras

   Started On:    15.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT uiuSkinLoader;

INTERFACE

   USES
      uLog,
      {ox}
      oxuPaths,
      {ui}
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
   skin.ResourcePath := oxAssetPaths.FindDirectory(oxPaths.UI + skin.Name);

   log.v('Skin(' + skin.Name + ') resource path set to: ' + skin.ResourcePath);
end;

INITIALIZATION
   uiSkin.Loader := @uiTSkinLoader.Load;

END.
