{
   oxuTransform, transform handling
   Copyright (C) 2013. Dejan Boras

   NOTE: Rotation order is YZX
   TODO: Maybe JustApply() should be part of oxTRenderer
}

{$INCLUDE oxheader.inc}
UNIT oxuTransform;

INTERFACE

   USES
      Math, uStd, vmVector, vmQuaternions, uComponentProvider,
      {oX}
      oxuRenderer, oxuRenderers, oxuSerialization;

TYPE
   { oxTTransform }

   oxTTransform = class(oxTSerializable)
      public
      vPosition,
      vScale: TVector3f;
      vRotation: TQuaternion;

      Matrix,
      RotationMatrix: TMatrix4f;

      constructor Create(); override;

      {return matrix to identity state (does not alter other properties)}
      procedure Identity(); virtual;

      {setup matrix from vPosition, vScale and vRotation properties}
      procedure SetupMatrix();
      {apply the matrix}
      procedure Apply(); virtual;
      {apply the specified matrix (will replace the Matrix property)}
      procedure Apply(const m: TMatrix4f); virtual;
      {apply the specified matrix to the renderer without overriding this transform}
      procedure JustApply(const {%H-}m: TMatrix4f); virtual;

      procedure Translate(x, y, z: single); virtual;
      procedure GetTranslateMatrix(x, y, z: single; out m: TMatrix4f); virtual;

      procedure Rotate(const angles: TVector3f);
      procedure Rotate(x, y, z: single);
      procedure Rotate(w, x, y, z: single); inline;
      procedure GetRotationMatrix(w, x, y, z: single; out m: TMatrix4f); virtual;
      procedure RotateX(w: single); virtual;
      procedure RotateY(w: single); virtual;
      procedure RotateZ(w: single); virtual;
      procedure GetRotationMatrixX(w: single; out m: TMatrix4f); virtual;
      procedure GetRotationMatrixY(w: single; out m: TMatrix4f); virtual;
      procedure GetRotationMatrixZ(w: single; out m: TMatrix4f); virtual;

      procedure Scale(x, y, z: single); virtual;
      procedure GetScaleMatrix(x, y, z: single; out m: TMatrix4f); virtual;
      procedure Scale(s: single);

      procedure Translate(const v: TVector3f); virtual;
      procedure TranslationMatrix(const v: TVector3f); virtual;
      procedure Rotate(const v: TVector4f); inline;
      procedure Scale(const v: TVector3f); virtual;

      function GetForward(): TVector3f; virtual;
      function GetUp(): TVector3f; virtual;
      function GetRight(): TVector3f; virtual;

      procedure GetEuler(out v: TVector3f);
      procedure GetEulerYZX(out v: TVector3f; var m: TMatrix4f);
      procedure GetEulerXYZ(out v: TVector3f; var m: TMatrix4f);
      procedure GetEuler(var x, y, z: single);

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

   vRotation := vmqIdentity;
   vPosition := vmvZero3f;
   vScale := vmvOne3f;
end;

procedure oxTTransform.SetupMatrix();
begin
   vRotation.ToRotationMatrix(RotationMatrix);

   TranslationMatrix(vPosition);

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

procedure oxTTransform.JustApply(const m: TMatrix4f);
begin
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
   vmqFromEulerDeg(angles, vRotation);

   RotateY(angles[1]);
   RotateZ(angles[2]);
   RotateX(angles[0]);
end;

procedure oxTTransform.Rotate(x, y, z: single);
begin
   vRotation[1] := y;
   RotateY(y);

   vRotation[2] := z;
   RotateZ(z);

   vRotation[0] := x;
   RotateX(x);
end;

procedure oxTTransform.Rotate(w, x, y, z: single);
var
   m: TMatrix4f;

begin
   GetRotationMatrix(w, x, y, z, m);

   Matrix := Matrix * m;
end;

procedure oxTTransform.GetRotationMatrix(w, x, y, z: single; out m: TMatrix4f);
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
var
   cosw,
   sinw: single;

   m: TMatrix4f;

begin
   m := vmmUnit4;

   cosw := cos(w * vmcToRad);
   sinw := sin(w * vmcToRad);

   m[1][1] := cosw;
   m[1][2] := -sinw;

   m[2][1] := sinw;
   m[2][2] := cosw;

   Matrix := Matrix * m;
end;

procedure oxTTransform.RotateY(w: single);
var
   cosw,
   sinw: single;

   m: TMatrix4f;

