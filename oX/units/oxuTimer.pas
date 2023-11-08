{
   oxuTimer, oX timing
   Copyright (C) 2008. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuTimer;

INTERFACE

   USES
      {$IFDEF WINDOWS}
      MMSystem,
      {$ENDIF}
      sysutils, uApp, uStd, uTiming,
      {ox}
      uOX, oxuRunRoutines;

TYPE

   { oxTTime }

   oxTTime = record
      {should never report time passed greater than this to be reported,
      this is also affected by the time factor}
      MaxTimeFlow: single;

      Timer: TTimer;
      Flow: single;

      procedure Pause();
      procedure Resume();
      procedure TogglePause();
      procedure Tick();
      function Paused(): boolean;
      {reset the timer to behave as it just started}
      procedure Reset();

      class procedure Initialize(out t: oxTTime); static;
   end;

   { oxTRenderingTimer }

   oxTRenderingTimer = record
      Interval: TTimerInterval;
      TargetFramerate: loopint;

      class procedure Initialize(out t: oxTRenderingTimer; target_framerate: loopint); static;
      function Elapsed(): boolean;

      {reset the timer to behave as it just started}
      procedure Reset();
   end;

   { oxTTimerGlobal }

   oxTTimerGlobal = record
      class function Sleep(duration: loopint = -1): boolean; static;
      class function SloppySleep(duration: loopint = -1): boolean; static;
   end;

VAR
   oxTimer: oxTTimerGlobal;

   {base timer used for most oX functionality}
   oxBaseTime,
   {game timer used for the game}
   oxTime: oxTTime;

   {default rendering timer}
   oxRenderingTimer: oxTRenderingTimer;

IMPLEMENTATION

{ oxTTimerGlobal }

class function oxTTimerGlobal.Sleep(duration: loopint): boolean;
begin
   Result := false;

   if(duration = -1) then
      duration := app.IdleTime;

   if(duration > 0) then begin
      {$IFDEF WINDOWS}
      MMSystem.timeBeginPeriod(1);
      SysUtils.Sleep(duration);
      MMSystem.timeEndPeriod(1);
      {$ELSE}
      SysUtils.Sleep(duration);
      {$ENDIF}

      Result := true;
   end;
end;

class function oxTTimerGlobal.SloppySleep(duration: loopint): boolean;
begin
   Result := false;

   if(duration = -1) then
      duration := app.IdleTime;

   if(duration > 0) then begin
      SysUtils.Sleep(duration);
      Result := true;
   end;
end;

{ oxTRenderingTimer }

class procedure oxTRenderingTimer.Initialize(out t: oxTRenderingTimer; target_framerate: loopint);
begin
   t.TargetFramerate := target_framerate;

   if(target_framerate > 0) then
      TTimerInterval.Initializef(t.Interval, 1 / target_framerate)
   else begin
      TTimerInterval.Initializef(t.Interval, 1 / 60);
      t.TargetFramerate := 0;
   end;
end;

function oxTRenderingTimer.Elapsed(): boolean;
begin
   if(TargetFramerate > 0) then
      Result := Interval.Elapsed()
   else
      Result := true;
end;

procedure oxTRenderingTimer.Reset();
begin
   Interval.Reset();
end;

{ oxTTime }

procedure oxTTime.Pause();
begin
   if(not Timer.Paused) then
      Timer.Pause();
end;

procedure oxTTime.Resume();
begin
   if(Timer.Paused) then
      Timer.Resume();
end;

procedure oxTTime.TogglePause();
begin
   if(not Timer.Paused) then
      Pause()
   else
      Resume();
end;

procedure oxTTime.Tick();
var
   maxTime: single;

begin
   if(not Timer.Paused) then begin
      {calculate time flow}
      Flow := Timer.TimeFlow();
      maxTime := MaxTimeFlow * Timer.Factor;

      {correct time flow}
      {the time flow must not exceed the maximum time flow,
       but only if oxcMaxTimeFlow is not 0.0}
      if(MaxTimeFlow <> 0.0) and (Flow > maxTime) then
         Flow := maxTime;
   end else
      Flow := 0;
end;

function oxTTime.Paused(): boolean;
begin
   Result := Timer.Paused;
end;

procedure oxTTime.Reset();
begin
   Flow := 0;
   Timer.Start();
end;

class procedure oxTTime.Initialize(out t: oxTTime);
begin
   ZeroPtr(@t, SizeOf(t));

   t.MaxTimeFlow := 5.0;
   t.Timer.InitStart();
end;

procedure tick();
begin
   oxBaseTime.Tick();
   oxTime.Tick();
end;

procedure startTimer();
begin
   oxBaseTime.Reset();
   oxTime.Reset();
   oxRenderingTimer.Interval.Reset();
end;

INITIALIZATION
   oxTTime.Initialize(oxTime);
   oxTTime.Initialize(oxBaseTime);

   ox.OnRun.Add('ox.tick', @tick);
   ox.OnStart.Add('ox.timer.start', @startTimer);

   {$IFNDEF OX_LIBRARY}
   oxTRenderingTimer.Initialize(oxRenderingTimer, 60);
   {$ELSE}
   {in library mode, our rendering timing is dictated by the host}
   oxTRenderingTimer.Initialize(oxRenderingTimer, 0);
   {$ENDIF}

END.
