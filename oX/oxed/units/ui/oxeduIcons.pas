{
   oxeduIcons, oxed icon management
   Copyright (C) 2017. Dejan Boras

   Started On:    23.04.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduIcons;

INTERFACE

   USES
      uStd, StringUtils,
      {ox}
      uOX, oxuPaths, oxuFreetype, oxuTexture, oxuTexturePool, uiuContextMenu, oxuDefaultTexture,
      {oxed}
      uOXED, oxuFileIcons;

TYPE
   oxedTIconsSource = record
      Font: oxTFreetypeFont;
      Textures: oxTTexturePool;
   end;

   { oxedTIconsGlobal }

   oxedTIconsGlobal = record
      Primary,
      Secondary: oxedTIconsSource;
      {default size for glyphs}
      DefaultSize: loopint;
      {will return glyph even if one cannot be loaded due to issues (to prevent any potential crashes)}
      AlwaysReturnGlyphs: boolean;

      function Create(c: longword; size: longint; const name: string; const source: oxedTIconsSource): oxTTexture;
      function Create(c: longword; size: longint = 0; const name: string = ''): oxTTexture;
      function CreateSecondary(c: longword; size: longint = 0; const name: string = ''): oxTTexture;
      function Create(const c: string; size: longint = 0): oxTTexture;

      procedure Create(item: uiPContextMenuItem; c: longword; size: longint = 0);
      procedure CreateSecondary(item: uiPContextMenuItem; c: longword; size: longint = 0);
   end;

VAR
   oxedIcons: oxedTIconsGlobal;

IMPLEMENTATION

procedure init();
var
   path: UTF8String;
   tex: oxTTexture;

begin
   path := oxAssetPaths.Find(oxPaths.Fonts + 'FontAwesome.otf');
   oxedIcons.Primary.Font := oxFreetypeManager.Load('default', path);

   path := oxAssetPaths.Find(oxPaths.Fonts + 'MaterialIcons-Regular.woff');
   oxedIcons.Secondary.Font := oxFreetypeManager.Load('material', path);

   oxedIcons.Primary.Textures := oxTTexturePool.Create();
   oxedIcons.Secondary.Textures := oxTTexturePool.Create();

   {file}
   tex := oxedIcons.Create('file');
   oxFileIcons.SetFile(tex);

   {folder}
   tex := oxedIcons.Create($f07b {folder});
   oxFileIcons.SetDirectory(tex);

   {file-code-o}
   tex := oxedIcons.Create($f1c9 {file-code-o});
   oxFileIcons.Add(tex, 'pas');
   oxFileIcons.Add(tex, 'pp');
   oxFileIcons.Add(tex, 'lpr');

   {file-tex}
   tex := oxedIcons.Create($f15c {'file-text'});
   oxFileIcons.Add(tex, 'txt');
   oxFileIcons.Add(tex, 'md');

   {file-image-o}
   tex := oxedIcons.Create($f1c5 {file-image});
   oxFileIcons.Add(tex, 'png');
   oxFileIcons.Add(tex, 'tga');
   oxFileIcons.Add(tex, 'jpeg');
   oxFileIcons.Add(tex, 'jpg');

   {file-archive-o}
   tex := oxedIcons.Create($f1c6 {file-archive-o});
   oxFileIcons.Add(tex, 'zip');
   oxFileIcons.Add(tex, '7z');
   oxFileIcons.Add(tex, 'rar');

   {file-audio-o}
   tex := oxedIcons.Create($f1c7 {file-audio-o});
   oxFileIcons.Add(tex, 'wav');
   oxFileIcons.Add(tex, 'mp3');
   oxFileIcons.Add(tex, 'ogg');
   oxFileIcons.Add(tex, 'flac');

   {file-audio-o}
   tex := oxedIcons.Create($f1c8 {file-video-o});
   oxFileIcons.Add(tex, 'mp4');
   oxFileIcons.Add(tex, 'mkv');
   oxFileIcons.Add(tex, 'h264');
   oxFileIcons.Add(tex, 'h264');
   oxFileIcons.Add(tex, 'wmv');

   {git}
   tex := oxedIcons.Create($f1d3{git});
   oxFileIcons.Add(tex, 'gitignore');
end;

procedure deinit();
begin
   FreeObject(oxedIcons.Primary.Textures);
   FreeObject(oxedIcons.Secondary.Textures);
end;

{ oxedTIconsGlobal }

function oxedTIconsGlobal.Create(c: longword; size: longint; const name: string; const source: oxedTIconsSource): oxTTexture;
var
   monospaced,
   exactSize: boolean;
   alphaType: oxTFreetypeAlphaType;

begin
   Result := oxTTexture(source.Textures.FindByPath('f' + sf(c)));

   if(Result = nil)  then begin
      if(source.Font <> nil) then begin
         if(size = 0) then
            size := DefaultSize;

         monospaced := source.Font.Square;
         exactSize := source.Font.ExactSize;
         alphaType := source.Font.AlphaType;

         source.Font.Square := true;
         source.Font.ExactSize := true;
         source.Font.AlphaType := oxFREETYPE_ALPHA_AVERAGE;

         if(name = '') then
            source.Font.CreateGlyphTexture(c, Result, size)
         else
            source.Font.CreateGlyphTexture(name, Result, size);

         if(Result <> nil) then begin
            Result.Path := 'f' + sf(c);
            source.Textures.AddResource(Result);
         end;

         source.Font.Square := monospaced;
         source.Font.ExactSize := exactSize;
         source.Font.AlphaType := alphaType;
      end else if(AlwaysReturnGlyphs) then
         Result := oxDefaultTexture.Texture;
   end;

   if(Result <> nil) then
      Result.MarkUsed();
end;

function oxedTIconsGlobal.Create(c: longword; size: longint; const name: string): oxTTexture;
begin
   Result := Create(c, size, name, Primary);
end;

function oxedTIconsGlobal.CreateSecondary(c: longword; size: longint; const name: string): oxTTexture;
begin
   Result := Create(c, size, name, Secondary);
end;

function oxedTIconsGlobal.Create(const c: string; size: longint): oxTTexture;
begin
   Result := Create(0, size, c);
end;

procedure oxedTIconsGlobal.Create(item: uiPContextMenuItem; c: longword; size: longint);
var
   tex: oxTTexture;

begin
   tex := Create(c, size);

   if(tex <> nil) then
      item^.SetGlyph(tex);
end;

procedure oxedTIconsGlobal.CreateSecondary(item: uiPContextMenuItem; c: longword; size: longint);
var
   tex: oxTTexture;

begin
   tex := CreateSecondary(c, size);

   if(tex <> nil) then
      item^.SetGlyph(tex);
end;

INITIALIZATION
   oxedIcons.DefaultSize := 64;
   oxedIcons.AlwaysReturnGlyphs := true;

   oxed.Init.iAdd('oxed.icons', @init);
   ox.PreInit.dAdd('oxed.icons', @deinit);

END.
