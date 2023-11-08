{
   oxeduBuildAssets, oxed asset build system
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxeduBuildAssets;

INTERFACE

   USES
      sysutils, uStd, uError, uLog, uFileUtils,
      {oxed}
      uOXED,
      oxeduProject, oxeduProjectScanner, oxeduAssets, oxeduPackage;

TYPE

   { oxedTBuildAssets }

   oxedTBuildAssets = record
      Walker: TFileTraverse;

      CurrentPackage: oxedPPackage;
      CurrentPath,
      Target: StdString;

      OnFile: oxedTProjectScannerFileProcedures;

      procedure Initialize();
      {deploys asset files to the given target}
      procedure Deploy(const useTarget: StdString);
      {deploy the specified package}
      procedure DeployPackage(var p: oxedTPackage);
   end;

VAR
   oxedBuildAssets: oxedTBuildAssets;

IMPLEMENTATION

function scanFile(const fd: TFileTraverseData): boolean;
var
   ext: StdString;
   f: oxedTScannerFile;

begin
   Result := true;

   {ignore stuff in the temp directory}
   if(Pos(oxPROJECT_TEMP_DIRECTORY, fd.f.Name) = 1) then
      exit;

   ext := ExtractFileExt(fd.f.Name);
   f.Extension := ext;

   if(oxedAssets.ShouldIgnore(f.Extension)) then begin
      log.v('Ignoring: ' + fd.f.Name);
      exit;
   end;

   f.FileName := fd.f.Name;
   f.fd := fd.f;

   f.Package := oxedBuildAssets.CurrentPackage;
   f.PackagePath := oxedBuildAssets.CurrentPath;
   f.PackageFileName := ExtractRelativepath(f.PackagePath, f.FileName);
   f.ProjectFileName := oxedProject.GetPackageRelativePath(f.Package^) + f.PackageFileName;

   log.v('Deploying: ' + fd.f.Name);

   oxedBuildAssets.OnFile.Call(f);
end;

function onDirectory(const fd: TFileTraverseData): boolean;
begin
   Result := true;

   {ignore project config directory}
   if(fd.f.Name = oxedProject.Path + oxPROJECT_DIRECTORY) then
      exit(false);

   {ignore project temporary directory}
   if(fd.f.Name = oxedProject.Path + oxPROJECT_TEMP_DIRECTORY) then
      exit(false);
end;

{ oxedTBuildAssets }

procedure oxedTBuildAssets.Initialize();
begin
   TFileTraverse.Initialize(Walker);

   Walker.OnFile:= @scanFile;
   Walker.OnDirectory := @onDirectory;

   OnFile.Initialize(OnFile);
end;

procedure oxedTBuildAssets.Deploy(const useTarget: StdString);
var
   i: loopint;

begin
   Target := useTarget;
   log.i('Deploying asset files to ' + useTarget);

   try
      DeployPackage(oxedProject.MainPackage);

      for i := 0 to oxedProject.Packages.n - 1 do begin
         DeployPackage(oxedProject.Packages.List[i]);
      end;
   except
      on e: Exception do begin
         log.e('Asset deployment failed running');
         log.e(DumpExceptionCallStack(e));
      end;
   end;

   CurrentPackage := nil;

   log.v('Done assets deploy');
end;

procedure oxedTBuildAssets.DeployPackage(var p: oxedTPackage);
begin
   CurrentPackage := @p;
   CurrentPath := oxedProject.GetPackagePath(p);

   log.v('Deploying package: ' + CurrentPath);
   Walker.Run(oxedBuildAssets.CurrentPath);
end;

procedure init();
begin
   oxedBuildAssets.Initialize();
end;

INITIALIZATION
   oxed.Init.Add('build_assets', @init);

END.
