{
   vmQuaternions, quaternion mathematics & operations
   Copyright (C) 2007. Dejan Boras

   Some of this was adapted from http://www.opengl-tutorial.org/assets/faq_quaternions/index.html#Q60
}

{$INCLUDE oxheader.inc}
UNIT vmQuaternions;

INTERFACE

   USES
      uStd, StringUtils,
      vmVector, Math, vmMath;

TYPE
   {Quaternion type, xyz vector, and w scalar, basicaly a vector with 4 elements}
   TQuaternion       = TVector4;
   TQuaternion2d     = TVector2d;

   { TQuaternionHelper }

   TQuaternionHelper = type helper for TQuaternion
      function ToString(decimals: loopint = -1; const separator: string = ','): string;
      procedure ToRotationMatrix(out m: TMatrix4f);
      procedure ToRotationMatrix(out m: TMatrix3f);
   end;

CONST
   vmqZero: TQuaternion = (0.0, 0.0, 0.0, 0.0);
   vmqIdentity: TQuaternion = (0.0, 0.0, 0.0, 1.0);

{create a quaternion from a axis and angle}
function vmqFromAxisAngle(const axis: TVector3; degree: single): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
{get axis and angle from a quaternion}
procedure vmqToAxisAngle(const q: TQuaternion; out axis: TVector3; out angle: single); {$IFDEF VM_INLINE}inline;{$ENDIF}
{create a quaternion out of a 4x4 matrix}
procedure vmqFromMatrix(const m: TMatrix3; var qt: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
procedure vmqFromMatrix(const m: TMatrix4; var qt: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}

procedure vmqFromMatrixAlt(const m: TMatrix3; var qt: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
procedure vmqFromMatrixAlt(const m: TMatrix4; var qt: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}

{Return a spherical linear interpolation(SLERP) of two quaternions, taking t into account}
function vmqSLERP(var q1, q2: TQuaternion; t: single): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
{calculate a quaternion from Euler angle representation}
procedure vmqFromEuler(pitch, yaw, roll: single; out q: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
{calculate a quaternion from Euler angle representation}
procedure vmqFromEuler(const v: TVector3f; out q: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
{calculate a quaternion from Euler angle representation in degrees}
procedure vmqFromEulerDeg(x, y, z: single; out q: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
procedure vmqFromEulerDeg(const v: TVector3f; out q: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
{returns the three Euler angles from a quaternion as a vector}
function vmqToEuler(var q: TQuaternion): TVector3;
procedure vmqToEuler(var q: TQuaternion; out v: TVector3);
procedure vmqToEulerDeg(var q: TQuaternion; out v: TVector3);

{calculate the magnitude of a quaternion}
function vmqMagnitude(var q: TQuaternion): single; {$IFDEF VM_INLINE}inline;{$ENDIF}
{normalize a quaternion}
function vmqNormalize(const q: TQuaternion): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
procedure vmqNormalizev(var q: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
{multiply two quaternions}
function vmqMul(const q1, q2: TQuaternion): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
{conjugate the quaternion}
function vmqConjugate(const q: TQuaternion): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
procedure vmqConjugatev(var q: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}

{get the angle of rotation around the axis(quaternion vector)}
function vmqGetAngle(const q: TQuaternion): single; {$IFDEF VM_INLINE}inline;{$ENDIF}
{returns a unit vector representing the axis of rotation(quaternion vector)}
function vmqGetAxis(const q: TQuaternion): TVector3; {$IFDEF VM_INLINE}inline;{$ENDIF}
{rotate a quaternion by another quaternion}
function vmqRotate(const q1, q2: TQuaternion): TQuaternion;
{rotate a vector by a quaternion}
function vmqRotate(const q: TQuaternion; const v: TVector3): TVector3;

{operator overload for multiplying two quaternions}
operator * (const q1, q2: TQuaternion): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
{operator overload for scalar multiplication of a quaternion}
operator * (const q: TQuaternion; s: single): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
{operator overload for scalar division of a quaternion}
operator / (const q: TQuaternion; s: single): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
{operator overload for adding two quaternions}
operator + (const q1, q2: TQuaternion): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
{operator overload for subtracting two quaternions}
operator - (const q1, q2: TQuaternion): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
{ vectors and quaternions }
{operator overload for multiplying a quaternion and a vector}
operator * (const q: TQuaternion; const v: TVector3): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
operator * (const v: TVector3; const q: TQuaternion): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}

IMPLEMENTATION

function vmqFromAxisAngle(const axis: TVector3; degree: single): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   sin_a,
   cos_a: single;

begin
   sin_a := sin(degree * 0.5);
   cos_a := cos(degree * 0.5);

   Result[0] := axis[0] * sin_a; {x}
   Result[1] := axis[1] * sin_a; {y}
   Result[2] := axis[2] * sin_a; {z}
   Result[3] := cos_a; {w}
end;

procedure vmqToAxisAngle(const q: TQuaternion; out axis: TVector3; out angle: single);
var
   cos_a,
   sin_a: single;

begin
   cos_a := q[3];
   angle := ArcCos(cos_a) * 2;
   sin_a := Sqrt(1.0 - cos_a * cos_a);

   if(Abs(sin_a) < 0.00005) then
      sin_a := 1;

   axis[0] := q[0] / sin_a;
   axis[1] := q[1] / sin_a;
   axis[2] := q[2] / sin_a;
end;

procedure vmqFromMatrix(const m: TMatrix3; var qt: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
{$INCLUDE operators/qfrommatrix.inc}

procedure vmqFromMatrix(const m: TMatrix4; var qt: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
{$INCLUDE operators/qfrommatrix.inc}

{ Thanks to certain Christian for this quaternion from matrix code.
http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/christian.htm

Although I've expected it to go faster than the standard routine, it does not for some reason.}

procedure vmqFromMatrixAlt(const m: TMatrix3; var qt: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
{$INCLUDE operators/qfrommatrixalt.inc}

procedure vmqFromMatrixAlt(const m: TMatrix4; var qt: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
{$INCLUDE operators/qfrommatrixalt.inc}

function vmqSLERP(var q1, q2: TQuaternion; t: single): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   dotp, scale1, scale2, theta, sintheta: single;

begin
   {based on the equation: q = (((q2.q1)^-1)^t)q1
   we will calculate the interpolated quaternion}

   {check if the two quaternions are the same}
   if(CompareDWord(q1, q2, sizeof(TQuaternion) div 4)  <> 0) then begin
      {calculate the dot product of the two quaternions, basically the same
      as calculating the dot product of TVector4}
      dotp := q1[0] * q2[0] + q1[1] * q2[1] + q1[2] * q2[2] + q1[3] * q1[3];

      {if the dotp is less then 0, then the angle is greater than 90 deg}
      if(dotp < 0.0) then begin
		   {negate q2 and the dotp}
		   q2[0] := -q2[0];
         q2[1] := -q2[1];
         q2[2] := -q2[2];
         q2[3] := -q2[3];
		   dotp := -dotp;
	   end;

	   {set up scales}
	   scale1 := 1 - t; scale2 := t;

      if(1 - dotp > 0.1) then begin
         {get the angle of the two quaternions, and store the sinus of that angle into sintheta}
         theta := arccos(dotp);
         sintheta := sin(theta);

         {calculate scales for q1 and q2}
         scale1 := sin((1 - t) * theta) / sintheta;
         scale2 := sin(t * theta) / sintheta;
      end;

      {calculate the quaternion by using a form of linear interpolation for quaternions}
      {x}Result[0] := (scale1 * q1[0]) + (scale2 * q2[0]);
      {y}Result[1] := (scale1 * q1[1]) + (scale2 * q2[1]);
      {z}Result[2] := (scale1 * q1[2]) + (scale2 * q2[2]);
      {w}Result[3] := (scale1 * q1[3]) + (scale2 * q2[3]);
   end else
      Result := q1;
end;

procedure vmqFromEuler(pitch, yaw, roll: single; out q: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   qx, qy, qz, qt: TQuaternion;

begin
   qx := vmqFromAxisAngle(vmvLeft, pitch);
   qy := vmqFromAxisAngle(vmvUp, yaw);
   qz := vmqFromAxisAngle(vmvForward, roll);

   qt := vmqMul(qx, qy);
   q := vmqMul(qt, qz);
end;

procedure vmqFromEuler(const v: TVector3f; out q: TQuaternion);
begin
   vmqFromEuler(v[0], v[1], v[2], q);
end;

procedure vmqFromEulerDeg(x, y, z: single; out q: TQuaternion);
begin
   vmqFromEuler(x * vmcToRad, y * vmcToRad, z * vmcToRad, q);
end;

procedure vmqFromEulerDeg(const v: TVector3f; out q: TQuaternion);
var
   vd: TVector3f;

begin
   vd[0] := v[0] * vmcToRad;
   vd[1] := v[1] * vmcToRad;
   vd[2] := v[2] * vmcToRad;

   vmqFromEuler(vd, q);
end;

function vmqToEuler(var q: TQuaternion): TVector3;
var
   rm: TMatrix4f;

begin
   q.ToRotationMatrix(rm);

   Result := rm.RotationToEuler();
end;

procedure vmqToEuler(var q: TQuaternion; out v: TVector3);
begin
   v := vmqToEuler(q);
end;

procedure vmqToEulerDeg(var q: TQuaternion; out v: TVector3);
begin
   vmqToEuler(q, v);

   v[0] := v[0] * vmcToDeg;
   v[1] := v[1] * vmcToDeg;
   v[2] := v[2] * vmcToDeg;
end;

function vmqMagnitude(var q: TQuaternion): single; {$IFDEF VM_INLINE}inline;{$ENDIF}
begin
   {mag = sqrt(x*x + y*y + z*z + w*w)}
   vmqMagnitude := sqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3])
end;

function vmqNormalize(const q: TQuaternion): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   mag: single;

begin
   mag := sqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3]);

   vmqNormalize[0] := q[0] / mag;
   vmqNormalize[1] := q[1] / mag;
   vmqNormalize[2] := q[2] / mag;
   vmqNormalize[3] := q[3] / mag;
end;

procedure vmqNormalizev(var q: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   mag: single;

begin
   mag := sqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3]);

   q[0] := q[0] / mag;
   q[1] := q[1] / mag;
   q[2] := q[2] / mag;
   q[3] := q[3] / mag;
end;

function vmqMul(const q1, q2: TQuaternion): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   w1, w2,
   x1, x2,
   y1, y2,
   z1, z2: single;

begin
   w1 := q1[3];
   x1 := q1[0];
   y1 := q1[1];
   z1 := q1[2];

   w2 := q2[3];
   x2 := q2[0];
   y2 := q2[1];
   z2 := q2[2];

   Result[3] := w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2;
   Result[0] := w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2;
   Result[1] := w1 * y2 + y1 * w2 + z1 * x2 - x1 * z2;
   Result[2] := w1 * z2 + z1 * w2 + x1 * y2 - y1 * x2;
end;

function vmqConjugate(const q: TQuaternion): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
begin
   Result[0] := -q[0];
   Result[1] := -q[1];
   Result[2] := -q[2];
   Result[3] :=  q[3];
end;

procedure vmqConjugatev(var q: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
begin
   q[0] := -q[0];
   q[1] := -q[1];
   q[2] := -q[2];
end;

function vmqGetAngle(const q: TQuaternion): single; {$IFDEF VM_INLINE}inline;{$ENDIF}
begin
   Result := 2 * arccos(q[3]);
end;

function vmqGetAxis(const q: TQuaternion): TVector3; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   mag: single;
   v: TVector3 absolute q;

begin
   mag := sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);

   Result[0] := v[0] / mag;
   Result[1] := v[1] / mag;
   Result[2] := v[2] / mag;
end;

function vmqRotate(const q1, q2: TQuaternion): TQuaternion;
begin
   Result   := q1 * q2 * vmqConjugate(q1);
end;

function vmqRotate(const q: TQuaternion; const v: TVector3): TVector3;
var
   t: TQuaternion;
   e: TVector3 absolute t;

begin
   {TODO: Need to check this code, it might be incorrect}
   t        := q * v * vmqConjugate(q);
   Result   := e;
end;

{OPERATOR OVERLOAD}

operator * (const q1, q2: TQuaternion) : TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   w1, w2,
   x1, x2,
   y1, y2,
   z1, z2: single;

begin
   w1 := q1[3];
   x1 := q1[0];
   y1 := q1[1];
   z1 := q1[2];

   w2 := q2[3];
   x2 := q2[0];
   y2 := q2[1];
   z2 := q2[2];

   Result[3] := w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2;
   Result[0] := w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2;
   Result[1] := w1 * y2 + y1 * w2 + z1 * x2 - x1 * z2;
   Result[2] := w1 * z2 + z1 * w2 + x1 * y2 - y1 * x2;
end;

operator * (const q: TQuaternion; s: single): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
begin
   Result[0] := q[0] * s;
   Result[1] := q[1] * s;
   Result[2] := q[2] * s;
   Result[3] := q[3] * s;
end;

operator / (const q: TQuaternion; s: single): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
begin
   Result[0] := q[0] / s;
   Result[1] := q[1] / s;
   Result[2] := q[2] / s;
   Result[3] := q[3] / s;
end;

operator + (const q1, q2: TQuaternion): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
begin
   Result[0] := q1[0] + q2[0];
   Result[1] := q1[1] + q2[1];
   Result[2] := q1[2] + q2[2];
   Result[3] := q1[3] + q2[3];
end;

operator - (const q1, q2: TQuaternion): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
begin
   Result[0] := q1[0] - q2[0];
   Result[1] := q1[1] - q2[1];
   Result[2] := q1[2] - q2[2];
   Result[3] := q1[3] - q2[3];
end;

operator * (const q: TQuaternion; const v: TVector3): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
begin
   Result[0] :=   q[3]*v[0] + q[1]*v[2] - q[2]*v[1];
   Result[1] :=   q[3]*v[1] + q[2]*v[0] - q[0]*v[2];
   Result[2] :=   q[3]*v[2] + q[0]*v[1] - q[1]+v[0];
   Result[3] := -(q[0]*v[0] + q[1]*v[1] + q[2]*v[2]);
end;

operator * (const v: TVector3; const q: TQuaternion): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
begin
   Result[0] :=   q[3]*v[0] + q[2]*v[1] - q[1]*v[2];
   Result[1] :=   q[3]*v[1] + q[0]*v[2] - q[2]*v[0];
   Result[2] :=   q[3]*v[2] + q[1]*v[0] - q[0]*v[1];
   Result[3] := -(q[0]*v[0] + q[1]*v[1] + q[2]*v[2]);
end;

{ TQuaternionHelper }

function TQuaternionHelper.ToString(decimals: loopint; const separator: string): string;
begin
   if(decimals > -1) then
      Result := sf(Self[0], decimals) + separator + sf(Self[1], decimals) + separator + sf(Self[2], decimals) + separator + sf(Self[3], decimals)
   else
      Result := sf(Self[0]) + separator + sf(Self[1]) + separator + sf(Self[2]) + separator + sf(Self[3]);
end;

procedure TQuaternionHelper.ToRotationMatrix(out m: TMatrix4f);
var
   yy, xx, zz, xy, wz, xz, wx, wy, yz: single;

begin
   {small speedup, saves 6 multiplication operations}
   xx := Self[0] * Self[0];
   yy := Self[1] * Self[1];
   zz := Self[2] * Self[2];

   xy := Self[0] * Self[1];
   wz := Self[3] * Self[2];
   xz := Self[0] * Self[2];
   wx := Self[3] * Self[0];
   wy := Self[3] * Self[1];
   yz := Self[1] * Self[2];

	{The matrix will be filled with data from the quaternion}

   m[0, 0] := 1.0 - 2.0 * (yy + zz);
   m[1, 0] :=       2.0 * (xy - wz);
   m[2, 0] :=       2.0 * (xz + wy);

   m[0, 1] :=       2.0 * (xy + wz);
   m[1, 1] := 1.0 - 2.0 * (xx + zz);
   m[2, 1] :=       2.0 * (yz - wx);

   m[0, 2] :=       2.0 * (xz - wy);
   m[1, 2] :=       2.0 * (yz + wx);
   m[2, 2] := 1 -   2.0 * (xx + yy);

   m[3, 0] := 0.0;
   m[3, 1] := 0.0;
   m[3, 2] := 0.0;

   m[0, 3] := 0.0;
   m[1, 3] := 0.0;
   m[2, 3] := 0.0;

   m[3, 3] := 1.0;
end;

procedure TQuaternionHelper.ToRotationMatrix(out m: TMatrix3f);
var
   yy, xx, zz, xy, wz, xz, wx, wy, yz: single;

begin
   {small speedup, saves 6 multiplication operations}
   xx := Self[0] * Self[0];
   yy := Self[1] * Self[1];
   zz := Self[2] * Self[2];

   xy := Self[0] * Self[1];
   wz := Self[3] * Self[2];
   xz := Self[0] * Self[2];
   wx := Self[3] * Self[0];
   wy := Self[3] * Self[1];
   yz := Self[1] * Self[2];

	{The matrix will be filled with data from the quaternion}

   m[0, 0] := 1.0 - 2.0 * (yy + zz);
   m[1, 0] :=       2.0 * (xy - wz);
   m[2, 0] :=       2.0 * (xz + wy);

   m[0, 1] :=       2.0 * (xy + wz);
   m[1, 1] := 1.0 - 2.0 * (xx + zz);
   m[2, 1] :=       2.0 * (yz - wx);

   m[0, 2] :=       2.0 * (xz - wy);
   m[1, 2] :=       2.0 * (yz + wx);
   m[2, 2] := 1 -   2.0 * (xx + yy);
end;

END.
