{
   vmCollision, collision detection routines
   Copyright (C) 2009. Dejan Boras

   Started On:    24.06.2009.
}

{$MODE OBJFPC}{$H+}
UNIT vmCollision;

INTERFACE

   USES vmVector;

{ BOUNDING BOX }

{checks whether a point is inside a bounding box}
function vmPointInBBox(const vPoint: TVector3; const BBox: TBoundingBox): boolean;
{checks whether a ray intersects an AABB in single dimension}
function vmRayAABBIntersect1D(start, dir, min, max: single; var enter, ex: single): boolean;
{checks whether a line-segment collides with a AABB}
function vmRayAABBCollide(const box: TBoundingBox; const vS, vD: TVector3f; out penter, pexit: TVector3f): boolean;

{ SPHERE }

{classifies a sphere}
function vmClassifySphere(const vCenter, vNormal, vPoint: TVector3; const radius: single;
      var dist: single): word; {$IFDEF VM_INLINE}inline;{$ENDIF}
{check if the sphere is colliding against the edge of a polygon}
function vmEdgeSphereCollision(const vCenter: TVector3; var Poly: array of TVector3;
               nVertex: longint; radius: single): boolean; {$IFDEF VM_INLINE}inline;{$ENDIF}
{Once collided, this routine figures out how much to move back the sphere}
function vmSphereCollisionOffset(const vNormal: TVector3; radius, dist: single): TVector3; {$IFDEF VM_INLINE}inline;{$ENDIF}

{ PLANES / POLYS }

{return intersection point intersecting a plane}
function vmIntersectionPoint(const vNormal: TVector3; var Line: array of TVector3;
      const Distance: single): TVector3; {$IFDEF VM_INLINE}inline;{$ENDIF}
{Checks to see if a point is inside a range of polygons}
function vmInsidePoly(const vIntersection: TVector3; var Poly: array of TVector3; nVertices: longint): boolean; {$IFDEF VM_INLINE}inline;{$ENDIF}
{check if a line is intersecting a polygon}
function vmIntersectedPoly(var Poly, Line: array of TVector3;
      nVertices: longint): boolean; {$IFDEF VM_INLINE}inline;{$ENDIF}

{ PLANE }
{check if a plane is intersected by a line}
function vmPlaneIntersect(var poly, line: array of TVector3; out normal: TVector3;
      out oDist: single): boolean; {$IFDEF VM_INLINE}inline;{$ENDIF}

IMPLEMENTATION

{ BOUNDING BOX }

function vmPointInBBox(const vPoint: TVector3; const BBox: TBoundingBox): boolean;
begin
   result := (vPoint[0] >= BBox[0][0]) and (vPoint[0] <= BBox[1][0])
         and (vPoint[1] >= BBox[0][1]) and (vPoint[1] <= BBox[1][1])
         and (vPoint[2] >= BBox[0][2]) and (vPoint[2] <= BBox[1][2]);
end;

function vmRayAABBIntersect1D(start, dir, min, max: single; var enter, ex: single): boolean;
var
   t0,
   t1,
   tmp: single;

begin
   {ray parallel}
   if(abs(dir) < 1.0E-8) then
      exit((start >= min) and (start <= max));

   {intersection parameters}
   t0 := (min - start) / dir;
   t1 := (max - start) / dir;

   {sort intersections}
   if(t0 > t1) then begin
      tmp := t1;
      t1 := t0;
      t0 := tmp;
   end;

   {check if intervals are disjoint}
   if(t0 > ex) or (t1 < enter) then
      exit(false);

   {reduce interval}
   if(t0 > enter) then
      enter := t0;

   if(t1 < ex) then
      ex := t1;

   result := true;
end;

{checks whether a ray collides with an AABB}
function vmRayAABBCollide(const box: TBoundingBox; const vS, vD: TVector3f; out penter, pexit: TVector3f): boolean;
var
   enter: single  = 0.0;
   ex: single     = 1.0;

begin
   //TODO: Need to determine the line segment direction. This may be incorrect.

   {check individual sides}
   if(not vmRayAABBIntersect1D(vS[0], vD[0], box[0][0], box[1][0], enter, ex)) then
      exit(false);

   if(not vmRayAABBIntersect1D(vS[1], vD[1], box[0][1], box[1][1], enter, ex)) then
      exit(false);

   if(not vmRayAABBIntersect1D(vS[2], vD[2], box[0][2], box[1][2], enter, ex)) then
      exit(false);

   penter   := vS + vD * enter;
   pexit    := vS + vD * ex;

   result := true;
end;

{ SPHERE }

function vmClassifySphere(const vCenter, vNormal, vPoint: TVector3; const radius: single;
      var dist: single): word; {$IFDEF VM_INLINE}inline;{$ENDIF} {OK}
