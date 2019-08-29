{
   uImage, image loading/saving and manipulation
   Copyright (C) 2007. Dejan Boras

   Started On:    26.05.2007.
}

{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH ADVANCEDRECORDS}
UNIT uImage;

{Intended to provide a unified 'interface' and routines for reading/writing/manipulating images of various formats.}

INTERFACE

   USES uStd, uColors;

CONST
   imgcName = 'image';

   {ERROR CONSTANTS}
   imgeGENERAL                      = $0100;
   imgeLOADER_NOT_FOUND             = $0101;
   imgeWRITER_NOT_FOUND             = $0102;
   imgeFILEHANDLER                  = $0103;

   imgeUNSUPPORTED                  = $0104;
   imgeUNSUPPORTED_PIXF             = $0105;
   imgeUNSUPPORTED_DEPTH            = $0106;
   imgeUNSUPPORTED_CHANNEL_ORDER    = $0107;
   imgeUNSUPPORTED_CHANNELS         = $0108;
   imgeUNSUPPORTED_BPC              = $0109;
   imgeUNSUPPORTED_BPP              = $010A;
   imgeUNSUPPORTED_COLORMAP         = $010B;
   imgeUNSUPPORTED_COMPRESSION      = $010C;

   imgeINVALID_PIXF                 = $010D;
   imgeINVALID_DEPTH                = $010E;
   imgeINVALID_CHANNEL_ORDER        = $010F;
   imgeINVALID_CHANNELS             = $0110;
   imgeINVALID_BPC                  = $0111;
   imgeINVALID_BPP                  = $0112;
   imgeINVALID_COLORMAP             = $0113;
   imgeINVALID_COMPRESSION          = $0114;
   imgeINVALID_DIMENSIONS           = $0115;

   {GENERAL CONSTANTS}
   imgcNONE                         = $00; {refers to anything that supports none}

   {PIXEL FORMAT IDs}

   {INDEXED RGB/A}
   PIXF_INDEX_RGB_4     = 0000;
   PIXF_INDEX_4         = PIXF_INDEX_RGB_4;
   PIXF_INDEX_RGBA_4    = 0001;

   PIXF_INDEX_RGB_8     = 0002;
   PIXF_INDEX_8         = PIXF_INDEX_RGB_8;
   PIXF_INDEX_RGBA_8    = 0003;

   {INDEXED BGR/A}
   PIXF_INDEX_BGR_4     = 0004;
   PIXF_INDEX_BGR_8     = 0005;
   PIXF_INDEX_BGRA_4    = 0006;
   PIXF_INDEX_BGRA_8    = 0007;

   {PACKED RGB/A}
   PIXF_RGB_5_6_5       = 0008;
   PIXF_RGBA_5_5_5_1    = 0009;
   {PACKED BGR/A}
   PIXF_BGR_5_6_5       = 0010;
   PIXF_BGRA_5_5_5_1    = 0011;

   {RGB}
   PIXF_RGB             = 0012;
   PIXF_RGBA            = 0013;
   {BGR}
   PIXF_BGR             = 0014;
   PIXF_BGRA            = 0015;

   {48-bit}
   PIXF_RGB_48          = 0016;
   PIXF_RGBA_48         = 0017;
   PIXF_BGR_48          = 0018;
   PIXF_BGRA_48         = 0019;

   {INVERTED}
   PIXF_ARGB            = 0020;
   PIXF_ABGR            = 0021;

   {GREYSCALE}
   PIXF_GREYSCALE_8     = 0022;
   PIXF_GREYSCALE_16    = 0023;
   PIXF_GREYSCALE_32    = 0024;

   {SPECIAL TYPES}
   PIXF_ALPHA           = 0025;

   {maximum pixel format ID}
   PIXF_MAXIMUM         = 0025;

   {unsupported pixel format}
   PIXF_UNSUPPORTED     = 255;

   {COMPRESSION TYPES}
   {use imgcNONE to indicate no compression}
   imgcCOMPRESSION_NONE       = 0000;
   imgcCOMPRESSION_RLE        = 0001;

   {IMAGE ORIGINS}
   {image origin bitmasks}
   imgcBT_ORIGIN_VERTICAL     = 0001; {vertical origin, if 0 top, if 1 bottom}
   imgcBT_ORIGIN_HORIZONTAL   = 0002; {horizontal origin, if 0 left, if 1 right}

   imgcORIGIN_BL              = imgcBT_ORIGIN_VERTICAL;
   imgcORIGIN_BR              = imgcBT_ORIGIN_VERTICAL or imgcBT_ORIGIN_HORIZONTAL;
   imgcORIGIN_TL              = 0000;
   imgcORIGIN_TR              = imgcBT_ORIGIN_HORIZONTAL;
   imgcORIGIN_DEFAULT: longword = imgcORIGIN_TL;

   {color channel orders}
   PIXF_COLOR_CHANNEL_ORDER_RGB    = 0;
   PIXF_COLOR_CHANNEL_ORDER_BGR    = 1;
   PIXF_COLOR_CHANNEL_ORDER_MONO   = 2; {greyscale or monochromatic colors}

   {CHANNELS}
   imgccR   = $01;
   imgccG   = $02;
   imgccB   = $04;
   imgccA   = $08;
   imgcc0   = $10;
   imgcc1   = $20;
   imgcc2   = $40;
   imgcc3   = $80;

   {2 color channel constants, mostly used as a parameter for the color channel swap routine.}
   imgccRG  = imgccR or imgccG;
   imgccRB  = imgccR or imgccB;
   imgccGB  = imgccG or imgccB;
   {same as above three}
   imgccGR  = imgccRG;
   imgccBR  = imgccRB;
   imgccBG  = imgccGB;

   {5-bit to 8-bit color conversion table}
   imgc5To8Bits: array[0..31] of byte =
      (000,008,016,025,033,041,049,058,
       066,074,082,090,099,107,115,123,
       132,140,148,156,165,173,181,189,
       197,206,214,222,230,239,247,255);

   imgcFILE_TYPE_NORMAL = 00;
   imgcFILE_TYPE_TEXT   = 01;
   imgcFILE_TYPE_MEMORY = 02;

   {image properties}
   imgcPROPERTIES_PAL_EXTERNAL         = 0001; {external palette}

   imgcPIXFDepth: array[0..PIXF_MAXIMUM] of longint =
   {INDEX_RGB}
   (4,{PIXF_INDEX_RGB_4, PIXF_INDEX_4}
    4,{PIXF_INDEX_RGBA_4}
    8, {PIXF_INDEX_RGB_8, PIXF_INDEX_8}
    8, {PIXF_INDEX_RGBA_8}
    {INDEX_BGR}
    4,{PIXF_INDEX_BGR_4}
    4,{PIXF_INDEX_BGRA_4}
    8, {PIXF_INDEX_BGR_8}
    8, {PIXF_INDEX_BGRA_8}
    {PACKED RGB}
    16, {PIXF_RGB_5_6_5}
    16, {PIXF_RGB_5_5_5_1}
    16, {PIXF_BGR_5_6_5}
    16, {PIXF_BGR_5_5_5_1}
    {RGB/A}
    24, {PIXF_RGB}
    32, {PIXF_RGBA}
    {BGR/A}
    24, {PIXF_BGR}
    32, {PIXF_BGRA}
    {48 BIT}
    48, {PIXF_RGB_48}
    48, {PIXF_RGBA_48}
    48, {PIXF_BGR_48}
    48, {PIXF_BGRA_48}
    {A/RGB}
    32, {PIXF_ARGB}
    {A/BGR}
    32, {PIXF_ABGR}
    8, {PIXF_GREYSCALE_8}
    16, {PIXF_GREYSCALE_16}
    32, {PIXF_GREYSCALE_32}
    8 {PIXF_ALPHA}
    );

   imgcPIXFChannels: array[0..PIXF_MAXIMUM] of longint =
   {INDEXED RGB}
   (3, {PIXF_INDEX_RGB_4, PIXF_INDEX_4}
    4, {PIXF_INDEX_RGBA_4}
    3, {PIXF_INDEX_RGB_8, PIXF_INDEX_8}
    4, {PIXF_INDEX_RGBA_8}
    {INDEXED BGR}
    3, {PIXF_INDEX_BGR_4}
    4, {PIXF_INDEX_BGRA_4}
    3, {PIXF_INDEX_BGR_8}
    4, {PIXF_INDEX_BGRA_8}
    {PACKED}
    3, {PIXF_RGB_5_6_5}
    4, {PIXF_RGB_5_5_5_1}
    3, {PIXF_BGR_5_6_5}
    4, {PIXF_BGR_5_5_5_1}
    {RGB/BGR}
    3, {PIXF_RGB}
    4, {PIXF_RGBA}
    3, {PIXF_BGR}
    4, {PIXF_BGRA}
    {48 Bit}
    3, {PIXF_RGB_48}
    4, {PIXF_RGBA_48}
    3, {PIXF_BGR_48}
    4, {PIXF_BGRA_48}
    {INVERTED}
    4, {PIXF_ARGB}
    4, {PIXF_ABGR}
    {GREYSCALE}
    1, {PIXF_GREYSCALE_8}
    1, {PIXF_GREYSCALE_16}
    1,  {PIXF_GREYSCALE_32}
    {SPECIAL TYPES}
    1 {PIXF_ALPHA}
    );

   imgcPIXFNames: array[0..PIXF_MAXIMUM] of string =
   {INDEX_RGB}
   ('PIXF_INDEX_RGB_4',
    'PIXF_INDEX_RGBA_4',
    'PIXF_INDEX_RGB_8',
    'PIXF_INDEX_RGBA_8',
    {INDEX_BGR}
    'PIXF_INDEX_BGR_4',
    'PIXF_INDEX_BGRA_4',
    'PIXF_INDEX_BGR_8',
    'PIXF_INDEX_BGRA_8',
    {PACKED RGB}
    'PIXF_RGB_5_6_5',
    'PIXF_RGB_5_5_5_1',
    'PIXF_BGR_5_6_5',
    'PIXF_BGR_5_5_5_1',
    {RGB/A}
    'PIXF_RGB',
    'PIXF_RGBA',
    {BGR/A}
    'PIXF_BGR',
    'PIXF_BGRA',
    {48 BIT}
    'PIXF_RGB_48',
    'PIXF_RGBA_48',
    'PIXF_BGR_48',
    'PIXF_BGRA_48',
    {A/RGB}
    'PIXF_ARGB',
    {A/BGR}
    'PIXF_ABGR',
    {GREYSCALE}
    'PIXF_GREYSCALE_8',
    'PIXF_GREYSCALE_16',
    'PIXF_GREYSCALE_32',
    {ALPHA}
    'PIXF_ALPHA'
    );

   {channel types for pixel formats}
   PIXF_CHANNELS_RGB       = 0;
   PIXF_CHANNELS_RGBA      = 1;
   PIXF_CHANNELS_BGR       = 2;
   PIXF_CHANNELS_BGRA      = 3;
   PIXF_CHANNELS_ARGB      = 4;
   PIXF_CHANNELS_ABGR      = 5;
   PIXF_CHANNELS_MONO      = 6; {this is usually greyscale}
   PIXF_CHANNELS_INVALID   = -1;

   imgcPIXFChannelTypes: array[0..PIXF_MAXIMUM] of longint =
   {INDEXED RGB}
   (PIXF_CHANNELS_RGB,  {PIXF_INDEX_RGB_4, PIXF_INDEX_4}
    PIXF_CHANNELS_RGBA, {PIXF_INDEX_RGBA_4}
    PIXF_CHANNELS_RGB,  {PIXF_INDEX_RGB_8, PIXF_INDEX_8}
    PIXF_CHANNELS_RGBA, {PIXF_INDEX_RGBA_8}
    {INDEXED BGR}
    PIXF_CHANNELS_BGR,  {PIXF_INDEX_BGR_4}
    PIXF_CHANNELS_BGRA, {PIXF_INDEX_BGRA_4}
    PIXF_CHANNELS_BGR,  {PIXF_INDEX_BGR_8}
    PIXF_CHANNELS_BGRA, {PIXF_INDEX_BGRA_8}
    {PACKED}
    PIXF_CHANNELS_RGB,  {PIXF_RGB_5_6_5}
    PIXF_CHANNELS_RGB,  {PIXF_RGB_5_5_5_1}
    PIXF_CHANNELS_BGR,  {PIXF_BGR_5_6_5}
    PIXF_CHANNELS_BGR,  {PIXF_BGR_5_5_5_1}
    {RGB/BGR}
    PIXF_CHANNELS_RGB,  {PIXF_RGB}
    PIXF_CHANNELS_RGBA, {PIXF_RGBA}
    PIXF_CHANNELS_BGR,  {PIXF_BGR}
    PIXF_CHANNELS_BGRA, {PIXF_BGRA}
    {48 Bit}
    PIXF_CHANNELS_RGB,  {PIXF_RGB_48}
    PIXF_CHANNELS_RGBA, {PIXF_RGBA_48}
    PIXF_CHANNELS_BGR,  {PIXF_BGR_48}
    PIXF_CHANNELS_BGRA, {PIXF_BGRA_48}
    {INVERTED}
    PIXF_CHANNELS_ARGB, {PIXF_ARGB}
    PIXF_CHANNELS_ABGR, {PIXF_ABGR}
    PIXF_CHANNELS_MONO, {PIXF_GREYSCALE_8}
    PIXF_CHANNELS_MONO, {PIXF_GREYSCALE_8}
    PIXF_CHANNELS_MONO, {PIXF_GREYSCALE_8}
    PIXF_CHANNELS_MONO  {PIXF_ALPHA}
    );

   imgcPIXFColorChannelOrder: array[0..PIXF_MAXIMUM] of longint =
   {INDEXED RGB}
   (PIXF_COLOR_CHANNEL_ORDER_RGB, {PIXF_INDEX_RGB_4, PIXF_INDEX_4}
    PIXF_COLOR_CHANNEL_ORDER_RGB, {PIXF_INDEX_RGBA_4}
    PIXF_COLOR_CHANNEL_ORDER_RGB, {PIXF_INDEX_RGB_8, PIXF_INDEX_8}
    PIXF_COLOR_CHANNEL_ORDER_RGB, {PIXF_INDEX_RGBA_8}
    {INDEXED BGR}
    PIXF_COLOR_CHANNEL_ORDER_BGR, {PIXF_INDEX_BGR_4}
    PIXF_COLOR_CHANNEL_ORDER_BGR, {PIXF_INDEX_BGRA_4}
    PIXF_COLOR_CHANNEL_ORDER_BGR, {PIXF_INDEX_BGR_8}
    PIXF_COLOR_CHANNEL_ORDER_BGR, {PIXF_INDEX_BGRA_8}
    {PACKED}
    PIXF_COLOR_CHANNEL_ORDER_RGB, {PIXF_RGB_5_6_5}
    PIXF_COLOR_CHANNEL_ORDER_RGB, {PIXF_RGB_5_5_5_1}
    PIXF_COLOR_CHANNEL_ORDER_BGR, {PIXF_BGR_5_6_5}
    PIXF_COLOR_CHANNEL_ORDER_BGR, {PIXF_BGR_5_5_5_1}
    {RGB/BGR}
    PIXF_COLOR_CHANNEL_ORDER_RGB, {PIXF_RGB}
    PIXF_COLOR_CHANNEL_ORDER_RGB, {PIXF_RGBA}
    PIXF_COLOR_CHANNEL_ORDER_BGR, {PIXF_BGR}
    PIXF_COLOR_CHANNEL_ORDER_BGR, {PIXF_BGRA}
    {48 Bit}
    PIXF_COLOR_CHANNEL_ORDER_RGB, {PIXF_RGB_48}
    PIXF_COLOR_CHANNEL_ORDER_RGB, {PIXF_RGBA_48}
    PIXF_COLOR_CHANNEL_ORDER_BGR, {PIXF_BGR_48}
    PIXF_COLOR_CHANNEL_ORDER_BGR, {PIXF_BGRA_48}
    {INVERTED}
    PIXF_COLOR_CHANNEL_ORDER_RGB, {PIXF_ARGB}
    PIXF_COLOR_CHANNEL_ORDER_BGR, {PIXF_ABGR}
    PIXF_COLOR_CHANNEL_ORDER_MONO, {PIXF_GREYSCALE_8}
    PIXF_COLOR_CHANNEL_ORDER_MONO, {PIXF_GREYSCALE_16}
    PIXF_COLOR_CHANNEL_ORDER_MONO, {PIXF_GREYSCALE_32}
    PIXF_COLOR_CHANNEL_ORDER_MONO  {PIXF_ALPHA}
    );

   imgcPIXFHasAlpha: array[0..PIXF_MAXIMUM] of boolean =
   {INDEXED RGB}
   (false,  {PIXF_INDEX_RGB_4, PIXF_INDEX_4}
    true, {PIXF_INDEX_RGBA_4}
    false,  {PIXF_INDEX_RGB_8, PIXF_INDEX_8}
    true, {PIXF_INDEX_RGBA_8}
    {INDEXED BGR}
    false,  {PIXF_INDEX_BGR_4}
    true, {PIXF_INDEX_BGRA_4}
    false,  {PIXF_INDEX_BGR_8}
    true, {PIXF_INDEX_BGRA_8}
    {PACKED}
    false,  {PIXF_RGB_5_6_5}
    false,  {PIXF_RGB_5_5_5_1}
    false,  {PIXF_BGR_5_6_5}
    false,  {PIXF_BGR_5_5_5_1}
    {RGB/BGR}
    false,  {PIXF_RGB}
    true, {PIXF_RGBA}
    false,  {PIXF_BGR}
    true, {PIXF_BGRA}
    {48 Bit}
    false,  {PIXF_RGB_48}
    true, {PIXF_RGBA_48}
    false,  {PIXF_BGR_48}
    true, {PIXF_BGRA_48}
    {INVERTED}
    true, {PIXF_ARGB}
    true,{PIXF_ABGR}
    false, {PIXF_GREYSCALE_8}
    false, {PIXF_GREYSCALE_16}
    false, {PIXF_GREYSCALE_32}
    true); {PIXF_ALPHA}

