{
   oxuMaterial, material
   Copyright (C) 2009. Dejan Boras

   Started On:    14.11.2009.
}

{$INCLUDE oxdefines.inc}
UNIT oxuMaterial;

INTERFACE

   USES
      uStd, StringUtils, uLog, uColors, uComponentProvider, uThreads, vmVector,
      {ox}
      oxuRunRoutines, oxuTypes, oxuResourcePool,
      oxuTexture, oxuRenderer, oxuRenderers, oxuShader;

CONST
   {material properties}
      {appearance/rendering}
   oxMATERIAL_DYNAMIC              = $00000400; {material appearance changes, not for use in lists}
   oxMATERIAL_EXTENDED             = $00000800; {use extended material information such as ambient, specular, emissive, shinines...}
   oxMATERIAL_DIFFUSE              = $00001000; {apply the material diffuse color}
   oxMATERIAL_SHADER               = $00002000; {the material uses a shader}
   oxMULTI_STAGE                   = $00004000; {the material is a multi stage material}
   oxMATERIAL_ALPHA_TEST           = $00008000; {alpha test the material}
   oxMATERIAL_NO_CULL              = $00010000; {do not perform culling}
   oxMATERIAL_BLEND                = $00020000; {perform blending}
   oxMATERIAL_RGB_GEN              = $00040000; {generate alpha}
   oxMATERIAL_ALPHA_GEN            = $00080000; {generate alpha}
   oxMATERIAL_NO_RENDER            = $00100000; {do not render object with this material}
   oxMATERIAL_DEPTH_FUNC           = $00200000; {set depth testing}


TYPE
   { oxTMaterial }

   oxTMaterial = class(oxTResource)
      Name: string;
      Properties: longword;

      AlphaTestFunc: oxTTestFunction;
      DepthFunc: oxTTestFunction;
      BlendFunc: oxTBlendFunction;

      Shader: oxTShader;

      {pointers to entries, the list is starting part of the Values pool}
      PEntries: PPointer;
      {data pool where all values are held}
      ValuePool,
      Values: Pointer;
      ValueIndexes: PPtrInt;

      constructor Create; override;
      destructor Destroy; override;

      {assign shader to this material}
      procedure AssignShader(newShader: oxTShader);
      {dispose current values}
      procedure DisposeValues();

      {get value position}
      function GetValuePosition(index: loopint): pointer;

      procedure SetValue(index: loopint; value: pointer);
      {set value}
      procedure SetColor(index: loopint; c: TColor3ub);
      {set value}
      procedure SetColor(index: loopint; c: TColor4ub);
      {set value}
      procedure SetColor(index: loopint; c: TColor3f);
      {set value}
      procedure SetColor(index: loopint; c: TColor4f);
      {set value}
      procedure SetFloat(index: loopint; c: single);
      {set value}
      procedure SetFloat(index: loopint; c: double);
      {set value}
      procedure SetTexture(index: loopint; t: oxTTexture);

      {set value}
      procedure SetValue(const valueName: string; value: pointer);
      {set value}
      procedure SetColor(const colorName: string; c: TColor3ub);
      {set value}
      procedure SetColor(const colorName: string; c: TColor4ub);
      {set value}
      procedure SetColor(const colorName: string; c: TColor3f);
      {set value}
      procedure SetColor(const colorName: string; c: TColor4f);
      {set value}
      procedure SetFloat(const what: string; c: single);
      {set value}
      procedure SetFloat(const what: string; c: double);
      {set value}
      procedure SetTexture(const what: string; t: oxTTexture);

      {immediately apply value}
      procedure ApplyColor(index: loopint; c: TColor3ub);
      {immediately apply value}
      procedure ApplyColor(index: loopint; c: TColor4ub);
      {immediately apply value}
      procedure ApplyColor(index: loopint; c: TColor3f);
      {immediately apply value}
      procedure ApplyColor(index: loopint; c: TColor4f);
      {immediately apply value}
      procedure ApplyColor(index: loopint; r, g, b, a: byte);
      {immediately apply value}
      procedure ApplyColor(index: loopint; r, g, b, a: single);
      {immediately apply value}
      procedure ApplyFloat(index: loopint; c: single);
      {immediately apply value}
      procedure ApplyFloat(index: loopint; c: double);
      {immediately apply value}
      procedure ApplyTexture(index: loopint; t: oxTTexture);

      {immediately apply value}
      procedure ApplyColor(const colorName: string; c: TColor3ub);
      {immediately apply value}
      procedure ApplyColor(const colorName: string; c: TColor4ub);
      {immediately apply value}
      procedure ApplyColor(const colorName: string; c: TColor3f);
      {immediately apply value}
      procedure ApplyColor(const colorName: string; c: TColor4f);
      {immediately apply value}
      procedure ApplyColor(const colorName: string; r, g, b, a: byte);
      {immediately apply value}
      procedure ApplyColor(const colorName: string; r, g, b, a: single);
      {immediately apply value}
      procedure ApplyFloat(const what: string; c: single);
      {immediately apply value}
      procedure ApplyFloat(const what: string; c: double);
      {immediately apply value}
      procedure ApplyTexture(const what: string; t: oxTTexture);

      {applies the material for rendering}
      procedure Apply(); virtual;
      {called when material is applied}
      procedure OnApply(); virtual;

      {get the index of a shader uniform by its name}
      function GetShaderIndex(const what: string): loopint;
      {get material value as a string}
      function GetValueAsString(index: loopint): string;
      function GetValueAsString(const what: string): string;
      {log material values}
      procedure LogMaterialValues();

      {setup the material from the associated shader}
      procedure FromShader();

      {calculate the value pool size}
      function FormPool(): loopint;

      function CheckType(index: loopint; uniformType: oxTShaderUniformType; alternativeType: oxTShaderUniformType = oxunfSHADER_NONE): boolean;
      {$IFDEF OX_DEBUG}
      function DebugCheckType(index: loopint; uniformType: oxTShaderUniformType; alternativeType: oxTShaderUniformType = oxunfSHADER_NONE): boolean;
      procedure DebugFailedType(index: loopint; const what: string);
      {$ENDIF}

      function GetLoader(): POObject;
   end;

   oxTMaterials = specialize TSimpleList<oxTMaterial>;

   { oxTMaterialHelper }

   oxTMaterialHelper = record helper for oxTMaterials
      function FindByName(const name: string): oxTMaterial;
   end;

   { oxTMaterialGlobal }

   oxTMaterialGlobal = record
      MaterialInstance: TSingleComponent;
      {default material}
      Default: oxTMaterial;
      {default resource loader}
      ResourceLoader: POObject;

      function Instance(shader: oxTShader = nil): oxTMaterial;
      {create a material with the given shader (or default if nil)}
      function Make(shader: oxTShader = nil): oxTMaterial;
   end;

