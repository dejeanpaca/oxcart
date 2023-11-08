{
   oxumMS3D, MS3D(Milkshape 3D) model loader
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxumMS3D;

INTERFACE

   USES
      SysUtils, StringUtils, uFileHandlers, vmVector,
      {oX}
      oxuMaterials, oxuSkins, oxuModel, oxuTextures, oxuModelFile;

TYPE
   ms3dTID = array[0..9] of char;

CONST
   ms3dcID: ms3dTID = 'MS3D000000';

TYPE
   ms3dTHeader = packed record
      ID: ms3dTID;
      Version: int32;
   end;

   ms3dTVertex = packed record
      flags: uint8;
      Vertex: TVector3;
      boneID: int8;
      refCount: uint8;
   end;

   ms3dTTriangle = packed record
      flags: uint16;
      iVertex: TVector3us;
      vNormals: array[0..2] of TVector3;
      u, v: TVector3;
      smoothingGroup, groupIdx: uint8;
   end;

   ms3dTGroupF = packed record
      flags: uint8;
      name: string[31];
      nTriangles: uint16;
   end;

   ms3dTGroup = packed record
      flags: uint8;
      name: string[31];
      nTriangles: uint16;
      iTriangles: array of uint16;
      matIdx: int8;
   end;

   ms3dTMaterial = packed record
      Name: string[31];
      Ambient, 
      Diffuse,
      Specular, 
      Emissive: TVector4;
      Shinines,
      Transparency: single;
      Mode: int8;
      Texture, 
      Alphamap: string[127];
   end;

   {key frames will probably be supported in some future time, but not now}
(*   ms3dTKeyframerData = record
      AnimFPS, 
      curTime: single;
      TotalFrames: int32;
   end;

   ms3dTKeyFrameRot = record
      Time: single;
      Rotation: TVector3;
   end;

   ms3dTKeyFramePos = record
      Time: single;
      Position: TVector3;
   end;

   m3dTJoint = record
      Flags: uint8;
      Name, ParentName: string[32];
      Rotation, Position: TVector3;

      nKeyFramesRot, nKeyFramesPos: uint16;
      KeyFramesRot: array of ms3dTKeyFrameRot;
      KeyFramesPos: array of ms3dTKeyFramePos;
   end;*)

VAR
   oxmMS3DHandler: oxTModelHandler;

IMPLEMENTATION

VAR
   ms3dLoader: fhTHandler; {loader information}
   ms3dExt: fhTExtension;

procedure _eError(err, errd: TError);
begin
   oxmeRaise(err, errd);
end;

procedure _eError(err: TError);
begin
   _eError(err, 0);
end;


{reads in all data and converts it}
procedure readData(var ld: oxmTLoaderData);
var
   i, 
   j, 
   idx, 
   texID: uint32;
   pObj: oxmPObject = nil;

   {these will contain data loaded from the ms3d file}
   nVertices, nTriangles, nGroups, nMaterials, ngTriangles: uint16;
   Vertices: array of ms3dTVertex      = nil;
   Triangles: array of ms3dTTriangle   = nil;
   Groups: array of ms3dTGroup         = nil;
   Materials: array of ms3dTMaterial   = nil;

   pSkin: oxPSkin;
   pMaterial: oxPMaterial;
   pSubMat: oxPSubMaterial;
   sameTex: boolean = false;

   procedure cleanup();
   var
      i: int32;

   begin
      if(Vertices <> nil) then begin 
         SetLength(Vertices, 0); 
         Vertices := nil; 
      end;
      
      if(Triangles <> nil) then begin 
         SetLength(Triangles, 0); 
         Triangles := nil; 
      end;

      if(Materials <> nil) then begin 
         SetLength(Materials, 0);
         Materials := nil; 
      end;

      if(nGroups > 0) then begin
         for i := 0 to (nGroups-1) do begin
            SetLength(Groups[i].iTriangles, 0); 
            Groups[i].iTriangles := nil;
         end;
         
         Groups := nil; 
         nGroups := 0;
      end;
   end;

begin
   {... LOADING ...}

   {VERTICES}

   {get the number of vertices}
   nVertices := 0;
   oxmlBlockRead(ld, nVertices, SizeOf(nVertices));
   if(oxError <> 0) then 
      exit;

   {there must be at least 1 vertex}
   if(nVertices = 0) then begin
      _eError(eInvalid); 
      
      exit;
   end;

   {get enough memory to hold the vertices}
   SetLength(Vertices, nVertices);
   if(Length(Vertices) < nVertices) then begin
      _eError(eNO_MEMORY);
      exit;
   end;

   {read in the vertices}
   for i := 0 to (nVertices-1) do begin
      oxmlBlockRead(ld, Vertices[i], SizeOf(ms3dTVertex));
      if(oxError <> 0) then begin 
         cleanup(); 
         exit; 
      end;
   end;

   {TRIANGLES}
   {get the number of triangles}
   nTriangles := 0;
   oxmlBlockRead(ld, nTriangles, SizeOf(nTriangles));
   if(oxError <> 0) then begin 
      cleanup(); 
      exit; 
   end;

   if(nTriangles > 0) then begin
      {get enough memory to hold the triangles}
      SetLength(Triangles, nTriangles);
      if(Length(Triangles) < nTriangles) then begin
         _eError(eNO_MEMORY); begin 
         cleanup(); 
         exit; 
         end;
      end;

      {read in all the triangles}
      for i := 0 to (nTriangles-1) do begin
         oxmlBlockRead(ld, Triangles[i], SizeOf(ms3dTTriangle));
         if(oxError <> 0) then begin 
            cleanup(); 
            exit; 
         end;
      end;
   end;

   {GROUPS}
   {get the number of groups}
   oxmlBlockRead(ld, nGroups, SizeOf(nGroups));
   if(oxError <> 0) then begin 
      cleanup(); 
      exit; 
   end;

   if(nGroups > 0) then begin
      {get enough memory to hold the groups}
      SetLength(Groups, nGroups);
      if(Length(Groups) < nGroups) then begin
         _eError(eNO_MEMORY); 
         cleanup(); 
         exit;
      end;

      {read in all the groups}
      for i := 0 to (nGroups-1) do begin
         {initialize a group}
         Zero(Groups[i], SizeOf(ms3dTGroup));

         {read the group header}
         oxmlBlockRead(ld, Groups[i], SizeOf(ms3dTGroupF));
         if(oxError <> 0) then begin 
            cleanup(); 
            exit; 
         end;

         {get memory for the triangle indices}
         SetLength(Groups[i].iTriangles, Groups[i].nTriangles);
         if(Length(Groups[i].iTriangles) < Groups[i].nTriangles) then begin
            _eError(eNO_MEMORY); 
            cleanup(); 
            exit; 
            end;
         end;

         {read the triangle indices}
         oxmlBlockRead(ld, Groups[i].iTriangles[0], 2 * Groups[i].nTriangles);
         if(oxError <> 0) then begin 
            cleanup(); 
            exit; 
         end;

         {read the material index}
         oxmlBlockRead(ld, Groups[i].matIdx, SizeOf(ms3dTGroup.matIdx));
         if(oxError <> 0) then begin 
            cleanup(); 
            exit; 
         end;
      end;
   end;

   {MATERIALS}
   {get the number of materials}
   nMaterials := 0;
   oxmlBlockRead(ld, nMaterials, SizeOf(nMaterials));
   if(oxError <> 0) then begin 
      cleanup(); 
      exit; 
   end;

   if(nMaterials > 0) then begin
      {get enough memory for all the materials}
      SetLength(Materials, nMaterials);
      if(Length(Materials) < nMaterials) then begin
         _eError(eNO_MEMORY); begin 
            cleanup(); 
            exit; 
         end;
      end;

      {read in all the materials}
      for i := 0 to (nMaterials-1) do begin
         oxmlBlockRead(ld, Materials[i], SizeOf(ms3dTMaterial));
         if(oxError <> 0) then begin 
            cleanup(); 
            exit; 
         end;

         {convert the strings to pascal shortstrings}
         Materials[i].Name       := pChar(@Materials[i].Name);
         Materials[i].Texture    := pChar(@Materials[i].Texture);
         Materials[i].AlphaMap   := pChar(@Materials[i].AlphaMap);
      end;
   end;

   {So far everything required is loaded.
   Next we need to convert everything back to the ox format.}

   {... CONVERTING ...}

   {OBJECTS}
   {There will be as many objects as there are groups}
   oxmAddObjects(ld.submodel^, nGroups);
   if(oxError <> 0) then begin 
      cleanup(); 
      exit; 
   end;

   {VERTICES}

   {only the first object will contain the vertices}
   pObj := ld.submodel^.Objects[0];

   {allocate memory for the vertices}
   oxmAddObjectVertices(pObj^, nVertices);
   if(oxError <> 0) then begin 
      cleanup(); 
      exit; 
   end;

   {copy all the vertices}
   for i := 0 to (nVertices-1) do
      pObj^.Vertices[i] := Vertices[i].Vertex;

   {now we can free the memory used by the vertices}
   SetLength(Vertices, 0); 
   Vertices := nil;

   {MATERIALS}
   {the next thing we should do is make the materials, if any}
   if(nMaterials > 0) then begin
      {first we need a skin}
      oxmAddSkins(ld.mdl^, 1);
      if(oxError <> 0) then begin 
         cleanup(); 
         exit; 
      end;

      pSkin := @ld.mdl^.Skins.s[0];

      {allocate memory for the materials}
      oxAddMaterials(pSkin^, nMaterials);
      if(oxError <> 0) then begin 
         cleanup(); 
         exit; 
      end;

      {convert one by one material}
      for i := 0 to (nMaterials-1) do begin
         {name}
         pMaterial         := @pSkin^.Materials.m[i];
         pMaterial^.sName  := Materials[i].Name;

         oxAddSubMaterials(pMaterial^, 1);
         if(oxError <> 0) then begin 
            cleanup(); 
            exit; 
         end;
         pSubMat := @pMaterial^.m[0];

         {texture map}
         texID          := oxmAddTexture(ld.mdl^, '', Materials[i].Texture, sameTex);
         pSubMat^.Tex   := texID;
         if(sameTex) then 
            pSubMat^.Properties := pSubMat^.Properties or oxcMATERIAL_TEXTURE_SHARED;

            {this needs to be fixed}
(*         {alpha map}
         texID := oxmAddTexture(ld.mdl^, '', Materials[i].AlphaMap, sameTex);
         pSubMat^.AlphaMap := texID;
         if(sameTex) then pSubMat^.Properties := pSubMat^.Properties or oxcMATERIAL_ALPHAMAP_SHARED;*)

         {colors}
         move(pSubMat^.Ambient, Materials[i].Ambient, 3);
         move(pSubMat^.Diffuse, Materials[i].Diffuse, 3);
         move(pSubMat^.Specular,Materials[i].Specular, 3);
         move(pSubMat^.Emissive,Materials[i].Emissive, 3);

         {shinines and opacity}
         pSubMat^.Shinines := Materials[i].Shinines;
         pSubMat^.Alpha    := Materials[i].Transparency;
      end;

      {done with the materials, now to free them}
      SetLength(Materials, 0); 
      Materials := nil;
   end;

   {TRIANGLES}
   {next point is to convert the triangles which is a bit tricky}

   { ... texture uv coordinates ... }
   {only the first object will contain triangle texture UV coordinates}

   {get memory for the UV coordinates}
   oxmAddObjectTexUV(pObj^, nTriangles*3);
   if(oxError <> 0) then begin 
      cleanup(); 
      exit; 
   end;

   {copy the uv coordinates}
   for i := 0 to (nTriangles-1) do begin
      for j := 2 downto 0 do begin
         pObj^.TexUV[i*3+j][0] := Triangles[i].U[j];
         pObj^.TexUV[i*3+j][1] := Triangles[i].V[j];
      end;
   end;

   {GROUPS}
   for i := 0 to (nGroups-1) do begin
      pObj := ld.submodel^.Objects[i];
      ngTriangles := Groups[i].nTriangles;

      { ... faces ... }
      {allocate as many faces as there are triangles in the group}
      oxmAddObjectFaces(pObj^, ngTriangles);
      if(oxError <> 0) then begin
         cleanup(); 
         exit; 
      end;

      oxmAddObjectFacesUV(pObj^, ngTriangles);
      if(oxError <> 0) then begin 
         cleanup(); 
         exit; 
      end;

      {get enough memory for the normals}
      oxmAddObjectNormals(pObj^, ngTriangles * 3);
      if(oxError <> 0) then begin 
         cleanup(); 
         exit; 
      end;

      {go through each triangle}
      for j := 0 to (ngTriangles-1) do begin
         idx := Groups[i].iTriangles[j];

         {copy the indices for the triangle vertices}
         pObj^.Faces[j][0] := Triangles[idx].iVertex[0];
         pObj^.Faces[j][1] := Triangles[idx].iVertex[1];
         pObj^.Faces[j][2] := Triangles[idx].iVertex[2];

         {generate the texture coordinate indices}
         pObj^.FacesUV[j][0] := idx * 3;
         pObj^.FacesUV[j][1] := idx * 3 + 1;
         pObj^.FacesUV[j][2] := idx * 3 + 2;

         {copy the normals}
         pObj^.Normals[j*3+0] := Triangles[idx].vNormals[0];
         pObj^.Normals[j*3+1] := Triangles[idx].vNormals[1];
         pObj^.Normals[j*3+2] := Triangles[idx].vNormals[2];
      end;

      {add the material index}
      if(Groups[i].matIdx >= 0) then pObj^.matID := Groups[i].matIdx+1
      else pObj^.matID := 0;
   end;

   cleanup();
end;

{reads and checks the header of the file is valid}
procedure readHeader(var ld: oxmTLoaderData);
var
   hdr: ms3dTHeader;

begin
   oxmlBlockRead(ld, hdr, SizeOf(ms3dTHeader));
   if(oxError <> 0) then
      exit;

   {check the id}
   if(hdr.ID <> ms3dcID) then begin 
      _eError(eInvalid); 
      exit; 
   end;

   {check the version}
   if(hdr.Version <> 3) and (hdr.Version <> 4) then begin
      _eError(eUnsupported); 
      exit;
   end;

   ld.mdl^.Version := hdr.Version;

   {create a new submodel and get a pointer to it}
   oxmAddSubModel(ld.mdl^);
   if(oxError <> 0) then 
      exit;
   ld.submodel := ld.mdl^.SubModels[ld.mdl^.nSubModels-1];
end;

{LOAD ROUTINE}
procedure ms3dLoad(data: pointer);
var
   ld: oxmPLoaderData;
begin
   ld := data;

   {read the header}
   readHeader(ld^);
   if(oxError <> 0) then 
      exit;

   {read data and convert it}
   readData(ld^);
   if(oxError <> 0) then 
      exit;

   {finish}
   ld^.mdl^.mHandler                   := @oxmMS3DHandler;
   ld^.submodel^.typeNormals           := oxmcNORMAL_TYPE_VERTEX;
   ld^.submodel^.SingleVerticesObject  := true;
end;

INITIALIZATION
   ms3dExt.ext       := '.ms3d';
   ms3dExt.Handler   := @ms3dLoader;

   ms3dLoader.Name   := 'MS3D';
   ms3dLoader.Handle := @ms3dLoad;

   oxmLoaderInfo.RegisterExt(ms3dExt);
   oxmLoaderInfoRegisterHandler(ms3dLoader);
END.
