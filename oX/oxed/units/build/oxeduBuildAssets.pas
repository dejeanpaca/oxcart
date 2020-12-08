{
   oxeduBuildAssets, oxed asset build system
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduBuildAssets;

INTERFACE

   USES
      sysutils, uStd, uLog, uFileUtils, StringUtils,
      {oxed}
      uOXED, oxeduBuildLog,
      oxeduPackage, oxeduPackageTypes,
      oxeduProject, oxeduProjectScanner, oxeduProjectWalker,
      oxeduAssets, oxeduConsole;

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

      function OnFile(var {%H-}f: oxedTAssetBuildFile; var {%H-}sf: oxedTProjectWalkerFile): boolean; virtual;
   end;

   { oxedTBuildAssets }

   oxedTBuildAssets = class(oxedTProjectWalker)
      FileCount: loopint;

      {target path where assets will go}
      Target,
      {target path with the provided suffix}
      CurrentTarget,
      {use a suffix with the target path (if you want to override the target path)}
      TargetSuffix: StdString;

      {called before assets are deployed (hook your deployer here)}
      PreDeploy: TProcedures;

      {currently used assets deployer}
      Deployer,
      {default deployer set on every build}
      DefaultDeployer: oxedTAssetsDeployer;

      constructor Create(); override;

      {deploys asset files to the given target}
      procedure Deploy(const useTarget: StdString);

      protected
         function HandleFile(var f: oxedTProjectWalkerFile; const fd: TFileTraverseData): boolean; override;
         function HandleDirectory(var dir: StdString; const {%H-}fd: TFileTraverseData): boolean; override;
         function HandlePackage(var package: oxedTPackage): boolean; override;
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

function oxedTAssetsDeployer.OnFile(var f: oxedTAssetBuildFile; var sf: oxedTProjectWalkerFile): boolean;
begin
   Result := true;
end;

{ oxedTBuildAssets }

constructor oxedTBuildAssets.Create();
begin
   inherited;

   HandleOx := false;
end;

procedure oxedTBuildAssets.Deploy(const useTarget: StdString);
begin
   Target := IncludeTrailingPathDelimiter(useTarget);
   oxedBuildLog.i('Deploying asset files to ' + useTarget);
   Deployer := DefaultDeployer;
   FileCount := 0;

   PreDeploy.Call();

   Run();

   oxedBuildLog.i('Done assets deploy (files: ' + sf(FileCount) + ')');
end;

function oxedTBuildAssets.HandleFile(var f: oxedTProjectWalkerFile; const fd: TFileTraverseData): boolean;
var
   aF: oxedTAssetBuildFile;

begin
   Result := true;

   if(oxedAssets.ShouldIgnore(f.Extension)) then begin
      consoleLog.v('Ignoring: ' + fd.f.Name);
      exit(True);
   end;

   oxedBuildLog.v('Deploying: ' + fd.f.Name);

   ZeroOut(aF, SizeOf(aF));

   aF.Source := f.PackagePath + f.PackageFileName;
   aF.Target := oxedBuildAssets.CurrentTarget + f.PackageFileName;

   aF.CurrentPackage := oxedBuildAssets.Current.Package;

   if not oxedBuildAssets.Deployer.OnFile(aF, f) then
      exit(False);

   inc(oxedBuildAssets.FileCount);
end;

function oxedTBuildAssets.HandleDirectory(var dir: StdString; const fd: TFileTraverseData): boolean;
var
   pp: oxedPPackagePath;

begin
   Result := true;

   {find closest package path, and skip if optional}
   pp := oxedBuildAssets.Current.Package^.Paths.FindClosest(dir);

   if(pp <> nil) and (pp^.IsOptional()) then begin
      oxedBuildLog.v('Optional: ' + dir);
      exit(False);
   end;
end;

function oxedTBuildAssets.HandlePackage(var package: oxedTPackage): boolean;
begin
   Result := true;

   oxedBuildLog.v('Deploying package: ' + Current.Path);

   if(@package = @oxedAssets.oxDataPackage) then begin
      CurrentTarget := IncludeTrailingPathDelimiter(Target + TargetSuffix);
      TargetSuffix := 'data';
   end else begin
      TargetSuffix := '';
      CurrentTarget := Target;
   end;
end;

procedure initialize();
begin
   oxedBuildAssets := oxedTBuildAssets.Create();
end;

procedure deinitialize();
begin
   FreeObject(oxedBuildAssets);
end;

INITIALIZATION
   oxed.Init.Add('build_assets', @initialize, @deinitialize);

END.
