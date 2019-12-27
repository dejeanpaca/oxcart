{
   imguJPEG, JPEG image loader for dImage
   Copyright (C) 2007. Dejan Boras

   Started On:    05.11.2007.
}

{$INCLUDE oxdefines.inc}
UNIT imguJPEG;

INTERFACE

   USES
      uStd, uImage, uFileHandlers, imguRW,
      jpeglib, jerror, jdapimin, jdapistd, jdatasrc, Classes;

IMPLEMENTATION

VAR
   ext,
   ext2: fhTExtension;
   loader: fhTHandler;

procedure decodeJPEG(cinfo: jpeg_decompress_struct; var img: imgTImage; var ld: imgTFileData);
var
   i,
   nComponents,
   rowSpan: longint;
   rowsRead: longword;
   rows: array of pointer        = nil;
   startedDecompress: boolean    = false;

procedure CleanUp();
begin
   if(Length(rows) > 0) then
      SetLength(rows, 0);
   if(startedDecompress) then
      jpeg_finish_decompress(@cinfo);
end;

begin
   try
   {read in the jpeg file header}
   jpeg_read_header(@cinfo, true);

   {start data decompression}
   jpeg_start_decompress(@cinfo);
   startedDecompress := true;

   {assign values}
   nComponents       := cinfo.num_components;

   {width and height}
   img.Width         := cinfo.image_width;
   img.Height        := cinfo.image_height;
   img.Origin        := imgcORIGIN_TL; {top-left origin}

   {assign the pixel format and depth information}
   case nComponents of
      3: begin
         img.PixF := PIXF_RGB;
         img.PixelDepth := 24;
      end;
      4: begin
         img.PixF := PIXF_RGBA;
         img.PixelDepth := 32;
      end;
      else begin
         CleanUp();
         ld.error := eUNSUPPORTED;
         exit;
      end;
   end;

   {calculate number of pixels and image size}
   ld.Calculate();

   {allocate memory for the image data}
   ld.Allocate();

   {get the row span(size) in bytes so we know how long a row(line) is}
   rowSpan := nComponents*img.Width;

   {allocate memory for the array of row pointers and make them point to the appropriate rows}
   SetLength(rows, img.Height);
   if(Length(rows) < img.Height) then begin
      CleanUp();
      ld.error := eNO_MEMORY;
      exit;
   end;

   for i := 0 to (img.Height-1) do begin
      rows[i] := (img.Image+(i*rowSpan));
   end;

   {now we need to decode all the pixels from the scanlines}
   rowsRead := 0;
   while(cinfo.output_scanline < cinfo.output_height) do begin
      {read the current row of pixels}
      inc(rowsRead,
         jpeg_read_scanlines(@cinfo, @rows[rowsRead], cinfo.output_height - rowsRead));
   end;

   {that's it, now clean up}
   CleanUp();
   except
      ld.error := eIO;
      Cleanup();
      exit;
   end;
end;

procedure load(data: pointer);
var
   cinfo: jpeg_decompress_struct; {jpeg decompression info}
   jerr: jpeg_error_mgr; {jpeg error handler}

   f: TFileStream = nil;
   ld: imgPFileData;

begin
   ld := data;

   ZeroOut(jerr, SizeOf(jerr));

   try
      f := TFileStream.Create(ld^.fn, fmOpenRead);
   except
      ld^.SetError(eIO);
      exit;
   end;

   try
      {use the standard jpeg error handler}
      cinfo.err := jpeg_std_error(jerr);

      {initialize the jpeg decompression information}
      jpeg_create_decompress(@cinfo);

      {set the image file to be the data source}
      jpeg_stdio_src(@cinfo, @f);

      {decode the JPEG information into a valid imgTImage record}
      decodeJPEG(cinfo, ld^.Image, ld^);
    except
      ld^.SetError(eIO);
    end;

   {clean up the jpeg decompression info}
   jpeg_destroy_decompress(@cinfo);

   f.Free();
end;

INITIALIZATION
   {register the extensions and the loader}
   imgFile.Loaders.RegisterHandler(loader, 'JPEG', @load);
   {jpeg handler doesn't support file abstractions}
   loader.DoNotOpenFile := true;

   imgFile.Loaders.RegisterExt(ext, '.jpg', @loader);
   imgFile.Loaders.RegisterExt(ext2, '.jpeg', @loader);

END.
