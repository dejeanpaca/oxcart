{
   oxuglShaderLoader, gl shader loader support
   Copyright (C) 2017. Dejan Boras

   Started On:    21.12.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuglShaderLoader;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      uStd, sysutils, uSimpleParser, StringUtils, uFiles, uLog,
      {ox}
      uOX, oxuShader, oxuShaderLoader, oxuWindow, oxuFile,
      oxuglRenderer, oxuglShader, oxuOGL;

TYPE
   { oxglTShaderLoader }

   oxglTShaderLoader = class(oxTShaderLoader)
      function Load(shader: oxTShader; var data: oxTFileRWData): boolean; override;
   end;

VAR
   oxglShaderLoader: oxglTShaderLoader;

IMPLEMENTATION

TYPE
   PParserOptions = ^TParserOptions;
   TParserOptions = record
      Values: record
         Vertex,
         Fragment,
         GLSLVersion: string;
      end;

      {path where the glshader file is found}
      Path: string;
      {shader to be loaded}
      Shader: oxglTShader;
      {current glsl version}
      GLSLVersion: loopint;

      Data: oxPFileRWData;
   end;

function componentReturn(): TObject;
begin
   Result := oxglShaderLoader;
end;

procedure init();
begin
   oxglRenderer.components.RegisterComponent('shader.loader', @componentReturn);
   oxglShaderLoader := oxglTShaderLoader.Create();
end;

procedure deinit();
begin
   FreeObject(oxglShaderLoader);
end;

function loadShaderFile(const shaderFile, typeString: string; const options: TParserOptions): string;
var
   valid: boolean;

begin
   valid := shaderFile <> '';
   Result := '';

   if(not valid) then begin
      options.Data^.SetError('Invalid shader filename (' + shaderFile  + ') of type ' + typeString + ' in ' + options.Path + 'glshader');
      exit();
   end;

   Result := fGetString(options.Path + shaderFile);
   if(Result = '') then
      options.Data^.SetError('Failed to load shader file (' + shaderFile  + ') of type ' + typeString + ' specified in ' + options.Path + 'glshader');
end;

function parseShaderFile(var d: TParseData): boolean;
var
   options: PParserOptions;
   key,
   value: string;
   glslVersion,
   code: loopint;

begin
   options := d.externalData;

   if(StringUtils.GetKeyValue(d.currentLine, key, value, ':')) then begin
      if(key = 'version') then begin
         val(value, glslVersion, code);

         if(code = 0) then begin
            if(options^.Values.GLSLVersion = '') then begin
               {check if first version is higher}
               if(glslVersion > options^.GLSLVersion) then begin
                  options^.Data^.SetError('fist glsl version found is unsupported: ' + value + ' > ' + sf(options^.GLSLVersion));
                  exit(false);
               end;
            end;

            if(glslVersion <= options^.GLSLVersion) then
               options^.Values.GLSLVersion := value
            else
               {stop if we encounter shader version higher than ours}
               d.ReadMethod := nil;
         end else begin
            options^.Data^.SetError('Invalid glsl version specified: ' + value);
            exit(false);
         end;
      end else if(key = 'fragment') then
         options^.Values.Fragment := value
      else if(key = 'vertex') then
         options^.Values.Vertex := value;
   end;

   Result := true;
end;

{ oxglTShaderLoader }

function oxglTShaderLoader.Load(shader: oxTShader; var data: oxTFileRWData): boolean;
var
   path: string;

   parseData: TParseData;
   parseOptions: TParserOptions;
   shaderTypes: TAppendableString;

begin
   {construct path to the gl shader file}
   path :=  IncludeTrailingPathDelimiter(ExtractFilePath(shader.Path)) + 'gl' + DirectorySeparator;

   ZeroOut(parseOptions, SizeOf(parseOptions));
   parseOptions.Shader := oxglTShader(shader);
   parseOptions.Path := path;
   parseOptions.glslVersion := oglTWindow(oxWindow.Current).Info.GLSL.Compact;
   parseOptions.Data := @data;

   TParseData.Init(parseData);
   parseData.externalData := @parseOptions;
   parseData.ReadMethod := TParseExtMethod(@parseShaderFile);
   parseData.StripWhitespace := false;

   if(parseData.Read(path + 'glshader')) then begin
      if(parseOptions.Values.Fragment <> '') then
         parseOptions.Shader.Fragment.Source := loadShaderFile(parseOptions.Values.Fragment, 'fragment', parseOptions);

      if(data.Error = 0) and (parseOptions.Values.Vertex <> '') then
         parseOptions.Shader.Vertex.Source := loadShaderFile(parseOptions.Values.Vertex, 'vertex', parseOptions);

      shaderTypes := parseOptions.Shader.GetTypesString();

      log.v('Loaded gl shaders (' + shaderTypes + ') from ' + path + ', version ' + parseOptions.Values.GLSLVersion);
      exit(data.Error = 0);
   end;

   Result := false;
end;

INITIALIZATION
   ox.PreInit.Add('gl.shader_loader', @init, @deinit);

END.

