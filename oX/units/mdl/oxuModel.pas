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

      procedure GetBoundingBox(out bbox: TBoundingBox);

      {center the mesh to 0, 0, 0 origin}
      procedure Center();
      {translate the model by the given amount}
      procedure Translate(x, y, z: single);
      {scale all model meshes by the given factor}
      procedure Scale(x, y, z: single);
      {rotate all model meshes by the given angles around origin (0, 0, 0)}
      procedure Rotate(x, y, z: single);
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

procedure oxTModel.Center();
var
   bbox: TBoundingBox;
   offset: TVector3f;

begin
   GetBoundingBox(bbox);

   offset := vmvZero3f - ((bbox[1] + bbox[0]) / 2);

   Translate(offset[0], offset[1], offset[2]);
end;

procedure oxTModel.Translate(x, y, z: single);
var
   i: loopint;

begin
   for i := 0 to Meshes.n - 1 do begin
      Meshes.List[i].Translate(x, y, z);
   end;
end;

procedure oxTModel.Scale(x, y, z: single);
var
   i: loopint;

begin
   for i := 0 to Meshes.n - 1 do begin
      Meshes.List[i].Scale(x, y, z);
   end;
end;

procedure oxTModel.Rotate(x, y, z: single);
var
   i: loopint;

begin
   for i := 0 to Meshes.n - 1 do begin
      Meshes.List[i].Rotate(x, y, z);
   end;
end;

END.
