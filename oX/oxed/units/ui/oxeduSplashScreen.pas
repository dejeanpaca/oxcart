{
   oxeduSplashScreen
   Copyright (C) 2017. Dejan Boras

   Started On:    07.01.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxeduSplashScreen;

INTERFACE

   USES
      uOX, oxuSplashScreen, oxuPaths;

TYPE

   { oxedTSplashScreen }

   oxedTSplashScreen = class(oxTBasicSplashScreen)
      constructor Create; override;
      function GetVersionString: string; override;
   end;

IMPLEMENTATION

{ oxedTSplashScreen }

constructor oxedTSplashScreen.Create;
begin
   inherited Create;

   WriteVersion := true;
   Texture.Path := oxPaths.Data + 'splash.png';
   DisplayTime := 0;
end;

function oxedTSplashScreen.GetVersionString: string;
begin
   Result := 'OXED ' + ox.GetVersionString(oxVERSION_STR_ONLY);
end;

INITIALIZATION
   oxSplashScreen.StartupInstance := oxedTSplashScreen;

END.
