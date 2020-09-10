{
   oxuShader, oX shader management
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuShader;

INTERFACE

   USES
      uLog, uStd, uComponentProvider, typinfo, vmVector, uColors,
      {$IFDEF OX_DEBUG}
      StringUtils,
      {$ENDIF}
      {ox}
      oxuTypes, oxuRunRoutines, oxuResourcePool,
      oxuRenderer, oxuRenderers, oxuTexture;

CONST
   {shader uniform constant prefix, should correspond to the oxTShaderUniformType}
   oxSHADER_UNIFORM_PREFIX = 'oxunfSHADER_';

TYPE
   { shader properties }

   oxTShaderProperties = set of (
      {shader is compiled}
      oxpSHADER_COMPILED,
      {shader is internal part of a renderer, and should not be destroyed}
      oxpSHADER_INTERNAL
   );

   {shader uniform type}
   oxTShaderUniformType = (
      {unknown or unsupported type}
      oxunfSHADER_NONE,
      oxunfSHADER_BOOL,
      oxunfSHADER_UINT8,
      oxunfSHADER_UINT16,
      oxunfSHADER_UINT32,
      oxunfSHADER_UINT64,
      oxunfSHADER_INT8,
      oxunfSHADER_INT16,
      oxunfSHADER_INT32,
      oxunfSHADER_INT64,
      oxunfSHADER_HALF,
      oxunfSHADER_FLOAT,
      oxunfSHADER_DOUBLE,
      oxunfSHADER_RGB,
      oxunfSHADER_RGBA,
      oxunfSHADER_RGB_FLOAT,
      oxunfSHADER_RGBA_FLOAT,
      oxunfSHADER_TEXTURE,
      oxunfSHADER_VEC2F,
      oxunfSHADER_VEC3F,
      oxunfSHADER_VEC4F,
      oxunfSHADER_VEC2I,
      oxunfSHADER_VEC3I,
      oxunfSHADER_VEC4I
   );

   oxPShaderUniform = ^oxTShaderUniform;

   { oxTShaderUniform }

   oxTShaderUniform = record
      UniformType: oxTShaderUniformType;
      Name: string;
      {index for the same type}
      TypeIndex: loopint;

      class procedure Init(out uniform: oxTShaderUniform); static;
   end;

   oxTShaderUniforms = specialize TSimpleList<oxTShaderUniform>;

   { oxTShaderUniformsHelper }

   oxTShaderUniformsHelper = record helper for oxTShaderUniforms
      {find a uniform and return the index, returns -1 if nothing found}
      function Find(const name: string): loopint;
   end;

   { oxTShader }

   oxTShader = class(oxTResource)
      Name: string;

      Properties: oxTShaderProperties;
      Uniforms: oxTShaderUniforms;

      constructor Create(); override;
      destructor Destroy(); override;

      function Compile(): boolean; virtual;
      function SetupUniforms(): boolean; virtual;
      procedure Dispose();
      function GetIndex(const uniformName: string): loopint;

      procedure SetUniform(const uniformName: string; value: pointer);
      procedure SetUniform({%H-}index: loopint; {%H-}value: pointer); virtual;
      function GetDescriptor(): string; virtual;
      {get the size to store uniform value(or reference) of the uniform at specified index}
      function GetUniformSize(index: loopint): loopint;
      function GetUniformType(index: loopint): oxTShaderUniformType;
      function GetUniformName(index: loopint): string;

      procedure SetColor3ub(index: loopint; var c: TColor3ub);
      procedure SetColor4ub(index: loopint; var c: TColor4ub);
      procedure SetColor3f(index: loopint; var c: TColor3f);
      procedure SetColor4f(index: loopint; var c: TColor4f);
      procedure SetVector3f(index: loopint; var c: TVector3f);
      procedure SetVector4f(index: loopint; var c: TVector4f);
      procedure SetFloat(index: loopint; var c: single);
      procedure SetFloat(index: loopint; var c: double);
      procedure SetTexture(index: loopint; const t: oxTTexture);

      {called when the shader is applied}
      procedure OnApply(); virtual;

      {add a uniform to the list}
      function AddUniform(uniformType: oxTShaderUniformType; const setName: string): oxPShaderUniform;

      function CheckType(index: loopint; uniformType: oxTShaderUniformType; alternativeType: oxTShaderUniformType = oxunfSHADER_NONE): boolean;
      {$IFDEF OX_DEBUG}
      function DebugCheckType(index: loopint; uniformType: oxTShaderUniformType; alternativeType: oxTShaderUniformType = oxunfSHADER_NONE): boolean;
      {$ENDIF}
   end;

CONST
   oxunfSHADER_MAX = loopint(high(oxTShaderUniformType));

TYPE
   { oxTShaderGlobal }

   oxTShaderGlobal = record
      ShaderInstance: TSingleComponent;
      Sizes: array[0..oxunfSHADER_MAX] of loopint;
      GenericDefault,
      Default: oxTShader;

      function Instance(): oxTShader;
      function GetUniformName(p: oxTShaderUniformType): string;
      function GetUniformType(const s: string): oxTShaderUniformType;
      {get the size to store a uniform value (or reference)}
      function GetUniformSize(uniformType: oxTShaderUniformType): loopint;

      procedure SetDefault(shader: oxTShader; force: boolean = false);

      {set default value to the given position}
      procedure SetDefaultValue(uniformType: oxTShaderUniformType; where: pointer);

      procedure Destroy(var shader: oxTShader);
      procedure Free(var shader: oxTShader);
   end;


VAR
   oxShader: oxTShaderGlobal;

IMPLEMENTATION

{ oxTShaderUniform }

class procedure oxTShaderUniform.Init(out uniform: oxTShaderUniform);
begin
   ZeroPtr(@uniform, SizeOf(uniform));
end;

{ oxTShaderUniformsHelper }

function oxTShaderUniformsHelper.Find(const name: string): loopint;
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i].Name = name) then
         exit(i);
   end;

   Result := -1;
