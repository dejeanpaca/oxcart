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
   oxedTAssetBuildFile = record
      {currently used package}
      CurrentPackage: oxedPPackage;

      {source path, includes package path (or full path to the transformed file)}
      Source,
      {full destination path}
      Target: StdString;
   end;

   {this class handles deploying the actual assets, after they've been processed}

   { oxedTAssetsDeployer }

   oxedTAssetsDeployer = class
      {called when starting deploy}
      procedure OnStart(); virtual;
      {called when deploy is done}
      procedure OnDone(); virtual;

      function OnFile(var {%H-}f: oxedTAssetBuildFile; var sf: oxedTScannerFile): boolean; virtual;
   end;

   { oxedTBuildAssets }

   oxedTBuildAssets = record
      Walker: TFileTraverse;

      FileCount: loopint;


      Current: oxedTProjectScannerCurrent;

      {target path where assets will go}
      Target,
      {target path with the provided suffix}
      CurrentTarget,
      {use a suffix with the target path (if you want to override the target path)}
      TargetSuffix: StdString;

      {called before assets are deployed (hook your deployer here)}
      PreDeploy: TProcedures;
      {called when a file is handled}
      OnFile: oxedTProjectScannerFileProcedures;

      {currently used assets deployer}
      Deployer,
      {default deployer set on every build}
      DefaultDeployer: oxedTAssetsDeployer;

      procedure Initialize();
      {deploys asset files to the given target}
      procedure Deploy(const useTarget: StdString);
      {deploy the specified package}
      procedure DeployPackage(var p: oxedTPackage);
   end;

VAR
   oxedBuildAssets: oxedTBuildAssets;

IMPLEMENTATION

{ oxedTAssetsDeployer }

procedure oxedTAssetsDeployer.OnStart();
begin

end;

procedure oxedTAssetsDeployer.OnDone();
begin

end;

function oxedTAssetsDeployer.OnFile(var f: oxedTAssetBuildFile; var sf: oxedTScannerFile): boolean;
begin
   Result := true;
end;

function scanFile(const fd: TFileTraverseData): boolean;
var
   f: oxedTScannerFile;
   aF: oxedTAssetBuildFile;

   source,
   target: StdString;

begin
   Result := true;

   {ignore stuff in the temp directory}
   if(Pos(oxPROJECT_TEMP_DIRECTORY, fd.f.Name) = 1) then
      exit;

   oxedBuildAssets.Current.FormFile(f, fd.f);

   if(oxedAssets.ShouldIgnore(f.Extension)) then begin
      consoleLog.v('Ignoring: ' + fd.f.Name);
      exit;
   end;

   oxedBuildLog.v('Deploying: ' + fd.f.Name);

   source := f.PackagePath + f.PackageFileName;
   target := oxedBuildAssets.CurrentTarget + f.PackageFileName;

   ZeroOut(aF, SizeOf(aF));

   aF.Source := source;
   aF.Target := target;

   aF.CurrentPackage := oxedBuildAssets.Current.Package;

   if not oxedBuildAssets.Deployer.OnFile(aF, f) then
      exit(False);

   inc(oxedBuildAssets.FileCount);

   oxedBuildAssets.OnFile.Call(f);
end;

function onDirectory(const fd: TFileTraverseData): boolean;
var
   dir: StdString;
   pp: oxedPPackagePath;

begin
   Result := true;

   dir := oxedProjectScanner.GetValidPath(oxedBuildAssets.Current.Path, fd.f.Name);

   if(dir <> '') then begin
      {Find closest package path, and skip if optional}
      pp := oxedBuildAssets.Current.Package^.Paths.FindClosest(dir);

      if(pp <> nil) and (pp^.IsOptional()) then begin
         oxedBuildLog.v('Optional: ' + dir);
         exit(False);
      end;
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

   Deployer := DefaultDeployer;

   FileCount := 0;

   PreDeploy.Call();

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

   Current.Package := nil;

   oxedBuildLog.i('Done assets deploy (files: ' + sf(FileCount) + ')');
end;

procedure oxedTBuildAssets.DeployPackage(var p: oxedTPackage);
begin
   Current.Package := @p;
   Current.Path := oxedProject.GetPackagePath(p);

   if(TargetSuffix = '') then
      CurrentTarget := Target
   else
      CurrentTarget := IncludeTrailingPathDelimiter(Target + TargetSuffix);

   oxedBuildLog.v('Deploying package: ' + Current.Path);
   Walker.Run(oxedBuildAssets.Current.Path);

   TargetSuffix := '';
end;

procedure init();
begin
   oxedBuildAssets.Initialize();
end;

INITIALIZATION
   oxed.Init.Add('build_assets', @init);

END.
