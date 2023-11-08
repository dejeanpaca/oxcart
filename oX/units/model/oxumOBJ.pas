{
   oxumOBJ, OBJ model loader
   Copyright (C) 2011. Dejan Boras

   TODO: Maybe try to optimize the wasUseMtl := false redundancy
}

{$INCLUDE oxheader.inc}
UNIT oxumOBJ;

INTERFACE

   USES
      uStd, uLog, StringUtils, uFileHandlers, vmVector, uFile, uFiles, uColors,
      {oX}
      oxuTypes, oxuPaths,
      oxuFile, oxuMaterial, oxuModel, oxuModelFile, oxuMesh, oxuSerializationString, oxuPrimitives;

IMPLEMENTATION

CONST
     MAX_SUPPORTED_FACE_POINTS = 256;

TYPE
   { TLoaderData }

   TLoaderData = record
      MaterialCount,

      {total vertex loaded so far}
      TotalV,
      {total normals loaded so far}
      TotalN,
      {total uv loaded so far}
      TotalUV: loopint;

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
   matfn := oxPaths.Find(matfn);

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
            diffuse := cWhite4f;
            oxsSerialization.Deserialize(value, color);
            diffuse.Assign(color);

            {$IFDEF OX_DEBUG}
            if(m.GetShaderIndex('color') > -1) then
            {$ENDIF}
               m.SetColor('color', diffuse);

            {$IFDEF OX_DEBUG}
            if(m.GetShaderIndex('diffuse') > -1) then
            {$ENDIF}
               m.SetColor('diffuse', diffuse);
         end else if(key = 'Ks') then begin {specular}
            oxsSerialization.Deserialize(value, color);

            {$IFDEF OX_DEBUG}
            if(m.GetShaderIndex('specular') > -1) then
            {$ENDIF}
               m.SetColor('specular', color);
         end else if(key = 'd') then begin {dissolve (transparency)}
            Val(value, fValue, code);

            if(code <> 0) then begin
               diffuse[3] := fValue;
               m.SetColor('color', diffuse);

               {$IFDEF OX_DEBUG}
               if(m.GetShaderIndex('transparency') > -1) then
               {$ENDIF}
                  m.SetFloat('transparency', fValue);
            end;
         end else if(key = 'Tr') then begin {transparency (1 - d)}
            Val(value, fValue, code);

            if(code <> 0) then begin
               diffuse[3] := 1 - fValue;
               m.SetColor('color', diffuse);

               {$IFDEF OX_DEBUG}
               if(m.GetShaderIndex('transparency') > -1) then
               {$ENDIF}
                  m.SetFloat('transparency', 1 - fValue);
            end;
         end;
      until matf.EOF() or (matf.Error <> 0);

      matf.Close();
   end else
      data.SetError(matf.Error, 'Failed to read materials file: ' + matf.GetErrorString());
end;