end;

{ oxTShaderGlobal }

function oxTShaderGlobal.Instance(): oxTShader;
begin
   if(ShaderInstance.return <> nil) then
      result := oxTShader(ShaderInstance.return())
   else
      result := oxTShader.Create();
end;

function oxTShaderGlobal.GetUniformName(p: oxTShaderUniformType): string;
begin
   result := copy(GetEnumName(TypeInfo(oxTShaderUniformType), integer(p)), length(oxSHADER_UNIFORM_PREFIX), 127);
end;

function oxTShaderGlobal.GetUniformType(const s: string): oxTShaderUniformType;
var
   c: string;
   value: longint;

begin
   c := oxSHADER_UNIFORM_PREFIX + s;
   value := GetEnumValue(TypeInfo(oxTShaderUniformType), c);

   if(value >= 0) then
      Result := oxTShaderUniformType(value)
   else
      Result := oxunfSHADER_NONE;
end;

function oxTShaderGlobal.GetUniformSize(uniformType: oxTShaderUniformType): loopint;
begin

   Result := Sizes[loopint(uniformType)];
end;

procedure oxTShaderGlobal.SetDefault(shader: oxTShader; force: boolean);
begin
   Self.Destroy(Default);

   if(force) or (Default = nil) or (Default.ClassName = 'oxTShader') then begin
      log.v('Set shader as default: ' + shader.Name + ' (' + shader.ClassName + ')');

      Default := shader;
   end;
end;

procedure oxTShaderGlobal.SetDefaultValue(uniformType: oxTShaderUniformType; where: pointer);
var
   size: loopint;

begin
   size := GetUniformSize(uniformType);

   if(uniformType = oxunfSHADER_RGB) then
      TColor3ub(where^) := cWhite3ub
   else if(uniformType = oxunfSHADER_RGBA) then
      TColor4ub(where^) := cWhite4ub
   else if(uniformType = oxunfSHADER_RGB_FLOAT) then
      TColor3f(where^) := cWhite3f
   else if(uniformType = oxunfSHADER_RGBA_FLOAT) then
      TColor4f(where^) := cWhite4f
   else if(size > 0) then
      ZeroPtr(where, size);
