{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH ADVANCEDRECORDS}
PROGRAM Simple;

   USES uStd, uLog, uFileStd,
     uImage, imguOperations,
     {readers}
     imguBMP, imguTGA, imguJPEG, imguWAL, imguPNM, imguPCX, {dTMG, }imguSGIRGB, imguPNG,
     {writers}
     imguRW, imguwTGA, imguPaletteRW;

CONST
   nocopy: boolean      = true;

VAR
   image, image2: imgTImage;
   imgProps: imgTRWProperties;
   imgFN: string;

   errcode: longint;

function saveImage(var img: imgTImage): longint;
begin
   result := eNONE;

   if(img.PixF = PIXF_RGBA) then
      result := imgOperations.Transform(img, PIXF_BGRA)
   else if(img.PixF = PIXF_RGB) then
      result := imgOperations.Transform(img, PIXF_BGR);

   if(result <> 0) then exit;

   result := imgFile.Write(img, 'saved.tga');
end;

procedure writelnError();
begin
   write('img error: ', imgProps.error.e);
   write(' | file: ', imgProps.error.f);
   write(' | eIO: ', imgProps.error.io);
   writeln();
end;

BEGIN
   log.InitStd('test', '', logcREWRITE);
   img.settings.log := true;

   imgFN    := ParamStr(1);
   if(imgFN = '') then
      imgFN := 'image.tga';

   image := nil;
   image2 := nil;
   imgFile.Init(imgProps);

   writeln('Load ...');
   errcode := imgFile.Load(image, imgFN, imgProps);
   if(errcode = 0) then begin
      writeln('... End');

      if(not nocopy) then begin
         writeln('Copying in memory...');
         errcode := image.Copy(image2);
      end;

      if(errcode = 0) then begin
         if(not nocopy) then
            writeln('... End');

         writeln('Write ...');

         img.settings.defaultColorChannelOrder := PIXF_COLOR_CHANNEL_ORDER_BGR;
         img.settings.setToDefaultColorChannelOrder := true;

         if(image2 <> nil) then
            saveImage(image2)
         else
            saveImage(image);

         if(errcode <> 0) then begin
            writelnError();
         end;
         writeln('... End');
      end else begin
         writeln('Error copying image in memory: ', errcode);
      end;
   end else begin
      writelnError();
   end;

   img.Dispose(image);
   img.Dispose(image2);
END.
