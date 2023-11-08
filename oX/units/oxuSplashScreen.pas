{
   oxuSplashScreen, splash screen
   Copyright (C) 2017. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuSplashScreen;

INTERFACE

   USES
      uTiming, uStd, uLog, uColors, vmVector, StringUtils,
      {oX}
      uOX, oxuTypes, oxuWindowTypes,
      oxuRenderer, oxuRender, oxuRenderThread, oxuSurfaceRender, oxuRenderingContext,
      oxuTexture, oxuTextureGenerate, oxuPaths, oxuThreadTask,
      oxuMaterial, oxuFont, oxumPrimitive, oxuWindow, oxuTransform, oxuResourcePool, oxuPrimitives,
      oxuRunRoutines, oxuTimer,
      {ui}
      oxuUI, uiuWindow, uiuWindowRender, uiuDraw;

CONST
   oxSPLASH_SCREEN_DEFAULT_DISPLAY_TIME = 2000;

TYPE
   { oxTSplashScreen }

   oxTSplashScreen = class(oxTThreadTask)
      RC: loopint;

      ClearColor: TColor4f;
      ClearBits: TBitSet;

      {minimum time the splash screen needs to be displayed}
      DisplayTime: longint;
      {associated window}
      AssociatedWindow: oxTWindow;

      Timer,
      RenderingTimer: TTimer;
      TimeFlow: Single;

      constructor Create(); override;
      destructor Destroy(); override;

      {startup splash screen for a window}
      procedure StartSplash(wnd: oxTWindow);
      {load and initialize all required resources}
      procedure Load(); virtual;
      {unload all resources}
      procedure Unload(); virtual;
      {renders the splash screen, with content and overlay}
      procedure Render(); virtual;
      {renders content here}
      procedure RenderContent(var {%H-}context: oxTRenderingContext); virtual;

      {run rendering in a separate thread, use instead of Start()}
      procedure RunThreaded(wnd: oxTWindow);
      {restore rendering context to the associated window}
      procedure RestoreRender();

      {called to update the splash screen (animate, calculate, and what else, but not render)}
      procedure Update(); virtual;
      {waits until display time passsed}
      procedure WaitForDisplayTime();

      {runs the splash screen task}
      procedure Run(); override;

      procedure TaskStart(); override;
      procedure TaskStop(); override;

      procedure ThreadStart(); override;
   end;

   { oxTBasicSplashScreen }

   oxTBasicSplashScreen = class(oxTSplashScreen)
      {write version to the splash screen}
      WriteVersion: boolean;

      {splash screen texture}
      Texture: record
         Path: string;
         Texture: oxTTexture;
      end;

      Quad: oxTPrimitiveModel;

      constructor Create(); override;
      procedure Load(); override;
      procedure Unload(); override;
      procedure RenderContent(var {%H-}context: oxTRenderingContext); override;

      function GetVersionString(): string; virtual;
   end;

   oxTSplashScreenClass = class of oxTSplashScreen;

   oxTSplashScreenGlobal = record
      {default minimum splash display time, in miliseconds (0 means no display time)}
      DefaultDisplayTime: longword;

      Startup: oxTSplashScreen;
      StartupThreaded: boolean;
      StartupInstance: oxTSplashScreenClass;
   end;

VAR
   oxSplashScreen: oxTSplashScreenGlobal;

IMPLEMENTATION

{ oxTSplashScreen }

constructor oxTSplashScreen.Create();
begin
   inherited;

   ClearColor := cBlack4f;
   ClearBits := oxrBUFFER_CLEAR_NOTHING;
   DisplayTime := oxSplashScreen.DefaultDisplayTime;

   Timer.InitStart();
   RenderingTimer.InitStart();

   EmitAllEvents();
end;

destructor oxTSplashScreen.Destroy();
begin
   Unload();

   inherited Destroy;
end;

procedure oxTSplashScreen.StartSplash(wnd: oxTWindow);
begin
   AssociatedWindow := wnd;

   Timer.Start();
   Load();

   RenderingTimer.InitStart();
end;

procedure oxTSplashScreen.Load();
begin
end;

procedure oxTSplashScreen.Unload();
begin

end;

procedure oxTSplashScreen.Render();
begin
   oxCurrentMaterial := oxMaterial.Default;

   if(oxCurrentMaterial.Shader = nil) then
      exit;

   if(AssociatedWindow <> nil) then
      oxSurfaceRender.RenderOnly(AssociatedWindow, @RenderContent);
end;

procedure oxTSplashScreen.RenderContent(var context: oxTRenderingContext);
begin
end;

procedure oxTSplashScreen.RunThreaded(wnd: oxTWindow);
begin
   StartSplash(wnd);

   Start();
   log.v('Started splash screen: ' + Name);
end;

procedure oxTSplashScreen.RestoreRender();
var
   rtc: oxTRenderTargetContext;

begin
   AssociatedWindow.FromWindow(rtc);
   oxTRenderer(AssociatedWindow.Renderer).ContextCurrent(rtc);
end;

procedure oxTSplashScreen.Update();
begin
end;

procedure oxTSplashScreen.WaitForDisplayTime();
begin
   if(DisplayTime > 0) then begin
      Timer.Update();

      while(Timer.Elapsed() < DisplayTime) do begin
         oxTimer.Sleep(1);
         Timer.Update();
      end;
   end;
end;

procedure oxTSplashScreen.Run();
begin
   Update();
   TimeFlow := RenderingTimer.TimeFlow();
   Render();
end;

procedure oxTSplashScreen.TaskStart();
begin
   if(AssociatedWindow <> nil) then begin
      oxRenderThread.StartThread(AssociatedWindow, RC);

      oxRenderer.ClearColor(ClearColor);
   end;
end;

procedure oxTSplashScreen.TaskStop();
begin
   Unload();

   if(AssociatedWindow <> nil) then
      oxRenderThread.StopThread(AssociatedWindow);

   log.v('Ended splash screen: ' + Name);
end;

procedure oxTSplashScreen.ThreadStart();
var
   rtc: oxTRenderTargetContext;
   renderer: oxTRenderer;

begin
   renderer := oxTRenderer(AssociatedWindow.Renderer);

   {get an RC to render the splash screen}
   RC := renderer.GetRenderingContext(AssociatedWindow);

   {mark current context for use only (since we'll render in the splash)}
   AssociatedWindow.FromWindow(rtc);
   rtc.ContextType := oxRENDER_TARGET_CONTEXT_USE;

   renderer.ContextCurrent(rtc);
end;

{ oxTBasicSplashScreen }

constructor oxTBasicSplashScreen.Create();
begin
   inherited Create;

   Texture.Path := oxPaths.Textures + 'splash.png';
   oxmPrimitive.Init(Quad);
end;

procedure oxTBasicSplashScreen.Load();
begin
   if(AssociatedWindow = nil) then
      exit;

   if(Texture.Path <> '') then begin
      Unload();

      oxTextureGenerate.Generate(oxPaths.Find(Texture.Path), Texture.Texture);
   end;

   Quad.Quad();
   Quad.Scale(round(AssociatedWindow.Dimensions.w / 2), round(AssociatedWindow.Dimensions.h / 2), 0);
   Quad.Translate(round(AssociatedWindow.Dimensions.w / 2), -round(AssociatedWindow.Dimensions.h / 2), 0);
end;

procedure oxTBasicSplashScreen.Unload();
begin
   oxResource.Destroy(Texture.Texture);
end;

procedure oxTBasicSplashScreen.RenderContent(var context: oxTRenderingContext);
var
   m: TMatrix4f;
   f: oxTFont;
   w, h, dots: loopint;
   dotsString: ShortString;

begin
   uiWindowRender.Prepare(AssociatedWindow);

   if(Texture.Texture <> nil) then begin
      m := oxTransform.Matrix;
      oxTransform.Translate(AssociatedWindow.RPosition.x, AssociatedWindow.RPosition.y, 0);
      oxTransform.Apply();

      oxRender.TextureCoords(QuadTexCoords[0]);
      uiDraw.Texture(Texture.Texture);

      Quad.Render();

      uiDraw.ClearTexture();
      oxTransform.Apply(m);
   end;

   f := oxui.GetDefaultFont();

   if(f.Valid()) then begin
      f.Start();

      uiDraw.Color(1, 1, 1, 1.0);

      w := f.GetWidth();
      h := f.GetHeight();

      {write version}

      if(WriteVersion) then
         f.Write(round(w * 0.5), round(h * 0.5), GetVersionString());

      dots := trunc((RenderingTimer.Cur() mod 1000) / 250);

      {write dots}

      dotsString := '';
      AddLeadingPadding(dotsString, 'x', dots);

      f.Write(AssociatedWindow.Dimensions.w - round(w * 4), round(h * 0.5), dotsString);

      oxf.Stop();
   end;
end;

function oxTBasicSplashScreen.GetVersionString(): string;
begin
   Result := ox.GetVersionString();
end;

{ INITIALIZATION }

procedure splashInitialize();
begin
   if(oxSplashScreen.Startup = nil) then begin
      if(oxSplashScreen.StartupInstance <> nil) then
         oxSplashScreen.Startup := oxSplashScreen.StartupInstance.Create();
   end;

   if(oxSplashScreen.Startup <> nil) then begin
      oxSplashScreen.Startup.StartSplash(oxWindow.Current);
      oxSplashScreen.Startup.Render();

      if(oxSplashScreen.StartupThreaded) then
         oxSplashScreen.Startup.Start();
   end;
end;

procedure splashStart();
begin
   if(oxSplashScreen.Startup <> nil) then begin
      oxSplashScreen.Startup.WaitForDisplayTime();
      oxSplashScreen.Startup.StopWait();
      oxSplashScreen.Startup.RestoreRender();

      oxThreadEvents.Destroy(oxTThreadTask(oxSplashScreen.Startup));
   end;
end;

INITIALIZATION
   oxSplashScreen.StartupInstance := oxTBasicSplashScreen;
   oxSplashScreen.DefaultDisplayTime := oxSPLASH_SCREEN_DEFAULT_DISPLAY_TIME;

   {$IFNDEF NO_THREADS}
   oxSplashScreen.StartupThreaded := true;
   {$ENDIF}

   ox.OnPreInitialize.Add('ox.splash_initialize', @splashInitialize);
   ox.OnStart.Add('ox.splash_start', @splashStart);

END.
