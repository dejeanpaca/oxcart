{
   oxuWindowsConsolePlatform, Windows OS console specific functionality
   Copyright (c) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuWindowsConsolePlatform;

INTERFACE

   USES
      {oX}
      {%H-}oxuPlatforms,
      {windows}
      oxuWindowsPlatformBase;

TYPE
   { oxTWindowsConsolePlatform }

   oxTWindowsConsolePlatform = class(oxTWindowsPlatformBase)
      constructor Create(); override;
   end;

IMPLEMENTATION

{ oxTWindowsConsolePlatform }

constructor oxTWindowsConsolePlatform.Create();
begin
   inherited;

   Name := 'mswinconsole';
end;

INITIALIZATION
   { platform }
   oxPlatforms.Register(oxTWindowsConsolePlatform);

END.
