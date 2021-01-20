{
   oxuRendererGL, OpenGL Renderer
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}

{$IFNDEF OX_RENDERER_GL}
   {$FATAL Included gl renderer, with no OX_RENDERER_GL defined}
{$ENDIF}

UNIT oxuRendererGL;

INTERFACE

   USES
      uStd,
      oxuglRenderer,
      {$IF DEFINED(WINDOWS)}
      oxuglRendererWin, {$IFNDEF OX_LIBRARY}oxuWindowsPlatform,{$ENDIF}
      {$ELSEIF DEFINED(X11)}
      oxuglRendererX11, {$IFNDEF OX_LIBRARY}oxuX11Platform,{$ENDIF}
      {$ELSEIF DEFINED(COCOA)}
      oxuglRendererCocoa, {$IFNDEF OX_LIBRARY}oxuCocoaPlatform,{$ENDIF}
      {$ELSEIF DEFINED(ANDROID)}
      oxuglRendererEGL, {$IFNDEF OX_LIBRARY}oxuAndroidPlatform,{$ENDIF}
      {$ENDIF}
      oxuglTextureComponent,
      oxuglTextureGenerate,
      oxuglTransform,
      oxuglRender,
      {$IFNDEF GLES}
      oxuglShader,
      oxuglShaderLoader,
      {$ENDIF}
      oxuglMaterial,
      {$IF (NOT DEFINED(OX_LIBRARY)) AND (NOT DEFINED(GLES))}oxuglDebugOutput,{$ENDIF}
      oxuglFP,
      oxuglFPShaders,
      oxuglScreenshot,
      oxuglParams;

IMPLEMENTATION

{we don't need to indicate which platform instance we want for the renderer, as we use the editor one}
{$IFNDEF OX_LIBRARY}
VAR
   PlatformInstance: TClass;

INITIALIZATION
   {$INCLUDE ../../ox_default_platform_instance.inc}
   oxglTRenderer.glSystemPlatform := PlatformInstance;
{$ENDIF}

END.
