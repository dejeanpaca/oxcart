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

      class procedure Initialize(out t: oxTTime); static;
   end;

   { oxTRenderingTimer }

   oxTRenderingTimer = record
      Interval: TTimerInterval;
      TargetFramerate: loopint;

      class procedure Initialize(out t: oxTRenderingTimer; target_framerate: loopint); static;
      function Elapsed(): boolean;
   end;

   { oxTTimerGlobal }

   oxTTimerGlobal = record
      function Sleep(duration: loopint): boolean;
   end;


VAR
   {base timer used for most oX functionality}
   oxBaseTime,
   {game timer used for the game}
   oxTime: oxTTime;

   {default rendering timer}
   oxRenderingTimer: oxTRenderingTimer;

IMPLEMENTATION

{ oxTTimerGlobal }

function oxTTimerGlobal.Sleep(duration: loopint): boolean;
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
      SysUtils.Sleep(time);
      {$ENDIF}

      Result := true;
   end;
end;

{ oxTRenderingTimer }

class procedure oxTRenderingTimer.Initialize(out t: oxTRenderingTimer; target_framerate: loopint);
begin
   t.TargetFramerate := target_framerate;
   TTimerInterval.Initializef(t.Interval, 1 / target_framerate);
end;

function oxTRenderingTimer.Elapsed(): boolean;
begin
   Result := Interval.Elapsed();
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

INITIALIZATION
   oxTTime.Initialize(oxTime);
   oxTTime.Initialize(oxBaseTime);

   ox.OnRun.Add('ox.tick', @tick);

   oxTRenderingTimer.Initialize(oxRenderingTimer, 60);

END.
