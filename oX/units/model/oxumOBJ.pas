{
   oxumOBJ, OBJ model loader
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxumOBJ;

INTERFACE

   USES
      uStd, uLog, StringUtils, uFileHandlers, vmVector, uFile, uFiles, uColors,
      {oX}
      oxuTypes,
      oxuFile, oxuMaterial, oxuModel, oxuModelFile, oxuMesh, oxuSerializationString, oxuPrimitives;

IMPLEMENTATION

CONST
     MAX_SUPPORTED_FACE_POINTS = 256;

TYPE
   { TLoaderData }

   TLoaderData = record
      MaterialCount: loopint;
      Model: oxTModel;
      UnsupportedFaces,
      HasTris,
      HasQuads,
      HasPolygons: boolean;
   end;

VAR
   objLoader: fhTHandler; {loader information}
   objExt: fhTExtension;

procedure loadMaterials(var data: oxTFileRWData; var ld: TLoaderData; const materialLib: string);
var
   code: loopint;
   matf: TFile;
   matfn: string;
   s,
   key,
   value: StdString;
   m: oxTMaterial;
   diffuse: TColor4f;
   color: TColor3f;
   fValue: single;

begin
   matfn := IncludeTrailingPathDelimiterNonEmpty(ExtractFilePath(data.FileName)) + materialLib;
   m := nil;

   fFile.Init(matf);
   matf.Open(matfn);
   if(matf.Error = 0) then begin
      repeat
         matf.Readln(s);

         GetKeyValue(s, key, value, ' ');
         if(key = 'newmtl') then begin
            m := oxMaterial.Make();
            inc(ld.MaterialCount);

            log.v('Loading material: ' + value);

            m.Name := value;
            ld.Model.Materials.Add(m);
         end else if(key = 'Ka') then begin {ambient}
            oxsSerialization.Deserialize(value, color);
         end else if(key = 'Kd') then begin {diffuse}
            oxsSerialization.Deserialize(value, color);
            diffuse := cWhite4f;
            diffuse.Assign(color);
            m.SetColor('color', diffuse);
         end else if(key = 'Ks') then begin {specular}
            oxsSerialization.Deserialize(value, color);
         end else if(key = 'd') then begin {dissolve (transparency)}
            Val(value, fValue, code);

            if(code <> 0) then begin
               diffuse[3] := fValue;
               m.SetColor('color', diffuse);
               m.SetFloat('transparency', fValue);
            end;
         end else if(key = 'Tr') then begin {transparency (1 - d)}
            Val(value, fValue, code);

            if(code <> 0) then begin
               diffuse[3] := 1 - fValue;
               m.SetColor('color', diffuse);
               m.SetFloat('transparency', 1 - fValue);
            end;
         end;
      until matf.EOF() or (matf.Error <> 0);

      matf.Close();
   end else
      data.SetError(matf.Error);
end;

procedure scan(var data: oxTFileRWData; var ld: TLoaderData);
var
   s,
   key,
   value: StdString;

   lineCount,
   vertexCount,
   normalCount,
   faceCount,
   facePointCount: loopint;

   hasVertex,
   hasFaces: Boolean;

   m: oxPMesh;

   procedure reset();
   begin
      hasVertex := false;
      hasFaces := false;
      vertexCount := 0;
      normalCount := 0;
      faceCount := 0;
      facePointCount := 0;
   end;

   procedure meshDone();
   begin
      if(m <> Nil) and (data.f^.Error = 0) then begin
         m^.SetVertices(vertexCount);
         m^.SetNormals(normalCount);
         m^.Data.nFaces := faceCount;

         m^.Data.nVertsPerFace := oxPrimitivePoints[loopint(m^.Primitive)];
         m^.SetIndices(faceCount * m^.Data.nVertsPerFace);
      end;

      reset();

      m := nil;
   end;

begin
   m := nil;

   reset();
   lineCount := 0;

   repeat
      data.f^.Readln(s);
      inc(lineCount);

      GetKeyValue(s, key, value, ' ');
      if(key = 'mtllib') then begin
         loadMaterials(data, ld, value);
      end else begin
         if(key = 'o') then begin
            meshDone();

            m := ld.Model.AddMesh();
            m^.Name := value;
            m^.Primitive := oxPRIMITIVE_TRIANGLES;
         end else begin
            if(m <> nil) then begin
               if(key = 'v') then begin
                  inc(vertexCount);
                  hasVertex := true;

                  if(hasFaces) then
                     data.SetError(eINVALID, 'Invalid (v) order at line' + sf(lineCount));
               end else if(key = 'vn') then begin
                  inc(normalCount);

                  if(hasFaces) then
                     data.SetError(eINVALID, 'Invalid (vn) order at line ' + sf(lineCount));
               end else if(key = 'f') then begin
                  hasFaces := true;

                  if(not hasVertex) then
                     data.SetError(eINVALID, 'Invalid (f) order');

                  facePointCount := CharacterCount(value, ' ') + 1;

                  {triangles}
                  if(facePointCount = 3) then begin
                     inc(faceCount);
                     ld.HasTris := true;
                  {quads}
                  end else if(facePointCount = 4) then begin
                     inc(faceCount, 2);
                     ld.HasQuads := true;
                  end else if(facePointCount < MAX_SUPPORTED_FACE_POINTS) then begin
                     inc(faceCount, facePointCount - 2);
                     ld.HasPolygons := true;
                  end else begin
                     data.SetError(eUNSUPPORTED, 'Unsupported face point count ' + sf(facePointCount) + ' (not triangle or quad) at line ' + sf(lineCount));
                     ld.UnsupportedFaces := true;
                  end;
               end else if(key = 'usemtl') then begin
                  inc(m^.Materials.n);
               end;
            end;
         end;
      end;
   until data.f^.EOF() or (data.f^.Error <> 0);

   meshDone();
end;

procedure load(var data: oxTFileRWData; var ld: TLoaderData);
var
   s,
   key,
   value,
   materialName: StdString;

   m: oxPMesh = nil;
   pM: oxPMeshMaterial;

   meshIndex,
   vertexIndex,
   normalIndex,
   previousFace,
   currentFace,
   currentMaterial,
   facePointCount,
   vertsPerFace: loopint;

   indices: array of dword = nil;

   indiceStrings: array[0..2] of ShortString;
   faceStrings: array[0..MAX_SUPPORTED_FACE_POINTS] of ShortString;

   {currently read face}
   face: array[0..MAX_SUPPORTED_FACE_POINTS - 1] of record
      {vertex indice}
      v,
      {normal indice}
      n,
      {uv indice}
      uv: loopint;
   end;

   ivOffset,
   inOffset,
   iuvOffset,
   iCurrentOffset,
   i,
   nIndices,
   index: loopint;

   hasN,
   hasUV: boolean;

   newV: array of TVector3f;
   newUV: array of TVector2f;

   procedure reset();
   begin
      ivOffset := 0;
      iuvOffset := 0;
      inOffset := 0;

      currentFace := 0;
      previousFace := 0;
      currentMaterial := 0;
      iCurrentOffset := 0;

      vertexIndex := 0;
      normalIndex := 0;

      hasUV := false;
      hasN := false;

      m := nil;
      pM := nil;
      materialName := '';
   end;

   procedure meshDone();
   var
      z: loopint;

   begin
      if(m <> nil) then begin
         {if nothing set (no faces) assume we have triangles}
         if(m^.Primitive = oxPRIMITIVE_NONE) then
            m^.Primitive := oxPRIMITIVE_TRIANGLES;

         for z := 0 to m^.Data.nIndices - 1 do begin
            m^.Data.i[z] := indices[ivOffset + z];
         end;

         if(hasN) and (m^.Data.n <> nil) then begin
            SetLength(newV, m^.Data.nVertices);

            oxPrimitives.Reindex(@indices[inOffset], pdword(@indices[ivOffset]), m^.Data.nIndices,
               @m^.Data.n[0], PVector3f(@newV[0]));
            SetLength(m^.Data.n, 0);

            m^.Data.n := newV;
            m^.Data.nNormals := m^.Data.nVertices;
            newV := nil;
         end;

         if(hasUV) and (m^.Data.t <> nil) then begin
            SetLength(newUV, m^.Data.nVertices);

            oxPrimitives.Reindex(@indices[iuvOffset], pdword(@indices[iuvOffset]), m^.Data.nIndices, @m^.Data.t[0], PVector2f(@newUV[0]));
            SetLength(m^.Data.t, 0);

            m^.Data.t := newUV;
            m^.Data.nNormals := m^.Data.nVertices;
            newUV := nil;
         end;
      end;

      reset();
   end;

   procedure materialDone();
   begin
      if(pM <> nil) then begin
         pM^.IndiceCount := (currentFace - previousFace) * vertsPerFace;

         if(pM^.IndiceCount + pM^.StartIndice > m^.Data.nIndices) then begin
            data.SetError('Invalid indice count or starting position for material: ' + materialName);
            pM^.IndiceCount := 0;
            pM^.StartIndice := 0;
         end;
      end;

      materialName := '';
   end;

   procedure cleanup();
   begin
      nIndices := 0;
      SetLength(indices, 0);
   end;

   function getOffset(): loopint;
   begin
      Result := iCurrentOffset;
      inc(iCurrentOffset, m^.Data.nIndices);
   end;

   function getIndice(const s: string): loopint; inline;
   var
      code,
      indice: loopint;

   begin
      Val(s, indice, code);

      if(code = 0) then
         Result := indice - 1
      else
         Result := 0;
   end;

   procedure setIndice(which: loopint; offset: loopint); inline;
   var
      where: loopint;

   begin
      where := (currentFace * vertsPerFace) + offset;

      if(where < nIndices) and (which >= 0) then
         indices[where] := which
      else
         data.SetError(eINVALID, 'Failed to set indice because of miscalculation/invalid');
   end;

   procedure setFacePoint(source, where: loopint); inline;
   begin
      setIndice(face[source].v, ivOffset + where);

      if(hasUV) then
         setIndice(face[source].uv, iuvOffset + where);

      if(hasN) then
         setIndice(face[source].n, inOffset + where);
   end;

begin
   data.f^.Seek(0);
   if(data.f^.Error <> 0) then
      exit;

   nIndices := 0;
   meshIndex := 0;

   indiceStrings[0] := '';
   indiceStrings[1] := '';
   indiceStrings[2] := '';

   faceStrings[0] := '';
   faceStrings[1] := '';
   faceStrings[2] := '';
   faceStrings[3] := '';

   ivOffset := 0;
   iuvOffset := 0;
   inOffset := 0;

   currentFace := 0;
   previousFace := 0;
   currentMaterial := 0;
   iCurrentOffset := 0;

   vertexIndex := 0;
   normalIndex := 0;
   vertsPerFace := 0;

   hasUV := false;
   hasN := false;

   m := nil;
   pM := nil;

   ZeroPtr(@face, SizeOf(face));

   repeat
      data.f^.Readln(s);

      GetKeyValue(s, key, value, ' ');

      if(key = 'matlib') then
         loadMaterials(data, ld, value)
      else begin
         if(key = 'o') then begin
            if(m <> nil) then
               meshDone();

            if(meshIndex < ld.Model.Meshes.n) then begin
               m := @ld.Model.Meshes.List[meshIndex];
               vertsPerFace := m^.Data.nVertsPerFace;

               if(m^.Materials.n > 0) then
                  m^.Materials.SetSize(m^.Materials.n);
            end else begin
               m := nil;
               break;
            end;

            inc(meshIndex);
         end else if(m <> nil) then begin
            if(key = 'v') then begin
               if(vertexIndex < m^.Data.nVertices) then begin
                  if(not oxsSerialization.Deserialize(value, m^.Data.v[vertexIndex])) then begin
                     m^.Data.v[vertexIndex] := vmvZero3f;
                     data.SetError(eINVALID, 'Invalid vertex value: ' + value);
                  end;
               end else
                  log.e('Vertex count exceed scanned value: ' + sf(m^.Data.nVertices));

               inc(vertexIndex);
            end else if(key = 'vn') then begin
               if(normalIndex < m^.Data.nNormals) then begin
                  if(not oxsSerialization.Deserialize(value, m^.Data.n[normalIndex])) then begin
                     m^.Data.n[normalIndex] := vmvZero3f;
                     data.SetError(eINVALID, 'Invalid normal value: ' + value);
                  end;
               end else
                  log.e('Normal count exceed scanned value: ' + sf(m^.Data.nNormals));

               inc(normalIndex);
            end else if(key = 'f') then begin
               facePointCount := CharacterCount(value, ' ') + 1;

               {get individual face points as a string}
               strExplode(value, ' ', faceStrings, facePointCount);

               {initialize structure if we're at the first face}
               if(currentFace = 0) then begin
                  strExplode(faceStrings[0], '/', indiceStrings, 3);

                  hasUV := indiceStrings[1] <> '';
                  hasN := indiceStrings[2] <> '';

                  ivOffset := getOffset();

                  if(hasUV) then
                    iuvOffset := getOffset();

                  if(hasN) then
                    inOffset := getOffset();

                  nIndices := iCurrentOffset;
                  SetLength(indices, iCurrentOffset);
               end;

               {get individual indices for each face point}
               for i := 0 to facePointCount - 1 do begin
                  strExplode(faceStrings[i], '/', indiceStrings, 3);

                  face[i].v := getIndice(indiceStrings[0]);

                  if(indiceStrings[1] <> '') then
                     face[i].uv := getIndice(indiceStrings[1]);

                  if(indiceStrings[2] <> '') then
                     face[i].n := getIndice(indiceStrings[2]);
               end;

               if(facePointCount = 3) then begin
                  {we have a triangle}
                  setFacePoint(0, 0);
                  setFacePoint(1, 1);
                  setFacePoint(2, 2);

                  inc(currentFace);
               end else if(facePointCount = 4) then begin
                  {convert quads to tris}
                  setFacePoint(0, 0);
                  setFacePoint(1, 1);
                  setFacePoint(3, 2);
                  setFacePoint(3, 3);
                  setFacePoint(1, 4);
                  setFacePoint(2, 5);

                  inc(currentFace, 2);
               end else begin
                  for i := 2 to facePointCount - 1  do begin
                     index := i - 2;

                     {convert quads to tris}
                     setFacePoint(index, 0);
                     setFacePoint(index + 1, 1);
                     setFacePoint(facePointCount - 1, 2);

                     inc(currentFace);
                  end;
               end;
            end else if(key = 'usemtl') then begin
               materialDone();

               materialName := value;
               if(currentMaterial < m^.Materials.n) then begin
                  pM := @m^.Materials.List[currentMaterial];
                  pM^.Material := ld.Model.Materials.FindByName(materialName);

                  {get starting indice}
                  pM^.StartIndice := currentFace * vertsPerFace;

                  if(pM^.StartIndice > m^.Data.nIndices) then begin
                     log.w('Invalid indice starting position for material: ' + materialName);
                     pM^.StartIndice := 0;
                  end;

                  previousFace := currentFace;
               end else
                  pM := nil;

               inc(currentMaterial);
            end;
         end;
      end;
   until data.f^.EOF() or (data.f^.Error <> 0);

   materialDone();

   if(data.f^.Error = 0) then
      meshDone();

   cleanup();
end;


{LOAD ROUTINE}
procedure objLoad(data: pointer);
var
   pData: oxPFileRWData;
   loaderData: TLoaderData;

   options: oxPModelFileOptions;

begin
   pData := data;

   pData^.HandlerData := @loaderData;
   ZeroPtr(@loaderData, SizeOf(loaderData));
   options := oxPModelFileOptions(pData^.Options);
   loaderData.Model := options^.Model;

   { scan pass }
   scan(pData^, loaderData);

   { we can't load this }
   if(loaderData.UnsupportedFaces) then begin
      pData^.SetError(eUNSUPPORTED, 'Unsupported face point count (not triangle or quad)');
      options^.Model.Validate();
      exit;
   end;

   if(loaderData.HasPolygons) then
      log.w('Polygons will be converted to triangles for: ' + pData^.FileName)
   else if(loaderData.HasQuads) then
      log.w('Quads will be converted to triangles for: ' + pData^.FileName);

   { actually load the model }
   load(pData^, loaderData);
end;


INITIALIZATION
   oxfModel.Readers.RegisterHandler(objLoader, 'obj', @objLoad);
   oxfModel.Readers.RegisterExt(objExt, '.obj', @objLoader);

END.
