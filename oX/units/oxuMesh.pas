{
   oxuMesh, mesh
   Copyright (c) 2017. Dejan Boras

   Started On:    11.07.2017.

   TODO: Support for multiple channels
}

{$INCLUDE oxdefines.inc}
UNIT oxuMesh;

INTERFACE

   USES
      uStd, vmVector, uColors,
      {ox}
      oxuTypes, oxuMaterial;

TYPE
   oxPMeshMaterial = ^oxTMeshMaterial;

   { oxTMeshMAterial}

   oxTMeshMaterial = record
      StartIndice,
      IndiceCount: loopint;

      Material: oxTMaterial;
   end;

   {list of materials in a mesh}
   oxTMeshMaterials = specialize TPreallocatedArrayList<oxTMeshMaterial>;

   oxPMesh = ^oxTMesh;

   { oxTMesh }

   oxTMesh = record
      Name: string;
      Primitive: oxTPrimitives;
      CullFace: oxTCullFace;

      Data: record
         {word indices}
         i: array of word;
         {longword indices}
         il: array of longword;
         {vertex buffer}
         v: array of TVector3f;
         {texture coordinate buffer (uv)}
         t: array of TVector2f;
         {normals buffer}
         n: array of TVector3f;
         {color buffer}
         c: array of TColor4ub;

         {counts}
         nFaces,
         nIndices,
         nTexCoords,
         nVertices,
         nNormals,
         nColors,
         nVertsPerFace,
         VertexOffset,
         nVertexCutoff: loopint;
      end;

      Material: oxTMaterial;
      Materials: oxTMeshMaterials;

      HasBoundingBox: boolean;
      BoundingBox: TBoundingBox;

      {initialize the primitive model record}
      procedure Init();
      class procedure Init(out m: oxTMesh); static;

      {scales a primitive model}
      procedure Scale(scalar: single);
      procedure Scale(x, y, z: single);
      {rotate given angles around origin (0, 0, 0)}
      procedure Rotate(x, y, z: single);
      {scale texture coordinates}
      procedure ScaleTexture(scalar: single); inline;
      procedure ScaleTexture(x, y: single);
      {offset a primitive model}
      procedure Translate(x, y, z: single);

      {allocate memory}
      procedure SetVertices(count: loopint);
      procedure SetIndices(count: loopint);
      procedure SetIndicesL(count: loopint);
      procedure SetTexCoords(count: loopint);
      procedure SetNormals(count: loopint);
      procedure SetColors(count: loopint);
      procedure SetMaterials(count: loopint);

      {allocate required memory for vertices, indices, texture coords, normals}
      procedure SetData(nv: loopint; ni: loopint = 0; nt: loopint = 0; nn: loopint = 0);

      {set the color of the entire model}
      procedure SetColor(const color: TColor4ub);

      {dispose of the model}
      procedure Dispose();
      {recycles primitive for use}
      procedure Recycle();

      {computes normals for a model with the specified mode}
      function ComputeNormals(mode: oxTNormalsMode): loopint;
      {get the bounding box for the mesh}
      procedure GetBoundingBox(out bbox: TBoundingBox);
      procedure GetBoundingBox();

      {checks if the mesh data is quads}
      function IsQuad(): boolean;
      {convert quads to triangles}
      procedure QuadsToTriangles();
   end;

   oxTMeshes = specialize TPreallocatedArrayList<oxTMesh>;

IMPLEMENTATION

procedure oxTMesh.Init();
begin
   data.nVertsPerFace := 3;
   Primitive := oxPRIMITIVE_TRIANGLES;
   CullFace := oxCULL_FACE_DEFAULT;
end;

class procedure oxTMesh.Init(out m: oxTMesh);
begin
   ZeroPtr(@m, SizeOf(m));
   m.Init();
   m.Materials.InitializeValues(m.Materials);
end;

procedure oxTMesh.SetVertices(count: loopint);
begin
   data.nVertices := count;
   SetLength(data.v, count);