VAR
   oxMaterial: oxTMaterialGlobal;

THREADVAR
   oxCurrentMaterial: oxTMaterial;

IMPLEMENTATION

{ oxTMaterialHelper }

function oxTMaterialHelper.FindByName(const name: string): oxTMaterial;
var
   i: loopint;

begin
   for i := 0 to n - 1 do begin
      if(List[i].Name = name) then
         exit(List[i]);
   end;

   Result := nil;
end;

{ oxTMaterialGlobal }

function oxTMaterialGlobal.Instance(shader: oxTShader = nil): oxTMaterial;
begin
   if(MaterialInstance.return <> nil) then
      Result := oxTMaterial(MaterialInstance.Return())
   else
      Result := oxTMaterial.Create();

   if(shader = nil) then
      shader := oxShader.Default;

   Result.AssignShader(shader);
end;

function oxTMaterialGlobal.Make(shader: oxTShader): oxTMaterial;
begin
   Result := Instance(shader);
   Result.FromShader();
end;

{ oxTMaterial }

constructor oxTMaterial.Create;
begin
   inherited;

   AlphaTestFunc := oxTEST_FUNCTION_GEQUAL;
   DepthFunc := oxTEST_FUNCTION_GEQUAL;
   BlendFunc := oxBLEND_DEFAULT;
end;

destructor oxTMaterial.Destroy;
begin
   inherited Destroy;

   DisposeValues();
end;

procedure oxTMaterial.AssignShader(newShader: oxTShader);
begin
   DisposeValues();
   Shader := newShader;
end;

procedure oxTMaterial.DisposeValues();
begin
   XFreeMem(ValuePool);
   Values := nil;
   ValueIndexes := nil;
end;

