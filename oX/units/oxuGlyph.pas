{
   oxuGlyph, glyph loading from textures/fonts
   Copyright (c) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuGlyph;

INTERFACE

   USES
      uStd, uLog, StringUtils,
      {ox}
      uOX, oxuRunRoutines,
      oxuResourcePool, oxuTexture, oxuTexturePool, oxuDefaultTexture, oxuFreetype, oxuFreetypeFonts;

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
      function LoadTexture(const name: string; code: loopint; size: loopint): oxTTexture;
      function Load(const name: string; size: loopint = 0): oxTTexture;
      function Load(code: loopint; size: loopint = 0): oxTTexture;

      {split path into source and name(the actual path in the source)}
      class procedure SplitSourceName(const path: string; out source, name: string); static;

      {destroy all glyphs}
      procedure Destroy();
   end;

VAR
   oxGlyphs: oxTGlyphs;

IMPLEMENTATION

function oxTGlyphs.LoadTexture(const name: string; code: loopint; size: loopint): oxTTexture;
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

begin
   source := '';
   newName := '';
   path := '';
   Result := nil;
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

   Result := oxTTexture(GlyphPool.FindByPath(path));
   if(Result <> nil) then begin
      Result.MarkUsed();
      exit();
   end;

   if(source <> '') then
      font := oxFreetypeManager.FindFont(source)
   else
      font := oxFreetypeManager.FindFont('default');

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
         font.CreateGlyphTexture(code, Result, Size)
      else
         font.CreateGlyphTexture(Name, Result, Size);

      font.Square := monospaced;
      font.ExactSize := exactSize;
      font.AlphaType := alphaType;
      font.MaxPixelValues := maxPixelValues;

      if(Result <> nil) then begin
         Result.Path := path;
         GlyphPool.AddResource(Result);
      end;
   end;

   if(AlwaysReturnTexture) and (Result = nil) then
      Result := oxDefaultTexture.Texture;
end;

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

function oxTGlyphs.Load(const name: string; size: loopint): oxTTexture;
begin
   Result := LoadTexture(name, 0, size);
end;

function oxTGlyphs.Load(code: loopint; size: loopint): oxTTexture;
begin
   Result := LoadTexture('', code, size);
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
