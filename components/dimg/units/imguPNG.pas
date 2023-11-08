{
   imguPNG, PNG image loader for dImage
   Copyright (C) 2007. Dejan Boras

   Started On:    13.11.2007.
}

{$INCLUDE oxdefines.inc}
UNIT imguPNG;

INTERFACE

   USES
      uStd, uImage, StringUtils,
      uFileHandlers, imguRW,
      paszlib, ZInflate,
      {ox}
      uOX, oxuFile;

IMPLEMENTATION

CONST
   pngcSignature: packed array[0..7] of byte = (137, 80, 78, 71, 13, 10, 26, 10);

   {chunk bit-masks}
   (*
   pngcANCILLARY  = $10000000;
   pngcPRIVATE    = $00100000;
   pngcRESERVED   = $00001000;
   pngcSAFECOPY   = $00000010;
   *)

TYPE
   pngTChunkID = packed array[0..3] of char;

CONST
   {chunk IDs, Note that these must be ASCII or else they won't match.}
   pngcIHDR: pngTChunkID   = 'IHDR';
   //pngccHRM: pngTChunkID = 'cHRM';
   //pngcgAMA: pngTChunkID = 'gAMA';
   //pngcsBIT: pngTChunkID = 'sBIT';
   //pngcPLTE: pngTChunkID = 'PLTE';
   //pngcbKGD: pngTChunkID = 'bKGD';
   //pngchIST: pngTChunkID = 'hIST';
   //pngctRNS: pngTChunkID = 'tRNS';
   //pngcoFFs: pngTChunkID = 'oFFs';
   pngcpHYs: pngTChunkID   = 'pHYs';
   pngcIDAT: pngTChunkID   = 'IDAT';
   //pngctIME: pngTChunkID = 'tIME';
   //pngcsCAL: pngTChunkID = 'sCAL';
   //pngctEXt: pngTChunkID = 'tEXt';
   //pngczTXt: pngTChunkID = 'zTXt';
   pngcIEND: pngTChunkID   = 'IEND';
   //pngcsRGB: pngTChunkID = 'sRGB';
   //pngciCCP: pngTChunkID = 'iCCP';
   //pngciTXt: pngTChunkID = 'sPLT';
   //pngcUnkn: pngTChunkID = 'Unkn';

   pngcFILTER_SUB          = 0001;
   pngcFILTER_UP           = 0002;
   pngcFILTER_AVERAGE      = 0003;
   pngcFILTER_PAETH        = 0004;

   //pngcCLR_GRAYSCALE       = 0000;
   pngcCLR_RGB             = 0002;
   //pngcCLR_PALETTE         = 0003;
   //pngcCLR_GRAYSCALEALPHA  = 0004;
   pngcCLR_RGBA            = 0006;

TYPE
   {this is the first part of the chunk,
   additionaly each chunk also contains data and the CRC}
   pngfTChunkHeader = packed record
      length: longword;
      typ: pngTChunkID;
   end;

   pngfTIHDR = packed record
      Width,
      Height: longword;

      BitDepth,
      ColorType,
      CompressionMethod,
      FilterMethod,
      InterlaceFilter: byte;

      crc: longword;
   end;

   TPNGLoaderData = record
      chunk: pngfTChunkHeader;
      HDR: pngfTIHDR;
      nIDAT: longint;

      bpp: longint;
      fzStream: TZStream;
      fzImagePosition: int64;

      fIDATEnd: fileint;
      pngBuffer: pbyte;
      zBuffer: pbyte;
   end;

   pngfTphYs = packed record
      ppux, ppuy: longint;
      unitSpec: byte;
      crc: longword;
   end;

VAR
   ext: fhTExtension;
   loader: fhTHandler;

{read the chunk header}
procedure pngReadChunkHeader(var ld: imgTFileData; var data: TPNGLoaderData);
begin
   ld.BlockRead(data.chunk, SizeOf(data.chunk));
   if(ld.GetError() = 0) then begin
      {$IFDEF ENDIAN_LITTLE}
      data.chunk.length := BEtoN(data.chunk.length);
      {$ENDIF}
   end;
end;

procedure skipCRC(var ld: imgTFileData);
var
   CRC: longword;

begin
   ld.BlockRead(CRC, SizeOf(CRC));
end;

procedure skipChunk(var ld: imgTFileData; var data: TPNGLoaderData);
begin
   ld.Seek(ld.PFile^.f^.fPosition + data.chunk.length + 4);
end;

procedure loadIHDR(var ld: imgTFileData; var img: imgTImage; var data: TPNGLoaderData);
begin
   {read the IHDR chunk}
   pngReadChunkHeader(ld, data);
   if(ld.GetError() = 0) then begin
      if(data.chunk.typ <> pngcIHDR) then begin
         ld.SetError(eINVALID);
         exit;
      end;
   end else
      exit;

   ld.BlockRead(data.HDR, sizeof(pngfTIHDR));
   if(ld.GetError() = 0) then begin
      {assign and calculate}
      img.Width   := BEtoN(data.HDR.Width);
      img.Height  := BEtoN(data.HDR.Height);

      {check the bit depth}
      if(data.HDR.BitDepth <> 8) then begin
         ld.SetError(eUNSUPPORTED);
         exit;
      end;

      img.Origin  := imgcORIGIN_TL;

      {check the color type}
      if(data.HDR.ColorType = pngcCLR_RGB) then begin
         img.PixF          := PIXF_RGB;
         img.PixelDepth    := 24;
         img.RowSize       := img.Width * 3;
         data.bpp          := 3;
      end else if (data.HDR.ColorType = pngcCLR_RGBA) then begin
         img.PixF          := PIXF_RGBA;
         img.PixelDepth    := 32;
         img.RowSize       := img.Width * 4;
         data.bpp          := 4;
      end else begin
         ld.SetERror(eUNSUPPORTED);
         exit;
      end;

      {check compression and filtering}
      if(data.HDR.CompressionMethod <> 0) and (data.HDR.FilterMethod <> 0) then begin
         ld.SetError(eUNSUPPORTED);
         exit;
      end;

      {Calculate size and allocate memory}
      ld.Calculate();
      ld.Allocate();
   end;
end;

{ decoding }
const
   zBufferSize = 4096 * 2;

{IDAT CHUNK(S)

Since it is allowed and quite possible that there is more than one IDAT chunk
it takes a bit more care to load it all properly.}

{this routine loads the data from the IDAT chunk(s)
and stores it as image data into memory}
procedure loadIDAT(var ld: imgTFileData; var data: TPNGLoaderData);
var
   pos, bread, size, toread: fileint;
   error: longint;

begin
   pos := 0;

   repeat
      size := data.chunk.length - pos;

      if(size < zBufferSize) then
         toread := size
      else
         toread := zBufferSize;

      bread := ld.BlockRead(data.zBuffer^, toread);

      if(bread > 0) then begin
         inc(pos, bread);

         data.fzStream.avail_in  := bread;
         data.fzStream.next_in   := data.zBuffer;
      end else begin
         ld.SetError(eINVALID);
         exit();
      end;

      repeat
         error := zinflate.inflate(data.fzStream, Z_NO_FLUSH);

         if(error < 0) then begin
            ld.SetError(eEXTERNAL, 'z_stream error(' + sf(error) + ',' + zError(error) + ') while unpacking');
            exit();
         end;
      until (data.fzStream.avail_in <= 0);

   until (pos >= data.chunk.length) or ld.PFile^.f^.EOF() or (error <> Z_OK);

   skipCRC(ld);

   inc(data.nIDAT);
end;

{$PUSH}{$R-}
function paethPredictor(a, b, c: longint): longint; inline;
var
   p,
   pa,
   pb,
   pc: longint;

begin
   p  := a + b - c;
   pa := abs(p - a);
   pb := abs(p - b);
   pc := abs(p - c);

   if(pa <= pb) and (pa <= pc) then
      Result := a
   else if(pb <= pc) then
      Result := b
   else
      Result := c;
end;
{$POP}

procedure pngFilter(var img: imgTImage; var data: TPNGLoaderData);
var
   i,
   j: longint;

   left,
   above,
   aboveleft: longint;

   row,
   prow,
   targetRow: pbyte;

   pngRowSize: longint = 0;

procedure getRows();
begin
   prow        := data.pngBuffer + (pngRowSize * i - pngRowSize) + 1;
   row         := data.pngBuffer + (pngRowSize * i) + 1;
   targetRow   := pbyte(img.Image)+(img.RowSize * i);
end;

begin
   if(data.pngBuffer <> nil) then begin
      pngRowSize := img.RowSize + 1;
      targetRow := nil;

      row := nil;
      prow := nil;

      for i := 0 to (img.Height - 1) do begin
         getRows();

         {the first byte of a row is the filter byte,
         since row points to data after the filter byte, we use -1 to get the filter byte}

         case row[-1] of
            pngcFILTER_SUB: begin
               {$PUSH}{$R-}
               for j := data.bpp to (img.RowSize-1) do
                  row[j] := (row[j] + row[j - data.bpp]) and $FF;
               {$POP}
            end;

            pngcFILTER_UP: begin
               for j := 0 to (img.RowSize-1) do begin
                  {$PUSH}{$R-}
                  row[j] := (row[j] + prow[j]) and $FF;
                  {$POP}
               end;
            end;

            pngcFILTER_AVERAGE: begin
               for j := 0 to (img.RowSize-1) do begin
                  if(i > 0) then
                     above := prow[j]
                  else
                     above := 0;

                  if(j >= data.bpp) then
                     left := row[j - data.bpp]
                  else
                     left := 0;

                  {$PUSH}{$R-}
                  row[j] := (row[j] + ((left + above) div 2)) and $FF;
                  {$POP}
               end;
            end;

            pngcFILTER_PAETH: begin
               left := 0;
               aboveleft := 0;

               for j := 0 to img.RowSize - 1  do begin
                  if(j >= data.bpp) then begin
                     left        := row[j - data.bpp];
                     aboveleft   := prow[j-data.bpp];
                  end;

                  {$PUSH}{$R-}
                  row[j] := (row[j] + paethPredictor(left, prow[j], aboveleft)) and $FF;
                  {$POP}
               end;
            end;
         end;
      end;

      { move all data to the final image }
      for i := 0 to (img.Height-1) do begin
         getRows();

         move(row^, targetRow^, img.RowSize)
      end;
   end;
end;

procedure loadPhysicalData(var ld: imgTFileData; var img: imgTImage);
var
   physData: pngfTphYs;

begin
   ld.BlockRead(physData, SizeOf(physData));

   img.ppux       := physData.ppux;
   img.ppuy       := physData.ppuy;
   img.unitSpec   := physData.unitSpec;
end;

procedure pngReadChunks(var ld: imgTFileData; var img: imgTImage; var data: TPNGLoaderData);
begin
   {go through all chunks}
   repeat
      {read chunk header}
      pngReadChunkHeader(ld, data);
      if(ld.GetError() <> 0) then
        break;

      {IDAT}
      if (data.chunk.typ = pngcIDAT) then
        loadIDAT(ld, data)
      {IEND}
      else if(data.chunk.typ = pngcIEND) then
         exit
      {pHYs}
      else if(data.chunk.typ = pngcpHYs) then
         loadPhysicalData(ld, img)
      {UNKNOWN}
      else
         skipChunk(ld, data);

      if(ld.GetError() <> 0) then
        break;
   until(ld.PFile^.f^.EOF() = true);
end;

function getPNGBufferSize(const img: imgTImage): int64;
begin
   Result := int64(img.Height) * (int64(img.RowSize) + int64(1));
end;

procedure loadFile(var ld: imgTFileData; var img: imgTImage; var data: TPNGLoaderData);
var
   error: longint;

begin
   {load the IHDR chunk}
   loadIHDR(ld, img, data);
   if(ld.GetError() <> 0) then
      exit;

   {allocate memory for the z buffer}
   GetMem(data.zBuffer, zBufferSize);
   if(data.zBuffer <> nil) then begin
      GetMem(data.pngBuffer, getPNGBufferSize(img));

      if(data.pngBuffer <> nil) then begin
         {initialize inflate}
         error := zinflate.inflateInit_(@data.fzStream, ZLIB_VERSION, SizeOf(TZStream));
         if(error = 0) then begin
            data.fzStream.next_out  := data.pngBuffer;
            data.fzStream.avail_out := getPNGBufferSize(img);

            {read all chunks}
            pngReadChunks(ld, img, data);

            if(ld.GetError() = 0) then begin
               {filter image}
               pngFilter(img, data);
            end;
         end;
      end else
         ld.SetError(eNO_MEMORY);
   end else
      ld.SetError(eNO_MEMORY);

   zinflate.inflateEnd(data.fzStream);
   XFreeMem(data.zBuffer);
   XFreeMem(data.pngBuffer);
end;

{the main routine for loading png images}
procedure load(data: pointer);
var
   pngSig: packed array[0..7] of byte;
   ld: imgPFileData;
   loaderData: TPNGLoaderData;

begin
   ld := oxTFileRWData(data^).External;

   {read png signature and verify it}
   ld^.BlockRead(pngSig, 8);

   if(ld^.GetError() = 0) then begin
      if(CompareDWord(pngSig, pngcSignature, 2) <> 0) then begin
         ld^.SetError(eINVALID);
         exit;
      end;

      {initialize loader data}
      ZeroOut(loaderData, SizeOf(TPNGLoaderData));
      loadFile(ld^, ld^.Image, loaderData);
   end;
end;

procedure init();
begin
  imgFile.Readers.RegisterHandler(loader, 'PNG', @load);
  imgFile.Readers.RegisterExt(ext, '.png', @loader);
end;

INITIALIZATION
   ox.PreInit.Add('image.png', @init);

END.