function oxTMaterial.GetValuePosition(index: loopint): pointer;
begin
   Result := ValuePool + ValueIndexes[index];
end;

{ SET INDEX/VALUE }

procedure oxTMaterial.SetValue(index: loopint; value: pointer);
var
   size: PtrInt;
   position: Pointer;
   uniformType: oxTShaderUniformType;

begin
   if(ValuePool <> nil) and (index > -1) then begin
      assert(Shader <> nil, 'Shader not set but trying to set value for material ' + Name);
      assert(Values <> nil, 'Values not set but trying to set value for material ' + Name);
      assert(ValueIndexes <> nil, 'Values not set but trying to set value for material ' + Name);

      size := Shader.GetUniformSize(index);
      position := ValuePool + ValueIndexes[index];
      uniformType := Shader.GetUniformType(index);

      if(uniformType <> oxunfSHADER_TEXTURE) then begin
         {raw data, just move it}
         Move(value^, position^, size);
      end else begin
         {remove previous reference}
         if(oxTTexture(position^) <> nil) then
            oxResource.Destroy(position^);

         {set new reference}
         if(oxTTexture(value^) <> nil) then
            oxTTexture(value^).MarkUsed();

         oxTTexture(position^) := oxTTexture(value^);
      end;
   end;
end;

procedure oxTMaterial.SetColor(index: loopint; c: TColor3ub);
var
   c3f: TColor3f;
   c4ub: TColor4ub;
   c4f: TColor4f;

begin
   if(Shader.GetUniformType(index) = oxunfSHADER_RGB) then begin
      SetValue(index, @c);
   end else if(Shader.GetUniformType(index) = oxunfSHADER_RGBA) then begin
      c4ub := c.ToColor4ub();
      SetValue(index, @c4ub);
   end else if(Shader.GetUniformType(index) = oxunfSHADER_RGB_FLOAT) then begin
      c3f := c.ToColor3f();
      SetValue(index, @c3f);
   end else if(Shader.GetUniformType(index) = oxunfSHADER_RGBA_FLOAT) then begin
      c4f := c.ToColor4f();
      SetValue(index, @c4f);
   {$IFDEF OX_DEBUG}
   end else begin
      DebugFailedType(index, 'unsupported type (rgb, rgba, rgbf, rgbaf)');
   {$ENDIF}
   end;
end;

procedure oxTMaterial.SetColor(index: loopint; c: TColor4ub);
var
   c3f: TColor3f;
   c3ub: TColor3ub;
   c4f: TColor4f;

begin
   if(Shader.GetUniformType(index) = oxunfSHADER_RGB) then begin
      c3ub := c.ToColor3ub();
      SetValue(index, @c3ub);
   end else if(Shader.GetUniformType(index) = oxunfSHADER_RGBA) then begin
      SetValue(index, @c);
   end else if(Shader.GetUniformType(index) = oxunfSHADER_RGB_FLOAT) then begin
      c3f := c.ToColor3f();
      SetValue(index, @c3f);
   end else if(Shader.GetUniformType(index) = oxunfSHADER_RGBA_FLOAT) then begin
      c4f := c.ToColor4f();
      SetValue(index, @c4f);
   {$IFDEF OX_DEBUG}
   end else begin
      DebugFailedType(index, 'unsupported type (rgb, rgba, rgbf, rgbaf)');
   {$ENDIF}
   end;
end;

procedure oxTMaterial.SetColor(index: loopint; c: TColor3f);
var
   c3ub: TColor3ub;
   c4ub: TColor4ub;
   c4f: TColor4f;

begin
   if(Shader.GetUniformType(index) = oxunfSHADER_RGB) then begin
      c3ub := c.ToColor3ub();
      SetValue(index, @c3ub);
   end else if(Shader.GetUniformType(index) = oxunfSHADER_RGBA) then begin
      c4ub := c.ToColor4ub();
      SetValue(index, @c4ub);
   end else if(Shader.GetUniformType(index) = oxunfSHADER_RGB_FLOAT) then begin
      SetValue(index, @c);
   end else if(Shader.GetUniformType(index) = oxunfSHADER_RGBA_FLOAT) then begin
      c4f := c.ToColor4f();
      SetValue(index, @c4f);
   {$IFDEF OX_DEBUG}
   end else begin
      DebugFailedType(index, 'unsupported type (rgb, rgba, rgbf, rgbaf)');
   {$ENDIF}
   end;
