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
   oxTime: oxTTime;

IMPLEMENTATION

procedure oxTTime.Pause();
begin
   if(not Timer.Paused) then begin
      Timer.Pause();
   end;
end;

procedure oxTTime.Resume();
begin
   if(Timer.Paused) then begin
      Timer.Resume();
   end;
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
      oxTime.Flow := oxTime.Timer.TimeFlow();
      maxTime := oxTime.MaxTimeFlow * oxTime.Timer.Factor;

      {correct time flow}
      {the time flow must not exceed the maximum time flow,
       but only if oxcMaxTimeFlow is not 0.0}
      if(oxTime.MaxTimeFlow <> 0.0) and (oxTime.Flow > maxTime) then
         oxTime.Flow := maxTime;
   end else
      oxTime.Flow := 0;
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
   oxTime.Tick();
end;

VAR
   tickRoutine: oxTRunRoutine;

INITIALIZATION
   oxTTime.Initialize(oxTime);

   ox.OnRun.Add(tickRoutine, 'ox.tick', @tick);

END.
