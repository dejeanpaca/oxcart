{
   oxuFramerate, oX framerate measurement
   Copyright (C) 2011. Dejan Boras

   Started On:    19.03.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuFramerate;

INTERFACE

   USES
     StringUtils, uTiming,
     {ox}
     uOX;

CONST
   oxcFramerateUpdateInterval: longword = 1000;

TYPE
   oxTFramerate = record
      f,
      favg: single;

      fTimer,
      favgTimer: TTimer;

      fCount,
      favgCount: longint;

      procedure Update();
      procedure Increment();

      procedure Pause();
      procedure Resume();

      function Get(): string;
      function GetAverage(): string;
   end;

VAR
   oxFramerate: oxTFramerate;

{ FRAMERATE }
procedure oxFramerateInit(var f: oxTFramerate);

function oxFramerateGet(fps: single; nDecimals: longint): string;
function oxFramerateGetAverage(fps: single; nDecimals: longint): string;

IMPLEMENTATION

{ FRAMERATE }
procedure oxFramerateInit(var f: oxTFramerate);
begin
   f.fCount       := 0;
   f.favgCount    := 0;

   f.fTimer.Init();
   f.favgTimer.Init();
   f.fTimer.Init();
   f.favgTimer.Init();
end;

procedure oxTFramerate.Update();
begin
   {update timers}
   fTimer.Update();
   favgTimer.Update();

   {calculate framerate}
   if(not fTimer.paused) then begin
      if(fTimer.ElapsedTime >= oxcFramerateUpdateInterval) then begin
         f        := fCount / (fTimer.elapsedTime / 1000);
         fCount   := 0;
         fTimer.Start();
      end;
   end;

   {calculate average framerate}
   if(not favgTimer.Paused) then begin
      if(favgTimer.elapsedTime > 0) then begin
         favg := favgCount / (favgTimer.elapsedTime / 1000);
      end;
   end;
end;

procedure oxTFramerate.Increment();
begin
   if(not fTimer.paused) then
      inc(fCount);

   if(not favgTimer.paused) then
      inc(favgCount);

   Update();
end;

procedure oxTFramerate.Pause();
begin
   fTimer.Pause();
   favgTimer.Pause();
end;

procedure oxTFramerate.Resume();
begin
   fTimer.Resume();
   favgTimer.Resume();
end;

function oxTFramerate.Get(): string;
begin
   result := sf(f, 2);
end;

function oxTFramerate.GetAverage(): string;
begin
   result := sf(favg, 2);
end;

function oxFramerateGet(fps: single; nDecimals: longint): string;
var
   xstr: string;

begin
   str(fps:0:nDecimals, xstr);
   result := xstr;
end;

function oxFramerateGetAverage(fps: single; nDecimals: longint): string;
var
   xstr: string;

begin
   str(fps:0:nDecimals, xstr);
   result := xstr;
end;

procedure update();
begin
   oxFramerate.Increment();
end;

INITIALIZATION
   oxFramerateInit(oxFramerate);
   ox.OnRun.Add(@update);

END.
