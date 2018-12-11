{
   oxfonttex, creates a font texture
   Copyright (C) 2009. Dejan Boras
   
   Started On:    26.06.2009.
}

{$MODE OBJFPC}{$H+}
PROGRAM oxfonttex;

   USES ConsoleUtils, ParamUtils, StringUtils, uColors, ufhStandard,
   {dImage}
   uImage, imguRW, imguOperations,
   {$INCLUDE imgIncludeAllLoaders.inc},
   imguwTGA;

CONST
   dcProgramVersion     = $0114;

   {texture types}
   TEX_TYPE_WOB         = $0000;
   TEX_TYPE_BOW         = $0001;

VAR
   fntname: string;

   srcimg, 
   img: imgTImage;
   errcode: longint;

   TexType: int32 = TEX_TYPE_WOB;
   ReverseAlpha: boolean = false;
   MaxIntensity: boolean = false;

procedure Terminate(code: uint8);
begin
   srcimg.Dispose();
   img.Dispose();
   halt(code);
end;

procedure WriteVersion();
begin
   writeln();
   writeln('oxfonttex v' + sf(Hi(dcProgramVersion)) + '.' + sf(Lo(dcProgramVersion)));
   writeln('Copyright (c) 2009. Dejan Boras ');
   writeln();
   Terminate(0);
end;

procedure WriteHelp(err: int32);
begin
   writeln('oxfonttex [srcimg]');
   writeln(' -help         - writes this screen');
   writeln(' -version      - displays the program version');
   writeln(' texture parameters:');
   writeln('      -bow     - black text on white background');
   writeln('      -wob     - white text on black background');
   writeln();
   writeln('The output file is named font.tga in the Truevision TGA (TARGA) format.');
   writeln('-wob is default if neither -bow or -wob specified.');
   Terminate(err);
end;

procedure WriteHelp();
begin
   WriteHelp(0);
end;

{this routine will set all non-black colors in the font image to white}
procedure Whiten();
var
   j: int32;
   pColor: PColor3ub = nil;

begin
   pColor := srcimg.Image;
   for j := 0 to (srcimg.Height*srcimg.Width-1) do begin
      if(pColor^[0] > 0) then 
         pColor^[0] := 255;
      if(pColor^[1] > 0) then 
         pColor^[1] := 255;
      if(pColor^[2] > 0) then 
         pColor^[2] := 255;
      inc(pointer(pColor), 3);
   end;
end;

{this routine sets the alpha values in the new image}
procedure doAlpha();
var
   j: int32;
   pColor: PColor3ub = nil;
   pAlpha: PColor4ub = nil;
   pAlpha3: PColor3ub absolute pAlpha;
   alpha: uint8;

begin
   pColor := srcimg.Image;
   pAlpha := img.Image;

   if(TexType = TEX_TYPE_BOW) then begin
      for j := 0 to (srcimg.Height*srcimg.Width-1) do begin
         pAlpha3^ := pColor^;
         alpha := (pColor^[0] + pColor^[1] + pColor^[2]) div 3;
         if(ReverseAlpha) then
            alpha := 255 - alpha;
         pAlpha^[3] := alpha;

         if(MaxIntensity) then begin
            pAlpha^[0] := 0;
            pAlpha^[1] := 0;
            pAlpha^[2] := 0;
         end;

         inc(pColor);
         inc(pAlpha);
      end;
   end else if(TexType = TEX_TYPE_WOB) then begin
      for j := 0 to (srcimg.Height*srcimg.Width-1) do begin
         pAlpha3^ := pColor^;
         alpha := 255 - ((pColor^[0] + pColor^[1] + pColor^[2]) div 3);
         if(ReverseAlpha) then
            alpha := 255 - alpha;
         pAlpha^[3] := alpha;

         if(MaxIntensity) then begin
            pAlpha^[0] := 255;
            pAlpha^[1] := 255;
            pAlpha^[2] := 255;
         end;

         inc(pColor);
         inc(pAlpha);
      end;
   end;
end;

{this routine will process the images and create a new font image}
procedure Process();
begin
   writeln('Processing...');

   {transform and pre-process the source image}
   imgOperations.Transform(srcimg, PIXF_RGB);

   if(TexType = TEX_TYPE_BOW) then
      imgOperations.InvertColors(srcimg);

   Whiten();

   {create a new image in memory}
   errcode := srcimg.Copy(img);
   if(errcode <> 0) then begin
      console.e('Could not create a new image in memory');
      Terminate(1);
   end;

   {transform the new image to include an alpha channel}
   errcode := imgOperations.Transform(img, PIXF_RGBA);
   if(errcode <> 0) then begin
      console.e('Could not transform the image to the required pixel format.');
   end;

   {find the alpha for the new image}
   doAlpha();
end;

function params(const pstr, lstr: string): boolean;
var
   ps: string;

begin
   result := true;

   ps := lstr;
   if(ps = '-?') or (ps = '?') or
      (ps = '/?') or (ps = '-help') then
         WriteHelp()
   else if(ps = '-version') then
      WriteVersion()
   else if(ps = '-wob') then begin
      TexType := TEX_TYPE_WOB;
   end else if(ps = '-bow') then begin
      TexType := TEX_TYPE_BOW;
   end else if(ps = '-reverse') then begin
      ReverseAlpha := true;
   end else if(ps = '-max') then begin
      MaxIntensity := true;
   end else begin
      fntname := pstr;
   end;
end;

BEGIN
   {process parameters}
   parameters.Process(@params);
   if(fntname = '') then begin
      console.e('Did not enter valid name for font image.');
      WriteHelp(1);
   end;

   {load images}
   writeln('Loading image...');
   errcode := imgFile.Load(srcimg, fntname);
   if(errcode <> 0) then begin
      console.e('Could not load the font image.');
      Terminate(1);
   end;

   {do the thing}
   Process();

   writeln('Writing...');
   {write the image}
   errcode := imgFile.Write(img, 'font.tga');
   if(errcode <> 0) then begin
      console.e('Failed to write the file properly.');
   end;

   writeln('Done');
END.
