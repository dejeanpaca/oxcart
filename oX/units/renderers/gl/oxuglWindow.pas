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
      oxuWindowTypes, oxuOGL, oxuglRendererInfo,
      {$IF DEFINED(X11)}GLX, oxuX11Platform
      {$ELSEIF DEFINED(WINDOWS)}oxuWindowsOS
      {$ELSEIF DEFINED(COCOA)}CocoaAll, oxuCocoaPlatform
      {$ELSEIF DEFINED(ANDROID)}oxuAndroidWindow
      {$ENDIF};

TYPE

   {$IFDEF X11}
   {glx attributes array}
   TXAttrIntSimpleList = specialize TSimpleList<XAttrInt>;
   {$ENDIF}

   { oglTWindow }

   oglTWindow = class({$IF DEFINED(WINDOWS)}winosTWindow
         {$ELSEIF DEFINED(X11)}x11TWindow
         {$ELSEIF DEFINED(COCOA)}cocoaTWindow
         {$ELSEIF DEFINED(ANDROID)}androidTWindow
         {$ELSE}
         oxTWindow
         {$ENDIF})
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
   if(oxglRendererInfo.Version.RequiresContextAttribs()) then begin
      RaiseError(eERR, 'gl > gl 3.2+ not supported (WGL_ARB_create_context_profile extension misisng)');
      Result := false;
   end else begin
      oglDefaultVersion.Major := 3;
      oglDefaultVersion.Minor := 1;
      oglDefaultVersion.Profile := oglPROFILE_COMPATIBILITY;

      {downgrade version}
      if(not oxglRendererInfo.Properties.Warned32NotSupported) then begin
         oxglRendererInfo.Properties.Warned32NotSupported := true;
         log.w('gl > gl 3.2+ not supported, will downgrade to ' + oglDefaultVersion.GetString());
      end;
   end;

   Result := true;
end;

END.
