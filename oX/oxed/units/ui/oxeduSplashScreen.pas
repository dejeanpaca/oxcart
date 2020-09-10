{
   oxeduSplashScreen
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxeduSplashScreen;

INTERFACE

   USES
      uOX, oxuSplashScreen, oxuDefaultSplashScreen, oxuPaths;

TYPE

   { oxedTSplashScreen }

   oxedTSplashScreen = class(oxTDefaultSplashScreen)
      constructor Create(); override;

      function GetVersionString(): string; override;
   end;

IMPLEMENTATION

{ oxedTSplashScreen }

constructor oxedTSplashScreen.Create();
begin
   inherited Create;

   WriteVersion := true;
   Texture.Path := '';
   DisplayTime := 0;
end;

function oxedTSplashScreen.GetVersionString(): string;
begin
   Result := 'OXED ' + ox.GetVersionString(oxVERSION_STR_ONLY);
end;

INITIALIZATION
   oxSplashScreen.StartupInstance := oxedTSplashScreen;

END.
