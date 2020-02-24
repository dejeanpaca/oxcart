{
   oxuFramerate, oX framerate measurement
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuFramerate;

INTERFACE

   USES
     StringUtils, uTiming,
     {ox}
     uOX, oxuRunRoutines;

CONST
   oxcFramerateUpdateInterval: longint = 1000;

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
   if(not fTimer.Paused) then begin
      if(fTimer.ElapsedTime >= oxcFramerateUpdateInterval) then begin
         f        := fCount / (fTimer.ElapsedTime / 1000);
         fCount   := 0;
         fTimer.Start();
      end;
   end;

   {calculate average framerate}
   if(not favgTimer.Paused) then begin
      if(favgTimer.ElapsedTime > 0) then begin
         favg := favgCount / (favgTimer.ElapsedTime / 1000);
      end;
   end;
end;

procedure oxTFramerate.Increment();
begin
   if(not fTimer.Paused) then
      inc(fCount);

   if(not favgTimer.Paused) then
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
   Result := sf(f, 2);
end;

function oxTFramerate.GetAverage(): string;
begin
   Result := sf(favg, 2);
end;

function oxFramerateGet(fps: single; nDecimals: longint): string;
var
   xstr: string;

begin
   str(fps:0:nDecimals, xstr);
   Result := xstr;
end;

function oxFramerateGetAverage(fps: single; nDecimals: longint): string;
var
   xstr: string;

begin
   str(fps:0:nDecimals, xstr);
   Result := xstr;
end;

procedure update();
begin
   oxFramerate.Increment();
end;

INITIALIZATION
   oxFramerateInit(oxFramerate);

   ox.OnRun.Add('ox.framerate_update', @update);

END.
