{
   ufhMemory
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT ufhMemory;

INTERFACE

   USES uStd, uFileUtils, uFile, StringUtils;

TYPE

   { TMemoryFileHandler }

   TMemoryFileHandler = object(TFileHandler)
      constructor Create();

      function Read(var f: TFile; out buf; count: fileint): fileint; virtual;
      function Write(var f: TFile; const buf; count: fileint): fileint; virtual;
      procedure Destroy(var f: TFile); virtual;
   end;

VAR
   memFileHandler: TFileHandler;
   memMemFileHandler: TFileMemHandler;

IMPLEMENTATION

CONST
   PROP_EXTERNAL = 0001;

{ TMemoryFileHandler }

constructor TMemoryFileHandler.Create();
begin
   inherited;
   Name := 'memory';
   UseBuffering := false;
   DoReadUp := false;
end;

function TMemoryFileHandler.Read(var f: TFile; out buf; count: fileint): fileint;
begin
   {$IFNDEF DFILE_QND}
   if(f.ExtData <> nil) then begin
   {$ENDIF}
      move((f.ExtData + f.fPosition)^, buf, count);
      Result := count;
   {$IFNDEF DFILE_QND}
   end else begin
      Result := -1;
   end;
   {$ENDIF}
end;

function TMemoryFileHandler.Write(var f: TFile; const buf; count: fileint): fileint;
begin
   {$IFNDEF DFILE_QND}
   if(f.ExtData <> nil) then begin
   {$ENDIF}
      move(buf, (f.ExtData + f.fPosition)^, count);
      Result := count;
   {$IFNDEF DFILE_QND}
   end else
      Result := -1;
   {$ENDIF}
end;

procedure TMemoryFileHandler.Destroy(var f: TFile);
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
   f.fn           := 'mem:' + addr2str(mem) + ':' + sf(Size);

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
      f.fn := 'mem:' + addr2str(f.extData) + ':' + sf(Size);
   end else
      f.raiseError(eNO_MEMORY);
end;

INITIALIZATION
   {memory file handler}
   memFileHandler.Create();

   memMemFileHandler.Handler := @memFileHandler;
   memMemFileHandler.Open    := @memfOpen;
   memMemFileHandler.New     := @memfNew;
   fFile.Handlers.Mem := @memMemFileHandler;
END.

