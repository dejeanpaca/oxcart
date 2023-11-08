{
   oxuEGLWindow
   Copyright (c) 2020. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuEGLWindow;

INTERFACE

   USES
      egl,
      {oX}
      oxuWindowTypes;

TYPE
   eglTWindow = class(oxTWindow)
      wd: record
         Surface: EGLSurface;
         Context: EGLContext;
         Display: EGLDisplay;
         Config: EGLConfig;
         ValidSurface: boolean;
      end;
   end;

IMPLEMENTATION

END.
