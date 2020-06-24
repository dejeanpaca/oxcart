{
   oxu9PatchFileReader, reads oX specific 9patch files
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxu9PatchFileReader;

INTERFACE

   USES
      uStd, uFile, uFileHandlers, uLog, StringUtils,
      {ox}
      oxuFile, oxu9Patch, oxu9PatchFile;

IMPLEMENTATION

VAR
   ext: fhTExtension;
   handler: fhTHandler;

procedure handleFile(var f: TFile; var data: oxTFileRWData);
begin
end;

procedure handle(data: pointer);
begin
   handleFile(oxTFileRWData(data^).f^, oxTFileRWData(data^));
end;

INITIALIZATION
   oxf9Patch.Readers.RegisterHandler(handler, '9patch', @handle);
   oxf9Patch.Readers.RegisterExt(ext, '.9p', @handler);

END.
