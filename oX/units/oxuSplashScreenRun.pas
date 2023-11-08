{
   oxuSplashScreenRun, runs the splash screen
   Copyright (C) 2021. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuSplashScreenRun;

INTERFACE

   USES
      {oX}
      uOX, oxuThreadTask,
      oxuWindow, oxuSplashScreen;

CONST
   oxSPLASH_SCREEN_DEFAULT_DISPLAY_TIME = 2000;

TYPE
   oxTSplashScreenRun = record
      {should the splash screen run on the main thread}
      RunOnMainThread: boolean;

      Startup: oxTSplashScreen;
      {run in a thread}
      StartupThreaded: boolean;
      StartupInstance: oxTSplashScreenClass;
   end;

VAR
   oxSplashScreen: oxTSplashScreenRun;

IMPLEMENTATION

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

      {start in thread if indicated to do so}
      if(oxSplashScreen.StartupThreaded) and (not oxSplashScreen.RunOnMainThread) then
         oxSplashScreen.Startup.Start();
   end;
end;

procedure splashDone();
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
   oxTSplashScreen.DefaultDisplayTime := oxSPLASH_SCREEN_DEFAULT_DISPLAY_TIME;

   {$IFNDEF NO_THREADS}
   oxSplashScreen.StartupThreaded := true;
   oxSplashScreen.RunOnMainThread := true;
   {$ENDIF}

   ox.OnPreInitialize.Add('ox.splash_initialize', @splashInitialize);
   ox.OnStart.Add('ox.splash_start', @splashDone);
   ox.OnInitialize.dAdd('ox.splash_deinitialize', @splashDone);

END.
