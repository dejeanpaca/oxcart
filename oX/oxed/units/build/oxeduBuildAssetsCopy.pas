{
   oxeduBuildAssetsCopy, plain copy file asset deployer
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduBuildAssetsCopy;

INTERFACE

   USES
      uStd, sysutils, uFileUtils,
      {oxed}
      uOXED, oxeduProjectScanner,
      oxeduBuild, oxeduBuildLog, oxeduBuildAssets;

TYPE

   { oxedTCopyAssetsDeployer }

   oxedTCopyAssetsDeployer = class(oxedTAssetsDeployer)
      function OnFile(var f: oxedTAssetBuildFile; var {%H-}sf: oxedTScannerFile): boolean; override;
   end;

VAR
   oxedCopyAssetsDeployer: oxedTCopyAssetsDeployer;

IMPLEMENTATION

procedure init();
begin
   oxedCopyAssetsDeployer := oxedTCopyAssetsDeployer.Create();
   oxedBuildAssets.Deployer := oxedCopyAssetsDeployer;
   oxedBuildAssets.DefaultDeployer := oxedCopyAssetsDeployer;
end;

procedure deinit();
begin
   FreeObject(oxedCopyAssetsDeployer);
   oxedBuildAssets.Deployer := nil;
end;

{ oxedTCopyAssetsDeployer }

function oxedTCopyAssetsDeployer.OnFile(var f: oxedTAssetBuildFile; var sf: oxedTScannerFile): boolean;
var
   target: StdString;

begin
   target := ExtractFilePath(f.Target);
   Result := false;

   {create directories required for target file, and quit if we fail}
   if(not sysutils.ForceDirectories(target)) then begin
      oxedBuildLog.e('Failed to create target directory ' + target);
      exit(false);
   end;

   if(FileUtils.Copy(f.Source, f.Target) < 0) then begin
      oxedBuildLog.e('Failed to copy source file (' + f.Source + ') to target (' + f.Target + ')');
      exit(false);
   end;

   Result := true;
end;

INITIALIZATION
   oxed.Init.Add('copy_assets_deployer', @init, @deinit);

END.
