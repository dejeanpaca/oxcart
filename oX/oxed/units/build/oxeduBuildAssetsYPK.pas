{
   oxeduBuildAssetsYPK, deploys assets into an ypk file
   Copyright (C) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduBuildAssetsYPK;

INTERFACE

   USES
      uStd, sysutils, uFileUtils,
      {oxed}
      uOXED, oxeduYPK, oxeduProjectWalker,
      oxeduBuild, oxeduBuildLog, oxeduBuildAssets;

TYPE

   { oxedTYPKAssetsDeployer }

   oxedTYPKAssetsDeployer = class(oxedTAssetsDeployer)
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
   FreeObject(oxedYPKAssetsDeployer);
end;

{ oxedTYPKAssetsDeployer }

procedure oxedTYPKAssetsDeployer.OnStart();
begin
   oxedYPK.Builder.Reset();
   oxedYPK.Builder.OutputFN := IncludeTrailingPathDelimiter(oxedBuildAssets.Target) + 'data.ypk';
end;

procedure oxedTYPKAssetsDeployer.OnDone();
begin
   oxedYPK.Builder.Build();
end;

function oxedTYPKAssetsDeployer.OnFile(var f: oxedTAssetBuildFile; var sf: oxedTProjectWalkerFile): boolean;
begin
   oxedYPK.Builder.AddFile(f.Source, f.Target);
   Result := true;
end;

INITIALIZATION
   oxed.Init.Add('ypk_assets_deployer', @init, @deinit);

END.
