{
   oxuglInfo, OpenGL information
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuglInfo;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      uLog, {$IFNDEF OX_LIBRARY}StringUtils,{$ENDIF}
      {ox}
      oxuOGL, oxuglExtensions, oxuRenderer;

CONST
   ogleVERSION_OK            = 0;
   ogleVERSION_LOWER         = 1;
   ogleVERSION_UNSUPPORTED   = 2;

procedure oglGetInformation(wnd: oglTWindow);
procedure oglLogInformation(wnd: oglTWindow);
function oglVersionCheck(wnd: oglTWindow): longint;

IMPLEMENTATION

procedure oglGetInformation(wnd: oglTWindow);
begin
   {$IFNDEF OX_LIBRARY}
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
   {$ELSE}
   wnd.Info := oglTWindow(wnd.ExternalWindow.oxwParent).Info;
   oglExtensions.Get(wnd);
   {$ENDIF}
end;

procedure oglLogInformation(wnd: oglTWindow);
begin
   log.Collapsed('OpenGL Information');
      log.i('Renderer: ' + wnd.Info.Renderer);
      log.i('Vendor: ' + wnd.Info.Vendor);

      log.i('Version: ' + wnd.gl.GetString() + ' ' + sf(wnd.Info.iVersion) +
         ' (original: ' + wnd.Info.Version + ')');

      if(wnd.gl.Version.Major > 1) then
         log.i('GLSL Version: ' + sf(wnd.Info.GLSL.Compact) + ' (original: ' + wnd.Info.GLSL.Version + ')');

      log.Enter('Capabilities');
      log.i('Maximum Texture Size: ' + sf(wnd.Limits.MaxTextureSize) + 'x' + sf(wnd.Limits.MaxTextureSize));
      log.i('Maximum Lights: ' + sf(wnd.Limits.MaxLights));
      log.i('Maximum Clip Planes: ' + sf(wnd.Limits.MaxClipPlanes));
      log.i('Supports non power of two textures: ' + sf(oxTRenderer(wnd.Renderer).Properties.Textures.Npot));
      log.Leave();
      log.Enter('Stack depths');
      log.i('Projection Stack: ' + sf(wnd.Limits.MaxProjectionStackDepth));
      log.i('ModelView Stack: ' + sf(wnd.Limits.MaxModelViewStackDepth));
      log.i('Texture Stack: ' + sf(wnd.Limits.MaxTextureStackDepth));
      log.Leave();
   log.Leave();

   oglExtensions.Log(wnd);
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
