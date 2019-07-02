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
      {Check if the system is currently using a dark theme.
      Returns 0 for no, 1 for yes, and -1 if unknown}
      function IsSystemDarkTheme(): loopint; virtual;
      {get the name of the system theme}
      function GetSystemTheme(): StdString; virtual;
   end;

IMPLEMENTATION

{ uiTPlatformComponent }

function uiTPlatformComponent.IsSystemDarkTheme(): loopint;
begin
   Result := -1;
end;

function uiTPlatformComponent.GetSystemTheme(): StdString;
begin
   Result := 'unknown';
end;

END.
