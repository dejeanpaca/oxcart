{
   oxuRendererConsole, Console Renderer
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}

{$IFNDEF OX_RENDERER_CONSOLE}
   {$FATAL Included console renderer, with no OX_RENDERER_CONSOLE defined}
{$ENDIF}

UNIT oxuRendererConsole;

INTERFACE

   USES
      uStd,
      oxuConsoleRenderer, oxurConsoleRender, oxurConsoleTextureComponent;

IMPLEMENTATION

INITIALIZATION
   Pass();

END.
