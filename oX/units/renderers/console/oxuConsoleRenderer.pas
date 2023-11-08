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

      function SetupWindow(wnd: oxTWindow): boolean; override;
      function DeInitWindow({%H-}wnd: oxTWindow): boolean; override;

      procedure SwapBuffers({%H-}wnd: oxTWindow); override;
      procedure Clear({%H-}clearBits: longword); override;
  end;
   
VAR
   oxConsoleRenderer: oxTConsoleRenderer;

IMPLEMENTATION

{ oxglTRenderer }

constructor oxTConsoleRenderer.Create();
begin
   inherited;

   Id := 'console';
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

function oxTConsoleRenderer.SetupWindow(wnd: oxTWindow): boolean;
begin
   Result := tvGlobal.Initialize();

   if(Result) then begin
      {we can't use console log in video mode}
      consoleLog.Close();
   end else
      exit(False);

   tvGlobal.LogModes();

   if(tvGlobal.ModeCount > 0) then begin
      wnd.Dimensions.w := tvGlobal.Mode.Col;
      wnd.Dimensions.h := tvGlobal.Mode.Row;
   end;

   tvCurrent.ClearScreen();
   tvCurrent.Update();
end;

function oxTConsoleRenderer.DeInitWindow(wnd: oxTWindow): boolean;
begin
   tvGlobal.Deinitialize();
   Result := true;
end;

procedure oxTConsoleRenderer.SwapBuffers(wnd: oxTWindow);
begin
   tvCurrent.Update();
end;

procedure oxTConsoleRenderer.Clear(clearBits: longword);
begin
   tvCurrent.Clear();
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
   ox.PreInit.Add('rendere.console', @init, @deinit);

END.
