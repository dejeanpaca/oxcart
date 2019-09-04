{
   oxumPrimitive, primitive models
   Copyright (c) 2011. Dejan Boras

   Started On:    13.02.2011.

   TODO: Add normals and texture coords for meshes missing this
}

{$INCLUDE oxdefines.inc}
UNIT oxumPrimitive;

INTERFACE

   USES
      uStd, vmVector, uLog,
      {ox}
      oxuTypes, oxuPrimitives, oxuTexture, oxuRender, oxuMesh, oxuMaterial, oxuModelRender, oxuResourcePool;

TYPE
   oxTPrimitiveModelType = (
      oxmPRIMITIVE_NONE,
      oxmPRIMITIVE_TRIANGLE,
      oxmPRIMITIVE_CIRCLE,
      oxmPRIMITIVE_DISK,
      oxmPRIMITIVE_QUAD,
      oxmPRIMITIVE_CUBE,
      oxmPRIMITIVE_SPHERE,
      oxmPRIMITIVE_CYLINDER,
      oxmPRIMITIVE_TORUS,
      oxmPRIMITIVE_CONE
   );

CONST
   oxMAX_PRIMITIVE = longint(oxmPRIMITIVE_TORUS);

   oxmPRIMITIVE_CUBE_METHOD_DEFAULT           = 0000;
   oxmPRIMITIVE_CUBE_METHOD_TRIANGLE_STRIP    = 0001;
   oxmPRIMITIVE_CUBE_METHOD_ARRAY             = 0002;

   oxmPRIMITIVE_SPHERE_METHOD_SIMPLE          = 0000;
   oxmPRIMITIVE_SPHERE_METHOD_ENHANCED        = 0001;

TYPE
   oxTPrimitiveIndice = word;

   oxPPrimitiveModel = ^oxTPrimitiveModel;

   { oxTPrimitiveModel }

   oxTPrimitiveModel = record
      Mesh: oxTMesh;
      PrimitiveType: oxTPrimitiveModelType;
      PrimitiveMethod: longint;
      Material: oxTMaterial;

      Transform: record
         Translation,
         Scale: TVector3f;
         EdgeOffset: single;
      end;

      {initialize the primitive model record}
      procedure Init();

      {scales a primitive model}
      procedure Scale(scalar: single);
      procedure Scale(x, y, z: single);
      {scale texture coordinates}
      procedure ScaleTexture(scalar: single); inline;
      procedure ScaleTexture(x, y: single);
      {offset a primitive model}
      procedure Translate(x, y, z: single);

      {render a primitive model}
      procedure Render();

      {dispose of the model}
      procedure Dispose();
      {recycles primitive for use}
      procedure Recycle();
      {set material to be used for rendering}
      procedure SetMaterial(newMaterial: oxTMaterial);

      { MODELS }

      { triangle }
      procedure InitTriangle(size: single);
      procedure Triangle(size: single);
      procedure InitTriangle();
      procedure Triangle();

      { quad }
      procedure InitQuad();
      procedure Quad();
      procedure QuadResetVertices();

      { circle/disk }
      procedure InitCircleDisk(r: single; d: longint; pT: oxTPrimitiveModelType);
      procedure CircleDisk(r: single; d: longint; pT: oxTPrimitiveModelType);

      procedure InitDisk(r: single; d: longint);
      procedure Disk(r: single; d: longint);
      procedure InitDisk();
      procedure Disk();

      procedure InitCircle(r: single; d: longint);
      procedure Circle(r: single; d: longint);
      procedure InitCircle();
      procedure Circle();

      { cube }
      procedure InitCube(a, b, c: single; method: longint = oxmPRIMITIVE_CUBE_METHOD_DEFAULT);
      procedure Cube(a, b, c: single; method: longint = oxmPRIMITIVE_CUBE_METHOD_DEFAULT);
      procedure InitCube(method: longint = oxmPRIMITIVE_CUBE_METHOD_DEFAULT);
      procedure Cube(method: longint = oxmPRIMITIVE_CUBE_METHOD_DEFAULT);

      { sphere }
      procedure SphereEnhanced(r: single = 1.0; stacks: longint = 10; slices: longint = 15);
      procedure SphereSimple(r: single = 1.0; stacks: longint = 10; slices: longint = 15);

      procedure InitSphere(r: single = 1.0; stacks: longint = 10; slices: longint = 15;
         method: longint = oxmPRIMITIVE_SPHERE_METHOD_SIMPLE);
      procedure Sphere(r: single = 1.0; stacks: longint = 10; slices: longint = 15;
         method: longint = oxmPRIMITIVE_SPHERE_METHOD_SIMPLE);
      procedure InitSphere(method: longint = oxmPRIMITIVE_SPHERE_METHOD_SIMPLE);
      procedure Sphere(method: longint = oxmPRIMITIVE_SPHERE_METHOD_SIMPLE);

      { cylinder }
      procedure Cylinder();
      procedure InitCylinder(major, minor: longint; height, radius: single);
      procedure Cylinder(major, minor: longint; height, radius: single);

      { torus }
      procedure Torus();
      procedure InitTorus(major, minor: longint; minorRadius, majorRadius: single);
      procedure Torus(major, minor: longint; minorRadius, majorRadius: single);

      { torus }
      procedure Cone();
      procedure InitCone(divisions: longint; radius, length: single);
      procedure Cone(divisions: longint; radius, length: single);

      {create model from the specified type}
      procedure FromType(pT: oxTPrimitiveModelType);
      procedure FromType();
   end;

   { oxTPrimitiveModelGlobal }

   oxTPrimitiveModelGlobal = record
      defaults: record
         CircleDivisions: longint;
         SphereStacks: longint;
         SphereSlices: longint;
      end;

      {creation settings}
      Create: record
         {should normals be created}
         Normals,
         {should texture coordinates be created}
         TextureCoords: boolean;
      end;

      procedure Init(out m: oxTPrimitiveModel);

      {create a empty primitive model on the heap}
      function Make(): oxPPrimitiveModel;

      {dispose of the model}
      procedure Dispose(var p: oxPPrimitiveModel);
   end;

