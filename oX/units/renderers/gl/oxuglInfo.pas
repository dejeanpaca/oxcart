{
   oxuglInfo, OpenGL information
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuglInfo;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      uLog,
      {ox}
      oxuOGL, oxuRenderer,
      oxuglExtensions, oxuglRendererInfo;

CONST
   ogleVERSION_OK            = 0;
   ogleVERSION_LOWER         = 1;
   ogleVERSION_UNSUPPORTED   = 2;

procedure oglGetInformation();
function oglVersionCheck(): longint;

IMPLEMENTATION

procedure oglGetInformation();
begin
   {$IFDEF GLES}
   oxglRendererInfo.GLES := true;
   {$ENDIF}

   {$IFNDEF OX_LIBRARY}
   {get basic information}
   oxglRendererInfo.Renderer := ogl.GetString(GL_RENDERER);
   oxglRendererInfo.Vendor   := ogl.GetString(GL_VENDOR);
   oxglRendererInfo.sVersion  := ogl.GetString(GL_VERSION);

   {try to figure out the OpenGL version}
   ogl.GetVersion(oxglRendererInfo.Version.Major,
      oxglRendererInfo.Version.Minor,
      oxglRendererInfo.Version.Revision,
      oxglRendererInfo.Version.Profile);

   oxglRendererInfo.iVersion := oxglRendererInfo.Version.Major * 100 + oxglRendererInfo.Version.Minor * 10;

   {get other information}
   glGetIntegerv(GL_MAX_TEXTURE_SIZE, @oxglRendererInfo.Limits.MaxTextureSize);
   glGetIntegerv(GL_MAX_CLIP_PLANES, @oxglRendererInfo.Limits.MaxClipPlanes);

   if(not oxglRendererInfo.GLES) then begin
      glGetIntegerv(GL_MAX_LIGHTS, @oxglRendererInfo.Limits.MaxLights);
      glGetIntegerv(GL_MAX_PROJECTION_STACK_DEPTH, @oxglRendererInfo.Limits.MaxProjectionStackDepth);
      glGetIntegerv(GL_MAX_MODELVIEW_STACK_DEPTH, @oxglRendererInfo.Limits.MaxModelViewStackDepth);
      glGetIntegerv(GL_MAX_TEXTURE_STACK_DEPTH, @oxglRendererInfo.Limits.maxTextureStackDepth);
   end;

   oxglRendererInfo.GLSL.Version := 'none';
   oxglRendererInfo.GLSL.Major := 0;
   oxglRendererInfo.GLSL.Minor := 0;
   oxglRendererInfo.GLSL.Compact := 0;

   {get shader information}
   if(oxglRendererInfo.Version.Major > 1) then begin
      {$IFNDEF GLES}
      {get GLSL version}
      oxglRendererInfo.GLSL.Version := ogl.GetString(GL_SHADING_LANGUAGE_VERSION);

      {get version in numerical form}
      if(oxglRendererInfo.GLSL.Version <> '') then
         ogl.GetGLSLVersion(oxglRendererInfo.GLSL.Version, oxglRendererInfo.GLSL.Major, oxglRendererInfo.GLSL.Minor, oxglRendererInfo.GLSL.Compact);

      if(oxglRendererInfo.GLSL.Compact = 0) then
         log.w('Failed to get/parse GLSL version');
      {$ENDIF}
   end;

   oglExtensions.Get();

   {$IFNDEF GLES}
   oxRenderer.Properties.Textures.Npot := oglExtensions.Supported(cGL_ARB_texture_non_power_of_two);
   {$ELSE}
   oxRenderer.Properties.Textures.Npot := false;
   oxRenderer.Properties.Textures.WarnedNpot := true;
   {$ENDIF}

   {$ELSE}
   oglExtensions.Get();
   {$ENDIF}
end;

function oglVersionCheck(): longint;
var
   required,
   default: oglTVersion;

begin
   required := oxglRendererInfo.GetRequiredVersion();
   default := oxglRendererInfo.GetExpectedVersion();

   if(ogl.CompareVersions(oxglRendererInfo.Version, required) < 0) then begin
      log.e('OpenGL version ' + oxglRendererInfo.Version.GetString() + ' is lower than required ' + required.GetString());

      exit(ogleVERSION_UNSUPPORTED);
   end;

   if(ogl.CompareVersions(oxglRendererInfo.Version, default) < 0) then begin
      log.w('OpenGL version ' + oxglRendererInfo.Version.GetString() + ' is lower than targeted ' + default.GetString());

      exit(ogleVERSION_LOWER);
   end;

   Result := ogleVERSION_OK;
end;

END.
