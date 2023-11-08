{
   oxum3DS, 3DS model loader for oX
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxum3DS;

{3DS model loader for oX.

- This loader is based on the v3.0 of the 3DS file format and may malfunction
with higher(and maybe with lower?) versions since their structure may be
different, but I am not quite sure about that.
- This loader currently does not support any kind of animations.}

INTERFACE

   USES
      uStd, sysutils, StringUtils, uColors, uLog,
      vmVector,
      uFile, uFileHandlers,
      {oX}
      oxuTexture, oxuSkins, oxuModel, oxuModelFile, oxuFile, oxuMesh, oxuMaterial;

CONST
   {CHUNK IDs}
   c3dsNULL                            = $0000;{null}
   c3dsVERSION                         = $0002;{version}
   {color chunks}
   c3dsCOLOR_FLOAT                     = $0010;
   c3dsCOLOR_24                        = $0011;
   c3dsCOLOR_LINEARFLOAT               = $0010;
   {percentage}
   c3dsPERCENTAGE_FLOAT                = $0030;
   c3dsPERCENTAGE_INT                  = $0031;
   c3dsMASTER_SCALE                    = $0100;

   c3dsBACKGROUND_COLOR                = $1200;{background color, obviously}

   c3dsPRIMARY                         = $4d4d;{main / primary chunk}

   c3dsOBJECTINFO                      = $3d3d;{mesh data}
   c3dsMESHVERSION                     = $3d3e;{mesh version}

   {object chunks}
   c3dsOBJECT                          = $4000;
   {sub-defines of OBJECT}
   c3dsOBJECT_MESH                     = $4100;
   c3dsOBJECT_LAMP                     = $4600;
   c3dsOBJECT_LAMP_SPOT                = $4610;
   c3dsOBJECT_LAMP_OFF                 = $4620;
   c3dsOBJECT_LAMP_ATTENUATE           = $4625;
   c3dsOBJECT_LAMP_RAYSHADE            = $4627;
   c3dsOBJECT_LAMP_SHADOWED            = $4630;
   c3dsOBJECT_LAMP_LOCAL_SHADOW        = $4640;
   c3dsOBJECT_LAMP_LOCAL_SHADOW2       = $4641;
   c3dsOBJECT_LAMP_SEE_CONE            = $4651;
   c3dsOBJECT_LAMP_SPOT_RECTANGULAR    = $4651;
   c3dsOBJECT_LAMP_SPOT_OVERSHOOT      = $4652;
   c3dsOBJECT_LAMP_SPOT_PROJECTOR      = $4653;
   c3dsOBJECT_LAMP_EXCLUDE             = $4654;
   c3dsOBJECT_LAMP_RANGE               = $4655;
   c3dsOBJECT_LAMP_ROLL                = $4656;
   c3dsOBJECT_LAMP_RAY_BIAS            = $4658;
   c3dsOBJECT_LAMP_INNER_RANGE         = $4659;
   c3dsOBJECT_LAMP_OUTER_RANGE         = $465A;
   c3dsOBJECT_LAMP_MULTIPLIER          = $465B;

   {sub-defines of OBJECT_MESH}
   c3dsOBJECT_VERTICES                 = $4110;
   c3dsPOINT_FLAG_ARRAY                = $4111;
   c3dsOBJECT_FACES                    = $4120;
   c3dsOBJECT_MATERIAL                 = $4130;
   c3dsMESH_TEXTURE_COORDS             = $4140;
   c3dsMESH_SMOOTH_GROUP               = $4150;
   c3dsMESH_TRANS_MATRIX               = $4160;
   c3dsMESH_VISIBLE                    = $4165;
   c3dsMESH_MAPPINGSTANDARD            = $4170;

   {material chunks}
   c3dsMATERIAL                        = $afff;
   c3dsMATERIAL_NAME                   = $A000;
   c3dsMATERIAL_AMBIENT                = $A010;
   c3dsMATERIAL_DIFFUSE                = $A020;
   c3dsMATERIAL_SPECULAR               = $a030;
   c3dsMATERIAL_SHININES               = $a040;
   c3dsMATERIAL_SHIN2PCT               = $a041;
   c3dsMATERIAL_TRANSPARENCY           = $a050;
   c3dsMATERIAL_XPFALL                 = $a052;
   c3dsMATERIAL_REFBLUR                = $a053;
   c3dsMATERIAL_SELF_ILLUM             = $a084;
   c3dsMATERIAL_WIRESIZE               = $a087;
   c3dsMATERIAL_XPFALLIN               = $a08a;
   c3dsMATERIAL_SHADING                = $a100;
   c3dsMATERIAL_TEXMAP                 = $a200;
   c3dsMATERIAL_SPECULAR_MAP           = $a204;
   c3dsMATERIAL_OPACITY_MAP            = $a210;
   c3dsMATERIAL_REFLECTION_MAP         = $a220;
   c3dsMATERIAL_BUMP_MAP               = $a230;
   c3dsMATERIAL_MAP_FILENAME           = $a300;

   {key frame}
   c3dsKEYF                            = $b000;
   c3dsKEYF_MESH_INFO                  = $b002;
   c3dsKEYF_OBJECT_NAME                = $b010;
   c3dsKEYF_START_AND_END              = $b008;
   c3dsPIVOT                           = $b013;
   c3dsPOSITION_TRACK_TAG              = $b020;
   c3dsROTATION_TRACK_TAG              = $b021;
   c3dsSCALE_TRACK_TAG                 = $b022;

TYPE
   oxT3DSChunk = record
      ID: word;
      Size, BytesRead: fileint;
   end;

IMPLEMENTATION

TYPE
   PLoaderData = ^TLoaderData;
   TLoaderData = record
      Version,
      MeshVersion: LongWord;
   end;

VAR
   m3DSLoader: fhTHandler;
   m3DSExt: fhTExtension;

{returns an empty object}

{READ ROUTINES}
{read a block}
{Reads a block from the oxmFile file, increments file position and performs other tasks aside from block reading.
Extra code required to manage certain things has been placed into this routine}
function xblockread(var data: oxTFileRWData; out buf; count: longint; var chunk: oxT3DSChunk): boolean;
var
   brres: fileint;

begin
   brres := data.f^.Read(buf, count);

   if(data.f^.Error = 0) then begin
      inc(chunk.BytesRead, brres);
      Result := true
   end else
      Result := false;
end;

{Seeks past a chunk. In order for this routine to correctly work, correct file position information must be maintained
(which is usually done with xblockread). This is a far better method than reading past a chunk since reading requires a buffer,
and takes more time.}
function SeekPast(var data: oxTFileRWData; var chunk: oxT3DSChunk): boolean;
var
   skip: longint;

begin
   skip := (chunk.size - chunk.bytesread);
   data.f^.Seek(skip, fSEEK_CUR);

   if(data.f^.Error = 0) then begin
      inc(chunk.BytesRead, skip);
      Result := true;
   end else
      Result := false;
end;

{CHUNKS & ELEMENTS}

{read a chunk}
function m3dsReadChunk(var data: oxTFileRWData; out chunk: oxT3DSChunk): boolean;
begin
   chunk.bytesread := 0;
   chunk.size := 0;

   {read the ID}
   xblockread(data, chunk.id, 2, chunk);
   if(data.f^.Error = 0) then begin
      {read the size}
      xblockread(data, chunk.size, 4, chunk);
      Result := data.f^.Error = 0;
   end else
      Result := false;
end;

{read up a null-terminated string to a pascal string}
procedure m3dsReadString(var data: oxTFileRWData; var st: string; var Chunk: oxT3DSChunk);
var
   _st: shortstring  = '';
   ch: char          = #0;
   posx: longint     = 0;

begin
   {initialize}
   if(not xblockread(data, ch, 1, Chunk)) then
      exit;

   if(ch = #0) then
      exit;

   {read up string}
   repeat
      inc(posx);
      _st[posx] := ch;
      if(not xblockread(data, ch, 1, Chunk)) then
         exit;
   until ch = #0;

   _st[0] := char(posx);

   st := _st;
end;

{simply reads a string and does nothing with it}
procedure m3dsReadStringNil(var data: oxTFileRWData; var chunk: oxT3DSChunk);
var
   s: string = '';

begin
   m3dsReadString(data, s, chunk);
   s := '';
end;

{read color | 24 bit}
procedure m3dsReadColor(var data: oxTFileRWData; out c; var PreviousChunk: oxT3DSChunk);
var
   TempChunk: oxT3DSChunk;

begin
	{read the color chunk}
   if(not m3dsReadChunk(data, TempChunk)) then
      exit;

   {read the appropriate color type}
   if(TempChunk.ID = c3dsCOLOR_24) then begin
      {read in the rgb colors, byte each, 3 bytes total}
      xblockread(data, c, 3, TempChunk);
   end else if (TempChunk.ID = c3dsCOLOR_FLOAT) then begin
      {read in the rgb colors, single each, 12 bytes total}
      xblockread(data, c, sizeof(TColor3f), TempChunk);
   end;

   if(data.f^.Error = 0) then
      inc(PreviousChunk.BytesRead, TempChunk.BytesRead);
end;

procedure m3dsReadColorNil(var ld: oxTFileRWData; var PreviousChunk: oxT3DSChunk);
var
   clr: TColor4f;

begin
   m3dsReadColor(ld, clr, PreviousChunk);
end;


procedure m3dsReadPercentage(var data: oxTFileRWData; var percentage; var PreviousChunk: oxT3DSChunk);
var
   TempChunk: oxT3DSChunk;

begin
   {read the percentage chunk}
   if(m3dsReadChunk(data, TempChunk)) then begin
      {read the appropriate percentage type}
      if(TempChunk.ID = c3dsPERCENTAGE_FLOAT) then
         xblockread(data, percentage, 4, TempChunk)
      else
         xblockread(data, percentage, 2, TempChunk);

      if(data.f^.Error = 0) then begin
         {skip the rest}
         SeekPast(data, TempChunk);

         inc(PreviousChunk.BytesRead, TempChunk.BytesRead);
      end;
   end;
end;

procedure m3dsReadPercentageNil(var data: oxTFileRWData; var previousChunk: oxT3DSChunk);
var
   percent: int64 = 0;

begin
   m3dsReadPercentage(data, percent, previousChunk);
end;

{MODEL PROCESSING}
{adds a new object to the model, which has to be filled in with data in order to be valid}
procedure m3dsAddModelObject(var data: oxTFileRWData; var chunk: oxT3DSChunk);
var
   options: oxPModelFileOptions;
   mesh: oxPMesh;

begin
   options := data.Options;
   mesh := options^.Model.AddMesh();

   {read the object name}
   m3dsReadString(data, mesh^.Name, Chunk);

   if(data.f^.Error = 0) and (oxfModel.LogExtended) then begin
      log.v('Added mesh: ' + sf(options^.Model.Meshes.n) + ' | Name: ' + mesh^.Name);
   end;
end;

{add new material to the model, which has to be filled in with data in order to be valid}
procedure m3dsAddModelMaterial(var data: oxTFileRWData);
var
   options: oxPModelFileOptions;

begin
   options := data.Options;

   options^.Model.GetSkin()^.AddMaterial();
end;

{CHUNK PROCESSING ROUTINES}

{reads in the vertices(points) of the current object}
procedure m3dsReadVertices(var data: oxTFileRWData; var PreviousChunk: oxT3DSChunk);
var
   mesh: oxPMesh;
   nVertices: longint = 0;
   options: oxPModelFileOptions;

begin
   options := data.Options;
   mesh := options^.Model.Meshes.GetLast();

   {first read in the number of vertices}
   if(not xblockread(data, nVertices, 2, PreviousChunk)) then
      exit;

   {allocate memory for all vertices}
   mesh^.SetVertices(nVertices);

   {read in all the vertices, the total amount of bytes to read in is the number
   of vertices times the size of each vector3}
   if(nVertices > 0) then begin
      if(not xblockread(data, mesh^.data.v[0], mesh^.Data.nVertices * sizeof(TVector3), PreviousChunk)) then
         exit;

      {Need to swap y and z axis, due to the Z-up coordinate system of 3DS}
      vmSwapCoords(vmcXZY, vmcXYZ, mesh^.data.v[0], mesh^.data.nVertices);
   end;
end;

{read the vertex indices}
procedure m3dsReadVertexIndices(var data: oxTFileRWData; var PreviousChunk: oxT3DSChunk);
var
   indexes: array[0..3] of word  = (0, 0, 0, 0);
   i: longint                    = 0;
   nFaces: longint               = 0;
   mesh: oxPMesh;
   options: oxPModelFileOptions;

begin
   options := data.Options;
   mesh := options^.Model.Meshes.GetLast();

   {first it is required to read the number of faces}
   if(not xblockread(data, nFaces, 2, PreviousChunk)) then
      exit;

   {now, allocate enough memory for all faces}
   mesh^.SetIndices(nFaces * 3);

   {read in all vertex indices | the fourth value, visibility, is read but never assigned}
   for i := 0 to (nFaces - 1) do begin
         if(not xblockread(data, indexes, sizeof(indexes), PreviousChunk)) then
            exit;

         mesh^.Data.i[i * 3 + 0] := indexes[0];
         mesh^.Data.i[i * 3 + 1] := indexes[1];
         mesh^.Data.i[i * 3 + 0] := indexes[2];

         {obj^.Faces[i].iUV[0] := 0;
         obj^.Faces[i].iUV[1] := 0;}
   end;
end;

{reads in object material, and binds an object to the material}
procedure m3dsReadObjectMaterial(var data: oxTFileRWData; var PreviousChunk: oxT3DSChunk);
var
   i: longint;
   MatName: string = '';
   model: oxTModel;
   skin: oxPSkin;
   mat: oxTMaterial;
   options: oxPModelFileOptions;

begin
   options := data.Options;
   model := options^.Model;
   skin := model.GetSkin();

   {first load in the name of this material}
   m3dsReadString(data, MatName, PreviousChunk);
   if(not data.Ok()) then
      exit;

   {process the materials}
   for i := 0 to (model.Materials.n - 1) do begin
      mat := model.Materials[i];

      if(MatName = mat.Name) then begin
         skin^.SetIntoSlot(model.Meshes.n - 1, mat);
      end;
   end;

   {skip the rest}
   if(not SeekPast(data, PreviousChunk)) then
      exit;

   if(oxfModel.LogExtended) then
      log.v('Read Object Material: ' + MatName);
end;

{reads texture coordinates for the mesh}
procedure m3dsReadMeshTextureCoordinates(var data: oxTFileRWData; var PreviousChunk: oxT3DSChunk);
var
   mesh: oxPMesh;
   nTexUV: longint = 0;

begin
   mesh := oxPModelFileOptions(data.Options)^.Model.Meshes.GetLast();

   {first read in the indice count}
   if(not xblockread(data, nTexUV, 2, PreviousChunk)) then
      exit;

   {allocate enough memory to read in all indices}
   mesh^.SetTexCoords(nTexUV);

   {now read in all indices}
   if(not xblockread(data, mesh^.Data.t[0], PreviousChunk.Size - PreviousChunk.BytesRead, PreviousChunk)) then
      exit;

   if(oxfModel.LogExtended) then
      log.v('Read mesh texture coordinates. Count: ' + sf(mesh^.data.nTexCoords));
end;

procedure readTexMap(var data: oxTFileRWData; var PreviousChunk: oxT3DSChunk);
var
   texMAp: string = '';
   mat: oxTMAterial = nil;
   tex: oxTTexture;
   model: oxTModel;

begin
   model := oxPModelFileOptions(data.options)^.Model;
   m3dsReadString(data, texMap, PreviousChunk);

   if(texMap <> '') then begin
      mat := model.GetLastMaterial();

      if(mat <> nil) then begin
         tex := model.GetTexture(texMap);

         {unused texture, set it up}
         if(tex <> nil) and (tex.ReferenceCount = 0) then
            tex.Name := model.GetPath() + texMap;

         {TODO: Sst texture name to the material}
      end;

      TexMap := '';
   end;
end;

{process a chunk that contains material relevant data}
procedure m3dsProcessMaterialChunk(var data: oxTFileRWData; var PreviousChunk: oxT3DSChunk);
var
   CurChunk: oxT3DSChunk;
   mat: oxTMaterial = nil;
   {transparency: single = 1.0;}

begin
 	while (PreviousChunk.BytesRead < PreviousChunk.Size) do begin
      if(not m3dsReadChunk(data, CurChunk)) then
         exit;

      mat := oxPModelFileOptions(data.Options)^.Model.GetLastMaterial();

      case CurChunk.ID of
         c3dsMATERIAL_NAME: begin
			   {read the material name | quite a simple chunk}
            if(mat <> nil) then begin
               m3dsReadString(data, mat.Name, CurChunk);

               if(oxfModel.LogExtended) then
                  log.v('Added material: ' + mat.Name);
            end else
               m3dsReadStringNil(data, CurChunk);
         end;
         c3dsMATERIAL_DIFFUSE: begin
            if(mat <> nil) then begin
               { TODO: Set diffuse color
               m3dsReadColor(ld, mat.Diffuse, CurChunk);
               mat.Properties := mat.Properties or oxcMATERIAL_DIFFUSE;}
            end else
               m3dsReadColorNil(data, CurChunk);
         end;
         c3dsMATERIAL_AMBIENT: begin
            {TODO: Set material ambient
            if(mat <> nil) then
               m3dsReadColor(ld, mat.Ambient, CurChunk)
            else
               m3dsReadColorNil(ld, CurChunk);}
         end;
         c3dsMATERIAL_SPECULAR: begin
            {TODO: Set specular color
            if(mat <> nil) then
               m3dsReadColor(ld, mat.Specular, CurChunk)
            else
               m3dsReadColorNil(ld, CurChunk);}
         end;
         c3dsMATERIAL_SHININES: begin
            {TODO: Set shinines
            if(mat <> nil) then
               m3dsReadPercentage(ld, mat.Shinines, CurChunk)
            else
               m3dsReadPercentageNil(ld, CurChunk);}
         end;
         c3dsMATERIAL_TRANSPARENCY: begin
            {TODO: Set transparency
            if(mat <> nil) then begin
               m3dsReadPercentage(ld, transparency, CurChunk);
               mat.Alpha := transparency;
            end else
               m3dsReadPercentageNil(ld, CurChunk);}
         end;
         c3dsMATERIAL_TEXMAP: begin
			   {read in the material texture map information}
            m3dsProcessMaterialChunk(data, CurChunk);
         end;
		   c3dsMATERIAL_MAP_FILENAME: begin
	         {read in the material's filename}
            readTexMap(data, CurChunk);
         end;
         else begin
            if(oxfModel.LogExtended) then
               log.w('Unknown material chunk: ' + hexStr(CurChunk.ID, 4));

            SeekPast(data, CurChunk);
         end;
      end;

      if(data.Ok()) then
         inc(PreviousChunk.BytesRead, CurChunk.BytesRead)
      else
         break;
   end;
end;

{process chunks that contain object relevant data}
procedure m3dsProcessObjectChunk(var data: oxTFileRWData; var previousChunk: oxT3DSChunk);
var
   curChunk: oxT3DSChunk;

begin
 	while (PreviousChunk.BytesRead < PreviousChunk.Size) do begin
      if(not m3dsReadChunk(data, curChunk)) then
         exit;

      case CurChunk.ID of
         c3dsOBJECT_MESH: { a object mesh is found}
			   {read in the object mesh information}
			   m3dsProcessObjectChunk(data, curChunk); {process object chunk}
         {read vertices}
         c3dsOBJECT_VERTICES:
            m3dsReadVertices(data, curChunk);
         {read vertex indices}
         c3dsOBJECT_FACES:
            m3dsReadVertexIndices(data, curChunk);
         {read the object material}
         c3dsOBJECT_MATERIAL:
            m3dsReadObjectMaterial(data, curChunk);
         {read in the texture(uv) coordinates}
         c3dsMESH_TEXTURE_COORDS:
            m3dsReadMeshTextureCoordinates(data, curChunk);
         else
            SeekPast(data, CurChunk);
      end;

      if(data.Ok()) then
         inc(previousChunk.BytesRead, curChunk.BytesRead)
      else
         break;
  end;
end;

{process a keyframe chunk}
procedure m3dsProcessKeyframeChunk(var data: oxTFileRWData; var previousChunk: oxT3DSChunk);
var
   curChunk: oxT3DSChunk;

begin
 	while (PreviousChunk.BytesRead < PreviousChunk.Size) do begin
      if(not m3dsReadChunk(data, CurChunk)) then
         exit;

      case curChunk.ID of
         c3dsKEYF_MESH_INFO:     SeekPast(data, CurChunk);
         c3dsKEYF_OBJECT_NAME:   SeekPast(data, CurChunk);
         c3dsKEYF_START_AND_END: SeekPast(data, CurChunk);
         c3dsPIVOT:              SeekPast(data, CurChunk);
         c3dsPOSITION_TRACK_TAG: SeekPast(data, CurChunk);
         c3dsROTATION_TRACK_TAG: SeekPast(data, CurChunk);
         c3dsSCALE_TRACK_TAG:    SeekPast(data, CurChunk);
         else
            SeekPast(data, CurChunk);
      end;

      if(data.Ok()) then
         inc(PreviousChunk.BytesRead, CurChunk.BytesRead)
      else
         break;
   end;
end;

{process a normal chunk}
procedure m3dsProcessChunk(var data: oxTFileRWData; var previousChunk: oxT3DSChunk);
var
   curChunk: oxT3DSChunk;

begin
 	while (previousChunk.BytesRead < previousChunk.Size) do begin
      if(not m3dsReadChunk(data, CurChunk)) then
         exit;

      case curChunk.ID of
         c3dsVERSION: begin
            {process the version}

            {read in the version}
            {if version information is larger or smaller than 4 bytes}
            if(curChunk.Size - curChunk.BytesRead <> 4) then begin
               PLoaderData(data.HandlerData)^.Version := 3;

               log.i('Warning: Version information is not equal 4 bytes. The file may not be standard 3DS file,'
					   + #13 + 'or the version is greater. There might be errors reading or performing.');

               SeekPast(data, CurChunk);
            {otherwise read in normally}
            end else begin
               if(xblockread(data, PLoaderData(data.HandlerData)^.Version, 4, CurChunk)) then begin
                  {in case the version is unsupported}
                  if(PLoaderData(data.HandlerData)^.Version <> 3) then
                     log.w('Unsupported version. There might be errors reading or performing.');
               end;
            end;
         end;
         c3dsOBJECTINFO: begin
            {process the object data}
			   m3dsProcessChunk(data, curchunk);
         end;
         c3dsMESHVERSION: begin
            {read the mesh version}
            {this block has been previously read in the OBJECTINFO section, but now it is separate to make
            it more clear what the routine is doing}
			   xblockread(data, PLoaderData(data.HandlerData)^.MeshVersion, 4, CurChunk);
         end;
         c3dsMATERIAL: begin
            {add a material}
            m3dsAddModelMaterial(data);

            {process the material data}
            m3dsProcessMaterialChunk(data, CurChunk);
         end;
         c3dsOBJECT: begin
            {add a object}
            m3dsAddModelObject(data, CurChunk);
            {process the object data}
            m3dsProcessObjectChunk(data, CurChunk); {process object chunk}
         end;
         c3dsKEYF: begin
            {the keyframer chunk is recognised but currently unsupported. It is only required for animations.}
            SeekPast(data, CurChunk);
         end;
         else
            SeekPast(data, CurChunk);
      end;

      if(data.Ok()) then
         inc(previousChunk.BytesRead, curChunk.BytesRead)
      else
         break;
   end;
end;

{IMPORT ROUTINE}
procedure m3dsLoad(data: pointer);
var
   pData: oxPFileRWData;
   primaryChunk: oxT3DSChunk;
   loaderData: TLoaderData;

begin
   pData := data;
   pData^.HandlerData := @loaderData;
   {INITIALIZE MODEL}

   {LOAD}
   {read primary chunk and check file type}
   m3dsReadChunk(pData^, primaryChunk);

   {if not a 3DS file}
   if(primaryChunk.ID <> c3dsPRIMARY) then begin
      pData^.SetError(eINVALID_ENV, 'Invalid 3ds header');
      exit;
   end;

   {process chunks}
   m3dsProcessChunk(pData^, PrimaryChunk);
   if(not pData^.Ok()) then
      exit;

   if(oxfModel.LogExtended) then begin
      log.i('3ds > Version: ' + sf(loaderData.Version) + ', mesh version: '+sf(loaderData.MeshVersion));
      log.v('3ds > Meshes: ' + sf(oxPModelFileOptions(pData^.Options)^.Model.Meshes.n));
   end;
end;

INITIALIZATION
   oxfModel.Readers.RegisterHandler(m3DSLoader, '3DS', @m3dsLoad);
   oxfModel.Readers.RegisterExt(m3DSExt, '.3ds', @m3DSLoader);

END.
