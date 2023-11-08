{
   ufhUnix
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT ufhUnix;

INTERFACE

   USES
      BaseUnix, Unix, uUnix, uStd, uFileUtils, uFile, StringUtils;

TYPE

   { TUnixFileHandler }

   TUnixFileHandler = object(TFileHandler)
      constructor Create();

      procedure Open(var f: TFile); virtual;
      procedure New(var f: TFile); virtual;
      function Read(var f: TFile; out buf; count: fileint): fileint; virtual;
      function Write(var f: TFile; const buf; count: fileint): fileint; virtual;
      procedure Close(var f: TFile); virtual;
      procedure Flush(var f: TFile); virtual;
      function Seek(var f: TFile; pos: fileint): fileint; virtual;
      procedure OnBufferSet(var f: TFile); virtual;
   end;

   { TUnixBufferedFileHandler }

   TUnixBufferedFileHandler = object(TUnixFileHandler)
      function Read(var f: TFile; out buf; count: fileint): fileint; virtual;
      function Write(var f: TFile; const buf; count: fileint): fileint; virtual;
   end;

VAR
   stdfUnixHandler: TUnixFileHandler;
   stdfUnixHandlerBuffered: TUnixBufferedFileHandler;

   unixStdFileHandler: TFileStdHandler;

function unxfIoErr(var f: TFile): longint;
procedure fOpenUnix(var f: TFile; d: cint; offs, size: fileint); {normal file via descriptor}

IMPLEMENTATION

function unxfIoErr(var f: TFile): longint;
begin
   f.IoError := fpgeterrno();

   if(f.IoError = 0) then
      exit(0)
   else begin
      fpseterrno(0);
      f.Error := eIO;
   end;

   Result := f.IoError;
end;

{STANDARD FILE HANDLER}

procedure fOpenUnix(var f: TFile; d: cint; offs, size: fileint); {normal file via descriptor}
begin
   f.ErrorReset();

   {set defaults}
   f.SetDefaults(fcfREAD, 'dscr:' + sf(d));

   {assign a standard file handler}
   f.AssignHandler(stdfUnixHandler);
   if(f.Error = 0) then begin
      f.Handle := d;
      f.Seek(offs);

      if(f.Error = 0) then begin
         f.fSize        := size;
         f.fSizeLimit   := size;
         f.fOffset      := offs;
      end;
   end;
end;

{ TUnixBufferedFileHandler }

function TUnixBufferedFileHandler.Read(var f: TFile; out buf; count: fileint): fileint;
var
   bRead,
   bLeft,
   rLeft: fileint;

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
      rLeft := (count - bLeft);

      {fill the buffer first and then read from buffer}
      if(rLeft <= f.bSize) then begin
         bRead := unxFpread(f.Handle, pchar(f.bData), f.bSize);

         if(unxfIoErr(f) = 0) then begin
            move(f.bData^, (@buf + bLeft)^, rLeft);
            f.bPosition    := rLeft;
            f.bLimit       := bRead;
            Result         := count;
         end else
            Result := -bLeft;
      {read directly}
      end else begin
         bRead := unxFpread(f.Handle, pchar(@buf + bLeft), rLeft);

         if(unxfIoErr(f) = 0) then
            Result := bLeft + bRead
         else
            Result := -(bLeft + bRead);
      end;
   end;
end;

function TUnixBufferedFileHandler.Write(var f: TFile; const buf; count: fileint): fileint;
var
   bWrite: fileint;

procedure moveToBuf(); inline;
begin
   move(buf, (f.bData + f.bPosition)^, count);
   inc(f.bPosition, count);
end;

begin
   {store into buffer}
   if(f.bPosition + count < f.bSize-1) then begin
      moveToBuf();
      Result := count;
   {write out}
   end else begin
      {write out buffer}
      bWrite := unxFpread(f.Handle, pchar(f.bData), f.bPosition);
      f.bPosition := 0;

      {store data into buffer if it can fit}
      if(count < f.bSize) then begin
         moveToBuf();
         Result := count;
      {otherwise write contents directly to file}
      end else begin
         bWrite := unxFpread(f.Handle, pchar(@buf), count);

         if(unxfIoErr(f) = 0) then
            Result := bWrite
         else
            exit(-1);
      end;
   end;
end;

{ TUnixFileHandler }

constructor TUnixFileHandler.Create();
begin
   Name := 'unix';
   UseBuffering := true;
end;

procedure TUnixFileHandler.Open(var f: TFile);
var
   pos: fileint;

begin
   fpseterrno(0);
   f.Handle := FpOpen(f.fn, O_RdOnly);

   if(unxfIoErr(f) = 0) then begin
      pos := FpLseek(f.Handle, 0, SEEK_END);

      if(unxfIoErr(f) = 0) then begin
         FpLSeek(f.Handle, 0, SEEK_SET);

         if(unxfIoErr(f) = 0) then begin
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

procedure TUnixFileHandler.New(var f: TFile);
begin
   fpseterrno(0);

   f.Handle := FpOpen(f.fn, O_WrOnly or O_Creat or O_Trunc);

   if(unxfIoErr(f) <> 0) then begin
      f.RaiseError(feNEW);
      f.AutoSetBuffer();
   end;
end;

function TUnixFileHandler.Read(var f: TFile; out buf; count: fileint): fileint;
var
   bRead: fileint;

begin
   {$PUSH}{$HINTS OFF} // buf does not need to be initialized, since we're moving data into it
   bRead := unxFpRead(f.Handle, pchar(@buf), count);{$POP}

   if(unxfIoErr(f) = 0) then
      Result := bRead
   else
		exit(-1);
end;

function TUnixFileHandler.Write(var f: TFile; const buf; count: fileint): fileint;
var
   bWrite: fileint;

begin
   bWrite := unxFpWrite(f.Handle, pchar(@buf), count);

   if(unxfIoErr(f) = 0) then
      Result := bWrite
   else
      Result := -1;
end;

procedure TUnixFileHandler.Close(var f: TFile);
begin
   FpClose(f.Handle);
   unxfIoErr(f);
end;

procedure TUnixFileHandler.Flush(var f: TFile);
begin
   unxFpWrite(f.Handle, pchar(f.bData), f.bPosition);
   unxfIoErr(f);
end;

function TUnixFileHandler.Seek(var f: TFile; pos: fileint): fileint;
var
   res: fileint;

begin
   res := FpLSeek(f.Handle, f.fOffset + pos, Seek_Set);

   if(unxfIoErr(f) = 0) then
      Result := res
   else
      Result := -1;
end;

procedure TUnixFileHandler.OnBufferSet(var f: TFile);
begin
   {if buffering set}
   if(f.bSize > 0) then
      f.pHandler := @stdfUnixHandlerBuffered
   {if buffering not set}
   else
      f.pHandler := @stdfUnixHandler;
end;

INITIALIZATION
   stdfUnixHandler.Create();
   stdfUnixHandlerBuffered.Create();

   unixStdFileHandler.Handler := @stdfUnixHandler;
   fFile.Handlers.Std := @unixStdFileHandler;

END.
