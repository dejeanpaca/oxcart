{
   oxuGlyph, glyph loading from textures/fonts
   Copyright (c) 2018. Dejan Boras

   Started On:    19.08.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuGlyph;

INTERFACE

   USES
      uStd, uLog, StringUtils,
      {ox}
      uOX, oxuResourcePool, oxuTexture, oxuTexturePool, oxuFreetype, oxuDefaultTexture;

TYPE
   oxPGlyphs = ^oxTGlyphs;
   oxPGlyphMap = ^oxTGlyphMap;

   { oxTGlyphMap }

   oxTGlyphMap = record
      {font code for the glyph}
      Code,
      {size of the glyph in pixels}
      Size: loopint;
      {glyph name}
      Name: string;
      {source and path to the glyph}
      Path: string;
      {texture associated with the glyph}
      Texture: oxTTexture;
      {glyph manager}
      Root: oxPGlyphs;

      {load the glyph}
      function Load(): boolean;
      {unload the glyph}
      procedure Unload();

      {get a texture (if none, return the default one if AlwaysReturnTexture is true)}
      function GetTexture(): oxTTexture;
   end;

   oxTGlyphMaps = specialize TPreallocatedArrayList<oxTGlyphMap>;

   { oxTGlyphs }

   oxTGlyphs = record
      Maps: oxTGlyphMaps;
      GlyphPool: oxTTexturePool;
      DefaultSize: loopint;
      AlwaysReturnTexture: boolean;

      class procedure Init(out glyphs: oxTGlyphs); static;

      {get an existing map with the given name}
      function Get(const name: string): oxPGlyphMap;
      function Load(const name: string; const path: string; size: loopint = 0): oxPGlyphMap;
      function Load(code: loopint; size: loopint = 0): oxPGlyphMap;

      {adds new map or returns matching existing one}
      function AddMap(const name: string; const path: string; size: loopint = 0): oxPGlyphMap;

      {split path into source and name(the actual path in the source)}
      class procedure SplitSourceName(const path: string; out source, name: string); static;

      {destroy all glyphs}
      procedure Destroy();
   end;

VAR
   oxGlyphs: oxTGlyphs;

IMPLEMENTATION

{ oxTGlyphMap }

function oxTGlyphMap.Load(): boolean;
var
   source,
   newPath: string;
   font: oxTFreetypeFont;
   c: LongWord;
   valCode: loopint;

   monospaced,
   exactSize: boolean;
   alphaType: oxTFreetypeAlphaType;

begin
   if(Texture = nil) then begin
      oxTGlyphs.SplitSourceName(path, source, newPath);

      if(source <> '') then
         font := oxFreetypeManager.FindFont(source)
      else
         font := oxFreetypeManager.FindFont('default');

      if(font <> nil) then begin
         Val(newPath, c, valCode);

         monospaced := font.Square;
         exactSize := font.ExactSize;
         alphaType := font.AlphaType;

         font.Square := true;
         font.ExactSize := true;
         font.AlphaType := oxFREETYPE_ALPHA_AVERAGE;

         if(valCode = 0) then begin
            Code := c;

            font.CreateGlyphTexture(c, Texture, Size);
         end else begin
            font.CreateGlyphTexture(Name, Texture, Size);
         end;

         font.Square := monospaced;
         font.ExactSize := exactSize;
         font.AlphaType := alphaType;

         if(Texture <> nil) then begin
            Root^.GlyphPool.AddResource(texture);
            Texture.MarkUsed();
         end;

         exit(Texture <> nil);
      end;

      exit(False);
   end;

   Result := True;
end;

procedure oxTGlyphMap.Unload();
begin
   oxResource.Destroy(Texture);
end;

function oxTGlyphMap.GetTexture(): oxTTexture;
begin
   Result := Texture;

   if(Texture = nil) and (Root^.AlwaysReturnTexture) then
      exit(oxDefaultTexture.Texture);
end;

{ oxTGlyphs }

class procedure oxTGlyphs.Init(out glyphs: oxTGlyphs);
begin
   ZeroOut(glyphs, SizeOf(glyphs));
   glyphs.DefaultSize := 128;
   glyphs.Maps.InitializeValues(glyphs.Maps);
   glyphs.GlyphPool := oxTTexturePool.Create();
   glyphs.AlwaysReturnTexture := true;
end;

function oxTGlyphs.Get(const name: string): oxPGlyphMap;
var
   i: loopint;

begin
   for i := 0 to Maps.n - 1 do begin
      if(Maps.List[i].Name = name) then
         exit(@Maps.List[i]);
   end;

   Result := nil;
end;

function oxTGlyphs.Load(const name: string; const path: string; size: loopint): oxPGlyphMap;
begin
   Result := AddMap(name, path, size);

   if(Result <> nil) then begin
      if(Result^.Texture = nil) then
         Result^.Load();
   end;
end;

function oxTGlyphs.Load(code: loopint; size: loopint): oxPGlyphMap;
var
   map: oxPGlyphMap = nil;
   codeName: string;

begin
   codeName := sf(code);
   map := oxGlyphs.Load(codeName, codeName, size);

   Result := map;
end;

function oxTGlyphs.AddMap(const name: string; const path: string; size: loopint): oxPGlyphMap;
var
   map: oxTGlyphMap;

begin
   Result := Get(name);

   if(Result = nil) and (name <> '') and (path <> '') then begin
      ZeroOut(map, SizeOf(map));
      map.Name := name;
      map.Path := path;
      map.Root := @Self;
      if(size = 0) then
         map.Size := DefaultSize
      else
         map.Size := size;

      Maps.Add(map);
      Result := Maps.GetLast();
   end;
end;

class procedure oxTGlyphs.SplitSourceName(const path: string; out source, name: string);
var
   p: loopint;

begin
   source := '';
   name := '';

   if(path[1] = '@') then begin
      p := Pos(':', path);

      if(p > 0) then begin
         source := Copy(path, 2, p - 2);
         name := Copy(path, p + 1, Length(path) - p);

         exit();
      end;
   end;

   name := path;
end;

procedure oxTGlyphs.Destroy();
var
   i: loopint;

begin
   for i := 0 to Maps.n - 1 do begin
      Maps.List[i].Unload();
   end;

   Maps.Dispose();

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
