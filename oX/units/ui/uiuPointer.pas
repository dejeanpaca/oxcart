{
   uiuPointer, ui pointer handling
   Copyright (C) 2019. Dejan Boras

   Started On:    17.04.2019.
}

{$INCLUDE oxdefines.inc}
UNIT uiuPointer;

INTERFACE

   USES
      sysutils, uStd, uTiming,
      {app}
      appuMouse,
      {oX}
      oxuUI, oxuTypes, oxuGlobalInstances,
      {ui}
      uiuControl;

TYPE
   uiTPointerEvent = record
      Time: TDateTime;
      Target: uiTControl;
      m: appTMouseEvent;
   end;

   { uiTPointerGlobal }

   uiTPointerGlobal = record
      {last pointer events}
      nEvents: loopint;
      Events: array[0..5] of uiTPointerEvent;

      DoubleClick: record
         {time to consider click events a double click}
         Time,
         {distance to consider click events a double click}
         Distance: loopint;
      end;

      procedure AddEvent(t: uiTControl; m: appTMouseEvent);

      {checks if events contain a double click}
      function IsDoubleClick(): boolean;
   end;

VAR
   uiPointer: uiTPointerGlobal;

IMPLEMENTATION

procedure uiTPointerGlobal.AddEvent(t: uiTControl; m: appTMouseEvent);
var
   i: loopint;
   event: uiTPointerEvent;

begin
   ZeroPtr(@event, SizeOf(event));
   event.Time := Now;
   event.Target := t;
   event.m := m;

   if(nEvents < High(Events) - 1) then
      {we have room to add a new event}
      inc(nEvents)
   else begin
      {move all events one place down the list}
      for i := 0 to nEvents - 2 do
         Events[i] := Events[i + 1];
   end;

   Events[nEvents - 1] := event;
end;

function uiTPointerGlobal.IsDoubleClick(): boolean;
var
   i,
   f,
   elapsed: loopint;
   p1,
   p2: oxTPoint;

begin
   if(nEvents >= 3) then begin
      f := nEvents - 1;

      if(Events[f].m.IsReleased()) then begin
         for i := f - 1 downto f - 2 do begin
            if(i >= 0) then begin
               {both events must be releases on a matching target, with matching buttons}
               if(Events[i].m.IsReleased()) and (Events[i].Target = Events[f].Target)
               and (Events[i].m.Button = Events[f].m.Button) then begin
                  elapsed := TTimer.Elapsed(Events[i].Time, Events[f].Time);

                  {two clicks must occur within the allowed time span}
                  if(elapsed < 0) or (elapsed > DoubleClick.Time) then
                     Exit(False);

                  p1.x := round(Events[f].m.x);
                  p1.y := round(Events[f].m.y);

                  p2.x := round(Events[i].m.x);
                  p2.y := round(Events[i].m.y);

                  {distance must not exceed allowed distance}
                  if(p2.Distance(p1) > DoubleClick.Distance) then
                     exit(False);

                  {seems like a double click}
                  Exit(True);
               end;
            end;
         end;
      end;
   end;

   Result := False;
end;

INITIALIZATION
   uiPointer.DoubleClick.Distance := 5;
   uiPointer.DoubleClick.Time := 400;

   oxGlobalInstances.Add('uiTPointerGlobal', @uiPointer);

END.