end;

procedure oxTShaderGlobal.Destroy(var shader: oxTShader);
begin
   if(Default = shader) then
      Default := nil;

   oxResource.Destroy(shader);
end;

procedure oxTShaderGlobal.Free(var shader: oxTShader);
begin
   if(Default = shader) then
      Default := nil;

   oxResource.Free(shader);
end;

{ oxTShader }

constructor oxTShader.Create();
begin
   inherited Create();

   Uniforms.InitializeValues(Uniforms);
end;

destructor oxTShader.Destroy();
begin
   inherited;

   Dispose();
end;

function oxTShader.Compile(): boolean;
begin
   Include(Properties, oxpSHADER_COMPILED);
   Result := true;
end;

function oxTShader.SetupUniforms(): boolean;
begin
   Result := true;
end;

procedure oxTShader.Dispose();
begin
   Uniforms.Dispose();
end;

function oxTShader.GetIndex(const uniformName: string): loopint;
var
   i: loopint;

begin
   for i := 0 to Uniforms.n - 1 do begin
      if(Uniforms.List[i].Name = uniformName) then
         exit(i);
   end;

   Result := -1;
end;

procedure oxTShader.SetUniform(const uniformName: string; value: pointer);
var
   index: loopint;

begin
   index := GetIndex(uniformName);

   if(index > -1) then
      SetUniform(index, value)
   else
      log.w('Tried to set uniform with non-existing index: ' + uniformName);
end;

procedure oxTShader.SetUniform(index: loopint; value: pointer);
begin
end;

function oxTShader.GetDescriptor(): string;
begin
   result := Path;
end;

function oxTShader.GetUniformSize(index: loopint): loopint;
begin
   Result := oxShader.GetUniformSize(Uniforms.List[index].UniformType);
end;

function oxTShader.GetUniformType(index: loopint): oxTShaderUniformType;
begin
   Result := Uniforms.List[index].UniformType;
end;

function oxTShader.GetUniformName(index: loopint): string;
begin
   Result := Uniforms.List[index].Name;
end;

procedure oxTShader.SetColor3ub(index: loopint; var c: TColor3ub);
var
   v3f: TColor3f;

begin
   if(Uniforms.List[index].UniformType = oxunfSHADER_VEC3F) or (Uniforms.List[index].UniformType = oxunfSHADER_RGB_FLOAT) then begin
      v3f := c.ToColor3f();

      SetUniform(index, @v3f);
   end else begin
      {$IFDEF OX_DEBUG}
      if(not DebugCheckType(index, oxunfSHADER_VEC3F, oxunfSHADER_RGB_FLOAT)) then
         exit;
      {$ENDIF}

      SetUniform(index, @c);
   end;
end;

procedure oxTShader.SetColor4ub(index: loopint; var c: TColor4ub);
var
   v4f: TColor4f;

begin
   if(Uniforms.List[index].UniformType = oxunfSHADER_VEC4F) or (Uniforms.List[index].UniformType = oxunfSHADER_RGBA_FLOAT) then begin
      v4f := c.ToColor4f();

      SetUniform(index, @v4f);
   end else begin
      {$IFDEF OX_DEBUG}
      if(not DebugCheckType(index, oxunfSHADER_VEC4F, oxunfSHADER_RGBA_FLOAT)) then
         exit;
      {$ENDIF}

      SetUniform(index, @c);
   end;
end;

procedure oxTShader.SetColor3f(index: loopint; var c: TColor3f);
begin
   {$IFDEF OX_DEBUG}
   if(not DebugCheckType(index, oxunfSHADER_RGB_FLOAT, oxunfSHADER_VEC3F)) then
      exit;
   {$ENDIF}

   SetUniform(index, @c);
end;

