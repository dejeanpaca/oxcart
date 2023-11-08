{
   oxuFramerate, oX framerate measurement
   Copyright (C) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuFramerate;

INTERFACE

   USES
     StringUtils, uTiming,
     {ox}
     uOX, oxuRunRoutines, oxuWindowRender;

CONST
   oxcFramerateUpdateInterval: longint = 1000;

TYPE
   oxTFramerate = record
      f,
      fAverage: single;

      fTimer,
      fAverageTimer: TTimer;

      fCount,
      fAverageCount: longint;

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
   f.fCount := 0;
   f.fAverageCount := 0;

   f.fTimer.Init();
   f.fAverageTimer.Init();
   f.fTimer.Init();
   f.fAverageTimer.Init();
end;

procedure oxTFramerate.Update();
begin
   {update timers}
   fTimer.Update();
   fAverageTimer.Update();

   {calculate framerate}
   if(not fTimer.Paused) then begin
      if(fTimer.ElapsedTime >= oxcFramerateUpdateInterval) then begin
         f        := fCount / (fTimer.ElapsedTime / 1000);
         fCount   := 0;
         fTimer.Start();
      end;
   end;

   {calculate average framerate}
   if(not fAverageTimer.Paused) then begin
      if(fAverageTimer.ElapsedTime > 0) then begin
         fAverage := fAverageCount / (fAverageTimer.ElapsedTime / 1000);
      end;
   end;
end;

procedure oxTFramerate.Increment();
begin
   if(not fTimer.Paused) then
      inc(fCount);

   if(not fAverageTimer.Paused) then
      inc(fAverageCount);

   Update();
end;

procedure oxTFramerate.Pause();
begin
   fTimer.Pause();
   fAverageTimer.Pause();
end;

procedure oxTFramerate.Resume();
begin
   fTimer.Resume();
   fAverageTimer.Resume();
end;

function oxTFramerate.Get(): string;
begin
   Result := sf(f, 2);
end;

function oxTFramerate.GetAverage(): string;
begin
   Result := sf(fAverage, 2);
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
   if(oxWindowRender.Rendered) then
      oxFramerate.Increment();
end;

INITIALIZATION
   oxFramerateInit(oxFramerate);

   ox.OnRun.Add('ox.framerate_update', @update);

END.
