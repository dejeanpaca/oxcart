{
   oxuFreetypeFonts, freetype font support
   Copyright (c) 2018. Dejan Boras

   Started On:    28.05.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuFreetypeFonts;

INTERFACE

   USES
      {$IFDEF OX_FEATURE_FREETYPE}
      freetypeh,
      {$ENDIF}
      uStd, uLog, StringUtils, vmMath,
      uImage, imguOperations,
      {ox}
      uOX, oxuPaths, oxuGlobalInstances,
      oxuTexture, oxuTextureGenerate, oxuTypes, oxuFont, oxuFreetype, uSimpleParser
      {$IFNDEF OX_LIBRARY}, oxuRunRoutines{$ENDIF};

TYPE
   { oxTFreetypeManager }

   oxTFreetypeManager = class
      Lib: PFT_Library;
      Fonts: oxTFreetypeFonts;
      Enabled: Boolean;
      {should the image be flipped when font is created}
      FlipImage,
      {auto insert a space character if it does not exist in the font}
      AutoSpaceCharacter: boolean;
      {ratio for the space character size}
      AutoSpaceCharacterRatio: single;

      AlphaType: oxTFreetypeAlphaType;

      constructor Create();

      function Load(const name, path: string; faceIndex: longint = 0; size: longint = 0; keep: boolean = true): oxTFreetypeFont;
      procedure Dispose(var bitmaps: oxTFreetypeBitmaps);
      procedure Dispose(const f: oxTFreetypeFonts);

      function FindFont(const name: string): oxTFreetypeFont;

      function CreateFont(ft: oxTFreetypeFont; size: longint = 12; base: longint = 32; charCount: longint = 94): oxTFont;
      function CreateFont(const path: string; size: longint = 12; base: longint = 32; charCount: longint = 94): oxTFont;

      procedure LoadFontsList();
      class procedure Initialize(); static;
      class procedure Deinitialize(); static;
   end;

VAR
   oxFreetypeManager: oxTFreetypeManager;

IMPLEMENTATION

{ oxTFreetypeManager }

constructor oxTFreetypeManager.Create();
begin
   Fonts.Initialize(Fonts);

   AutoSpaceCharacter := true;
   AutoSpaceCharacterRatio := 0.5;
   AlphaType := oxFREETYPE_ALPHA_AVERAGE;
end;

function oxTFreetypeManager.Load(const name, path: string; faceIndex: longint; size: longint; keep: boolean): oxTFreetypeFont;
var
   face: PFT_Face;
   error: integer;
   fn: string;
   font: oxTFreetypeFont;

begin
   {$IFDEF OX_FEATURE_FREETYPE}
   if(not Enabled) then
      exit(nil);

   face := nil;
   Result := nil;
   fn := oxPaths.Find(path);

   error := FT_New_Face(Lib, PChar(fn), faceIndex, face);
   if(error = 0) then begin
      if(size <> 0) then
         FT_Set_Pixel_Sizes(face, 0, size);

      font := oxTFreetypeFont.Create();
      font.FontName := name;
      font.Face := face;
      font.Scalable := face^.face_flags and FT_FACE_FLAG_SCALABLE > 0;
      font.AlphaType := AlphaType;

      if(keep) then
         Fonts.Add(font);

      Result := font;
      log.v('FreeType loaded ' + fn + ' > ' + sf(face^.num_glyphs));
   end else begin
(*      if(error = FT_Err_Unknown_File_Format) then
         log.e('Unknown file format')
      else*)
         log.e('FreeType face load failed with error: ' + sf(error));

      log.e('Failed loading: ' + fn);
   end;
   {$ELSE}
   Result := nil;
   {$ENDIF}
end;

procedure oxTFreetypeManager.Dispose(var bitmaps: oxTFreetypeBitmaps);
var
   i: loopint;

begin
   for i := 0 to (bitmaps.n - 1) do begin
      FreeMem(bitmaps.List[i].Data);
   end;

   bitmaps.Dispose();
end;

procedure oxTFreetypeManager.Dispose(const f: oxTFreetypeFonts);
var
   i: loopint;

begin
   for i := 0 to (f.n - 1) do
      FreeObject(f.List[i]);

   f.Dispose();
end;

function oxTFreetypeManager.FindFont(const name: string): oxTFreetypeFont;
var
   i: loopint;

begin
   for i := 0 to Fonts.n - 1 do begin
      if(Fonts.List[i].FontName = name) then
         exit(Fonts.List[i]);
   end;

   Result := nil;
end;

function oxTFreetypeManager.CreateFont(ft: oxTFreetypeFont; size: longint; base: longint; charCount: longint): oxTFont;
const
   MAX_CHARS = 4096;

var
   i,
   {last advance value}
   lastAdvance,
   {maximum advance value}
   maxAdvance: loopint;

   fontImages: array[0..MAX_CHARS - 1] of imgTImage;
   Characters: array[0..MAX_CHARS - 1] of oxTFreetypeFontGlyphData;
   font: oxTFont;
   fontImage: imgTImage;
   fontTexture: oxTTexture;

   pFlipVertically: boolean;

   {width of the generated image}
   imageWidth,
   imageHeight: loopint;

   {is the font monospace}
   monospace: boolean;
   {we have automatically included space}
   autoIncludedSpace: loopint;

   {total width of all glyphs}
   totalGlyphWidth: loopint = 0;

   {texture generate}
   gen: oxTTextureGenerate;

   cX,
   currentLine: longint;

procedure calculateGlyph(image: imgTImage);
begin
   if(cX + image.Width >= imageWidth) then begin
      cX := 0;
      inc(font.Lines);
   end;

   inc(cX, image.Width);

   if(font.Lines * size > imageHeight) then
      imageHeight := vmNextPow2(int64(font.Lines) * int64(size));
end;

procedure addGlyph(image: imgTImage; character: longint);
var
   n: loopint;

begin
   n := character - base;

   font.Characters[n].BearingX := Characters[n].BearingX;
   font.Characters[n].BearingY := Characters[n].BearingY;
   font.Characters[n].Advance := Characters[n].Advance;

   if(image <> nil) then begin
      font.Characters[n].Width := image.Width;
      font.Characters[n].Height := image.Height;

      if(cX + image.Width >= imageWidth) then begin
         cX := 0;
         inc(currentLine);
      end;

      image.CopyArea(fontImage, 0, 0, cX, currentLine * size, image.Width, image.Height);

      inc(cX, image.Width);
   end else begin
      font.Characters[n].Width := 0;
      font.Characters[n].Height := 0;
   end;
end;

begin
   Result := nil;

   if(charCount <= 0) then
      exit(nil);

   if(charCount > MAX_CHARS) then
      charCount := MAX_CHARS;

   ZeroOut(fontImages, SizeOf(fontImages));
   ZeroOut(Characters, SizeOf(Characters));

   if(ft <> nil) then begin
      pFlipVertically := ft.FlipVertically;
      {the font is assumed monospace}
      monospace := true;
      {we have not auto included space yet}
      autoIncludedSpace := -1;

      {we'll do this ourselves anyways}
      ft.FlipVertically := false;

      font        := oxTFont.Create();
      font.Base   := base;
      font.Chars  := charCount;
      font.TextureBaseline := true;
      font.fn     := ft.FontName + '-' + sf(size);
      font.Width  := size;
      font.Height := size;

      {we fit as many characters per line as possible}
      font.CPLine := 0;
      font.Lines := 1;

      {allocate but do not initialize chars (we're gonna set values for them anyways)}
      font.AllocateChars(false);

      {no last advance value yet}
      lastAdvance := -1;
      maxAdvance := 0;

      for i := 0 to (charCount - 1) do begin
         Characters[i] := ft.CreateGlyphImage(base + i, fontImages[i], size);

         {check if font is monospace}
         if(fontImages[i] <> nil) then begin
            if(Characters[i].Advance > maxAdvance) then
               maxAdvance := Characters[i].Advance;

            {check with last valid lastAdvance value}
            if(lastAdvance <> -1) then begin
               if(Characters[i].Advance <> lastAdvance) then
                  monospace := false;
            end;

            lastAdvance := Characters[i].Advance;
         end else begin
            Characters[i].Advance := -1;
         end;

         {auto include space if missing}
         if(fontImages[i] = Nil) and (char(base + i) = #32) and (oxFreetypeManager.AutoSpaceCharacter) then begin
            autoIncludedSpace := i;

            {educated guess for space size}
            Characters[i].Advance := round(Font.Width * oxFreetypeManager.AutoSpaceCharacterRatio);
         end;
      end;

      {get total glyph length}
      for i := 0 to (charCount - 1) do begin
         if(fontImages[i] <> nil) then
            totalGlyphWidth := totalGlyphWidth + fontImages[i].Width;
      end;

      {st proper width}
      font.Width := maxAdvance;

      {set proper value for auto included space if monospace font}
      if(monospace) and (autoIncludedSpace <> -1) then begin
         Characters[autoIncludedSpace].Advance := maxAdvance;
      end;

      font.Monospace := monospace;

      {determine initial image width and height and round it to powers of two}
      imageWidth := vmNextPow2(round(sqrt(size * totalGlyphWidth)));
      imageHeight := imageWidth;

      {calculate dimensions}
      cX := 0;

      for i := 0 to (charCount - 1) do begin
         if(Characters[i].Advance = -1) then
            Characters[i].Advance := font.Width;

         if(fontImages[i] <> nil) then
            calculateGlyph(fontImages[i]);
      end;

      {create a new font image}
      fontImage := img.MakeBlank(imageWidth, imageHeight, PIXF_RGBA);
      fontImage.Clear();

      {start generating glyphs}
      cX := 0;
      currentLine := 0;

      for i := 0 to (charCount - 1) do begin
         addGlyph(fontImages[i], base + i);
      end;

      {generate font texture}
      oxTextureGenerate.Init(gen);
      gen.Filter := oxFont.Filter;

      imgOperations.FlipV(fontImage);
      oxTextureGenerate.Generate(fontImage, fontTexture);

      font.Texture := fontTexture;

      font.Build();

      {dispose of all images}
      for i := 0 to (charCount - 1) do begin
         if(fontImages[i] <> nil) then
            img.Dispose(fontImages[i]);
      end;

      ft.FlipVertically := pFlipVertically;

      FreeObject(fontImage);

      gen.Dispose();
      exit(font);
   end;

   Result := nil;
end;

function oxTFreetypeManager.CreateFont(const path: string; size: longint; base: longint; charCount: longint): oxTFont;
var
   ftFont: oxTFreetypeFont;
   fontLoaded: boolean = false;

begin
   Result := nil;

   if(charCount <= 0) then
      exit(nil);

   ftFont := oxFreetypeManager.FindFont(path);

   if(ftFont = nil) then begin
      ftFont := Load('', path, 0, 0, false);
      fontLoaded := true;
   end;

   if(ftFont <> nil) then begin
      Result := CreateFont(ftFont, size, base, charCount);

      if(fontLoaded) then
         FreeObject(ftFont);
   end;
end;

function readFontList(var p: TParseData): boolean;
var
   path: string;

begin
   Result := true;

   {add font specified with value (path)}
   if(p.Value <> '') then begin
      path := oxPaths.Find(oxPaths.Fonts + p.Value);

      if(path <> '') then begin
         oxFreetypeManager.Load(p.Key, path);
         log.v('Loaded font as ' + p.Key);
      end else
         log.w('Cannot find font ' + p.Key + ' in path: ' + p.Value);
   end;
end;

procedure oxTFreetypeManager.LoadFontsList();
var
   path: string;
   p: TParseData;

begin
   path := oxPaths.Find(oxPaths.Fonts + 'fonts.list');

   if(path <> '') then begin
      TParseData.InitKeyValue(p);
      p.ReadMethod := TParseMethod(@readFontList);
      p.KeyValueSeparator := ' ';
      p.Read(path);

      log.v('Loaded fonts list from: ' + path);
   end;

   if(FindFont('default') = nil) then begin
      {add default font}
      path := oxPaths.Find(oxPaths.Fonts + 'FontAwesome.otf');

      if(path <> '') then
         Load('default', path);
   end;
end;

class procedure oxTFreetypeManager.Initialize();
{$IFDEF OX_FEATURE_FREETYPE}
var
   major,
   minor,
   patch: integer;
{$ENDIF}

begin
   oxFreetypeManager.Enabled := false;

   {$IFDEF OX_FEATURE_FREETYPE}
   if(FT_Init_FreeType(oxFreeTypeManager.Lib) = 0) then begin
      oxFreetypeManager.Enabled := true;

      major := 0;
      minor := 0;
      patch := 0;

      FT_Library_Version(oxFreetypeManager.Lib, major, minor, patch);
      log.v('FreeType (' + sf(major) + '.' + sf(minor) + '.' + sf(patch) + ') initialized');

      oxFreetypeManager.LoadFontsList();
   end else
      log.e('FreeType library initialization failed');
   {$ELSE}
   log.w('Freetype functionality disabled');
   {$ENDIF}
end;

class procedure oxTFreetypeManager.Deinitialize();
begin
   oxFreetypeManager.Dispose(oxFreetypeManager.Fonts);

   if(oxFreetypeManager.Lib <> nil) then begin
      {$IFDEF OX_FEATURE_FREETYPE}
      if(FT_Done_FreeType(oxFreeTypeManager.Lib) = 0) then
         log.v('FreeType deinitialized')
      else
         log.e('FreeType library deinitialization failed');

      oxFreeTypeManager.Lib := nil;
      {$ENDIF}
   end;
end;

function instance(): TObject;
begin
   Result := oxTFreetypeManager.Create();
end;

{$IFNDEF OX_LIBRARY}
procedure initialize();
begin
   oxTFreetypeManager.Initialize();
end;

procedure deinitialize();
begin
   oxTFreetypeManager.Deinitialize();
end;

{$ENDIF}

INITIALIZATION
   oxGlobalInstances.Add(oxTFreetypeManager, @oxFreetypeManager, @instance)^.
      CopyOverReference := true;

   {$IFNDEF OX_LIBRARY}
   ox.Init.Add('ox.freetype', @initialize, @deinitialize);
   {$ENDIF}

END.
