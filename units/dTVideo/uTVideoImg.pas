{
   uTVideoImg, image operations
   Copyright (C) 2007. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uTVideoImg;

INTERFACE

   USES uStd, uTVideo;

CONST
   tvcImageFileVersion: word  = $0100;

TYPE
   tvcTImgID = array[0..3] of char;

CONST
   tvcImgID: tvcTImgID = ('D', 'T', 'V', 'I');

{loads a text video image}
procedure tvLoadImage(const fn: string; var img: pointer);
{saves a text video image}
procedure tvSaveImage(const fn: string; img: pointer);

IMPLEMENTATION

{loads a text video image}
procedure tvLoadImage(const fn: string; var img: pointer);
var
   f: file;
   w: word           = 0;
   h: word           = 0;
   version: word     = 0;
   size: longword;
   id: tvcTImgID     = '';
   endian: byte      = 0;

   procedure CleanUp(err: longint);
   begin
      tvGlobal.eRaise(err);
      Close(f);
   end;

begin
   {open the file}
   Assign(f, fn);
   Reset(f, 1);
   if(ioerror <> 0) then begin
      tvGlobal.eRaise(eIO);
      exit;
   end;

   {read the ID and verify it}
   blockread(f, id, SizeOf(tvcTImgID));
   if(ioerror <> 0) then begin
      CleanUp(eIO);
      exit;
   end;

   if(id <> tvcImgID) then begin
      CleanUp(tveNOT_TV_IMAGE);
      exit;
   end;

   {read the endian and verify it}
   blockread(f, endian, 1);
   if(ioerror <> 0) then begin
      CleanUp(eIO);
      exit;
   end;

   {$IFDEF ENDIAN_LITTLE}
   if(endian <> $00) then begin
      if(endian = $FF) then
   {$ELSE}
   if(endian <> $FF) then begin
      if(endian = $00) then
   {$ENDIF}
      begin
         CleanUp(tveUNSUPPORTED_ENDIAN);
         exit;
      end else begin
        CleanUp(tveCORRUPTED);
        exit;
      end;
   end;

   {read the version and verify it}
   blockread(f, version, 2);
   if(ioerror <> 0) then begin
      CleanUp(eIO);
      exit;
   end;

   if(version <> tvcImageFileVersion) then begin
      CleanUp(tveUNSUPPORTED_VERSION);
      exit;
   end;

   {read the width and height}
   blockread(f, w, 2);
   if(ioerror <> 0) then begin
      CleanUp(eIO);
      exit;
   end;

   blockread(f, h, 2);
   if(ioerror <> 0) then begin
      CleanUp(eIO);
      exit;
   end;

   size := w * h * 2;

   {allocate memory for the image}
   XFreeMem(img);
   XGetMem(img, size + 4);
   if(img <> nil) then begin 
      {store the width and height}
      word(img^)        := w;
      word((img + 2)^)  := h;

      {read the image data}
      if(size > 0) then begin
         blockread(f, (img + 4)^, size);
         if(ioerror <> 0) then begin
            CleanUp(eIO);
            exit;
         end;
      end;

      {close the file}
      Close(f);
      if(ioerror <> 0) then
         tvGlobal.eRaise(eIO);
   end else
      CleanUp(eNO_MEMORY);
end;

{saves a text video image}
procedure tvSaveImage(const fn: string; img: pointer);
var
   f: file;
   w,
   h: word;
   size: longword;

   procedure CleanUp(err: longint); begin
      tvGlobal.eRaise(err);
      Close(f);
   end;

begin
   if(img <> nil) then begin
      {open the file}
      Assign(f, fn);
      Rewrite(f, 1);
      if(ioerror <> 0) then begin
         tvGlobal.eRaise(eIO);
         exit;
      end;

      {write the ID}
      blockwrite(f, tvcImgID, 4);
      if(ioerror <> 0) then begin
         CleanUp(eIO);
         exit;
      end;

      {write the endian}
      blockwrite(f, ENDIAN_BYTE, 1);
      {write the version}
      blockwrite(f, tvcImageFileVersion, 2);
      if(ioerror <> 0) then begin
         CleanUp(eIO);
         exit;
      end;

      {get the width and height}
      w := word(img^);
      h := word((img + 2)^);
      
      {write the width and height of the image}
      blockwrite(f, w, 2);
      if(ioerror <> 0) then begin
         CleanUp(eIO);
         exit;
      end;

      blockwrite(f, h, 2);
      if(ioerror <> 0) then begin
         CleanUp(eIO);
         exit;
      end;

      {now write the entire image}
      size := w*h*2;
      if(size > 0) then begin
         blockwrite(f, (img + 4)^, size);
         if(ioerror <> 0) then begin
            CleanUp(eIO);
            exit;
         end;
      end;

      {close the file and finish up}
      Close(f);
      if(ioerror <> 0) then begin
         CleanUp(eIO);
         exit;
      end;
   end;
end;

END.
