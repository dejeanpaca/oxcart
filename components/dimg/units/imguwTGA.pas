{
   imguwTGA, Truevision Targa image writer for dImage
   Copyright (C) 2009. Dejan Boras

   Started On:    26.06.2009.
}

{TODO: Add support for indexed image types and RLE compression}

{$INCLUDE oxdefines.inc}
UNIT imguwTGA;

INTERFACE

   USES
      uImage, uFileHandlers, imguRW;

IMPLEMENTATION

   USES imguTGAStuff;

VAR
   ext: fhTExtension;
   writer: fhTHandler;

   XFileFooter: tgaTFooter = (
      offsetExt:  0;
      offsetDev:  0;
      Signature:  '';
      chars:      '.'#0;
   );

{this routine is the purpose of this unit, it is the targa image writer}
procedure writeImage(data: pointer);
var
   ld: imgPFileData;
   Header: tgaTHeader;
   imgSpec: tgaTImageSpec;

   imgP: imgTImage;

{write an uncompressed true color image}
function writeUncompressedTrueColor(): longint;
begin
   Result := ld^.BlockWrite(imgP.Image^, imgP.Size);
end;

begin {writeImage}
   ld := data;
   imgP := ld^.Image;

   {check if the image is of a supported format}
   if(imgP.PixF <> PIXF_RGB) and (imgP.PixF <> PIXF_RGBA) and
      (imgP.PixF <> PIXF_BGR) and (imgP.PixF <> PIXF_BGRA) then
         exit;

   {image header}
   Header.lengthID               := 0;
   Header.typeColorMap           := 0;
   Header.typeImage              := TGA_UNCOMPRESSED_TRUE_COLOR;

   Header.cmSpec.cmEntrySize     := 0;
   Header.cmSpec.cmLength        := 0;
   Header.cmSpec.FirstEntry      := 0;

   {image specifications}
   imgSpec.PixDepth              := img.PIXFDepth(imgP.PixF);
   imgSpec.xOrigin               := 0;
   imgSpec.yOrigin               := 0;
   imgSpec.Width                 := imgP.Width;
   imgSpec.Height                := imgP.Height;

   imgSpec.imgDescriptor := 0;

   {setup the origin}
   if(imgP.Origin and imgcBT_ORIGIN_HORIZONTAL > 0) then
      imgSpec.imgDescriptor := imgSpec.imgDescriptor or TGA_ORIGIN_HORIZONTAL;
   if(imgP.Origin and imgcBT_ORIGIN_VERTICAL = 0) then
      imgSpec.imgDescriptor := imgSpec.imgDescriptor or TGA_ORIGIN_VERTICAL;

   {writeImage the header}
   if(ld^.BlockWrite(Header, SizeOf(Header)) < 0) then
      exit;

   {writeImage the image specification}
   if(ld^.BlockWrite(imgSpec, SizeOf(imgSpec)) < 0) then
      exit;

   {NOTE: writeImage here the image ID}
   {TODO: writeImage here the image palette}

   {writeImage the image down}
   if(writeUncompressedTrueColor() < 0) then
      exit;

   {writeImage the footer}
   if(ld^.BlockWrite(XFileFooter, SizeOf(XFileFooter)) < 0) then
      exit;

   {success}
end;

INITIALIZATION
   {register the extension and the writer}
   imgFile.Writers.RegisterHandler(writer, 'TGA', @writeImage);
   imgFile.Writers.RegisterExt(ext, '.tga', @writer);

   XFileFooter.Signature := tgacFooterSignature;

END.