end;

procedure oxTMesh.SetIndices(count: loopint);
begin
   data.nIndices := count;
   SetLength(data.i, count);
end;

procedure oxTMesh.SetIndicesL(count: loopint);
begin
   data.nIndices := count;
   SetLength(data.il, count);
end;

procedure oxTMesh.SetTexCoords(count: loopint);
begin
   data.nTexCoords := count;
   SetLength(data.t, count);
end;

procedure oxTMesh.SetNormals(count: loopint);
begin
   data.nNormals := count;
   SetLength(data.n, count);
end;

procedure oxTMesh.SetColors(count: loopint);
begin
   data.nColors := count;
   SetLength(data.c, count);
end;

procedure oxTMesh.SetMaterials(count: loopint);
begin
   Materials.Allocate(count);
end;

procedure oxTMesh.SetData(nv: loopint; ni: loopint; nt: loopint; nn: loopint);
begin
   SetVertices(nv);
   if(ni > 0) then
      SetIndices(ni);

   if(nt > 0) then
      SetTexCoords(nt);

   if(nn > 0) then
      SetNormals(nn);
end;

procedure oxTMesh.SetColor(const color: TColor4ub);
begin
   if(data.nVertices > 0) then begin
      SetColors(data.nVertices);

      FillDWord(data.c[0], data.nColors, dword(color));
   end;
end;

procedure oxTMesh.Scale(scalar: single);
begin
   {scale all vertices}
   if(data.nVertices > 0) then
      vmScale(data.v[0], data.nVertices, scalar);
end;

procedure oxTMesh.Scale(x, y, z: single);
begin
   {scale all vertices}
   if(data.nVertices > 0) then
      vmScale(data.v[0], data.nVertices, x, y, z);
end;

procedure oxTMesh.Rotate(x, y, z: single);
var
   i: loopint;

begin
   {scale all vertices}
   if(data.nVertices > 0) then begin
      for i := 0 to Data.nVertices - 1 do begin
         if(x <> 0) then
            vmRotateAroundPoint(x * vmcToRad, 1, 0, 0, vmvZero3f, data.v[i]);

         if(y <> 0) then
            vmRotateAroundPoint(y * vmcToRad, 0, 1, 0, vmvZero3f, data.v[i]);

         if(z <> 0) then
            vmRotateAroundPoint(z * vmcToRad, 0, 0, 1, vmvZero3f, data.v[i]);
      end;
   end;
end;

procedure oxTMesh.ScaleTexture(scalar: single); inline;
begin
   ScaleTexture(scalar, scalar);
end;

procedure oxTMesh.ScaleTexture(x, y: single);
begin
   if(data.nTexCoords > 0) then
      vmScale(data.t[0], data.nTexCoords, x, y);
end;

procedure oxTMesh.Translate(x, y, z: single);
begin
   {offset all vertices by specified amount}
   if(data.nVertices > 0) then
      vmOffset(data.v[0], data.nVertices, x, y, z);
end;

{dispose of the model}
procedure oxTMesh.Dispose();
begin
   SetLength(Data.v, 0);
   Data.nVertices    := 0;
   Data.v            := nil;

   SetLength(data.i, 0);
   Data.nIndices     := 0;
   Data.i            := nil;

   SetLength(data.il, 0);
   Data.il           := nil;

   SetLength(data.t, 0);
   Data.nTexCoords   := 0;
   Data.t            := nil;

   SetLength(data.n, 0);
   Data.nNormals     := 0;
   Data.n            := nil;
end;

procedure oxTMesh.Recycle();
begin
   Dispose();
   Init();
end;

{ COMPUTING NORMALS }

function oxTMesh.ComputeNormals(mode: oxTNormalsMode): loopint;

function calcPPNormals(): loopint;
var
   i,
   j,
   idx: loopint;
   vertex: TVector3f;