end;

procedure oxTMaterial.SetColor(index: loopint; c: TColor4f);
var
   c3ub: TColor3ub;
   c4ub: TColor4ub;
   c3f: TColor4f;

begin
   if(Shader.GetUniformType(index) = oxunfSHADER_RGB) then begin
      c3ub := c.ToColor3ub();
      SetValue(index, @c3ub);
   end else if(Shader.GetUniformType(index) = oxunfSHADER_RGBA) then begin
      c4ub := c.ToColor4ub();
      SetValue(index, @c4ub);
   end else if(Shader.GetUniformType(index) = oxunfSHADER_RGB_FLOAT) then begin
      c3f := c.ToColor3f();
      SetValue(index, @c3f);
   end else if(Shader.GetUniformType(index) = oxunfSHADER_RGBA_FLOAT) then begin
      SetValue(index, @c);
   {$IFDEF OX_DEBUG}
   end else begin
      DebugFailedType(index, 'unsupported type (rgb, rgba, rgbf, rgbaf)');
   {$ENDIF}
   end;
end;

procedure oxTMaterial.SetFloat(index: loopint; c: single);
begin
   {$IFDEF OX_DEBUG}
   if(not DebugCheckType(index, oxunfSHADER_FLOAT)) then
      exit;
   {$ENDIF}

   SetValue(index, @c);
end;

procedure oxTMaterial.SetFloat(index: loopint; c: double);
begin
   {$IFDEF OX_DEBUG}
   if(not DebugCheckType(index, oxunfSHADER_DOUBLE)) then
      exit;
   {$ENDIF}

   SetValue(index, @c);
end;

procedure oxTMaterial.SetTexture(index: loopint; t: oxTTexture);
begin
   {$IFDEF OX_DEBUG}
   if(not DebugCheckType(index, oxunfSHADER_TEXTURE)) then
      exit;
   {$ENDIF}

   SetValue(index, @t);
end;

{ SET NAME/VALUE }

procedure oxTMaterial.SetValue(const valueName: string; value: pointer);
var
   index: loopint;

begin
   index := GetShaderIndex(valueName);
   SetValue(index, value);
end;

procedure oxTMaterial.SetColor(const colorName: string; c: TColor3ub);
var
   index: loopint;

begin
   index := GetShaderIndex(colorName);
   SetColor(index, c);
end;

procedure oxTMaterial.SetColor(const colorName: string; c: TColor4ub);
var
   index: loopint;

begin
   index := GetShaderIndex(colorName);
   SetColor(index, c);
end;

procedure oxTMaterial.SetColor(const colorName: string; c: TColor3f);
var
   index: loopint;

begin
   index := GetShaderIndex(colorName);
   SetColor(index, c);
end;

procedure oxTMaterial.SetColor(const colorName: string; c: TColor4f);
var
   index: loopint;

begin
   index := GetShaderIndex(colorName);
   SetColor(index, c);
end;

procedure oxTMaterial.SetFloat(const what: string; c: single);
var
   index: loopint;

begin
   index := GetShaderIndex(what);
   SetFloat(index, c);
end;

procedure oxTMaterial.SetFloat(const what: string; c: double);
var
   index: loopint;

begin
   index := GetShaderIndex(what);
   SetFloat(index, c);
end;

procedure oxTMaterial.SetTexture(const what: string; t: oxTTexture);
var
   index: loopint;

begin
   index := GetShaderIndex(what);
   SetTexture(index, t);
end;

{ APPLY INDEX/VALUE }

procedure oxTMaterial.ApplyColor(index: loopint; c: TColor3ub);
begin
   if(index > -1) then begin
      SetColor(index, c);
      Shader.SetColor3ub(index, c);
   end;
end;

procedure oxTMaterial.ApplyColor(index: loopint; c: TColor4ub);
begin
   if(index > -1) then begin
      SetColor(index, c);
      Shader.SetColor4ub(index, c);
   end;
end;

procedure oxTMaterial.ApplyColor(index: loopint; c: TColor3f);
begin
   if(index > -1) then begin
      SetColor(index, c);
      Shader.SetColor3f(index, c);
   end;
end;

procedure oxTMaterial.ApplyColor(index: loopint; c: TColor4f);
begin
   if(index > -1) then begin
      SetColor(index, c);
      Shader.SetColor4f(index, c);
   end;
