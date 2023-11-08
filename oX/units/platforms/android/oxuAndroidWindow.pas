{
   oxuAndroidWindow
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuAndroidWindow;

INTERFACE

   USES
      egl,
      {oX}
      oxuWindowTypes;

TYPE
   androidTWindow = class(oxTWindow)
      wd: record
         surface: EGLSurface;
         context: EGLContext;
         display: EGLDisplay;
         config: EGLConfig;
      end;
   end;

IMPLEMENTATION

END.
