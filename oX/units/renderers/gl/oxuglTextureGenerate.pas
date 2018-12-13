{
   oxuglTextureGenerateComponent, texture generating component
   Copyright (C) 2011. Dejan Boras

   Started On:    08.02.2016.
}

{$INCLUDE oxdefines.inc}
UNIT oxuglTextureGenerate;

INTERFACE

   USES
   {$INCLUDE usesgl.inc},
      uStd, uLog, uImage, StringUtils,
      {ox}
      uOX, oxuTypes, oxuTexture, oxuTextureGenerate,
      oxuOGL, oxuglRenderer;

TYPE
   { oglTTextureGenerateComponent }
   oglTTextureGenerateComponent = class(oxTTextureGenerateComponent)
      public
      function Generate(var gen: oxTTextureGenerate; var tex: oxTTextureID): longint; override;
   end;

IMPLEMENTATION

VAR
   oglTextureGenerate: oglTTextureGenerateComponent;

function componentReturn(): TObject;
begin
   Result := oglTextureGenerate;
end;

{ oglTextureGenerateComponent }

function oglTTextureGenerateComponent.Generate(var gen: oxTTextureGenerate; var tex: oxTTextureID): longint;
var
   typ,
   storageType,
   texDim: GLuint;
   glErr: GLenum;
   mips: boolean;

function enoughMem(): boolean;
{$IFNDEF GLES}
var
   fmt: GLint;
{$ENDIF}

begin
   {$IFNDEF GLES}
   fmt := 0;
   glTexImage2D(GL_PROXY_TEXTURE_2D, 0, typ, gen.image.Width, gen.image.Height, 0, typ, storageType, nil);
   glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, 0, GL_TEXTURE_INTERNAL_FORMAT, @fmt);
   Result := fmt <> 0;
   {$ELSE}
   Result := true;
   {$ENDIF}
end;

begin
   glErr := ogl.eRaise();
   if(glErr <> 0) then
      Log.e('gl > error at start of generating texture: ' + ogl.ErrorString(glErr));

   Result := eNONE;

   texDim := GL_TEXTURE_2D;

   {generate a opengl texture if one was not generated}
   if(tex = 0) then
      glGenTextures(1, @tex);

   glErr := glGetError();
   if(glErr <> 0) then begin
      log.e('gl > error ' + ogl.ErrorString(glErr) + ' while generating texture.');
      exit(oxeRENDERER);
   end;

   {determine storage type and pixel format}

   storageType := GL_UNSIGNED_BYTE;
   if(gen.image.PixF = PIXF_RGB) then
      typ := GL_RGB
   else if (gen.image.PixF = PIXF_RGBA) then
      typ := GL_RGBA
   else begin
      log.e('gl > Image pixel format not supported: ' + img.PIXFName(gen.image.PixF));
      exit(eUNSUPPORTED);
   end;

   if(enoughMem() = false) then begin
      log.e('gl > Insufficient graphics memory to generate texture.');
      exit(oxeNO_GRAPHICS_MEM);
   end;

   mips := (gen.MipCount = -1) or (gen.MipCount > 0);

   {bind texture and assign parameters}
   glBindTexture(texDim, Tex);
   tex.SetFilter(gen.Filter);
   tex.SetRepeat(gen.RepeatType);

   {generate the texture}
   glTexImage2D(texDim, 0, typ, gen.Image.Width, gen.Image.Height, 0, typ, storageType, gen.Image.Image);

   {generate 2D mipmaps}
   {$IFNDEF GLES}
   if(mips) then begin
      glGenerateMipmap(texDim);

      if(ogl.eRaise(-1) <> 0) then
         log.w('Failed to generate mip-maps for: ' + gen.Image.FileName);
   end;
   {$ENDIF}

   glErr := glGetError();
   if(glErr <> 0) then begin
      Result := oxeRENDERER;

      log.e('gl > error(' + sf(glErr) + ') while generating texture image: ' + gen.image.FileName);
   end;
end;

procedure init();
begin
   oglTextureGenerate := oglTTextureGenerateComponent.Create();

   oxglRenderer.Components.RegisterComponent('texture.generate', @componentReturn);
end;

procedure deinit();
begin
   oglTextureGenerate.Free();
end;

INITIALIZATION
   ox.PreInit.Add('ox.gl.texture_generate', @init, @deinit);

END.
