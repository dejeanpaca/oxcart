{
   uiuUtils, platform specific UI functionality
   Copyright (C) 2019. Dejan Boras

   Started On:    19.06.2019.
}

{$INCLUDE oxdefines.inc}
UNIT uiuPlatform;

INTERFACE

   USES
      uStd;

TYPE
   { uiTPlatformComponent }

   uiTPlatformComponent = class
      {get the name of the system theme}
      function GetSystemTheme(): StdString; virtual;
   end;

IMPLEMENTATION

{ uiTPlatformComponent }

function uiTPlatformComponent.GetSystemTheme(): StdString;
begin
   Result := 'unknown';
end;

END.
