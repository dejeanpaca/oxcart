{
   oxuTransform, transform handling
   Copyright (C) 2013. Dejan Boras

   Started On:    10.12.2013.

   NOTE: Rotation order is YZX
}

{$INCLUDE oxdefines.inc}
UNIT oxuTransform;

INTERFACE

   USES
      Math, uStd, vmVector, uComponentProvider,
      {oX}
      oxuRenderer, oxuRenderers, oxuSerialization;

TYPE
   { oxTTransform }

   oxTTransform = class(oxTSerializable)
      public
      vPosition,
      vScale,
      vRotation: TVector3f;

      Matrix,
      RotationMatrix: TMatrix4f;

      constructor Create(); override;

      {return matrix to identity state (does not alter other properties)}
      procedure Identity(); virtual;
      procedure IdentityVectors();

      {setup matrix from vPosition, vScale and vRotation properties}
      procedure SetupMatrix();
      {create a final matrix using matrix and rotation matrix}
      procedure FinalizeMatrix();
      {apply the matrix}
      procedure Apply(); virtual;
      {apply the specified matrix (will replace the Matrix property)}
      procedure Apply(const m: TMatrix4f); virtual;

      procedure Translate(x, y, z: single); virtual;
      procedure GetTranslateMatrix(x, y, z: single; out m: TMatrix4f); virtual;
      procedure Rotate(const angles: TVector3f);
      procedure Rotate(x, y, z: single);
      procedure Rotate(w, x, y, z: single); virtual;
      procedure GetRotateMatrix(w, x, y, z: single; out m: TMatrix4f); virtual;
      procedure RotateX(w: single); virtual;
      procedure RotateY(w: single); virtual;
      procedure RotateZ(w: single); virtual;
      procedure Scale(x, y, z: single); virtual;
      procedure GetScaleMatrix(x, y, z: single; out m: TMatrix4f); virtual;
      procedure Scale(s: single);

      procedure Translate(const v: TVector3f); virtual;
      procedure Rotate(const v: TVector4f); virtual;
      procedure Scale(const v: TVector3f); virtual;

      function GetForward(): TVector3f; virtual;
      function GetUp(): TVector3f; virtual;
      function GetRight(): TVector3f; virtual;

      procedure GetEuler(out v: TVector3f);
      procedure GetEuler(var x, y, z: single);
      procedure GetEuler();

      {get a perspective frustum matrix}
      class function PerspectiveFrustum(l, r, b, t, n, f: single): TMatrix4f; static;
      class function PerspectiveFrustum(fovY, aspect, zNear, zFar: single): TMatrix4f; static;
      {get an ortho frustum matrix}
      class function OrthoFrustum(l, r, b, t, n, f: single): TMatrix4f; static;

      class function Instance(): oxTTransform; static;
   end;

VAR
   oxTransform: oxTTransform;
   oxTransformSerialization: oxTSerialization;

IMPLEMENTATION

VAR
   transformInstance: TSingleComponent;

{ oxglTTransformMatrixHelper }

constructor oxTTransform.Create();
begin
   vScale := vmvOne3f;
   Identity();
end;

procedure oxTTransform.Identity();
begin
   {setup the identity transform}
   Matrix := vmmUnit4;
   RotationMatrix := vmmUnit4;
end;

procedure oxTTransform.IdentityVectors();
begin
   vPosition := vmvZero3f;
   vScale := vmvUnit3f;
   vRotation := vmvZero3f;
end;

procedure oxTTransform.SetupMatrix();
begin
   RotationMatrix := vmmUnit4;

   Rotate(vRotation[1], 0, 1, 0);
   Rotate(vRotation[2], 0, 0, 1);
   Rotate(vRotation[0], 1, 0, 0);

   Matrix := vmmUnit4;

   Translate(vPosition);

   Matrix := Matrix * RotationMatrix;

   Scale(vScale);
end;

procedure oxTTransform.FinalizeMatrix();
begin
   Matrix := Matrix * RotationMatrix;

   Scale(vScale);
end;

procedure oxTTransform.Apply();
begin
end;

procedure oxTTransform.Apply(const m: TMatrix4f);
begin
   Matrix := m;
   Apply();
end;

procedure oxTTransform.Translate(x, y, z: single);
var
   m: TMatrix4f;

begin
   m := vmmUnit4;

   m[0][3] := x;
   m[1][3] := y;
   m[2][3] := z;

   Matrix := Matrix * m;
end;

