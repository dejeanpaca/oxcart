{
   oxuWGL, WGL extensions list
   Copyright (C) 2013. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuWGL;

INTERFACE

   USES uLog, StringUtils, ustrList,
      {$INCLUDE usesglext.inc},
      oxuWindowTypes, oxuglExtensions, oxuWindowsOS;

CONST
   cWGL_EXT_depth_float                       = 0;
   cWGL_ARB_buffer_region                     = 1;
   cWGL_ARB_extensions_string                 = 2;
   cWGL_ARB_make_current_read                 = 3;
   cWGL_ARB_pixel_format                      = 4;
   cWGL_ARB_pbuffer                           = 5;
   cWGL_EXT_extensions_string                 = 6;
   cWGL_EXT_swap_control                      = 7;
   cWGL_ARB_multisample                       = 8;
   cWGL_ARB_pixel_format_float                = 9;
   cWGL_ARB_framebuffer_sRGB                  = 10;
   cWGL_ARB_create_context                    = 11;
   cWGL_ARB_create_context_profile            = 12;
   cWGL_EXT_pixel_format_packed_float         = 13;

   wglnExtensions = 14;
   wglExtensions: array[0..wglnExtensions - 1] of oglTExtensionDescriptor = (
      (
         Name: 'WGL_EXT_depth_float';
         Present: false
      ),
      (
         Name: 'WGL_ARB_buffer_region';
         Present: false
      ),
      (
         Name: 'WGL_ARB_extensions_string';
         Present: false
      ),
      (
         Name: 'WGL_ARB_make_current_read';
         Present: false
      ),
      (
         Name: 'WGL_ARB_pixel_format';
         Present: false
      ),
      (
         Name: 'WGL_ARB_pbuffer';
         Present: false
      ),
      (
         Name: 'WGL_EXT_extensions_string';
         Present: false
      ),
      (
         Name: 'WGL_EXT_swap_control';
         Present: false
      ),
      (
         Name: 'WGL_ARB_multisample';
         Present: false
      ),
      (
         Name: 'WGL_ARB_pixel_format_float';
         Present: false
      ),
      (
         Name: 'WGL_ARB_framebuffer_sRGB';
         Present: false
      ),
      (
         Name: 'WGL_ARB_create_context';
         Present: false
      ),
      (
         Name: 'WGL_ARB_create_context_profile';
         Present: false
      ),
      (
         Name: 'WGL_EXT_pixel_format_packed_float';
         Present: false
      )
   );

IMPLEMENTATION

procedure GetExts(i: longint; const ext: string);
var
   id: longint;

begin
   id := oglExtensions.FindDescriptor(wglExtensions, ext);
   if(id > -1) then
      wglExtensions[id].Present := true;

   log.i(sf(i) + ':' + ext);
end;

procedure GetExtensions(wnd: oxTWindow);
var
   exts: pChar;

begin
   if(wglGetExtensionsStringARB <> nil) then begin
      exts := wglGetExtensionsStringARB(winosTWindow(wnd).wd.dc);

      log.Enter('WGL');

      strList.ProcessSpaceSeparated(exts, @GetExts);
      log.Leave();
   end else
      log.w('There seems to be no WGL extensions.');
end;

INITIALIZATION
   oglExtensions.GetPlatformSpecific := @GetExtensions;
   oglExtensions.nPlatformSpecific := wglnExtensions;
   oglExtensions.PlatformSpecific := @wglExtensions[0];

END.
