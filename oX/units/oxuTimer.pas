{
   oxuTimer, oX timing
   Copyright (C) 2008. Dejan Boras

   Started On:    07.05.2008.
}

{$INCLUDE oxdefines.inc}
UNIT oxuTimer;

INTERFACE

   USES
      uStd, uTiming,
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

VAR
   {base timer used for most oX functionality}
   oxBaseTime,
   {game timer used for the game}
   oxTime: oxTTime;

IMPLEMENTATION

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

END.
