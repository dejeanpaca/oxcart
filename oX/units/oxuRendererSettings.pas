{
   oxuWindowTypes, oX window data types
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuRendererSettings;

INTERFACE

   USES
      uStd;

TYPE
   {settings for a renderer}
   oxTRendererSettings = record
      DoubleBuffer,
      Software,
      Stereo,
      VSync: boolean;

      ColorBits,
      DepthBits,
      StencilBits,
      AccumBits,
      AuxBuffers: longword;

      Layer: loopint;
   end;

CONST
   oxrTargetSettings: oxTRendererSettings = (
      DoubleBuffer: true;
      Software: false;
      Stereo: false;
      VSync: false;

      ColorBits:     32;
      DepthBits:     24;
      StencilBits:   0;
      AccumBits:     0;
      AuxBuffers:    0;
      Layer:         0
   );

   oxrContextSettings: oxTRendererSettings = (
      DoubleBuffer: true;
      Software: false;
      Stereo: false;
      VSync: false;

      ColorBits:        32;
      DepthBits:        24;
      StencilBits:      0;
      AccumBits:        0;
      AuxBuffers:       0;
      Layer:            0
   );

IMPLEMENTATION

END.
