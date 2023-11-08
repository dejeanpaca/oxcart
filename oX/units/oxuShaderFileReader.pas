{
   oxuShaderFileReader, oX shader file reading
   Copyright (C) 2017. Dejan Boras

   Started On:    26.09.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuShaderFileReader;

INTERFACE

   USES
      uStd, uFile, uFileHandlers, uLog, StringUtils,
      {ox}
      uOX, oxuRunRoutines, oxuFile, oxuShader, oxuShaderFile, oxuShaderLoader;

IMPLEMENTATION

VAR
   ext: fhTExtension;
   handler: fhTHandler;

procedure handleFile(var f: TFile; var data: oxTFileRWData);
var
   s,
   key,
   value: StdString;
   shader: oxTShader = nil;
   code: longint;

   values: record
      name: string;
      UniformCount: loopint;
   end;

   uniforms: oxTShaderUniforms;
   uniform: oxTShaderUniform;
   uniformIndex: loopint;

begin
   s := '';
   key := '';
   value := '';
   values.name := '';
   values.UniformCount := 0;

   uniforms.Initialize(uniforms);

   repeat
      f.Readln(s);

      if(GetKeyValue(s, key, value, ':')) then begin
         if(key = 'name') then
            values.Name := value
         else if(key = 'uniforms') then begin
            val(value, values.UniformCount, code);

            if(code <> 0) then
               data.SetError('Invalid uniform count: ' + value);

            break;
         end;
      end;
   until f.EOF() or (f.Error <> 0);

   uniformIndex := 0;

   // read uniforms
   if(values.UniformCount > 0) then begin
      uniforms.Allocate(values.UniformCount);

      repeat
         f.Readln(s);
         if(GetKeyValue(s, key, value, ':')) then begin
            if(uniformIndex >= uniforms.a) then begin
               log.w('Too many uniforms listed in ' + f.fn);
               break;
            end;

            uniform.Name := key;
            uniform.UniformType := oxShader.GetUniformType(value);

            if(uniform.UniformType <> oxunfSHADER_NONE) then begin
               uniforms[uniformIndex] := uniform;
               inc(uniformIndex);
               inc(uniforms.n)
            end else begin
               data.SetError('Invalid type ' + value + ' for uniform ' + key);
               break;
            end;
         end;
      until f.EOF() or (f.Error <> 0);
   end;

   if(uniforms.n <> uniforms.a) then begin
      data.SetError('Insufficient uniforms listed' );
   end;

   if(f.Error = 0) and (data.Error = 0) then begin
      uniforms.n := uniforms.a;

      shader := oxShader.Instance();
      shader.Path := f.fn;
      shader.Name := values.name;

      if(uniforms.n > 0) then
         Shader.Uniforms := uniforms;

      if(oxShaderLoader <> nil) then begin
         if(oxShaderLoader.Load(shader, data)) then begin
            shader.Compile();

            if(oxpSHADER_COMPILED in shader.Properties) then begin
               shader.SetupUniforms();
            end else begin
               data.SetError('Shader failed to compile');
            end;
         end else
            data.SetError('Shader loader failed');
      end;

      data.Result := shader;
   end else begin
      uniforms.Dispose();

      if(f.Error <> 0) then
         data.SetError('Failed to read shader file')
      else
        data.SetError('Failed to parse shader file');
   end;
end;

procedure handle(data: pointer);
begin
   handleFile(oxTFileRWData(data^).f^, oxTFileRWData(data^));
end;

procedure init();
begin
   oxfShader.Readers.RegisterHandler(handler, 'oxs', @handle);
   oxfShader.Readers.RegisterExt(ext, '.oxs', @handler);
end;

INITIALIZATION
   ox.Init.Add('shader_reader', @init);

END.