begin
   m := vmmUnit4;

   cosw := cos(w * vmcToRad);
   sinw := sin(w * vmcToRad);

   m[0][0] := cosw;
   m[0][2] := sinw;

   m[2][0] := -sinw;
   m[2][2] := cosw;

   Matrix := Matrix * m;
end;

procedure oxTTransform.RotateZ(w: single);
var
   cosw,
   sinw: single;

   m: TMatrix4f;

begin
   m := vmmUnit4;

   cosw := cos(w * vmcToRad);
   sinw := sin(w * vmcToRad);

   m[0][0] := cosw;
   m[0][1] := -sinw;

   m[1][0] := sinw;
   m[1][1] := cosw;

   Matrix := Matrix * m;
end;

procedure oxTTransform.GetRotationMatrixX(w: single; out m: TMatrix4f);
var
   cosw,
   sinw: single;

begin
   m := vmmUnit4;

   cosw := cos(w * vmcToRad);
   sinw := sin(w * vmcToRad);

   m[1][1] := cosw;
   m[1][2] := -sinw;

   m[2][1] := sinw;
   m[2][2] := cosw;
end;

procedure oxTTransform.GetRotationMatrixY(w: single; out m: TMatrix4f);
var
   cosw,
   sinw: single;

begin
   m := vmmUnit4;

   cosw := cos(w * vmcToRad);
   sinw := sin(w * vmcToRad);

   m[0][0] := cosw;
   m[0][2] := sinw;

   m[2][0] := -sinw;
   m[2][2] := cosw;
end;

procedure oxTTransform.GetRotationMatrixZ(w: single; out m: TMatrix4f);
var
   cosw,
   sinw: single;

begin
   m := vmmUnit4;

   cosw := cos(w * vmcToRad);
   sinw := sin(w * vmcToRad);

   m[0][0] := cosw;
   m[0][1] := -sinw;

   m[1][0] := sinw;
   m[1][1] := cosw;
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

procedure oxTTransform.TranslationMatrix(const v: TVector3f);
begin
   Matrix := vmmUnit4;

   Matrix[0][3] := v[0];
   Matrix[1][3] := v[1];
   Matrix[2][3] := v[2];
end;

procedure oxTTransform.Rotate(const v: TVector4f);
var
   m: TMatrix4f;

begin
   GetRotationMatrix(v[3], v[0], v[1], v[2], m);

   Matrix := Matrix * m;
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
   Result[0] := Matrix[0][2];
   Result[1] := Matrix[1][2];
   Result[2] := Matrix[2][2];
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
begin
   GetEulerYZX(v, RotationMatrix);
end;

procedure oxTTransform.GetEulerYZX(out v: TVector3f; var m: TMatrix4f);
begin
   if(m[1, 0] < 0.999999) then begin
       if(m[1, 0] > -0.99999) then begin
           v[2] := arcsin(m[1, 0]);
           v[1] := arctan2(-m[2, 0], m[0, 0]);
           v[0] := arctan2(-m[1, 2], m[1, 1]);
       end else begin
           v[2] := - (vmcPi / 2);
           v[1] := - arctan2(m[2, 1], m[2, 2]);
           v[0] := 0;
       end;
   end else begin
      v[2] := vmcPi / 2;
      v[1] := arctan2(m[2, 1], m[2, 2]);
      v[0] := 0;
   end;

   v[0] := v[0] * vmcToDeg;
   v[1] := v[1] * vmcToDeg;
   v[2] := v[2] * vmcToDeg;
end;

procedure oxTTransform.GetEulerXYZ(out v: TVector3f; var m: TMatrix4f);
begin
   v := vmvZero3f;

   if(m[0, 2] < 0.999999) then begin
       if(m[0, 2] > -0.99999) then begin
           v[1] := arcsin(m[0, 2]);
           v[0] := arctan2(-m[1, 2], m[2, 2]);
           v[2] := arctan2(-m[0, 1], m[0, 0]);
       end else begin
           v[1] := - (vmcPi / 2);
           v[0] := - arctan2(m[1, 0], m[1, 1]);
           v[2] := 0;
       end;
   end else begin
      v[1] := vmcPi / 2;
      v[0] := arctan2(m[1, 0], m[1, 1]);
      v[2] := 0;
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
	fH := tan(fovY / 360 * vmcPi) * zNear;

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
