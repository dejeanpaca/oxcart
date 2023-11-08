{
   oxeduBuildAssetsYPK, deploys assets into an ypk file
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduBuildAssetsYPK;

INTERFACE

   USES
      uStd, sysutils, uFileUtils, StringUtils,
      ypkuBuilder,
      {oxed}
      uOXED, oxeduProjectWalker,
      oxeduBuild, oxeduBuildLog, oxeduBuildAssets;

TYPE

   { oxedTYPKAssetsDeployer }

   oxedTYPKAssetsDeployer = class(oxedTAssetsDeployer)
      Builder: ypkTBuilder;

      constructor Create();

      procedure OnStart(); override;
      procedure OnDone(); override;

      function OnFile(var f: oxedTAssetBuildFile; var {%H-}sf: oxedTProjectWalkerFile): boolean; override;
   end;

VAR
   oxedYPKAssetsDeployer: oxedTYPKAssetsDeployer;

IMPLEMENTATION

procedure init();
begin
   oxedYPKAssetsDeployer := oxedTYPKAssetsDeployer.Create();
end;

procedure deinit();
begin
   if(oxedYPKAssetsDeployer <> nil) then begin
      oxedYPKAssetsDeployer.Builder.Dispose();
      FreeObject(oxedYPKAssetsDeployer);
   end;
end;

{ oxedTYPKAssetsDeployer }

constructor oxedTYPKAssetsDeployer.Create();
begin
   ypkTBuilder.Initialize(Builder);
end;

procedure oxedTYPKAssetsDeployer.OnStart();
begin
   Builder.Reset();
   Builder.OutputFN := IncludeTrailingPathDelimiterNonEmpty(oxedBuildAssets.Target) + 'data.ypk';
end;

procedure oxedTYPKAssetsDeployer.OnDone();
begin
   oxedBuildLog.i('Building ypk file to: ' + Builder.OutputFN);

   if(Builder.Build()) then
      oxedBuildLog.k('Built ypk file: ' + Builder.OutputFN)
   else begin
      oxedBuildLog.e('Failed building ypk file: ' + Builder.OutputFN);
      oxedBuildLog.e('Error: ' + Builder.ErrorDescription);
   end;
end;

function oxedTYPKAssetsDeployer.OnFile(var f: oxedTAssetBuildFile; var sf: oxedTProjectWalkerFile): boolean;
begin
   Builder.AddFile(f.Source, f.Target);
   Result := true;
end;

INITIALIZATION
   oxed.Init.Add('ypk_assets_deployer', @init, @deinit);

END.