procedure scan(var data: oxTFileRWData; var ld: TLoaderData);
var
   s,
   key,
   value: StdString;

   lineCount,
   vertexCount,
   normalCount,
   texCoordCount,
   faceCount,
   facePointCount: loopint;

   hasVertex,
   hasFaces,
   wasUseMtl: Boolean;

   m: oxPMesh;

   procedure reset(); inline;
   begin
      hasVertex := false;
      hasFaces := false;
      vertexCount := 0;
      normalCount := 0;
      texCoordCount := 0;
      faceCount := 0;
      facePointCount := 0;
      wasUseMtl := false;
   end;

   procedure meshDone();
   begin
      if(m <> Nil) and (data.f^.Error = 0) then begin
         m^.SetVertices(vertexCount);
         m^.SetNormals(normalCount);
         m^.SetTexCoords(texCoordCount);
         m^.Data.nFaces := faceCount;

         m^.Data.nVertsPerFace := oxPrimitivePoints[loopint(m^.Primitive)];
         m^.Data.nIndices := faceCount * m^.Data.nVertsPerFace;
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

            wasUseMtl := false;
         end else begin
            if(m <> nil) then begin
               if(key = 'v') then begin
                  inc(vertexCount);
                  hasVertex := true;

                  if(hasFaces) then
                     data.SetError(eINVALID, 'Invalid (v) order at line' + sf(lineCount));

                  wasUseMtl := false;
               end else if(key = 'vn') then begin
                  inc(normalCount);

                  if(hasFaces) then
                     data.SetError(eINVALID, 'Invalid (vn) order at line ' + sf(lineCount));

                  wasUseMtl := false;
               end else if(key = 'vt') then begin
                  inc(texCoordCount);

                  if(hasFaces) then
                     data.SetError(eINVALID, 'Invalid (vt) order at line ' + sf(lineCount));

                  wasUseMtl := false;
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

                  wasUseMtl := false;
               end else if(key = 'usemtl') then begin
                  inc(m^.Materials.n);
                  wasUseMtl := true;
               end else if(key = 's') then begin
                  if(not wasUseMtl) then
                     inc(m^.Materials.n);

                  wasUseMtl := false;
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
   texCoordIndex,
   previousFace,
   currentFace,
   currentMaterial,
   facePointCount,
   vertsPerFace: loopint;

   indices: array of dword = nil;
   longIndices: boolean;

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
   hasUV,
   wasUseMtl: boolean;

   newV: array of TVector3f;
   newUV: array of TVector2f;

   procedure reset(); inline;
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
      texCoordIndex := 0;

      hasUV := false;
      hasN := false;

      m := nil;
      pM := nil;
      materialName := '';
      wasUseMtl := false;
   end;

   procedure meshDone();
   var
      z: loopint;

   begin
      if(m <> nil) then begin
         {if nothing set (no faces) assume we have triangles}
         if(m^.Primitive = oxPRIMITIVE_NONE) then
            m^.Primitive := oxPRIMITIVE_TRIANGLES;

         longIndices := false;

         inc(ld.TotalV, m^.Data.nVertices);

         {we have to have allocated indices}
         if (Length(indices) > 0) and (m^.Data.nIndices > 0) then begin
            {check if we need long indices (dword)}
            for z := 0 to m^.Data.nIndices - 1 do begin
               if(indices[ivOffset + z] > 65535) then begin
                  longIndices := true;
                  break;
               end;
            end;

            if(not longIndices) then
               m^.SetIndices(m^.Data.nFaces * m^.Data.nVertsPerFace)
            else
               m^.SetIndicesL(m^.Data.nFaces * m^.Data.nVertsPerFace);

            if(not longIndices) then begin
               for z := 0 to m^.Data.nIndices - 1 do begin
                  m^.Data.i[z] := indices[ivOffset + z];
               end;
            end else
               Move(indices[ivOffset], m^.Data.il[0], SizeOf(m^.Data.il[0]) * m^.Data.nIndices);
         end;

         if(hasN) and (m^.Data.n <> nil) and (inOffset > -1) then begin
            SetLength(newV, m^.Data.nVertices);
            inc(ld.TotalN, m^.Data.nNormals);

            oxPrimitives.Reindex(@indices[inOffset], pdword(@indices[ivOffset]), m^.Data.nIndices,
               @m^.Data.n[0], PVector3f(@newV[0]));
            SetLength(m^.Data.n, 0);

            m^.Data.n := newV;
            m^.Data.nNormals := m^.Data.nVertices;
            newV := nil;
         end;

         if(hasUV) and (m^.Data.t <> nil) and (iuvOffset > -1) then begin
            SetLength(newUV, m^.Data.nVertices);
            inc(ld.TotalUV, m^.Data.nTexCoords);

            oxPrimitives.Reindex(@indices[iuvOffset], pdword(@indices[ivOffset]), m^.Data.nIndices, @m^.Data.t[0], PVector2f(@newUV[0]));
            SetLength(m^.Data.t, 0);

            m^.Data.t := newUV;
            m^.Data.nTexCoords := m^.Data.nVertices;
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
   end;

   procedure getMaterial();
   begin
      if(m = nil) then
         exit;

      if currentMaterial < m^.Materials.n then begin
         pM := @m^.Materials.List[currentMaterial];
         pM^.Material := ld.Model.Materials.FindByName(materialName);

         {get starting indice}
         pM^.StartIndice := currentFace * vertsPerFace;

         if(pM^.StartIndice > m^.Data.nIndices) then begin
            data.SetError(eUNEXPECTED, 'Invalid indice starting position for material: ' + materialName);
            pM^.StartIndice := 0;
         end;

         previousFace := currentFace;
      end else
         pM := nil;

      inc(currentMaterial);

      if(currentMaterial > m^.Materials.n) then
         data.SetError(eUNEXPECTED, 'Improperly scanned number of materials for mesh: ' + sf(meshIndex));
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
   var
      v: loopint;

   begin
      v := face[source].v - ld.TotalV;

      setIndice(v, ivOffset + where);

      if(v > m^.Data.nVertices) then
         data.SetError(eUNSUPPORTED, 'Failed to set vertex indice because out of range');

      if(hasUV) then begin
         v := face[source].uv - ld.TotalUV;

         setIndice(v, iuvOffset + where);

         if(v > m^.Data.nTexCoords) then
            data.SetError(eUNSUPPORTED, 'Failed to set tex coord indice because out of range');
      end;

      if(hasN) then begin
         v := face[source].n - ld.TotalN;

         setIndice(v, inOffset + where);

         if(v > m^.Data.nNormals) then
            data.SetError(eUNSUPPORTED, 'Failed to set normal indice because out of range');
      end;
   end;