end;

procedure oxTMaterial.ApplyColor(index: loopint; r, g, b, a: byte);
var
   c: TColor4ub;

begin
   if(index > -1) then begin
      c[0] := r;
      c[1] := g;
      c[2] := b;
      c[3] := a;
      SetColor(index, c);
      Shader.SetColor4ub(index, c);
   end;
end;

procedure oxTMaterial.ApplyColor(index: loopint; r, g, b, a: single);
var
   c: TColor4f;

begin
   if(index > -1) then begin
      c[0] := r;
      c[1] := g;
      c[2] := b;
      c[3] := a;
      SetColor(index, c);
      Shader.SetVector4f(index, c);
   end;
end;

procedure oxTMaterial.ApplyFloat(index: loopint; c: single);
begin
   if(index > -1) then begin
      SetFloat(index, c);
      Shader.SetFloat(index, c);
   end;
end;

procedure oxTMaterial.ApplyFloat(index: loopint; c: double);
begin
   if(index > -1) then begin
      SetFloat(index, c);
      Shader.SetFloat(index, c);
   end;
end;

procedure oxTMaterial.ApplyTexture(index: loopint; t: oxTTexture);
begin
   if(index > -1) then begin
      SetTexture(index, t);
      Shader.SetTexture(index, t);
   end;
end;

{ APPLY NAME/VALUE }

procedure oxTMaterial.ApplyColor(const colorName: string; c: TColor3ub);
var
   index: loopint;

begin
   index := GetShaderIndex(colorName);

   if(index > -1) then begin
      SetColor(index, c);
      Shader.SetColor3ub(index, c);
   end;
end;

procedure oxTMaterial.ApplyColor(const colorName: string; c: TColor4ub);
var
   index: loopint;

begin
   index := GetShaderIndex(colorName);

   if(index > -1) then begin
      SetColor(index, c);
      Shader.SetColor4ub(index, c);
   end;
end;

procedure oxTMaterial.ApplyColor(const colorName: string; c: TColor3f);
var
   index: loopint;

begin
   index := GetShaderIndex(colorName);

   if(index > -1) then begin
      SetColor(index, c);
      Shader.SetVector3f(index, c);
   end;
end;

procedure oxTMaterial.ApplyColor(const colorName: string; c: TColor4f);
var
   index: loopint;

begin
   index := GetShaderIndex(colorName);

   if(index > -1) then begin
      SetColor(index, c);
      Shader.SetColor4f(index, c);
   end;
end;

procedure oxTMaterial.ApplyColor(const colorName: string; r, g, b, a: byte);
var
   index: loopint;
   c: TColor4ub;

begin
   index := GetShaderIndex(colorName);

   if(index > -1) then begin
      c[0] := r;
      c[1] := g;
      c[2] := b;
      c[3] := a;
      SetColor(index, c);
      Shader.SetColor4ub(index, c);
   end;
end;

procedure oxTMaterial.ApplyColor(const colorName: string; r, g, b, a: single);
var
   index: loopint;
   c: TColor4f;

begin
   index := GetShaderIndex(colorName);

   if(index > -1) then begin
      c[0] := r;
      c[1] := g;
      c[2] := b;
      c[3] := a;
      SetColor(index, c);
      Shader.SetVector4f(index, c);
   end;
end;

procedure oxTMaterial.ApplyFloat(const what: string; c: single);
var
   index: loopint;

begin
   index := GetShaderIndex(what);

   if(index > -1) then begin
      SetFloat(index, c);
      Shader.SetFloat(index, c);
   end;
end;

procedure oxTMaterial.ApplyFloat(const what: string; c: double);
var
   index: loopint;

begin
   index := GetShaderIndex(what);

   if(index > -1) then begin
      SetFloat(index, c);
      Shader.SetFloat(index, c);
   end;
end;

procedure oxTMaterial.ApplyTexture(const what: string; t: oxTTexture);
var
   index: loopint;

begin
   index := GetShaderIndex(what);

   if(index > -1) then begin
      SetTexture(index, t);
      Shader.SetTexture(index, t);
   end;
end;

procedure oxTMaterial.Apply();
var
   i: loopint;

