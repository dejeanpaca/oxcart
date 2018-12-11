{
   oxuModelRender, model rendering
   Copyright (C) 2018. Dejan Boras

   Started On:    25.06.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuModelRender;

INTERFACE

   USES
      uStd, uLog,
      {oX}
      oxuTypes, oxuMaterial, oxuMesh, oxuModel, oxuRender;

TYPE
   { oxTModelRenderGlobal }

   oxTModelRenderGlobal = record
      {render mesh with the given mesh material}
      procedure RenderMesh(const mesh: oxTMesh; material: oxTMaterial; const pM: oxTMeshMaterial);
      {render mesh with the given material}
      procedure RenderMesh(const mesh: oxTMesh; material: oxTMaterial = nil);
      procedure Render(model: oxTModel);
   end;

VAR
   oxModelRender: oxTModelRenderGlobal;

IMPLEMENTATION

{ oxTModelRenderGlobal }

procedure oxTModelRenderGlobal.RenderMesh(const mesh: oxTMesh; material: oxTMaterial; const pM: oxTMeshMaterial);
var
   currentMaterial: oxTMaterial;

begin
   currentMaterial := pM.Material;
   if(currentMaterial = nil) then
      currentMaterial := material;

   currentMaterial.Apply();

   if(Mesh.Data.i <> nil) then
      oxRender.Primitives(Mesh.Primitive, pM.IndiceCount, pword(@Mesh.Data.i[pM.StartIndice]))
   else if(Mesh.Data.il <> nil) then
      oxRender.Primitives(Mesh.Primitive, pM.IndiceCount, PDWord(@Mesh.Data.il[pM.StartIndice]))
end;

procedure oxTModelRenderGlobal.RenderMesh(const mesh: oxTMesh; material: oxTMaterial);
var
   i: loopint;

begin
   if(mesh.Data.nVertices <> 0) then begin
      oxRender.CullFace(mesh.CullFace);

      if(material = nil) then
         material := oxMaterial.Default;

      oxRender.Vertex(Mesh.Data.v[Mesh.Data.vertexOffset]);

      if(Mesh.Data.n <> nil) then begin
         oxRender.Normals(Mesh.Data.n[Mesh.Data.vertexOffset]);
      end else
         oxRender.DisableNormals();

      if(Mesh.Data.c <> nil) then begin
         oxRender.Color(Mesh.Data.c[0]);
      end else
         oxRender.DisableColor();

      if(mesh.Materials.n > 0) then begin
         for i := 0 to mesh.Materials.n - 1 do begin
            RenderMesh(mesh, material, mesh.Materials.List[i]);
         end;
      end else begin
         material.Apply();

         if(Mesh.Data.i <> nil) then
            oxRender.Primitives(Mesh.Primitive, Mesh.Data.nIndices, PWord(@Mesh.Data.i[0]))
         else if(Mesh.Data.il <> nil) then
            oxRender.Primitives(Mesh.Primitive, Mesh.Data.nIndices, PDWord(@Mesh.Data.il[0]))
         else
            oxRender.DrawArrays(Mesh.Primitive, (Mesh.Data.nVertices - Mesh.Data.vertexOffset - Mesh.Data.nVertexCutoff));
     end;

     if(Mesh.Data.c <> nil) then
        oxRender.DisableColor();

     if(Mesh.CullFace <> oxCULL_FACE_DEFAULT) then
        oxRender.CullFace(oxCULL_FACE_DEFAULT);
  end;

end;

procedure oxTModelRenderGlobal.Render(model: oxTModel);
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
