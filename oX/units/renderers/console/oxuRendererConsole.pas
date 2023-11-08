{
   oxuRendererConsole, Console Renderer
   Copyright (C) 2016. Dejan Boras

   Started On:    28.11.2016.
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
