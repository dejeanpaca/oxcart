{
   oxuModel, oX model management and operations
   Copyright (C) 2017. Dejan Boras

   Started On:    31.05.2007.
}

{$INCLUDE oxdefines.inc}
UNIT oxuModel;

INTERFACE

   USES
      uStd, sysutils, vmVector, vmBBox,
      {oX}
      oxuMaterial, oxuSkins, oxuTypes, oxuMesh, oxuTexture, oxuTexturePool;

TYPE
   oxTModelRenderData = record
      skin: loopint;
   end;

   { oxTModel }

   oxTModel = class(oxTResource)
      Name: string;

      {all the meshes}
      Meshes: oxTMeshes;
      {all the materials used by this model}
      Materials: oxTMaterials;
      {materials sorted into skins (there should always be at least one by default)}
      Skins: oxTSkinList;

      constructor Create(); override;

      function GetSkin(): oxPSkin;
      function GetTexture(const textureName: string): oxTTexture;
      function GetTexture(): oxTTexture;

      function AddMesh(): oxPMesh;
      function GetLastMesh(): oxPMesh;
      function GetLastSkin(): oxPSkin;
      function GetLastMaterial(): oxTMaterial;

      procedure Render(var rd: oxTModelRenderData);

      procedure GetBoundingBox(out bbox: TBoundingBox);
   end;

   { oxTModelGlobal }

   oxTModelGlobal = record
      function Instance(): oxTModel;
   end;

VAR
   oxModel: oxTModelGlobal;

IMPLEMENTATION

{ oxTModelGlobal }

function oxTModelGlobal.Instance(): oxTModel;
begin
   Result := oxTModel.Create();
end;

{ oxTModel }

constructor oxTModel.Create();
begin
   inherited Create();

   Materials.Initialize(Materials);
   Meshes.Initialize(Meshes);
   Skins.Initialize(Skins);
end;

function oxTModel.GetSkin(): oxPSkin;
var
   skin: oxTSkin;

begin
   if(Skins.n = 0) then begin
      oxTSkin.Init(skin);
      Skins.Add(skin);
   end;

   Result := @Skins.List[0];
end;

function oxTModel.GetTexture(const textureName: string): oxTTexture;
begin
   Result := oxTTexture(oxTexturePool.FindByPath(textureName));

   if(Result = nil) then
      Result := GetTexture();
end;

function oxTModel.GetTexture(): oxTTexture;
begin
   Result := oxTTexture.Create();
   oxTexturePool.Add(Result)
end;

function oxTModel.AddMesh(): oxPMesh;
var
   mesh: oxTMesh;

begin
   oxTMesh.Init(mesh);
   Meshes.Add(mesh);
   Result := @Meshes.List[Meshes.n - 1];
end;

function oxTModel.GetLastMesh(): oxPMesh;
begin
   if(Meshes.n > 0) then
      Result := @Meshes.List[Meshes.n - 1]
   else
      Result := nil;
end;

function oxTModel.GetLastSkin(): oxPSkin;
begin
   if(Skins.n > 0) then
      Result := @Skins.List[Skins.n - 1]
   else
      Result := nil;
end;

function oxTModel.GetLastMaterial(): oxTMaterial;
begin
   if(Materials.n > 0) then
      Result := Materials.List[Materials.n - 1]
   else
      Result := nil;
end;

procedure oxTModel.Render(var rd: oxTModelRenderData);
var
   i: loopint;
   pSkin: oxPSkin;
   mat: oxTMaterial;

begin
   assert((rd.skin >= 0) and (rd.skin < Skins.n), 'rendering skin out of bounds');

   pSkin := @Skins.List[rd.skin];

   for i := 0 to Meshes.n - 1 do begin
      if(i < pSkin^.Materials.n) then
         mat := pSkin^.Materials.List[i]
      else
         mat := oxMaterial.Default;

      mat.Apply();

      {TODO: Render mesh}
   end;
end;

procedure oxTModel.GetBoundingBox(out bbox: TBoundingBox);
var
   i: loopint;
   tempBox: TBoundingBox;

begin
   bbox := vmBBoxZero;

   for i := 0 to Meshes.n - 1 do begin
      Meshes.List[0].GetBoundingBox(tempBox);
      bbox.Expand(tempBox);
   end;
end;

END.
