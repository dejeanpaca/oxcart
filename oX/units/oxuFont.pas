{
  oxuFont, common oX constants
  Copyright (c) 2011. Dejan Boras

  Started On:    17.02.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuFont;

INTERFACE

   USES
      uStd, StringUtils, vmVector, uColors, uFile,
      {oX}
      uOX, oxuRunRoutines, oxuProjection, oxuTypes,
      oxuTexture, oxuTextureGenerate, oxuPaths, oxuTFD, oxuRender, oxuPrimitives,
      oxuResourcePool, oxuMaterial, oxuTransform, oxuRenderer;

TYPE
   oxTFontBuffer = record
      t: array of TVector2f;

      Built: boolean;
   end;

   oxTFontCharacter = record
      Width,
      Height,
      BearingX,
      BearingY,
      Advance: longint;
   end;

   oxTFontProperties = (
      oxfpBreak,
      oxfpMultiline,
      oxfpCenterHorizontal,
      oxfpCenterVertical,
      oxfpCenterHorizontalTotal,
      oxfpCenterLeft,
      oxfpCenterRight,
      oxfpCenterTop,
      oxfpCenterBottom
   );

   oxTFontPropertiesSet = set of oxTFontProperties;

   { oxTFont }

   oxTFont = class
      public

      Texture: oxTTexture;
      {characters are on a baseline on the texture}
      TextureBaseline,
      {is the font monospace}
      Monospace: boolean;
      {file name}
      fn: StdString;

      Width, {width}
      Height, {height}
      VerticalSpacing, {vertical spacing}
      HorizontalSpacing, {horizontal spacing}
      Base, {base character index}
      Chars, {character count}
      CPLine, {characters per line}
      Lines: longint; {number of lines}

      {scaling}
      vScale: TVector2f;

      {texture name}
      TexName: StdString;
      {buffers}
      Buf: oxTFontBuffer;

      {list of character widths and heights}
      Characters: array of oxTFontCharacter;
      {maximum bearing}
      MaxBearingY: longint;

      constructor Create();
      destructor Destroy(); override;

      procedure AllocateChars(initialize: boolean = true);

      {builds font buffers (character triangles)}
      function FirstBuild(): longint;
      function Build(): longint;
      {dispose a font}
      procedure Dispose();

      {prepare for font writing and use the specified font}
      procedure Start();

      {cache a string into buffers}
      function Cache(const s: StdString; out v: TVector3f; out t: TVector2f; out indices: Word;
        out actualLength: loopint; maxlen: longint = 0): boolean;

      {write text using a font}
      procedure Write(x, y: single; const s: StdString);
      procedure WriteCentered(const s: StdString; const r: oxTRect);
      procedure WriteCentered(const s: StdString; const r: oxTRect; props: oxTFontPropertiesSet);
      procedure WriteCenteredCxt(const s: StdString; props: oxTFontPropertiesSet);
      procedure WriteCenteredScaled(const s: StdString; const r: oxTRect; sx, sy: single);
      procedure WriteCenteredScaledCxt(const s: StdString; sx, sy: single);
      procedure WriteInRect(const txt: StdString; const r: oxTRect; breakChars: boolean = true; multiline: boolean = true);
      procedure WriteInRect(const txt: StdString; const r: oxTRect; props: oxTFontPropertiesSet);

      {scale a font}
      procedure Scale(x, y: single);

      {select this font}
      procedure Select();

      {dimensions}
      function GetHeight(): longint;
      function GetHeight(c: longint): longint;
      function GetWidth(): longint;
      function GetWidth(c: longint): longint;
      function GetLength(const s: StdString): longint;

      {get length of a multiline string}
      function GetMultilineLength(const txt: StdString): loopint;

      {assigns a TFD to a font}
      procedure Assign(const tfd: oxTTFD);

      {checks if the font is valid}
      function Valid(): boolean;
   end;

   { oxTFontGlobal }

   oxTFontGlobal = record
      {this indicates whether vertically flipped texture coordinates should be generated}
      FlippedGen,
      {writes text flipped upside down}
      WriteUpsideDown: boolean;

      {filter used for generating font textures}
      Filter: oxTTextureFilter;

      Default: oxTFont;
      Selected: oxTFont;
      NilFont: oxTFont;

      {load a font from TFD file}
      function Load(var f: oxTFont; const fn: StdString): longint;
      {load file with a specific tfd and file}
      function Load(var f: oxTFont; var tfd: oxTTFD; const extension: StdString; var textureFile: TFile): longint;

      {prepare for font writing}
      procedure Start();
      {perform steps to restore state after font writing}
      procedure Stop();

      {get default font}
      function GetDefault(): oxTFont;
      {get default font if the specified one is nil}
      procedure GetNilDefault(var f: oxTFont);
      procedure SetDefault(var f: oxTFont);

      {font selection}
      procedure Select(var f: oxTFont);
      function GetSelected(): oxTFont;
   end;

CONST
   oxfpInRectDefaultProperties = [oxfpBreak, oxfpMultiline];
   oxfpCenterHV = [oxfpCenterHorizontal, oxfpCenterVertical];

VAR
   oxFont: oxTFontGlobal;
   oxf: oxTFontGlobal absolute oxFont;

IMPLEMENTATION

constructor oxTFont.Create();
begin
   Monospace := true;

   Chars   := 256;
   Width   := 8;
   Height  := 8;

   vScale[0] := 1.0;
   vScale[1] := 1.0;
end;

destructor oxTFont.Destroy();
begin
   inherited;

   Dispose();
end;

procedure oxTFont.AllocateChars(initialize: boolean);
begin
   SetLength(Characters, Chars);

   if(initialize) then
      ZeroOut(Characters[0], SizeOf(Characters[0]) * int64(Chars));
end;

function oxTFont.FirstBuild(): longint;
begin
   {build the font}
   Result := Build();

   if(oxf.Default = nil) then
      oxf.SetDefault(self);
end;

function oxTFont.Build(): longint;
var
   pelx,
   pely,
   cx,
   cy,
   px,
   py,
   currentPY: single;

   ch: longint = 0;
   cht: longint;

   currentX,
   currentWidth,
   currentHeight: longint;

   i,
   j: longint;

   done: boolean = false;

begin
   if(Texture = nil) then
      exit;

   { ALLOCATIONS }

   {allocate memory for texture coordinates}
   try
      SetLength(Buf.t, Chars * 4);
   except
      exit(eNO_MEMORY);
   end;

   { CALCULATIONS }

   {figure out a pel (pixel) size}
   pelx := 1.0 / Texture.Width;
   pely := 1.0 / Texture.Height;

   {determine horizontal and vertical grid piece sizes}
   px := pelx * Width;
   py := pely * Height;

   cy := 1.0;

   currentWidth := Width;
   currentHeight := Height;
   currentPY := py;

   if(Characters <> nil) then
      for i := 0 to (Chars - 1) do begin
         if(Characters[i].BearingY > MaxBearingY) then
            MaxBearingY := Characters[i].BearingY;
      end;

   {go through all Lines}
   for i := 0 to (Lines - 1) do begin
      {go back to horizontal start of texture}
      cx := 0.0;
      currentX := 0;

      {go through characters on a line}
      j := 0;
      repeat
         if(Characters <> nil) then begin
            currentWidth := Characters[ch].Width;
            currentHeight := Characters[ch].Height;

            px := pelx * currentWidth;
            currentPY := pely * currentHeight;

            if(currentX + currentWidth >= Texture.Width) then
               break
            else
               inc(currentX, currentWidth);
         end;

         {get starting coordinates index for current char.}
         cht := ch * 4;

         {build texture coordinates}
         if(not oxFont.flippedGen) then {normal texture coordinates}
            oxPrimitives.GetQuadTextureCoords(cx, cy, px, currentPY, @Buf.t[cht])
         else {vertically flipped texture coordinates}
            oxPrimitives.GetQuadTextureCoordsFlipped(cx, cy, px, currentPY, @Buf.t[cht]);

         {go to next character}
         cx := cx + px;
         inc(ch);

         {if processed all characters then quit}
          if(ch >= Chars) then begin
             done := true;
             break;
          end;

         inc(j);
      until (j >= CPLine) and (CPLine <> 0);

      {quit if done building}
      if(done) then
         break;

      cx := 0.0;
      cy := cy - py;
   end;

   Buf.Built := true;
end;

procedure oxTFont.Dispose();
begin
   oxResource.Destroy(Texture);

   SetLength(Buf.t, 0);
end;

procedure oxTFont.Start();
begin
   Select();

   if(Valid()) then begin
      oxTransform.Identity();

      oxRender.BlendFunction(oxBLEND_ALPHA);
      oxRender.DepthTest(oxTEST_FUNCTION_NONE);
      oxRender.DisableNormals();
      oxRender.DisableColor();
      oxRender.CullFace(oxCULL_FACE_BACK);

      if(oxCurrentMaterial <> nil) then
         oxCurrentMaterial.ApplyTexture('texture', Texture);

      oxRender.TextureCoords(Buf.t[0]);

      if(oxFont.writeUpsideDown) then
         oxTransform.Rotate(180.0, 1.0, 0.0, 0.0);

      oxTransform.Apply();
   end;
end;

function oxTFont.Cache(const s: StdString; out v: TVector3f; out t: TVector2f; out indices: Word;
  out actualLength: loopint; maxlen: longint = 0): boolean;
var
   {length of string}
   len,
   {current character}
   i,
   {current computed index into vectors or texture coordinates}
   index,
   {current character index}
   charIndex,
   {current length of string (we may skip some characters), to be stored into actualLength}
   currentLength: loopint;


   pVector: PVector3f;
   pTexture: PVector2f;
   pIndice: PWord;

   px,
   py: single;
   b: byte;

   currentWidth,
   currentHeight: single;

begin
   Result := false;
   actualLength := 0;
   indices := 0;

   if(Valid()) then begin
      len := Length(s);

      {don't overflow our buffers}
      if(maxlen > 0) and (len > maxlen) then
         len := Length(v) div 4;

      if(len > 0) then begin
         px := 0;
         i := 1;

         if(MaxBearingY = 0) then
            py := 0
         else
            py := (Height - MaxBearingY);

         currentWidth := Width;
         currentHeight := Height;

         pVector := @v;
         pTexture := @t;
         pIndice := @indices;
         currentLength := 0;

         while(i <= len) do begin
            b := ord(s[i]);

            charIndex := currentLength;

            if(b >= Base) and (b < Base + Chars) then begin
               inc(currentLength);
               b := b - Base;

               if(Characters <> nil) then begin
                  currentWidth := Characters[b].Width;
                  currentHeight := Characters[b].Height;

                  if(Characters[b].BearingX <> 0) or (Characters[b].BearingY <> 0) then begin
                     px := px + Characters[b].BearingX;
                     py := py - (Characters[b].Height - Characters[b].BearingY);
                  end;
               end;

               {build quad coordinates}
               index := charIndex * 4 + 0;

               pVector[index][0] := px;
               pVector[index][1] := py;
               pVector[index][2] := 0.0;

               index := charIndex * 4 + 1;

               pVector[index][0] := px + currentWidth;
               pVector[index][1] := py;
               pVector[index][2] := 0.0;

               index := charIndex * 4 + 2;

               pVector[index][0] := px + currentWidth;
               pVector[index][1] := py + currentHeight;
               pVector[index][2] := 0.0;

               index := charIndex * 4 + 3;

               pVector[index][0] := px;
               pVector[index][1] := py + currentHeight;
               pVector[index][2] := 0.0;

               {build texture coordinates}
               index := charIndex * 4;
               pTexture[index + 0] := Buf.t[b * 4 + 0];
               pTexture[index + 1] := Buf.t[b * 4 + 1];
               pTexture[index + 2] := Buf.t[b * 4 + 2];
               pTexture[index + 3] := Buf.t[b * 4 + 3];

               {build indices}
               index := charIndex * 6;

               pIndice[index + 0] := charIndex * 4 + QuadIndicesus[0];
               pIndice[index + 1] := charIndex * 4 + QuadIndicesus[1];
               pIndice[index + 2] := charIndex * 4 + QuadIndicesus[2];
               pIndice[index + 3] := charIndex * 4 + QuadIndicesus[3];
               pIndice[index + 4] := charIndex * 4 + QuadIndicesus[4];
               pIndice[index + 5] := charIndex * 4 + QuadIndicesus[5];

               if(Characters <> nil) then begin
                  px := px + Characters[b].Advance;
                  {restore y back on baseline}
                  py := py + (Characters[b].Height - Characters[b].BearingY);
               end else
                  px := px + Width;
            end;

            inc(i);
         end;

         actualLength := currentLength;

         Result := true;
      end;
   end;
end;

procedure oxTFont.Write(x, y: single; const s: StdString);
var
   len,
   cachedLength: loopint;
   px,
   py: single;

   v: array[0..16383] of TVector3f;
   indices: array[0..24575] of Word;
   t: array[0..16383] of TVector2f;

   m: TMatrix4f;

begin
   if(Valid()) then begin
      m := oxTransform.Matrix;
      len := Length(s);

      {don't overflow our buffers}
      if(len * 4 > Length(v)) then
         len := Length(v) div 4;

      if(len > 0) then begin
         cachedLength := len;

         if(not Cache(s, v[0], t[0], indices[0], cachedLength)) then
            exit;

         if(cachedLength = 0) then
            exit;

         if(not oxFont.writeUpsideDown) then
            py := y / vScale[1]
         else
            py := -((y + Height) / vScale[1]);

         px := x / vScale[0];

         oxTransform.Translate(px, py, 0.0);
         oxTransform.Apply();

         oxCurrentMaterial.ApplyTexture('texture', Texture);
         oxRender.TextureCoords(t[0]);
         oxRender.Vertex(v[0]);
         oxRender.Primitives(oxPRIMITIVE_TRIANGLES, 6 * cachedLength, pword(@indices[0]));

         {return to origin}
         oxTransform.Apply(m);
      end;
   end;
end;

procedure oxTFont.WriteCentered(const s: StdString; const r: oxTRect);
begin
   WriteCentered(s, r, oxfpCenterHV);
end;

procedure oxTFont.WriteCentered(const s: StdString; const r: oxTRect; props: oxTFontPropertiesSet);
var
   h, x, y, len: loopint;

begin
   {get the font height and calculate center position}
   h := GetHeight();
   len := GetLength(s);

   if(oxfpCenterVertical in props) then
      y := r.h div 2 - Height div 2
   else if(oxfpCenterTop in props) then
      y := r.h - round(h - vScale[1])
   else
      y := 0;

   if(oxfpCenterHorizontal in props) then
      x := (r.w - round(len * vScale[0])) div 2
   else if(oxfpCenterRight in props) then
      x := (r.w - round(len * vScale[0]))
   else
      x := 0;

   Write(r.x + x, r.y - r.h + 1 + y, s);
end;

procedure oxTFont.WriteCenteredCxt(const s: StdString; props: oxTFontPropertiesSet);
var
   rect: oxTRect;

begin
   rect.x := 0;
   rect.y := oxProjection^.Dimensions.h - 1;
   rect.w := oxProjection^.Dimensions.w;
   rect.h := oxProjection^.Dimensions.h;

   WriteCentered(s, rect, props);
end;

procedure oxTFont.WriteCenteredScaled(const s: StdString; const r: oxTRect; sx, sy: single);
var
   x, y, w, h: single;

begin
   w := (GetWidth() / 2) * sx;
   h := (GetHeight() / 2) * sy;

   x := (r.w / 2) - (w * Length(s));
   y := (r.h / 2) + (h);

   Scale(sx, sy);
   Write(r.x + x, r.y - y, s);
   Scale(1.0, 1.0);
end;

procedure oxTFont.WriteCenteredScaledCxt(const s: StdString; sx, sy: single);
var
   rect: oxTRect;

begin
   rect.x := 0;
   rect.y := oxProjection^.Dimensions.h - 1;
   rect.w := oxProjection^.Dimensions.w;
   rect.h := oxProjection^.Dimensions.h;

   WriteCenteredScaled(s, rect, sx, sy);
   Scale(1.0, 1.0);
end;

procedure oxTFont.WriteInRect(const txt: StdString; const r: oxTRect; breakChars: boolean; multiline: boolean);
var
   props: oxTFontPropertiesSet;

begin
   props := [];

   if(breakChars) then
      Include(props, oxfpBreak);

   if(multiline) then
      Include(props, oxfpMultiline);

   WriteInRect(txt, r, props);
end;

procedure oxTFont.WriteInRect(const txt: StdString; const r: oxTRect; props: oxTFontPropertiesSet);
var
   s: StdString;
   {width, txt length, i, start, char length, y position}
   tempSize,
   i,
   w,
   l,
   ss,
   len,
   y,
   lastBreak,
   totalHeight,
   totalWidth,
   currentWidth,
   stringCount: loopint;

   breakChars,
   multiline,
   centerHorizontal,
   centerVertical: boolean;

   strings: array[0..1023] of StdString;

begin
   l := Length(txt);
   i := 1;
   lastBreak := 1;

   breakChars := oxfpBreak in props;
   multiline := oxfpMultiline in props;
   centerHorizontal := (oxfpCenterHorizontal in props) or (oxfpCenterHorizontalTotal in props);
   centerVertical := oxfpCenterVertical in props;

   totalWidth := 0;
   totalHeight := 0;
   stringCount := 0;

   strings[0] := '';

   if(txt <> '') then repeat
      w := 0;
      ss := i;

      while(i <= l) do begin
         len := round(GetWidth(longint(txt[i])) * vScale[0]);
         lastBreak := i;

         if(breakChars and (txt[i] in [' ', ',', '.', '?', '!', ':', ';'])) then
            lastBreak := i;

         if((txt[i] = #13) or (txt[i] = #10)) and (multiline) then begin
            lastBreak := i;
            break;
         end;

         if(w + len <= r.w) then
            {add the total length or break}
            w := w + len
         else begin
            {we can't fit current character without overflowing}
            dec(i);
            lastBreak := i;

            {we can't fit anything, so no point in continuing}
            if(i = 0) then
               exit;

            break;
         end;

         inc(i);
      end;

      if(i >= l) then
         lastBreak := l;

      if(not multiline) or ((txt[lastBreak] <> #13) and (txt[lastBreak] <> #10)) then
         s := Copy(txt, ss, (lastBreak - ss) + 1)
      else
         s := Copy(txt, ss, (lastBreak - ss));

      strings[stringCount] := s;
      inc(stringCount);

      i := lastBreak + 1;

      {skip crlf completely}
      if((multiline) and (i < l) and (txt[i] = #13) and (txt[i + 1] = #10)) then
         inc(i);

      if(oxfpCenterHorizontalTotal in props) then begin
         tempSize := GetLength(s);

         if(tempSize > totalWidth) then
            totalWidth := tempSize;
      end;

      inc(totalHeight, GetHeight());
   until (i >= l) or (totalHeight > r.h);

   y := r.y - GetHeight();
   if(centerVertical) then
      y := r.y - ((r.h div 2) - totalHeight div 2);

   for i := 0 to stringCount - 1 do begin;
      s := strings[i];

      if(s <> '') then begin
         if(not centerHorizontal) then
            Write(r.x, y, s)
         else begin
            if(oxfpCenterHorizontalTotal in props) then
               currentWidth := totalWidth
            else
               currentWidth := GetLength(s);

            Write(r.x + ((r.w div 2) - currentWidth div 2) , y, s)
         end;
      end;

      dec(y, GetHeight());
   end;
end;

procedure oxTFont.Scale(x, y: single);
begin
   oxTransform.Identity();
   vScale[0] := x;
   vScale[1] := y;
   oxTransform.Scale(x, y, 1.0);
   oxTransform.Apply();
end;

procedure oxTFont.Select();
begin
   oxFont.Selected := self;
end;

{dimensions}
function oxTFont.GetHeight(): longint;
begin
   Result := Height;
end;

function oxTFont.GetHeight(c: longint): longint;
begin
   if(Characters <> nil) then begin
      if(c >= Base) and (c < Base + Chars) then
         Result := Characters[c - Base].Height
      else
         Result := Height;
   end else
      Result := Height;
end;

function oxTFont.GetWidth(): longint;
begin
   Result := Width;
end;

function oxTFont.GetWidth(c: longint): longint;
begin
   if(Characters <> nil) then begin
      if(c >= Base) and (c < Base + Chars) then
         Result := Characters[c - Base].BearingX + Characters[c - Base].Advance
      else
         Result := Width;
   end else
      Result := Width;
end;

function oxTFont.GetLength(const s: StdString): longint;
var
   i,
   l: loopint;

begin
   if(Characters = nil) then
      Result := Length(s) * Width
   else begin
      l := Length(s);

      Result := 0;

      for i := 1 to l do begin
         inc(Result, GetWidth(ord(s[i])));
      end;
   end;
end;

function oxTFont.GetMultilineLength(const txt: StdString): loopint;
var
   s: TStringArray;
   i,
   strLen: loopint;
   l: loopint = 0;

begin
   s := strExplode(txt, #10);

   for i := 0 to (Length(s) - 1) do begin
      strLen := GetLength(s[i]);

      if(strLen > l) then
         l := strLen;
   end;

   Result := l;
end;

procedure oxTFont.Assign(const tfd: oxTTFD);
begin
   {assign attributes}
   Width        := tfd.Width;
   Height        := tfd.Height;
   HorizontalSpacing        := tfd.SpaceX;
   VerticalSpacing        := tfd.SpaceY;
   Base      := tfd.Base;
   Chars     := tfd.Chars;
   CPLine    := tfd.CPLine;
   Lines     := tfd.Lines;

   texname   := tfd.TextureName;
end;

function oxTFont.Valid(): boolean;
begin
   Result := oxTex.ValidId(Texture) and Buf.Built;
end;

{ oxTFontGlobal }

function oxTFontGlobal.Load(var f: oxTFont; const fn: StdString): longint;
var
   tfd: oxTTFD;
   tfn: StdString;
   errCode: longint;
   gen: oxTTextureGenerate;

begin
   Result := eNONE;
   oxTTextureGenerate.Init(gen);

   if(f <> nil) then
      FreeObject(f);

   f := oxTFont.Create();
   f.fn := fn;

   oxTFD.Init(tfd);

   f.fn := oxPaths.Find(f.fn);

   errCode := oxTFD.Load(tfd, f.fn);
   if(errCode = 0) then begin
      f.Assign(tfd);

      {try to load the texture}
      tfn := ExtractFilePath(f.fn) + tfd.TextureName;
      gen.Filter := oxFont.Filter;

      errCode := gen.Generate(tfn, f.Texture);
      if(errCode = 0) then begin
         f.Texture.MarkUsed();
         f.FirstBuild();
      end;
   end;

   gen.Dispose();

   Result := errCode;
end;

function oxTFontGlobal.Load(var f: oxTFont; var tfd: oxTTFD; const extension: StdString; var textureFile: TFile): longint;
var
   errCode: longint;
   gen: oxTTextureGenerate;

begin
   Result := eNONE;
   oxTTextureGenerate.Init(gen);

   if(f <> nil) then
      FreeObject(f);

   f := oxTFont.Create();

   f.Assign(tfd);

   {try to load the texture}
   gen.Filter := oxFont.Filter;

   errCode := gen.Generate(extension, textureFile, f.Texture);
   if(errCode = 0) then
      f.FirstBuild();

   gen.Dispose();

   Result := errCode;
end;


procedure oxTFontGlobal.Start();
begin
   if(Selected <> nil) then
      Selected.Start();
end;

procedure oxTFontGlobal.Stop();
begin
   oxRender.DisableBlend();
   oxCurrentMaterial.ApplyTexture('texture', nil);

   oxTransform.Identity();
end;

{get default font}
function oxTFontGlobal.GetDefault(): oxTFont;
begin
   Result := default;
end;

procedure oxTFontGlobal.GetNilDefault(var f: oxTFont);
begin
   if(f = nil) then
      f := GetDefault();
end;

procedure oxTFontGlobal.SetDefault(var f: oxTFont);
begin
   if(f <> nil) then
      Default := f;
end;

{font selection}
procedure oxTFontGlobal.Select(var f: oxTFont);
begin
   if(f <> nil) then
      f.Select();
end;

function oxTFontGlobal.GetSelected(): oxTFont;
begin
   if(Selected = nil) then
      Select(Default);

   Result := Selected;
end;

procedure init();
begin
   oxFont.NilFont := oxTFont.Create();
end;

procedure deinit();
begin
   FreeObject(oxFont.NilFont);
   oxf.Default := nil;
end;

VAR
   initRoutines: oxTRunRoutine;

INITIALIZATION
   ox.Init.Add(initRoutines, 'ox.font', @init, @deinit);

   {this indicates whether vertically flipped texture coordinates should be generated}
   oxFont.FlippedGen := false;
   oxFont.WriteUpsideDown := false;

   oxFont.Filter := oxTEXTURE_FILTER_NONE;

END.