var
   d: single;

begin
   d := vmPlaneDistance(vNormal, vPoint);

   dist:= (vNormal[0] * vCenter[0] + vNormal[1] * vCenter[1] + vNormal[2] * vCenter[2] + d);

   if(abs(dist) < radius) then
      result := vmcIntersects
   else if(dist >= radius) then
      result := vmcFront
   else
      result := vmcBehind;
end;

function vmEdgeSphereCollision(const vCenter: TVector3; var Poly: array of TVector3;
               nVertex: longint; radius: single): boolean; {$IFDEF VM_INLINE}inline;{$ENDIF} {OK}
var
   vPoint: TVector3;
   i: longint;
   Dist: single;

begin
   Result := false;

   for i := 0 to (nVertex-1) do begin
      vPoint   := vmClosestPointOnLine(Poly[i], Poly[(i+1) mod nVertex], vCenter);
      Dist     := vPoint.Distance(vCenter);

      if(Dist < radius) then
         exit(true);
   end;
end;

function vmSphereCollisionOffset(const vNormal: TVector3; radius,
      dist: single): TVector3; {$IFDEF VM_INLINE}inline;{$ENDIF} {OK}
begin
   if(dist > 0) then
      exit(vNormal * (radius - dist))
   else
      exit(vNormal * (-(radius + dist)));
end;

{ PLANES / POLYS }

function vmIntersectionPoint(const vNormal: TVector3; var Line: array of TVector3;
                  const Distance: single): TVector3; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   vPoint,
   vLineDir: TVector3;
   numerator,
   denominator,
   dist: single;

begin
   {get line vector, direction}
   vLineDir := (Line[1] - Line[0]);
   vLineDir.Normalize();

   {The plane equation helps to find the Distanceance}
   numerator := -(vNormal[0] * Line[0][0] +
                  vNormal[1] * Line[0][1] +
                  vNormal[2] * Line[0][2] + Distance);

   denominator := vNormal.Dot(vLineDir);

	{Since we are using division, we need to make sure we don't get a divide by zero error
	If we do get a 0, that means that there are infinite vPoints because the the line is
	on the plane (the vNormal is perpendicular to the line - (vNormal.Vector = 0)).
	In this case, we should just return any vPoint on the line.}

   if(denominator <> 0.0) then begin
      dist := Numerator / Denominator;

      vPoint[0] := Line[0][0] + (vLineDir[0] * dist);
      vPoint[1] := Line[0][1] + (vLineDir[1] * dist);
      vPoint[2] := Line[0][2] + (vLineDir[2] * dist);

      result := vPoint;
   end else
      result := Line[0];
end;

function vmInsidePoly(const vIntersection: TVector3; var Poly: array of TVector3;
      nVertices: longint): boolean; {$IFDEF VM_INLINE}inline;{$ENDIF} {OK}
const
   cMatchFactor = 0.9999;

var
   angle: double = 0.0;
   v1,
   v2: TVector3;
   i: longint;

begin
   for i := 0 to (nVertices-1) do begin
      v1 := Poly[i] - vIntersection;
      v2 := Poly[(i + 1) mod nVertices] - vIntersection;
      Angle += vmAngle(v1, v2);
   end;

   result := Angle >= (cMatchFactor * 2.0 * vmcPi);
end;

function vmIntersectedPoly(var Poly, Line: array of TVector3;
      nVertices: longint): boolean; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   intersection, normal: TVector3;
   oDist: single;

begin
   {if there is no intersection the return false}

   if(vmPlaneIntersect(Poly, Line, normal, oDist)) then
      exit(false);

   {get the intersection point}
   intersection := vmIntersectionPoint(normal, Line, oDist);

	{test if the intersection point is inside the polygon}
   result := vmInsidePoly(intersection, Poly, nVertices); {there was a collision if true}
end;

{ PLANE }

function vmPlaneIntersect(var poly, line: array of TVector3; out normal: TVector3;
      out oDist: single): boolean; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   dist1,
   dist2: single;

begin
   normal := vmNormal(poly);

   {find the distance of the origin from plane}
   oDist := vmPlaneDistance(normal, poly[0]);

   {Get the distance from the plane using the equation(use line point 0):  Ax + Bx + Cz + D}
   dist1 := ((normal[0] * line[0][0]) + (normal[1] * line[0][1]) + (normal[2] + line[0][2]) + oDist);
               {Ax                  +           Bx           +          Cz              +   D}

   {Same as above, only for the second line point}
   dist2 := ((normal[0] * line[1][0]) + (normal[1] * line[1][1]) + (normal[2] + line[1][2]) + oDist);

   {if dist1 * dist2 is greater than 0 then no collision has occured, otherwise it has}
   result := dist1 * dist2 >= 0;
end;

END.
