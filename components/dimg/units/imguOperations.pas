{
   imguOperations, image operations
   Copyright (C) 2013. Dejan Boras

   Started On:    07.04.2013.
}

{$INCLUDE oxheader.inc}
UNIT imguOperations;

INTERFACE

   USES
      uStd, uColors, uImage;

TYPE

   { imgTOperations }

   imgTOperations = record
      UseWeightedAverage: boolean;

      {flip image verticaly}
      function FlipV(var image: imgTImage): longint;
      {flip image horizontaly}
      function FlipH(var image: imgTImage): longint;

      {transform the image from one pixel format to another}
      function Transform(var image: imgTImage; TargetFormat: byte): longint;

      {adjust the gamma factor of an image}
      procedure Gamma(var image: imgTImage; factor: single);
      {swaps the specified color channels}
      function SwapColorChannels(var image: imgTImage; chans: longword): boolean;
      {invert the image colors}
      procedure InvertColors(var image: imgTImage);

      {sets transparent only zero (0, 0, 0) pixels}
      procedure AlphaZero(var image: imgTImage);
      {uses the average color as alpha value}
      procedure AlphaFromAverage(var image: imgTImage);
      {uses the inverse level of white (rgb average value) as alpha (alpha increases the darker the pixel is)}
      procedure AlphaFromInverseAverage(var image: imgTImage);

      {set all pixels that are non-zero to max values (255)}
      procedure MaxPixelValues(var image: imgTImage);

      {set the image to the target origin}
      procedure SetOrigin(var image: imgTImage; target: longint);
      {sets the image to the default origin, based on what it's origin is now}
      procedure SetDefaultOrigin(var image: imgTImage);
      {set default colors}
      procedure SetDefaultPixelFormat(var image: imgTImage);
      {set the image to the default color channel order}
      procedure SetDefaultColorChannelOrder(var image: imgTImage);

      {NOTE: Filling uses a qword parameter, which supports pixel formats up to 8 bytes in size}

      {fill the image with some value}
      function Fill(var image: imgTImage; c: qword): longint;
      {fill a region of the image with some value}
      function Fill(var image: imgTImage; x, y, w, h: longint; c: qword): longint;
   end;

VAR
   imgOperations: imgTOperations;

IMPLEMENTATION

{ IMAGE PROCESSING }

function imgTOperations.FlipV(var image: imgTImage): longint;
var
   i,
   lineSize,
   pos,
   pos2: longint;
   line: pointer = nil;
   PD: byte;

begin
   Result := eNONE;

   if(image.Image = nil) or (image.Width = 0) or (image.Height < 2) then
      exit;

   {get the pixel depth}
   PD := img.PIXFDepth(image.PixF);
   if(PD mod 8 <> 0) then
      exit(eUNSUPPORTED);

   PD := PD div 8;

   {allocate enough memory for the line}
   linesize := (image.Width*PD);
   GetMem(line, lineSize);

   if(line <> nil) then begin
      {flip all lines vertically, that is swap them}
      pos := 0; pos2 := (image.Size-lineSize);
      for i := 0 to (image.Height div 2 - 1) do begin
         {put the first line into the temporary one}
         move((image.Image + pos)^, line^, lineSize);

         {put the second line into the first}
         move((image.Image + pos2)^, (image.Image + pos)^, lineSize);

         {put the temporary line into the second}
         move(line^, (image.Image + pos2)^, lineSize);

         inc(pos, lineSize);
         dec(pos2, lineSize);
      end;

      XFreeMem(line);
   end else
      exit(eNO_MEMORY);
end;

{TODO: Implementation of the routine is not completed.}
function imgTOperations.FlipH(var image: imgTImage): longint;
var
   i,
   lineSize,
   cPos: longword;
   line: pointer = nil;
   PD: byte;

begin
   Result := eNONE;

   if(image.Image = nil) or (image.Width = 0) or (image.Height = 0) then
      exit;

   {get the pixel depth}
   PD := img.PIXFDepth(image.PixF);
   if(PD mod 8 <> 0) then
      exit(eUNSUPPORTED);

   PD := PD div 8;

   {allocate enough memory for the line}
   linesize := image.Width * PD;
   GetMem(line, lineSize);
   if(line <> nil) then begin
      cPos := 0;

      {flip all lines horizontally}
      for i := 0 to (image.Height - 1) do begin
         {move the current line to temporary line memory}
         move((image.Image + cPos)^, line^, linesize);
         {now move the line back to it's place only flipped horizontally}
      end;

      XFreeMem(line);
   end else
      exit(eNO_MEMORY);
end;

function imgTOperations.Transform(var image: imgTImage; TargetFormat: byte): longint;
var
   j,
   i: longint;

   newImage: pointer = nil;
   imgSize: longword;
   Depth,
   newDepth: byte;

   oiData,
   niData: pointer;
   oInc,
   nInc: longint;

   {NOTE: Colors stored in clr4ub and clr3ub must always have RGB/A channels,
   so the transformation routine needs not determine what channels are stored.}
   clr4ub: TColor4ub;
   clr3ub: TColor3ub absolute clr4ub;

{routines that convert from X to RGB/A accept a color and store it into clr4ub,
other routines use the color in clr4ub and store it into clr(parameter)}
procedure BGRtoRGB(clr: TColor3ub);
begin
   {r=b, g=g, b=r}
   clr4ub[0] := clr[2];
   clr4ub[1] := clr[1];
   clr4ub[2] := clr[0];
end;

procedure RGBtoBGR(var clr: TColor3ub);
begin
   {r=b, g=g, b=r}
   clr[2] := clr4ub[0];
   clr[1] := clr4ub[1];
   clr[0] := clr4ub[2];
end;

procedure BGRAtoRGBA(clr: TColor4ub);
begin
   clr4ub[0] := clr[2];
   clr4ub[2] := clr[0];
   clr4ub[1] := clr[1];
   clr4ub[3] := clr[3];
end;

procedure RGBAtoBGRA(var clr: TColor4ub);
begin
   clr[2] := clr4ub[0];
   clr[0] := clr4ub[2];
   clr[1] := clr4ub[1];
   clr[3] := clr4ub[3];
end;

procedure ARGBtoRGBA(clr: TColor4ub);
begin
   {r=a, g=r, b=g, a=b}
   clr4ub[3] := clr[0];
   clr4ub[0] := clr[1];
   clr4ub[1] := clr[2];
   clr4ub[2] := clr[3];
end;

procedure RGBAtoARGB(var clr: TColor4ub);
begin
   {r=a, g=r, b=g, a=b}
   clr[0] := clr4ub[3];
   clr[1] := clr4ub[0];
   clr[2] := clr4ub[1];
   clr[3] := clr4ub[2];
end;

procedure ABGRtoRGBA(clr: TColor4ub);
begin
   {r=a, g=b, b=g, a=r}
   clr4ub[3] := clr[0];
   clr4ub[0] := clr[3];
   clr4ub[1] := clr[2];
   clr4ub[2] := clr[1];
end;

procedure RGBAtoABGR(var clr: TColor4ub);
begin
   clr[0] := clr4ub[3];
   clr[3] := clr4ub[0];
   clr[2] := clr4ub[1];
   clr[1] := clr4ub[2];
end;

procedure GR8toRGB(clr: byte);
begin
   clr3ub[0] := clr;
   clr3ub[1] := clr;
   clr3ub[2] := clr;
end;

begin
   {first check the arguments}
   if(image.Image = nil) or (image.PixF = TargetFormat) then
      exit(eNONE);

   if(image.Compression <> 0) or (image.PixelDepth = 0) then
      exit(eUNSUPPORTED);

   {get information}
   Depth    := img.PIXFDepth(image.PixF);
   newDepth := img.PIXFDepth(TargetFormat);

   {check if the depth is suitable}
   if(Depth mod 8 <> 0) or (newDepth mod 8 <> 0) then
      exit(eUNSUPPORTED);

   {check if the image has a palette, if a palette is required}
   if((image.PixF = PIXF_INDEX_RGB_8) or (image.PixF = PIXF_INDEX_RGBA_8)) and (image.palette = nil) then
      exit(eINVALID);

   {allocate enough space for the new image data}
   imgSize := (image.Height * image.Width) * (newDepth div 8); {calculate size}
   GetMem(newImage, imgSize);

   clr4ub := cWhite4ub;

   if(newImage <> nil) then begin
      {get data}
      oiData   := image.Image; {old image data}
      niData   := newImage; {new image data}
      oInc     := Depth div 8; {old image increment}
      nInc     := newDepth div 8; {new image increment}

      for j := 0 to (image.Height - 1) do begin
         for i := 0 to (image.Width - 1) do begin
            {set the color to white with alpha 255}
            clr4ub := cWhite4ub;

            {get the old image pixel colors}
            case image.PixF of
               PIXF_INDEX_RGB_8:
                  clr3ub := TColorTable_8_RGB(image.palette.data^)[byte(oiData^)];
               PIXF_INDEX_RGBA_8:
                  clr4ub := TColorTable_8_RGBA(image.palette.data^)[byte(oiData^)];
               PIXF_INDEX_BGR_8: begin
                  clr3ub := TColorTable_8_RGB(image.palette.data^)[byte(oiData^)];
                  BGRtoRGB(clr3ub);
               end;
               PIXF_INDEX_BGRA_8: begin
                  clr4ub := TColorTable_8_RGBA(image.palette.data^)[byte(oiData^)];
                  BGRAtoRGBA(clr4ub);
               end;
               PIXF_RGB:
                  clr3ub := TColor3ub(oiData^);
               PIXF_BGR:
                  BGRtoRGB(TColor3ub(oiData^));
               PIXF_RGBA:
                  clr4ub := TColor4ub(oiData^);
               PIXF_BGRA:
                  BGRAtoRGBA(TColor4ub(oiData^));
               PIXF_ARGB:
                  ARGBtoRGBA(TColor4ub(oiData^));
               PIXF_ABGR:
                  ABGRtoRGBA(TColor4ub(oiData^));
               PIXF_GREYSCALE_8:
                  GR8toRGB(byte(oiData^));
            end;

            {transform to the new colors}
            case TargetFormat of
               PIXF_RGB:
                  TColor3ub(niData^) := clr3ub;
               PIXF_BGR:
                  RGBtoBGR(TColor3ub(niData^));
               PIXF_RGBA:
                  TColor4ub(niData^) := clr4ub;
               PIXF_BGRA:
                  RGBAtoBGRA(TColor4ub(niData^));
               PIXF_ARGB:
                  RGBAtoARGB(TColor4ub(niData^));
               PIXF_ABGR:
                  RGBAtoABGR(TColor4ub(niData^));
               PIXF_GREYSCALE_8: begin
                  if(UseWeightedAverage) then
                     pbyte(niData)^ := round((clr3ub[0] * 0.3 + clr3ub[1] * 0.59 + clr3ub[2] * 0.11) / 3)
                  else
                     pbyte(niData)^ := (clr3ub[0] + clr3ub[1] + clr3ub[2]) div 3;
               end;
            end;

            {move to the next pixel}
            inc(oiData, oInc);
            inc(niData, nInc);
         end;
      end;

      image.DisposeData();

      {set the new data}
      image.PixF := TargetFormat;
      image.Image := newImage;
      image.Calculate();

      Result := eNONE;
   end else
      exit(eNO_MEMORY);
end;

procedure imgTOperations.Gamma(var image: imgTImage; factor: single);
var
   incr,
   i: longword;
   pos: pointer;
   scale,
   temp,
   r,
   g,
   b: single;

begin
   if(image.Image <> nil) then begin
      {check if the image is of a supported format}
      if(image.PixF <> PIXF_RGB) and (image.PixF <> PIXF_RGBA) and
        (image.PixF <> PIXF_BGR) and (image.PixF <> PIXF_BGRA) then
           exit;

      {get the pixel depth}
      incr := img.PIXFIncrementBytes(image.PixF);
      pos  := image.Image;

      for i := 0 to (image.Height*image.Width)-1 do begin
         scale := 1.0; temp := 0.0;

         {get the r,g,b values(or b,g,r it does not matter)}
         r     := byte(pos^);
         g     := byte((pos+1)^);
         b     := byte((pos+2)^);

         {multiply the values by the factor, and keep the ratio of 255}
         r     := r * factor / 255.0;
         g     := g * factor / 255.0;
         b     := b * factor / 255.0;

         if(r = 0) then
            temp := 0.0
         else
            temp := 1.0 / r;

         if(r > 1.0) and (temp < scale) then
            scale := temp;

         if(g = 0) then
            temp := 0.0
         else
            temp := 1.0 / g;

         if(g > 1.0) and (temp < scale) then
            scale := temp;

         if(b = 0) then
            temp := 0.0
         else
            temp := 1.0 / b;

         if(b > 1.0) and (temp < scale) then
            scale := temp;

         {check if the values are higher than 255}

         {multiply all values by scale}
         scale    := scale * 255.0;
         r        := r * scale;
         g        := g * scale;
         b        := b * scale;

         {assign the new gamma corrected values}
         byte(pos^)        := byte(round(r));
         byte((pos + 1)^)  := byte(round(g));
         byte((pos + 2)^)  := byte(round(b));

         pos      := pos + incr;
      end;
   end;
end;

function imgTOperations.SwapColorChannels(var image: imgTImage; chans: longword): boolean;
var
   i,
   incr,
   xincr: longint;
   cPixel: PColor4ub;

begin
   Result := false;
   if(image.Image <> nil) then begin
      xincr := 0;
      incr := img.PIXFIncrementBytes(image.PixF);

      {check if the image is of a supported pixel format}

      case image.PixF of
         PIXF_INDEX_RGB_4,
         PIXF_INDEX_RGB_8,
         PIXF_INDEX_RGBA_4,
         PIXF_INDEX_RGBA_8: begin
            image.Palette.SwapColorChannels(chans);
            exit(true);
         end;

         PIXF_ARGB,
         PIXF_ABGR: begin
            xincr := 1;
         end;
         else
            exit; {unsupported format}
      end;

      {NOTE: xincr serves to skip channels that come before RGB or BGR channels}

      cPixel := pointer(image.Image);
      inc(Pointer(cPixel), xincr);

      {Swap channels by using triple xor swapping. Faster than using normal
      swapping with a temp variable.}
      case chans of
         {swap red and green channels}
         imgccRG: begin
            for i := 0 to (image.Pixels-1) do begin
               cPixel^[1] := cPixel^[1] xor cPixel^[0];
               cPixel^[0] := cPixel^[1] xor cPixel^[0];
               cPixel^[1] := cPixel^[1] xor cPixel^[0];

               inc(pointer(cPixel), incr);
            end;
         end;

         {swap red and blue channels}
         imgccRB: begin
            for i := 0 to (image.Pixels-1) do begin
               cPixel^[2] := cPixel^[2] xor cPixel^[0];
               cPixel^[0] := cPixel^[2] xor cPixel^[0];
               cPixel^[2] := cPixel^[2] xor cPixel^[0];

               inc(pointer(cPixel), incr);
            end;
         end;

         {swap green and blue channels}
         imgccGB: begin
            for i := 0 to (image.Pixels-1) do begin
               cPixel^[1] := cPixel^[1] xor cPixel^[2];
               cPixel^[2] := cPixel^[1] xor cPixel^[2];
               cPixel^[1] := cPixel^[1] xor cPixel^[2];

               inc(pointer(cPixel), incr);
            end;
         end;
      end;

      Result := true;
   end;
end;

procedure imgTOperations.InvertColors(var image: imgTImage);
var
   i,
   Incr: longint;
   cPixel: PColor4ub;

begin
   if(image.Image <> nil) then begin
      {unsupported format}
      if(img.PIXFDepth(image.PixF) mod 8 <> 0) then
         exit;

      incr := img.PIXFIncrementBytes(image.PixF);

      cPixel := pointer(image.Image);

      if(image.PixelDepth div 8 >= 3) then begin
         {invert the colors in the image}
         for i := 0 to (image.Pixels-1) do begin
            cPixel^[0] := 255 - cPixel^[0];
            cPixel^[1] := 255 - cPixel^[1];
            cPixel^[2] := 255 - cPixel^[2];

            inc(pointer(cPixel), Incr);
         end;
      end else if(image.PixelDepth div 8 = 1) then begin
         {invert the colors in the image}
         for i := 0 to (image.Pixels - 1) do begin
            cPixel^[0] := 255 - cPixel^[0];

            inc(pointer(cPixel), Incr);
         end;
      end;
   end;
end;

procedure imgTOperations.AlphaZero(var image: imgTImage);
var
   i: loopint;
   cPixel: PColor4ub;

begin
   if(image.Image <> nil) then begin
      {check if the image is of a supported pixel format}
      if(image.PixF <> PIXF_BGRA) and (image.PixF <> PIXF_RGBA) then
         {unsupported format}
         exit;

      cPixel := pointer(image.Image);

      {invert the colors in the image}
      for i := 0 to (image.Pixels - 1) do begin
         if(cPixel^[0] + cPixel^[1] + cPixel^[2] <> 0) then
            cPixel^[3] := 255
         else
            cPixel^[3] := 0;

         inc(pointer(cPixel), 4);
      end;
   end;
end;

procedure imgTOperations.AlphaFromAverage(var image: imgTImage);
var
   i: loopint;
   cPixel: PColor4ub;

begin
   if(image.Image <> nil) then begin
      {check if the image is of a supported pixel format}
      if(image.PixF <> PIXF_BGRA) and (image.PixF <> PIXF_RGBA) then
         {unsupported format}
         exit;

      cPixel := pointer(image.Image);

      {invert the colors in the image}
      for i := 0 to (image.Pixels - 1) do begin
         cPixel^[3] := (cPixel^[0] + cPixel^[1] + cPixel^[2]) div 3;

         inc(pointer(cPixel), 4);
      end;
   end;
end;

procedure imgTOperations.AlphaFromInverseAverage(var image: imgTImage);
var
   i: loopint;
   cPixel: PColor4ub;

begin
   if(image.Image <> nil) then begin
      {check if the image is of a supported pixel format}
      if(image.PixF <> PIXF_BGRA) and (image.PixF <> PIXF_RGBA) then
         {unsupported format}
         exit;

      cPixel := pointer(image.Image);

      {invert the colors in the image}
      for i := 0 to (image.Pixels - 1) do begin
         cPixel^[3] := 255 - ((cPixel^[0] + cPixel^[1] + cPixel^[2]) div 3);

         inc(pointer(cPixel), 4);
      end;
   end;
end;

procedure imgTOperations.MaxPixelValues(var image: imgTImage);
var
   i, j: loopint;
   cPixel: PColor4ub;
   increment: loopint;

begin
   if(image.Image <> nil) then begin
      {unsupported format}
      if(not image.HasAlpha()) then
         exit;

      increment := img.PIXFIncrementBytes(image.PixF);

      {unsupported format}
      if(image.PixelDepth mod 8 <> 0) or ((increment <> 3) and (increment <> 4)) then
         exit;

      cPixel := pointer(image.Image);

      {invert the colors in the image}
      for j := 0 to (image.Height - 1) do begin
         for i := 0 to (image.Width - 1) do begin
            if(cPixel^[0] <> 0) or (cPixel^[1] <> 0) or (cPixel^[2] <> 0) then begin
               cPixel^[0] := 255;
               cPixel^[1] := 255;
               cPixel^[2] := 255;
            end;

            inc(pointer(cPixel), 4);
         end;

         inc(Pointer(cPixel), image.RowAlignBytes);
      end;
   end;
end;

procedure imgTOperations.SetOrigin(var image: imgTImage; target: longint);
var
   target_vertical,
   target_horizontal: boolean;

   image_vertical,
   image_horizontal: boolean;

begin
   if(image.Origin <> target) then begin
      {get the origin settings}
      target_vertical   := target and imgcBT_ORIGIN_VERTICAL > 0;
      target_horizontal := target and imgcBT_ORIGIN_HORIZONTAL > 0;
      image_vertical    := image.Origin and imgcBT_ORIGIN_VERTICAL > 0;
      image_horizontal  := image.Origin and imgcBT_ORIGIN_HORIZONTAL > 0;

      {flip the image if origins are different}
      if(target_vertical <> image_vertical) then
         FlipV(image);

      if(target_horizontal <> image_horizontal) then
         FlipH(image);

      image.Origin := target;
   end;
end;

{sets the image to the default origin, based on what it's origin is now}
procedure imgTOperations.SetDefaultOrigin(var image: imgTImage);
begin
   SetOrigin(image, imgcORIGIN_DEFAULT);
end;

{set default colors}
procedure imgTOperations.SetDefaultPixelFormat(var image: imgTImage);
begin
   if(not img.PIXFHasAlpha(image.PixF)) then
      Transform(image, img.settings.defaultPixelFormat)
   else
      Transform(image, img.settings.defaultPixelFormatAlpha);
end;

{set the image to the default color channel order}
procedure imgTOperations.SetDefaultColorChannelOrder(var image: imgTImage);
var
   cco: longint;

begin
   {get the color channel order of iamge and exit if same as default}
   cco := img.PIXFColorChannelOrder(image.PixF);
   if(cco = img.settings.defaultColorChannelOrder) then
      exit;

   if(SwapColorChannels(image, imgccRB)) then begin
      case image.PixF of
         {RGB}
         PIXF_INDEX_RGB_4:
            image.PixF := PIXF_INDEX_BGR_4;
         PIXF_INDEX_RGB_8:
            image.PixF := PIXF_INDEX_BGR_8;
         PIXF_RGB:
            image.PixF := PIXF_BGR;
         PIXF_RGBA:
            image.PixF := PIXF_BGRA;
         PIXF_ARGB:
            image.PixF := PIXF_ABGR;

         {BGR}
         PIXF_INDEX_BGR_4:
            image.PixF := PIXF_INDEX_RGB_4;
         PIXF_INDEX_BGR_8:
            image.PixF := PIXF_INDEX_RGB_8;
         PIXF_BGR:
            image.PixF := PIXF_RGB;
         PIXF_BGRA:
            image.PixF := PIXF_RGBA;
         PIXF_ABGR:
            image.PixF := PIXF_ARGB;
      end;
   end;
end;

function imgTOperations.Fill(var image: imgTImage; c: qword): longint;
begin
   Result := Fill(image, 0, 0, image.width, image.height, c);
end;

function imgTOperations.Fill(var image: imgTImage; x, y, w, h: longint; c: qword): longint;
var
   psize,
   i,
   algn,
   len,
   srcrowlen: longint;

   p,
   s,
   line: pbyte;

begin
   if(img.Valid(image)) then begin
      if(w > 0) and (h > 0) then begin
         {get pixel depth}
         psize := img.PIXFDepth(image.PixF);

         if(psize mod 8 = 0) then begin
            psize := psize div 8; {get pixel size in bytes}
            len   := psize * w; {figure out how many bytes to copy at a time}

            {check that the position does not go out of the boundaries}
            if(x + w > image.Width) then
               exit(eINVALID_ARG)
            else if(y + h > image.Height) then
               exit(eINVALID_ARG);

            {calculate row lengths in bytes}
            srcrowlen := (image.Width * psize) + image.RowAlignBytes;

            {position at image}
            algn:= image.RowAlignBytes * y;
            {$PUSH}{$HINTS OFF}
            p := pbyte((y * image.Width + x) * psize + algn);
            s := image.Image + ptruint(p);
            {$POP}

            {create a filled out line}
            line := nil;

            getmem(line, len);
            if(line = nil) then
               exit(eNO_MEMORY);

            for i := 0 to w - 1 do begin
               Move(c, (line + i * psize)^, psize);
            end;

            {fill rows one at a time}
            for i := 0 to (h - 1) do begin
               Move(line^, s^, len);

               {move to next row}
               inc(s, srcrowlen);
            end;

            Freemem(line);
         end else
            exit(eUNSUPPORTED);
      end else
         exit(eUNSUPPORTED);
   end else
      exit(eINVALID);

   Result := eNONE;
end;

INITIALIZATION
   imgOperations.UseWeightedAverage := true;

END.
