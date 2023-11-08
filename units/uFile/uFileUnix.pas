{
   uFileUnix
   Copyright (C) 2011. Dejan Boras
}

{$MODE OBJFPC}{$H+}{$I-}
UNIT uFileUnix;

INTERFACE

   USES BaseUnix, Unix, uStd, uFileUtils, uFile, StringUtils;
   
VAR
   stdfUnixHandler: TFileHandler;
   stdfUnixHandlerBuffered: TFileHandler;

   unixStdFileHandler: TFileStdHandler;

procedure fOpenUnx(var f: TFile; d: cint; offs, size: fileint); {normal file via descriptor}

IMPLEMENTATION

function fioerr(var f: TFile): longint;
begin
   f.ioError := fpgeterrno();

   if(f.ioError = 0) then
      exit(0)
   else begin
      fpseterrno(0);
      f.error := eIO;
   end;

   Result := f.ioError;
end;

{STANDARD FILE HANDLER}

procedure unxOpen(var f: TFile);
var
   pos: fileint;

begin
   fpseterrno(0);

   f.handle := FpOpen(f.fn, O_RdOnly);

   if(fioerr(f) = 0) then begin
      pos := FpLseek(f.handle, 0, SEEK_END);
      if(fioerr(f) = 0) then begin
         FpLSeek(f.handle, 0, SEEK_SET);
         if(fioerr(f) = 0) then begin
            f.fSize := pos;
            f.fSizeLimit := 0;

            f.AutoSetBuffer();
         end else
            f.RaiseError(feSEEK);
      end else
         f.RaiseError(feSEEK);
   end else
      f.RaiseError(feOPEN);
end;

procedure unxNew(var f: TFile);
begin
   fpseterrno(0);

   f.handle := FpOpen(f.fn, O_WrOnly or O_Creat or O_Trunc);
   if(fioerr(f) <> 0) then begin
      f.RaiseError(feNEW);
      f.AutoSetBuffer();
   end;
end;

procedure unxClose(var f: TFile);
begin
   FpClose(f.handle);
   fioerr(f);
end;

procedure unxFlush(var f: TFile);
begin
   FpWrite(f.handle, f.bData^, f.bPosition);
   fioerr(f);
end;

function unxReadBfrd(var f: TFile; out buf; count: fileint): fileint;
var
   bRead, bLeft, rLeft: fileint;

begin
   bLeft := f.bLimit - f.bPosition;

   {if enough data is in the buffer}
   if(count <= bLeft) then begin
      {$PUSH}{$HINTS OFF} // buf does not need to be initialized, since we're moving data into it
      move((f.bData + f.bPosition)^, buf, count);
      {$POP}
      inc(f.bPosition, count);

      Result := count;
   end else begin
      {move what can be moved from the buffer}
      if(bLeft > 0) then begin
         move((f.bData + f.bPosition)^, buf, bLeft);
         f.bPosition    := 0;
         f.bLimit       := 0;
      end;

      {figure out what is left}
      rLeft := (count-bLeft);

      {fill the buffer first and then read from buffer}
      if(rLeft <= f.bSize) then begin
         bRead := FpRead(f.handle, f.bData^, f.bSize);
         if(fioerr(f) = 0) then begin
            move(f.bData^, (@buf + bLeft)^, rLeft);
            f.bPosition    := rLeft;
            f.bLimit       := bRead;
            Result         := count;
         end else
            Result := -bLeft;
      {read directly}
      end else begin
         bRead := FpRead(f.handle, (@buf + bLeft)^, rLeft);
         if(fioerr(f) = 0) then
            Result := bLeft + bRead
         else
            Result := -(bLeft + bRead);
      end;
   end;
end;

function unxRead(var f: TFile; out buf; count: fileint): fileint;
var
   bRead: fileint;

begin
   {$PUSH}{$HINTS OFF} // buf does not need to be initialized, since we're moving data into it
   bRead := FpRead(f.handle, buf, count);{$POP}
   if(fioerr(f) = 0) then
      Result := bRead
   else
		exit(-1);
end;

function unxWriteBfrd(var f: TFile; var buf; count: fileint): fileint;
var
   bWrite: fileint;

procedure movetobuf(); inline;
begin
   move(buf, (f.bData + f.bPosition)^, count);
   inc(f.bPosition, count);
end;

begin
   {store into buffer}
   if(f.bPosition + count < f.bSize-1) then begin
      movetobuf();
      Result := count;
   {write out}
   end else begin
      {write out buffer}
      bWrite := FpWrite(f.handle, f.bData^, f.bPosition);
      f.bPosition := 0;

      {store data into buffer if it can fit}
      if(count < f.bSize) then begin
         movetobuf();
         Result := count;
      {otherwise write contents directly to file}
      end else begin
         bWrite := FpWrite(f.handle, buf, count);

         if(fioerr(f) = 0) then
            Result := bWrite
         else
            exit(-1);
      end;
   end;
end;

function unxWrite(var f: TFile; var buf; count: fileint): fileint;
var
   bWrite: fileint;

begin
   bWrite := FpWrite(f.handle, buf, count);
   if(fioerr(f) = 0) then
      Result := bWrite
   else
      Result := -1;
end;

function unxSeek(var f: TFile; pos: fileint): fileint;
var
   res: fileint;

begin
   res := FpLSeek(f.handle, f.fOffset + pos, Seek_Set);
   if(fioerr(f) = 0) then
      Result := res
   else
      Result := -1;
end;

procedure unxOnBufferSet(var f: TFile);
begin
   {if buffering set}
   if(f.bSize > 0) then
      f.pHandler := @stdfUnixHandlerBuffered
   {if buffering not set}
   else
      f.pHandler := @stdfUnixHandler;
end;

procedure fOpenUnx(var f: TFile; d: cint; offs, size: fileint); {normal file via descriptor}
begin
   f.ErrorReset();
   f.fNew      := 0;
   f.fMode     := fcfREAD;

   {set defaults}
   f.SetDefaults('dscr:' + sf(d));

   {assign a standard file handler}
   f.AssignHandler(stdfUnixHandler);
   if(f.error = 0) then begin
      f.handle := d;
      unxSeek(f, offs);

      if(f.error = 0) then begin
         f.fSize        := size;
         f.fSizeLimit   := size;
         f.fOffset      := offs;
      end;
   end;
end;

INITIALIZATION
   {standard file handler}
   stdfUnixHandler               := fDummyHandler;
   stdfUnixHandler.Name          := 'unix';
   stdfUnixHandler.open          := fTFileProcedure(@unxOpen);
   stdfUnixHandler.read          := fTReadFunc     (@unxRead);
   stdfUnixHandler.write         := fTWriteFunc    (@unxWrite);
   stdfUnixHandler.close         := fTFileProcedure(@unxClose);
   stdfUnixHandler.flush         := fTFileProcedure(@unxFlush);
   stdfUnixHandler.seek          := fTSeekProc     (@unxSeek);
   stdfUnixHandler.onbufferset   := fTFileProcedure(@unxOnBufferSet);
   stdfUnixHandler.useBuffering  := true;

   stdfUnixHandlerBuffered       := stdfUnixHandler;
   stdfUnixHandlerBuffered.read  := fTReadFunc(@unxReadBfrd);
   stdfUnixHandlerBuffered.write := fTWriteFunc(@unxWriteBfrd);

   unixStdFileHandler.handler    := @stdfUnixHandler;
   fStdFileHandler               := @unixStdFileHandler;
END.
