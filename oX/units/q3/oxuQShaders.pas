{
   oxuQShaders, quake shader processing
   Copyright (C) 2009. Dejan Boras

   Note: Extensive logging can be enabled by defining the OX_QSHADERS_EXTRA_LOGGING symbol.
}

{$INCLUDE oxdefines.inc}
UNIT oxuQShaders;

INTERFACE

   USES SysUtils, uStd, uLog, uColors,
   {q3Parser}
   q3uParser, q3uShaders,
   {oX}
   oxuConstants, oxuInit, oxuMaterials, oxuTexture, oxuTexturePool, oxuglInfo;

CONST
   OXQ_SHADER_MAP_EDITOR            = $0001; {a map editor specific shader}
   OXQ_SHADER_VALID                 = $0002; {fully valid shader}

   {$INCLUDE q3shaderdefinitions.inc}

TYPE
   {a shader}
   oxqPShader = ^oxqTShader;
   oxqTShader = record
      {shader properties}
      Properties: longword;

      {material that the shader consists of}
      mat: oxTMaterial;

      {next shader in list}
      Next: oxqPShader;
   end;

   oxqTShaderPool = record
      n: longint;
      
      s, 
      e: oxqPShader;
   end;

VAR
   oxqShaderPool: oxqTShaderPool = (
      n: 0; 
      s: nil; 
      e: nil
   );

{ SHADERS }
{initialize a oxqTShader record}
procedure oxqInitShaderRecord(out s: oxqTShader);
{create a new shader on the heap}
function oxqMakeShader(): oxqPShader;

{ SHADER FILES }
{load a shader file and store all shaders into the pool}
function oxqLoadShaderFile(const fn: string): boolean;

{ SHADER POOL }
{adds the shader to pool}
procedure oxqAddShaderToPool(shader: oxqPShader);
procedure oxqAddShaderToPool(var shader: oxqTShader); inline;
{load all shaders from pool path}
procedure oxqLoadShaderPool(const path: string);

{ DISPOSING }
{dispose of a shader}
procedure oxqDisposeShader(var s: oxqTShader);
procedure oxqDisposeShader(var s: oxqPShader);
{dispose of the entire shader pool}
procedure oxqDisposeShaderPool();

