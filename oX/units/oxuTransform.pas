{
   oxuTransform, transform handling
   Copyright (C) 2013. Dejan Boras

   Started On:    10.12.2013.
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

      Matrix: TMatrix4f;

      constructor Create(); override;

      {return matrix to identity state (does not alter other properties)}
      procedure Identity(); virtual;
      procedure IdentityVectors();

      {setup matrix from vPosition, vScale and vRotation properties}
      procedure SetupMatrix();
      {apply the matrix}
      procedure Apply(); virtual;
      {apply the specified matrix (will replace the Matrix property)}
      procedure Apply(const m: TMatrix4f); virtual;

      procedure Translate(x, y, z: single); virtual;
      procedure Rotate(x, y, z: single);
      procedure Rotate(w, x, y, z: single); virtual;
      procedure RotateX(w: single); virtual;
      procedure RotateY(w: single); virtual;
      procedure RotateZ(w: single); virtual;
      procedure Scale(x, y, z: single); virtual;
      procedure Scale(s: single);

      procedure Translate(const v: TVector3f); virtual;
      procedure Rotate(const v: TVector4f); virtual;
      procedure Scale(const v: TVector3f); virtual;

      {get a perspective frustum matrix}
      class function PerspectiveFrustum(l, r, b, t, n, f: single): TMatrix4f; static;
      class function PerspectiveFrustum(fovY, aspect, zNear, zFar: single): TMatrix4f; static;
      {get an ortho frustum matrix}
      class function OrthoFrustum(l, r, b, t, n, f: single): TMatrix4f; static;

      class function Instance(): oxTTransform; static;

      published
         property vpPositionX: single read vPosition[0] write vPosition[0];
         property vpPositionY: single read vPosition[1] write vPosition[1];
         property vpPositionZ: single read vPosition[2] write vPosition[2];

         property vpScaleX: single read vScale[0] write vScale[0];
         property vpScaleY: single read vScale[1] write vScale[1];
         property vpScaleZ: single read vScale[2] write vScale[2];

         property vpRotationX: single read vRotation[0] write vRotation[0];
         property vpRotationY: single read vRotation[1] write vRotation[1];
         property vpRotationZ: single read vRotation[2] write vRotation[2];
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
   Matrix       := vmmUnit4;
end;

procedure oxTTransform.IdentityVectors();
begin
   vPosition := vmvZero3f;
   vScale := vmvUnit3f;
   vRotation := vmvZero3f;
end;

procedure oxTTransform.SetupMatrix();
begin
   Matrix := vmmUnit4;
   Translate(vPosition);
   RotateX(vRotation[0]);
   RotateY(vRotation[1]);
   RotateZ(vRotation[2]);
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

procedure oxTTransform.Rotate(x, y, z: single);
begin
   Rotate(x, 1, 0, 0);
   Rotate(y, 0, 1, 0);
   Rotate(z, 0, 0, 1);
end;

procedure oxTTransform.Rotate(w, x, y, z: single);
var
   c, s, c1, c2, c3: single;
   m: TMatrix4f;

begin
   w := w * vmcToRad;

   c := cos(w);
   s := sin(w);

   c1 := x * (1 - c);
   c2 := y * (1 - c);
   c3 := z * (1 - c);

   m := vmmUnit4;

   m[0][0] := (x * c1) + c;
   m[0][1] := (x * c2) - z * s;
   m[0][2] := (x * c3) + y * s;

   m[1][0] := (y * c1) + z * s;
   m[1][1] := (y * c2) + c;
   m[1][2] := (y * c3) - x * s;

   m[2][0] := (x * c3) - y * s;
   m[2][1] := (y * c3) + x * s;
   m[2][2] := (z * c3) + c;

   Matrix := Matrix * m;
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
