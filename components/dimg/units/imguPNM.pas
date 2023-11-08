{
   imguPNM, PNM image loader for dImage
   Copyright (C) 2007. Dejan Boras

   Started On:    05.11.2007.
}

{$INCLUDE oxdefines.inc}
UNIT imguPNM;

{A loader for Portable aNyMaps(PNM). It can load portable bitmaps(PBM),
portable greymaps(PGM) and portable pixmaps(PPM).
Actually not. It can currently only load PPM P6 Raw files.}

INTERFACE

   USES uStd, uImage, uFileHandlers, imguRW, StringUtils;

TYPE
   pnmTID = array[0..2] of char;

CONST
   pnmcP6ID: pnmTID     = ('P', '6', #10);

   pnmcP6               = 6;

IMPLEMENTATION

VAR
   pbmExt,
   pgmExt,
   ppmExt: fhTExtension;
   loader: fhTHandler;

procedure pnmLoad(data: pointer);
var
   ld: imgPFileData = nil;
   imgP: imgTImage = nil;

   id: array[0..3] of char;
   j, pnmType: longword;
   code: longint;
   aStr: string = '';

procedure xreadstr(var aStr: string);
var
   c: char = #0;
   s: shortstring = '';
   i: longword = 1;

begin
   i := 0;
   repeat
      ld^.BlockRead(c, 1);

      if(ld^.Error = 0) then begin
         if(c = #10) then
            break;

         s[1+i] := c;
         inc(i);
      end else
         exit;
   until i = 255;

   s[0] := char(i);
   aStr := s;
end;

begin
   ld := data; 
   imgP := ld^.Image;

   ld^.BlockRead(ID, SizeOf(pnmTID));
   if(ld^.Error <> 0) then exit;

   if(id = pnmcP6ID) then
      pnmType := pnmcP6
   else begin
      ld^.SetError(eUNSUPPORTED);
      exit;
   end;

   j := 0;
   repeat
      xreadstr(aStr);
      if(ld^.Error = 0) then begin
         if(aStr[1] <> '#') then begin
            {get the width and height}
            if(j = 0) then begin
               Val(CopyToDel(aStr), imgP.Width, code);

               if(code <> 0) then begin
                  ld^.SetError(eINVALID);
                  exit;
               end;

               Val(CopyToDel(aStr), imgP.Height, code);

               if(code <> 0) then begin
                  ld^.SetError(eINVALID);
                  exit;
               end;
            {get the maximum color}
            end else begin
               if(aStr = '255') then break
               else begin
                  ld^.SetError(eINVALID);
                  exit;
               end;
            end;
            inc(j);
         end;
      end else
         exit;
   until (j = 10);

   if(pnmType = pnmcP6) then begin
      imgP.PixF := PIXF_RGB;
      imgP.PixelDepth := 24;
   end;

   imgP.Origin := imgcORIGIN_TL; {top-left}

   {calculate image properties}
   ld^.Calculate();

   {allocate memory for the image}
   ld^.Allocate();

   if(ld^.Error <> 0) then
      exit;

   {read in all the data}
   if(imgP.Image <> nil) then begin
      {$PUSH}{$HINTS OFF}
      ld^.BlockRead(imgP.Image^, imgP.Width * imgP.Height * 3);{$POP}

      if(ld^.Error <> 0) then
         exit;
   end;
end;

BEGIN
   {register the extensions and the loader}
   imgFile.Loaders.RegisterExt(pbmExt, '.pbm', @loader);
   imgFile.Loaders.RegisterExt(pgmExt, '.pgm', @loader);
   imgFile.Loaders.RegisterExt(ppmExt, '.ppm', @loader);

   imgFile.Loaders.RegisterHandler(loader, 'PNM', @pnmLoad);
END.