VAR
   oxmPrimitive: oxTPrimitiveModelGlobal;


IMPLEMENTATION

procedure oxTPrimitiveModel.Init();
begin
   Mesh.Init();

   Mesh.CullFace := oxCULL_FACE_BACK;
   Transform.Scale := vmvOne3f;
end;

procedure oxTPrimitiveModelGlobal.Init(out m: oxTPrimitiveModel);
begin
   ZeroOut(m, SizeOf(m));
   m.Init();
end;

function oxTPrimitiveModelGlobal.Make(): oxPPrimitiveModel;
var
   p: oxPPrimitiveModel = nil;

begin
   new(p);
   if(p <> nil) then
      p^.Init();

   result := p;
end;

procedure oxTPrimitiveModelGlobal.Dispose(var p: oxPPrimitiveModel);
begin
   if(p <> nil) then begin
      p^.Dispose();
      FreeMem(p);
      p := nil;
   end;
end;

procedure oxTPrimitiveModel.Scale(scalar: single);
begin
   {modify the scale}
   Transform.Scale := Transform.Scale * scalar;

   Mesh.Scale(scalar);
end;

procedure oxTPrimitiveModel.Scale(x, y, z: single);
begin
   {modify the scale}
   Transform.Scale[0] := Transform.Scale[0] * x;
   Transform.Scale[1] := Transform.Scale[1] * y;
   Transform.Scale[2] := Transform.Scale[2] * z;

   {scale all vertices}
   Mesh.Scale(x, y, z);
end;

procedure oxTPrimitiveModel.ScaleTexture(scalar: single); inline;
begin
   ScaleTexture(scalar, scalar);
end;

procedure oxTPrimitiveModel.ScaleTexture(x, y: single);
begin
   Mesh.ScaleTexture(x, y);
end;

procedure oxTPrimitiveModel.Translate(x, y, z: single);
begin
   {store the offset vertex}
   Transform.Translation[0] := Transform.Translation[0] + x;
   Transform.Translation[1] := Transform.Translation[1] + y;
   Transform.Translation[2] := Transform.Translation[2] + z;

   {offset all vertices by specified amount}
   Mesh.Translate(x, y, z);
end;

procedure oxTPrimitiveModel.Render();
var
   currentMaterial: oxTMaterial;

begin
   currentMaterial := oxCurrentMaterial;

   oxModelRender.RenderMesh(mesh, Material);

   oxCurrentMaterial := currentMaterial;
end;

{dispose of the model}
procedure oxTPrimitiveModel.Dispose();
begin
   Mesh.Dispose();
   oxResource.Destroy(Material);
