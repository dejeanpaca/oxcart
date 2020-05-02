{
   uiuSkin, UI skin management
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuSkinLoader;

INTERFACE

   USES
      uLog, StringUtils, uFile, uFileUtils,
      {ox}
      oxuPaths, oxuTexture, oxuTextureGenerate, oxuGlyphs, uiuTypes,
      {ui}
      uiuSkin, uiuSkinTypes;

TYPE
   { uiTSkinLoader }

   uiTSkinLoader = record
      class procedure Load(skin: uiTSkin); static;
      class procedure LoadTexture(const fn: string; out tex: oxTTexture); static;
   end;

IMPLEMENTATION

{ uiTSkinLoader }

class procedure uiTSkinLoader.Load(skin: uiTSkin);
var
   windowPath: string;

begin
   skin.ResourcePath := IncludeTrailingPathDelimiterNonEmpty(oxPaths.FindDirectory(oxPaths.UI + skin.Name));

   log.v('Skin(' + skin.Name + ') resource path set to: ' + skin.ResourcePath);

   windowPath := skin.ResourcePath + 'window' + DirectorySeparator;

   LoadTexture(windowPath + 'background.png', skin.Window.Textures.Background);

   skin.Window.TitleButtonGlyphs[uiwBUTTON_CLOSE] := oxGlyphs.Load($f00d);
   skin.Window.TitleButtonGlyphs[uiwBUTTON_MINIMIZE] := oxGlyphs.Load('regular:62161');
   skin.Window.TitleButtonGlyphs[uiwBUTTON_MAXIMIZE] := oxGlyphs.Load('regular:62160');
   skin.Window.TitleButtonGlyphs[uiwBUTTON_RESTORE] := oxGlyphs.Load($f2d2);
end;

class procedure uiTSkinLoader.LoadTexture(const fn: string; out tex: oxTTexture);
begin
   tex := nil;

   if(FileUtils.Exists(fn) > 0) then begin
      oxTextureGenerate.Generate(fn, tex);

      if(tex <> nil) then begin
         log.d('Loaded: ' + fn);
         tex.MarkPermanent();
      end;
   end else
      log.d('Not found: ' + fn);
end;

INITIALIZATION
   uiSkin.Loader := @uiTSkinLoader.Load;

END.