begin
   result   := eNONE;
   idx      := 0;

   if(data.nIndices = 0) then begin
      for i := 0 to (data.nFaces - 1) do begin
         for j := 0 to (data.nVertsPerFace - 1) do
            data.n[idx + j] := vmNormal(data.v[idx + 2], data.v[idx + 1], data.v[idx + 0]);

         inc(idx, data.nVertsPerFace);
      end;
   end else begin
      for i := 0 to (data.nFaces - 1) do begin
         vertex := vmNormal(data.v[data.i[idx + 2]], data.v[data.i[idx + 1]], data.v[data.i[idx + 0]]);

         for j := 0 to (data.nVertsPerFace - 1) do
            data.n[data.i[idx + j]] := vertex;

         inc(idx, data.nVertsPerFace);
      end;
   end;
end;

function calcPVNormals(): loopint;
var
   i,
   j,
   idx: loopint;

   p,
   k,
   normal: TVector3f;

   counts: array of loopint = nil;
   v0,
   v1,
   v2: PVector3f;

   countinv: single;

begin
   result := eNONE;

   {get memory for count array}
   SetLength(counts, data.nVertices);
   if(Length(counts) <> data.nVertices) then
      exit(eNO_MEMORY);

   {initialize}
   ZeroOut(counts[0], int64(data.nVertices) * SizeOf(counts[0]));
   ZeroOut(data.n[0], int64(data.nVertices) * SizeOf(data.n[0]));

   {calculate}
   for i := 0 to (data.nFaces - 1) do begin
      idx   := i * data.nVertsPerFace;
      j     := i * data.nVertsPerFace;
      if(data.nIndices > 0) then begin
         p := data.v[data.i[idx + 0]] - data.v[data.i[idx + 1]];
         k := data.v[data.i[idx + 0]] - data.v[data.i[idx + 2]];
      end else begin
         p := data.v[j] - data.v[j + 1];
         k := data.v[j] - data.v[j + 2];
      end;

      normal := p.Cross(k);

      if(data.nIndices > 0) then begin
         v0    := @data.n[data.i[idx + 0]];
         v0^   := v0^ + normal;
         inc(counts[data.i[idx + 0]]);

         v1    := @data.n[data.i[idx + 1]];
         v1^   := v1^ + normal;
         inc(counts[data.i[idx + 1]]);

         v2    := @data.n[data.i[idx + 2]];
         v2^   := v2^ + normal;
         inc(counts[data.i[idx + 2]]);
      end else begin
         v0    := @data.n[j + 0];
         v0^   := v0^ + normal;
         inc(counts[j + 0]);

         v1    := @data.n[j + 1];
         v1^   := v1^ + normal;
         inc(counts[j + 1]);

         v2    := @data.n[j + 2];
         v2^   := v2^ + normal;
         inc(counts[j + 2]);
      end;
   end;

   {average and normalize}
   for i := 0 to (data.nVertices-1) do begin
      if(counts[i] = 0) then
         continue;

      countinv    := 1.0 / counts[i];
      data.n[i]   := data.n[i] * countinv;
      data.n[i].Normalize();
   end;

   {cleanup}
   SetLength(counts, 0);
end;

function calcNormalizedVertices(): loopint;
var
   i: loopint;

begin
   for i := 0 to (data.nNormals - 1) do begin
      data.n[i] := data.v[i];
      data.n[i].Normalize();
   end;

   result := eNONE;
end;

begin
   result := eNONE;

   if(data.nVertices > 0) then begin
      if(data.nVertsPerFace >= 3) or ((mode = oxNORMALS_MODE_NORMALIZED_VERTICES)) then begin

         if(mode <> oxNORMALS_MODE_NONE) then begin
            SetNormals(data.nVertices);
            {calculate}
            if(mode = oxNORMALS_MODE_PER_POLY) then
               result := calcPPNormals()
            else if(mode = oxNORMALS_MODE_PER_VERTEX) then
               result := calcPVNormals()
            else if(mode = oxNORMALS_MODE_NORMALIZED_VERTICES) then
               result := calcNormalizedVertices()
            else
               result := eINVALID_ARG;
         end;
      end;
   end;