end;

procedure oxTPrimitiveModel.Recycle();
begin
   Dispose();
   Init();
end;

procedure oxTPrimitiveModel.SetMaterial(newMaterial: oxTMaterial);
begin
   oxResource.Destroy(Material);

   Material := newMaterial;

   if(Material <> nil) then
      Material.MarkUsed();
end;

{ PRIMITIVE MODELS }

procedure oxTPrimitiveModel.InitTriangle(size: single);
begin
   Init();
   Triangle(size);
end;

procedure oxTPrimitiveModel.Triangle(size: single);
begin
   Mesh.CullFace     := oxCULL_FACE_BACK;
   Mesh.Data.nFaces  := 1;
   PrimitiveType     := oxmPRIMITIVE_TRIANGLE;

   Mesh.SetData(3);

   {top vertex}
   Mesh.Data.v[0][0] := 0.0;
   Mesh.Data.v[0][1] := size;
   Mesh.Data.v[0][2] := 0.0;
   {lower left vertex}
   Mesh.Data.v[1][0] :=-size;
   Mesh.Data.v[1][1] :=-size;
   Mesh.Data.v[1][2] := 0.0;
   {lower right vertex}
   Mesh.Data.v[2][0] := size;
   Mesh.Data.v[2][1] :=-size;
   Mesh.Data.v[2][2] := 0.0;

   { TEXTURE COORDINATES }
   if(oxmPrimitive.Create.TextureCoords) then begin
      Mesh.SetTexCoords(3);

      {top vertex}
      Mesh.Data.t[0][0] := 0.0;
      Mesh.Data.t[0][1] := 0.0;
      {lower left vertex}
      Mesh.Data.t[1][0] := 1.0;
      Mesh.Data.t[1][1] := 0.0;
      {lower right vertex}
      Mesh.Data.t[2][0] := 1.0;
      Mesh.Data.t[2][1] := 1.0;
   end;
end;

procedure oxTPrimitiveModel.InitTriangle();
begin
   Init();
   Triangle();
end;

procedure oxTPrimitiveModel.Triangle();
begin
   Triangle(1.0);
end;

procedure oxTPrimitiveModel.InitQuad();
begin
   Init();
   Quad();
end;

procedure oxTPrimitiveModel.Quad();
begin
   { prepare }
   primitiveType := oxmPRIMITIVE_QUAD;
   Mesh.Data.nFaces := QUAD_FACES;
   Mesh.CullFace := oxCULL_FACE_NONE;

   { add indices, vertices and texture coordinates}
   Mesh.SetData(QUAD_VERTICEs, QUAD_INDICES, QUAD_VERTICES);

   { setup data }
   Move(QuadIndicesus[0], Mesh.Data.i[0], QUAD_INDICES * SizeOf(oxTPrimitiveIndice));
   QuadResetVertices();
   Move(QuadTexCoords[0], Mesh.Data.t[0], QUAD_VERTICES * SizeOf(TVector2f));
end;

procedure oxTPrimitiveModel.QuadResetVertices();
begin
   if(Length(Mesh.Data.v) >= QUAD_VERTICES) then
      move(QuadVertices[0], Mesh.Data.v[0], QUAD_VERTICES * SizeOf(TVector3f));

   Transform.Scale := vmvOne3f;

   Transform.Translation := vmvZero3f;
end;

procedure oxTPrimitiveModel.InitCircleDisk(r: single; d: longint; pT: oxTPrimitiveModelType);
begin
   Init();
   CircleDisk(r, d, pT);
end;

procedure oxTPrimitiveModel.CircleDisk(r: single; d: longint; pT: oxTPrimitiveModelType);
var
   piece,
   p: single;
   i, ni: longint;