begin
   oxCurrentMaterial := Self;

   if(Shader <> nil) and (ValuePool <> nil) then begin
      Shader.OnApply();

      for i := 0 to Shader.Uniforms.n - 1 do begin
         Shader.SetUniform(i, GetValuePosition(i));
      end;
   end;

   OnApply();
end;

procedure oxTMaterial.OnApply();
begin

end;

function oxTMaterial.GetShaderIndex(const what: string): loopint;
begin
   if(Shader <> nil) then
      exit(Shader.GetIndex(what));

   Result := -1;
end;

function oxTMaterial.GetValueAsString(index: loopint): string;
var
   uniformType: oxTShaderUniformType;
   position: pointer;

begin
   if(index > -1) and (ValuePool <> nil) and (Shader <> nil) then begin
      uniformType := Shader.GetUniformType(index);
      position := GetValuePosition(index);

      if(uniformType = oxunfSHADER_BOOL) then
         Result := sf(Boolean(position^))
      else if(uniformType = oxunfSHADER_UINT8) then
         Result := sf(uint8(position^))
      else if(uniformType = oxunfSHADER_UINT16) then
         Result := sf(uint16(position^))
      else if(uniformType = oxunfSHADER_UINT32) then
         Result := sf(uint32(position^))
      else if(uniformType = oxunfSHADER_UINT64) then
         Result := sf(uint64(position^))
      else if(uniformType = oxunfSHADER_INT8) then
         Result := sf(int8(position^))
      else if(uniformType = oxunfSHADER_INT16) then
         Result := sf(int16(position^))
      else if(uniformType = oxunfSHADER_INT32) then
         Result := sf(int32(position^))
      else if(uniformType = oxunfSHADER_INT64) then
         Result := sf(int64(position^))
      else if(uniformType = oxunfSHADER_HALF) then
         Result := sf(single(position^))
      else if(uniformType = oxunfSHADER_FLOAT) then
         Result := sf(single(position^))
      else if(uniformType = oxunfSHADER_DOUBLE) then
         Result := sf(double(position^))
      else if(uniformType = oxunfSHADER_RGB) then
         Result := TColor3ub(position^).ToString()
      else if(uniformType = oxunfSHADER_RGBA) then
         Result := TColor4ub(position^).ToString()
      else if(uniformType = oxunfSHADER_RGB_FLOAT) then
         Result := TColor3f(position^).ToString()
      else if(uniformType = oxunfSHADER_RGBA_FLOAT) then
         Result := TColor4f(GetValuePosition(index)^).ToString()
      else if(uniformType = oxunfSHADER_TEXTURE) then begin
         if(oxTTexture(position^) <> nil) then
            Result := oxTTexture(position^).Name + ' (' + oxTTexture(position^).Path + ')'
         else
            Result := 'nil';
      end else if(uniformType = oxunfSHADER_VEC2F) then
         Result := TVector2f(position^).ToString()
      else if(uniformType = oxunfSHADER_VEC3F) then
         Result := TVector3f(position^).ToString()
      else if(uniformType = oxunfSHADER_VEC4F) then
         Result := TVector4f(position^).ToString()
      else if(uniformType = oxunfSHADER_VEC2I) then
         Result := TVector2i(position^).ToString()
      else if(uniformType = oxunfSHADER_VEC3I) then
         Result := TVector3i(position^).ToString()
      else if(uniformType = oxunfSHADER_VEC4I) then
         Result := TVector4i(position^).ToString()
      else
         Result := '';
   end else
      Result := '';
end;

function oxTMaterial.GetValueAsString(const what: string): string;
var
   index: loopint;

begin
   index := GetShaderIndex(what);

   if(index > -1) then
      Result := GetValueAsString(index)
   else
      Result := '';
end;

procedure oxTMaterial.LogMaterialValues();
var
   priority: LongInt;
   i: loopint;

begin
   if(Shader <> nil) then begin
      priority := logcINFO;
      log.s(priority, Name + ' (' + sf(Shader.Uniforms.n) + ' values)');

      for i := 0 to Shader.Uniforms.n - 1 do begin
         log.s(priority, Shader.GetUniformName(i) + ' = ' + GetValueAsString(i));
      end;
   end;
end;

procedure oxTMaterial.FromShader();
begin
   DisposeValues();
   FormPool();
end;

function oxTMaterial.FormPool(): loopint;
var
   i,
   index: loopint;

