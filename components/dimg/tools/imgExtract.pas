{
   imgExtract, extracts raw data from image files
   Copyright (C) 2008. Dejan Boras

   Started On:    17.04.2008.
}

{$MODE OBJFPC}{$H+}{$I-}
PROGRAM imgExtract;

   USES dStd, dError, ConsoleUtils,
   dImage, dBMP, dTGA, dJPEG, dPCX, dPNM, dWAL, dPNG, dSGIRGB;

CONST
   dcProgramName: string      = 'imgExtract';
   dcProgramVersion           = $0100;
   dcProgramAuthor            = 'Dejan Boras';
   dcProgramDescription       = 'Extracts raw data from image files';

   {default file names}
   cdfnPalette                = 'bitmap.pal';
   cdfnPixels                 = 'bitmap.pix';

   {extraction operations}
   copPalette                 = 01;
   copPixels                  = 02;

VAR
   Image: imgTImage;
   imgFileName, dataFileName: string;
   dataFile: file;

   Operation: uint32; {the operation this program should perform}

{extract the palette from the bitmap}
procedure Extract();
var
   errcode: longint;

begin
   {load the image}
   writeln('Loading image: ', imgFileName);
   errcode := imgLoad(imgFileName, Image);
   if(errcode <> 0) then begin
      console.e('Unable to load the image.');
      if(errcode = eIO) then
         Writeln('IO Error: ', _IOResult)
      else
         Writeln('Error Value: ', errcode);
      halt(1);
   end;

   if(Operation = copPalette) then begin
      if(Image.ColorTable = nil) or (Image.ctSize = 0) then begin
         console.e('Color table is not loaded.');
         halt(1);
      end;
   end else if(Operation = copPixels) then begin
      if(Image.Image = nil) or (Image.Size = 0) then begin
         console.e('The image is either not loaded or empty.');
         halt(1);
      end;
   end;

   {write the palette}
   if(Operation = copPalette) then begin
      writeln('Writing palette file to: ', dataFileName);
   end else if(Operation = copPixels) then begin
      writeln('Writing pixels file to: ', dataFileName);
   end;

   {open the palette file}
   Assign(dataFile, dataFileName);
   Rewrite(dataFile, 1);
   if(ioerror <> 0) then begin
      console.e('Cannot create the palette file.');
      halt(1);
   end;

   {write the data}
   if(Operation = copPalette) then begin
      blockwrite(dataFile, Image.ColorTable^, Image.ctSize);
      if(ioerror <> 0) then begin
         console.e('Cannot write to the palette file.');
         halt(1);
      end;
   end else if(Operation = copPixels) then begin
      blockwrite(dataFile, Image.Image^, Image.Size);
      if(ioerror <> 0) then begin
         console.e('Cannot write to the pixels file.');
         halt(1);
      end;
   end;

   {close and finish}
   Close(dataFile);
   if(ioerror <> 0) then begin
      console.w('Could not properly close the palette file.');
   end;
end;

{initialize the program}
procedure initProgram();
begin
end;

{sets the operation specified by a parameter}
procedure SetOperation(op: uint32);
begin
   if(Operation = 0) then 
      Operation := op
   else begin
      console.e('Cannot perform more than one operation.');
      halt(1);
   end;
end;

{parse parameters}
procedure ParseParameters();
var
   i, nParams, nName: int32;
   pStr: string;

begin
   pStr := ParamStr(1);
   {Check parameters}
   if (pStr = '?') or (pStr = '-?') or (pStr = '/?') then begin
      writeln('imgExtract v1.00');
      writeln('Extracts raw data from images(pixels, palettes)');
      writeln('Copyright (c) Dejan Boras 2008.');
      writeln;
      writeln('imgExtract [-pix, -pal] [imgfile] [datafile]');
      halt(0);
   end;

   nParams := ParamCount(); nName := 0;
   for i := 1 to nParams do begin
      pStr := ParamStr(i);
      if(pstr[1] = '-') then begin {a option}
         pStr := LowerCase(pStr);
         if(pStr = '-pal') then 
            SetOperation(copPalette)
         else if(pStr = '-pix') then 
            SetOperation(copPixels)
         else
            console.e('Unkown operation: '+pStr+'. Use -? option for help.');
      end else begin
         inc(nName);
         case nName of
            1: imgFileName := pStr;
            2: dataFileName := pStr;
            else begin
               console.e('Too many parameters. Check your typing.'); 
               halt(1);
            end;
         end;
      end;
   end;

   {check arguments}
   if(Operation = 0) then begin
      console.e('Operation not specified.'); 
      halt(1);
   end;

   {check if the file name is specified}
   if(nName = 0) then begin
      console.e('Image file name not specified.'); 
      halt(1);
   {check if the data file name is specified}
   end else if (nName = 1) then begin
      case Operation of
         copPalette: begin
            console.w('Palette file name not specified. Will use: ' + cdfnPalette);
            dataFileName := cdfnPalette;
         end;
         copPixels: begin
            console.w('Pixels file name not specified. Will use: ' + cdfnPixels);
            dataFileName := cdfnPixels;
         end;
      end;
   end;
end;

BEGIN
   initProgram();
   ParseParameters();
   Extract();

   Writeln('Done.');
END.
