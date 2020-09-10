{
   oxuGlyphs, glyph loading from textures/fonts
   Copyright (c) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuGlyphs;

INTERFACE

   USES
      uStd, uLog, StringUtils,
      {ox}
      uOX, oxuRunRoutines,
      oxuResourcePool, oxuTexture, oxuTexturePool, oxuDefaultTexture,
      oxuGlyph, oxuFreetype, oxuFreetypeFonts;

TYPE
   oxPGlyphs = ^oxTGlyphs;

   { oxTGlyphs }

   oxTGlyphs = record
      GlyphPool: oxTTexturePool;
      DefaultSize: loopint;
      AlwaysReturnTexture: boolean;

      class procedure Init(out glyphs: oxTGlyphs); static;

      {get an existing map with the given name}
      function Get(const name: string): oxTTexture;
      function LoadGlyph(const name: string; code: loopint; size: loopint): oxTGlyph;
      function LoadTexture(const name: string; code: loopint; size: loopint): oxTTexture;
      function Load(const name: string; size: loopint = 0): oxTTexture;
      function Load(code: loopint; size: loopint = 0): oxTTexture;
      function LoadGlyph(const name: string; size: loopint = 0): oxTGlyph;
      function LoadGlyph(code: loopint; size: loopint = 0): oxTGlyph;

      {split path into source and name(the actual path in the source)}
      class procedure SplitSourceName(const path: string; out source, name: string); static;

      {destroy all glyphs}
      procedure Destroy();
   end;

VAR
   oxGlyphs: oxTGlyphs;

IMPLEMENTATION

{ oxTGlyphs }

class procedure oxTGlyphs.Init(out glyphs: oxTGlyphs);
begin
   ZeroOut(glyphs, SizeOf(glyphs));

   glyphs.DefaultSize := 64;
   glyphs.GlyphPool := oxTTexturePool.Create();
   glyphs.GlyphPool.Name := 'glyphs';

   glyphs.AlwaysReturnTexture := true;
end;

function oxTGlyphs.Get(const name: string): oxTTexture;
begin
   Result := oxTTexture(GlyphPool.FindByPath(name));
end;

function oxTGlyphs.LoadGlyph(const name: string; code: loopint; size: loopint): oxTGlyph;
var
   path,
   source,
   newName: string;
   font: oxTFreetypeFont;
   valCode: loopint;

   monospaced,
   exactSize,
   maxPixelValues: boolean;
   alphaType: oxTFreetypeAlphaType;

   glyph: oxTFreetypeFontGlyphData;

procedure storeGlyphData();
begin
   Result.Width := glyph.Width;
   Result.Height := glyph.Height;
   Result.BearingX := glyph.BearingX;
   Result.BearingY := glyph.BearingY;
   Result.Advance := glyph.Advance;
end;

begin
   oxTGlyph.Init(Result);

   source := '';
   newName := '';
   path := '';
   valCode := 0;

   if(size = 0) then
      size := DefaultSize;

   if(code <> 0) then begin
      path := sf(code);
      newName := path;
   end else begin
      path := name;
      code := 0;
      oxTGlyphs.SplitSourceName(name, source, newName);
   end;

   Result.Texture := oxTTexture(GlyphPool.FindByPath(path));
   if(Result.Texture <> nil) then
      Result.Texture.MarkUsed();

   if(source <> '') then
      font := oxFreetypeManager.FindFont(source)
   else
      font := oxFreetypeManager.FindFont('default');

   if(Result.Texture <> nil) then begin
      if(code <> 0) then
         glyph := font.GetGlyphData(code, Size)
      else
         glyph := font.GetGlyphData(Name, Size);

      storeGlyphData();

      exit();
   end;

   if(font <> nil) then begin
      if(code = 0) then begin
         Val(newName, code, valCode);

         if(valCode <> 0) then
            code := 0;
      end;

      monospaced := font.Square;
      exactSize := font.ExactSize;
      alphaType := font.AlphaType;
      maxPixelValues := font.MaxPixelValues;

      font.Square := true;
      font.ExactSize := true;
      font.AlphaType := oxFREETYPE_ALPHA_AVERAGE;
      font.MaxPixelValues := true;


      if(code <> 0) then
         glyph := font.CreateGlyphTexture(code, Result.Texture, Size)
      else
         glyph := font.CreateGlyphTexture(Name, Result.Texture, Size);

      storeGlyphData();

      font.Square := monospaced;
      font.ExactSize := exactSize;
      font.AlphaType := alphaType;
      font.MaxPixelValues := maxPixelValues;

      if(Result.Texture <> nil) then begin
         Result.Texture.Path := path;
         GlyphPool.AddResource(Result.Texture);
      end;
   end;

   if(AlwaysReturnTexture) and (Result.Texture = nil) then
      Result.Texture := oxDefaultTexture.Texture;
end;

function oxTGlyphs.LoadTexture(const name: string; code: loopint; size: loopint): oxTTexture;
var
   glyph: oxTGlyph;

begin
   glyph := LoadGlyph(name, code, size);
   Result := glyph.Texture;
end;


function oxTGlyphs.Load(const name: string; size: loopint): oxTTexture;
begin
   Result := LoadTexture(name, 0, size);
end;

function oxTGlyphs.Load(code: loopint; size: loopint): oxTTexture;
begin
   Result := LoadTexture('', code, size);
end;

function oxTGlyphs.LoadGlyph(const name: string; size: loopint): oxTGlyph;
begin
   Result := LoadGlyph(name, 0, size);
end;

function oxTGlyphs.LoadGlyph(code: loopint; size: loopint): oxTGlyph;
begin
   Result := LoadGlyph('', code, size);
end;

class procedure oxTGlyphs.SplitSourceName(const path: string; out source, name: string);
begin
   GetKeyValue(path, source, name, ':');
end;

procedure oxTGlyphs.Destroy();
begin
   FreeObject(GlyphPool);
end;

procedure init();
begin
   oxTGlyphs.Init(oxGlyphs);
end;

procedure deinit();
begin
   oxGlyphs.Destroy();
end;

INITIALIZATION
   ox.Init.Add('ox.glyphs', @init, @deinit);

END.
