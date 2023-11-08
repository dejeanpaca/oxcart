{
   oxuglInfo, OpenGL information
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuglInfo;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      uLog,
      {ox}
      oxuOGL, oxuglExtensions, oxuRenderer;

CONST
   ogleVERSION_OK            = 0;
   ogleVERSION_LOWER         = 1;
   ogleVERSION_UNSUPPORTED   = 2;

procedure oglGetInformation(wnd: oglTWindow);
function oglVersionCheck(wnd: oglTWindow): longint;

IMPLEMENTATION

procedure oglGetInformation(wnd: oglTWindow);
{$IFNDEF OX_LIBRARY}
var
   renderer: oxTRenderer;
{$ENDIF}

begin
   {$IFNDEF OX_LIBRARY}
   renderer := oxTRenderer(wnd.Renderer);

   {get basic information}
   wnd.Info.Renderer := ogl.GetString(GL_RENDERER);
   wnd.Info.Vendor   := ogl.GetString(GL_VENDOR);
   wnd.Info.Version  := ogl.GetString(GL_VERSION);

   {try to figure out the OpenGL version}
   ogl.GetVersion(wnd.gl.Version.Major,
      wnd.gl.Version.Minor,
      wnd.gl.Version.Revision,
      wnd.gl.Version.Profile);

   wnd.Info.iVersion := wnd.gl.Version.Major * 100 + wnd.gl.Version.Minor * 10;

   {get other information}
   glGetIntegerv(GL_MAX_TEXTURE_SIZE,  @wnd.Limits.MaxTextureSize);
   glGetIntegerv(GL_MAX_LIGHTS,        @wnd.Limits.MaxLights);
   glGetIntegerv(GL_MAX_CLIP_PLANES,   @wnd.Limits.MaxClipPlanes);

   glGetIntegerv(GL_MAX_PROJECTION_STACK_DEPTH, @wnd.Limits.MaxProjectionStackDepth);
   glGetIntegerv(GL_MAX_MODELVIEW_STACK_DEPTH,  @wnd.Limits.MaxModelViewStackDepth);
   glGetIntegerv(GL_MAX_TEXTURE_STACK_DEPTH,    @wnd.Limits.maxTextureStackDepth);

   wnd.Info.GLSL.Version := 'none';
   wnd.Info.GLSL.Major := 0;
   wnd.Info.GLSL.Minor := 0;
   wnd.Info.GLSL.Compact := 0;

   {get shader information}
   if(wnd.gl.Version.Major > 1) then begin
      {$IFNDEF GLES}
      {get GLSL version}
      wnd.Info.GLSL.Version := ogl.GetString(GL_SHADING_LANGUAGE_VERSION);

      {get version in numerical form}
      if(wnd.Info.GLSL.Version <> '') then
         ogl.GetGLSLVersion(wnd.Info.GLSL.Version, wnd.Info.GLSL.Major, wnd.Info.GLSL.Minor, wnd.Info.GLSL.Compact);

      if(wnd.Info.GLSL.Compact = 0) then
         log.w('Failed to get/parse GLSL version');
      {$ENDIF}
   end;

   oglExtensions.Get(wnd);

   {$IFNDEF GLES}
   renderer.Properties.Textures.Npot := oglExtensions.Supported(cGL_ARB_texture_non_power_of_two);
   {$ELSE}
   renderer.Properties.Textures.Npot := false;
   renderer.Properties.Textures.WarnedNpot := true;
   {$ENDIF}

   {$ELSE}
   wnd.Info := oglTWindow(wnd.ExternalWindow.oxwParent).Info;
   oglExtensions.Get(wnd);
   {$ENDIF}
end;

function oglVersionCheck(wnd: oglTWindow): longint;
begin
   if(ogl.CompareVersions(wnd.gl.Version, wnd.glRequired.Version) < 0) then begin
      log.e('OpenGL version ' + wnd.gl.GetString() + ' is lower than required ' + wnd.glRequired.GetString());

      exit(ogleVERSION_UNSUPPORTED);
   end;

   if(ogl.CompareVersions(wnd.gl.Version, wnd.glDefault.Version) < 0) then begin
      log.w('OpenGL version ' + wnd.gl.GetString() + ' is lower than targeted ' + wnd.glDefault.GetString());

      exit(ogleVERSION_LOWER);
   end;

   Result := ogleVERSION_OK;
end;

END.
