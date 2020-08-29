{
   vmQuaternions, quaternion mathematics & operations
   Copyright (C) 2007. Dejan Boras
}

{$MODE OBJFPC}{$H+}
UNIT vmQuaternions;

INTERFACE

   USES vmVector, Math, vmMath;
   
TYPE
   {Quaternion type, xyz vector, and w scalar, basicaly a vector with 4 elements}
   TQuaternion       = TVector4;
   TQuaternion2d     = TVector4d;

CONST
   vmqZero: TQuaternion = (0.0, 0.0, 0.0, 0.0);
   vmqIdentity: TQuaternion = (0.0, 0.0, 0.0, 1.0);

{create a quaternion from a axis and angle}
function vmqFromAxisAngle(const axis: TVector3; degree: single): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
{create a rotation matrix out of a quaternion}
procedure vmqToMatrix(const qt: TQuaternion; var m: TMatrix4);
procedure vmqToMatrix(const qt: TQuaternion; var m: TMatrix3);
{create a quaternion out of a 4x4 matrix}
procedure vmqFromMatrix(const m: TMatrix3; var qt: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
procedure vmqFromMatrix(const m: TMatrix4; var qt: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}

procedure vmqFromMatrixAlt(const m: TMatrix3; var qt: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
procedure vmqFromMatrixAlt(const m: TMatrix4; var qt: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}

{Return a spherical linear interpolation(SLERP) of two quaternions, taking t into account}
function vmqSLERP(var q1, q2: TQuaternion; t: single): TQuaternion; {$IFDEF VM_INLINE}inline;{$ENDIF}
{calculate a quaternion from Euler angle representation}
procedure vmqFromEuler(roll, pitch, yaw: single; out q: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
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
   theta,
   res: single;
   
begin
   theta := ((degree / 180) * vmcPI);
   res   := sin(theta / 2.0);

   vmqFromAxisAngle[0] := (axis[0] * res); {x}
   vmqFromAxisAngle[1] := (axis[1] * res); {y}
   vmqFromAxisAngle[2] := (axis[2] * res); {z}
   vmqFromAxisAngle[3] := cos(theta / 2.0);{w}
end;

procedure vmqToMatrix(const qt: TQuaternion; var m: TMatrix4); {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   yy, xx, zz, xy, wz, xz, wx, wy, yz: single;
   
begin
   {small speedup, saves 6 multiplication operations}
   xx := qt[0] * qt[0];
   yy := qt[1] * qt[1];
   zz := qt[2] * qt[2];

   xy := qt[0] * qt[1];
   wz := qt[3] * qt[2];
   xz := qt[0] * qt[2];
   wx := qt[3] * qt[0];
   wy := qt[3] * qt[1];
   yz := qt[1] * qt[2];

	{The matrix will be filled with data from the quaternion}

   {row 0}	
	m[0][ 0] := 1.0 - 2.0 * (yy + zz);
	m[0][ 1] := 2.0 * (xy - wz);
	m[0][ 2] := 2.0 * (xz + wy);
	m[0][ 3] := 0.0;
	
	{row 1}
	m[1][ 0] := 2.0 * (xy + wz);
	m[1][ 1] := 1.0 - 2.0 * (xx + zz);
	m[1][ 2] := 2.0 * (yz - wx);
	m[1][ 3] := 0.0;

   {row 2}
	m[2][ 0] := 2.0 * (xz - wy);
	m[2][ 1] := 2.0 * (yz + wx);
	m[2][ 2] := 1.0 - 2.0 * (xx + yy);
	m[2][ 3] := 0.0;
   
	{row 3}
	m[3][ 0] := 0.0;
	m[3][ 1] := 0.0;
	m[3][ 2] := 0.0;
	m[3][ 3] := 1.0;
end;

procedure vmqToMatrix(const qt: TQuaternion; var m: TMatrix3);
var
   yy, xx, zz, xy, wz, xz, wx, wy, yz: single;

begin
   {small speedup, saves 6 multiplication operations}
   xx := qt[0] * qt[0];
   yy := qt[1] * qt[1];
   zz := qt[2] * qt[2];

   xy := qt[0] * qt[1];
   wz := qt[3] * qt[2];
   xz := qt[0] * qt[2];
   wx := qt[3] * qt[0];
   wy := qt[3] * qt[1];
   yz := qt[1] * qt[2];

	{The matrix will be filled with data from the quaternion}

   {row 0}
	m[0][ 0] := 1.0 - 2.0 * (yy + zz);
	m[0][ 1] := 2.0 * (xy - wz);
	m[0][ 2] := 2.0 * (xz + wy);

	{row 1}
	m[1][ 0] := 2.0 * (xy + wz);
	m[1][ 1] := 1.0 - 2.0 * (xx + zz);
	m[1][ 2] := 2.0 * (yz - wx);

   {row 2}
	m[2][ 0] := 2.0 * (xz - wy);
	m[2][ 1] := 2.0 * (yz + wx);
	m[2][ 2] := 1.0 - 2.0 * (xx + yy);
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

procedure vmqFromEuler(roll, pitch, yaw: single; out q: TQuaternion); {$IFDEF VM_INLINE}inline;{$ENDIF}
var
   cr, cp, cy, sr, sp, sy, cpcy, spsy: single; {trig identities}
   
begin
   {cosinus}
   cr := cos(roll / 2);
   cp := cos(pitch / 2);
   cy := cos(yaw / 2);

   {sinus}
   sr := sin(roll / 2);
   sp := sin(pitch / 2);
   sy := sin(yaw / 2);

   {calculate and store multiplications result, small speedup}
   cpcy := cp * cy;
   spsy := sp * sy;
   
   {calculate the quaternion}
   q[0] := sr * cpcy - cr * spsy; {x}
   q[1] := cr * sp * cy + sr * cp * sy; {y}
   q[2] := cr * cp * sy - sr * sp * cy; {z}
   q[3] := cr * cpcy + sr * spsy; {w}   
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
   r11, r21, r31, r32, r33, r12, r13,
   q00, q11, q22, q33,
   tmp: single{double};

begin
   q00 := q[3] * q[3];
   q11 := q[0] * q[0];
   q22 := q[1] * q[1];
   q33 := q[2] * q[2];

   r11 := q00 + q11 - q22 - q33;
   r21 := 2 * (q[0] + q[1] + q[3] * q[2]);
   r31 := 2 * (q[0] * q[2] - q[3] * q[1]);
   r32 := 2 * (q[1] * q[2] + q[3] * q[0]);
   r33 := q00 - q11 - q22 + q33;
   
   tmp := abs(r31);
   if(tmp > 0.999999) then begin
      r12 := 2 * (q[0] * q[1] - q[3] * q[2]);
      r13 := 2 * (q[0] * q[2] + q[3] * q[1]);
      
      vmqToEuler[0] := 0.0 * vmcToDeg;
      vmqToEuler[1] := (-(vmcPI/2) * 131/tmp) * vmcToDeg;
      vmqToEuler[2] := arctan2(-r12, -r31*r13) * vmcToDeg;
   end;

   vmqToEuler[0] := arctan2(r32, r33)*vmcToDeg;
   vmqToEuler[1] := arcsin(-r31)*vmcToDeg;
   vmqToEuler[2] := arctan2(r21, r11)*vmcToDeg;
end;

procedure vmqToEuler(var q: TQuaternion; out v: TVector3);
var
   r11, r21, r31, r32, r33, r12, r13,
   q00, q11, q22, q33,
   tmp: single{double};

begin
   q00 := q[3] * q[3];
   q11 := q[0] * q[0];
   q22 := q[1] * q[1];
   q33 := q[2] * q[2];

   r11 := q00 + q11 - q22 - q33;
   r21 := 2 * (q[0] + q[1] + q[3] * q[2]);
   r31 := 2 * (q[0] * q[2] - q[3] * q[1]);
   r32 := 2 * (q[1] * q[2] + q[3] * q[0]);
   r33 := q00 - q11 - q22 + q33;

   tmp := abs(r31);

   if(tmp > 0.999999) then begin
      r12 := 2 * (q[0] * q[1] - q[3] * q[2]);
      r13 := 2 * (q[0] * q[2] + q[3] * q[1]);

      v[0] := 0.0 * vmcToDeg;
      v[1] := (-(vmcPI/2) * 131/tmp) * vmcToDeg;
      v[2] := arctan2(-r12, -r31 * r13) * vmcToDeg;
   end;

   v[0] := arctan2(r32, r33) * vmcToDeg;
   v[1] := arcsin(-r31) * vmcToDeg;
   v[2] := arctan2(r21, r11) * vmcToDeg;
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
   vq1,
   vq2,
   tv1,
   tv2,
   tv3: TVector3;
   q3: TQuaternion;
   
begin
   vq1[0] := q1[0];
   vq1[1] := q1[1];
   vq1[2] := q1[2];

   vq2[0] := q2[0];
   vq2[1] := q2[1];
   vq2[2] := q2[2];

   tv1 := vq1;
   q3[3] := (q1[3] * q2[3]) - tv1.Dot(vq2);
   tv1 := tv1.Cross(vq2);
   
   tv2[0] := q1[3] * q2[0];
   tv2[1] := q1[3] * q2[1];
   tv2[2] := q1[3] * q2[2];

   tv3[0] := q2[3] * q1[0];
   tv3[1] := q2[3] * q1[1];
   tv3[2] := q2[3] * q1[2];
   
   q3[0] := tv1[0] + tv2[0] + tv3[0];
   q3[1] := tv1[1] + tv2[1] + tv3[1];
   q3[0] := tv2[0] + tv2[0] + tv3[0];
   
   exit(q3);
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
   vq1,
   vq2,
   tv1,
   tv2,
   tv3: TVector3;
   q3: TQuaternion;
   
begin
   vq1[0]   := q1[0];
   vq1[1]   := q1[1];
   vq1[2]   := q1[2];

   vq2[0]   := q2[0];
   vq2[1]   := q2[1];
   vq2[2]   := q2[2];

   tv1      := vq1;
   q3[3]    := (q1[3] * q2[3]) - tv1.Dot(vq2);
   tv1      := tv1.Cross(vq2);
   
   tv2[0]   := q1[3] * q2[0];
   tv2[1]   := q1[3] * q2[1];
   tv2[2]   := q1[3] * q2[2];

   tv3[0]   := q2[3] * q1[0];
   tv3[1]   := q2[3] * q1[1];
   tv3[2]   := q2[3] * q1[2];
   
   q3[0]    := tv1[0] + tv2[0] + tv3[0];
   q3[1]    := tv1[1] + tv2[1] + tv3[1];
   q3[0]    := tv2[0] + tv2[0] + tv3[0];
   
   exit(q3);
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

END.
