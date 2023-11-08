{
   imguBMP, Windows BMP image loader for dImage
   Copyright (C) 2007. Dejan Boras

   Started On:    25.05.2007.
}

{$INCLUDE oxdefines.inc}
UNIT imguBMP;

{This loader currently supports non-compressed 8, 16, 24 and 32 bit bitmaps
using the standard info header. Since these are the most common there
should be no problem with loading bitmaps.

General outline of the bitmap file format:

00h - 0Dh  - header
0Eh - 35h  - information
36h - 75h  - color table (palette)
76h - 275h - color index}

INTERFACE

   USES
      uStd, uImage, uFileHandlers, imguRW,
      {ox}
      uOX, oxuFile;

IMPLEMENTATION

TYPE
   {these must be packed in order to be read successfully}
   {bitmap header}
   TBMPHeader = packed record
      Typ: array[0..1] of char;
      FileSize: longword;
      Reserved: longword;
      Offset: longword;
   end;

   {bitmap information header}
   TBMPInfo = packed record
      Size: longword;

      Width,
      Height: longint;

      Planes,
      BitCount: word;

      Compression: longword;

      ImageSize,
      XPixelsPerMeter,
      YPixelsPerMeter: longword;

      ClrUsed,
      ClrImportant: longword;
   end;

VAR
   ext: fhTExtension;
   loader: fhTHandler;

{loads the bitmap file}
procedure load(data: pointer);
var
   ld: imgPFileData;
   imgP: imgTImage;

   Header: TBMPHeader;
   Info: TBMPInfo;

begin
   ld := oxTFileRWData(data^).External;
   imgP := ld^.Image;

   {read the header}
   {Jeader does not need to be initialized as were reading it from a file.}
   if(ld^.BlockRead(Header, SizeOf(TBMPHeader)) = -1) then
      exit;

   {Info, same thing as for header}
   if(ld^.BlockRead(Info, SizeOf(TBMPInfo)) = -1) then
      exit;

   {check the bitmap}
   if(Info.Compression <> 0) then begin
      ld^.SetError(eUNSUPPORTED);
      exit;
   end;

   {assign values}
   imgP.Width       := Info.Width;
   imgP.Height      := Info.Height;
   imgP.PixelDepth  := Info.BitCount;
   imgP.Pixels      := Info.Width*Info.Height;
   imgP.Origin      := imgcORIGIN_BL; {bottom-left origin}

   case Info.BitCount of
    //04: imgP.PixF := PIXF_INDEX_RGB_4; {this is still unsupported}
      08: imgP.PixF := PIXF_INDEX_RGB_8;
      16: imgP.PixF := PIXF_RGB_5_6_5;
      24: imgP.PixF := PIXF_RGB;
      32: imgP.PixF := PIXF_RGBA;
      else begin
         imgP.PixF  := PIXF_UNSUPPORTED;
         ld^.SetError(eUNSUPPORTED);
         exit;
      end;
   end;

   {calculate the properties of the image}
   ld^.Calculate();

   {get memory for bitmap and the color table}
   ld^.Allocate();
   if(ld^.GetError() <> 0) then
      exit;

   if(Info.BitCount = 4) then
      pal.Make(imgP, PIXF_BGR, 16)
   else if(Info.BitCount = 8) then
      pal.Make(imgP, PIXF_BGR, 256);

   if(ld^.GetError() <> 0) then
      exit;

   {read in the palette, if one is present}
   ld^.ReadPalette(1);
   if(ld^.GetError() = 0) then begin
      {read in the bitmap}
      ld^.Seek(Header.Offset);

      if(ld^.GetError() = 0) then
         ld^.BlockRead(imgP.Image^, imgP.Size);
   end;
end;

procedure init();
begin
   imgFile.Readers.RegisterHandler(loader, 'WINBMP', @load);
   imgFile.Readers.RegisterExt(ext, '.bmp', @loader);
end;

INITIALIZATION
   ox.PreInit.Add('image.bmp', @init);

END.
