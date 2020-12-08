{
   oxeduProjectWalker, walks through project packages and files
   Copyright (C) 2020. Dejan Boras
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
      oxeduPackage, oxeduPackageTypes, oxeduProject,
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

      {has this task been terminated}
      Terminated: boolean;

      constructor Create(); virtual;

      procedure Run();

      {checks if the path is valid (not ignored or excluded)}
      class function ValidPath(const packagePath, fullPath: StdString): Boolean; static;
      {get valid path}
      class function GetValidPath(const basePath, fullPath: StdString): StdString; static;
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
   walker.OnFile.Call(f);

   if(walker.Terminated) then
      exit(false);
end;

function onDirectory(const fd: TFileTraverseData): boolean;
var
   dir: StdString;
   path: oxedPPackagePath;
   walker: oxedTProjectWalker;

begin
   Result := true;

   walker := oxedTProjectWalker(fd.ExternalData);

   dir := oxedTProjectWalker.GetValidPath(walker.Current.Path, fd.f.Name);

   if(dir <> '') then begin
      {load package path properties if we have any}
      if(FileExists(fd.f.Name + DirSep + OX_PACKAGE_PROPS_FILE_NAME)) then begin
         path := walker.Current.Package^.Paths.Get(dir);
         path^.LoadPathProperties(walker.Current.Path);
      end;
   end else
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
end;

procedure oxedTProjectWalker.Run();
var
   i: loopint;

procedure walkPackage(var p: oxedTPackage);
begin
   Current.Package := @p;
   Current.Path := oxedProject.GetPackagePath(p);

   Walker.Run(Current.Path);
end;

begin
   try
      if(not Terminated) then
         walkPackage(oxedAssets.oxPackage);

      if(not Terminated) then
         walkPackage(oxedAssets.oxDataPackage);

      if(not Terminated) then
         walkPackage(oxedProject.MainPackage);

      for i := 0 to oxedProject.Packages.n - 1 do begin
         if(not Terminated) then
            walkPackage(oxedProject.Packages.List[i])
         else
            break;
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

END.
