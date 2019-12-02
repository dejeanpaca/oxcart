{
   oxuCamera, oX camera management
   Copyright (C) 2007. Dejan Boras

   Started On:    14.06.2007.
}

{$INCLUDE oxdefines.inc}
UNIT oxuCamera;

INTERFACE

   USES
      Math, uStd, vmVector, vmMath,
      {ox}
      oxuTransform, oxuSerialization, oxuProjectionType, oxuProjection;

CONST
   oxvCameraPosition: TVector3  = (0.0, 0.0, 0.0);
   oxvCameraView: TVector3      = (0.0, 0.0, -1.0);
   oxvCameraUp: TVector3        = (0.0, 1.0, 0.0);
   oxvCameraRight: TVector3     = (-1.0, 0.0, 0.0);

TYPE
   { oxTCamera }
   oxPCamera = ^oxTCamera;
   oxTCamera = record
      public
      {vectors}
      vPos,
      vView,
      vUp,
      vRight,
      vTarget: TVector3;

      {camera radius}
      Radius: single;

      Transform: oxTTransform;

      procedure Initialize();
      procedure Dispose();

      {reset camera to default values}
      procedure Reset();

      {move the camera's position in a specified direction}
      procedure Move(const Direction: TVector3);
      {move the camera's position in a specified direction and speed}
      procedure Move(speed: single; const Direction: TVector3);
      {moves the camera forward}
      procedure MoveForward(speed: single);
      {strafes the camera}
      procedure Strafe(speed: single);
      {moves the camera vertically(up or down)}
      procedure MoveVertical(speed: single);

      {set camera to pitch and yaw (assuming standard up vector)}
      procedure PitchYaw(pitch, yaw: single);
      {set forward (view) from rotation (in degrees)}
      procedure ForwardFromRotation(const newRotation: TVector3f);
      {increase camera angles by pitch and yaw (assuming standard up vector)}
      procedure IncPitchYaw(pitch, yaw: single);

      {create the up vector from the view vector}
      procedure UpFromView();

      {get pitch, yaw and roll}
      procedure GetRotationAngles(out v: TVector3f);

      {set up OpenGL to look the way the camera indicates}
      procedure LookAt(apply: boolean = true);
      {apply camera matrix}
      procedure Apply(const m: TMatrix4f);
      {apply camera matrix}
      procedure Apply();

      {get ray from camera with a starting and ending point}
      procedure GetRay(length: single; out vS, vE: TVector3f);
      {get object position from pointer position}
      procedure GetPointerOrigin(x, y, z: single; out origin: TVector3f; const projection: oxTProjection);
      procedure GetPointerOrigin(x, y: single; out origin: TVector3f; const projection: oxTProjection);
      {get ray from pointer position}
      procedure GetPointerRay(x, y: single; out origin, endPosition: TVector3f; const projection: oxTProjection);
   end;

VAR
   {default camera}
   oxDefaultCamera: oxTCamera;

IMPLEMENTATION

VAR
   serialization: oxTSerialization;

procedure oxTCamera.Move(const Direction: TVector3);
begin
   vPos := vPos + Direction;
end;

procedure oxTCamera.Move(speed: single; const Direction: TVector3);
begin
   vPos := vPos + (Direction * speed);
end;

procedure oxTCamera.MoveForward(speed: single);
begin
   vPos := vPos + (vView * speed);
end;

procedure oxTCamera.Strafe(speed: single);
begin
   vPos := vPos + (vRight * speed);
end;

procedure oxTCamera.MoveVertical(speed: single);
begin
   vPos := vPos + (vUp * speed);
end;

procedure oxTCamera.PitchYaw(pitch, yaw: single);
var
   vRot: TVector3f;

begin
   vRot[0] := pitch;
   vRot[1] := yaw;
   vRot[2] := 0;

   ForwardFromRotation(vRot);
end;

procedure oxTCamera.ForwardFromRotation(const newRotation: TVector3f);
var
   pitch,
   yaw: single;

begin
   pitch := newRotation[0] * vmcToRad;
   yaw   := newRotation[1] * vmcToRad;

   vView[0] := cos(pitch) * cos(yaw);
   vView[1] := sin(pitch);
   vView[2] := cos(pitch) * sin(yaw);

   vView.Normalize();

   UpFromView();
end;

procedure oxTCamera.IncPitchYaw(pitch, yaw: single);
var
   rotation: TVector3f;

begin
   GetrotationAngles(rotation);

   rotation[0] := rotation[0] + pitch;
   rotation[1] := rotation[1] + yaw;

   if(rotation[0] >= 0) then
      rotation[0] := rotation[0] mod 360.0
   else
      rotation[0] := -(abs(rotation[0]) mod 360.0);

   if(rotation[1] >= 0) then
      rotation[1] := rotation[1] mod 360.0
   else
      rotation[1] := -(abs(rotation[1]) mod 360.0);

   PitchYaw(rotation[0], rotation[1]);
end;

procedure oxTCamera.UpFromView();
begin
   vUp := oxvCameraUp;

   vRight := vView.Cross(vUp).Normalized();

   vUp := vRight.Cross(vView).Normalized();
end;

procedure oxTCamera.GetRotationAngles(out v: TVector3f);
var
   d: TVector3f;
   pitch,
   yaw: single;

begin
   d := vView;

   pitch := arcsin(d[1]);
   yaw := arctan2(d[2], d[0]);

   v[0] := pitch * vmcToDeg;
   v[1] := yaw * vmcToDeg;
   v[2] := 0;
end;

procedure oxTCamera.LookAt(apply: boolean);
var
   direction: TVector3f;

   m,
   mpos: TMatrix4f;

begin
   direction := vView * -1;
   direction.Normalize();

   m := vmmUnit4;

   m[0][0] := vRight[0];
   m[0][1] := vRight[1];
   m[0][2] := vRight[2];

   m[1][0] := vUp[0];
   m[1][1] := vUp[1];
   m[1][2] := vUp[2];

   m[2][0] := direction[0];
   m[2][1] := direction[1];
   m[2][2] := direction[2];

   mpos := vmmUnit4;

   mpos[0][3] := -vPos[0];
   mpos[1][3] := -vPos[1];
   mpos[2][3] := -vPos[2];

   if(apply) then
      Transform.Apply(m * mpos)
   else
      Transform.Matrix := m * mpos;
end;

procedure oxTCamera.Apply(const m: TMatrix4f);
begin
   oxTransform.Apply(m);
end;

procedure oxTCamera.Apply();
begin
   oxTransform.Apply();
end;

procedure oxTCamera.GetRay(length: single; out vS, vE: TVector3f);
begin
   vS := vPos + vView;
   vE := vPos + (vView * length);
end;

procedure oxTCamera.GetPointerOrigin(x, y, z: single; out origin: TVector3f; const projection: oxTProjection);
begin
   projection.Unproject(x, y, z, Transform.Matrix, origin);
end;

procedure oxTCamera.GetPointerOrigin(x, y: single; out origin: TVector3f; const projection: oxTProjection);
begin
   GetPointerOrigin(x, y, 0, origin, projection);
end;

procedure oxTCamera.GetPointerRay(x, y: single; out origin, endPosition: TVector3f; const projection: oxTProjection);
begin
   GetPointerOrigin(x, y, 0, origin, projection);
   GetPointerOrigin(x, y, 1, endPosition, projection);
end;

{ oxTCamera }

procedure oxTCamera.Initialize();
begin
   Transform := oxTTransform.Instance();

   Reset();
end;

procedure oxTCamera.Dispose();
begin
   FreeObject(Transform);
end;

procedure oxTCamera.Reset();
begin
   vPos   := oxvCameraPosition;
   vView  := oxvCameraView;
   vUp    := oxvCameraUp;
   vRight := oxvCameraRight;

   Transform.Identity();
end;

INITIALIZATION
   serialization := oxTSerialization.CreateRecord('oxTCamera');

   serialization.AddProperty('vPos', @oxTCamera(nil^).vPos, oxSerialization.Types.Vector3f);
   serialization.AddProperty('vView', @oxTCamera(nil^).vView, oxSerialization.Types.Vector3f);
   serialization.AddProperty('vUp', @oxTCamera(nil^).vUp, oxSerialization.Types.Vector3f);
   serialization.AddProperty('vRight', @oxTCamera(nil^).vRight, oxSerialization.Types.Vector3f);

   serialization.AddProperty('Radius', @oxTCamera(nil^).Radius, oxSerialization.Types.Single);

FINALIZATION
   FreeObject(serialization);

END.
