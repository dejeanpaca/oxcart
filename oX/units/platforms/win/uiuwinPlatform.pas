{
   ui windows platform functionality
   Copyright (C) 2019. Dejan Boras

   Started On:    19.06.2019.
}

{$INCLUDE oxdefines.inc}
UNIT uiuwinPlatform;

INTERFACE

   USES
      uStd,
      uOX, oxuPlatform, oxuPlatforms, oxuRunRoutines,
      oxuWindowsPlatform, uiuPlatform;

TYPE
   { uiTWindowsPlatformComponent }

   uiTWindowsPlatformComponent = class(uiTPlatformComponent)
      {Check if the system is currently using a dark theme.
      Returns 0 for no, 1 for yes, and -1 if unknown}
      function IsSystemDarkTheme(): loopint; override;
      {get the name of the system theme}
      function GetSystemTheme(): StdString; override;
   end;

VAR
  uiWindowsPlatform: uiTWindowsPlatformComponent;

IMPLEMENTATION

{ uiTWindowsPlatformComponent }

function uiTWindowsPlatformComponent.IsSystemDarkTheme(): loopint;
begin
   Result := -1;
end;

function uiTWindowsPlatformComponent.GetSystemTheme(): StdString;
begin
   Result := 'unknown';
end;

function componentReturn(): TObject;
begin
   Result := uiWindowsPlatform;
end;

VAR
   initRoutines: oxTRunRoutine;

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
   oxPlatforms.OnComponent.Add(initRoutines, 'ui.win.platform', @init, @deinit);

END.