procedure oxTShader.SetColor4f(index: loopint; var c: TColor4f);
begin
   {$IFDEF OX_DEBUG}
   if(not DebugCheckType(index, oxunfSHADER_RGBA_FLOAT, oxunfSHADER_VEC4F)) then
      exit;
   {$ENDIF}

   SetUniform(index, @c);
end;

procedure oxTShader.SetVector3f(index: loopint; var c: TVector3f);
begin
   {$IFDEF OX_DEBUG}
   if(not DebugCheckType(index, oxunfSHADER_VEC3F, oxunfSHADER_RGB_FLOAT)) then
      exit;
   {$ENDIF}

   SetUniform(index, @c);
end;

procedure oxTShader.SetVector4f(index: loopint; var c: TVector4f);
begin
   {$IFDEF OX_DEBUG}
   if(not DebugCheckType(index, oxunfSHADER_VEC4F, oxunfSHADER_RGBA_FLOAT)) then
      exit;
   {$ENDIF}

   SetUniform(index, @c);
end;

procedure oxTShader.SetFloat(index: loopint; var c: single);
begin
   {$IFDEF OX_DEBUG}
   if(not DebugCheckType(index, oxunfSHADER_FLOAT)) then
      exit;
   {$ENDIF}

   SetUniform(index, @c);
end;

procedure oxTShader.SetFloat(index: loopint; var c: double);
begin
   {$IFDEF OX_DEBUG}
   if(not DebugCheckType(index, oxunfSHADER_DOUBLE)) then
      exit;
   {$ENDIF}

   SetUniform(index, @c);
end;

procedure oxTShader.SetTexture(index: loopint; const t: oxTTexture);
begin
   {$IFDEF OX_DEBUG}
   if(not DebugCheckType(index, oxunfSHADER_TEXTURE)) then
      exit;
   {$ENDIF}

   SetUniform(index, @t);
end;

procedure oxTShader.OnApply();
begin
end;

function oxTShader.AddUniform(uniformType: oxTShaderUniformType; const setName: string): oxPShaderUniform;
var
   uniform: oxTShaderUniform;

begin
   oxTShaderUniform.Init(uniform);

   uniform.UniformType := uniformType;
   uniform.Name := setName;

   Uniforms.Add(uniform);

   Result := Uniforms.GetLast();
end;

function oxTShader.CheckType(index: loopint; uniformType: oxTShaderUniformType; alternativeType: oxTShaderUniformType): boolean;
begin
   Result := false;

   if(index > -1) and (index < Uniforms.n) then begin
      if(Uniforms.List[index].UniformType = uniformType) then
         exit(true);

      if(alternativeType <> oxunfSHADER_NONE) then
         if(Uniforms.List[index].UniformType = alternativeType) then
            exit(true);
   end;
end;

{$IFDEF OX_DEBUG}
function oxTShader.DebugCheckType(index: loopint; uniformType: oxTShaderUniformType; alternativeType: oxTShaderUniformType = oxunfSHADER_NONE): boolean;
begin
   Result := CheckType(index, uniformType, alternativeType);

   if(not Result) then begin
      if(index > -1) and (index < Uniforms.n) then
         if(alternativeType = oxunfSHADER_NONE) then begin
            log.w('Shader(' + Name +  ') type (' + sf(loopint(uniformType)) + ') not equal for ' +
               sf(index) + '/' + Uniforms.List[index].Name +
               ' (expected: ' + sf(loopint(Uniforms.List[index].UniformType)) + ')')
         end else begin
            log.w('Shader(' + Name +  ') type (' + sf(loopint(uniformType)) + ' or ' + sf(loopint(alternativeType)) + ') not equal for ' +
               sf(index) + '/' + Uniforms.List[index].Name +
               ' (expected: ' + sf(loopint(Uniforms.List[index].UniformType)) + ')')
         end
      else
         log.w('Shader(' + Name +  ') index ' + sf(index) + ' out of bounds (count: ' + sf(Uniforms.n) + ')')
   end;
end;
{$ENDIF}

procedure onUse();
var
   pShaderInstance: PSingleComponent;

