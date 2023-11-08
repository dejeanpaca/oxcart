{
   uTiming, timing operations, timers & timing utilities
   Copyright (C) 2011. Dejan Boras

   Started On:    28.01.2011.
}

{$MODE OBJFPC}{$H+}{$MODESWITCH ADVANCEDRECORDS}{$MODESWITCH TYPEHELPERS}
UNIT uTiming;

INTERFACE

   USES SysUtils, StringUtils;

TYPE
   {contains the start of timing, elapsed time, and the goal time}
   PTimerData = ^TTimerData;

   { TTimerData }

   TTimerData = record
      startTime,
      currentTime,
      elapsedTime: longint;
      elapsedTimef: single;

      goalTime,
      add: longint; {added time}

      iterations: longint;
      factor: single;
      factorint: longint;

      {pausing}
      paused: boolean;
      pausedTime: longint;

      {a linked timer}
      timerLink: PTimerData;

      {initialize a timer record}
      class procedure Init(out timer: TTimerData); static;

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
      {did we hit the goal}
      function Goal(): boolean;
      {increment iteration count}
      procedure Inc();
      {return the time flow}
      function TimeFlow(): single;

      procedure Pause();
      procedure Resume();

      {link specified timer to self}
      procedure Link(var withTimer: TTimerData);

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
      function Elapsed(): longint;
      function Elapsedf(): single;
      function ElapsedfToString(decimals: longint = 2): string;

      function MatchingDay(const other: TDateTime): boolean;
   end;

   {note: goal and elapsed time is relative of start time}

CONST
	cZeroTimer: TTimerData = (
      startTime:        0;
      currentTime:      0;
      elapsedTime:      0;
      elapsedTimef:     0;
      goalTime:         0;
      add:              0;
      iterations:       0;
      factor:           1.0;
      factorint:        1;
      paused:           false;
      pausedTime:       0;
      timerLink:        nil
   );

VAR
   timer: TTimerData;

IMPLEMENTATION

{ TDateTimeHelper }

function TDateTimeHelper.Elapsed(): longint;
var
   ts,
   currentTime: longint;

begin
   ts := DateTimeToTimestamp(Self).time;
   currentTime := DateTimeToTimestamp(Time).time;

   result := (currentTime - ts);
end;

function TDateTimeHelper.Elapsedf(): single;
var
   ts,
   currentTime: longint;

begin
   ts := DateTimeToTimestamp(Self).time;
   currentTime := DateTimeToTimestamp(Time).time;

   result := (currentTime - ts) / 1000;
end;

function TDateTimeHelper.ElapsedfToString(decimals: longint = 2): string;
begin
   result := sf(Elapsedf(), decimals);
end;

function TDateTimeHelper.MatchingDay(const other: TDateTime): boolean;
var
   y, m, d,
   oy, om, od: word;

begin
   DecodeDate(Self, y, m, d);
   DecodeDate(other, oy, om, od);

   result := (y = oy) and (m = om) and (d = od);
end;

class procedure TTimerData.Init(out timer: TTimerData);
begin
   timer := cZeroTimer;
end;

procedure TTimerData.Init();
begin
	self := cZeroTimer;
end;

procedure TTimerData.InitStart();
begin
   Init();
   Start();
end;

function TTimerData.Cur(): longint;
begin
   if(timerLink = nil) then
      Result := DateTimeToTimestamp(Time).time
   else
      Result := timerLink^.Elapsed();
end;

procedure TTimerData.Start();
begin
   startTime      := Cur();
   currentTime    := startTime;
   elapsedTime    := 0;
   elapsedTimef   := 0.0;
   add            := 0;
   paused         := false;
end;

procedure TTimerData.StartOffset(ofs: longint);
begin
   {%H-}system.inc(startTime, ofs);
end;

procedure TTimerData.StartOffsetf(ofs: single);
begin
   StartOffset(round(ofs * 1000));
end;

procedure TTimerData.Update();
begin
   if(not paused) then begin
      currentTime    := Cur();
      elapsedTime    := (currentTime - startTime + add) * factorint;
      elapsedTimef   := ((currentTime - startTime + add) / 1000) * factor;
   end;
end;

procedure TTimerData.SetGoal(ms: longint);
begin
   goalTime := ms;
end;

procedure TTimerData.SetFactor(newFactor: longint);
begin
   factor      := newFactor;
   factorint   := newFactor;
end;

procedure TTimerData.SetFactor(newFactor: single);
begin
   factor      := newFactor;
   factorint   := round(newFactor);
end;

function TTimerData.Elapsed(): longint;
begin
   result := elapsedTime;
end;

function TTimerData.Elapsedf(): single;
begin
   result := elapsedTimef;
end;

function TTimerData.Goal(): boolean;
var
   current: longint;

begin
   current  := Cur();
   result   := (current - elapsedTime + add) > goalTime;
end;


procedure TTimerData.Inc();
begin
   system.inc(iterations);
end;

{return the time flow}
function TTimerData.TimeFlow(): single;
begin
   Update();
   result := elapsedTimef * factor;
   Start();
end;


procedure TTimerData.Pause();
begin
   if(not paused) then begin
      paused      := true;
      pausedTime  := Cur();
   end;
end;

procedure TTimerData.Resume();
begin
   if(paused) then begin
      add         := add + (pausedTime - startTime);
      elapsedTime := 0;
      startTime   := Cur();
      paused      := false;
   end;
end;

procedure TTimerData.Link(var withTimer: TTimerData);
begin
   withTimer.timerLink := @withTimer;
end;

{ GENERAL }

class function TTimerData.GetRandomIntervalf(const minTime, maxTime: single): Single;
begin
   result := minTime + (random() * (maxTime - minTime));
end;

class function TTimerData.Elapsed(const t1, t2: TDateTime): longint;
begin
   Result := DateTimeToTimestamp(t2).Time - DateTimeToTimestamp(t1).Time;
end;

class function TTimerData.Elapsedf(const t1, t2: TDateTime): single;
begin
   Result := (DateTimeToTimestamp(t2).Time - DateTimeToTimestamp(t1).Time) / 1000;
end;


INITIALIZATION
   {setup the default timer}
   TTimerData.Init(timer);

END.