begin
   data.f^.Seek(0);
   if(data.f^.Error <> 0) then
      exit;

   reset();
   nIndices := 0;
   meshIndex := 0;
   vertsPerFace := 0;

   indiceStrings[0] := '';
   indiceStrings[1] := '';
   indiceStrings[2] := '';

   faceStrings[0] := '';
   faceStrings[1] := '';
   faceStrings[2] := '';
   faceStrings[3] := '';

   ld.TotalV := 0;
   ld.TotalN := 0;
   ld.TotalUV := 0;

   ZeroPtr(@face, SizeOf(face));

   repeat
      data.f^.Readln(s);

      GetKeyValue(s, key, value, ' ');


      if(key = 'o') then begin
         materialDone();
         meshDone();

         if(meshIndex < ld.Model.Meshes.n) then begin
            m := @ld.Model.Meshes.List[meshIndex];
            vertsPerFace := m^.Data.nVertsPerFace;

            if(m^.Materials.n > 0) then
               m^.Materials.SetSize(m^.Materials.n);
         end else begin
            m := nil;
            data.SetError('Improperly scanned number of meshes');
            break;
         end;

         m^.Name := value;

         inc(meshIndex);
         wasUseMtl := false;
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
            wasUseMtl := false;
         end else if(key = 'vn') then begin
            if(normalIndex < m^.Data.nNormals) then begin
               if(not oxsSerialization.Deserialize(value, m^.Data.n[normalIndex])) then begin
                  m^.Data.n[normalIndex] := vmvZero3f;
                  data.SetError(eINVALID, 'Invalid normal value: ' + value);
               end;
            end else
               log.e('Normal count exceed scanned value: ' + sf(m^.Data.nNormals));

            inc(normalIndex);
            wasUseMtl := false;
         end else if(key = 'vt') then begin
            if(texCoordIndex < m^.Data.nTexCoords) then begin
               if(not oxsSerialization.Deserialize(value, m^.Data.t[texCoordIndex])) then begin
                  m^.Data.t[texCoordIndex] := vmvZero2f;
                  data.SetError(eINVALID, 'Invalid tex coord value: ' + value);
               end;
            end else
               log.e('Tex coord count exceed scanned value: ' + sf(m^.Data.nTexCoords));

            inc(texCoordIndex);
            wasUseMtl := false;
         end else if(key = 'f') then begin
            facePointCount := CharacterCount(value, ' ') + 1;

            {get individual face points as a string}
            strExplode(value, ' ', faceStrings, facePointCount);

            {initialize structure if we're at the first face}
            if(currentFace = 0) then begin
               strExplode(faceStrings[0], '/', indiceStrings, 3);

               hasUV := indiceStrings[1] <> '';
               hasN := indiceStrings[2] <> '';

               iCurrentOffset := 0;

               ivOffset := getOffset();

               if(hasUV) then
                 iuvOffset := getOffset()
              else
                 iuvOffset := -1;

               if(hasN) then
                  inOffset := getOffset()
               else
                  inOffset := -1;

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

            wasUseMtl := false;
         end else if(key = 'usemtl') then begin
            wasUseMtl := true;
            materialName := value;

            materialDone();
            getMaterial();
         end else if(key = 's') then begin
            if(not wasUseMtl) then begin
               materialDone();
               getMaterial();
            end;

            wasUseMtl := false;
         end;
      end;
   until data.f^.EOF() or (data.f^.Error <> 0) or (data.Error <> 0);

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

   {failed loading model, fixup some aspects of it}
   if(pData^.Error <> 0) then begin
      options^.Model.Validate();
      exit;
   end;

   { we can't load this }
   if(loaderData.UnsupportedFaces) then begin
      pData^.SetError(eUNSUPPORTED, 'Unsupported face point count (not triangle or quad)');
      options^.Model.Validate();
      exit;
   end;

   {failed loading model, fixup some aspects of it}
   if(pData^.Error <> 0) then begin
      options^.Model.Validate();
      exit;
   end;

   {conversion notification}
   if(loaderData.HasPolygons) then
      log.w('Polygons will be converted to triangles for: ' + pData^.FileName)
   else if(loaderData.HasQuads) then
      log.w('Quads will be converted to triangles for: ' + pData^.FileName);

   {actually load the model}
   load(pData^, loaderData);

   {failed loading model, fixup some aspects of it}
   if(pData^.Error <> 0) then
      options^.Model.Validate();
end;


INITIALIZATION
   oxfModel.Readers.RegisterHandler(objLoader, 'obj', @objLoad);
   oxfModel.Readers.RegisterExt(objExt, '.obj', @objLoader);

END.
