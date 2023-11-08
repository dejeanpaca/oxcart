{
   oxuSplashScreen, splash screen
   Copyright (C) 2017. Dejan Boras

   NOTE: This is just an abstraction. Requires per platform implementation (for platforms that support it).

   Started On:    05.02.2017.
}

{$INCLUDE oxdefines.inc}
UNIT oxuSplashScreen;

INTERFACE

   USES
      uTiming, uStd, uColors, vmVector, StringUtils,
      {oX}
      uOX, oxuTypes, oxuWindowTypes,
      oxuTexture, oxuTextureGenerate, oxuPaths, oxuRenderer, oxuRender, oxuThreadTask,
      oxuMaterial, oxuFont, oxumPrimitive, oxuWindow, oxuTransform, oxuResourcePool, oxuPrimitives,
      oxuRun, oxuRunRoutines,
      {ui}
      oxuUI, uiuWindow;

CONST
   oxSPLASH_SCREEN_DEFAULT_DISPLAY_TIME = 2000;

TYPE
   { oxTSplashScreen }

   oxTSplashScreen = class(oxTThreadTask)
      ClearColor: TColor4f;
      ClearBits: TBitSet;

      {minimum time the splash screen needs to be displayed}
      DisplayTime: longword;
      {associated window}
      AssociatedWindow: oxTWindow;

      {write version to the splash screen}
      WriteVersion: boolean;

      constructor Create; override;
      destructor Destroy; override;

      {start rendering in the current thread, renders a single frame}
      procedure StartSplash(wnd: oxTWindow);
      {load and initialize all required resources}
      procedure Load(); virtual;
      {unload all resources}
      procedure Unload(); virtual;
      {renders the splash screen, with content and overlay}
      procedure Render(); virtual;
      {renders content here}
      procedure RenderContent(); virtual;

      {run rendering in a separate thread, use instead of Start()}
      procedure RunThreaded(wnd: oxTWindow);

      {called to update the splash screen (animate, calculate, and what else, but not render)}
      procedure Update(); virtual;
      {waits until display time passsed}
      procedure WaitForDisplayTime();

      {runs the splash screen task}
      procedure Run(); override;

      procedure TaskStart; override;
      procedure TaskStop; override;

      function GetVersionString(): string; virtual;
   end;

   { oxTBasicSplashScreen }

   oxTBasicSplashScreen = class(oxTSplashScreen)
      {splash screen texture}
      Texture: record
         Path: string;
         Texture: oxTTexture;
      end;

      Quad: oxTPrimitiveModel;

      constructor Create; override;
      procedure Load; override;
      procedure Unload; override;
      procedure RenderContent; override;
   end;

   { oxTDefaultSplashScreen }

   oxTDefaultSplashScreen = class(oxTBasicSplashScreen)
      constructor Create; override;
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

{ oxTBasicSplashScreen }

constructor oxTBasicSplashScreen.Create;
begin
   inherited Create;

   Texture.Path := oxPaths.Textures + 'splash.png';
   oxmPrimitive.Init(Quad);
end;

procedure oxTBasicSplashScreen.Load;
begin
   if(Texture.Path <> '') then begin
      oxTextureGenerate.Generate(oxAssetPaths.Find(Texture.Path), Texture.Texture);

      if(Texture.Texture <> nil) then
         Texture.Texture.MarkUsed();
   end;

   Quad.Quad();
   Quad.Scale(round(AssociatedWindow.Dimensions.w / 2), round(AssociatedWindow.Dimensions.h / 2), 0);
   Quad.Translate(round(AssociatedWindow.Dimensions.w / 2), -round(AssociatedWindow.Dimensions.h / 2), 0);
end;

procedure oxTBasicSplashScreen.Unload;
begin
   oxResource.Destroy(Texture.Texture);
end;

procedure oxTBasicSplashScreen.RenderContent;
var
   m: TMatrix4f;
   f: oxTFont;
   w, h, dots: loopint;
   dotsString: ShortString;

begin
   oxui.Material.Apply();

   if(Texture.Texture <> nil) then begin
      m := oxTransform.Matrix;
      oxTransform.Translate(AssociatedWindow.RPosition.x, AssociatedWindow.RPosition.y, 0);
      oxTransform.Apply();

      oxRender.TextureCoords(QuadTexCoords[0]);
      oxui.Material.ApplyTexture('texture', Texture.Texture);

      Quad.Render();
      oxui.Material.ApplyTexture('texture', nil);
      oxTransform.Apply(m);
   end;

   dots := trunc((timer.Cur() mod 1000) / 250);

   oxui.Material.Apply();
   f := oxf.GetDefault();
   if(f.Valid()) then begin
      f.Start();

      oxui.Material.ApplyColor('color', 1, 1, 1, 1.0);
      oxRender.EnableBlend();

      w := f.GetWidth();
      h := f.GetHeight();

      dotsString := '';
      AddLeadingPadding(dotsString, '.', dots);

      f.Write(AssociatedWindow.Dimensions.w - (f.GetWidth() * 3) {%H-}- round(w * 0.5), round(h * 0.5), dotsString);

      oxf.Stop();
   end;
