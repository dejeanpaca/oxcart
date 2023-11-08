{
   oxeduProjectWalker, walks through project packages and files
   Copyright (C) 2020. Dejan Boras

   TODO: better handle file and directory failure (stop on fail)
}

{$INCLUDE oxheader.inc}
UNIT oxeduProjectWalker;

INTERFACE

   USES
      sysutils, uStd, uError, uLog, uFileUtils,
      {app}
      appuActionEvents,
      {ox}
      oxuRunRoutines, oxuTimer,
      {oxed}
      uOXED,
      oxeduPackage, oxeduProject,
      oxeduAssets;

TYPE
   oxedTProjectWalkerFile = record
      {complete file name (including package path)}
      FileName,
      {file name within the package}
      PackageFileName,
      {file name relative to the project path}
      ProjectFileName,
      {file extension}
      Extension,
      {path of the package}
      PackagePath: StdString;

      Package: oxedPPackage;

      fd: TFileDescriptor;
   end;

   oxedTProjectWalkerFileProcedure = procedure(var f: oxedTProjectWalkerFile);
   oxedTProjectWalkerFileProcedures = specialize TSimpleList<oxedTProjectWalkerFileProcedure>;

   { oxedTWalkerOnFileProceduresHelper }

   oxedTWalkerOnFileProceduresHelper = record helper for oxedTProjectWalkerFileProcedures
      procedure Call(var f: oxedTProjectWalkerFile);
   end;

   { oxedTProjectWalkerCurrent }

   {holds information about the current state of the project walker while a walk is being done}
   oxedTProjectWalkerCurrent = record
      Package: oxedPPackage;
      Path: StdString;

      procedure FormFile(out f: oxedTProjectWalkerFile; const fd: TFileDescriptor);
   end;

   { oxedTProjectWalker }

   oxedTProjectWalker = class
      Walker: TFileTraverse;
      Current: oxedTProjectWalkerCurrent;

      OnStart,
      OnDone: TProcedures;
      OnFile: oxedTProjectWalkerFileProcedures;

      {should we handle the oX source package}
      HandleOx,
      {should we handle the oX data package}
      HandleOxData,
      {has this task been terminated}
      Terminated: boolean;

      constructor Create(); virtual;

      {run the walker}
      procedure Run();

      {checks if the path is valid (not ignored or excluded)}
      class function ValidPath(const packagePath, fullPath: StdString): Boolean; static;
      {get valid path}
      class function GetValidPath(const basePath, fullPath: StdString): StdString; static;

      protected
         function HandleFile(var {%H-}f: oxedTProjectWalkerFile; const {%H-}fd: TFileTraverseData): boolean; virtual;
         function HandleDirectory(var {%H-}dir: StdString; const {%H-}fd: TFileTraverseData): boolean; virtual;
         function HandlePackage(var {%H-}package: oxedTPackage): boolean; virtual;
   end;

IMPLEMENTATION

function scanFile(const fd: TFileTraverseData): boolean;
var
   f: oxedTProjectWalkerFile;
   walker: oxedTProjectWalker;

begin
   Result := true;

   walker := oxedTProjectWalker(fd.ExternalData);

   walker.Current.FormFile(f, fd.f);

   if(not walker.HandleFile(f, fd)) then
      exit(false);

   walker.OnFile.Call(f);

   if(walker.Terminated) then
      exit(false);
end;

function onDirectory(const fd: TFileTraverseData): boolean;
var
   dir: StdString;
   walker: oxedTProjectWalker;

begin
   Result := true;

   walker := oxedTProjectWalker(fd.ExternalData);

   dir := oxedTProjectWalker.GetValidPath(walker.Current.Path, fd.f.Name);

   if(dir <> '') then
      walker.HandleDirectory(dir, fd)
   else
      Result := false;
end;

{ oxedTProjectWalkerCurrent }

procedure oxedTProjectWalkerCurrent.FormFile(out f: oxedTProjectWalkerFile; const fd: TFileDescriptor);
begin
   ZeroOut(f, SizeOf(f));

   f.FileName := fd.Name;
   f.Extension := ExtractFileExt(fd.Name);
   f.fd := fd;

   f.Package := Package;
   f.PackagePath := Path;
   f.PackageFileName := ExtractRelativepath(f.PackagePath, f.FileName);
   f.ProjectFileName := oxedProject.GetPackageRelativePath(f.Package^) + f.PackageFileName;
end;

{ oxedTWalkerOnFileProceduresHelper }

procedure oxedTWalkerOnFileProceduresHelper.Call(var f: oxedTProjectWalkerFile);
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      List[i](f);
   end;
end;

{ oxedTProjectWalker }

constructor oxedTProjectWalker.Create();
begin
   TFileTraverse.Initialize(Walker);

   Walker.OnFile := @scanFile;
   Walker.OnDirectory := @onDirectory;
   Walker.ExternalData := Self;

   HandleOx := true;
   HandleOxData := true;
end;

procedure oxedTProjectWalker.Run();
var
   i: loopint;
   ok: boolean;

function walkPackage(var p: oxedTPackage): boolean;
begin
   Current.Package := @p;
   Current.Path := oxedProject.GetPackagePath(p);

   Result := HandlePackage(p);

   if(not Result) then
      exit(False);

   Walker.Run(Current.Path);
end;

begin
   Terminated := false;

   try
      if(not Terminated) and (HandleOx) then
         ok := walkPackage(oxedAssets.oxPackage);

      if(not Terminated) and (HandleOxData) and (ok) then
         ok := walkPackage(oxedAssets.oxDataPackage);

      if(not Terminated) and ok then
         ok := walkPackage(oxedProject.MainPackage);

      if(ok) then begin
         for i := 0 to oxedProject.Packages.n - 1 do begin
            if(not Terminated) and ok then
               ok := walkPackage(oxedProject.Packages.List[i])
            else
               break;
         end;
      end;
   except
      on e: Exception do begin
         log.e('Failed running project walker');
         log.e(DumpExceptionCallStack(e));
      end;
   end;

   Current.Package := nil;
end;

class function oxedTProjectWalker.ValidPath(const packagePath, fullPath: StdString): Boolean;
begin
   Result := true;

   {ignore project config directory}
   if(packagePath = oxPROJECT_DIRECTORY) then
      exit(false);

   {ignore project temporary directory}
   if(packagePath = oxPROJECT_TEMP_DIRECTORY) then
      exit(false);

   {ignore folder if .noassets file is declared in it}
   if FileUtils.Exists(fullPath + DirSep + OX_NO_ASSETS_FILE) >= 0 then
      exit(False);

   {ignore directory if included in ignore lists}
   if(oxedAssets.ShouldIgnoreDirectory(packagePath)) then
      exit(False);
end;

class function oxedTProjectWalker.GetValidPath(const basePath, fullPath: StdString): StdString;
begin
   Result := Copy(fullPath, Length(basePath) + 1, Length(fullPath));

   if(not ValidPath(Result, fullPath)) then
      exit('');
end;

function oxedTProjectWalker.HandleFile(var f: oxedTProjectWalkerFile; const fd: TFileTraverseData): boolean;
begin
   Result := true;
end;

function oxedTProjectWalker.HandleDirectory(var dir: StdString; const fd: TFileTraverseData): boolean;
begin
   Result := true;
end;

function oxedTProjectWalker.HandlePackage(var package: oxedTPackage): boolean;
begin
   Result := true;
end;

END.