begin
   Result := 0;

   DisposeValues();

   {determine size of the pool}
   if(Shader <> nil) and (Shader.Uniforms.n > 0) then begin
      {pool indexes}
      Result := Shader.Uniforms.n * SizeOf(Pointer);
      {store index to point after the pool}
      index := Result;

      {go through all uniforms to determine size}
      for i := 0 to Shader.Uniforms.n - 1 do begin
         inc(Result, Shader.GetUniformSize(i));
      end;

      {determine value indexes}
      if(Result > 0) then begin
         XGetMem(ValuePool, Result);
         ZeroPtr(ValuePool, Result);
         Values := Values + ptrint(Result);
         ValueIndexes := ValuePool;

         {go through all uniforms to get their indexes in the pool}
         for i := 0 to Shader.Uniforms.n - 1 do begin
            ValueIndexes[i] := PtrInt(index);

            inc(index, Shader.GetUniformSize(i));
         end;

         {setup values}
         for i := 0 to Shader.Uniforms.n - 1 do begin
            oxShader.SetDefaultValue(Shader.Uniforms.List[i].UniformType, GetValuePosition(i));
         end;
      end;
   end;
end;

{$IFDEF OX_DEBUG}

function oxTMaterial.CheckType(index: loopint;
   uniformType: oxTShaderUniformType; alternativeType: oxTShaderUniformType): boolean;
begin
   Result := false;

   if(Shader <> nil) and (index > -1) and (index < Shader.Uniforms.n) then begin
      if(Shader.Uniforms.List[index].UniformType = uniformType) then
         exit(true);

      if(alternativeType <> oxunfSHADER_NONE) then
         if(Shader.Uniforms.List[index].UniformType = alternativeType) then
            exit(true);
   end;
end;

function oxTMaterial.DebugCheckType(index: loopint;
   uniformType: oxTShaderUniformType; alternativeType: oxTShaderUniformType): boolean;
begin
   Result := CheckType(index, uniformType, alternativeType);

   if(not Result) then begin
      if(index > -1) and (index < Shader.Uniforms.n) then
         if(alternativeType = oxunfSHADER_NONE) then begin
            log.w('Material(' + Name +  ') type (' + sf(loopint(uniformType)) + ') not equal for ' +
               sf(index) + '/' + Shader.Uniforms.List[index].Name +
               ' (expected: ' + sf(loopint(Shader.Uniforms.List[index].UniformType)) + ')')
         end else begin
            log.w('Material(' + Name +  ') type (' + sf(loopint(uniformType)) + ' or ' + sf(loopint(alternativeType)) + ') not equal for ' +
               sf(index) + '/' + Shader.Uniforms.List[index].Name +
               ' (expected: ' + sf(loopint(Shader.Uniforms.List[index].UniformType)) + ')')
         end
      else
         log.w('Material(' + Name +  ') index ' + sf(index) + ' out of bounds (count: ' + sf(Shader.Uniforms.n) + ')')
   end;
end;

{$ENDIF}

procedure oxTMaterial.DebugFailedType(index: loopint; const what: string);
begin
   log.w('Material(' + Name +  ') index ' + sf(index) + ' failed check: ' + what)
end;

function oxTMaterial.GetLoader(): POObject;
begin
   Result := oxMaterial.ResourceLoader;
end;

procedure onUse();
var
   pMaterialInstance: PSingleComponent;

begin
   FreeObject(oxMaterial.Default);

   pMaterialInstance := oxRenderer.FindComponent('material');

   if(pMaterialInstance <> nil) then
      oxMaterial.MaterialInstance := pMaterialInstance^;

   {create a default material}
   oxMaterial.Default := oxMaterial.Instance();
   oxMaterial.Default.Name := 'default';

   oxMaterial.Default.MarkPermanent();
   oxMaterial.Default.FromShader();

   oxCurrentMaterial := oxMaterial.Default;
end;

procedure deinit();
begin
   oxResource.Free(oxTResource(oxMaterial.Default));
end;

procedure threadInitialize();
begin
   oxCurrentMaterial := oxMaterial.Default;
end;

INITIALIZATION
   oxRenderers.PostUseRoutines.Add(@onUse);
   oxRenderers.Init.dAdd('material', @deinit);

   Threads.GetHandlerIndex(@threadInitialize);

END.