TYPE
   imgPPaletteHandler   = ^imgTPaletteHandler;

   imgTPixelFormat = longint;
   imgPImagePage = ^imgTImagePage;

   { PALETTE }

   imgTPalette = class
      public
      fn: StdString;
      nColors: longword;
      PixF: imgTPixelFormat;
      Size: longint;
      Data: pointer;

      sAuthor,
      sName,
      sDescription,
      sProgram: StdString;

      {data is external}
      DataExternal: boolean;

      {initialize a palette data}
      procedure InitData();
      {make a palette}
      function MakeData(): longint;

      {checks if the palette is valid}
      function Valid(): boolean;

      {calculates and returns the size of the suitable palette for the image}
      function GetSize(): longint;
      {swaps the specified color channels in the palette}
      procedure SwapColorChannels(chans: longword);

      {copy palette to a destination palette}
      function Copy(var dst: imgTPalette): longint;

      destructor Destroy(); override;
   end;

   imgTPaletteHandler = record
      Make: procedure(var pal: imgTPalette);
      Dispose: procedure(var pal: imgTPalette);
   end;

   { IMAGE}

   imgTImagePage = record
      Width,
      Height: loopint;

      Page: Pointer;
   end;

   imgTImages = record
      n: loopint;
      Images: imgPImagePage;
   end;

   { imgTImage }

   imgTImage = class
      public
      Name,
      FileName: StdString;
      Properties: longword;

      Width,
      Height,
      Size,
      Pixels,
      RowAlignBytes,
      RowSize: longint;

      PixF: imgTPixelFormat;
      PixelDepth,
      Origin,
      Compression: longint;

      Image: pointer; {image pixel data}
      Palette: imgTPalette;

      ppux, ppuy: longint;
      unitSpec: longint;

      {multiple image support}
      Images: imgTImages;

      Error,
      FileError: longint;

      {checks if the image is valid}
      function Valid(): boolean;
      {checks if the image has an alpha channel}
      function HasAlpha(): boolean;

      {calculates aspects of image, needs to have width, height and PIXF}
      procedure Calculate();
      {allocates memory for image contents, must have size pre-calculated}
      function Allocate(): longint;

      {copy image from one to another}
      function Copy(var dst: imgTImage): longint;
      {copies area of source image to destination image, provided they are of same PIXF}
      function CopyArea(var dst: imgTImage; px, py, dx, dy, w, h: longint): longint;

      {create a blank image}
      procedure Blank(w, h: longint; pf: longword);
      {create a blank image}
      procedure Clear();

      {sets a palette from an external source}
      procedure SetExternalPalette(externalPalette: imgTPalette);

      {dispose image pixel data}
      procedure DisposeData();
      {disposes of the memory allocated to image and it's fields}
      procedure Dispose();
      {destructor}
      destructor Destroy(); override;
   end;

   imgTErrorData = record
      e,
      f,
      io: longint;
      description: StdString;
   end;

   { imgTGlobal }

   imgTGlobal = record
      Settings: record
         {determines if the loading routines should store filename into the record}
         StoreFileNames,
         Log, {whether or not to perform logging}
         LogNameAlways, {always log the name of the image being loaded}

         {set the image to the default origin when loading}
         SetToDefaultOrigin,
         {set the image to default pixel format when loading}
         SetToDefaultPixelFormat,
         {set the image to the default color channel order}
         SetToDefaultColorChannelOrder: boolean;

         DefaultPixelFormat,
         DefaultPixelFormatAlpha,
         DefaultColorChannelOrder: longint;
      end;

      { GENERAL IMAGE ROUTINES }
      {error data}
      procedure Init(out errorData: imgTErrorData);
      {dispose of the image data}
      procedure Dispose(var img: imgTImage);

      {checks whether an image is valid}
      function Valid(var img: imgTImage): boolean;

      {create a blank texture}
      function MakeBlank(w, h: longint; pf: longword): imgTImage;

      { INFORMATION }
      {return the pixel format depth in bits}
      function PIXFDepth(pf: longword): longint;
      {return the number of channels a pixel format has}
      function PIXFChannels(pf: longword): longint;
      {returns the channel type of a PIXF}
      function PIXFChannelType(pf: longword): longint;
      {tells whether a pixel format has an alpha channel}
      function PIXFHasAlpha(pf: longword): boolean;
      {returns the color channel order for the specified PIXF}
      function PIXFColorChannelOrder(pf: longword): longint;
      {return the name of the pixel format}
      function PIXFName(pf: longword): string;

      {get the number of bytes to increment for a pixel format}
      function PIXFIncrementBytes(pf: longword): loopint;
   end;

   imgTPaletteGlobal = record
   end;

   imgTPaletteGlobalHandler = record helper for imgTPaletteGlobal
      procedure Init(out pal: imgTPalette);
      {initialize a imgTPaletteHandler record}
      procedure Init(out palh: imgTPaletteHandler);

      {make a palette}
      function Make(var image: imgTImage): boolean;
      function Make(var image: imgTImage; pf: longword; nColors: longint): longint;
      function Make(): imgTPalette;
      {dispose of a palette}
      procedure Dispose(var palette: imgTPalette);
      procedure Dispose(var image: imgTImage);
      {returns true if a palette is valid for an image}
      function Valid(var image: imgTImage): boolean;
   end;

VAR
   img: imgTGlobal;
   pal: imgTPaletteGlobal;

IMPLEMENTATION

{ IMAGE SUPPORT }

procedure imgTGlobal.Init(out errorData: imgTErrorData);
begin
   ZeroOut(errorData,  SizeOf(errorData))
end;

function imgTImage.Valid(): boolean;
begin
   Result := (Width <> 0) and (Height <> 0) and (Image <> nil);
end;

procedure imgTImage.DisposeData();
begin
   XFreeMem(Image);
   pal.Dispose(self);
end;

procedure imgTImage.Dispose();
begin
   FileName    := '';
   Name        := '';

   DisposeData();

   Size        := 0;
end;

destructor imgTImage.Destroy();
begin
   inherited;

   Dispose();

   {if(Length(img.Images) > 0) then begin
      img.nImages := 0; SetLength(img.Images, 0);
   end;}
end;

procedure imgTGlobal.Dispose(var img: imgTImage);
begin
   FreeObject(img);
end;

function imgTGlobal.Valid(var img: imgTImage): boolean;
begin
   Result := false;

   if(img.Image <> nil) then
      Result := img.Valid();
end;

function imgTGlobal.MakeBlank(w, h: longint; pf: longword): imgTImage;
var
   p: imgTImage = nil;

begin
   p := imgTImage.Create();
   if(p <> nil) then
      p.Blank(w, h, pf);

   Result := p;
end;

{copy image from one to another}
function imgTImage.Copy(var dst: imgTImage): longint;
begin
   Result := eNONE;

   {dispose the previous destination image, if any}
   img.Dispose(dst);

   dst := imgTImage.Create();
   if(dst = nil) then
      exit(eNO_MEMORY);

   {copy strings}
   dst.Name          := Name;
   dst.FileName      := FileName;
   dst.Properties    := Properties;

   dst.Width         := Width;
   dst.Height        := Height;

   dst.Size          := Size;
   dst.Pixels        := Pixels;
   dst.RowAlignBytes := RowAlignBytes;
   dst.Origin        := Origin;

   {copy data}
   dst.PixF          := PixF;
   dst.PixelDepth    := PixelDepth;
   dst.Compression   := Compression;
   dst.Origin        := Origin;

   dst.ppux          := ppux;
   dst.ppuy          := ppuy;
   dst.unitSpec      := unitSpec;

   dst.error         := error;
   dst.fileError     := fileError;

   {NOTE: We want a pointer to new image data, not use the one from src}
   dst.Image := nil;

   {allocate memory for the new image data, if the source has an image}
   if(Image <> nil) then begin
      GetMem(dst.Image, dst.Size);

      if(dst.Image <> nil) then
         {copy the image data}
         move(Image^, dst.Image^, dst.Size)
      else
         exit(eNO_MEMORY);
   end;

   {copy the palette too, if any and if not external}
   if(palette <> nil) and
      (Properties and imgcPROPERTIES_PAL_EXTERNAL = 0) then
         palette.Copy(dst.palette);
end;

function imgTImage.CopyArea(var dst: imgTImage; px, py, dx, dy, w, h: longint): longint;
var
   psize,
   len,
   i,
   algn,
   srcrowlen,
   dstrowlen: longint;

   p,
   s,
   d: pbyte;

begin
   if(Valid() and img.Valid(dst)) then begin
      if(w <= 0) or (h <= 0) or (px < 0) or (py < 0) or (PixF <> dst.PixF) then
         exit(eUNSUPPORTED);

      {get pixel depth}
      psize := img.PIXFDepth(PixF);

      if(psize mod 8 = 0) then begin
         if(dx < 0) then begin
            w := w + dx - 1;
            dx := 0;

            if(w < 0) then
               exit(eNONE);
         end;

         if(dy < 0) then begin
            h := h + dy - 1;
            dy := 0;

            if(h < 0) then
               exit(eNONE);
         end;

         if(w > Width) then
            w := Width;

         if(h > Height) then
            h := Height;

         if(dx + w > dst.Width) then
            w := dst.Width - dx;

         if(dy + h > dst.Height) then
            h := dst.Height - dy;

         {check that the position does not go out of the boundaries}
         if(px + w > Width) or (dx + w > dst.Width) or (w <= 0) then
            exit(eINVALID_ARG)
         else if(py + h > Height) or (dy + h > dst.Height) or (h <= 0) then
            exit(eINVALID_ARG);

         psize       := psize div 8; {get pixel size in bytes}
         len         := psize * w; {figure out how many bytes to copy at a time}

         {calculate row lengths in bytes}
         srcrowlen   := (Width * psize) + RowAlignBytes;
         dstrowlen   := (dst.Width * psize) + dst.RowAlignBytes;

         {position at source}
         algn        := RowAlignBytes * py;
         {$PUSH}{$HINTS OFF}
         p           := pbyte((py * Width + px) * psize + algn);
         s           := Image + ptruint(p);
         {$POP}

         {position at destination}
         algn        := dst.RowAlignBytes * dy;
         {$PUSH}{$HINTS OFF}
         p           := pbyte((dy * dst.Width + dx) * psize + algn);
         d           := pbyte(dst.Image) + ptruint(p);
         {$POP}

         {copy rows one at a time}
         for i := 0 to h - 1 do begin
            move(s^, d^, len);

            {move to next row}
            inc(s, srcrowlen);
            inc(d, dstrowlen);
         end;

         Result := eNONE;
      end else
         Result := eUNSUPPORTED;
   end else
      Result := eINVALID;
end;

procedure imgTImage.Blank(w, h: longint; pf: longword);
begin
   if(Image <> nil) then
      Dispose();

   Width      := w;
   Height     := h;
   PixF       := pf;

   Calculate();
   Allocate();
end;

procedure imgTImage.Clear;
begin
   if(Image <> nil) then begin
      ZeroOut(Image^, Size);
   end;
end;

procedure imgTImage.SetExternalPalette(externalPalette: imgTPalette);
begin
   palette      := externalPalette;
   Properties   := Properties or imgcPROPERTIES_PAL_EXTERNAL;
end;

{ IMAGE INFORMATION }

function imgTGlobal.PIXFDepth(pf: longword): longint;
begin
   if(pf <= PIXF_MAXIMUM) then
      Result := imgcPIXFDepth[pf]
   else
      Result := 0;
end;

function imgTGlobal.PIXFChannels(pf: longword): longint;
begin
   if(pf <= PIXF_MAXIMUM) then
      Result := imgcPIXFChannels[pf]
   else
      Result := 0;
end;

function imgTGlobal.PIXFChannelType(pf: longword): longint;
begin
   if(pf <= PIXF_MAXIMUM) then
      Result := imgcPIXFChannelTypes[pf]
   else
      Result := PIXF_CHANNELS_INVALID;
end;

function imgTGlobal.PIXFHasAlpha(pf: longword): boolean;
begin
   if(pf <= PIXF_MAXIMUM) then
      Result := imgcPIXFHasAlpha[pf]
   else
      Result := false;
end;

function imgTGlobal.PIXFColorChannelOrder(pf: longword): longint;
begin
   if(pf <= PIXF_MAXIMUM) then
      Result := imgcPIXFColorChannelOrder[pf]
   else
      Result := -1;
end;

function imgTGlobal.PIXFName(pf: longword): string;
begin
   if(pf <= PIXF_MAXIMUM) then
      Result := imgcPIXFNames[pf]
   else
      Result := 'PIXF_UNKNOWN';
end;

function imgTGlobal.PIXFIncrementBytes(pf: longword): loopint;
begin
   Result := PIXFDepth(pf) div 8;
end;

function imgTImage.HasAlpha(): boolean;
begin
   Result := imgcPIXFHasAlpha[PixF];
end;

{ PALETTE }

procedure imgTPaletteGlobalHandler.Init(out pal: imgTPalette);
begin
   ZeroOut(pal, SizeOf(pal));
end;

procedure imgTPaletteGlobalHandler.Init(out palh: imgTPaletteHandler);
begin
   ZeroOut(palh, SizeOf(palh));
end;

procedure imgTPalette.InitData();
begin
   if(Data <> nil) and (Size > 0) then
      Zero(Data^, Size);
end;

{initialize}
function imgTPalette.MakeData(): longint;
var
   calculatedSize: longword;

begin
   Result := eNONE;
   calculatedSize := GetSize();

   if(calculatedSize > 0) then begin
      GetMem(Data, calculatedSize);

      if(Data <> nil) then begin
         Size := calculatedSize;
         InitData();
      end else
         exit(eNO_MEMORY);
   end;
end;

function imgTPaletteGlobalHandler.Make(var image: imgTImage): boolean;
begin
   image.palette := Make();
   Result := image.palette <> nil;
end;

function imgTPaletteGlobalHandler.Make(var image: imgTImage; pf: longword; nColors: longint): longint;
var
   err: longint;

begin
   if(not pal.Make(image)) then
      exit(eNO_MEMORY);

   image.palette.PixF      := pf;
   image.palette.nColors   := nColors;

   err := image.palette.MakeData();
   Result := err;
end;

function imgTPaletteGlobalHandler.Make(): imgTPalette;
var
   pal: imgTPalette = nil;

begin
   pal := imgTPalette.Create();
   Result := pal;
end;

destructor imgTPalette.Destroy();
begin
   inherited;

   if(not DataExternal) then
      XFreeMem(data);
end;

procedure imgTPaletteGlobalHandler.Dispose(var palette: imgTPalette);
begin
   FreeObject(palette);
end;

procedure imgTPaletteGlobalHandler.Dispose(var image: imgTImage);
begin
   if(image.Properties and imgcPROPERTIES_PAL_EXTERNAL = 0) and (image.palette <> nil) then
      pal.Dispose(image.palette);
end;

function imgTPaletteGlobalHandler.Valid(var image: imgTImage): boolean;
begin
   if(image.palette <> nil) then
      Result := image.palette.Valid()
   else
      Result := false;
end;

function imgTPalette.Valid(): boolean;
begin
   Result := (Data <> nil) and (nColors > 0);
end;

function imgTPalette.GetSize(): longint;
var
   channels: longword;

begin
   Result := 0;

   channels := img.PIXFChannels(PixF);

   {calculate and return the size}
   Result := channels * nColors;
end;

{swaps the specified color channels in the palette}
procedure imgTPalette.SwapColorChannels(chans: longword);
var
   i,
   elements,
   channels,
   Incr: longint;
   cPixel: PColor4ub;

begin
   if(not Valid()) then
      exit;

   elements := nColors;
   channels := img.PIXFChannels(PixF);
   if(elements = 0) then
      exit;

   {get the first color in the palette}
   cPixel := Data;

   {initialize swapping}
   Incr := channels;

   {Swap channels by using triple xor swapping. Faster than using normal
   swapping with a temp variable.}
   case chans of
      {swap red and green channels}
      imgccRG: begin
         for i := 0 to (elements-1) do begin
            cPixel^[1] := cPixel^[1] xor cPixel^[0];
            cPixel^[0] := cPixel^[1] xor cPixel^[0];
            cPixel^[1] := cPixel^[1] xor cPixel^[0];
            inc(pointer(cPixel), Incr);
         end;
      end;
      {swap red and blue channels}
      imgccRB: begin
         for i := 0 to (elements-1) do begin
            cPixel^[2] := cPixel^[2] xor cPixel^[0];
            cPixel^[0] := cPixel^[2] xor cPixel^[0];
            cPixel^[2] := cPixel^[2] xor cPixel^[0];
            inc(pointer(cPixel), Incr);
         end;
      end;
      {swap green and blue channels}
      imgccGB: begin
         for i := 0 to (elements-1) do begin
            cPixel^[1] := cPixel^[1] xor cPixel^[2];
            cPixel^[2] := cPixel^[1] xor cPixel^[2];
            cPixel^[1] := cPixel^[1] xor cPixel^[2];
            inc(pointer(cPixel), Incr);
         end;
      end;
      else
         exit;
   end;
end;

function imgTPalette.Copy(var dst: imgTPalette): longint;
begin
   pal.Dispose(dst);

   dst := imgTPalette.Create();
   if(dst  = nil) then
      exit(eNO_MEMORY);

   {copy strings}
   dst.fn            := fn;
   dst.sAuthor       := sAuthor;
   dst.sName         := sName;
   dst.sDescription  := sDescription;
   dst.sProgram      := sProgram;

   dst.Data          := nil;

   {copy data}
   if(data <> nil) then begin
      GetMem(dst.data, dst.Size);
      if(dst.data <> nil) then
         move(data^, dst.data^, dst.Size)
      else
         exit(eNO_MEMORY);
   end;

   Result := eNONE;
end;

{ HELPER ROUTINES }
procedure imgTImage.Calculate();
begin
   PixelDepth  := img.PIXFDepth(PixF);

   {calculate the image size}
   Size := Width * Height * (PixelDepth div 8);

   {calculate the number of pixels}
   Pixels := Width * Height;
end;

function imgTImage.Allocate(): longint;
var
   align: PtrInt;

begin
   Result := eNONE;

   {align to 16 bytes}
   align := Size + (16 - (Size mod 16));

   {allocate memory}
   GetMem(Image, align);
   if(Image = nil) then
      exit(eNO_MEMORY);
end;

INITIALIZATION
   with img.settings do begin
      storeFileNames  := true;
      log             := false;
      logNameAlways   := false;

      {set the image to the default origin while loading}
      setToDefaultOrigin             := false;
      setToDefaultPixelFormat        := false;
      setToDefaultColorChannelOrder  := false;

      defaultPixelFormat       := PIXF_RGB;
      defaultPixelFormatAlpha  := PIXF_RGBA;
      defaultColorChannelOrder := PIXF_COLOR_CHANNEL_ORDER_RGB;
   end;

END.
