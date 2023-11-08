{
   ui windows platform functionality
   Copyright (C) 2019. Dejan Boras

   Started On:    19.06.2019.
}

{$INCLUDE oxdefines.inc}
UNIT uiuwinPlatform;

INTERFACE

   USES
      windowsutils, windows,
      uStd,
      uOX, oxuPlatform, oxuPlatforms, oxuRunRoutines,
      oxuWindowsPlatform, uiuPlatform;

TYPE
   { uiTWindowsPlatformComponent }

   uiTWindowsPlatformComponent = class(uiTPlatformComponent)
      {get the name of the system theme}
      function GetSystemTheme(): StdString; override;
   end;

VAR
  uiWindowsPlatform: uiTWindowsPlatformComponent;

IMPLEMENTATION

{ uiTWindowsPlatformComponent }

function uiTWindowsPlatformComponent.GetSystemTheme(): StdString;
var
  appsUseLightTheme: windows.DWORD;

begin
   Result := 'unknown';

   if(OutRegistryDWord(HKEY_CURRENT_USER, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize',
      'AppsUseLightTheme', appsUseLightTheme)) then begin
      if(appsUseLightTheme > 0) then
         Result := 'light'
      else
        Result := 'dark';
   end;
end;

function componentReturn(): TObject;
begin
   Result := uiWindowsPlatform;
end;

procedure init();
var
    p: oxTWindowsPlatform;

begin
   uiWindowsPlatform := uiTWindowsPlatformComponent.Create();

   p := oxTWindowsPlatform(oxPlatforms.Find(oxTWindowsPlatform));
   p.Components.RegisterComponent('ui.platform', @componentReturn);
end;

procedure deinit();
begin
   FreeObject(uiWindowsPlatform);
end;

INITIALIZATION
   oxPlatforms.OnComponent.Add('ui.win.platform', @init, @deinit);

END.
