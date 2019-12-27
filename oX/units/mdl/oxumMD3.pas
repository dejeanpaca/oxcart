{
   oxumMD3, MD3 model loader
   Copyright (C) 2007. Dejan Boras

   Started On:    12.06.2007.
}

{$INCLUDE oxdefines.inc}
UNIT oxumMD3;

{The order of MD3 models within the oxTModel structure goes like this:
sub-model no: model type
0: lower body
1: upper body
2: head
In case the model is not a player model(e.g. a weapon) then
sub-model 0 contains the entire model. This is all assuming the model was empty
when loading.}

INTERFACE

   USES
      uStd, uLog, uFileHandlers, q3uParser,
      vmVector,
      {oX}
      oxuTexture, oxuSkins, oxuModel, oxuQShaders;

CONST
   oxcMD3ID: array[0..3] of char    = ('I', 'D', 'P', '3');
   oxcMD3Version                    = 15;

   md3cConvert: boolean             = true;

   {flags, don't forget these need to be the same also in oxmMD3Shader}
   md3cFLAG_Q3_PLAYER               = $01;
   md3cFLAG_WEAPON                  = $02;

   {ANIMATION CONSTANTS}
   {both}
   q3cBOTH_DEATH1                   = $00;
   q3cBOTH_DEAD1                    = $01;
   q3cBOTH_DEATH2                   = $02;
   q3cBOTH_DEAD2                    = $03;
   q3cBOTH_DEATH3                   = $04;
   q3cBOTH_DEAD3                    = $05;

   {torso}
   q3cTORSO_GESTURE                 = $06;
   q3cTORSO_ATTACK                  = $07;
   q3cTORSO_ATTACK2                 = $08;

   q3cTORSO_DROP                    = $09;
   q3cTORSO_RAISE                   = $0A;

   q3cTORSO_STAND                   = $0B;
   q3cTORSO_STAND2                  = $0C;

   {legs}
   q3cLEGS_WALKCR                   = $0D;
   q3cLEGS_WALK                     = $0E;
   q3cLEGS_RUN                      = $0F;
   q3cLEGS_BACK                     = $10;
   q3cLEGS_SWIM                     = $11;

   q3cLEGS_JUMP                     = $12;
   q3cLEGS_LAND                     = $13;

   q3cLEGS_JUMPB                    = $14;
   q3cLEGS_LANDB                    = $15;

   q3cLEGS_IDLE                     = $16;
   q3cLEGS_IDLECR                   = $17;

   q3cLEGS_TURN                     = $18;

   q3cMAX_ANIMATIONS                = $19;


TYPE
   {MD3 Header}
   oxmmd3PHeader = ^oxmmd3THeader;
   oxmmd3THeader = record
      ID, Version: longword;
      FileName: String[67];
      nFrames, 
      nTags, 
      nMeshes, 
      nMaxSkins,
      HeaderLength, 
      offsetTag, 
      offsetTagEnd, 
      FileSize: longint;
   end;

   oxmmd3TTag = record
      Name: String[63];
      Position: TVector3;
      Rotation: TMatrix3;
   end;

   oxmmd3TBoneFrame = record
      Mins, Maxs, Position: TVector3; {Min(x, y, z) and max value for the bone,
      position of the bone(probably)}
      Scale: single; {bone scale}
      creator: String[15]; {program used to create the model}
   end;

   oxmmd3TMesh = record
      ID: array[0..3] of char;
      Name: String[67];
      nMeshFrames, 
      nSkins, 
      nVertices, 
      nTriangles,
      offsetTriangle, 
      HeaderSize, 
      offsetUV, 
      offsetVertex, 
      MeshSize: longint;
   end;

   oxmmd3TSkin = string[67];

   oxmmd3TTriangle = record
      vertex: TVector3s;
      EnvMap: TVector2ub; {normal values, or environment map, can't quite guess...}
   end;

   oxmmd3TUV = TVector2f;

   oxmmd3TFace = TVector3i;

   oxmmd3TData = record
      animcfg: q3pTStructure;
      shader: q3pTStructure;
   end;

VAR
   oxmMD3Handler: oxTModelHandler;

{loads a Quake III player model}
procedure md3LoadQ3Player(const fn: string; var model: oxTModel);

IMPLEMENTATION

VAR
   MD3Loader: fhTHandler; {loader information}
   MD3Ext: fhTExtension;

procedure raiseError(var ld: oxmTLoaderData; err: longint);
begin
   ld.errCode := err;
end;

function ioerr(var ld: oxmTLoaderData): longint;
begin
   ld.ioE := IOResult();

   if(ld.ioE <> 0) then
      ld.errCode := eIO;

   result := ld.ioE;
end;

procedure ioErrIgn();
begin
   IOResult();
end;

{load bone frames}
procedure md3LoadBoneData(var ld: oxmTLoaderData);
var
   i: longint;
   Bone: oxmmd3TBoneFrame;
   pHdr: oxmmd3PHeader;

begin
   pHdr := ld.Data;

   {allocate memory for the bone frames in the submodel}
   if(oxmAddBoneFrames(ld.submodel^, pHdr^.nFrames) = nil) then begin
      raiseError(ld, eNO_MEMORY); 
      exit;
   end;

   {process all bone}
   for i := 0 to (pHdr^.nFrames-1) do begin
      {read in the bones}
      if(oxmlBlockRead(ld, Bone, SizeOf(oxmmd3TBoneFrame)) < 0) then begin
         ld.log := 'Failed to read bone data';
         exit;
      end;

      {assign the bone}
      ld.submodel^.BoneFrames[i].vMin  := Bone.Mins;
      ld.submodel^.BoneFrames[i].vMax  := Bone.Maxs;
      ld.submodel^.BoneFrames[i].vPos  := Bone.Position;
      ld.submodel^.BoneFrames[i].Scale := Bone.Scale;
   end;
end;

{convert an md3 tag to oxTTag}
procedure md3ConvertTag(var md3tag: oxmmd3TTag; var tag: oxmTTag);
begin
   {convert tag name from pChar to string}
   tag.sName := pChar(@md3tag.name);
   if(md3cConvert) then begin
      tag.vPosition[0] :=  md3tag.Position[0];
      tag.vPosition[1] :=  md3tag.Position[2];
      tag.vPosition[2] := -md3tag.Position[1];
   end else
      tag.vPosition := md3tag.Position; {copy position vector}

   tag.Rotation := md3tag.Rotation;
end;

{load tags}
procedure md3LoadTags(var ld: oxmTLoaderDAta);
var
   i, nTags: longint;
   Tags: array of oxmmd3TTag;
   pHdr: oxmmd3PHeader;

begin
   pHdr := ld.Data;

   {seek to where the tags are placed}
   if(oxmlSeek(ld, pHdr^.offsetTag) < 0) then begin
      ld.log := 'Failed to seek to tags section';
      exit();
   end;

	{Add the required number of tags}
	nTags := pHdr^.nFrames * pHdr^.nTags;
   {for every frame of animation, there are pHdr^.nTags, which means
	there is pHdr^.nFrame * pHdr^.nTags total of tags}
	if(nTags > 0) then begin
      try
   	   SetLength(Tags, nTags);
      except
         raiseError(ld, eNO_MEMORY); 
         exit;
      end;

   	{read in the tags}
      oxmlBlockRead(ld, Tags[0], SizeOf(oxmmd3TTag) * nTags);

   	{now that we have the tags read in it is required to convert them to the
      oX model tags}

   	{add required number of tags to the sub-model}
   	if(oxmAddTags(ld.submodel^, nTags) = nil) then begin
         {set the amount of tags per frame}
      	ld.submodel^.nTagsPF := pHdr^.nTags;

      	{convert each tag}
      	for i := 0 to nTags-1 do begin
            md3ConvertTag(Tags[i], ld.submodel^.Tags[i]);
      	end;

      	{free memory used by md3 tags}
      	SetLength(Tags, 0);

         {go where the tags end}
         if(oxmlSeek(ld, pHdr^.offsetTagEnd) < 0) then begin
            ld.log := 'Failed to seek to tags section end';
            exit;
         end;
      end;
   end;
end;

{initialize links}
procedure md3InitializeLinks(var ld: oxmTLoaderData);
begin
   ld.submodel^.nLinks := ld.submodel^.nTags;
end;

procedure md3LoadObjects(var ld: oxmTLoaderData);
var
   {mesh position and information}
   i, 
   j, 
   mofs: longint;
   minfo: oxmmd3TMesh;

   {mesh data}
   skins: array of oxmmd3TSkin         = nil;
   TexCoords: array of oxmmd3TUV       = nil;
   Vertices: array of oxmmd3TTriangle  = nil;
   Triangles: array of oxmmd3TFace     = nil;

   pobject: oxmPObject;
   pHdr: oxmmd3PHeader;

begin
   pHdr := ld.Data;
   mofs := ld.fPos; {store file position}

   if(pHdr^.nMeshes = 0) then 
      exit;

   {add the same amount of objects as there are meshes}
   if(oxmAddObjects(ld.submodel^, pHdr^.nMeshes) = nil) then begin
      raiseError(ld, eNO_MEMORY); 
      exit();
   end;

   for i := 0 to (pHdr^.nMeshes-1) do begin
      {LOAD}

      {go to the start of the mesh and read the mesh header}
      if(oxmlSeek(ld, mofs) < 0) then begin
         ld.log := 'Failed to seek to the mesh header';
         exit;
      end;

      if(oxmlBlockRead(ld, minfo, SizeOf(oxmmd3TMesh)) < 0) then begin
         ld.log := 'Failed to read the mesh header';
         exit;
      end;

      if(minfo.nSkins > 0) then begin
         {allocate memory for skins}
         try
            SetLength(Skins, minfo.nSkins);
         except
            raiseError(ld, eNO_MEMORY); exit;
         end;

         {read in the skin information}
         if(oxmlBlockRead(ld, Skins[0], sizeof(oxmmd3TSkin)*minfo.nSkins) < 0) then begin
            ld.log := 'Failed to read the skins';
            exit;
         end;

         for j := 0 to (minfo.nSkins-1) do begin
            Skins[j] := pChar(@Skins[j][0]);
         end;

         {free memory used by md3 skin data}
         SetLength(Skins, 0);
      end;

      {allocate enough memory for md3 data}
      {texture UV}
      try
         SetLength(TexCoords, minfo.nVertices);
      except
         raiseError(ld, eNO_MEMORY); exit;
      end;

      {triangles}
      try
         SetLength(Triangles, minfo.nTriangles);
      except
         raiseError(ld, eNO_MEMORY);exit;
      end;

      {vertices}
      try
      SetLength(Vertices, minfo.nVertices * minfo.nMeshFrames);
      except
         raiseError(ld, eNO_MEMORY); exit;
      end;

      {read the triangle/face data}
      if(oxmlSeek(ld, mofs+minfo.offsetTriangle) < 0) then begin
         ld.log := 'Cannot seek to mesh face(triangles) data';
         exit;
      end;
      if(oxmlBlockRead(ld, Triangles[0], sizeof(oxmmd3TFace)*minfo.nTriangles) < 0) then begin
         ld.log := 'Cannot read the mesh face(triangles) data';
         exit;
      end;

      {read uv coordinate data}
      if(oxmlSeek(ld, mofs+minfo.offsetUV) < 0) then begin
         ld.log := 'Cannot seek to UV data';
         exit;
      end;

      if(oxmlBlockRead(ld, TexCoords[0], int64(sizeof(oxmmd3TUV))*int64(minfo.nVertices)) < 0) then begin
         ld.log := 'Cannot read the UV data';
         exit;
      end;

      {read in the vertex/face index information}
      if(oxmlSeek(ld, mofs+minfo.offsetVertex) < 0)then begin
         ld.log := 'Cannot seek to vertex data';
         exit;
      end;

      if(oxmlBlockRead(ld, Vertices[0], sizeof(oxmmd3TTriangle)*minfo.nMeshFrames*minfo.nVertices) < 0) then begin
         ld.log := 'Cannot read the vertex data';
         exit;
      end;

      {CONVERT}
      {now it is required to convert the md3 data into the TModel data}
      pobject := ld.submodel^.Objects[i];

      {get the objects name}
      pobject^.sName := pChar(@mInfo.Name);

      {assign counts for vertices, uv coordinates and faces}
      pobject^.nFrameVertices := minfo.nVertices;
      pobject^.nFrames        := minfo.nMeshFrames;

      {allocate memory for the three items mentioned above}
      if(not oxmAddObjectVertices(pobject^, minfo.nVertices * minfo.nMeshFrames)) then begin
         raiseError(ld, eNO_MEMORY);
         exit;
      end;

      if(not oxmAddObjectTexUV(pobject^, minfo.nVertices)) then begin
         raiseError(ld, eNO_MEMORY); 
         exit;
      end;

      if(not oxmAddObjectFaces(pobject^, minfo.nTriangles)) then begin
         raiseError(ld, eNO_MEMORY); 
         exit;
      end;

      if(not oxmAddObjectFacesUV(pobject^, minfo.nTriangles)) then begin
         raiseError(ld, eNO_MEMORY); 
         exit;
      end;

      {assign all vertices to the model structure}
      for j := 0 to (pobject^.nVertices)-1 do begin
         {Each vertex needs to be divided by 64 for some unknown reason.
         This may need more checking.}
         pobject^.Vertices[j][0] := Vertices[j].Vertex[0]   / 64.0;
         pobject^.Vertices[j][1] := Vertices[j].Vertex[2]   / 64.0;
         pobject^.Vertices[j][2] := -Vertices[j].Vertex[1]  / 64.0;
      end;

      {assign all texture uv coordinates to the model structure,
      and correct q3's funny UV mapping}
      for j := 0 to (pobject^.nTexUV-1) do begin
         pObject^.TexUV[j][0] :=  TexCoords[j][0];
         pObject^.TexUV[j][1] := -TexCoords[j][1];
      end;

      {assign all face data to the model structure}
      for j := 0 to (pobject^.nFaces-1) do begin
         {vertex indices}
         pobject^.Faces[j][0] := Triangles[j][0];
         pobject^.Faces[j][1] := Triangles[j][1];
         pobject^.Faces[j][2] := Triangles[j][2];

         {coordinate indices, same as vertex indices}
         pobject^.FacesUV[j][0] := Triangles[j][0];
         pobject^.FacesUV[j][1] := Triangles[j][1];
         pobject^.FacesUV[j][2] := Triangles[j][2];
      end;
      {object complete}

		{need to go to the position of the next mesh in the file}
		inc(mofs, minfo.MeshSize);
   end;

   {FREE MEMORY}
	{at last free the memory used by md3 data}
	SetLength(TexCoords, 0);
	SetLength(Triangles, 0);
	SetLength(Vertices, 0);
end;

{This procedure loads the data. Essentially it calls out routines
intended for loading individual pieces(bones, skins, frame and vertex
data, etc.)}
procedure md3LoadData(var ld: oxmTLoaderData);
begin
   md3LoadBoneData(ld);
   if(ld.errCode <> 0) then 
      exit;
   md3LoadTags(ld);
   if(ld.errCode <> 0) then 
      exit;
   md3InitializeLinks(ld);
   if(ld.errCode <> 0) then 
      exit;
   md3LoadObjects(ld);
   if(ld.errCode <> 0) then 
      exit;
end;

{The loading routine must be aware that there may already be sub-models
within them model, otherwise errors will occur.}
procedure md3LoadModel(var ld: oxmTLoaderData; const filename: string);
var
   pHdr: oxmmd3PHeader;

procedure logFile();
begin
   log.e('oxmMD3 > Error Loading file: '+filename);
end;

begin
   pHdr := ld.Data;

   {open the file}
   ld.ioE := FileReset(file(ld.f^), filename);
   if(ld.ioE <> 0) then begin
      logFile();
      raiseError(ld, eIO); 
      exit;
   end;


   {read in the file header}
   if(not oxmlBlockRead(ld, pHdr^, SizeOf(oxmmd3THeader)) < 0) then begin
      ld.log := 'Cannot read the header';
      exit;
   end;

   if(pHdr^.HeaderLength <> SizeOf(oxmmd3THeader)) then begin
      ld.log := 'Header size is not valid or supported';
      logFile();
   end;

   {check ID and version}
   if(pHdr^.ID <> longword(oxcMD3ID)) then begin
      ld.log := 'Invalid header ID';
      logFile();
      raiseError(ld, eINVALID); 
      exit;
   end;
   
   if(pHdr^.Version <> oxcMD3Version) then begin
      ld.log := 'Invalid or unsupported MD3 version';
      logFile();
      raiseError(ld, eUNSUPPORTED); 
      exit();
   end;

   {initialize the model by adding a new sub-model which will be filled with md3 data}
   if(oxmAddSubModel(ld.mdl^) = nil) then begin
      raiseError(ld, eNO_MEMORY); 
      exit;
   end;
   ld.submodel := ld.mdl^.SubModels[ld.mdl^.nSubModels - 1];

   {load the data}
   md3LoadData(ld);
   if(ld.errCode <> 0) then
      logFile();

   {close the file}
   Close(file(ld.f^));
   ioErrIgn();
end;

{associates objects with the specified tag with the specified matID}
procedure md3AssociateMaterial(var ld: oxmTLoaderData; const tag: string; matID: longint);
var
   j, 
   k: longint;
   pModel: oxPModel;
   pSubModel: oxPSubModel;
   pObject: oxmPObject;

begin
   pModel := ld.mdl;
   if(pModel^.Skins.n > 0) then begin
      {go through all sub-models and their objects}
      for j := 0 to (pModel^.nSubModels-1) do begin
         pSubModel := pModel^.SubModels[j];
         if(pSubModel^.nObjects > 0) then
         for k := 0 to (pSubModel^.nObjects-1) do begin
            pObject := pSubModel^.Objects[k];
            {check if they match and associate if they do}
            if(tag = pObject^.sName) then 
               pObject^.matID := matID;
         end;
      end;
   end;
end;

{loads the model skin}
procedure md3LoadSkin(var ld: oxmTLoaderData; const fn: string; cSkin: longint);
var
   skindata: q3pTStructure;
   i, matID: longint;
   idx: longint = -1;
   pTex: oxPTexture;
   pLine: q3pPLine;
   kTag, kFile: string; {keywords}
   pSkin: oxPSkin;
   pMaterial: oxPMaterial;
   pSubMat: oxPSubMaterial;
   sameTex: boolean = false;
   pShader: oxqPShader;

procedure logFile();
begin
   log.e('oxmMD3 > Error loading skin file: '+fn);
end;

begin
   {load the skin file using the parser}
   q3pInitStructure(skindata);
   q3pLoadFile(fn, skindata);
   if(q3pError <> 0) then begin
      q3pDisposeStructure(skindata); 
      logFile();
      raiseError(ld, oxeQ3PARSER); 
      exit;
   end;

   pSkin := @ld.mdl^.Skins.s[cSkin];

   if(skindata.nLines > 0) then
   for i := 0 to (skindata.nLines-1) do begin
      pLine := skindata.Lines[i];
      if(pLine = nil) then 
         continue;
      if(pLine^.nItems < 3) then 
         continue;

      {lines containing material data usually have the mesh name, a
      separator and the filename, but we only need the first and third items,
      the separator is ignored}

      {make sure that the first and third items are keywords}
      if(pLine^.Items[0].typeItem = q3pcKeyword)
         and (pLine^.Items[2].typeItem = q3pcKeyword) then begin
         {get the tag and the filename}
         kTag  := pShortString(pline^.Items[0].Data)^;
         kFile := pShortString(pline^.Items[2].Data)^;

         if(kTag = '') or (kFile = '') then 
            continue; {check for validity}

         pMaterial := oxAddMaterial(pSkin^);
         if(pMaterial = nil) then begin
            raiseError(ld, eNO_MEMORY); 
            exit;
         end;

         matID := (pSkin^.Materials.n-1);

         pShader := oxqFindShader(dExtractAllNoExt(kFile));
         if(pShader <> nil) then begin
            oxCopyMaterial(pShader^.mat, pMaterial^);
         end else begin
            pMaterial^.sName := kTag+' '+dExtractAllNoExt(kFile);

            if(kFile = 'null') then
               pMaterial^.Properties := pMaterial^.Properties or oxcMATERIAL_NO_RENDER;

            {add the filename as a texture map}
            if(pMaterial^.Properties and oxcMATERIAL_NO_RENDER = 0) then begin
               pTex := oxGetNewUniqueTexture(kFile, idx, sameTex);
       	      if(pTex = nil) then begin
                  raiseError(ld, eNO_MEMORY); 
                  exit();
               end;

               {add a sub-materials}
               pSubMat := oxAddSubMaterials(pMaterial^, 1);
       	      if(pTex = nil) then begin
                  raiseError(ld, eNO_MEMORY); 
                  exit();
               end;

               oxSetTextureFN(pTex^, kFile);

               pSubMat^.Tex := idx;
            end;
         end;

         md3AssociateMaterial(ld, kTag, matID);
      end;
   end;

   {free up the parser data for the skin file}
   q3pDisposeStructure(skindata);
end;

{load all the skins associated with the model}
procedure md3LoadSkins(var ld: oxmTLoaderData; const fn: string);
var
   nSkins, i: longint;
   skin: string;

{load all skin files for a model}
procedure loadSkin(cSkin: longint);
var
   pSkin: oxPSkin;

begin
   {set the skin name}
   pSkin := @ld.mdl^.Skins.s[cSkin];
   pSkin^.sName := ld.Skins[cSkin];
   if(pSkin^.sName <> '') then begin
      {load the corresponding skin files}
      if(ld.flags and md3cFLAG_Q3_PLAYER > 0) then begin
         md3LoadSkin(ld, fn +  'lower' + skin + '.skin', cSkin);
         md3LoadSkin(ld, fn + 'upper' + skin + '.skin', cSkin);
         md3LoadSkin(ld, fn + 'head' + skin + '.skin', cSkin);
      end else begin
         md3LoadSkin(ld, fn+'skin', cSkin);
      end;
   end else
      raiseError(ld, eNO_MEMORY);
end;

begin
   {get the number of skins}
   nSkins := 0;
   if(ld.skins <> nil) then
      nSkins := Length(ld.skins);

   {if no skins are present then load default}
   if(nSkins = 0) then begin
      if(oxmAddSkins(ld.mdl^, 1) = nil) then begin
         raiseError(ld, eNO_MEMORY); 
         exit;
      end;
      skin := '_default';
      loadSkin(0);
   {otherwise load all presented skins}
   end else begin
      if(oxmAddSkins(ld.mdl^, nSkins) = nil) then begin
         raiseError(ld, eNO_MEMORY); 
         exit;
      end;

      for i := 0 to (nSkins-1) do begin
         if(ld.skins[i] <> '') then
            skin := '_'+ld.skins[i]
         else
            skin := '';
         loadSkin(i);
      end;
   end;
end;

{load in the animation data}
procedure md3LoadAnimationConfigFile(var ld: oxmTLoaderData; const FileName: string);
var
   i: longint;
   torsoOffset: longint       = -1;
   anim: q3pTStructure;
   pLine: q3pPLine;
   torsoAnimStart: longint    = 0;
   legsAnimStart: longint     = 0;

   tAnim: oxmTKRAnim;
   sName: string;

procedure assignData(var anim: oxmTKRanim);
begin
   anim.sName        := tAnim.sName;
   anim.startFrame   := tAnim.startFrame;
   anim.nFrames      := tAnim.nFrames;
   anim.loopFrames   := tAnim.loopFrames;
   anim.framesPS     := tAnim.framesPS;
   anim.endFrame     := tAnim.startFrame + tAnim.nFrames;
end;

procedure addLegsAnim();
var
   panim: oxmPKRAnim;

begin
   {This is required to make the legs animation correct with certain
   animation.cfg files which have the animation start frame incorrectly set.
   This is caused by exporters which simply keep the LEGS frame count going up
   after the TORSO animations, though it should go up after the BOTH
   animations. It took a hell to figure this one out.}
   if(tAnim.sName <> '') then begin
      if(pos('legs_', lowercase(tAnim.sName)) > 0) then begin
         {get the position of the first LEGS animation}
         if(legsAnimStart = 0) then
            if(pos('legs_', lowercase(tAnim.sName)) > 0) then 
               legsAnimStart := tAnim.startFrame;

         if(torsoOffset = -1) then begin
            torsoOffset := legsAnimStart - torsoAnimStart;
         end;

         if(torsoOffset > 0) then
            tAnim.startFrame := tAnim.startFrame - torsoOffset;
      end;
   end;

   if(oxmAddKRAnim(ld.mdl^.SubModels[0]^) <> nil) then begin
      ld.mdl^.SubModels[0]^.KRAnims[ld.mdl^.SubModels[0]^.nKRAnims-1] := tAnim;

      panim := @ld.mdl^.SubModels[0]^.KRAnims[ld.mdl^.SubModels[0]^.nKRAnims-1];

      assignData(panim^);
   end else
      raiseError(ld, eNO_MEMORY);
end;

procedure addTorsoAnim();
var
   panim: oxmPKRAnim;

begin
   if(tAnim.sName <> '') then begin
      {get the position of the first torso animation}
      if(torsoAnimStart = 0) then
         if(pos('torso_', lowercase(tAnim.sName)) > 0) then 
            torsoAnimStart := tAnim.startFrame;
   end;

   if(oxmAddKRAnim(ld.mdl^.SubModels[1]^) = nil) then begin
      raiseError(ld, eNO_MEMORY); 
      exit;
   end;

   panim := @ld.mdl^.SubModels[1]^.KRAnims[ld.mdl^.SubModels[1]^.nKRAnims-1];
   assignData(panim^);
end;

procedure logFile();
begin
   log.e('oxmMD3 > Error loading animation configuration file: '+FileName);
end;

begin
   {load the skin file using the parser}
   q3pInitStructure(anim);
   q3pLoadFile(FileName, anim);
   if(q3pError <> 0) then begin
      q3pDisposeStructure(anim);
      logFile(); 
      raiseError(ld, oxeQ3PARSER); 
      exit;
   end;

   if(anim.nLines > 0) then
   for i := 0 to (anim.nLines-1) do begin
      pLine := anim.Lines[i];

      if(pLine = nil) then
         continue;
      if(pLine^.nItems < 4) then 
         continue;

      {check that all items are integer, if they are this is most
      likely a animation line}
      if(pLine^.Items[0].typeItem = q3pcInt) and
         (pLine^.Items[1].typeItem = q3pcInt) and
         (pLine^.Items[2].typeItem = q3pcInt) and
         (pLine^.Items[3].typeItem = q3pcInt) then begin

         {assign frame values}
         {$PUSH}{$HINTS OFF}
         tAnim.startFrame  := longint(pLine^.Items[0].Data); {first frame}
         tAnim.nFrames     := longint(pLine^.Items[1].Data); {number of frames}
         tAnim.loopFrames  := longint(pLine^.Items[2].Data); {looping frames}
         tAnim.framesPS    := longint(pLine^.Items[3].Data); {frames per second}
         {$POP}

         sName := '';

         {check if there is a comment and add it as the animation name}
         if(pLine^.nItems > 4) then begin
            if(pLine^.Items[4].typeItem = q3pcComment) then begin
               sName       := pShortString(pLine^.Items[4].Data)^;
               dStripWhiteSpace(sName);
               sName       := dCopy2Del(sName);
               tAnim.sName := sName;
            end;
         end;

         sName := LowerCase(sName);

         if(Pos('legs_', sName) <> 0) then begin
            addLegsAnim(); tanim.sName := '';
         end else if(Pos('torso_', sName) <> 0) then begin
            addTorsoAnim(); tanim.sName := '';
         end else if(Pos('both_', sName) <> 0) then begin
            addLegsAnim(); addTorsoAnim();
            tanim.sName := '';
         end;
       end;
   end;

   {free up the parser data for the skin file}
   q3pDisposeStructure(anim);
end;

{load a weapon shader}
procedure md3LoadWeaponShader(var ld: oxmTLoaderData; const FileName: string);
var
   f: text;
   ln: string = '';
   matID: longint;
   Idx: longint;
   texIdx: longint = -1;
   pSkin: oxPSkin;
   pMaterial: oxPMaterial;
   pSubMat: oxPSubMaterial;
   pSubmodel: oxPSubModel;
   sameTex: boolean = false;
   pTex: oxPTexture;

procedure logFile();
begin
   log.e('oxmMD3 > Error loading shader file: ' + FileName);
end;

procedure cleanup();
begin
   close(f); 
   ioErrIgn();
end;

begin
   {no point in loading the shader file if it does not exist}
   if(fExist(FileName) < 0) then 
      exit;

   {add a skin}
   oxmAddSkins(ld.mdl^, 1);
   pSkin := @ld.mdl^.Skins.s[ld.mdl^.Skins.n-1];

   pSubModel := ld.mdl^.SubModels[ld.mdl^.nSubModels-1];

   {initialize}
   if(Length(FileName) = 0) then
      exit();
   Idx := 0;

   {open the shader  file}
   ld.ioE := FileReset(f, FileName);
   if(ld.ioE <> 0) then begin
      raiseError(ld, eIO);
      logFile();
      exit;
   end;

   {process all lines}
   repeat
      {read line}
      readln(f, ln);
      if(ioerr(ld) <> 0) then begin 
         logFile(); 
         cleanup(); 
         break; 
      end;

      {add another texture}
      if(Length(ln) > 0) then begin
         {add the material}
         pMaterial := oxAddMaterial(pSkin^);
         if(pMaterial = nil) then begin
            raiseError(ld, eNO_MEMORY); 
            cleanup(); 
            exit;
         end;

         matID := pSkin^.Materials.n-1;

         ln    := dExtractFilePath(FileName)+ln;

         {add the texture name}
         pTex  := oxGetNewUniqueTexture(ln, texIdx, sameTex);

         {add a sub-material}
         pSubMat := oxAddSubMaterials(pMaterial^, 1);
         if(pSubMat = nil) then begin 
            raiseError(ld, eNO_MEMORY); 
            cleanup(); 
            exit; 
         end;

         {setup the sub-material}
         pSubMat^.Tex := texIdx;
         oxSetTextureFN(pTex^, ln);
         pSubMat^.uTile := 1.0;
         pSubMat^.vTile := 1.0;

         {assign the material to the object}
         if(pSubModel^.nObjects > Idx) then
            pSubModel^.Objects[Idx]^.matID := matID
         else 
            break;
         inc(Idx);
      end;
   until eof(f);

   cleanup();
end;

procedure md3DefaultTexture(var ld: oxmTLoaderData);
var
   pSkin: oxPSkin;
   pMaterial: oxPMaterial;
   pSubMat: oxPSubMaterial;
   pSubModel: oxPSubModel;
   pObject: oxmPObject;
   i, j, matID: longint;
   idx: longint = -1;
   sameTex: boolean = false;
   pTex: oxPTexture;

begin
   {add the default skin, material and texture}
   pSkin := oxmAddSkins(ld.mdl^, 1);
   if(pSkin = nil) then begin
      raiseError(ld, eNO_MEMORY); 
      exit;
   end;

   {add the material}
   pMaterial := oxAddMaterial(pSkin^);
   if(pMaterial = nil) then begin
      raiseError(ld, eNO_MEMORY); 
      exit;
   end;

   matID := pSkin^.Materials.n - 1;

   {TODO: Add support for default texture extensions other than .tga}

   {add the texture name}
   pTex := oxGetNewUniqueTexture('default.tga', idx, sameTex);
   if(pTex = nil) then begin
      raiseError(ld, eNO_MEMORY); 
      exit;
   end;

   {add a sub-material}
   pSubMat := oxAddSubMaterials(pMaterial^, 1);
   if(pSubMat = nil) then begin
      raiseError(ld, eNO_MEMORY);
      exit;
   end;

   {setup the sub-material}
   pSubMat^.Tex   := idx;
   pSubMat^.uTile := 1.0; 
   pSubMat^.vTile := 1.0;

   {now assign the material to all objects in the model}
   for i := 0 to (ld.mdl^.nSubModels-1) do begin
      pSubModel := ld.mdl^.SubModels[i];
      for j := 0 to (pSubModel^.nObjects-1) do begin
         pObject        := pSubModel^.Objects[j];
         pObject^.matID := matID;
      end;
   end;
end;

{the loading routine}
procedure md3Load(data: pointer);
var
   ld: oxmPLoaderData;
   fPath, 
   fn: string;
   md3spos: longint;
   hdr: oxmmd3THeader;
   defaultTex: boolean = false;

begin
   {INITIALIZE}
   ld          := data; 
   ld^.Data    := @hdr;

   fPath       := dExtractFilePath(fn);

   {get rid of the extension}
   md3spos := Pos('.md3', lowercase(fn));
   if(md3spos <> 0) then 
      delete(fn, md3spos, 4);

   {Associate the model with the md3 model handler}
   ld^.mdl^.mHandler := @oxmMD3Handler;

   {check to see if we have the default texture present}
   if(fExist(fPath+'default.tga') >= 0) then 
      defaultTex := true;

   {LOAD THE MODEL}

   {load quake III player model}
   if(ld^.Flags and md3cFLAG_Q3_PLAYER > 0) then begin
      {The lower, upper and head models need to be loaded.}
      md3LoadModel(ld^, fPath+'lower.md3');
      if(ld^.errCode <> 0) then exit;
      md3LoadModel(ld^, fPath+'upper.md3');
      if(ld^.errCode <> 0) then exit;
      md3LoadModel(ld^, fPath+'head.md3');
      if(ld^.errCode <> 0) then exit;

      {load the skins}
      md3LoadSkins(ld^, fPath);
      if(ld^.errCode <> 0) then ld^.errCode := 0;

      {load animation configuration file}
      md3LoadAnimationConfigFile(ld^, fPath+'animation.cfg');
      if(ld^.errCode <> 0) then ld^.errCode := 0;
   {request to load a weapon}
   end else if(ld^.Flags and md3cFLAG_WEAPON > 0) then begin
      {load the weapon}
      md3LoadModel(ld^, fn);
      if(ld^.errCode <> 0) then 
         exit;

      {if the default.tga file is present then we have a default skin}
      if(defaultTex) then begin
         md3DefaultTexture(ld^);
      end else begin
        {load the weapon shader}
        md3LoadWeaponShader(ld^, fn+'.shader');
      end;
   {just load a model}
   end else begin
      md3LoadModel(ld^, fn);
      if(ld^.errCode <> 0) then
         exit;

      if(defaultTex) then begin
         md3DefaultTexture(ld^);
      end else begin
         md3LoadSkins(ld^, fn);
      end;
   end;

   if(ld^.Flags and md3cFLAG_Q3_PLAYER > 0) then begin
      {setup linkage information}
      oxmAddLinkages(ld^.mdl^, 2);
      if(ld^.errCode <> 0) then 
         exit;

      ld^.mdl^.Linkages[0].sm1      := 1; 
      ld^.mdl^.Linkages[0].sm2      := 2;
      ld^.mdl^.Linkages[0].tagName  := 'tag_torso';

      ld^.mdl^.Linkages[1].sm1      := 2;
      ld^.mdl^.Linkages[1].sm2      := 3;
      ld^.mdl^.Linkages[1].tagName  := 'tag_head';

      {set the animations}
      oxmSetDefaultAnim(ld^.mdl^.SubModels[0]^, 'LEGS_IDLE');
      oxmSetDefaultAnim(ld^.mdl^.SubModels[1]^, 'TORSO_STAND');
   end;

   ld^.mdl^.msProperties := ld^.Flags;

   ld^.errCode := 0;
end;

procedure md3LoadQ3Player(const fn: string; var model: oxTModel);
begin
   oxmLoad(fn, model, md3cFLAG_Q3_PLAYER);
end;

INITIALIZATION
   MD3Ext.ext        := '.md3';
   MD3Ext.Handler    := @MD3Loader;

   MD3Loader.Name    := 'MD3';
   MD3Loader.Handle  := @md3Load;
   {the md3 loader itself will manage file opening and closing files}
   MD3Loader.DoNotOpenFile := true;

   oxmLoaderInfo.RegisterExt(MD3Ext);
   oxmLoaderInfo.RegisterHandler(MD3Loader);

   oxmMD3Handler.Dispose := nil;
END.
