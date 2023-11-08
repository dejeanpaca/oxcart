{
   uiuSkin, UI skin management
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uiuSkinLoader;

INTERFACE

   USES
      uStd, uLog, StringUtils, uFile, uFileUtils,
      {ox}
      oxuPaths, oxuTexture, oxuTextureGenerate, oxuGlyphs, uiuTypes,
      {ui}
      uiuSkin, uiuSkinTypes, uiWidgets, uiuRegisteredWidgets, uiuWidget;

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
   s: uiPWidgetClass;

begin
   skin.ResourcePath := IncludeTrailingPathDelimiterNonEmpty(oxPaths.FindDirectory(oxPaths.UI + skin.Name));

   log.v('Skin(' + skin.Name + ') resource path set to: ' + skin.ResourcePath);

   windowPath := skin.ResourcePath + 'window' + DirectorySeparator;

   LoadTexture(windowPath + 'background.png', skin.Window.Textures.Background);

   skin.Window.TitleButtonGlyphs[uiwBUTTON_CLOSE] := oxGlyphs.LoadGlyph($f00d);
   skin.Window.TitleButtonGlyphs[uiwBUTTON_MINIMIZE] := oxGlyphs.LoadGlyph('regular:62161');
   skin.Window.TitleButtonGlyphs[uiwBUTTON_MAXIMIZE] := oxGlyphs.LoadGlyph('regular:62160');
   skin.Window.TitleButtonGlyphs[uiwBUTTON_RESTORE] := oxGlyphs.LoadGlyph($f2d2);

   skin.ChevronRight := oxGlyphs.LoadGlyph($f054);


   s := uiRegisteredWidgets.Internals.s;

   if(s = nil) then
      exit;

   repeat
     if(s^.SkinDescriptor.Glyphs <> nil) then begin
        {TODO: Go through everything}
     end;

     s := s^.Next;
   until s = nil;
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
