   {$If defined(X11)}
   PlatformInstance := oxTX11Platform;
   {$ElseIf defined(WINDOWS)}
   PlatformInstance := oxTWindowsPlatform;
   {$ElseIf defined(COCOA)}
   PlatformInstance := TCocoaPlatform;
   {$EndIf}
