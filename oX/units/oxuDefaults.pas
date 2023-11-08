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
      {$IFDEF ANDROID}
      ulogAndroid,
      {$ENDIF}
      { app }
      appuKeyStateUpdater,
      {$IFNDEF OX_LIBRARY}
      appuCtrlBreak,
      appuCrashDetect,
      {$ENDIF}
      appuPaths,
      appuLog,
      {$IFNDEF NODVAR}appudvarConfiguration,{$ENDIF}
      {$IFNDEF OX_LIBRARY}
         appuSysInfo,
      {$ELSE}
        oxuSysInfo,
      {$ENDIF}

      oxuSerializationTypes,

      {$IFNDEF OX_LIBRARY}
         {image loaders}
         {$INCLUDE ../../components/dimg/units/imgIncludeAllLoaders.inc},
         {image writers}
         {$INCLUDE ../../components/dimg/units/imgIncludeAllWriters.inc},
      {$ELSE}
         {%H-}oxulibImageRW,
      {$ENDIF}

      {$IFDEF OX_PLATFORM_SUPPORT}
         {$IFNDEF OX_LIBRARY}
            { platforms }
            {$IF defined(WINDOWS)}
               {%H-}oxuPlatformWindows,
            {$ELSEIF defined(ANDROID)}
               {%H-}oxuAndroidPlatform,
            {$ELSEIF defined(X11)}
               {%H-}oxuPlatformX11,
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
         {$IF DEFINED(WINDOWS) AND DEFINED(OX_FEATURE_DX)}
         {%H-}appuControllerXInput,
         {%H-}appuControllerDirectInput,
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
      {$IFNDEF OX_LIBRARY}
      oxuDefaultSplashScreen,
      {$ENDIF}

      {ui}
      {$IFDEF OX_FEATURE_UI}
      uiuOXHooks,
      wdguTitleButtons,
      uiuHints,
      uiuCursor,
      uiuDockableWindowContextMenu,
      uiuDefaultFont,
      uiuWindowContextMenu,
      uiuSkinLoader,
      {$ENDIF}

      {$IFDEF OX_FEATURE_PARAMS}
      oxuRendererCmd,
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
      oxuconAbout,
      oxuconDVar,
      oxuconWindow,
      oxuconKeyMappings,
      oxuconInput,
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

      {$IFDEF OX_FEATURE_UI}
      oxuwndSettings,
      oxuwndSettingsVideo,
      oxuwndSettingsAudio,
      oxuwndSettingsInput,
      oxuwndSettingsOther,
      {$ENDIF}

      {loaders}
      oxuMaterialLoader,
      oxuShaderFileReader;

IMPLEMENTATION

INITIALIZATION
   Pass();

END.
