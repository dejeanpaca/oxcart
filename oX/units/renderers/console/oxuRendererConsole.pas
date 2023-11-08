{
   oxuRendererConsole, Console Renderer
   Copyright (C) 2016. Dejan Boras

   Started On:    28.11.2016.
}

{$IFDEF OX_NO_CONSOLE_RENDERER}
   {$FATAL Included console renderer, with OX_NO_CONSOLE_RENDERER defined}
{$ENDIF}

{$INCLUDE oxdefines.inc}
UNIT oxuRendererConsole;

INTERFACE

   USES oxuConsoleRenderer, oxurConsoleRender, oxurConsoleTextureComponent;

IMPLEMENTATION

END.
