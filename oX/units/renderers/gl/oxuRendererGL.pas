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
      oxuglRendererWin, oxuWindowsPlatform,
      {$ELSEIF DEFINED(X11)}
      oxuglRendererX11, oxuX11Platform,
      {$ELSEIF DEFINED(COCOA)}
      oxuglRendererCocoa, oxuCocoaPlatform,
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

VAR
   PlatformInstance: TClass;

INITIALIZATION
   {$INCLUDE ../../ox_default_platform_instance.inc}
   oxglTRenderer.glSystemPlatform := PlatformInstance;

END.
