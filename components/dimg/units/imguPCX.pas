{
   imguPCX, PCX image loader for dImage
   Copyright (C) 2007. Dejan Boras

   Started On:    20.12.2007.
}

{$INCLUDE oxdefines.inc}
UNIT imguPCX; {PCX}

{TODO: Implement 4-bit image loading with palette.}

INTERFACE

   USES
      uStd, uImage, uFileHandlers, imguRW, uColors,
      {ox}
      oxuFile;

IMPLEMENTATION

CONST
   {pcx constants}
   pcxcMANUFACTURER        = 10;
   pcxcENCODING            = 01;

TYPE
   pcxPHeader = ^pcxTHeader;
   pcxTHeader = packed record
      Manufacturer,
      Version,
      Encoding,
      BPP: byte;

      xMin,
      yMin,
      xMax,
      yMax: smallint;

      HDpi,
      VDpi: smallint;

      Colormap: array[0..15, 0..2] of byte;

      Reserved,
      NPlanes: byte;

      BytesPerLine,
      PaletteInfo,
      HScreenSize,
      VScreenSize: smallint;

      Filler: array[0..53] of byte;
   end;

VAR
   ext: fhTExtension;
   loader: fhTHandler;

{load the PCX image}
procedure load(data: pointer);
var
   ld: imgPFileData;
   imgP: imgTImage;

   hdr: pcxPHeader;
   lineSize: longint       = 0;

   pcxData: pointer        = nil;
   pcxiData: pointer       = nil;
   imgData: pointer        = nil;
   palData: pointer        = nil;
   dataByte: byte          = 0;
   bytes: longint          = 0;
   incCount: longint       = 1;
   fileSize: fileint;

   i: longint;

procedure cleanup();
begin
   XFreeMem(pcxData);
end;

procedure processAlignment();
begin
   {not sure why this works, but it works, and I'm gonna leave it at that}
   dec(pcxiData, bytes mod 2);
end;

{process a RLE compressed plane(encoding: 1)}
procedure processPlaneRLE();
var
   k: longint;
   count: longint = 0;
   total: longint = 0;

begin
   repeat
      inc(pcxiData);

      {get the count and data byte}
      dataByte    := byte(pcxiData^);
      if((dataByte and $C0) = $C0) then begin
         count    := dataByte and $3F;
         inc(pcxiData);
         dataByte := byte(pcxiData^);
      end else
         count := 1;

      {add the data to the image}
      for k := 0 to (count-1) do begin
         byte(imgData^) := dataByte;
         inc(imgData, incCount);
      end;

      {next data}
      inc(total, count);
      inc(bytes, count);
   until (total >= hdr^.BytesPerLine);
end;

{process a uncompressed plane}
procedure processPlane();
var
   j: longint;

begin
   for j := 0 to (imgP.Width-1) do begin
      inc(pcxiData);
      byte(imgData^) := byte(pcxiData^);

      {next data}
      inc(imgData, incCount);
   end;
end;

begin
   ld := oxTFileRWData(data^).External;
   imgP := ld^.image;

   fileSize := ld^.f^.GetSize();

   {get memory for the file}
   GetMem(pcxData, fileSize);

  if(pcxData <> nil) then begin
      {read in the entire file}
      ld^.BlockRead(pcxData^, fileSize);

     if(ld^.GetError() <> 0) then begin
         cleanup();
         exit;
      end;

      {assign the header}
      hdr := pcxData;

      {check if the PCX is supported}
      if(hdr^.Manufacturer <> pcxcManufacturer) then begin
         ld^.SetError(eUNSUPPORTED);
         exit;
      end;

      if(hdr^.Encoding <> 0) and (hdr^.Encoding <> pcxcENCODING) then begin
         ld^.SetError(eUNSUPPORTED);
         exit;
      end;

      {assign the values}
      {width and height}
      imgP.Width       := (hdr^.xMax - hdr^.xMin) + 1;
      imgP.Height      := (hdr^.yMax - hdr^.yMin) + 1;
      imgP.Pixels      := imgP.Width * imgP.Height;
      imgP.Origin      := imgcORIGIN_TL; {top-left}

      imgP.PixelDepth  := hdr^.BPP * hdr^.nPlanes;
      case imgP.PixelDepth of
         {4: imgP.PixF := PIXF_INDEX_4;}
         8: imgP.PixF  := PIXF_INDEX_8;
         24:imgP.PixF  := PIXF_RGB;
         else begin
            ld^.SetError(eUNSUPPORTED);
            exit;
         end;
      end;

      lineSize          := hdr^.nPlanes * hdr^.BytesPerLine;
      if(lineSize = 0) then begin
         ld^.SetError(eINVALID);
         exit;
      end;

      {allocate memory for the image}
      ld^.Calculate();
      ld^.Allocate();

      if(ld^.GetError() <> 0) then begin
         cleanup();
         exit;
      end;

      {load the data}
      pcxiData    := pcxData + 127; {get the position of the image data}
      imgData     := imgP.Image;

      if(imgP.PixelDepth = 24) then begin
         incCount := 3;

         {process all lines}
         if(hdr^.Encoding = 0) then begin
            for i := 0 to (imgP.Height-1) do begin
               bytes       := 0;
               {process the red plane}
               imgData     := imgP.Image + (i * imgP.Width * 3) + 0;
               processPlane();
               {process the green plane}
               imgData     := imgP.Image+(i * imgP.Width * 3) + 1;
               processPlane();
               {process the blue plane}
               imgData     := imgP.Image+(i * imgP.Width * 3) + 2;
               processPlane();
               processAlignment();
            end;
         end else begin
            for i := 0 to (imgP.Height-1) do begin
               bytes       := 0;
               {process the red plane}
               imgData     := imgP.Image+(i * imgP.Width * 3) + 0;
               processPlaneRLE();
               {process the green plane}
               imgData     := imgP.Image+(i * imgP.Width * 3) + 1;
               processPlaneRLE();
               {process the blue plane}
               imgData     := imgP.Image+(i * imgP.Width * 3) + 2;
               processPlaneRLE();
               processAlignment();
            end;
         end;
      end else if(imgP.PixelDepth = 8) then begin
         {get the image}
         incCount          := 1;
         if(hdr^.Encoding = 0) then begin
            for i := 0 to (imgP.Height-1) do begin
               bytes       := 0;
               imgData     := imgP.Image + (i * imgP.Width);
               processPlane();
               processAlignment();
            end;
         end else begin
            for i := 0 to (imgP.Height-1) do begin
               bytes       := 0;
               imgData     := imgP.Image + (i * imgP.Width);
               processPlaneRLE();
               processAlignment();
            end;
         end;

         {get the palette(only in version 5 or better)}
         if(hdr^.Version >= 5) then begin
            {go to the end of the file}
            pcxiData := pcxData+(fileSize-769);
            {check for palette presence}
            if(byte(pcxiData^) = 12) then begin
               inc(pcxiData);

               {get memory for the palette}
               pal.Make(imgP, PIXF_RGB, 256);
               if(ld^.GetError() <> 0) then
                  exit;

               palData := imgP.palette.Data;

               {read in the palette}
               for i := 0 to 255 do begin
                  TColor3ub(palData^) := TColor3ub(pcxiData^);
                  inc(pcxiData, 3);
                  inc(palData, 3);
               end;
            end;
         end;
      end;
   {if(pcxData <> nil)}
   end else
      ld^.SetError(eNO_MEMORY);
end;

INITIALIZATION
   imgFile.Readers.RegisterHandler(loader, 'PCX', @load);
   imgFile.Readers.RegisterExt(ext, '.pcx', @loader);

END.
