{
   oxumOBJ, OBJ model loader
   Copyright (C) 2011. Dejan Boras

   Started On:    22.08.2007.
}

{$INCLUDE oxdefines.inc}
UNIT oxumOBJ;

INTERFACE

   USES
      uStd, uLog, StringUtils, uFileHandlers, vmVector, uFile, uFiles, uColors,
      {oX}
      uOX, oxuTypes, oxuFile, oxuMaterial, oxuModel, oxuModelFile, oxuMesh, oxuSerializationString, oxuPrimitives;

IMPLEMENTATION

TYPE
   { TLoaderData }

   TLoaderData = record
      MaterialCount: loopint;
      Model: oxTModel;
      InconsistentFaces,
      QuadWarn,
      ConvertQuads: boolean;
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
   value: string;
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
   value: string;

   vertexCount,
   normalCount,
   faceCount,
   previousFacePointCount,
   facePointCount: loopint;

   m: oxPMesh;

   procedure meshDone();
   begin
      if(m <> Nil) and (data.f^.Error = 0) then begin
         m^.SetVertices(vertexCount);
         m^.SetNormals(normalCount);
         m^.Data.nFaces := faceCount;

         if(not ld.InconsistentFaces) and m^.IsQuad() then begin
            m^.Primitive := oxPRIMITIVE_QUADS;

            if(not ld.QuadWarn) then begin
               log.w('Quads will be converted to triangles for: ' + data.FileName);
               ld.QuadWarn := true;
            end;
         end;

         m^.Data.nVertsPerFace := oxPrimitivePoints[loopint(m^.Primitive)];
         m^.SetIndices(faceCount * m^.Data.nVertsPerFace);
      end;

      vertexCount := 0;
      normalCount := 0;
      faceCount := 0;

      facePointCount := 0;
      previousFacePointCount := 0;

      m := nil;
   end;

