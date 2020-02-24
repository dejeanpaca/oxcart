{
   oxuGLX, GLX specific functionality
   Copyright (C) 2013. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuGLX;

INTERFACE

   USES
     {$INCLUDE usesgl.inc},
     uLog, StringUtils, ustrList,
     xlib, GLX,
     {oX}
     oxuWindowTypes,
     oxuOGL, oxuglExtensions, oxuX11Platform;

CONST
   cGLX_ARB_create_context                    = 0;
   cGLX_ARB_create_context_profile            = 1;

   glxnExtensions = 2;
   glxExtensions: array[0..glxnExtensions - 1] of oglTExtensionDescriptor = (
      (
         Name: 'GLX_ARB_create_context';
         Present: false
      ),
      (
         Name: 'GLX_ARB_create_context_profile';
         Present: false
      )
   );

IMPLEMENTATION

procedure GetExts(i: longint; const ext: string);
var
   id: longint;

begin
   id := oglExtensions.FindDescriptor(glxExtensions, ext);
   if(id > -1) then
      glxExtensions[id].Present := true;

   log.i(sf(i) + ':' + ext);
end;

procedure getExtensions({%H-}wnd: oxTWindow);
var
   exts: pChar;

begin
   if(glXQueryExtensionsString <> nil) then begin
      exts := glXQueryExtensionsString(x11.DPY, DefaultScreen(x11.DPY));

      if(Length(exts) > 0) then begin
         log.Enter('GLX');

         strList.ProcessSpaceSeparated(exts, @GetExts);
         log.Leave();
      end;
   end else
      log.w('There seems to be no GLX extensions.')
end;

INITIALIZATION
   oglExtensions.GetPlatformSpecific := @getExtensions;
   oglExtensions.nPlatformSpecific := glxnExtensions;
   oglExtensions.PlatformSpecific := @glxExtensions[0];

END.
