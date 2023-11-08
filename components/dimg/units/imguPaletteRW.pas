{
   imguPaletteRW, read/write image palette files
   Copyright (C) 2013. Dejan Boras

   Started On:    02.04.2013.
}

{$INCLUDE oxdefines.inc}
UNIT imguPaletteRW;

INTERFACE

   USES
      uStd, uLog, StringUtils, uImage,
      uFileHandlers, uFile, uFiles;

TYPE
   palPFileData = ^palTFileData;
   palTFileData = record
      pal: imgTPalette;
      error: longint;
      eDescription: string;

      fn: string;
      fileType: longword;
      f: uFile.PFile;
   end;

VAR
   palLoaders: fhTHandlerInfo; {palette loaders}

{initialize a loader data record}
procedure palInit(out ld: palTFileData);
{fills out error data from file loader data}
procedure palSetErrorData(var errorData: imgTErrorData; const data: palTFileData);

{load a palette}
function palLoad(var palette: imgTPalette; const filename: string): longint;
function palLoad(var palette: imgTPalette; const filename: string; out errorData: imgTErrorData): longint;
{save a palette}
function palWrite(var palette: imgTPalette; const filename: string): longint;
function palWrite(var palette: imgTPalette; const filename: string; out errorData: imgTErrorData): longint;

IMPLEMENTATION

procedure palInit(out ld: palTFileData);
begin
   ZeroOut(ld, SizeOf(ld));
end;

procedure palSetErrorData(var errorData: imgTErrorData; const data: palTFileData);
begin
   errorData.e := data.error;
   if(data.f <> nil) then begin
      errorData.f    := data.f^.error;
      errorData.io   := data.f^.ioError;
   end;
   errorData.description := data.eDescription;
end;

procedure palLogError(const fn, what: string; const data: palTFileData);
begin
   if(not img.settings.log) then begin
      log.i(imgcName+' > error ' + what + ': ' + fn);
      if(data.f <> nil) then
         log.e('Error: ' + sf(data.error) + ', file: ' + sf(data.f^.error) + ', IO: ' + sf(data.f^.ioError))
      else
         log.e('Error: ' + sf(data.error));
   end;
end;

function palLoad(var palette: imgTPalette; const filename: string): longint;
var
   errorData: imgTErrorData;

begin
   result := palLoad(palette, filename, errorData);
end;

function palLoad(var palette: imgTPalette; const filename: string; out errorData: imgTErrorData): longint;
var
   data: palTFileData;
   fd: fhTFindData;
   f: TFile;

begin
   result := eNONE;

   {initialize}
   if(length(filename) <> 0) then begin
      fInit(f);
      img.Init(errorData);
      palInit(data);

      {set up the loader data}
      data.f      := @f;
      data.pal    := palette;

      {store the filename if specified}
      if(img.settings.storeFileNames = true) then
         palette.fn   := filename;

      if(img.settings.logNameAlways) then
         log.i(imgcName+' > Loading: ' + FileName);

      {call the file handler which will figure out what loader to call}
      if(palLoaders.FindHandler(FileName, fd) <> 0) then
         exit(imgeFILEHANDLER);

      {if a loader has been found}
      if(fd.handler <> nil) then begin
         {open the file if instructed to do so}
         if(not fd.handler^.DoNotOpenFile) then begin
            f.Open(fileName);
            if(f.error <> 0) then begin
               palSetErrorData(errorData, data);
               exit(eIO);
            end;

            if(f.GetSize() = 0) then begin
               f.Close();
               exit(eEMPTY);
            end;
         end;

         {call the loader}
         fd.handler^.CallHandler(@data, fileName);

         if(data.error <> 0) then begin
            palSetErrorData(errorData, data);
            palLogError(fileName, 'loading', data);
         end;

         {close the file if instructed to do so}
         if(not fd.handler^.DoNotOpenFile) then begin
            f.Close();
            fErrorIgn();
         end;

         result := data.error;
      end else begin
         exit(imgeLOADER_NOT_FOUND);
      end;
   end;
end;

function palWrite(var palette: imgTPalette; const filename: string): longint;
var
   errorData: imgTErrorData;

begin
   result := palWrite(palette, filename, errorData);
end;

function palWrite(var palette: imgTPalette; const filename: string; out errorData: imgTErrorData): longint;
begin
   result := eNONE;
   img.Init(errorData);

   if(filename <> '') and (palette.Data <> nil) then begin
      // TODO: Implement palWrite
   end;
end;

END.
