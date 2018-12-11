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
      oxuglShader,
      oxuglShaderLoader,
      oxuglMaterial
      {$IFNDEF OX_LIBRARY}, oxuglDebugOutput{$ENDIF},
      oxuglFP,
      oxuglFPShaders;

IMPLEMENTATION

END.
