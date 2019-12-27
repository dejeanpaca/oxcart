{
   uTiming, timing operations, timers & timing utilities
   Copyright (C) 2011. Dejan Boras

   Started On:    28.01.2011.

   TODO: Implement interval logic
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}{$MODESWITCH TYPEHELPERS}
UNIT uTiming;

INTERFACE

   USES SysUtils, StringUtils, uStd;

TYPE
   {contains the start of timing, elapsed time, and the goal time}
   PTimer = ^TTimer;

   { TTimer }

   TTimer = record
      StartTime,
      CurrentTime,
      ElapsedTime: longint;
      ElapsedTimef: single;

      GoalTime,
      Add: longint; {added time}

      Iterations: longint;
      Factor: single;
      FactorInt: longint;

      {pausing}
      Paused: boolean;
      PausedTime: longint;

      {a linked timer}
      TimerLink: PTimer;

      {initialize a timer record}
      class procedure Init(out timer: TTimer); static;

      procedure Init();
      procedure InitStart();
      {start the timer}
      function Cur(): longint;
      procedure Start();
      procedure StartOffset(ofs: longint);
      procedure StartOffsetf(ofs: single);
      {update the timer}
      procedure Update();
      {set the goal}
      procedure SetGoal(ms: longint);
      {set the time factor}
      procedure SetFactor(newFactor: longint);
      procedure SetFactor(newFactor: single);
      {get elapsed time in milliseconds}
      function Elapsed(): longint;
      {get elapsed time in seconds, as a floating point}
      function Elapsedf(): single;
      {get elapsed time as a string}
      function ElapsedfToString(decimals: longint = 2): string;
      {did we hit the goal}
      function Goal(): boolean;
      {increment iteration count}
      procedure Inc();
      {return the time flow}
      function TimeFlow(): single;

      procedure Pause();
      procedure Resume();

      {link specified timer to self}
      procedure Link(var withTimer: TTimer);

      { HELPERS }

      {gets a random time interval (floating point) between minTime and maxTime}
      class function GetRandomIntervalf(const minTime, maxTime: single): Single; static;
      {get elapsed time between two timedates}
      class function Elapsed(const t1, t2: TDateTime): longint; static;
      {get elapsed time between two timedates as a float}
      class function Elapsedf(const t1, t2: TDateTime): single; static;
   end;

   { TDateTimeHelper }

   TDateTimeHelper = type helper for TDateTime
      function ModuleTime(base: longint): longint;
      function ModuleTimef(base: single): single;

      function Elapsed(): longint;
      function Elapsedf(): single;
      function ElapsedfToString(decimals: longint = 2): string;

      function MatchingDay(const other: TDateTime): boolean;
   end;

   { TTimerInterval }

   TTimerInterval = record
      Interval: longint;
      Timer: TTimer;

      class procedure Initialize(out t: TTimerInterval; setInterval: longint = 1000); static;
      procedure Start(setInterval: longint = 1000);
      function Elapsed(): boolean;
   end;

   {note: goal and elapsed time is relative of start time}

CONST
	cZeroTimer: TTimer = (
      StartTime:        0;
      CurrentTime:      0;
      ElapsedTime:      0;
      ElapsedTimef:     0;
      GoalTime:         0;
      Add:              0;
      Iterations:       0;
      Factor:           1.0;
      FactorInt:        1;
      Paused:           false;
      PausedTime:       0;
      TimerLink:        nil
   );

VAR
   timer: TTimer;

IMPLEMENTATION

{ TDateTimeHelper }

function TDateTimeHelper.ModuleTime(base: longint): longint;
begin
   Result := (DateTimeToTimestamp(Self).Time mod base);
end;

function TDateTimeHelper.ModuleTimef(base: single): single;
begin
   Result := (DateTimeToTimestamp(Self).Time mod round(base * 1000)) / 1000;
end;

function TDateTimeHelper.Elapsed(): longint;
var
   ts,
   currentTime: longint;

begin
   ts := DateTimeToTimestamp(Self).time;
   currentTime := DateTimeToTimestamp(Time).time;

   Result := (currentTime - ts);
end;

function TDateTimeHelper.Elapsedf(): single;
var
   ts,
   currentTime: longint;

begin
   ts := DateTimeToTimestamp(Self).time;
   currentTime := DateTimeToTimestamp(Time).time;

   Result := (currentTime - ts) / 1000;
end;

function TDateTimeHelper.ElapsedfToString(decimals: longint = 2): string;
begin
   Result := sf(Elapsedf(), decimals);
end;

