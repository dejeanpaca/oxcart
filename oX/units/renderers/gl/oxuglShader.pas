{
   oxuglShader, gl shader support
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuglShader;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      uStd, uLog,
      {ox}
      uOX, oxuShader, oxuRunRoutines,
      oxuOGL, oxuglRenderer;

TYPE
   oxglTShaderType = (
      glSHADER_TYPE_VERTEX,
      glSHADER_TYPE_FRAGMENT
   );

   oxglTUniformLocations = specialize TSimpleList<GLint>;

   { oxglTShaderObject }

   oxglTShaderObject = record
      Source: string;
      Shader: GLuint;
      Compiled: boolean;

      procedure Dispose();
   end;

   { oxglTShader }

   oxglTShader = class(oxTShader)
      const
      DefaultName = 'gl.default';

      public
      Vertex,
      Fragment: oxglTShaderObject;

      glProgram: GLuint;
      glUniformLocations: oxglTUniformLocations;

      function GetTypesString(): TAppendableString;
      function GetGLDescriptor(shaderType: GLenum = oglNONE): string;

      function Compile(var obj: oxglTShaderObject; shaderType: GLenum): boolean;
      function Compile(): boolean; override;
      function SetupUniforms(): boolean; override;

      procedure SetUniform(index: loopint; value: pointer); override;

      function CreateProgram(): boolean;

      procedure Detach(var obj: oxglTShaderObject);
      procedure DestroyProgramShaders();

      constructor Create(); override;
      destructor Destroy(); override;

      {$IFNDEF GLES}
      class function GetShaderTypeString(shaderType: GLenum): string; static;
      {$ENDIF}
   end;

IMPLEMENTATION

function componentReturn(): TObject;
begin
   result := oxglTShader.Create();
end;

{ oxglTShaderObject }

procedure oxglTShaderObject.Dispose();
begin
   if(Shader <> 0) then
      glDeleteShader(Shader);
end;

{ oxglTShaderObject }

{ oxglTShader }

function oxglTShader.GetTypesString(): TAppendableString;
begin
   Result := '';

   if(Vertex.Source <> '') then
      Result.Add('vertex', ', ');

   if(Fragment.Source <> '') then
      Result.Add('fragment', ', ');
end;

function oxglTShader.GetGLDescriptor(shaderType: GLenum): string;
var
   typeString: string;

begin
   typeString := GetShaderTypeString(shaderType);

   Result := '(gl ' + typeString + ') ' + GetDescriptor();
end;

function oxglTShader.Compile(var obj: oxglTShaderObject; shaderType: GLenum): boolean;
var
   strings: array[0..0] of PChar;
   lengths: array[0..0] of longint;
   success: GLint = 0;
   logSize: GLint = 0;
   shaderLog: array[0..16383] of char;

begin
   if(not obj.Compiled) then begin
      if(obj.Shader = 0) then begin
         obj.Shader := glCreateShader(shaderType);

         if(ogl.eRaise() <> GL_NONE) then begin
            log.e('Failed to create shader object');
            exit(False);
         end;
      end;

      if(obj.Source <> '') then begin
         strings[0] := @obj.Source[1];
         lengths[0] := Length(obj.Source);

         glShaderSource(obj.Shader, 1, @strings, @lengths);
         if(ogl.eRaise() <> GL_NONE) then
            log.e('Failed to set shader source: ' + GetGLDescriptor(shaderType));
      end else
         log.e('Empty source in ' + GetGLDescriptor());

      glCompileShader(obj.Shader);
      glGetShaderiv(obj.Shader, GL_COMPILE_STATUS, @success);

      if(success <> GLint(GL_FALSE)) then
         obj.Compiled := True
      else begin
         obj.Compiled := False;
         log.e('Failed to compile: ' + GetGLDescriptor(shaderType));

         {get log}
         glGetShaderiv(obj.Shader, GL_INFO_LOG_LENGTH, @logSize);

         if(logSize > 0) then begin
            glGetShaderInfoLog(obj.Shader, Length(shaderLog), @logSize, @shaderLog[0]);
            log.w('gl > shader log: ' + PChar(@shaderLog[0]));
         end;
      end;
   end;

   Result := obj.Compiled;
end;

function oxglTShader.Compile(): boolean;
begin
   if(Compile(Fragment, GL_FRAGMENT_SHADER)) then begin
      if(Compile(Vertex, GL_VERTEX_SHADER)) then begin
         exit(CreateProgram());
      end;
   end;

   Exclude(Properties, oxpSHADER_COMPILED);
   Result := false;
end;

function oxglTShader.SetupUniforms(): boolean;
var
   i: loopint;

begin
   if(Uniforms.n > 0) then begin
      glUniformLocations.Allocate(Uniforms.n);
      glUniformLocations.n := glUniformLocations.a;

      for i := 0 to Uniforms.n - 1 do begin
         glUniformLocations.List[i] := glGetUniformLocation(glProgram, pchar(Uniforms.List[i].Name));
         if(glUniformLocations.List[i] = -1) then begin
            log.e('Failed to get uniform location for ' + Uniforms.List[i].Name + ': ' + GetGLDescriptor());
         end;
      end;
   end;

   Result := true;
end;

procedure oxglTShader.SetUniform(index: loopint; value: pointer);
begin
   if(Uniforms.List[index].UniformType = oxunfSHADER_VEC2F) then
      glUniform1fv(glUniformLocations.List[index], 1, PGLfloat(value))
   else if(Uniforms.List[index].UniformType = oxunfSHADER_VEC2F) then
      glUniform2fv(glUniformLocations.List[index], 1, PGLfloat(value))
   else if(Uniforms.List[index].UniformType = oxunfSHADER_VEC3F) then
      glUniform3fv(glUniformLocations.List[index], 1, PGLfloat(value))
   else if(Uniforms.List[index].UniformType = oxunfSHADER_VEC4F) then
      glUniform4fv(glUniformLocations.List[index], 1, PGLfloat(value));

   ogl.eRaise();
end;

function oxglTShader.CreateProgram(): boolean;
var
   success: GLint = 0;
   logLength: GLint;
   programLog: array[0..16383] of char;

begin
   if(glProgram = 0) then begin
      glProgram := glCreateProgram();
      if(ogl.eRaise() <> GL_NONE) then begin
         log.e('gl > Failed to create a shader program');
         exit(False);
      end;

      if(Vertex.Shader <> 0) then
         glAttachShader(glProgram, Vertex.Shader);
      if(Vertex.Shader <> 0) then
         glAttachShader(glProgram, Fragment.Shader);

      glLinkProgram(glProgram);

      glGetProgramiv(glProgram, GL_LINK_STATUS, @success);
      if(success <> GLint(GL_FALSE)) then begin
         Include(Properties, oxpSHADER_COMPILED);

         Detach(Vertex);
         Detach(Fragment);

         exit(True);
      end else begin
         log.e('Failed to link program ' + GetGLDescriptor());
         glGetProgramiv(glProgram, GL_INFO_LOG_LENGTH, @logLength);
         if(logLength > 0) then begin
            glGetProgramInfoLog(glProgram, logLength, @logLength, @programLog[0]);

            log.w('gl > shader log: ' + PChar(@programLog[0]));
         end;
      end;

      DestroyProgramShaders();
   end else begin
      Include(Properties, oxpSHADER_COMPILED);
      Exit(True);
   end;

   Exclude(Properties, oxpSHADER_COMPILED);
   Result := False;
end;

procedure oxglTShader.Detach(var obj: oxglTShaderObject);
begin
   if(obj.Shader <> 0) then
      glDetachShader(glProgram, obj.Shader);
end;

procedure oxglTShader.DestroyProgramShaders();
begin
   if(glProgram <> 0) then
      glDeleteProgram(glProgram);

   Vertex.Dispose();
   Fragment.Dispose();
end;

constructor oxglTShader.Create();
begin
   inherited Create;

   Name := DefaultName;
   glUniformLocations.InitializeValues(glUniformLocations);
end;

destructor oxglTShader.Destroy();
begin
   inherited Destroy;
end;

{$IFNDEF GLES}
class function oxglTShader.GetShaderTypeString(shaderType: GLenum): string;
begin
   if(shaderType = GL_VERTEX_SHADER) then
      Result := 'vertex'
   else if(shaderType = GL_FRAGMENT_SHADER) then
      Result := 'fragment'
   else if (shaderType = GL_GEOMETRY_SHADER) then
      Result := 'geometry'
   else if (shaderType = GL_TESS_EVALUATION_SHADER) then
      Result := 'tess_evaluation'
   else if (shaderType = GL_TESS_CONTROL_SHADER) then
      Result := 'tess_control'
   else if (shaderType = GL_COMPUTE_SHADER) then
      Result := 'compute'
   else
      Result := 'unknown';
end;
{$ENDIF}

procedure init();
begin
   oxglRenderer.components.RegisterComponent('shader', @componentReturn);
end;

INITIALIZATION
   ox.PreInit.Add('ox.gl.shader', @init);

END.
