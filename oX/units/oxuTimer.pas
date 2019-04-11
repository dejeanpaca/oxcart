{
   oxuTimer, oX timing
   Copyright (C) 2008. Dejan Boras

   Started On:    07.05.2008.
}

{$INCLUDE oxdefines.inc}
UNIT oxuTimer;

INTERFACE

   USES
      uTiming,
      {ox}
      uOX, oxuRunRoutines;

TYPE
   oxTTime = record
     {should never report time passed greater than this to be reported,
     this is also affected by the time factor}
     MaxTimeFlow: single;

     Timer: TTimer;
     Flow: single;
   end;

VAR
   oxTime: oxTTime;

IMPLEMENTATION

procedure Tick();
var
   maxTime: single;

begin
   {calculate time flow}
   oxTime.Flow := oxTime.Timer.TimeFlow();
   maxTime := oxTime.MaxTimeFlow * oxTime.Timer.Factor;

   {correct time flow}
   {the time flow must not exceed the maximum time flow,
    but only if oxcMaxTimeFlow is not 0.0}
   if(oxTime.MaxTimeFlow <> 0.0) and (oxTime.Flow > maxTime) then
      oxTime.Flow := maxTime;
end;

VAR
   tickRoutine: oxTRunRoutine;

{initializes the main timer}
procedure initTimer();
begin
   oxTime.Timer.InitStart();
   ox.OnRun.Add(tickRoutine, 'ox.tick', @tick);
end;

INITIALIZATION
   oxTime.MaxTimeFlow := 5.0;
   initTimer();

END.