end;

procedure oxTMesh.GetBoundingBox(out bbox: TBoundingBox);
var
   i: loopint;

begin
   bbox := vmBBoxZero;

   if(data.nVertices > 0) then begin
      bbox[0] := data.v[0];
      bbox[1] := data.v[1];

      for i := 0 to (data.nVertices - 1) do begin
         if(data.v[i][0] < bbox[0][0]) then
            bbox[0][0] := data.v[i][0];
         if(data.v[i][0] > bbox[1][0]) then
            bbox[1][0] := data.v[i][0];

         if(data.v[i][1] < bbox[0][1]) then
            bbox[0][1] := data.v[i][1];
         if(data.v[i][1] > bbox[1][1]) then
            bbox[1][1] := data.v[i][1];

         if(data.v[i][2] < bbox[0][2]) then
            bbox[0][2] := data.v[i][2];
         if(data.v[i][2] > bbox[1][2]) then
            bbox[1][2] := data.v[i][2];
      end;
   end;
end;

procedure oxTMesh.GetBoundingBox();
begin
   GetBoundingBox(BoundingBox);
   HasBoundingBox := true;
end;

function oxTMesh.IsQuad(): boolean;
begin
   Result := Primitive = oxTPrimitives.oxPRIMITIVE_QUADS;
end;

procedure oxTMesh.QuadsToTriangles();
var
   trim: oxTMesh;
   i,
   quadIndex,
   triIndex: loopint;

begin
   if(Primitive <> oxPRIMITIVE_QUADS) then
      exit;

   trim := Self;

   {convert quad indices to triangle indices}
   if(Data.nIndices <> 0) then begin
      {NOTE: We create new indice arrays without destroying the old ones. We don't need to reorganize the data
      as we'll just index each}

      {4 indices per quad, we have 2 triangles per quad and 3 indices per triangle}
      trim.Data.nFaces := Data.nFaces * 2;
      trim.Data.nIndices := trim.Data.nFaces * 3;
      trim.Primitive := oxPRIMITIVE_TRIANGLES;

      if(trim.Data.i <> nil) then begin
         trim.Data.i := nil;
         trim.SetIndices(trim.Data.nIndices);

         for i := 0 to Data.nFaces - 1 do begin
            quadIndex := i * 4;
            triIndex := i * 6;

            trim.Data.i[triIndex + 0] := Data.i[quadIndex + 0];
            trim.Data.i[triIndex + 1] := Data.i[quadIndex + 1];
            trim.Data.i[triIndex + 2] := Data.i[quadIndex + 2];

            trim.Data.i[triIndex + 3] := Data.i[quadIndex + 0];
            trim.Data.i[triIndex + 4] := Data.i[quadIndex + 2];
            trim.Data.i[triIndex + 5] := Data.i[quadIndex + 3];
         end;
      end;

      if(trim.Data.il <> nil) then begin
         trim.Data.il := nil;
         trim.SetIndicesL(trim.Data.nIndices);

         for i := 0 to Data.nFaces - 1 do begin
            quadIndex := i * 4;
            triIndex := i * 6;

            trim.Data.i[triIndex + 0] := Data.i[quadIndex + 0];
            trim.Data.i[triIndex + 1] := Data.i[quadIndex + 1];
            trim.Data.i[triIndex + 2] := Data.i[quadIndex + 2];

            trim.Data.i[triIndex + 3] := Data.i[quadIndex + 0];
            trim.Data.i[triIndex + 4] := Data.i[quadIndex + 2];
            trim.Data.i[triIndex + 5] := Data.i[quadIndex + 3];
         end;
      end;

      {dispose indices}
      SetLength(Data.i, 0);
      SetLength(Data.il, 0);

      {set current mesh to triangle mesh}
      Self := trim;
   end else begin
      {TODO: Convert quad arrays to triangle arrays}
   end;
end;

END.
