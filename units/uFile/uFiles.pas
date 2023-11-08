{
   uFiles, handles standard file operations for some basic file types
   Copyright (C) 2011. Dejan Boras
}

{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH ADVANCEDRECORDS}
UNIT uFiles;

INTERFACE

   USES
      uStd, uFileUtils, uFile,
      ufhStandard, ufhMemory, ufhSub;

TYPE
   TFileOperationsHelper = record helper for TFile
     {standard file}
     procedure Open(var h: TFileStdHandler; const fName: StdString);
     procedure Open(const fName: StdString);
     procedure New(var h: TFileStdHandler; const fName: StdString);
     procedure New(const fName: StdString);

     {memory file}
     procedure Open(var h: TFileMemHandler; mem: pointer; size: fileint);
     procedure Open(mem: pointer; size: fileint);
     procedure New(var h: TFileMemHandler; size: fileint);
     procedure New(size: fileint);

     {sub file}
     procedure Open(var h: TFileSubHandler; var parent: TFile; pos, size: fileint);
     procedure Open(var parent: TFile; pos, size: fileint);
     procedure New(var h: TFileSubHandler; var parent: TFile; pos, size: fileint);
     procedure New(var parent: TFile; pos, size: fileint);
   end;

function fGetString(const fn: StdString): StdString;

IMPLEMENTATION

function fGetString(const fn: StdString): StdString;
var
   f: TFile;

begin
   Result := '';

   fFile.Init(f);
   f.Open(fn);

   if(f.Error = 0) then
      Result := f.GetString();

   f.Close();
end;

{ STANDARD FILE }

procedure TFileOperationsHelper.Open(var h: TFileStdHandler; const fName: StdString);
begin
   Assert(@h <> nil, 'Fatal: An nil standard file handler was specified');
   Assert(h.Handler <> nil, 'Fatal: No handler object assigned for standard file');

   {$IFNDEF FILE_NOFS}
   if(fFile.fsExists(fName) > -1) then begin
      fFile.fsOpen(self, fName);
      exit;
   end;
   {$ENDIF}

   SetDefaults(fcfREAD, fName);

   {assign a standard file handler}
   AssignHandler(h.Handler^);

   if(Error = 0) then begin
      pHandler^.Open(self);

      if(Error <> 0) then
         Dispose();
   end;
end;

procedure TFileOperationsHelper.Open(const fName: StdString);
begin
   Assert(fFile.Handlers.Std <> nil, 'Fatal: fStdFileHandler is nil');

   Open(fFile.Handlers.Std^, fName);
end;

procedure TFileOperationsHelper.New(var h: TFileStdHandler; const fName: StdString);
begin
   Assert(@h <> nil, 'Fatal: An nil standard file handler was specified');

   SetDefaults(fcfWRITE, fName);

   {assign a standard file handler}
   AssignHandler(h.Handler^);

   if(Error = 0) then
      pHandler^.New(self);
end;

procedure TFileOperationsHelper.New(const fName: StdString);
begin
   Assert(fFile.Handlers.Std <> nil, 'Fatal: fStdFileHandler is nil');

   New(fFile.Handlers.Std^, fName);
end;

{ MEMORY FILE }

procedure TFileOperationsHelper.Open(var h: TFileMemHandler; mem: pointer; size: fileint);
begin
   Assert(@h <> nil, 'Fatal: A invalid memory file handler was specified');

   {set defaults}
   SetDefaults(fcfREAD, '');

   {assign a standard file handler}
   AssignHandler(h.Handler^);

   if(Error = 0) then begin
      {setup the file}
      h.Open(self, mem, size);

      {open the file}
      pHandler^.Open(self);

      if(Error <> 0) then
         Dispose();
   end;
end;

procedure TFileOperationsHelper.Open(mem: pointer; size: fileint);
begin
   Assert(fFile.Handlers.Mem <> nil, 'Fatal: fMemFileHandler is nil');

   Open(fFile.Handlers.Mem^, mem, size);
end;

procedure TFileOperationsHelper.New(var h: TFileMemHandler; size: fileint);
begin
   Assert(@h <> nil, 'Fatal: A nil memory file handler was specified');

   SetDefaults(fcfWRITE, '');

   {assign a memory handler}
   AssignHandler(h.Handler^);
   if(Error = 0) then begin
      {create a new file}
      h.New(self, size);
      pHandler^.New(self);
   end;
end;

procedure TFileOperationsHelper.New(size: fileint);
begin
   Assert(@fFile.Handlers.Mem <> nil, 'Fatal: fMemFileHandler is nil');

   New(fFile.Handlers.Mem^, size);
end;

{ SUB FILE }

procedure TFileOperationsHelper.Open(var h: TFileSubHandler; var parent: TFile; pos, size: fileint);
begin
   Assert(@h <> nil, 'Fatal: A invalid sub file handler was specified');

   {set defaults}
   SetDefaults(fcfREAD, '');

   {assign a standard file handler}
   AssignHandler(h.Handler^);

   if(Error = 0) then begin
      {setup the file}
      h.Open(self, parent, pos, size);

      {open the file}
      pHandler^.Open(self);
      if(Error <> 0) then
         Dispose();
   end;
end;

procedure TFileOperationsHelper.Open(var parent: TFile; pos, size: fileint);
begin
   Assert(fFile.Handlers.Sub <> nil, 'Fatal: fSubFileHandler is nil');

   Open(fFile.Handlers.Sub^, parent, pos, size);
end;

procedure TFileOperationsHelper.New(var h: TFileSubHandler; var parent: TFile; pos, size: fileint);
begin
   Assert(@h <> nil, 'Fatal: A nil sub file handler was specified');

   SetDefaults(fcfWRITE, '');

   {assign a memory handler}
   AssignHandler(h.Handler^);

   if(Error = 0) then begin
      {create a new file}
      h.New(self, parent, pos, size);
      pHandler^.New(self);
   end;
end;

procedure TFileOperationsHelper.New(var parent: TFile; pos, size: fileint);
begin
   Assert(@fFile.Handlers.Sub <> nil, 'Fatal: fSubFileHandler is nil');

   New(fFile.Handlers.Sub^, parent, pos, size);
end;

END.
