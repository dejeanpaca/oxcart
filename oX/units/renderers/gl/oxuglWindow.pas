{
   oxuOGL, OpenGL
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuglWindow;

INTERFACE

   USES
      {$INCLUDE usesgl.inc},
      uStd, uLog,
      {ox}
      oxuOGL, oxuglRendererInfo,
      {$IFDEF X11}GLX, oxuX11Platform{$ENDIF}
      {$IFDEF WINDOWS}oxuWindowsOS{$ENDIF}
      {$IFDEF COCOA}CocoaAll, oxuCocoaPlatform{$ENDIF};

TYPE

   {$IFDEF X11}
   {glx attributes array}
   TXAttrIntSimpleList = specialize TSimpleList<XAttrInt>;
   {$ENDIF}

   { oglTWindow }

   oglTWindow = class({$IFDEF WINDOWS}winosTWindow{$ENDIF}{$IFDEF X11}x11TWindow{$ENDIF}{$IFDEF COCOA}cocoaTWindow{$ENDIF})
      gl,
      glDefault,
      glRequired: oglTSettings;

      {$IFDEF X11}
      fbConfig: TGLXFBConfig;
      glxAttribs: TXAttrIntSimpleList;
      {$ENDIF}

      constructor Create(); override;

      function Downgrade32(): boolean;
   end;


VAR
   {OPENGL INFRMATION}
   ogl: oglTGlobal;

IMPLEMENTATION

{ oglTWindow }

constructor oglTWindow.Create();
begin
   inherited;

   {$IFDEF X11}
   glxAttribs.Initialize(glxAttribs);
   {$ENDIF}
end;

function oglTWindow.Downgrade32(): boolean;
begin
   if(glRequired.Version.RequiresContextAttribs()) then begin
      RaiseError(eERR, 'gl > gl 3.2+ not supported (WGL_ARB_create_context_profile extension misisng)');
      Result := false;
   end else begin
      gl.Version.Major := 3;
      gl.Version.Minor := 1;
      gl.Version.Profile := oglPROFILE_COMPATIBILITY;

      {downgrade version}
      if(not oxglRendererInfo.Properties.Warned32NotSupported) then begin
         oxglRendererInfo.Properties.Warned32NotSupported := true;
         log.w('gl > gl 3.2+ not supported, will downgrade to ' + gl.GetString());
      end;
   end;

   Result := true;
end;

END.