function TDateTimeHelper.MatchingDay(const other: TDateTime): boolean;
var
   y, m, d,
   oy, om, od: word;

begin
   DecodeDate(Self, y, m, d);
   DecodeDate(other, oy, om, od);

   Result := (y = oy) and (m = om) and (d = od);
end;

class procedure TTimer.Init(out timer: TTimer);
begin
   timer := cZeroTimer;
end;

procedure TTimer.Init();
begin
	self := cZeroTimer;
end;

procedure TTimer.InitStart();
begin
   Init();
   Start();
end;

function TTimer.Cur(): longint;
begin
   if(TimerLink = nil) then
      Result := DateTimeToTimestamp(Time).time
   else
      Result := TimerLink^.Elapsed();
end;

procedure TTimer.Start();
begin
   StartTime      := Cur();
   CurrentTime    := StartTime;
   ElapsedTime    := 0;
   ElapsedTimef   := 0.0;
   Add            := 0;
   Paused         := false;
end;

procedure TTimer.StartOffset(ofs: longint);
begin
   {%H-}system.inc(StartTime, ofs);
end;

procedure TTimer.StartOffsetf(ofs: single);
begin
   StartOffset(round(ofs * 1000));
end;

procedure TTimer.Update();
begin
   if(not Paused) then begin
      CurrentTime    := Cur();
      ElapsedTime    := (CurrentTime - StartTime + Add) * FactorInt;
      ElapsedTimef   := ((CurrentTime - StartTime + Add) / 1000) * Factor;
   end;
end;

procedure TTimer.SetGoal(ms: longint);
begin
   GoalTime := ms;
end;

procedure TTimer.SetFactor(newFactor: longint);
begin
   Factor      := newFactor;
   FactorInt   := newFactor;
end;

procedure TTimer.SetFactor(newFactor: single);
begin
   Factor      := newFactor;
   FactorInt   := round(newFactor);
end;

function TTimer.Elapsed(): longint;
begin
   Result := ElapsedTime;
end;

function TTimer.Elapsedf(): single;
begin
   Result := ElapsedTimef;
end;

function TTimer.ElapsedfToString(decimals: longint): string;
begin
   Result := sf(ElapsedTimef, decimals);
end;

function TTimer.Goal(): boolean;
var
   current: longint;

begin
   current  := Cur();
   Result   := (current - ElapsedTime + Add) > GoalTime;
end;


procedure TTimer.Inc();
begin
   system.inc(Iterations);
end;

{return the time flow}
function TTimer.TimeFlow(): single;
begin
   Update();
   Result := ElapsedTimef * Factor;
   Start();
end;


procedure TTimer.Pause();
begin
   if(not Paused) then begin
      Paused      := true;
      PausedTime  := Cur();
   end;
end;

procedure TTimer.Resume();
begin
   if(Paused) then begin
      Add         := Add + (PausedTime - StartTime);
      ElapsedTime := 0;
      StartTime   := Cur();
      Paused      := false;
   end;
end;

procedure TTimer.Link(var withTimer: TTimer);
begin
   withTimer.TimerLink := @withTimer;
end;

{ GENERAL }

class function TTimer.GetRandomIntervalf(const minTime, maxTime: single): Single;
begin
   Result := minTime + (random() * (maxTime - minTime));
end;

class function TTimer.Elapsed(const t1, t2: TDateTime): longint;
begin
   Result := DateTimeToTimestamp(t2).Time - DateTimeToTimestamp(t1).Time;
end;

class function TTimer.Elapsedf(const t1, t2: TDateTime): single;
begin
   Result := (DateTimeToTimestamp(t2).Time - DateTimeToTimestamp(t1).Time) / 1000;
end;

{ TTimerInterval }

class procedure TTimerInterval.Initialize(out t: TTimerInterval; setInterval: longint);
begin
   ZeroPtr(@t, SizeOf(t));

   t.Timer.Init();

   t.Start(setInterval);
end;

procedure TTimerInterval.Start(setInterval: longint);
begin
   Timer.Start();

   Interval := setInterval;
end;

function TTimerInterval.Elapsed(): boolean;
var
   elapsedTime,
   intervalOffset: longint;

begin
   Timer.Update();

   elapsedTime := Timer.Elapsed();

   if(elapsedTime >= Interval) then begin
      intervalOffset := elapsedTime - Interval;

      Timer.Start();

      if(intervalOffset > 0) then
         Timer.StartOffset(-intervalOffset);

      exit(true);
   end;

   Result := false;
end;

INITIALIZATION
   {setup the default timer}
   TTimer.Init(timer);

END.
