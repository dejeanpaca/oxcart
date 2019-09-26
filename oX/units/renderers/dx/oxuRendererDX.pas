{
   oxudxRenderer, DirectX renderer
   Copyright (C) 2018. Dejan Boras

   Started On:    27.12.2018.
}

{$INCLUDE oxdefines.inc}

{$IFNDEF OX_RENDERER_DX11}
   {$FATAL Included dx renderer, with no OX_RENDERER_DX11 defined}
{$ENDIF}

{$IFNDEF WINDOWS}
   {$FATAL dx renderer is only available on windows}
{$ENDIF}

UNIT oxuRendererDX;

INTERFACE

   USES
      uStd,
      oxudxRenderer;

IMPLEMENTATION

INITIALIZATION
   Pass();

END.
