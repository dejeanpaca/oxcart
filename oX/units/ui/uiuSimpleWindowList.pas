{
   uiuSimpleWindowList, simple window list
   Copyright (C) 2019. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT uiuSimpleWindowList;

INTERFACE

   USES
      uStd,
      {ui}
      uiuWindow, uiuWindowTypes;

TYPE
   { uiTSimpleWindowListHelper }

   uiTSimpleWindowListHelper = record helper for uiTSimpleWindowList
      function FindLeftOf(x: loopint): uiTSimpleWindowList;
      function FindRightOf(x: loopint): uiTSimpleWindowList;

      function FindAbove(y: loopint): uiTSimpleWindowList;
      function FindBelow(y: loopint): uiTSimpleWindowList;

      function GetLeftmostCoordinate(): loopint;

      {get total width (including non-client) of all windows}
      function GetTotalWidth(): loopint;
      {get total height (including non-client) of all windows}
      function GetTotalHeight(): loopint;

      {get total window width to the left from the specified x point}
      function GetLeftWidthFrom(px: loopint): loopint;
      {get total window width to the right from the specified x point}
      function GetRightWidthFrom(px: loopint): loopint;

      {get total window height above the specified y point}
      function GetAboveHeightFrom(py: loopint): loopint;
      {get total window height below the specified y point}
      function GetBelowHeightFrom(py: loopint): loopint;
   end;


IMPLEMENTATION

{ uiTSimpleWindowListHelper }

function uiTSimpleWindowListHelper.FindLeftOf(x: loopint): uiTSimpleWindowList;
var
   i: loopint;

begin
   Result.Initialize(Result);

   for i := 0 to (n - 1) do begin
      if(List[i].Position.x < x) then
         Result.Add(List[i]);
   end;
end;

function uiTSimpleWindowListHelper.FindRightOf(x: loopint): uiTSimpleWindowList;
var
   i: loopint;

begin
   Result.Initialize(Result);

   for i := 0 to (n - 1) do begin
      if(List[i].Position.x > x) then
         Result.Add(List[i]);
   end;
end;

function uiTSimpleWindowListHelper.FindAbove(y: loopint): uiTSimpleWindowList;
var
   i: loopint;

begin
   Result.Initialize(Result);

   for i := 0 to (n - 1) do begin
      if(List[i].Position.y > y) then
         Result.Add(List[i]);
   end;
end;

function uiTSimpleWindowListHelper.FindBelow(y: loopint): uiTSimpleWindowList;
var
   i: loopint;

begin
   Result.Initialize(Result);

   for i := 0 to (n - 1) do begin
      if(List[i].Position.y < y) then
         Result.Add(List[i]);
   end;
end;

function uiTSimpleWindowListHelper.GetLeftmostCoordinate(): loopint;
var
   i: loopint;

begin
   Result := 0;

   if(n > 0) then begin
      Result := List[0].Position.x;

      for i := 1 to n - 1 do begin
         if(List[i].Position.x < Result) then
            Result := List[i].Position.x;
      end;
   end;
end;

function uiTSimpleWindowListHelper.GetTotalWidth(): loopint;
var
   i: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      inc(Result, List[i].GetTotalWidth());
   end;
end;

function uiTSimpleWindowListHelper.GetTotalHeight(): loopint;
var
   i: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      inc(Result, List[i].GetTotalHeight());
   end;
end;

function uiTSimpleWindowListHelper.GetLeftWidthFrom(px: loopint): loopint;
var
   i,
   leftMost: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      leftMost := List[i].Position.x;

      if(px - leftMost> Result) then
         Result := px - leftMost;
   end;
end;

function uiTSimpleWindowListHelper.GetRightWidthFrom(px: loopint): loopint;
var
   i,
   rightMost: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      rightMost := List[i].Position.x + List[i].GetTotalWidth();

      if(rightMost - px > Result) then
         Result := rightMost - px;
   end;
end;

function uiTSimpleWindowListHelper.GetAboveHeightFrom(py: loopint): loopint;
var
   i,
   aboveMost: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      aboveMost := List[i].Position.y;

      if(aboveMost - py > Result) then
         Result := aboveMost - py;
   end;
end;

function uiTSimpleWindowListHelper.GetBelowHeightFrom(py: loopint): loopint;
var
   i,
   belowMost: loopint;

begin
   Result := 0;

   for i := 0 to (n - 1) do begin
      belowMost := List[i].Position.y - List[i].GetTotalHeight();

      if(py - belowMost > Result) then
         Result := py - belowMost;
   end;
end;

END.
