{
   ui x11 platform functionality
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiux11Platform;

INTERFACE

   USES
      uStd,
      uOX, oxuPlatform, oxuPlatforms, oxuRunRoutines,
      oxuX11Platform, uiuPlatform;

TYPE
   { uiTX11PlatformComponent }

   uiTX11PlatformComponent = class(uiTPlatformComponent)
   end;

VAR
  uiX11Platform: uiTX11PlatformComponent;

IMPLEMENTATION

function componentReturn(): TObject;
begin
   Result := uiX11Platform;
end;

procedure init();
begin
   uiX11Platform := uiTX11PlatformComponent.Create();

   x11.Components.RegisterComponent('ui.platform', @componentReturn);
end;

procedure deinit();
begin
   FreeObject(uiX11Platform);
end;

INITIALIZATION
   oxPlatforms.OnComponent.Add('ui.x11.platform', @init, @deinit);

END.
