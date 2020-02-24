{
   oxuUnixConsolePlatform, unix OS console specific functionality
   Copyright (c) 2018. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuUnixConsolePlatform;

INTERFACE

   USES
      {oX}
      {%H-}oxuPlatform, oxuPlatforms, oxuWindowTypes, oxuRenderer,
      {ui}
      uiuWindow;

TYPE
   { oxTUnixConsolePlatform }

   oxTUnixConsolePlatform = class(oxTPlatform)
      constructor Create(); override;

      function MakeWindow(wnd: oxTWindow): boolean; override;
      function DestroyWindow(wnd: oxTWindow): boolean; override;
   end;

IMPLEMENTATION

{ oxTUnixConsolePlatform }

constructor oxTUnixConsolePlatform.Create();
begin
   inherited;

   Name := 'unixconsole';
end;

function oxTUnixConsolePlatform.MakeWindow(wnd: oxTWindow): boolean;
begin
   Result := oxTRenderer(wnd.Renderer).InitWindow(wnd);
end;

function oxTUnixConsolePlatform.DestroyWindow(wnd: oxTWindow): boolean;
begin
   Result := oxTRenderer(wnd.Renderer).DeInitWindow(wnd);
end;

INITIALIZATION
   { platform }
   oxPlatforms.Register(oxTUnixConsolePlatform);

END.
