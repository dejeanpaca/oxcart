{
   oxeduBuildAssetsManager, manages asset builder
   Copyright (C) 2021. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduBuildAssetsManager;

INTERFACE

   USES
      {oxed}
      uOXED, oxeduProject,
      {build}
      oxeduBuildAssets,
      oxeduBuildAssetsCopy, oxeduBuildAssetsYPK;

IMPLEMENTATION

procedure useDeployer();
begin
   if(not oxedProject.Assets.Pack) then
      oxedBuildAssets.UseDeployer(oxedCopyAssetsDeployer)
   else
      oxedBuildAssets.UseDeployer(oxedYPKAssetsDeployer);
end;

INITIALIZATION
   oxedTBuildAssets.OnUseDeployer := @useDeployer;

END.
