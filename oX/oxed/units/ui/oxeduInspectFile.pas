{
   oxeduInspectFile, file inspector
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduInspectFile;

INTERFACE

   USES
      uStd, StringUtils,
      uFileUtils,
      {ui}
      uiWidgets,
      wdguLabel,
      {oxed}
      uOXED,
      oxeduWindow, oxeduwndInspector;

TYPE
   { oxedTInspectFile }

   oxedTInspectFile = class(oxedTInspector)
      procedure SetFile(const {%H-}fn: StdString; {%H-}fd: PFileDescriptor); virtual;

      {associate this inspector with an extension}
      procedure Associate(const extension: StdString);
   end;

   { oxedTFileInspectorAssociation }

   oxedTFileInspectorAssociation = record
      Extension: StdString;
      Inspector: oxedTInspectFile;
   end;

   oxedTFileInspectorAssociations = specialize TSimpleList<oxedTFileInspectorAssociation>;

   { oxedTInspectFileGlobal }

   oxedTInspectFileGlobal = record
      GenericInspector: oxedTInspectFile;
      Inspectors: oxedTFileInspectorAssociations;

      function FindInspectorByExtension(const ext: StdString): oxedTInspectFile;

      procedure Open(const fn: StdString; fd: PFileDescriptor = nil);
      {associate an inspector with an extension}
      procedure Associate(const extension: StdString; inspector: oxedTInspectFile);
   end;

VAR
   oxedInspectFile: oxedTInspectFileGlobal;

IMPLEMENTATION

{ oxedTInspectFileGlobal }

function oxedTInspectFileGlobal.FindInspectorByExtension(const ext: StdString): oxedTInspectFile;
var
   i: loopint;
   {$IFDEF WINDOWS}
   lext: StdString;
   {$ENDIF}

begin
   {$IFDEF WINDOWS}
   lext := LowerCase(ext);
   {$ENDIF}

   for i := 0 to Inspectors.n - 1 do begin
     {$IFDEF WINDOWS}
     if(Inspectors.List[i].Extension = lext) then
        exit(Inspectors.List[i].Inspector);
     {$ELSE}
     if(Inspectors.List[i].Extension = ext) then
        exit(Inspectors.List[i].Inspector);
     {$ENDIF}
   end;

   Result := nil;
end;

procedure oxedTInspectFileGlobal.Open(const fn: StdString; fd: PFileDescriptor);
var
   wnd: oxedTInspectorWindow;
   inspector: oxedTInspectFile;

begin
   if(not oxedInspector.GetWindow(wnd)) then
      exit;

   if(fn <> '') then begin
      {find inspector}
      inspector := FindInspectorByExtension(ExtractFileExt(fn));

      {no inspector for file found, so use global one if one is set}
      if(inspector = nil) then
         inspector := GenericInspector;

      if(inspector <> nil) then begin
         wnd.Open(inspector);
         inspector.SetFile(fn, fd);

         exit;
      end;
   end;

   wnd.Open(nil);
end;

procedure oxedTInspectFileGlobal.Associate(const extension: StdString; inspector: oxedTInspectFile);
var
   association: oxedTFileInspectorAssociation;

begin
   association.Extension := extension;
   association.Inspector := inspector;

   Inspectors.Add(association);
end;

{ oxedTInspectFile }

procedure oxedTInspectFile.SetFile(const fn: StdString; fd: PFileDescriptor);
begin
end;

procedure oxedTInspectFile.Associate(const extension: StdString);
begin
   oxedInspectFile.Associate(extension, Self);
end;

INITIALIZATION
   oxedTFileInspectorAssociations.Initialize(oxedInspectFile.Inspectors, 256);

END.
