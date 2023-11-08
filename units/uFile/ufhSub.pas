{
   ufhSub
   Copyright (C) 2011. Dejan Boras

   Started On:    19.02.2011.
}

{$MODE OBJFPC}{$H+}{$I-}
UNIT ufhSub;

INTERFACE

   USES uStd, StringUtils, uFileUtils, uFile;

VAR
   subfHandler: TFileHandler;
   subSubFileHandler: TFileSubHandler;

IMPLEMENTATION


function subRead(var f: TFile; out buf; count: fileint): fileint;
begin
   f.pSub^.Read(buf, count);
   if(f.error = 0) then
      Result := count
   else
      Result := -1;
end;

function subWrite(var f: TFile; var buf; count: fileint): fileint;
begin
   f.pSub^.Write(buf, count);
   if(f.error = 0) then
      Result := count
   else
      Result := -1;
end;

procedure subSeek(var f: TFile; pos: fileint);
begin
   f.pSub^.Seek(f.fOffset + pos);
end;

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

procedure subFlush(var f: TFile);
begin
   f.pSub^.Flush();
end;

INITIALIZATION
   {sub file handler}
   subfHandler                := fFile.DummyHandler;
   subfHandler.Name           := 'sub';
   subfHandler.read           := fTReadFunc     (@subRead);
   subfHandler.write          := fTWriteFunc    (@subWrite);
   subfHandler.seek           := fTSeekProc     (@subSeek);
   subfHandler.flush          := fTFileProcedure(@subFlush);

   subSubFileHandler.handler  := @subfHandler;
   subSubFileHandler.open     := @subfOpen;
   subSubFileHandler.new      := @subfNew;
   fFile.Handlers.Sub := @subSubFileHandler;
END.
