{
   oxeduBuildAssets, oxed asset build system
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduBuildAssets;

INTERFACE

   USES
      sysutils, uStd, uError, uLog, uFileUtils, StringUtils,
      {oxed}
      uOXED, oxeduBuildLog,
      oxeduPackage, oxeduPackageTypes,
      oxeduProject, oxeduProjectScanner, oxeduAssets, oxeduConsole;

TYPE

   { oxedTBuildAssets }

   oxedTBuildAssets = record
      Walker: TFileTraverse;

      FileCount: loopint;

      CurrentPackage: oxedPPackage;
      CurrentPath,
      {target path}
      Target,
      {target path with the provided suffix}
      CurrentTarget,
      {use a suffix with the target path (if you want to override the target path)}
      TargetSuffix: StdString;

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

   source,
   target: StdString;

begin
   Result := true;

   {ignore stuff in the temp directory}
   if(Pos(oxPROJECT_TEMP_DIRECTORY, fd.f.Name) = 1) then
      exit;

   ext := ExtractFileExt(fd.f.Name);
   f.Extension := ext;

   if(oxedAssets.ShouldIgnore(f.Extension)) then begin
      consoleLog.v('Ignoring: ' + fd.f.Name);
      exit;
   end;

   f.FileName := fd.f.Name;
   f.fd := fd.f;

   f.Package := oxedBuildAssets.CurrentPackage;
   f.PackagePath := oxedBuildAssets.CurrentPath;
   f.PackageFileName := ExtractRelativepath(f.PackagePath, f.FileName);
   f.ProjectFileName := oxedProject.GetPackageRelativePath(f.Package^) + f.PackageFileName;

   oxedBuildLog.v('Deploying: ' + fd.f.Name);

   source := f.PackagePath + f.PackageFileName;
   target := oxedBuildAssets.CurrentTarget + f.PackageFileName;

   {create directories required for target file, and quit if we fail}
   if(not sysutils.ForceDirectories(ExtractFilePath(target))) then
      Result := false;

   if(FileUtils.Copy(source, target) < 0) then begin
      oxedBuildLog.e('Failed to copy source file (' + source + ') to target (' + target + ')');
      Result := false;
   end;

   inc(oxedBuildAssets.FileCount);

   oxedBuildAssets.OnFile.Call(f);
end;

function onDirectory(const fd: TFileTraverseData): boolean;
var
   dir: StdString;
   pp: oxedPPackagePath;

begin
   Result := true;

   dir := oxedProjectScanner.GetValidPath(oxedBuildAssets.CurrentPath, fd.f.Name);

   if(dir <> '') then begin
      {Find closest package path, and skip if optional}
      pp := oxedBuildAssets.CurrentPackage^.Paths.FindClosest(dir);

      if(pp <> nil) and (pp^.IsOptional()) then
         exit(False);
   end else
      Result := false;
end;

{ oxedTBuildAssets }

procedure oxedTBuildAssets.Initialize();
begin
   TFileTraverse.Initialize(Walker);

   Walker.OnFile := @scanFile;
   Walker.OnDirectory := @onDirectory;

   OnFile.Initialize(OnFile);
end;

procedure oxedTBuildAssets.Deploy(const useTarget: StdString);
var
   i: loopint;

begin
   Target := IncludeTrailingPathDelimiter(useTarget);
   oxedBuildLog.i('Deploying asset files to ' + useTarget);

   FileCount := 0;

   try
      {deploy assets from ox, but only those in the data directory}
      TargetSuffix := 'data';

      DeployPackage(oxedAssets.oxDataPackage);

      {deploy assets from packages}
      for i := 0 to oxedProject.Packages.n - 1 do begin
         DeployPackage(oxedProject.Packages.List[i]);
      end;

      {deploy assets from project}
      DeployPackage(oxedProject.MainPackage);
   except
      on e: Exception do begin
         oxedBuildLog.e('Asset deployment failed running');
         oxedBuildLog.e(DumpExceptionCallStack(e));
      end;
   end;

   CurrentPackage := nil;

   oxedBuildLog.i('Done assets deploy (files: ' + sf(FileCount) + ')');
end;

procedure oxedTBuildAssets.DeployPackage(var p: oxedTPackage);
begin
   CurrentPackage := @p;
   CurrentPath := oxedProject.GetPackagePath(p);

   if(TargetSuffix = '') then
      CurrentTarget := Target
   else
      CurrentTarget := IncludeTrailingPathDelimiter(Target + TargetSuffix);

   oxedBuildLog.v('Deploying package: ' + CurrentPath);
   Walker.Run(oxedBuildAssets.CurrentPath);

   TargetSuffix := '';
end;

procedure init();
begin
   oxedBuildAssets.Initialize();
end;

INITIALIZATION
   oxed.Init.Add('build_assets', @init);

END.