{ FINDING }
{finds a shader with the specified name and return a pointer and it's index}
function oxqFindShader(const name: string): oxqPShader;

{ DEBUG }
{lists all shaders}
procedure oxqListShaders(toLog: boolean);

IMPLEMENTATION

{ SHADERS }

procedure oxqInitShaderRecord(out s: oxqTShader);
begin
   ZeroOut(s, SizeOf(s));
end;

function oxqMakeShader(): oxqPShader;
var
   s: oxqPShader = nil;

begin
   new(s);
   if(s <> nil) then
      Zero(s^, SizeOf(oxqTShader));

   oxqMakeShader := s;
end;

{ CALLBACKS }
VAR
   qshader: oxqPShader        = nil;
   shaderStage: longint       = -1;
   qsSubMat: oxPSubMaterial;
   qsMat: oxPMaterial;

{TODO: It might be a good idea that q3Parser reports how many stages there are,
and immediately allocate the appropriate sub-materials.}

function newShader(var s: string): boolean;
begin
   result := false;

   {if previous shader was not used then dispose of it}
   if(qshader <> nil) then
      oxqDisposeShader(qshader);

   {allocate memory for new shader}
   qshader := oxqMakeShader();
   if(qshader = nil) then
      exit(false);

   qsMat          := @qshader^.mat;
   qsMat^.sName   := s;

   {we need to start a shader from scratch}
   shaderStage    := -1;

   result := true;
end;

procedure newStage();
begin
   inc(shaderStage);
   if(shaderStage >= 0) and (qsMat <> nil) then begin
      qsSubMat := oxAddSubMaterial(qsMat^);
   end;
end;

CONST
   GEN_RGB        = 0000;
   GEN_ALPHA      = 0001;

procedure newField(var f: q3TShaderField; var def: q3TShaderDefinition);
var
   pvalue: string = '';

{setup rgb or alpha generation}
procedure rgbaGen(what: longint);
begin
   {TODO: Need to implement this properly.}
   if(def.sSub <> @q3scsWAVE) then begin
      if(pvalue = 'identity') or (pvalue = 'identityLighting') then begin
         if(what = GEN_RGB) then 
            qsSubMat^.Diffuse := cWhite3ub
         else if(what = GEN_ALPHA) then 
            qsSubMat^.Alpha := 255;
      end;
   end;
end;

{setup alpha function}
procedure alphaFunc();
begin
   pvalue := LowerCase(pvalue);
   {set the material for alpha testing}
   qsSubMat^.Properties := qsSubMat^.Properties or oxcMATERIAL_ALPHA_TEST;

   {setup alpha test functions}
   if(pvalue = 'ge128') then begin
      qsSubMat^.alphaTestFunc := oxDEPTH_TEST_GEQUAL;
      qsSubMat^.alphaRef := (1 / 255) * 128;
   end else if(pvalue = 'lt128') then begin
      qsSubMat^.alphaTestFunc := oxDEPTH_TEST_LESS;
      qsSubMat^.alphaRef := (1 / 255) * 128;
   end else if(pvalue = 'gt0') then begin
      qsSubMat^.alphaTestFunc := oxDEPTH_TEST_GREATER;
      qsSubMat^.alphaRef := 0;
   {in case the function is unknown disable alpha testing}
   end else
      qsSubMat^.Properties := qsSubMat^.Properties xor oxcMATERIAL_ALPHA_TEST;
end;

{setup blending}
procedure blendFunc();
begin
   qsSubMat^.Properties := qsSubMat^.Properties or oxcMATERIAL_BLEND;

   {if we have a classic blend function (src, dst)}
   if(Def.sSub = nil) then begin
      if(Def.DataTypes[0] = dtcSHORTSTRING) and (def.DataTypes[1] = dtcSHORTSTRING) then begin
         // TODO: Determine blend function to use
      end else
         qsSubMat^.Properties := qsSubMat^.Properties xor oxcMATERIAL_BLEND;
   {otherwise the blend function must be specified by name}
   end else begin
      if(Def.sSub = @q3scsADD) then begin
         qsSubMat^.blendFunc := oxBLEND_ADD;
      end else if(Def.sSub = @q3scsBLEND) then begin
         qsSubMat^.blendFunc := oxBLEND_ALPHA;
      end else if(Def.sSub = @q3scsFILTER) then begin
         qsSubMat^.blendFunc := oxBLEND_FILTER;
      {in case we cannot figure out what the blend function is, disable blending}
      end else
         qsSubMat^.Properties := qsSubMat^.Properties xor oxcMATERIAL_BLEND;
   end;
end;

{assign a texture to this sub-material}
procedure map();
var
   p: oxTTexture;
   idx: longint = -1;
   sameTex: boolean = false;

begin
   {do not add textures with special meaning}
   if(pos('$', pvalue) = 0) then begin
      if(pvalue = 'null') then
         qsMat^.Properties := qsMat^.Properties or oxcMATERIAL_NO_RENDER
      else begin
         p := oxGetNewUniqueTexture(pvalue, idx, sameTex);
         if(p <> nil) then begin
            oxSetTextureFN(p, pvalue);

            if(idx > -1) then
               qsSubMat^.Tex := idx;
         end;
      end;
   end;
end;

procedure depthFunc();
begin
   pvalue                  := LowerCase(pvalue);
   {set the material for alpha testing}
   qsSubMat^.Properties    := qsSubMat^.Properties or oxcMATERIAL_DEPTH_FUNC;

   {setup alpha test functions}
   if(pvalue = 'equal') then
      qsSubMat^.DepthFunc := oxDEPTH_TEST_EQUAL
   else if(pvalue = 'lequal') then
      qsSubMat^.DepthFunc := oxDEPTH_TEST_LEQUAL
   else if(pvalue = 'gequal') then
      qsSubMat^.DepthFunc := oxDEPTH_TEST_GEQUAL
   else if(pvalue = 'greater') then
      qsSubMat^.DepthFunc := oxDEPTH_TEST_GREATER
   else if(pvalue = 'less') then
      qsSubMat^.DepthFunc := oxDEPTH_TEST_LESS
   else
      qsSubMat^.Properties := qsSubMat^.Properties xor oxcMATERIAL_DEPTH_FUNC;
end;

begin
   if(shaderStage > -1) and (qsSubMat <> nil) and (@def <> nil) then begin
      pvalue := f.Data[0].s;

      if(def.uID = q3scRGBGEN) then
         rgbaGen(GEN_RGB)
      else if(def.uID = q3scALPHAGEN) then
         rgbaGen(GEN_ALPHA)
      else if(def.uID = q3scALPHAFUNC) then
         alphaFunc()
      else if(def.uID = q3scBLENDFUNC) then
         blendFunc()
      else if(def.uID = q3scDEPTHFUNC) then
         depthFunc()
      else if(def.uID = q3scMAP) then 
         map();
   end;
end;

{procedure customField(var f: q3TShaderField; var def: q3TShaderDefinition; var line: q3pTLine);
begin
   if(shaderStage > -1) and (qsSubMat <> nil) then begin
   end;
end;}

procedure endShader();
begin
   {TODO: Make sure the shader is valid before adding it.
   Otherwise dispose of the shader.}

   {add the new shader to the pool}
   oxqAddShaderToPool(qshader);

   {prepare for next shader}
   qshader := nil;
end;

CONST
   callbacks: q3TShaderCallbacks = (
      newShader:     @newShader;
      newStage:      @newStage;
      newField:      @newField;
      customField:   nil{@customField};
      endShader:     @endShader;
   );


{ SHADER FILES }

procedure processShaders(var s: q3pTStructure);
begin
   q3ParseShaderData(s, callbacks);
end;

{load a shader file into the shader pool}
function oxqLoadShaderFile(const fn: string): boolean;
var
   s: q3pTStructure = (
      FileName: ''; 
      nLines: 0; 
      Lines: nil
   );

procedure cleanup();
begin
   {dispose of the shader file}
   q3pDisposeStructure(s);
end;

begin
   result := false;
   if(fn <> '') then begin

      {$IFDEF OX_QSHADERS_EXTRA_LOGGING}
      log.i('oxQ > Loading shader: '+fn);
      {$ENDIF}
      {load the shader file and parse it}
      q3pLoadFile(fn, s);
      if(q3pError <> 0) then begin
         cleanup();
         exit;
      end;

      {get the shaders}
      processShaders(s);

      cleanup();
      result := true;
   end;
end;

{ SHADER POOL }

procedure oxqAddShaderToPool(shader: oxqPShader);
begin
   if(oxqShaderPool.s = nil) then begin
      oxqShaderPool.s := shader; 
      oxqShaderPool.e := shader;
   end else begin
      oxqShaderPool.e^.Next := shader; 
      oxqShaderPool.e := shader;
   end;

   shader^.Next := nil;
end;

procedure oxqAddShaderToPool(var shader: oxqTShader); inline;
begin
   oxqAddShaderToPool(@shader)
end;

{load all shaders from pool path}
procedure oxqLoadShaderPool(const path: string);
var
   src: TSearchRec;
   result: longint;
   xpath: string;

begin
   if(path = '') then exit;

   {make sure we have a separator at the end}
   xpath := path;
   if(xpath[Length(xpath)] <> DirectorySeparator) then
      xpath := xpath + DirectorySeparator;

   {select the required shader definitions}
   q3SelectShaderDefinitions(q3ShaderDefinitions);

   {find first}
   result := FindFirst(xpath+'*.shader', 0, src);
   if(result = 0) then begin
      repeat
         {be careful what not to process}
         if(src.Attr and faSysFile = 0) and (src.Attr and faVolumeId = 0) and
         (src.Attr and faReadOnly = 0) and (src.Attr and faDirectory = 0) then begin
            if(not oxqLoadShaderFile(xpath+src.Name)) then
               exit;
         end;
         result := FindNext(src);
      until (result <> 0)
   end;

   {cleanup}
   FindClose(src);
end;

{ DISPOSING }
procedure oxqDisposeShader(var s: oxqTShader);
begin
   oxDisposeMaterial(s.mat);
   s.Properties := 0;
end;

procedure oxqDisposeShader(var s: oxqPShader);
begin
   if(s <> nil) then begin
      oxqDisposeShader(s^); 
      dispose(s); 
      s := nil;
   end;
end;

procedure oxqDisposeShaderPool();
var
   p, cur: oxqPShader;

begin
   cur := oxqShaderPool.s;

   if(cur <> nil) then repeat
      {store the current shader and go to the next}
      P := cur; cur := cur^.next;
      {dispose of the current shader}
      oxqDisposeShader(p);
   until (cur = nil);

   oxqShaderPool.s := nil; 
   oxqShaderPool.e := nil;
end;

{ FINDING }

function oxqFindShader(const name: string): oxqPShader;
var
   cur: oxqPShader;

begin
   oxqFindShader := nil;
   cur := oxqShaderPool.s;
   if(cur <> nil) then repeat
      if(cur^.mat.sName = name) then 
         exit(cur);
      cur := cur^.Next;
   until cur = nil;
end;

{ DEBUG }
procedure oxqListShaders(toLog: boolean);
var
   cur: oxqPShader;

begin
   cur := oxqShaderPool.s;
   if(cur <> nil) then repeat
      if(cur^.mat.sName <> '') then begin
         if(toLog) then
            log.i('shader: ' + cur^.mat.sName)
         else
            writeln('shader: ', cur^.mat.sName);

      end;
      cur := cur^.Next;
   until cur = nil;
end;

INITIALIZATION
   oxiProcs.dAdd('qshaders', @oxqDisposeShaderPool);
END.
