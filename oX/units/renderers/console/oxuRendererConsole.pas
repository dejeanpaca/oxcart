{
   oxuRendererConsole, Console Renderer
   Copyright (C) 2016. Dejan Boras

   Started On:    28.11.2016.
}

{$INCLUDE oxdefines.inc}
{$INCLUDE oxfeaturedefines.inc}

{$IFDEF OX_NO_CONSOLE_RENDERER}
   {$FATAL Included console renderer, with OX_NO_CONSOLE_RENDERER defined}
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
