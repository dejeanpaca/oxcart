{
   oxuglExtensions, basic OpenGL extension management
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuglLog;

INTERFACE

   USES
      uStd, uLog, StringUtils,
      {ox}
      oxuRenderer,
      {renderer.gl}
      oxuOGL, oxuglExtensions, oxuglRendererInfo;

procedure oglLogInformation();

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

   if(oglExtensions.nPlatformSpecific > 0) then begin
      log.Collapsed('Platform extensions');

      for i := 0 to oglExtensions.nPlatformSpecific - 1 do begin
         if(oglExtensions.PlatformSpecific[i].Present) then
            log.i(sf(i) + ': ' + oglExtensions.PlatformSpecific[i].Name);
      end;

      log.Leave();
   end;

   log.Leave();
end;

procedure oglLogInformation();
begin
   log.Collapsed('Information');
      log.i('Renderer: ' + oxglRendererInfo.Renderer);
      log.i('Vendor: ' + oxglRendererInfo.Vendor);

      log.i('Version: ' + oxglRendererInfo.Version.GetString() + ' ' + sf(oxglRendererInfo.iVersion) +
         ' (original: ' + oxglRendererInfo.sVersion + ')');

      if(oxglRendererInfo.Version.Major > 1) then
         log.i('GLSL Version: ' + sf(oxglRendererInfo.GLSL.Compact) + ' (original: ' + oxglRendererInfo.GLSL.Version + ')');

      log.Enter('Capabilities');
      log.i('Maximum Texture Size: ' + sf(oxglRendererInfo.Limits.MaxTextureSize) + 'x' + sf(oxglRendererInfo.Limits.MaxTextureSize));
      log.i('Maximum Lights: ' + sf(oxglRendererInfo.Limits.MaxLights));
      log.i('Maximum Clip Planes: ' + sf(oxglRendererInfo.Limits.MaxClipPlanes));
      log.i('Supports non power of two textures: ' + sf(oxRenderer.Properties.Textures.Npot));
      log.Leave();
      log.Enter('Stack depths');
      log.i('Projection Stack: ' + sf(oxglRendererInfo.Limits.MaxProjectionStackDepth));
      log.i('ModelView Stack: ' + sf(oxglRendererInfo.Limits.MaxModelViewStackDepth));
      log.i('Texture Stack: ' + sf(oxglRendererInfo.Limits.MaxTextureStackDepth));
      log.Leave();
   log.Leave();

   logExtensions();
end;

END.
