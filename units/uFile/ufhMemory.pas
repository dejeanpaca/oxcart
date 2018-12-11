{
   ufhMemory
   Copyright (C) 2011. Dejan Boras

   Started On:    19.02.2011.
}

{$MODE OBJFPC}{$H+}{$I-}
UNIT ufhMemory;

INTERFACE

   USES uStd, uFileUtils, uFile, StringUtils;

VAR
   memFileHandler: TFileHandler;
   memMemFileHandler: TFileMemHandler;

IMPLEMENTATION

CONST
   PROP_EXTERNAL = 0001;

{MEMORY FILE HANDLER}
function memRead(var f: TFile; var buf; count: fileint): fileint;
begin
   {$IFNDEF DFILE_QND}
   if(f.extData <> nil) then begin
   {$ENDIF}
      move((f.extData + f.fPosition)^, buf, count);
      Result := count;
   {$IFNDEF DFILE_QND}
   end else
      Result := -1;
   {$ENDIF}
end;

function memWrite(var f: TFile; var buf; count: fileint): fileint;
begin
   {$IFNDEF DFILE_QND}
   if(f.extData <> nil) then begin
   {$ENDIF}
      move(buf, (f.extData + f.fPosition)^, count);
      Result := count;
   {$IFNDEF DFILE_QND}
   end else
      Result := -1;
   {$ENDIF}
end;

procedure memDispose(var f: TFile);
begin
   if(f.extData <> nil) then begin
      if(f.handlerProps and PROP_EXTERNAL > 0) then begin
         Freemem(f.extData);
         f.extData := nil;
      end;
   end;
end;

procedure memfOpen(var f: TFile; mem: pointer; size: fileint);
begin
   f.fn           := 'mem:' + HexStr({%H-}ptrint(mem), SizeOf(mem) div 2) + ':' + sf(Size);

   f.extData      := mem;
   f.fSizeLimit   := size;
   f.fSize        := size;
end;

procedure memfNew(var f: TFile; size: fileint);
begin
   GetMem(f.extData, size);
   f.handlerProps := f.handlerProps or PROP_EXTERNAL;

   if(f.extData <> nil) then begin
      f.fSizeLimit := size;
      f.fn := 'mem:' + HexStr({%H-}ptrint(f.extData), SizeOf(f.extData) div 2) + ':' + sf(Size);
   end else
      f.raiseError(eNO_MEMORY);
end;

INITIALIZATION
   {memory file handler}
   memFileHandler                := fFile.DummyHandler;
   memFileHandler.read           := fTReadFunc     (@memRead);
   memFileHandler.write          := fTWriteFunc    (@memWrite);
   memFileHandler.dispose        := fTFileProcedure(@memDispose);
   memFileHandler.useBuffering   := false;
   memFileHandler.doReadUp       := false;

   memMemFileHandler.handler     := @memFileHandler;
   memMemFileHandler.open        := @memfOpen;
   memMemFileHandler.new         := @memfNew;
   fFile.Handlers.Mem := @memMemFileHandler;
END.

