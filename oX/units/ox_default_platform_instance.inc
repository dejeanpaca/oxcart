{$IF defined(X11)}
   PlatformInstance := oxTX11Platform;
{$ELSEIF defined(WINDOWS)}
   PlatformInstance := oxTWindowsPlatform;
{$ELSEIF defined(COCOA)}
   PlatformInstance := TCocoaPlatform;
{$ELSEIF defined(ANDROID)}
   PlatformInstance := oxTAndroidPlatform;
{$ENDIF}
