{
   ufhSub
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT ufhSub;

INTERFACE

   USES uStd, StringUtils, uFileUtils, uFile;

TYPE

   { TSubFileHandler }

   TSubFileHandler = object(TFileHandler)
      constructor Create();

      function Read(var f: TFile; out buf; count: fileint): fileint; virtual;
      function Write(var f: TFile; const buf; count: fileint): fileint; virtual;
      function Seek(var f: TFile; pos: fileint): fileint; virtual;
      procedure Flush(var f: TFile); virtual;
   end;

VAR
   subfHandler: TSubFileHandler;
   subSubFileHandler: TFileSubHandler;

IMPLEMENTATION

procedure subfOpen(var f: TFile; var fn: TFile; pos, size: fileint);
begin
   {set defaults}
   f.fn           := 'sub(' + sf(pos) + ',' + sf(size) + '):' + fn.fn;

   f.pSub         := @fn;
   f.fSize        := size;
   f.fSizeLimit   := size;
   f.fOffset      := pos;
end;

procedure subfNew(var f: TFile; var fn: TFile; pos, size: fileint); {subfile}
begin
   f.fn           := 'sub(' + sf(pos) + ',' + sf(size) + '):' + fn.fn;

   f.pSub         := @fn;
   f.fSize        := 0;
   f.fSizeLimit   := size;
   f.fOffset      := pos;
end;

{ TSubFileHandler }

constructor TSubFileHandler.Create();
begin
   Name := 'sub';
   DoReadUp := false;
   UseBuffering := false;
end;

function TSubFileHandler.Read(var f: TFile; out buf; count: fileint): fileint;
begin
   Result := f.pSub^.Read(buf, count);
end;

function TSubFileHandler.Write(var f: TFile; const buf; count: fileint): fileint;
begin
   Result := f.pSub^.Write(buf, count);
end;

function TSubFileHandler.Seek(var f: TFile; pos: fileint): fileint;
begin
   Result := f.pSub^.Seek(f.fOffset + pos);

   if(Result > 0) then
      Result := Result - f.fOffset;
end;

procedure TSubFileHandler.Flush(var f: TFile);
begin
   f.pSub^.Flush();
end;

INITIALIZATION
   {sub file handler}
   subfHandler.Create();

   subSubFileHandler.Handler  := @subfHandler;
   subSubFileHandler.Open     := @subfOpen;
   subSubFileHandler.New      := @subfNew;

   fFile.Handlers.Sub := @subSubFileHandler;
END.
