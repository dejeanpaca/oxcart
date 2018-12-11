{
   tvImg
   Converts normal images to dTVideo images(.tvi) and views them
   Copyright (C) 2008. Dejan Boras

   Started On:    10.09.2008.
}

{$MODE OBJFPC}{$H+}{$I-}
PROGRAM tvImg;

   USES Crt, dStd, ConsoleUtils, dImage, dTGA, dBMP,
   dJPEG, uTVideoImg, uTVideo, Video;

CONST
   {operations}
   copView        = 01;
   copMake        = 02;
   copViewPalette = 03;

   {default tv image name}
   cdfnMake: string = 'image.tvi';

   {characters used for drawing}
   cUP = 220;
   cDN = 223;

   {standard palette}
   palette: array[0..15] of TColor3ub =
  ((0, 0, 0), {0, black}
   (0, 0, 255), {1, blue}
   (0, 85, 255), {2, dark green}
   (0, 170, 255), {3, turqoise}
   (255, 0, 0), {4, red}
   (255, 85, 255), {5, magenta}
   (255, 255, 170), {6, orange}
   (0, 170, 0), {7, dark white}
   (255, 85, 0), {8, dark gray}
   (0, 85, 0), {9, light blue}
   (0, 255, 0), {10, green}
   (0, 255, 255), {11, light turqoise}
   (255, 0, 255), {12, light red}
   (255, 170, 255), {13, light magenta}
   (255, 255, 0), {14, yellow}
   (255, 255, 255)); {15, white}

VAR
   {operation to be performed}
   operation: longword;
   {source and destination filenames}
   sourceFN, destFN: string;

   {images}
   Image: imgTImage;
   tvImage: pointer;

{view the palette}
procedure ViewPalette();
var
   j, i: longword;

begin
   tvInit();
   tvSetMode(tvcM80x25T);

   for j := 0 to 15 do begin
      tvSetColor(j);
      for i := 0 to 80 do begin
         tvPlot(i, j, #219);
      end;
   end;

   UpdateScreen(true);
   
   repeat until keypressed;
end;

{views the image}
procedure ViewImage();
begin
   {load the image}
   tvLoadImage(sourceFN, tvImage);
   if(tvError <> 0) then begin
      console.e('Failed to load the image.'); halt(1);
   end;

   tvInit();
   tvSetMode(tvcM80x50T);
   tvPlotImage(0, 0, tvImage);
   UpdateScreen(true);
   
   repeat until keypressed;

   {dispose the image}
   tvDisposeImage(tvImage);

   {deinit}
   tvDeInit();
end;

{no, this is not about religion, but about converting images}
procedure Convert();
var
   w, h: word;
   size: longword;
   i, j: longword;
   
   inc1, inc2, pos1, pos2: ptrint;
   clr, attr: byte;
   cell: TVideoCell;

   function WhichColor(var clr: TColor3ub): uint8;
   var
      i, gclr: longword;

   begin
      WhichColor := 0;
      for i := 0 to 15 do begin
         if(clr[0] = palette[i][0]) and
           (clr[1] = palette[i][1]) and
           (clr[2] = palette[i][2]) then exit(i);
      end;
   end;

begin
   tvInit();

   {check the source image to see if it is compatible}
   if(Image.Width > 65535) or (Image.Height > 65535) then begin
      console.e('The source image is too large.'); halt(1);
   end;

   {get the width and height, and calculate the size for the new image}
   w := Image.Width; h := Image.Height;
   size := w*h*2;

   {allocate memory for the new image}
   XGetMem(tvImage, size+4);
   if(tvImage <> nil) then begin
      {initialize the image}
      Zero((tvImage)^, size+4, 0);

      {store the width and height of the new image}
      uint16(tvImage^)     := w;
      uint16((tvImage+2)^) := h;

      {convert}
      inc1 := 3; inc2 := 2; pos1 := 0; pos2 := 4;
      for j := 0 to (w-1) do begin
         for i := 0 to (h-1) do begin
            {figure out which color it is and make a cell}
            clr := WhichColor(TColor3ub((Image.Image+pos1)^));
            attr := clr;
            cell := byte(#219) + (attr shl 8);
            //cell := tvMakeCell('O'{#219}, clr, 0);
            {write the cell}
            TVideoCell((tvImage+pos2)^) := cell;
            {go to next cell}
            inc(pos1, inc1); inc(pos2, inc2);
         end;
      end;
   end else begin
      console.e('Insufficient memory for the new image.'); halt(1);
   end;
   {done}
end;

{makes the image}
procedure MakeImage();
begin
   writeln('Making the image...');

   writeln('Loading source image: ', sourceFN);
   imgErrorReset();
   {load the image}
   imgLoad(sourceFN, Image);
   if(imgError <> 0) then begin
      console.e('Unable to load the source image.'); halt(1);
   end;

   {create a tvImage}
   writeln('Converting the image...');
   Convert();

   {save the image}
   writeln('Saving the image: ', destFN);
   tvSaveImage(destFN, tvImage);
   if(tvError <> 0) then begin
      console.e('Unable to save the destination image.'); halt(1);
   end;

   writeln('Done!');
end;

{sets the specified operation}
procedure SetOperation(op: longword);
begin
   if(operation = 0) then operation := op
   else begin
      console.e('Cannot set more than one operation.'); halt(1);
   end;
end;

procedure WriteHelp();
begin
   writeln('tvImg v1.00');
   writeln('Views and creates dTVideo compatible images');
   writeln('Copyright (c) Dejan Boras 2008.');
   writeln;
   writeln('For viewing: tvImg -view [source]');
   writeln('For viewing the palette: tvImg -viewpal');
   writeln('For making:  tvImg -make [source] [destination]')
end;

{parses the parameters}
procedure ParseParameters();
var
   i, nParams, nName: longint;
   pStr: string;

begin
   pStr := ParamStr(1);
   {Check parameters}
   if (pStr = '?') or (pStr = '-?') or (pStr = '/?') then begin
      WriteHelp(); halt(0);
   end;

   nParams := ParamCount(); nName := 0;
   for i := 1 to nParams do begin
      pStr := ParamStr(i);
      if(pstr[1] = '-') then begin {a option}
         pStr := LowerCase(pStr);
         if(pStr = '-view') then SetOperation(copView)
         else if(pStr = '-make') then SetOperation(copMake)
         else if(pStr = '-viewpal') then SetOperation(copViewPalette)
         else begin
            console.e('Unkown operation: '+pStr+'. Use -? option for help.');
         end;
      end else begin
         inc(nName);
         case nName of
            1: sourceFN := pStr;
            2: destFN := pStr;
            else begin
               console.e('Too many parameters. Check your typing.'); halt(1);
            end;
         end;
      end;
   end;

   {check arguments}
   if(Operation = 0) then begin
      console.e('Operation not specified.'); halt(1);
   end;

   {check if the file name is specified}
   if(nName = 0) and (Operation <> copViewPalette) then begin
      console.e('Source file name not specified.'); halt(1);
   {check if the data file name is specified}
   end else if (nName = 1) then begin
      case Operation of
         copMake: begin
            console.w('Destionation name not specified. Will use: '+cdfnMake);
            destFN := cdfnMake;
         end;
      end;
   end;
end;

procedure InitProgram();
begin
end;

BEGIN
   InitProgram();
   ParseParameters();

   case operation of
      copView: ViewImage();
      copMake: MakeImage();
      copViewPalette: ViewPalette();
   end;
END.
