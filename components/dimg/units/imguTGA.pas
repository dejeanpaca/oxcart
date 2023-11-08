{
   imguTGA, Truevision Targa image loader for dImage
   Copyright (C) 2007. Dejan Boras

   Started On:    31.05.2007.
}

{$INCLUDE oxdefines.inc}
UNIT imguTGA;

INTERFACE

   USES uImage, uFileHandlers, imguRW;

IMPLEMENTATION

   USES imguTGAStuff;

VAR
   ext: fhTExtension;
   loader: fhTHandler;

{this routine is the purpose of this unit, it is the targa image loader}
procedure load(data: pointer);
var
   ld: imgPFileData;
   Header: tgaTHeader;
   imgSpec: tgaTImageSpec;

   XFileFooter: tgaTFooter;

   img: pointer;
   imgP: imgTImage;

{load an uncompressed true color image}
procedure loadUncompressedTrueColor();
begin
   {load in the image}
   if(ld^.BlockRead(img^, imgP.Size) < 0) then
      exit;
end;

{load a RLE compressed image}
procedure loadRLETrueColor();
var
   {current pixel and byte}
   j,
   cPixel: longint;
   {one pixel}
   Pix: array[0..3] of byte   = (0,0,0,0);
   bpp: longint               = 0;
   chunk: byte                = 0; {bytes per pixel, chunk size}
   ximg, yimg: pointer;

begin
   {NOTE: As it can be seen from this empty routine the loading of RLE compressed
   true color tga images still needs to be implemented}

   {initialize variables}
   cPixel   := 0;
   ximg     := img;

   {get the number of bytes per pixel(not bits, but bytes!)}
   bpp      := imgP.PixelDepth div 8;
	repeat
      {read the chunk header}
      if(ld^.BlockRead(chunk, 1) > 0) then begin
         if(chunk < 128) then begin {raw block}
            inc(chunk);
            {check for buffer overrun}
            if(cPixel + chunk * bpp > imgP.Size) then
               chunk := (imgP.size - cPixel) div bpp;

            {read chunk pixels into the image}
            if(ld^.BlockRead((ximg)^, int64(chunk)*int64(bpp)) >= 0) then begin
               inc(cPixel, chunk * bpp); {increment the number of processed bytes}

               inc(ximg, chunk * bpp); {increment the pointer}
            end;
         end else begin {compressed block}
            chunk := chunk - 127;
            {check for buffer overrun}
            if(cPixel + chunk * bpp > imgP.Size) then
               chunk := (imgP.size - cPixel) div bpp;

            {read the pixel}
            if(ld^.BlockRead(Pix, bpp) >= 0) then begin
               yimg := ximg;

               {fill it in chunk times}
               if(bpp = 3) then begin
                  for j := 0 to chunk-1 do begin
                     byte((yimg+0)^) := Pix[0];
                     byte((yimg+1)^) := Pix[1];
                     byte((yimg+2)^) := Pix[2];
                     inc(yimg, 3);
                  end;
               end else
                  filldword(yimg^, chunk, dword((@Pix)^));

               inc(cPixel, chunk*bpp);{increment the number of processed bytes}

               inc(ximg, chunk*bpp); {increment the pointer}
            end else
               break;
         end;
      end else
         break;

   until(cPixel >= imgP.Size);
end;

begin {load}
   ld    := data;
   imgP  := ld^.Image;

   {first, check for a Targa File Footer and determine if the file is in the new
   TGA format, or the old format. Not used currently but may be helpful in the
   future.}
   if(ld^.Seek(ld^.f^.GetSize() - 26) < 0) then
      exit;

   {$PUSH}{$HINTS OFF}
   {XFileFooter does not need to be initialized.}
   if(ld^.BlockRead(XFileFooter, SizeOf(tgaTFooter)) < 0) then{$POP}
      exit;

   {if equal the file has the new format}
   if(XFileFooter.Signature = tgacFooterSignature) then;

   {HEADER}
   {read in the header}
   if(ld^.Seek(0) < 0) then
      exit;

   {$PUSH}{$HINTS OFF}
   {Header does not need to be initialized.}
   if(ld^.BlockRead(Header, SizeOf(tgaTHeader)) < 0) then{$POP}
      exit;

   {check if the image is of supported type}
   if(Header.typeImage <> TGA_UNCOMPRESSED_TRUE_COLOR) and (Header.typeImage <> TGA_RLE_TRUE_COLOR) then begin
      ld^.SetError(imgeUNSUPPORTED_COMPRESSION);
      exit;
   end;

   {IMAGE SPECIFICATION}
   {read image specification}
   {$PUSH}{$HINTS OFF}
   {imgSpec does not need to be initialized.}
   if(ld^.BlockRead(imgSpec, SizeOf(tgaTImageSpec)) < 0) then{$POP}
      exit;

   {load in width, height and bpp}
   imgP.Width       := imgSpec.Width;
   imgP.Height      := imgSpec.Height;
   imgP.PixelDepth  := imgSpec.PixDepth;

   {check if the values are valid and supported}
   case imgP.PixelDepth of
      24: imgP.PixF := PIXF_BGR;
      32: imgP.PixF := PIXF_BGRA;
      else begin
         imgP.PixF  := PIXF_UNSUPPORTED;
         ld^.SetError(imgeUNSUPPORTED_DEPTH);
         exit;
      end;
   end;

   {calculate size and pixels values}
   imgP.Pixels   := imgP.Width * imgP.Height;
   {this makes the image size come out exactly the number of bytes it actually is,
   regardless of the pixel depth}
   imgP.Size     := (imgP.Width * imgP.Height * imgP.PixelDepth) div 8;

   {LOADING}
   {allocate memory for image}
   if(ld^.Allocate() <> 0) then
      exit;

   img            := imgP.Image;

   {call the appropriate loading routine based on the type of tga image}
   if(Header.typeImage = TGA_UNCOMPRESSED_TRUE_COLOR) then
      loadUncompressedTrueColor()
   else if(Header.typeImage = TGA_RLE_TRUE_COLOR) then
      loadRLETrueColor();

   {NOTE: The color channels are always BGR or BGRA. They are not swapped.}

   imgP.Origin   := 0;
   {flip the image to make the origin top-left}
   {is origin bottom?}
   if(imgSpec.imgDescriptor and TGA_ORIGIN_VERTICAL = 0) then
      imgP.Origin := imgP.Origin or imgcBT_ORIGIN_VERTICAL;

   {is origin right?}
   if(imgSpec.imgDescriptor and TGA_ORIGIN_HORIZONTAL > 0) then
      imgP.Origin := imgP.Origin or imgcBT_ORIGIN_HORIZONTAL;

   {the image has been loaded successfully | mission accomplished}
end;

BEGIN
   {register the extension and the loader}
   imgFile.Loaders.RegisterHandler(loader, 'TGA', @load);
   imgFile.Loaders.RegisterExt(ext, '.tga', @loader);

END.