procedure oxTTransform.GetTranslateMatrix(x, y, z: single; out m: TMatrix4f);
begin
   m := vmmUnit4;

   m[0][3] := x;
   m[1][3] := y;
   m[2][3] := z;

   Matrix := Matrix * m;
end;

procedure oxTTransform.Rotate(const angles: TVector3f);
begin
   vRotation := angles;

   Rotate(angles[1], 0, 1, 0);
   Rotate(angles[2], 0, 0, 1);
   Rotate(angles[0], 1, 0, 0);
end;

procedure oxTTransform.Rotate(x, y, z: single);
var
   xm, ym, zm: TMatrix4f;

begin
   GetRotateMatrix(y, 0, 1, 0, ym);
   GetRotateMatrix(z, 0, 0, 1, zm);
   GetRotateMatrix(x, 1, 0, 0, xm);

   RotationMatrix := ym * zm * xm * RotationMatrix;
end;

procedure oxTTransform.Rotate(w, x, y, z: single);
var
   c,
   s,
   cx,
   cy,
   cz: single;
   m: TMatrix4f;

begin
   w := w * vmcToRad;

   c := cos(w);
   s := sin(w);

   cx := x * (1 - c);
   cy := y * (1 - c);
   cz := z * (1 - c);

   m := vmmUnit4;

   m[0][0] := (x * cx) + c;
   m[0][1] := (x * cy) - z * s;
   m[0][2] := (x * cz) + y * s;

   m[1][0] := (y * cx) + z * s;
   m[1][1] := (y * cy) + c;
   m[1][2] := (y * cz) - x * s;

   m[2][0] := (z * cx) - y * s;
   m[2][1] := (z * cy) + x * s;
   m[2][2] := (z * cz) + c;

   RotationMatrix := m * RotationMatrix;
end;

procedure oxTTransform.GetRotateMatrix(w, x, y, z: single; out m: TMatrix4f);
var
   c,
   s,
   cx,
   cy,
   cz: single;

begin
   w := w * vmcToRad;

   c := cos(w);
   s := sin(w);

   cx := x * (1 - c);
   cy := y * (1 - c);
   cz := z * (1 - c);

   m := vmmUnit4;

   m[0][0] := (x * cx) + c;
   m[0][1] := (x * cy) - z * s;
   m[0][2] := (x * cz) + y * s;

   m[1][0] := (y * cx) + z * s;
   m[1][1] := (y * cy) + c;
   m[1][2] := (y * cz) - x * s;

   m[2][0] := (z * cx) - y * s;
   m[2][1] := (z * cy) + x * s;
   m[2][2] := (z * cz) + c;
end;

procedure oxTTransform.RotateX(w: single);
begin
   Rotate(w, 1, 0, 0);
end;

procedure oxTTransform.RotateY(w: single);
begin
   Rotate(w, 0, 1, 0);
end;

procedure oxTTransform.RotateZ(w: single);
begin
   Rotate(w, 0, 0, 1);
end;

procedure oxTTransform.Scale(x, y, z: single);
var
   m: TMatrix4f;

begin
   m := vmmUnit4;

   m[0][0] := x;
   m[1][1] := y;
   m[2][2] := z;

   Matrix := Matrix * m;
end;

procedure oxTTransform.GetScaleMatrix(x, y, z: single; out m: TMatrix4f);
begin
   m := vmmUnit4;

   m[0][0] := x;
   m[1][1] := y;
   m[2][2] := z;
end;

procedure oxTTransform.Scale(s: single);
begin
   Scale(s, s, s);
end;

procedure oxTTransform.Translate(const v: TVector3f);
var
   m: TMatrix4f;

begin
   m := vmmUnit4;

   m[0][3] := v[0];
   m[1][3] := v[1];
   m[2][3] := v[2];

   Matrix := Matrix * m;
end;

procedure oxTTransform.Rotate(const v: TVector4f);
begin
   Rotate(v[3], v[0], v[1], v[2]);
end;

procedure oxTTransform.Scale(const v: TVector3f);
var
   m: TMatrix4f;

begin
   m := vmmUnit4;

   m[0][0] := v[0];
   m[1][1] := v[1];
   m[2][2] := v[2];

   Matrix := Matrix * m;
end;

function oxTTransform.GetForward(): TVector3f;
begin
   Result[0] := -Matrix[0][2];
   Result[1] := -Matrix[1][2];
   Result[2] := -Matrix[2][2];
end;

