{
   oxuDefaults, default unit includes for oX
   Copyright (c) 2012. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuDefaults;

INTERFACE

   {$DEFINE OX_PLATFORM_SUPPORT}

   {$IFDEF OX_LIBRARY}
      {$UNDEF OX_PLATFORM_SUPPORT}
   {$ENDIF}

   USES
      uStd,
      {$IFNDEF ANDROID}
      uErrorCrashHandler,
      {$ELSE}
      uAndroidCrashHandler,
      {$ENDIF}
      {%H-}uFiles,
      {$IFDEF ANDROID}
      ulogAndroid,
      {$ENDIF}
      { app }
      appuKeyStateUpdater,
      {$IFNDEF MOBILE}
      appuCtrlBreak,
      {$ENDIF}
      {$IFNDEF OX_LIBRARY}
      appuCrashDetect,
      {$ENDIF}
      appuPaths,
      appuLog,
      {$IFNDEF NODVAR}appudvarConfiguration,{$ENDIF}
      {%H-}oxuSysInfo,

      oxuSerializationTypes,

      {$IFNDEF OX_LIBRARY}
         {image loaders}
         imguBMP, imguJPEG, imguTGA, imguPNM, imguPNG,
         {image writers}
         imguwTGA,
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
         {$ENDIF}
      {$ENDIF}

      {$IFDEF OX_FEATURE_CONTROLLERS}
         {$IF DEFINED(UNIX) AND NOT DEFINED(DARWIN)}
         {%H-}appuControllerLinux,
         {$ENDIF}
         {$IF DEFINED(WINDOWS) AND DEFINED(OX_FEATURE_DX_INPUT)}
         {%H-}appuControllerXInput,
         {%H-}appuControllerDirectInput,
         {$ENDIF}
         {use default controller mappings}
         appuControllerMappings,
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

      {$IFNDEF OX_LIBRARY}
      oxuRendererSettingsRW,
      {$ENDIF}

      oxuProgramConfig,

      { default handlers }
      oxuDefaultFont,
      oxuDefaultTexture,
      {$IFDEF OX_FEATURE_HTML_LOG}
      oxuLogHTML,
      {$ENDIF}
      oxuKeyboardControl,
      oxuPointerControl,
      {$IF NOT DEFINED(OX_LIBRARY) AND NOT DEFINED(MOBILE)}
      oxuScreenshot,
      oxuDefaultSplashScreen,
      {$ENDIF}

      {ui}
      {$IFDEF OX_FEATURE_UI}
      uiuOXHooks,
      uiuDefaultFont,
      wdguTitleButtons,
      uiuHints,
      uiuCursor,
      uiuDockableWindowContextMenu,
      uiuWindowContextMenu,
      uiuSkinLoader,
      uiuCursorRenderer,
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

      {$IF DEFINED(OX_FEATURE_UI) AND DEFINED(OX_FEATURE_CONSOLE)}
      {console, requires UI}
      oxuConsole,
      oxuConsoleLog,
      oxuconAbout,
      oxuconDVar,
      oxuconWindow,
      oxuconKeyMappings,
      oxuconInput,
      oxuconOpenPath,
      {$ENDIF}

      {$IFDEF OX_FEATURE_MODELS}
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
         {$ELSE}
            {$IFNDEF OXED}
            oxunilSceneLoader,
            {$ENDIF}
         {$ENDIF}
         {$IFDEF OX_FEATURE_MODELS}
         oxuModelComponent,
         {$ENDIF}
      {$ENDIF}
      {%H-}uOX,

      {$IF DEFINED(OX_FEATURE_UI) AND DEFINED(OX_FEATURE_UI_WINDOWS)}
      oxuwndSettings,
      oxuwndSettingsVideo,
      oxuwndSettingsAudio,
      oxuwndSettingsInput,
      oxuwndSettingsOther,
         {$IFDEF OX_FEATURE_WND_ABOUT}
         { ui windows }
         oxuwndAbout,
         {$ENDIF}
      {$ENDIF}

      {$IF NOT DEFINED(OX_LIBRARY) AND NOT DEFINED(MOBILE)}
      oxuGlobalHotkeys,
      {$ENDIF}

      {loaders}
      oxuMaterialLoader,
      oxuShaderFileReader,
      oxu9PatchFileReader
      {$IFDEF OX_PACK}
      , oxuPackMounter
      {$ENDIF};

IMPLEMENTATION

INITIALIZATION
   Pass();

END.
