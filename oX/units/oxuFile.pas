{
   oxuFile, common oX file functionality
   Copyright (c) 2012. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuFile;

INTERFACE

   USES
     sysutils,
     uStd, uLog, uError, uTiming,
     {files}
     uFile, {%H-}uFiles, uFileHandlers,
     {ox}
     oxuPaths;

TYPE

   { oxTFileRWData }
   oxPFileRWData = ^oxTFileRWData;
   oxTFileRWData = record
      FileName: StdString;
      f: uFile.PFile;
      Handler: fhPHandler;

      {options for the handler}
      Options: pointer;
      {data kept by the handler data}
      HandlerData: Pointer;

      Error: loopint;
      ErrorDescription: StdString;

      Result: TObject;

      {external data}
      External: Pointer;

      {set an error code and description}
      procedure SetError(errorCode: loopint; const description: StdString = '');
      {set an error code and description}
      procedure SetError(const description: StdString = '');
      {get the error code}
      function GetError(): loopint;

      {it's ok if there are no errors}
      function Ok(): boolean;
   end;

   { oxTFileRW }

   oxTFileRW = object
      Readers,
      Writers: fhTHandlerInfo;

      {perform extended logging}
      LogExtended: boolean;

      constructor Create();

      function Read(var f: TFile; var handler: fhTHandler; options: pointer; pdata: oxPFileRWData = nil): loopint;
      function Read(var f: TFile; const fn: StdString; options: pointer; pdata: oxPFileRWData = nil): loopint;
      function Read(const fn: StdString; options: pointer = nil; pdata: oxPFileRWData = nil): loopint;

      function Write(var f: TFile; var handler: fhTHandler; options: pointer; pdata: oxPFileRWData = nil): loopint;
      function Write(var f: TFile; const fn: StdString; options: pointer; pdata: oxPFileRWData = nil): loopint;
      function Write(const fn: StdString; options: pointer = nil; pdata: oxPFileRWData = nil): loopint;

      function OnRead(var {%H-}data: oxTFileRWData): loopint; virtual;
      function OnWrite(var {%H-}data: oxTFileRWData): loopint; virtual;
   end;

IMPLEMENTATION

{ oxTFileRWData }

procedure oxTFileRWData.SetError(errorCode: loopint; const description: StdString);
begin
   if(Error = 0) then begin
      Error := errorCode;
      ErrorDescription := description;
   end;
end;

procedure oxTFileRWData.SetError(const description: StdString);
begin
   SetError(eFAIL, description);
end;

function oxTFileRWData.GetError(): loopint;
begin
   if(f <> nil) and (Error = 0) and (f^.Error <> 0) then
      Error := eIO;

   Result := Error;
end;

function oxTFileRWData.Ok(): boolean;
begin
   if(f <> nil) and (Error = 0) and (f^.Error <> 0) then
      Error := eIO;

   Result := Error = 0;
end;

{ oxTFileRW }

constructor oxTFileRW.Create();
begin

end;

procedure logIo(var f: TFile; const what: StdString = 'unknown');
begin
   log.e('File IO error: ' + f.fn);

   if(f.IoError <> 0) then
      log.e('(' + what + ') error: ' + f.GetErrorString() + ', io: ' + getRunTimeErrorString(f.IoError))
   else
      log.e('(' + what + ') error: ' + f.GetErrorString());
end;

function oxTFileRW.Read(var f: TFile; var handler: fhTHandler; options: pointer; pdata: oxPFileRWData = nil): loopint;
var
   startTime: TDateTime;
   localData: oxTFileRWData;

begin
   startTime := Now();

   if(pdata = nil) then begin
      pdata := @localData;
      ZeroOut(localData, SizeOf(localData));
   end;

   {set data}
   pdata^.FileName := f.fn;
   pdata^.f := @f;
   pdata^.Handler := @handler;
   pdata^.Options := options;

   {run handler}
   Result := OnRead(pdata^);

   {set result to error code, if any}
   if(Result = 0) then begin
      if(f.Error <> 0) then
         Result := eIO
      else if(pdata^.Error <> 0) then
         Result := eERR;
   end;

   if(Result <> 0) then begin
      log.e('Error (' + GetErrorCodeString(Result) + ') reading file: ' +
         f.fn + ' > ' + pdata^.ErrorDescription);
   end else begin
      {$IFDEF DEBUG}
      log.d('Read file: ' + f.fn + ' (Elapsed: ' + startTime.ElapsedfToString(3) + 's)');
      {$ENDIF}
   end;

   {close file if required}
   if(not handler.DoNotOpenFile) then
      f.Close();
end;

function oxTFileRW.Read(var f: TFile; const fn: StdString; options: pointer; pdata: oxPFileRWData = nil): loopint;
var
   fd: fhTFindData;

begin
   if(fn <> '') then begin
      Readers.FindHandler(fn, fd);

      if(fd.Handler <> nil) then begin
         Result := Read(f, fd.Handler^, options, pdata);

         if(f.Error <> 0) then begin
            logIo(f, 'reading');
            exit(eIO);
         end;
      end else
         exit(eUNSUPPORTED);
   end else
      Result := eINVALID_ARG;
end;

function oxTFileRW.Read(const fn: StdString; options: pointer = nil; pdata: oxPFileRWData = nil): loopint;
var
   f: TFile;
   fd: fhTFindData;
   path: StdString;

begin
   if(fn <> '') then begin
      fFile.Init(f);
      Readers.FindHandler(fn, fd);

      if(fd.Handler <> nil) then begin
         path := oxPaths.Find(fn);

         if(not fd.Handler^.DoNotOpenFile) then
            f.Open(path)
         else
            f.fn := fn;

         f.fn := fn;

         if(f.Error = 0) then begin
            exit(Read(f, fd.Handler^, options, pdata));
         end else begin
            logIo(f, 'opening for reading');
            exit(eIO);
         end;
      end else begin
         log.e('Could not find a handler for the file: ' + fn);
         exit(eUNSUPPORTED);
      end;
   end;

   Result := eINVALID_ARG;
end;

function oxTFileRW.Write(var f: TFile; var handler: fhTHandler; options: pointer; pdata: oxPFileRWData): loopint;
var
   localData: oxTFileRWData;

begin
   if(pdata = nil) then begin
      pdata := @localData;
      ZeroOut(localData, SizeOf(localData));
   end;

   {set data}
   pdata^.FileName := f.fn;
   pdata^.f := @f;
   pdata^.Handler := @handler;
   pdata^.Options := options;

   {run handler}
   Result := OnWrite(pdata^);

   {set result to error code, if any}
   if(Result = 0) then begin
      if(f.Error <> 0) then
         Result := eIO
      else if(pdata^.Error <> 0) then
         Result := eERR;
   end;

   if(Result <> 0) then begin
      log.e('Error (' + GetErrorCodeString(Result) + ') writing file: ' + f.fn + ' > ' + pdata^.ErrorDescription);
   end else begin
      {$IFDEF DEBUG}
      log.d('Write file: ' + f.fn);
      {$ENDIF}
   end;

   {close file if required}
   if(not handler.DoNotOpenFile) then
      f.Close();
end;

function oxTFileRW.Write(var f: TFile; const fn: StdString; options: pointer; pdata: oxPFileRWData): loopint;
var
   fd: fhTFindData;

begin
   if(fn <> '') then begin
      Writers.FindHandler(fn, fd);

      if(fd.Handler <> nil) then begin
         Result := Write(f, fd.Handler^, options, pdata);

         if(f.Error <> 0) then begin
            logIo(f, 'writing');
            exit(eIO);
         end;
      end else
         exit(eUNSUPPORTED);
   end else
      Result := eINVALID_ARG;
end;

function oxTFileRW.Write(const fn: StdString; options: pointer; pdata: oxPFileRWData): loopint;
var
   f: TFile;
   fd: fhTFindData;
   path: StdString;

begin
   if(fn <> '') then begin
      fFile.Init(f);
      Writers.FindHandler(fn, fd);

      if(fd.Handler <> nil) then begin
         path := oxPaths.Find(fn);

         if(not fd.Handler^.DoNotOpenFile) then
            f.New(path)
         else
            f.fn := fn;

         f.fn := fn;

         if(f.Error = 0) then begin
            exit(Write(f, fd.Handler^, options, pdata));
         end else begin
            logIo(f, 'opening for writing');
            exit(eIO);
         end;
      end else begin
         log.e('Could not find a handler for the file: ' + fn);
         exit(eUNSUPPORTED);
      end;
   end;

   Result := eINVALID_ARG;
end;

function oxTFileRW.OnRead(var data: oxTFileRWData): loopint;
begin
   data.Handler^.CallHandler(@data);
   Result := data.GetError();
end;

function oxTFileRW.OnWrite(var data: oxTFileRWData): loopint;
begin
   data.Handler^.CallHandler(@data);
   Result := data.GetError();
end;

END.
