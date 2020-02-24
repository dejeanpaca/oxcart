{
   vmBBox, bounding box operations
   Copyright (C) 2010. Dejan Boras
}

{$MODE OBJFPC}{$H+}{$I-}{$MODESWITCH TYPEHELPERS}
UNIT vmBBox;

INTERFACE

   USES vmVector, math;

TYPE

   { TBoundingBoxHelper }

   TBoundingBoxHelper = type helper for TBoundingBox
      {scale the specified bounding box}
      procedure Scale(x, y, z: single);
      {determine the radius of a bounding box}
      function DetermineRadius(): single;
      {expand this box with the given one}
      procedure Expand(const bbox: TBoundingBox);
   end;


IMPLEMENTATION

procedure TBoundingBoxHelper.Scale(x, y, z: single);
begin
   self[0][0] := self[0][0] * x;
   self[0][1] := self[0][1] * y;
   self[0][2] := self[0][2] * z;

   self[1][0] := self[1][0] * x;
   self[1][1] := self[1][1] * y;
   self[1][2] := self[1][2] * z;
end;

{NOTE: The bounding boxes may not be always centered(as the object used to
determine the bbox is not centered). Therefore the radius may be higher than
required. To get a minimum radius would require to center the object exactly.}
function TBoundingBoxHelper.DetermineRadius(): single;
var
   x,
   y,
   z: single;
   radius: single;

function higher(idx: longint): single;
begin
   {we need to use abs because length may be negative}
   if(abs(self[0][idx]) > abs(self[1][idx])) then
      result := abs(self[0][idx])
   else
      result := abs(self[1][idx]);
end;

begin
   {get the largest values for side lengths}
   x := higher(0);
   y := higher(1);
   z := higher(2);

   {the radius the largest length}
   if(x > y) then
      radius := x
   else begin
      if(y > z) then
         radius := y
      else
         radius := z;
   end;

   {we multiply by 2 because bbox values are half length}
   result := radius * 2;
end;

procedure TBoundingBoxHelper.Expand(const bbox: TBoundingBox);
begin
   Self[0][0] := Min(Self[0][0], bbox[0][0]);
   Self[0][1] := Min(Self[0][1], bbox[0][0]);
   Self[0][2] := Min(Self[0][2], bbox[0][0]);

   Self[1][0] := Max(Self[1][0], bbox[1][0]);
   Self[1][1] := Max(Self[1][1], bbox[1][1]);
   Self[1][2] := Max(Self[1][2], bbox[1][2]);
end;


END.
