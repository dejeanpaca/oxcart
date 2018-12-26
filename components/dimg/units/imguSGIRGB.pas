{
   imguSGIRGB, SGI RGB image format loader
   Copyright (C) 2010. Dejan Boras

   Started On:    12.05.2010.

   TODO: Implement support for colormaps, RLE compression and dimension other than 1.
}

{$MODE OBJFPC}{$H+}{$I-}
UNIT imguSGIRGB;

INTERFACE

   USES uStd, uImage, uFileHandlers, imguRW, uColors;

IMPLEMENTATION

CONST
   {storage types}
   cSTORAGE_NORMAL      = 0;
   cSTORAGE_RLE         = 1;

   {allowable values for ZSize, number of channels}
   cGREYSCALE           = 1;
   cRGB                 = 3;
   cRGBA                = 4;

   {colormap IDs}
   cCM_NORMAL           = 0;
   cCM_DITHERED         = 1;
   cCM_INDEX            = 2;
   cCM_COLORMAP         = 3;

   {dimensions}
   cDIMENSION_2D        = 1;

TYPE
   THeader = packed record
      Magic: word;
      Storage: byte;
      BPC: byte;
      Dimension: word;

      XSize,
      YSize,
      ZSize: word;

      PixMin,
      PixMax: TColor4ub;

      Dummy: longint;
      ImageName: array[0..79] of char;
      ColorMap: longint;
      pDummy: array[0..403] of char;
   end;

VAR
   sgirgbExt: fhTExtension;
   sgirgbLoader: fhTHandler;

{this routine is the purpose of this unit, it is the targa image loader}
procedure dLoad(data: pointer);
var
   hdr: THeader;
   ld: imgPFileData;
   imgP: imgTImage;

begin
   ld    := data;
   imgP   := ld^.image;

   {get the header}
   ld^.BlockRead(hdr, SizeOf(THeader));
   if(ld^.error <> 0) then exit;

   {header - check bpc}
   if(hdr.BPC < 1) or (hdr.BPC > 2) then begin
      ld^.error := eINVALID;
      exit;
   end;

   {header - check ZSize}
   case hdr.ZSize of
      cGREYSCALE:
         if(hdr.BPC = 1) then
            imgP.PixF := PIXF_GREYSCALE_8
         else if(hdr.BPC = 2) then
            imgP.PixF := PIXF_GREYSCALE_16;
      cRGB:
         if(hdr.BPC = 1) then
            imgP.PixF := PIXF_RGB
         else begin
            ld^.error := imgeUNSUPPORTED_BPC;
            exit;
         end;
      cRGBA:
         if(hdr.BPC = 2) then
            imgP.PixF := PIXF_RGBA
         else begin
            ld^.error := imgeUNSUPPORTED_BPC;
            exit;
         end;
      else begin
         ld^.error := imgeINVALID_PIXF;
         exit;
      end;
   end;

   {header - check color map type}
   case hdr.ColorMap of
      cCM_NORMAL,
      cCM_DITHERED,
      cCM_INDEX,
      cCM_COLORMAP: begin
         ld^.error := imgeUNSUPPORTED_COLORMAP;
         exit;
      end;
      else begin
         ld^.error := imgeINVALID_COLORMAP;
         exit;
      end;
   end;

   {header - check storage type}
   case hdr.Storage of
      cSTORAGE_NORMAL:;
      cSTORAGE_RLE: begin
         imgP.Compression := imgcCOMPRESSION_RLE;
         ld^.error := imgeUNSUPPORTED_COMPRESSION;
         exit;
      end;
      else begin
         ld^.error := imgeINVALID_COMPRESSION;
         exit;
      end;
   end;

   {header - check size}
   if(hdr.XSize < 1) or (hdr.YSize < 1) then begin
      ld^.error := imgeINVALID_DIMENSIONS;
      exit;
   end;

   {header - check dimension}
   if(hdr.Dimension <> cDIMENSION_2D) then begin
      ld^.error := imgeUNSUPPORTED;
      exit;
   end;

   {copy properties}
   imgP.Width  := hdr.XSize;
   imgP.Height := hdr.YSize;

   {calculate image properties}
   ld^.Calculate();

   {allocate memory for image}
   ld^.Allocate();
   if(ld^.error <> 0) then
      exit;

   {now read the image}
   ld^.BlockRead(imgP.Image^, imgP.Size);
end;

BEGIN
   {register the extension and the loader}
   imgFile.Loaders.RegisterHandler(sgirgbLoader, 'SGIRGB', @dLoad);
   imgFile.Loaders.RegisterExt(sgirgbExt, '.rgb', @sgirgbLoader);
END.
