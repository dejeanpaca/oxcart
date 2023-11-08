{
   oxuRendererGL, OpenGL Renderer
   Copyright (C) 2016. Dejan Boras

   Started On:    17.01.2016.
}

{$INCLUDE oxdefines.inc}

{$IFNDEF OX_RENDERER_GL}
   {$FATAL Included gl renderer, with no OX_RENDERER_GL defined}
{$ENDIF}

UNIT oxuRendererGL;

INTERFACE

   USES
      oxuglRenderer,
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
      oxuglFPShaders;

IMPLEMENTATION

END.