end;

{ oxTDefaultSplashScreen }

constructor oxTDefaultSplashScreen.Create;
begin
   inherited;

   WriteVersion := true;
end;

{ oxTSplashScreen }

constructor oxTSplashScreen.Create;
begin
   inherited;

   ClearColor := cBlack4f;
   ClearBits := oxrBUFFER_CLEAR_NOTHING;
   DisplayTime := oxSplashScreen.DefaultDisplayTime;
end;

destructor oxTSplashScreen.Destroy;
begin
   Unload();

   inherited Destroy;
end;

procedure oxTSplashScreen.StartSplash(wnd: oxTWindow);
begin
   AssociatedWindow := wnd;

   Load();
end;

procedure oxTSplashScreen.Load;
begin
end;

procedure oxTSplashScreen.Unload;
begin

end;

procedure oxTSplashScreen.Render;
var
   f: oxTFont;
   w, h: loopint;

procedure RenderStuff();
begin
   oxRenderer.ClearColor(ClearColor);
   oxRenderer.Clear(ClearBits);
   uiWindow.RenderPrepare(AssociatedWindow);

   RenderContent();

   if(WriteVersion) then begin
      f := oxf.GetDefault();
      f.Start();

      oxui.Material.ApplyColor('color', 1.0, 1.0, 1.0, 1.0);
      oxRender.EnableBlend();
      w := f.GetWidth();
      h := f.GetHeight();
      f.Write(round(w * 0.5), round(h * 0.5), GetVersionString());

      oxf.Stop();
   end;
end;

procedure SwapBuffers();
begin
   oxTRenderer(AssociatedWindow.Renderer).SwapBuffers(AssociatedWindow);
end;

begin
   oxCurrentMaterial := oxMaterial.Default;
   if(oxCurrentMaterial.Shader = nil) then
      exit;

   if(AssociatedWindow <> nil) then begin
      RenderStuff();
      SwapBuffers();
   end;
end;

procedure oxTSplashScreen.RenderContent;
begin
end;

procedure oxTSplashScreen.RunThreaded(wnd: oxTWindow);
begin
   StartSplash(wnd);

   Start();
end;


procedure oxTSplashScreen.Update;
begin
end;

procedure oxTSplashScreen.WaitForDisplayTime;
begin
   repeat
      oxRun.Sleep();
   until timer.Cur() > (StartTime + DisplayTime);
end;

procedure oxTSplashScreen.Run;
begin
   Update();
   Render();
end;

procedure oxTSplashScreen.TaskStart;
begin
   oxTRenderer(AssociatedWindow.Renderer).StartThread(AssociatedWindow);
end;

procedure oxTSplashScreen.TaskStop;
begin
   oxTRenderer(AssociatedWindow.Renderer).StopThread(AssociatedWindow);

   Unload();
end;

function oxTSplashScreen.GetVersionString: string;
begin
   result := ox.GetVersionString();
end;

procedure splashInitialize();
begin
   if(oxSplashScreen.Startup = nil) then begin
      if(oxSplashScreen.StartupInstance <> nil) then
         oxSplashScreen.Startup := oxSplashScreen.StartupInstance.Create();
   end;

   if(oxSplashScreen.Startup <> nil) then begin
      if(oxSplashScreen.StartupThreaded) then begin
         oxSplashScreen.Startup.StartSplash(oxWindow.Current);
         oxSplashScreen.Startup.Render();
         oxSplashScreen.Startup.Start();
      end else begin
         oxSplashScreen.Startup.StartSplash(oxWindow.Current);
         oxSplashScreen.Startup.Render();
      end;
   end;
end;

procedure splashStart();
begin
   if(oxSplashScreen.Startup <> nil) then begin
      oxSplashScreen.Startup.WaitForDisplayTime();
      oxSplashScreen.Startup.StopWait();

      FreeObject(oxSplashScreen.Startup);
   end;
end;

VAR
   preInitializeRoutine,
   startRoutine: oxTRunRoutine;

INITIALIZATION
   oxSplashScreen.StartupInstance := oxTDefaultSplashScreen;
   oxSplashScreen.DefaultDisplayTime := oxSPLASH_SCREEN_DEFAULT_DISPLAY_TIME;
   {$IFNDEF NO_THREADS}
   oxSplashScreen.StartupThreaded := true;
   {$ENDIF}

   ox.OnPreInitialize.Add(preInitializeRoutine, 'ox.splash_initialize', @splashInitialize);
   ox.OnStart.Add(startRoutine, 'ox.splash_start', @splashStart);
END.