function oxTTransform.GetUp(): TVector3f;
begin
   Result[0] := Matrix[0][1];
   Result[1] := Matrix[1][1];
   Result[2] := Matrix[2][1];
end;

function oxTTransform.GetRight(): TVector3f;
begin
   Result[0] := Matrix[0][0];
   Result[1] := Matrix[1][0];
   Result[2] := Matrix[2][0];
end;

procedure oxTTransform.GetEuler(out v: TVector3f);
var
   sy: single;
   singular: Boolean;


begin
   if(Matrix[0][0] = 1.0) then begin
      v[1] := arctan2(Matrix[0][2], Matrix[2][3]);
      v[0] := 0;
      v[2] := 0;
   end else if(Matrix[0][0] = -1.0) then begin
      v[1] := arctan2(Matrix[0][2], Matrix[2][3]);
      v[0] := 0;
      v[2] := 0;
   end else begin
      v[0] := arctan2(Matrix[2][0], Matrix[0][0]);
      v[1] := arcsin(Matrix[1][0]);
      v[2] := arctan2(Matrix[1][2], Matrix[1][1]);
   end;

   v[0] := v[0] * vmcToDeg;
   v[1] := v[1] * vmcToDeg;
   v[2] := v[2] * vmcToDeg;
end;

procedure oxTTransform.GetEuler(var x, y, z: single);
var
   v: TVector3f;

begin
   GetEuler(v);

   x := v[0];
   y := v[1];
   z := v[2];
end;

procedure oxTTransform.GetEuler();
begin
   GetEuler(vRotation);
end;

class function oxTTransform.PerspectiveFrustum(l, r, b, t, n, f: single): TMatrix4f;
begin
   Result := vmmZero4;

   Result[0][0] := (2 * n) / (r - l);
   Result[1][1] := (2 * n) / (t - b);

   Result[0][2] := (r + l) / (r - l); {A}
   Result[1][2] := (t + b) / (t - b); {B}
   Result[2][2] := - ((f + n) / (f - n)); {C}

   Result[2][3] := - ((2 * f * n) / (f - n)); {D}

   Result[3][2] := -1;
end;

class function oxTTransform.PerspectiveFrustum(fovY, aspect, zNear, zFar: single): TMatrix4f;
var
   fW,
   fH: double;

begin
	fH := tan(fovY / 360 * vmcPI) * zNear;

	fW := fH * aspect;

   Result := PerspectiveFrustum(-fW, fW, -fH, fH, zNear, zFar);
end;

class function oxTTransform.OrthoFrustum(l, r, b, t, n, f: single): TMatrix4f;
begin
   Result := vmmUnit4;

   Result[0][0] := 2 / (r - l);
   Result[1][1] := 2 / (t - b);
   Result[2][2] := -2 / (f - n);

   Result[0][3] := - ((r + l) / (r - l)); {tx}
   Result[1][3] := - ((t + b) / (t - b)); {ty}
   Result[2][3] := - ((f + n) / (f - n)); {tz}
end;

class function oxTTransform.Instance(): oxTTransform; static;
begin
   if(transformInstance.Return <> nil) then
      Result := oxTTransform(transformInstance.Return())
   else
      Result := oxTTransform.Create();
end;

{ oxTTextureGlobal }

procedure onUse();
var
   pTransformInstance: PSingleComponent;

begin
   pTransformInstance := oxRenderer.FindComponent('transform');

   if(pTransformInstance <> nil) then
      transformInstance := pTransformInstance^;
end;

procedure onStart();
begin
   FreeObject(oxTransform);
   oxTransform := oxTTransform.Instance();
end;

function instance(): TObject;
begin
   Result := oxTTransform.Instance();
end;

procedure init();
begin
   oxTransformSerialization := oxTSerialization.Create(oxTTransform, @instance);
   oxTransformSerialization.AddProperty('vPosition', @oxTTransform(nil).vPosition, oxSerialization.Types.Vector3f);
   oxTransformSerialization.AddProperty('vScale', @oxTTransform(nil).vScale, oxSerialization.Types.Vector3f);
   oxTransformSerialization.AddProperty('vRotation', @oxTTransform(nil).vRotation, oxSerialization.Types.Vector3f);
   oxTransformSerialization.PropertiesDone();
end;

INITIALIZATION
   oxRenderers.UseRoutines.Add(@onUse);
   oxRenderers.StartRoutines.Add(@onStart);

   init();

FINALIZATION
   FreeObject(oxTransform);
   FreeObject(oxTransformSerialization);

END.
