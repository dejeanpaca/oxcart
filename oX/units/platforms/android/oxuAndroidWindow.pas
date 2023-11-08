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
         Surface: EGLSurface;
         Context: EGLContext;
         Display: EGLDisplay;
         Config: EGLConfig;
      end;
   end;

IMPLEMENTATION

END.