begin
   primitiveType := pT;

   Mesh.Data.nVertsPerFace := 1;
   Mesh.Data.nVertexCutoff := 1; {we don't use the last vertex which is the center of the circle}

   { check primitive type }
   if(primitiveType = oxmPRIMITIVE_DISK) then
      Mesh.Primitive := oxPRIMITIVE_TRIANGLE_FAN
   else if(primitiveType = oxmPRIMITIVE_CIRCLE) then
      Mesh.Primitive := oxPRIMITIVE_LINE_LOOP;

   { prepare }
   Mesh.Data.nFaces := d;
   primitiveType := pT;

   Mesh.SetData(d + 1);

   { build circle/disk }
   piece := (vmcPI * 2) / d;

   for i := 0 to (d - 1) do begin
      p := piece * i;
      ni := d - i - 1; {we go in reverse, so the disk is culled back by default (front facing)}
      Mesh.Data.v[ni][0]   := sin(p) * r;
      Mesh.Data.v[ni][1]   := cos(p) * r;
      Mesh.Data.v[ni][2]   := 0.0;
   end;

   Mesh.Data.v[d]            := vmvZero3f;
end;

procedure oxTPrimitiveModel.InitDisk(r: single; d: longint);
begin
   Init();
   Disk(r, d);
end;

procedure oxTPrimitiveModel.Disk(r: single; d: longint);
begin
   CircleDisk(r, d, oxmPRIMITIVE_DISK);
end;

procedure oxTPrimitiveModel.InitDisk();
begin
   Init();
   Disk();
end;

procedure oxTPrimitiveModel.Disk();
begin
   CircleDisk(1.0, oxmPrimitive.defaults.circleDivisions, oxmPRIMITIVE_DISK);
end;

procedure oxTPrimitiveModel.InitCircle(r: single; d: longint);
begin
   Init();
   Circle(r, d);
end;

procedure oxTPrimitiveModel.Circle(r: single; d: longint);
begin
   CircleDisk(r, d, oxmPRIMITIVE_CIRCLE);
end;

procedure oxTPrimitiveModel.InitCircle();
begin
   Init();
   Circle();
end;

procedure oxTPrimitiveModel.Circle();
begin
   CircleDisk(1.0, oxmPrimitive.defaults.circleDivisions, oxmPRIMITIVE_CIRCLE);
end;

{ cube }
procedure oxTPrimitiveModel.InitCube(a, b, c: single; method: longint);
begin
   Init();
   Cube(a, b, c, method);
end;

procedure oxTPrimitiveModel.Cube(a, b, c: single; method: longint);
begin
   primitiveType           := oxmPRIMITIVE_CUBE;
   primitiveMethod         := method;
   Mesh.Data.nVertices     := 8;
   Mesh.Data.nFaces        := CUBE_FACES;

   if(method = oxmPRIMITIVE_CUBE_METHOD_DEFAULT) then begin
      Mesh.Data.nVertsPerFace   := 3;
      Mesh.Data.nIndices        := 12 * 3;
   end else if(method = oxmPRIMITIVE_CUBE_METHOD_TRIANGLE_STRIP) then begin
      Mesh.Primitive            := oxPRIMITIVE_TRIANGLE_STRIP;
      Mesh.Data.nVertsPerFace   := 1;
      Mesh.Data.nIndices        := CUBE_INDICES_TRI_STRIP;
   end else if(method = oxmPRIMITIVE_CUBE_METHOD_ARRAY) then begin
      Mesh.Data.nVertsPerFace   := 3;
      Mesh.Data.nVertices       := 36;
   end;

   { vertices }
   Mesh.SetData(Mesh.Data.nVertices, Mesh.Data.nIndices);

   if(method = oxmPRIMITIVE_CUBE_METHOD_DEFAULT) then
      move(CubeVertices, Mesh.Data.v[0], SizeOf(CubeVertices))
   else if(method = oxmPRIMITIVE_CUBE_METHOD_TRIANGLE_STRIP) then
      move(CubeVerticesTriStrip, Mesh.Data.v[0], SizeOf(CubeVerticesTriStrip))
   else if(method = oxmPRIMITIVE_CUBE_METHOD_ARRAY) then
      move(CubeVerticesArray, Mesh.Data.v[0], SizeOf(CubeVerticesArray));

   vmScale(Mesh.Data.v[0], Mesh.Data.nVertices, a, b, c);

   { indices }
   if(Mesh.Data.nIndices > 0) then begin
      if(method = oxmPRIMITIVE_CUBE_METHOD_TRIANGLE_STRIP) then
         move(CubeIndicesTriStripus, Mesh.Data.i[0], CUBE_INDICES_TRI_STRIP * SizeOf(oxTPrimitiveIndice))
      else
         move(CubeIndicesus, Mesh.Data.i[0], CUBE_INDICES * SizeOf(oxTPrimitiveIndice));
   end;
end;

procedure oxTPrimitiveModel.InitCube(method: longint);
begin
   Init();
   Cube(method);
end;

procedure oxTPrimitiveModel.Cube(method: longint);
begin
   Cube(1.0, 1.0, 1.0, method);
end;

{ sphere }

procedure oxTPrimitiveModel.SphereEnhanced(r: single; stacks: longint; slices: longint);
var
   theta,
   phi,
   thetas,
   phis: single;

   i,
   j,
   bvex,
   triPerSlice,
   vPerSlice,
   vCur,
   vPrev: longint;

   t0,
   t1: PVector3us;

begin
   if(stacks < 2) or (slices < 3) then
      exit();

   Mesh.CullFace        := oxCULL_FACE_BACK;
   primitiveType        := oxmPRIMITIVE_SPHERE;
   primitiveMethod      := oxmPRIMITIVE_SPHERE_METHOD_ENHANCED;

   thetas               := vmcPI / stacks;
   phis                 := vmcPI * 2 / slices;

   { set face count }
   Mesh.Data.nFaces := 2 * (slices * (stacks - 1));

   Mesh.SetData(2 + (stacks - 1) * slices, Mesh.Data.nVertsPerFace * Mesh.Data.nFaces);

   { determine certain factors }
   vPerSlice            := stacks - 1;
   triPerSlice          := 2 * (stacks - 1);
   bvex                 := 1 + vPerSlice * slices;

   { top and bottom vertex }

   vmSphereToCartesian(r, 0.0, 0.0, Mesh.Data.v[0]);
   vmSphereToCartesian(r, 0.0, vmcPI, Mesh.Data.v[bvex]);

   { create vertices }
   phi                  := 0.0;

   {for each slice}
   for i := 0 to (slices-1) do begin
      theta := thetas;

      {create stacks - 1 vertex per slice}
      for j := 0 to (stacks-2) do begin
         vmSphereToCartesian(r, phi, theta, Mesh.Data.v[1 + vPerSlice * i + j]);
         theta := theta + thetas;
      end;

      phi := phi + phis;
   end;

   { connect the vertices to form triangles }

   {for each slice except the first one}
   for i := 1 to (slices-1) do begin
      {for each stack}
      for j := 0 to (stacks-1) do begin
         if(j = 0) then begin
            t0       := @Mesh.Data.i[(triPerSlice * i)*3];

            vCur     := 1 + i * vPerSlice;
            vPrev    := 1 + (i - 1) * vPerSlice;

            t0^[0]   := 0;
            t0^[1]   := vPrev;
            t0^[2]   := vCur;
         end else if(j = stacks - 1) then begin
            t0       := @Mesh.Data.i[(triPerSlice * (i + 1) - 1)*3];

            vCur     := 1 + i * vPerSlice + j -1;
            vPrev    := 1 + (i - 1) * vPerSlice + j - 1;

            t0^[0]   := vCur;
            t0^[1]   := vPrev;
            t0^[2]   := bvex;
         end else begin
            t0       := @Mesh.Data.i[(triPerSlice * i + (j - 1) * 2 + 1) * 3];
            t1       := @Mesh.Data.i[(triPerSlice * i + (j - 1) * 2 + 1 + 1) * 3];

            vCur     := 1 + i * vPerSlice + j - 1;
            vPrev    := 1 + (i - 1) * vPerSlice + j - 1;

            t0^[0]   := vCur;
            t0^[1]   := vPrev;
            t0^[2]   := vPrev + 1;

            t1^[0]   := vCur;
            t1^[1]   := vPrev + 1;
            t1^[2]   := vCur  + 1;
         end;
      end;
   end;

   i := 0;
   {for each stack}
   for j := 0 to (stacks-1) do begin
      if(j = 0) then begin
         t0       := @Mesh.Data.i[(triPerSlice * i)*3];

         vCur     := 1 + i * vPerSlice;
         vPrev    := 1 + (slices - 1) * vPerSlice;

         t0^[0]   := 0;
         t0^[1]   := vPrev;
         t0^[2]   := vCur;
      end else if(j = stacks - 1) then begin
         t0       := @Mesh.Data.i[(triPerSlice*(i+1) - 1) * 3];
         vCur     := 1 + i*vPerSlice + j - 1;
         vPrev    := 1 + (slices - 1)*vPerSlice + j - 1;

         t0^[0]   := vCur;
         t0^[1]   := vPrev;
         t0^[2]   := bvex;
      end else begin
         t0       := @Mesh.Data.i[(triPerSlice * i + (j - 1) * 2 + 1) * 3];
         t1       := @Mesh.Data.i[(triPerSlice * i + (j - 1) * 2 + 1 + 1) * 3];

         vCur     := 1 + i * vPerSlice + j - 1;
         vPrev    := 1 + (slices - 1) * vPerSlice + j - 1;

         t0^[0]   := vCur;
         t0^[1]   := vPrev;
         t0^[2]   := vPrev + 1;

         t1^[0]   := vCur;
         t1^[1]   := vPrev + 1;
         t1^[2]   := vCur + 1;
      end;
   end;
end;

procedure oxTPrimitiveModel.SphereSimple(r: single; stacks: longint; slices: longint);
var
   i,
   j,
   n,
   first,
   second: longint;

   theta,
   sinTheta,
   cosTheta,
   phi,
   sinPhi,
   cosPhi,
   x,
   y,
   z: single;

begin
   if(stacks < 2) or (slices < 3) then
      exit();

   Mesh.CullFace      := oxCULL_FACE_BACK;
   primitiveType      := oxmPRIMITIVE_SPHERE;
   primitiveMethod    := oxmPRIMITIVE_SPHERE_METHOD_SIMPLE;
   Mesh.Primitive     := oxPRIMITIVE_TRIANGLES;

   { vertices }
   n := (stacks + 1) * (slices + 1);

   Mesh.SetData(n, 0, n, n);

   Mesh.Data.nFaces  := stacks * slices * 2;
   n                 := 0;

   for i := 0 to stacks do begin
      theta       := i * vmcPI / stacks;
      sinTheta    := sin(theta);
      cosTheta    := cos(theta);

      for j := 0 to slices do begin
         phi         := j * 2 * vmcPI / slices;
         sinPhi      := sin(phi);
         cosPhi      := cos(phi);

         x           := cosPhi * sinTheta;
         y           := cosTheta;
         z           := sinPhi * sinTheta;

         Mesh.Data.v[n][0] := r * x;
         Mesh.Data.v[n][1] := r * y;
         Mesh.Data.v[n][2] := r * z;

         if(oxmPrimitive.Create.TextureCoords) then begin
            Mesh.Data.t[n][0] := 1 - (j / slices);
            Mesh.Data.t[n][1] := 1 - (i / stacks);
         end;

         if(oxmPrimitive.Create.Normals) then begin
            Mesh.Data.n[n][0] := x;
            Mesh.Data.n[n][1] := y;
            Mesh.Data.n[n][2] := z;
         end;

         inc(n);
      end;
   end;

   n := 0;
   Mesh.SetIndices(Mesh.Data.nFaces * Mesh.Data.nVertsPerFace);

   for i := 0 to (stacks-1) do begin {lat}
      for j := 0 to (slices-1) do begin {long}
         first          := (i * (slices +1 )) + j;
         second         := first + slices + 1;

         Mesh.Data.i[n + 0]  := first + 1;
         Mesh.Data.i[n + 1]  := second;
         Mesh.Data.i[n + 2]  := first;

         Mesh.Data.i[n + 3]  := first + 1;
         Mesh.Data.i[n + 4]  := second + 1;
         Mesh.Data.i[n + 5]  := second;

         inc(n, 6)
      end;
   end;
end;

procedure oxTPrimitiveModel.InitSphere(r: single; stacks: longint; slices: longint; method: longint);
begin
   Init();
   Sphere(r, stacks, slices, method);
end;

procedure oxTPrimitiveModel.Sphere(r: single; stacks: longint; slices: longint; method: longint);
begin
   if(method = oxmPRIMITIVE_SPHERE_METHOD_SIMPLE) then
      SphereSimple(r, stacks, slices)
   else if(method = oxmPRIMITIVE_SPHERE_METHOD_ENHANCED) then
      SphereEnhanced(r, stacks, slices);
end;

procedure oxTPrimitiveModel.InitSphere(method: longint);
begin
   Init();
   Sphere(method);
end;

procedure oxTPrimitiveModel.Sphere(method: longint);
begin
   Sphere(1.0, oxmPrimitive.defaults.sphereStacks, oxmPrimitive.defaults.sphereSlices, method);
end;

procedure oxTPrimitiveModel.Cylinder();
begin
   Cylinder(32, 32, 2, 1);
end;

procedure oxTPrimitiveModel.InitCylinder(major, minor: longint; height, radius: single);
begin
   Init();
   Cylinder(major, minor, height, radius);
end;

procedure oxTPrimitiveModel.Cylinder(major, minor: longint; height, radius: single);
var
   i,
   j,
   nv: loopint;

   a,
   x,
   y,
   z0,
   z1,
   majorStep,
   minorStep: single;

begin
   majorStep := height / major;
   minorStep := 2 * vmcPI / minor;

   if(major < 2) or (minor < 3) then
      exit();

   Mesh.CullFace     := oxCULL_FACE_BACK;
   primitiveType     := oxmPRIMITIVE_CYLINDER;
   Mesh.Primitive    := oxPRIMITIVE_TRIANGLE_STRIP;

   Mesh.Data.nFaces := (major + 1)  * (minor + 1);
   Mesh.Data.nVertsPerFace := 2;

   Mesh.SetData(Mesh.Data.nFaces * 2, 0, Mesh.Data.nFaces * 2, Mesh.Data.nFaces * 2);

   nv := 0;

   for i := 0 to major do begin
      z0 := 0.5 * height - i * majorStep;
      z1 := z0 - majorStep;

      for j := 0 to minor do begin
			a := j * minorStep;
			x := radius * cos(a);
			y := radius * sin(a);

         Mesh.Data.v[nv][0] := x;
         Mesh.Data.v[nv][1] := y;
         Mesh.Data.v[nv][2] := z0;

         if(oxmPrimitive.Create.TextureCoords) then begin
            Mesh.Data.t[nv][0] := j / minor;
            Mesh.Data.t[nv][1] := i / major;
         end;

         if(oxmPrimitive.Create.Normals) then begin
            Mesh.Data.n[nv][0] := x / radius;
            Mesh.Data.n[nv][1] := y / radius;
            Mesh.Data.n[nv][2] := 0;
         end;

         inc(nv);

         Mesh.Data.v[nv][0] := x;
         Mesh.Data.v[nv][1] := y;
         Mesh.Data.v[nv][2] := z1;

         if(oxmPrimitive.Create.TextureCoords) then begin
            Mesh.Data.t[nv][0] := j / minor;
            Mesh.Data.t[nv][1] := (i + 1) / major;
         end;

         if(oxmPrimitive.Create.Normals) then begin
            Mesh.Data.n[nv][0] := x / radius;
            Mesh.Data.n[nv][1] := y / radius;
            Mesh.Data.n[nv][2] := 0;
         end;

         inc(nv);
      end;
   end;
end;

procedure oxTPrimitiveModel.Torus();
begin
   Torus(32, 32, 0.5, 2.0);
end;

procedure oxTPrimitiveModel.InitTorus(major, minor: longint; minorRadius, majorRadius: single);
begin
   Init();
   Torus(major, minor, minorRadius, majorRadius);
end;

procedure oxTPrimitiveModel.Torus(major, minor: longint; minorRadius, majorRadius: single);
var
   i,
   j,
   nv: loopint;

   a0,
   a1,
   b,
   majorStep,
   minorStep,

   x0,
   y0,
   x1,
   y1,
   c,
   r,
   z: single;

begin
   if(major < 2) or (minor < 3) then
      exit();

   Mesh.CullFace  := oxCULL_FACE_BACK;
   primitiveType  := oxmPRIMITIVE_TORUS;
   Mesh.Primitive := oxPRIMITIVE_TRIANGLE_STRIP;

   Mesh.Data.nFaces := (major + 1)  * (minor + 1);
   Mesh.Data.nVertsPerFace := 2;

   Mesh.SetData(Mesh.Data.nFaces * 2, 0, Mesh.Data.nFaces * 2, Mesh.Data.nFaces * 2);

   nv := 0;

   majorStep := 2.7 * vmcPI / major;
   minorStep := 2.7 * vmcPI / major;

   for i := 0 to major do begin
      a0 := i * majorStep;
      a1 := a0 + majorStep;
      x0 := cos(a0);
      y0 := sin(a0);

      x1 := cos(a1);
      y1 := sin(a1);

      for j := 0 to minor do begin
         b := j * minorStep;
         c := cos(b);
         r := minorRadius * c + majorRadius;
         z := minorRadius * sin(b);

         Mesh.Data.v[nv][0] := x0 * r;
         Mesh.Data.v[nv][1] := y0 * r;
         Mesh.Data.v[nv][2] := z;

         if(oxmPrimitive.Create.TextureCoords) then begin
            Mesh.Data.t[nv][0] := i / major;
            Mesh.Data.t[nv][1] := j / minor;
         end;

         if(oxmPrimitive.Create.Normals) then begin
            Mesh.Data.n[nv][0] := x0 * c;
            Mesh.Data.n[nv][1] := y0 * c;
            Mesh.Data.n[nv][2] := z / minorRadius;
         end;

         inc(nv);

         Mesh.Data.v[nv][0] := x1 * r;
         Mesh.Data.v[nv][1] := y1 * r;
         Mesh.Data.v[nv][2] := z;

         if(oxmPrimitive.Create.TextureCoords) then begin
            Mesh.Data.t[nv][0] := (i + 1) / major;
            Mesh.Data.t[nv][1] := j / minor;
         end;

         if(oxmPrimitive.Create.Normals) then begin
            Mesh.Data.n[nv][0] := x1 * c;
            Mesh.Data.n[nv][1] := y1 * c;
            Mesh.Data.n[nv][2] := z / minorRadius;
         end;

         inc(nv);
      end;
   end;
end;

procedure oxTPrimitiveModel.Cone();
begin
   InitCone(32, 1, 2);
end;

procedure oxTPrimitiveModel.InitCone(divisions: longint; radius, length: single);
begin
   Init();
   Cone(divisions, radius, length);
end;

procedure oxTPrimitiveModel.Cone(divisions: longint; radius, length: single);
var
   i,
   points: loopint;
   p,
   piece: single;

begin
   if(divisions < 3) then
      exit();

   Mesh.CullFace  := oxCULL_FACE_BACK;
   primitiveType  := oxmPRIMITIVE_CONE;
   Mesh.Primitive := oxPRIMITIVE_TRIANGLE_FAN;

   Mesh.Data.nFaces := divisions;
   Mesh.Data.nVertsPerFace := 2;

   points := Mesh.Data.nFaces * 2 + 2;

   Mesh.SetData(points, 0, points, points);

   {cone center}
   Mesh.Data.v[0][0] := 0;
   Mesh.Data.v[0][1] := length;
   Mesh.Data.v[0][2] := 0;

   { build cone }
   piece := (vmcPI * 2) / divisions;

   for i := 1 to divisions do begin
      p := piece * (i - 1);

      Mesh.Data.v[i][0] := sin(p) * radius;
      Mesh.Data.v[i][1] := 0;
      Mesh.Data.v[i][2] := cos(p) * radius;
   end;

   {repeat last point to close}
   p := 0;
   Mesh.Data.v[divisions + 1][0] := sin(p) * radius;
   Mesh.Data.v[divisions + 1][1] := 0;
   Mesh.Data.v[divisions + 1][2] := cos(p) * radius;
end;

procedure oxTPrimitiveModel.FromType(pT: oxTPrimitiveModelType);
begin
   if(pT = oxmPRIMITIVE_TRIANGLE) then
      Triangle()
   else if(pT = oxmPRIMITIVE_CIRCLE) then
      Circle()
   else if(pT = oxmPRIMITIVE_DISK) then
      Disk()
   else if(pT = oxmPRIMITIVE_QUAD) then
      Quad()
   else if(pT = oxmPRIMITIVE_CUBE) then
      Cube()
   else if(pT = oxmPRIMITIVE_SPHERE) then
      Sphere(oxmPRIMITIVE_SPHERE_METHOD_ENHANCED)
   else if(pT = oxmPRIMITIVE_CYLINDER) then
      Cylinder()
   else if(pT = oxmPRIMITIVE_TORUS) then
      Torus()
   else if(pT = oxmPRIMITIVE_CONE) then
      Cone()
   else
      log.e('Unsupported primitive type when called FromType()');
end;

procedure oxTPrimitiveModel.FromType();
begin
   FromType(primitiveType);
end;

INITIALIZATION
   oxmPrimitive.Defaults.CircleDivisions   := 45;
   oxmPrimitive.Defaults.SphereStacks      := 10;
   oxmPrimitive.Defaults.SphereSlices      := 15;

   oxmPrimitive.Create.TextureCoords := true;
   oxmPrimitive.Create.Normals := true;

END.
