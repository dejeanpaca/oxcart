{
   oxuFreetype, freetype support
   Copyright (c) 2017. Dejan Boras

   Started On:    23.04.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuFreetype;

INTERFACE

   USES
      {$IFDEF OX_FEATURE_FREETYPE}
      freetypeh,
      {$ENDIF}
      uStd, uLog, StringUtils, vmMath,
      uImage, imguOperations,
      {ox}
      uOX, oxuPaths, oxuTexture, oxuTextureGenerate, oxuFont;

TYPE
   oxTFreetypeAlphaType = (
      oxFREETYPE_ALPHA_ZERO,
      oxFREETYPE_ALPHA_AVERAGE,
      oxFREETYPE_ALPHA_INVERSE_AVERAGE
   );

   { oxTFreetypeBitmap }
   oxTFreetypeBitmap = record
      Index,
      Width,
      Pitch,
      Height,
      BearingX,
      BearingY,
      Advance,
      Size: loopint;
      Data: pbyte;
   end;

   oxTFreetypeBitmaps = specialize TSimpleList<oxTFreetypeBitmap>;

   { oxTFreetypeFontGlyphData }
   oxTFreetypeFontGlyphData = record
      BearingX,
      BearingY,
      Advance: longint;
   end;

   {$IFNDEF OX_FEATURE_FREETYPE}
   PFT_Face = pointer;
   FT_Uint = longword;
   FT_int = longint;
   PFT_Library = pointer;
   {$ENDIF}

   { oxTFreetypeFont }

   oxTFreetypeFont = class
      FontName: string;

      Face: PFT_Face;
      Scalable: Boolean;
      AlphaType: oxTFreetypeAlphaType;
      {create images with same width and height}
      Square,
      ExactSize,
      {flip vertically}
      FlipVertically,
      {flip image horizontally}
      FlipHorizontally,
      {set pixel values to max (non-zero to 255)}
      MaxPixelValues: boolean;

      {information about the last generated glyph}
      GlyphInfo: record
         Width,
         Height: longint;
      end;

      constructor Create();

      destructor Destroy(); override;

      function GetGlyphGray(c: char; size: longint): oxTFreetypeBitmap;
      function GetGlyphGray(c: UnicodeChar; size: longint): oxTFreetypeBitmap;
      function GetGlyphGray(c: LongWord; size: longint; index: FT_UInt = 0): oxTFreetypeBitmap;
      function GetGlyphGray(const name: string; size: longint): oxTFreetypeBitmap;

      function CreateGlyphImage(c: longword; out glyphImage: imgTImage; size: longint = 12; index: FT_UInt = 0): oxTFreetypeFontGlyphData;
      function CreateGlyphTexture(c: longword; out tex: oxTTexture; size: longint = 12; index: FT_UInt = 0): oxTFreetypeFontGlyphData;

      function CreateGlyphImage(const name: string; out glyphImage: imgTImage; size: longint = 12): oxTFreetypeFontGlyphData;
      function CreateGlyphTexture(const name: string; out tex: oxTTexture; size: longint = 12): oxTFreetypeFontGlyphData;
   end;

   oxTFreetypeFonts = specialize TSimpleList<oxTFreetypeFont>;

{$IFDEF OX_FEATURE_FREETYPE}
function FT_Get_Name_Index(face: PFT_Face; glyph_name: PChar): FT_UInt; cdecl; external freetypedll Name 'FT_Get_Name_Index';
{$ENDIF}

IMPLEMENTATION

{ oxTFreetypeFont }

constructor oxTFreetypeFont.Create();
begin
   FlipVertically := true;
   MaxPixelValues := true;
   AlphaType := oxFREETYPE_ALPHA_AVERAGE;
end;

destructor oxTFreetypeFont.Destroy();
begin
   inherited;

   if(Face <> nil) then begin
      {$IFDEF OX_FEATURE_FREETYPE}
      FT_Done_Face(Face);
      {$ENDIF}
   end;
end;

function oxTFreetypeFont.GetGlyphGray(c: char; size: longint): oxTFreetypeBitmap;
begin
   Result := GetGlyphGray(ord(c), size);
end;

function oxTFreetypeFont.GetGlyphGray(c: UnicodeChar; size: longint): oxTFreetypeBitmap;
begin
   Result := GetGlyphGray(ord(c), size);
end;

function oxTFreetypeFont.GetGlyphGray(c: LongWord; size: longint; index: FT_UInt = 0): oxTFreetypeBitmap;
{$IFDEF OX_FEATURE_FREETYPE}
var
   error: longint;
   trans : FT_Matrix;
   angle: single;
   glyph: PFT_Glyph;

   bm: PFT_BitmapGlyph;
   sizeSet: longint;
{$ENDIF}

begin
   {$IFDEF OX_FEATURE_FREETYPE}
   ZeroOut(Result, SizeOf(Result));

   if(index = 0) then begin
      index := FT_Get_Char_Index(Face, c);

      if(index = 0) then
         exit();
   end;

   glyph := nil;

   GlyphInfo.Width := 0;
   GlyphInfo.Height := 0;

   if(index <> 0) then begin
      Result.Index := index;

      angle := 0;
      trans.xx := round( cos(angle) * $10000);
      trans.xy := round(-sin(angle) * $10000);
      trans.yx := round( sin(angle) * $10000);
      trans.yy := round( cos(angle) * $10000);

      sizeSet := Size * 64;
      error := FT_Set_char_size(Face, sizeSet, sizeSet, 72, 72);

      error := FT_Load_Glyph(Face, index, FT_LOAD_DEFAULT);
      if(error = 0) then begin
         Result.Advance := face^.glyph^.advance.x shr 6;

         error := FT_Get_Glyph(Face^.glyph, glyph);

         FT_Glyph_Transform(glyph, @trans, nil);

         FT_Glyph_To_Bitmap(glyph, FT_RENDER_MODE_NORMAL, nil, true);
         bm := PFT_BitmapGlyph(glyph);

         Result.Width := bm^.bitmap.width;
         Result.Height := bm^.bitmap.rows;
         Result.Pitch := bm^.bitmap.pitch;
         Result.BearingX := bm^.left;
         Result.BearingY := bm^.top;

         GlyphInfo.Width := Result.Width;
         GlyphInfo.Height := Result.Height;

         Result.Size := Result.Pitch * Result.Height;

         if(Result.Size > 0) then begin
            GetMem(Result.Data, Result.Size);
            Move(bm^.bitmap.buffer^, Result.Data[0], Result.Size);
         end;

         FT_Done_Glyph(glyph);
         exit();
      end else
         log.e('Failed to load glyph: ' + sf(c));
   end else
      log.e('Could not find requested glyph: ' + sf(c));
   {$ELSE}
   ZeroOut(Result, SizeOf(Result));
   {$ENDIF}
end;

function oxTFreetypeFont.GetGlyphGray(const name: string; size: longint): oxTFreetypeBitmap;
var
   index: FT_UInt;

begin
   {$IFDEF OX_FEATURE_FREETYPE}
   index := FT_Get_Name_Index(Face, PChar(name));

   if(index > 0) then
      Result := GetGlyphGray(0, size, index)
   else begin
      log.w('Could not find glyph index for name ' + name + ' while getting glyph');
      ZeroOut(Result, SizeOf(Result));
   end;
   {$ELSE}
   ZeroOut(Result, SizeOf(Result));
   {$ENDIF}
end;

function oxTFreetypeFont.CreateGlyphImage(c: longword; out glyphImage: imgTImage; size: longint; index: FT_UInt): oxTFreetypeFontGlyphData;
var
   bmp: oxTFreetypeBitmap;
   image: imgTImage;
   error: longint;
   wh: longint;

begin
   glyphImage := nil;

   bmp := GetGlyphGray(c, size, index);

   if(bmp.Data <> nil) then begin
      Result.BearingX := bmp.BearingX;
      Result.BearingY := bmp.BearingY;
      Result.Advance := bmp.Advance;

      if(bmp.Size > 0) then begin
         {create a blank image to store the glyph in imgTImage format}
         image := img.MakeBlank(bmp.width, bmp.height, PIXF_GREYSCALE_8);

         {copy over data from the glyph}
         Move(bmp.data^, image.Image^, image.Size);

         {convert glyph image to wanted format}
         if(imgOperations.Transform(image, PIXF_RGBA) <> 0) then
            log.e('Failed to transform glyph: ' + sf(c));

         {copy image to destination}
         if(not Square) then begin
            if(not ExactSize) then
               glyphImage := img.MakeBlank(bmp.width, bmp.height, PIXF_RGBA)
            else
               glyphImage := img.MakeBlank(bmp.Width, size, PIXF_RGBA)
         end else begin
            if(not ExactSize) then begin
               wh := bmp.Height;
               if(bmp.Width > wh) then
                  wh := bmp.Width;
            end else
               wh := size;

            glyphImage := img.MakeBlank(wh, wh, PIXF_RGBA);
         end;

         imgOperations.Fill(glyphImage, 0);

         if(glyphImage.Width = image.Width) and (glyphImage.Height = image.Height) then
            error := image.CopyArea(glyphImage, 0, 0, 0, 0, image.Width, image.Height)
         else
            error := image.CopyArea(glyphImage, 0, 0, (glyphImage.Width - bmp.Width) div 2, (glyphImage.Height - bmp.Height) div 2, image.Width, image.Height);

         if(error <> 0) then
            log.e('Failed to copy glyph(' + sf(image.Width) + 'x' + sf(image.Height) + '): ' + sf(c));

         if(AlphaType = oxFREETYPE_ALPHA_ZERO) then
            imgOperations.AlphaZero(glyphImage)
         else if(AlphaType = OXFREETYPE_ALPHA_AVERAGE) then
            imgOperations.AlphaFromAverage(glyphImage)
         else if(AlphaType = oxFREETYPE_ALPHA_INVERSE_AVERAGE) then
            imgOperations.AlphaFromInverseAverage(glyphImage);

         if(MaxPixelValues) then
            imgOperations.MaxPixelValues(glyphImage);

         if(FlipVertically) then begin
            glyphImage.Origin := imgcORIGIN_BL;
            imgOperations.FlipV(glyphImage);
         end;

         if(FlipHorizontally) then begin
            imgOperations.FlipH(glyphImage);

            if(FlipVertically) then
               glyphImage.Origin := imgcORIGIN_BR
            else
               glyphImage.Origin := imgcORIGIN_BL;
         end;

         img.Dispose(image);
      end;

      FreeMem(bmp.Data);
   end else begin
      ZeroPtr(@Result, SizeOf(Result));

      log.e('Failed to get glyph bitmap for: ' + sf(c));
      exit;
   end;
end;

function oxTFreetypeFont.CreateGlyphTexture(c: longword; out tex: oxTTexture; size: longint; index: FT_UInt): oxTFreetypeFontGlyphData;
var
   glyphImage: imgTImage = nil;

begin
   tex := nil;

   Result := CreateGlyphImage(c, glyphImage, size, index);

   if(glyphImage <> nil) then
      oxTextureGenerate.Generate(glyphImage, tex);

   img.Dispose(glyphImage);
end;

function oxTFreetypeFont.CreateGlyphImage(const name: string; out glyphImage: imgTImage; size: longint): oxTFreetypeFontGlyphData;
var
   index: longint;

begin
   {$IFDEF OX_FEATURE_FREETYPE}
   index := FT_Get_Name_Index(Face, PChar(name));

   if(index > 0) then
      Result := CreateGlyphImage(0, glyphImage, size, index)
   else begin
      glyphImage := nil;
      ZeroOut(Result, SizeOf(Result));
      log.w('Could not find glyph index for name ' + name + ' while creating image');
   end;
   {$ELSE}
   glyphImage := nil;
   ZeroOut(Result, SizeOf(Result));
   {$ENDIF}
end;

function oxTFreetypeFont.CreateGlyphTexture(const name: string; out tex: oxTTexture; size: longint): oxTFreetypeFontGlyphData;
var
   index: longint;

begin
   {$IFDEF OX_FEATURE_FREETYPE}
   index := FT_Get_Name_Index(Face, PChar(name));

   if(index > 0) then
      Result := CreateGlyphTexture(0, tex, size, index)
   else begin
      tex := nil;
      ZeroOut(Result, SizeOf(Result));
      log.w('Could not find glyph index for name ' + name + ' while creating texture');
   end;
   {$ELSE}
   tex := nil;
   ZeroOut(Result, SizeOf(Result));
   {$ENDIF}
end;

END.
