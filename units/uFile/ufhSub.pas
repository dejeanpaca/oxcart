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

      procedure Make(var f: TFile); virtual;
      procedure Destroy(var f: TFile); virtual;
      function Read(var f: TFile; out buf; count: fileint): fileint; virtual;
      function Write(var f: TFile; const buf; count: fileint): fileint; virtual;
      function Seek(var f: TFile; pos: fileint): fileint; virtual;
      procedure Flush(var f: TFile); virtual;
      procedure Close(var f: TFile); virtual;
   end;

VAR
   subfHandler: TSubFileHandler;
   subSubFileHandler: TFileSubHandler;

IMPLEMENTATION

TYPE
   subPData = ^subTData;
   subTData = record
      {original position of the parent file}
      pOriginalPosition: loopint;
   end;

procedure subfOpen(var f: TFile; var fn: TFile; pos, size: fileint);
begin
   {set defaults}
   f.fn           := 'sub(' + sf(pos) + ',' + sf(size) + '):' + fn.fn;

   f.pSub         := @fn;
   f.fSize        := size;
   f.fSizeLimit   := size;
   f.fOffset      := pos;

   subPData(f.pData)^.pOriginalPosition := f.pSub^.fPosition;

   f.pSub^.Seek(f.fOffset);
end;

procedure subfNew(var f: TFile; var fn: TFile; pos, size: fileint); {subfile}
begin
   f.fn           := 'sub(' + sf(pos) + ',' + sf(size) + '):' + fn.fn;

   f.pSub         := @fn;
   f.fSize        := 0;
   f.fSizeLimit   := size;
   f.fOffset      := pos;

   f.pSub^.Seek(f.fOffset);
end;

{ TSubFileHandler }

constructor TSubFileHandler.Create();
begin
   Name := 'sub';
   DoReadUp := false;
   UseBuffering := false;
end;

procedure TSubFileHandler.Make(var f: TFile);
begin
   system.New(subPData(f.pData));

   if(f.pData <> nil) then
      Zero(f.pData^, SizeOf(subTData))
   else
      f.RaiseError(eNO_MEMORY);
end;

procedure TSubFileHandler.Destroy(var f: TFile);
begin
   system.Dispose(subPData(f.pData));
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

procedure TSubFileHandler.Close(var f: TFile);
begin
   f.pSub^.Seek(subPData(f.pData)^.pOriginalPosition);
end;

INITIALIZATION
   {sub file handler}
   subfHandler.Create();

   subSubFileHandler.Handler  := @subfHandler;
   subSubFileHandler.Open     := @subfOpen;
   subSubFileHandler.New      := @subfNew;

   fFile.Handlers.Sub := @subSubFileHandler;
END.