begin
   oxResource.Free(oxShader.GenericDefault);

   pShaderInstance := oxRenderer.FindComponent('shader');

   if(pShaderInstance <> nil) then
      oxShader.ShaderInstance := pShaderInstance^;

   oxShader.GenericDefault := oxShader.Instance();
   oxShader.GenericDefault.MarkPermanent();

   oxShader.SetDefault(oxShader.GenericDefault);
end;

procedure deinit();
begin
   if(oxShader.Default <> nil) and (oxShader.Default.ClassName <> 'oxTShader') then
      oxResource.Free(oxShader.Default);

   oxResource.Free(oxShader.GenericDefault);
end;

procedure InitializeUniformSizes();
{$IFDEF OX_DEBUG}
var
   i: loopint;
{$ENDIF}

begin
   ZeroPtr(@oxShader.Sizes[0], SizeOf(oxShader.Sizes));

   oxShader.Sizes[Integer(oxunfSHADER_NONE)] := 0;
   oxShader.Sizes[Integer(oxunfSHADER_BOOL)] := SizeOf(Boolean);

   oxShader.Sizes[Integer(oxunfSHADER_UINT8)] := SizeOf(UInt8);
   oxShader.Sizes[Integer(oxunfSHADER_UINT16)] := SizeOf(UInt16);
   oxShader.Sizes[Integer(oxunfSHADER_UINT32)] := SizeOf(UInt32);
   oxShader.Sizes[Integer(oxunfSHADER_UINT64)] := SizeOf(UInt64);

   oxShader.Sizes[Integer(oxunfSHADER_INT8)] := SizeOf(Int8);
   oxShader.Sizes[Integer(oxunfSHADER_INT16)] := SizeOf(Int16);
   oxShader.Sizes[Integer(oxunfSHADER_INT32)] := SizeOf(Int32);
   oxShader.Sizes[Integer(oxunfSHADER_INT64)] := SizeOf(Int64);

   oxShader.Sizes[Integer(oxunfSHADER_HALF)] := SizeOf(Single);
   oxShader.Sizes[Integer(oxunfSHADER_FLOAT)] := SizeOf(Single);
   oxShader.Sizes[Integer(oxunfSHADER_DOUBLE)] := SizeOf(Double);

   oxShader.Sizes[Integer(oxunfSHADER_RGB)] := SizeOf(TColor3ub);
   oxShader.Sizes[Integer(oxunfSHADER_RGBA)] := SizeOf(TColor4ub);
   oxShader.Sizes[Integer(oxunfSHADER_RGB_FLOAT)] := SizeOf(TColor3f);
   oxShader.Sizes[Integer(oxunfSHADER_RGBA_FLOAT)] := SizeOf(TColor4f);

   oxShader.Sizes[Integer(oxunfSHADER_VEC2F)] := SizeOf(TVector2f);
   oxShader.Sizes[Integer(oxunfSHADER_VEC3F)] := SizeOf(TVector3f);
   oxShader.Sizes[Integer(oxunfSHADER_VEC4F)] := SizeOf(TVector4f);
   oxShader.Sizes[Integer(oxunfSHADER_VEC2I)] := SizeOf(TVector2i);
   oxShader.Sizes[Integer(oxunfSHADER_VEC3I)] := SizeOf(TVector3i);
   oxShader.Sizes[Integer(oxunfSHADER_VEC4I)] := SizeOf(TVector4i);

   oxShader.Sizes[Integer(oxunfSHADER_TEXTURE)] := SizeOf(oxTTexture);

   {$IFDEF OX_DEBUG}
   for i := 1 to high(oxShader.Sizes) do begin
      assert(oxShader.Sizes[i] > 0, 'Shader uniform size for type ' + sf(i) + ' is invalid');
   end;
   {$ENDIF}
end;

INITIALIZATION
   oxRenderers.UseRoutines.Add(@onUse);
   oxRenderers.Init.dAdd('shader', @deinit);

   InitializeUniformSizes();

END.
