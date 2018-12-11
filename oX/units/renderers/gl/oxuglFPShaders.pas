{
   oxuglFPShaders, fixed pipeline "shader" suppport
   Copyright (C) 2018. Dejan Boras

   Started On:    31.03.2018.
}

{$INCLUDE oxdefines.inc}
UNIT oxuglFPShaders;

INTERFACE

   USES
      uStd, uLog,
      {ox}
      uOX,
      {gl}
      oxuShader, oxuTexture, oxuTypes, oxuRenderers, oxuResourcePool,
      {gl}
      oxuglShader, oxuglRenderer, oxuglFP, oxuglTextureComponent,
      {$INCLUDE usesgl.inc};

TYPE
   { oxglTFPShader }

   oxglTFPShader = class(oxTShader)
      constructor Create; override;

      function Compile(var obj: oxglTShaderObject; {%H-}shaderType: GLenum): boolean;
      function Compile(): boolean; override;

      procedure OnApply(); override;

      procedure SetUniform(index: loopint; value: pointer); override;

      function SetupUniforms(): boolean; override;
   end;

VAR
   oxglFPShader: oxglTFPShader;

IMPLEMENTATION

CONST
   fpuColor = 0;
   fpuTexture = 1;
   fpuMax = 2;

{ oxglTFPShader }

constructor oxglTFPShader.Create;
begin
   inherited Create;
end;

function oxglTFPShader.Compile(var obj: oxglTShaderObject; shaderType: GLenum): boolean;
begin
   obj.Compiled := True;
   Result := true;
end;

function oxglTFPShader.Compile(): boolean;
begin
   Include(Properties, oxpSHADER_COMPILED);
   Result := true;
end;

procedure oxglTFPShader.OnApply();
begin
   glEnable(GL_COLOR_MATERIAL);
end;

procedure oxglTFPShader.SetUniform(index: loopint; value: pointer);
var
   tex: oxTTexture;

begin
   if(index = fpuColor) then begin
      glColor4fv(PGLfloat(value));

      if(PGLfloat(value)[3] < 1.0) then
         glEnable(GL_BLEND)
      else
         glDisable(GL_BLEND);
   end else if(index = fpuTexture) then begin
      tex := oxTTexture(value^);

      if(tex <> nil) and (tex.rId <> 0) then begin
         glEnable(GL_TEXTURE_2D);
         glBindTexture(GL_TEXTURE_2D, tex.rId);
         glEnableClientState(GL_TEXTURE_COORD_ARRAY);
      end else begin
         glDisable(GL_TEXTURE_2D);
         glDisableClientState(GL_TEXTURE_COORD_ARRAY);
      end;
   end;
end;

function oxglTFPShader.SetupUniforms(): boolean;
begin
   Result := true;

   Uniforms.Allocate(fpuMax);

   AddUniform(oxunfSHADER_RGBA_FLOAT, 'color');
   AddUniform(oxunfSHADER_TEXTURE, 'texture');
end;

procedure onUse();
begin
   oxglFPShader := oxglTFPShader.Create();
   oxglFPShader.MarkPermanent();

   oxglFPShader.Name := 'gl.fp';
   oxglFPShader.SetupUniforms();
   oxglFPShader.Compile();

   oxShader.SetDefault(oxglFPShader, true);
end;

procedure init();
begin
end;

procedure deinit();
begin
   oxShader.Free(oxTShader(oxglFPShader));
   oxResource.Free(oxglFPShader);
end;

procedure preinit();
begin
   oxglRenderer.UseRoutines.Add(@onUse);
   oxglRenderer.Init.Add('gl.fpshader', @init, @deinit);
end;

INITIALIZATION
   ox.PreInit.iAdd('ox.gl.render', @preinit);

END.