begin
   m := nil;
   vertexCount := 0;
   normalCount := 0;
   faceCount := 0;

   facePointCount := 0;
   previousFacePointCount := 0;

   repeat
      data.f^.Readln(s);

      GetKeyValue(s, key, value, ' ');
      if(key = 'mtllib') then begin
         loadMaterials(data, ld, value);
      end else begin
         if(key = 'o') then begin
            meshDone();

            m := ld.Model.AddMesh();
            m^.Name := value;
         end else begin
            if(m <> nil) then begin
               if(key = 'v') then
                  inc(vertexCount)
               else if(key = 'vn') then
                  inc(normalCount)
               else if(key = 'f') then begin
                  inc(faceCount);

                  previousFacePointCount := facePointCount;
                  facePointCount := CharacterCount(value, ' ');

                  if(previousFacePointCount <> 0) and (facePointCount <> previousFacePointCount) then begin
                     if(not ld.InconsistentFaces) then begin
                        ld.InconsistentFaces := true;
                        log.w('Faces have incosnistent number of points ' + m^.Name);
                        Break;
                     end;
                  end;

                  if(m^.Primitive <> oxPRIMITIVE_NONE) then begin
                     {NOTE: we'll assume if 3 spaces we have triangles, otherwise quads}
                     if(facePointCount = 3) then
                        m^.Primitive := oxPRIMITIVE_TRIANGLES
                     else if(facePointCount = 4) then
                        m^.Primitive := oxPRIMITIVE_QUADS;
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
   materialName: string;

   m: oxPMesh = nil;
   pM: oxPMeshMaterial;

   meshIndex,
   vertexIndex,
   normalIndex,
   previousFace,
   currentFace,
   currentMaterial: loopint;

   faces: array of dword = nil;

   indiceStrings: array[0..2] of ShortString;
   faceStrings: array[0..3] of ShortString;

   ivOffset,
   inOffset,
   iuvOffset,
   iCurrentOffset,
   i,
   nFaces: loopint;

   hasN,
   hasUV: boolean;

   newV: array of TVector3f;

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
            m^.Data.i[z] := faces[ivOffset + z];
         end;

         if(hasN) then begin
            SetLength(newV, m^.Data.nVertices);

            oxPrimitives.Reindex(@faces[inOffset], pdword(@faces[ivOffset]), m^.Data.nIndices, @m^.Data.n[0], @newV[0]);
            SetLength(m^.Data.n, 0);

            m^.Data.n := newV;
            m^.Data.nNormals := m^.Data.nVertices;
            newV := nil;
         end;

         {TODO: Handle UV}

         {convert quads to triangle if indicated to do so}
         if(m^.IsQuad() and ld.ConvertQuads) then begin
            if(not ld.QuadWarn) then begin
               ld.QuadWarn := true;
               log.v('Quads will be converted to triangles for ' + data.FileName);
            end;

            m^.QuadsToTriangles();
         end;
      end;

      reset();
   end;

   procedure materialDone();
   begin
      if(pM <> nil) then begin
         pM^.IndiceCount := (currentFace - previousFace) * m^.Data.nVertsPerFace;

         if(pM^.IndiceCount + pM^.StartIndice > m^.Data.nIndices) then begin
            log.w('Invalid indice count or starting position for material: ' + materialName);
            pM^.IndiceCount := 0;
            pM^.StartIndice := 0;
         end;
      end;

      materialName := '';
   end;

   procedure cleanup();
   begin
      nFaces := 0;
      SetLength(faces, 0);
   end;

   function getOffset(): loopint;
   begin
      Result := iCurrentOffset;
      inc(iCurrentOffset, m^.Data.nIndices);
   end;

   procedure setIndice(const s: string; where: loopint);
   var
      code,
      indice: loopint;

   begin
      if(where < nFaces) then begin
         Val(s, indice, code);

         if(code = 0) then
           faces[where] := indice - 1
         else
           faces[where] := 0;
      end;
   end;

begin
   data.f^.Seek(0);
   if(data.f^.Error <> 0) then
      exit;

   nFaces := 0;
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

   hasUV := false;
   hasN := false;

   m := nil;
   pM := nil;

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
               strExplode(value, ' ', faceStrings, m^.Data.nVertsPerFace);

               if(currentFace = 0) then begin
                  strExplode(faceStrings[0], '/', indiceStrings, 3);

                  hasUV := indiceStrings[1] <> '';
                  hasN := indiceStrings[2] <> '';

                  ivOffset := getOffset();

                  if(hasUV) then
                    iuvOffset := getOffset();

                  if(hasN) then
                    inOffset := getOffset();

                  nFaces := iCurrentOffset;
                  SetLength(faces, iCurrentOffset);
                  ZeroPtr(@faces[0], SizeOf(faces[0]) * iCurrentOffset);
               end;

               for i := 0 to m^.Data.nVertsPerFace - 1 do begin
                  strExplode(faceStrings[i], '/', indiceStrings, 3);

                  {vertex (always assume is present)}
                  setIndice(indiceStrings[0], currentFace * m^.Data.nVertsPerFace + ivOffset + i);

                  if(hasUV) then
                     setIndice(indiceStrings[1], currentFace * m^.Data.nVertsPerFace + iuvOffset + i);

                  if(hasN) then
                     setIndice(indiceStrings[2], currentFace * m^.Data.nVertsPerFace + inOffset + i);
               end;

               inc(currentFace);
            end else if(key = 'usemtl') then begin
               materialDone();

               materialName := value;
               if(currentMaterial < m^.Materials.n) then begin
                  pM := @m^.Materials.List[currentMaterial];
                  pM^.Material := ld.Model.Materials.FindByName(materialName);

                  {get starting indice and number of faces for this material}
                  pM^.StartIndice := currentFace * m^.Data.nVertsPerFace;
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
   loaderData.ConvertQuads := options^.ConvertQuads;

   { scan pass }
   scan(pData^, loaderData);

   { we can't load this }
   if(loaderData.InconsistentFaces) then
      exit;

   { actually load the model }
   load(pData^, loaderData);
end;

procedure init();
begin
   oxfModel.Readers.RegisterHandler(objLoader, 'obj', @objLoad);
   oxfModel.Readers.RegisterExt(objExt, '.obj', @objLoader);
end;

INITIALIZATION
   ox.Init.iAdd('model.obj', @init);

END.
