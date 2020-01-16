{
   imguWAL, Quake WAL image loader for dImage
   Copyright (C) 2007. Dejan Boras

   Started On:    20.12.2007.
}

{$INCLUDE oxdefines.inc}
UNIT imguWAL;

{Quake WAL Image Format.
Loads in only the first mipmap as the current uImage implementation does not
support multiple images(mipmaps).}

INTERFACE

   USES
      uStd, uImage, uFileHandlers, imguRW,
      {ox}
      uOX, oxuFile;

CONST
   walcsPalAuthor       = 'ID Software';
   walcsPalName         = 'Quake 2';
   walcsPalDescription  = 'Quake 2 Palette';

TYPE
   walTHeader = packed record
      sName: string[31]; {texture name}
      Width,
      Height: longword; {width and height}

      Offset: array[0..3] of longword; {offset of each texture mipmap in the file}
      sNext: string[31]; {name of the next texture, if animated}

      flags,
      contents,
      value: longword; {unknown}
   end;

procedure quake2palproc;

VAR
   q2Palette: imgTPalette;

IMPLEMENTATION

VAR
   ext: fhTExtension;
   loader: fhTHandler;

{ palette }
{$INCLUDE quake2_pal.inc}

{Loads the wal image.}
procedure load(data: pointer);
var
   hdr: walTHeader;
   ld: imgPFileData;
   imgP: imgTImage;

begin
   ld := oxTFileRWData(data^).External;
   imgP  := ld^.Image;

   {read the header}
   if(ld^.BlockRead(hdr, SizeOf(hdr)) = -1) then
      exit;

   {check the values}
   if(hdr.Width = 0) or (hdr.Height = 0) then begin
      ld^.SetError(eINVALID);
      exit;
   end;

   {assign pixel format}
   imgP.PixF           := PIXF_INDEX_RGB_8;
   imgP.PixelDepth     := 8;
   {assign width and height}
   imgP.Width          := hdr.Width;
   imgP.Height         := hdr.Height;
   {essentialy, the number of bytes(size) and number of pixels is the same}
   imgP.Size           := hdr.Width*hdr.Height;
   imgP.Pixels         := imgP.Size;

   imgP.Origin         := imgcORIGIN_TL; {bottom-left}

   {read in only the first mipmap}
   ld^.Seek(hdr.Offset[0]);
   if(ld^.GetError() = 0) then begin
      ld^.Allocate();

      if(ld^.GetError() = 0) then begin
         ld^.BlockRead(imgP.Image^, imgP.Size);

         if(ld^.GetError() <> 0) then begin
            {associate the q2 palette with the image}
            if(imgP.palette = nil) then begin
               imgP.SetExternalPalette(q2Palette);
            end;
         end;
      end;
   end;
end;

procedure init();
begin
  q2Palette := imgTPalette.Create();

  q2Palette.nColors := 256;
  q2Palette.PixF := PIXF_RGB;
  q2Palette.Size := 256 * 3;
  q2Palette.Data := @quake2palproc;
  q2Palette.DataExternal := true;
  q2Palette.sAuthor := walcsPalAuthor;
  q2Palette.sName := walcsPalName;
  q2Palette.sDescription := walcsPalDescription;
end;

procedure deinit();
begin
  FreeObject(q2Palette);
end;

INITIALIZATION
   imgFile.Readers.RegisterHandler(loader, 'WAL', @load);
   imgFile.Readers.RegisterExt(ext, '.ext', @loader);

   ox.PreInit.Add('image.pnm', @init, @deinit);

END.
