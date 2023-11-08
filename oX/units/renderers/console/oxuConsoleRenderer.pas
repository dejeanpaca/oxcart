{
   oxuConsoleRenderer, oX console renderer base
   Copyright (C) 2016. Dejan Boras
}

{$INCLUDE oxdefines.inc}

{$IFNDEF OX_RENDERER_CONSOLE}
   {$FATAL Included console renderer, with no OX_RENDERER_CONSOLE defined}
{$ENDIF}

UNIT oxuConsoleRenderer;

INTERFACE

   USES
      uStd, uImage, uTVideo, uLog, Video,
      {ox}
      uOX,
      oxuWindowTypes, oxuRenderer, oxuRenderers, oxuPlatform
      {$IFDEF WINDOWS}
      , oxuWindowsConsolePlatform
      {$ENDIF}
      {$IFDEF UNIX}
      , oxuUnixConsolePlatform
      {$ENDIF};

TYPE
   { oxTConsoleRenderer }

   oxTConsoleRenderer = class (oxTRenderer)
      constructor Create(); override;

      procedure OnInitialize(); override;

      procedure SetupData(wnd: oxTWindow); override;
      function SetupWindow(wnd: oxTWindow): boolean; override;
      function PreInitWindow(wnd: oxTWindow): boolean; override;
      function InitWindow(wnd: oxTWindow): boolean; override;
      function DeInitWindow(wnd: oxTWindow): boolean; override;

      procedure SwapBuffers(wnd: oxTWindow); override;
      procedure Clear(clearBits: longword); override;
  end;
   
VAR
   oxConsoleRenderer: oxTConsoleRenderer;

IMPLEMENTATION

{ oxglTRenderer }

constructor oxTConsoleRenderer.Create();
begin
   inherited;

   Id := 'renderer.console';
   Name := 'Console';

   PlatformInstance := oxTPlatform;
   {$IFDEF WINDOWS}
   PlatformInstance := oxTWindowsConsolePlatform;
   {$ENDIF}
   {$IFDEF UNIX}
   PlatformInstance := oxTUnixConsolePlatform;
   {$ENDIF}

   WindowSettings.DepthBits := 0;
   WindowSettings.ColorBits := 8;
end;

procedure oxTConsoleRenderer.OnInitialize();
begin
end;

procedure oxTConsoleRenderer.SetupData(wnd: oxTWindow);
begin
   inherited SetupData(wnd);

   tvGlobal.Initialize();

   tvGlobal.LogDC();
   tvGlobal.LogModes();

   if(tvGlobal.ModeCount > 0) then begin
      wnd.Dimensions.w := tvGlobal.Mode.Col;
      wnd.Dimensions.h := tvGlobal.Mode.Row;
   end;
end;

function oxTConsoleRenderer.SetupWindow(wnd: oxTWindow): boolean;
begin
   Result := true;
end;

function oxTConsoleRenderer.PreInitWindow(wnd: oxTWindow): boolean;
begin
   Result:=inherited PreInitWindow(wnd);
end;

function oxTConsoleRenderer.InitWindow(wnd: oxTWindow): boolean;
begin
   Result := true;
end;

function oxTConsoleRenderer.DeInitWindow(wnd: oxTWindow): boolean;
begin
   Result := true;
end;

procedure oxTConsoleRenderer.SwapBuffers(wnd: oxTWindow);
begin
   Video.UpdateScreen(false);
end;

procedure oxTConsoleRenderer.Clear(clearBits: longword);
begin
end;

procedure init();
begin
   oxConsoleRenderer := oxTConsoleRenderer.Create();

   oxRenderers.Register(oxConsoleRenderer);
end;

procedure deinit();
begin
   FreeObject(oxConsoleRenderer);
end;

INITIALIZATION
   ox.PreInit.Add('ox.con.renderer', @init, @deinit);

END.
