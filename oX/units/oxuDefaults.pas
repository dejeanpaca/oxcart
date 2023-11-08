{
   oxuDefaults, default unit includes for oX
   Copyright (c) 2012. Dejan Boras

   Started On:    14.05.2012.
}

{$INCLUDE oxdefines.inc}
UNIT oxuDefaults;

INTERFACE

   USES
      uStd,
      ufhStandard,
      { app }
      appuKeyStateUpdater,
      appuCtrlBreak,
      appuPaths,
      appuLog,
      {$IFNDEF NODVAR}appudvarConfiguration,{$ENDIF}
      appuSysInfo,
      appuCrashDetect,

      {image loaders}
      {$INCLUDE ../../components/dimg/units/imgIncludeAllLoaders.inc},
      {image writers}
      {$INCLUDE ../../components/dimg/units/imgIncludeAllWriters.inc},

      {$IFDEF OX_PLATFORM_SUPPORT}
         {$IFNDEF OX_LIBRARY}
            { platforms }
            {%H-}oxuPlatform,
            {$IF defined(WINDOWS)}
               {%H-}oxuWindowsPlatform,
            {$ELSEIF defined(ANDROID)}
            {%H-}oxuAndroidPlatform,
            {$ELSEIF defined(X11)}
               {%H-}oxuX11Platform,
            {$ELSEIF defined(COCOA)}
               {%H-}oxuCocoaPlatform,
            {$ENDIF}
         {$ELSE}
            {%H-}oxuOXEDPlatform,
         {$ENDIF}
      {$ENDIF}

      {$IFDEF OX_FEATURE_CONTROLLERS}
         {$IF DEFINED(UNIX) AND NOT DEFINED(DARWIN)}
         {%H-}appuControllerLinux,
         {$ENDIF}
      {$ENDIF}

      { renderers }
      oxuNilRenderer,
      {$IFDEF OX_RENDERER_GL}
      {%H-}oxuRendererGL,
      {$ENDIF}
      {$IFDEF OX_RENDERER_CONSOLE}
      {%H-}oxuRendererConsole,
      {$ENDIF}
      {$IFDEF OX_RENDERER_VULKAN}
      {%H-}oxuRendererVulkan,
      {$ENDIF}
      {$IFDEF OX_RENDERER_DX11}
      {%H-}oxuRendererDX,
      {$ENDIF}

      { default handlers }
      oxuDefaultFont,
      oxuDefaultTexture,
      {$IFDEF OX_FEATURE_HTML_LOG}
      oxuLogHTML,
      {$ENDIF}
      {%H-}oxuclParameters,

      oxuKeyboardControl,
      oxuPointerControl,
      oxuScreenshot,
      oxuDefaultSplashScreen,

      {ui}
      {$IFDEF OX_FEATURE_UI}
      uiuOXHooks,
      wdguTitleButtons,
      uiuHints,
      uiuCursor,
      uiuDockableWindowContextMenu,
      uiuDefaultFont,
      uiuWindowContextMenu,
      {$ENDIF}

      {others}
      {$IFDEF OX_FEATURE_AUDIO}
      oxuAudio,
      oxauWAV,
      {$ENDIF}
      {$IFDEF OX_FEATURE_AL_AUDIO}
      oxuALAudio,
      {$ENDIF}

      {$IFDEF OX_FEATURE_WND_ABOUT}
      { ui windows }
      oxuwndAbout,
      {$ENDIF}

      {$IF DEFINED(OX_FEATURE_UI) AND DEFINED(OX_FEATURE_CONSOLE)}
      {console, requires UI}
      oxuConsole,
      oxuConsoleLog,
      oxuconDVar,
      oxuconWindow,
      oxuconKeyMappings,
      {$ENDIF}

      {$IFDEF OX_FEATURE_MODELS}
      oxum3DS,
      oxumOBJ,
      {$ENDIF}

      {$IFDEF OX_FEATURE_SCENE}
         oxuSceneRender,
         oxuSceneRunner,
         oxuCameraComponent,
         oxuPrimitiveModelComponent,
         {$IFDEF OX_LIBRARY}
         oxulibInputUpdater,
         oxuLibSceneLoader,
         {$ENDIF}
         {$IFDEF OX_FEATURE_MODELS}
         oxuModelComponent,
         {$ENDIF}
      {$ENDIF}
      {%H-}uOX,
      oxuShaderFileReader;

IMPLEMENTATION

INITIALIZATION
   Pass();

END.
