{
   uDirectoryCopier, directory copying utilities
   Copyright (C) 2021. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT uDirectoryCopier;

INTERFACE

   USES
      sysutils,
      uStd, StringUtils, uFileUtils, uFileTraverse;


TYPE
   PDirectoryCopierData = ^TDirectoryCopierData;
   PDirectoryCopier = ^TDirectoryCopier;

   TDirectoryCopierData = record
      TraverseData: PFileTraverseData;
      Copier: PDirectoryCopier;
      ExternalData: pointer;
   end;

   { TDirectoryCopier }

   TDirectoryCopier = record
      Walker: TFileTraverse;
      {your own external data}
      ExternalData: Pointer;

      {called when a file is found with matching extension (if any), if returns false traversal is stopped}
      OnFile: function(const f: TDirectoryCopierData): boolean;
      OnDirectory: function(const f: TDirectoryCopierData): boolean;

      Source,
      Destination: StdString;

      function Copy(const sourceDir, destinationDir: StdString): loopint;

      class procedure Initialize(out copier: TDirectoryCopier); static;
   end;

{copy a file from source to destination}
function CopyDirectory(const source, destination: StdString): longint;

IMPLEMENTATION

function copyOnDirectory(const f: TFileTraverseData): boolean;
var
   data: PDirectoryCopier;
   cd: TDirectoryCopierData;
   path: StdString;

begin
   data := f.ExternalData;

   if(data^.OnFile <> nil) then begin
      cd.ExternalData := data^.ExternalData;
      cd.Copier := data;
      cd.TraverseData := @f;

      Result := data^.OnDirectory(cd);
   end else
      Result := true;

   if(Result) then begin
      path := data^.Destination + ExtractRelativepath(data^.Source, f.f.Name);

      if(not CreateDir(path)) then
         Result := false;
   end;
end;

function copyOnFile(const f: TFileTraverseData): boolean;
var
   data: PDirectoryCopier;
   cd: TDirectoryCopierData;
   path: string;

begin
   data := f.ExternalData;

   if(data^.OnFile <> nil) then begin
      cd.ExternalData := data^.ExternalData;
      cd.Copier := data;
      cd.TraverseData := @f;

      Result := data^.OnFile(cd);
   end else
      Result := true;

   if(Result) then begin
      path := ExtractRelativepath(data^.Source, f.f.Name);

      if(FileUtils.Copy(data^.Source + path, data^.Destination + path) < 0) then
         Result := false;
   end;
end;

function CopyDirectory(const source, destination: StdString): longint;
var
   copier: TDirectoryCopier;

begin
   TDirectoryCopier.Initialize(copier);

   Result := copier.Copy(source, Destination);
//   copier.Destroy();
end;

{ TDirectoryCopier }

function TDirectoryCopier.Copy(const sourceDir, destinationDir: StdString): loopint;
begin
   Result := 0;

   if DirectoryExists(sourceDir) then begin
      {create target directory}
      if CreateDir(destinationDir) then begin
         Source := IncludeTrailingPathDelimiterNonEmpty(sourceDir);
         Destination := IncludeTrailingPathDelimiterNonEmpty(destinationDir);

         Walker.ExternalData := @Self;
         Walker.OnFile := @copyOnFile;
         Walker.OnDirectory := @copyOnDirectory;

         Walker.Run(sourceDir);
      end else
         Result := eIO
   end else
      {no source directory, nothing to do}
      Result := eNOT_FOUND;

   ioErrorIgn();
end;

class procedure TDirectoryCopier.Initialize(out copier: TDirectoryCopier);
begin
   TFileTraverse.Initialize(copier.Walker);
   copier.ExternalData := nil;
   copier.Source := '';
   copier.Destination := '';
   copier.OnFile := nil;
   copier.OnDirectory := nil;
end;

END.
