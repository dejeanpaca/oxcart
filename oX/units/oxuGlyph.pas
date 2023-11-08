{
   oxuGlyph, glyph loading from textures/fonts
   Copyright (c) 2018. Dejan Boras

   Started On:    19.08.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuGlyph;

INTERFACE

   USES
      uStd, uLog,
      {ox}
      oxuTexture, oxuTexturePool, oxuFreetype;

TYPE
   oxPGlyphs = ^oxTGlyphs;
   oxPGlyphMap = ^oxTGlyphMap;

   { oxTGlyphMap }

   oxTGlyphMap = record
      Name: string;
      Path: string;
      Texture: oxTTexture;
      Root: oxPGlyphs;

      function Load(): boolean;
   end;

   oxTGlyphMaps = specialize TPreallocatedArrayList<oxTGlyphMap>;

   { oxTGlyphs }

   oxTGlyphs = record
      Maps: oxTGlyphMaps;
      GlyphPool: oxTTexturePool;
      DefaultSize: loopint;

      procedure Init();

      function Get(const name: string): oxPGlyphMap;
      function Load(const name: string; const path: string): oxPGlyphMap;

      function AddMap(const name: string; const path: string): oxPGlyphMap;

      function GetSourceNameFromPath(const path: string): string;
      function SeparatePathInSource(const path: string): string;
   end;

VAR
   oxGlyphs: oxTGlyphs;

IMPLEMENTATION

{ oxTGlyphMap }

function oxTGlyphMap.Load(): boolean;
var
   source, newPath: string;
   font: oxTFreetypeFont;
   c: LongWord;
   code: loopint;
   tex: oxTTexture = nil;

begin
   if(Texture = nil) then begin
      source := Root^.GetSourceNameFromPath(path);

      if(source <> '') then begin
         font := oxFreetypeManager.FindFont(source);

         if(font <> nil) then begin
            newPath := Root^.SeparatePathInSource(Path);
            Val(newPath, c, code);

            if(code = 0) then begin
               font.CreateGlyphTexture(c, tex, Root^.DefaultSize);

               Root^.GlyphPool.AddResource(texture);
               Texture.MarkUsed();

               exit(True);
            end else
               log.w('Invalid glyph font code for ' + Path);
         end;
      end else begin
         // TODO: Load texture
      end;

      exit(False);
   end;

   Result := True;
end;

{ oxTGlyphs }

procedure oxTGlyphs.Init();
begin
   ZeroOut(Self, SizeOf(Self));
   DefaultSize := 256;
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

function oxTGlyphs.Load(const name: string; const path: string): oxPGlyphMap;
begin
   Result := AddMap(name, path);

   if(Result <> nil) then begin
      if(Result^.Texture = nil) then
         Result^.Load();
   end;
end;

function oxTGlyphs.AddMap(const name: string; const path: string): oxPGlyphMap;
var
   map: oxTGlyphMap;

begin
   Result := Get(name);

   if(Result = nil) and (name <> '') and (path <> '') then begin
      ZeroOut(map, SizeOf(map));
      map.Name := name;
      map.Path := path;
      map.Root := @Self;

      Maps.Add(map);
      Result := Maps.GetLast();
   end;
end;

function oxTGlyphs.GetSourceNameFromPath(const path: string): string;
var
   p: loopint;
   source: string;

begin
   if(path[1] = '@') then begin
      p := Pos(':', path);
      if(p > 0) then begin
         source := Copy(path, 2, p - 2);
         exit(source);
      end;
   end;

   Result := '';
end;

function oxTGlyphs.SeparatePathInSource(const path: string): string;
var
   p: loopint;
   newPath: string;

begin
   if(path[1] = '@') then begin
      p := Pos(':', path);

      if(p > 0) then begin
         newPath := Copy(path, p + 1, Length(path) - p);
         exit(newPath);
      end;
   end;

   Result := '';
end;

INITIALIZATION
   oxGlyphs.Init();

END.
