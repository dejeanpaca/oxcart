{
   oxuWindowTypes, oX window data types
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuRendererSettings;

INTERFACE

   USES
      uStd, udvars,
      {ox}
      uOX;

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

TYPE
   oxTRenderSettings = record
      dvg: TDVarGroup;
      TargetFramerate: loopint;
   end;

VAR
   oxRenderSettings: oxTRenderSettings;

IMPLEMENTATION

INITIALIZATION
   ox.dvar.Add('render', oxRenderSettings.dvg);

   oxRenderSettings.TargetFramerate := 60;

END.
