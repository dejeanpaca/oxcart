{
   oxuglExtensions, basic OpenGL extension management
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuglLog;

INTERFACE

   USES
      uStd, uLog, StringUtils,
      {ox}
      oxuWindowTypes, oxuRenderer,
      {renderer.gl}
      oxuOGL, oxuglExtensions;

procedure oglLogInformation(wnd: oglTWindow);

IMPLEMENTATION

procedure logExtensions();
var
   i: loopint;

begin
   log.Collapsed('OpenGL Extensions');

   for i := 0 to oglnExtensionDescriptors - 1 do begin
      if(oglExtensions.pExtensions[i].Present) then
         log.i(sf(i) + ': ' + oglExtensions.pExtensions[i].Name);
   end;

   log.Collapsed('Platform extensions');

   for i := 0 to oglExtensions.nPlatformSpecific - 1 do begin
      if(oglExtensions.PlatformSpecific[i].Present) then
         log.i(sf(i) + ': ' + oglExtensions.PlatformSpecific[i].Name);
   end;

   log.Leave();
   log.Leave();
end;

procedure oglLogInformation(wnd: oglTWindow);
begin
   log.Collapsed('Information');
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

   logExtensions();
end;

END.
