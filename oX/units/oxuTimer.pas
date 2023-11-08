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
      uOX;

CONST
   {should never report time passed greater than this to be reported,
   this is also affected by the time factor}
   oxcMaxTimeFlow: single = 5.0;

VAR
   oxMainTimer: TTimerData;
   oxMainTimeFlow: single;

IMPLEMENTATION

procedure Tick();
var
   maxTime: single;

begin
   {calculate time flow}
   oxMainTimeFlow    := oxMainTimer.TimeFlow();
   maxTime           := oxcMaxTimeFlow * oxMainTimer.Factor;

   {correct time flow}
   {the time flow must not exceed the maximum time flow,
    but only if oxcMaxTimeFlow is not 0.0}
   if(oxcMaxTimeFlow <> 0.0) and (oxMainTimeFlow > maxTime)
      then oxMainTimeFlow := maxTime;
end;

{initializes the main timer}
procedure initTimer();
begin
   oxMainTimer.InitStart();
   ox.OnRun.Add(@Tick);
end;

INITIALIZATION
   initTimer();
END.
