{
   oxuModelRender, model rendering
   Copyright (C) 2018. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuModelRender;

INTERFACE

   USES
      uStd, uLog,
      {oX}
      oxuTypes, oxuMaterial, oxuMesh, oxuModel, oxuRender;

TYPE
   { oxTModelRender }

   oxTModelRender = record
      {get material to render with (fallbacks to default materials if the specified one is not available)}
      class function GetMaterial(material: oxTMaterial = nil): oxTMaterial; static;

      {prepare rendering of a mesh (assign data)}
      procedure PrepareRender(const mesh: oxTMesh);

      {render mesh with the given mesh material}
      procedure DrawPrimitives(const mesh: oxTMesh; startIndex, count: loopint);
      {render mesh with the given mesh material}
      procedure RenderMesh(const mesh: oxTMesh; material: oxTMaterial; const pM: oxTMeshMaterial);
      {render mesh with the given material}
      procedure RenderMesh(const mesh: oxTMesh; material: oxTMaterial = nil);
      {render a given model}
      procedure Render(model: oxTModel);
   end;

VAR
   oxModelRender: oxTModelRender;

IMPLEMENTATION

{ oxTModelRender }

class function oxTModelRender.GetMaterial(material: oxTMaterial): oxTMaterial;
begin
   Result := material;

   if(Result = nil) then
      Result := oxCurrentMaterial;

   if(Result = nil) then
      Result := oxMaterial.Default;
end;

procedure oxTModelRender.PrepareRender(const mesh: oxTMesh);
begin
   oxRender.Vertex(Mesh.Data.v[Mesh.Data.VertexOffset]);

   if(Mesh.Data.t <> nil) then
      oxRender.TextureCoords(Mesh.Data.t[0])
   else
      oxRender.DisableTextureCoords();

   if(Mesh.Data.n <> nil) then begin
      oxRender.Normals(Mesh.Data.n[Mesh.Data.vertexOffset]);
   end else
      oxRender.DisableNormals();

   if(Mesh.Data.c <> nil) then begin
      oxRender.Color(Mesh.Data.c[0]);
   end else
      oxRender.DisableColor();
end;

procedure oxTModelRender.DrawPrimitives(const mesh: oxTMesh; startIndex, count: loopint);
begin
   if(Mesh.Data.i <> nil) then
      oxRender.Primitives(Mesh.Primitive, count, pword(@Mesh.Data.i[startIndex]))
   else if(Mesh.Data.il <> nil) then
      oxRender.Primitives(Mesh.Primitive, count, PDWord(@Mesh.Data.il[startIndex]))
   else
      oxRender.DrawArrays(Mesh.Primitive, mesh.Data.nVertices - mesh.Data.vertexOffset - mesh.Data.nVertexCutoff);
end;

procedure oxTModelRender.RenderMesh(const mesh: oxTMesh; material: oxTMaterial; const pM: oxTMeshMaterial);
var
   currentMaterial: oxTMaterial;

begin
   if(pM.IndiceCount > 0) then begin
      currentMaterial := pM.Material;

      if(currentMaterial = nil) then
         currentMaterial := GetMaterial(material);

      currentMaterial.Apply();

      DrawPrimitives(mesh, pM.StartIndice, pM.IndiceCount);
   end;
end;

procedure oxTModelRender.RenderMesh(const mesh: oxTMesh; material: oxTMaterial);
var
   i: loopint;

begin
   if(mesh.Data.nVertices <> 0) then begin
      oxRender.CullFace(mesh.CullFace);

      material := GetMaterial(material);

      PrepareRender(mesh);

      if(mesh.Materials.n > 0) then begin
         for i := 0 to mesh.Materials.n - 1 do begin
            RenderMesh(mesh, material, mesh.Materials.List[i]);
         end;
      end else begin
         material.Apply();

         DrawPrimitives(mesh, 0, mesh.Data.nIndices);
     end;

     if(Mesh.Data.c <> nil) then
        oxRender.DisableColor();

     if(Mesh.CullFace <> oxCULL_FACE_DEFAULT) then
        oxRender.CullFace(oxCULL_FACE_DEFAULT);
   end;
end;

procedure oxTModelRender.Render(model: oxTModel);
var
   i: loopint;
   mat: oxTMaterial;
   currentMaterial: oxTMaterial;

begin
   if(model = nil) then
      exit;

   currentMaterial := oxCurrentMaterial;

   for i := 0 to model.Meshes.n - 1 do begin
      { get material}
      if(model.Materials.n > i) then
         mat := model.Materials.List[i]
      else
         mat := nil;

      { render }
      RenderMesh(model.Meshes.List[i], mat);
   end;

   oxCurrentMaterial := currentMaterial;
end;

END.
