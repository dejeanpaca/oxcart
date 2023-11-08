{
   oxuProjection, provides projection management
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxdefines.inc}
UNIT oxuProjection;

INTERFACE

   USES
      uStd, uColors, vmVector, uLog,
      {oX}
      oxuAspect, oxuProjectionType, oxuTypes,
      oxuViewportType, oxuViewport,
      oxuSerialization,
      oxuRenderer, oxuRender, oxuTransform;

TYPE

   { oxTProjectionHelper }

   oxTProjectionHelper = record helper for oxTProjection
      class procedure Create(out projection: oxTProjection; withViewport: oxPViewport = nil); static;

      procedure Initialize(withViewport: oxPViewport);
      procedure Initialize(const source: oxTProjection);

      {apply this projection}
      procedure Apply();

      {get projection matrix from the projection settings}
      procedure GetProjectionMatrix(out m: TMatrix4f);
      {set projection matrix from the projection settings}
      procedure SetProjectionMatrix();
      {apply projection from the projection matrix}
      procedure Projection();

      {set zNear and zFar properties}
      procedure SetZ(zNear, zFar: single);

      {set properties of ortographic projection}
      procedure Ortho(zNear, zFar: single);
      procedure Ortho(l, r, b, t: single; zNear, zFar: single);
      procedure Ortho(w, h: single; zNear, zFar: single);
      procedure Ortho2D(w, h: single);

      {create a perspective correct aspect ortho}
      procedure AspectOrtho(h: single; zNear, zFar: single);

      {set default orthographic properties}
      procedure DefaultOrtho();

      {immediately make a perspective projection}
      procedure QuickPerspective(fovY, zNear, zFar: single);
      {immediately make a 2d orthographic projection}
      procedure QuickOrtho2D();
      {immediately make a 2d orthographic projection, with 0x0 as the lower left origin }
      procedure QuickOrtho2DZero();

      {set properties of perspective projection}
      procedure Perspective(fovY, aspect, zNear, zFar: single);
      {set properties of perspective projection}
      procedure Perspective(fovY, zNear, zFar: single);
      {set default perspective properties}
      procedure DefaultPerspective();

      procedure GetRect(out r: oxTRect);

      {get settings from another projection}
      procedure From(const source: oxTProjection);

      procedure UpdateViewport();

      {get normalized pointer coordinates}
      function Unproject(x, y, z: single; const view: TMatrix4f; out world: TVector3f): boolean;
   end;

VAR
   oxDefaultProjection: oxTProjection;
   oxProjection: oxPProjection;

IMPLEMENTATION

VAR
   serialization: oxTSerialization;

class procedure oxTProjectionHelper.Create(out projection: oxTProjection; withViewport: oxPViewport = nil);
begin
   ZeroPtr(@projection, SizeOf(projection));

   if(withViewport <> nil) then
      projection.Initialize(withViewport)
   else
      projection.Initialize(oxViewport);
end;

procedure oxTProjectionHelper.Initialize(withViewport: oxPViewport);
begin
   Viewport := withViewport;
   p := oxDefaultPerspective;

   SetProjectionMatrix();
end;

procedure oxTProjectionHelper.Initialize(const source: oxTProjection);
begin
   From(source);
end;

procedure oxTProjectionHelper.Apply();
begin
   Projection();
   oxProjection := @Self;
end;

procedure oxTProjectionHelper.GetProjectionMatrix(out m: TMatrix4f);
begin
   if(not p.IsOrtographic) then begin
      {perspective}
      m := oxTTransform.PerspectiveFrustum(p.FovY, Viewport^.a.Aspect, p.ZNear, p.ZFar)
   end else
      {orthographic}
      m := oxTTransform.OrthoFrustum(p.l, p.r, p.b, p.t, p.ZNear, p.ZFar);
end;

procedure oxTProjectionHelper.SetProjectionMatrix();
begin
   if(not p.IsOrtographic) then begin
      if(Viewport <> nil) then
         {perspective}
         ProjectionMatrix := oxTTransform.PerspectiveFrustum(p.FovY, p.Aspect, p.ZNear, p.ZFar)
   end else
      {orthographic}
      ProjectionMatrix := oxTTransform.OrthoFrustum(p.l, p.r, p.b, p.t, p.ZNear, p.ZFar);
end;

procedure oxTProjectionHelper.Projection();
begin
   oxRenderer.SetProjectionMatrix(ProjectionMatrix);
end;

procedure oxTProjectionHelper.SetZ(zNear, zFar: single);
begin
   p.ZNear := zNear;
   p.ZFar := zFar;

   if(zNear <= 0.0) and (not p.IsOrtographic) then
      log.w('zNear value should not be 0 or less');
end;

procedure oxTProjectionHelper.Ortho(zNear, zFar: single);
begin
   if(Viewport <> nil) then
      Ortho(Viewport^.Dimensions.w div 2, Viewport^.Dimensions.h div 2, zNear, zFar);
end;

procedure oxTProjectionHelper.Ortho(l, r, b, t: single; zNear, zFar: single);
begin
   p.IsOrtographic := true;

   p.l := l;
   p.r := r;
   p.b := b;
   p.t := t;

   SetZ(zNear, zFar);

   SetProjectionMatrix();
end;

procedure oxTProjectionHelper.Ortho(w, h: single; zNear, zFar: single);
begin
   Ortho(-w, w, -h, h, zNear, zFar);
end;

procedure oxTProjectionHelper.Ortho2D(w, h: single);
begin
   Ortho(w, h, -1.0, 1.0);
end;

procedure oxTProjectionHelper.AspectOrtho(h: single; zNear, zFar: single);
var
   fx, fy: single;

begin
   fx := h * Viewport^.a.acX;
   fy := h * Viewport^.a.acY;

   Ortho(-fx, fx, -fy, fy, zNear, zFar);
end;


procedure oxTProjectionHelper.DefaultOrtho();
begin
   Ortho(oxDefaultOrthographic.ZNear, oxDefaultOrthographic.ZFar);
end;

procedure oxTProjectionHelper.QuickPerspective(fovY, zNear, zFar: single);
begin
   Perspective(fovY, zNear, zFar);
end;

procedure oxTProjectionHelper.QuickOrtho2D();
begin
   Ortho(-Viewport^.Dimensions.w div 2, Viewport^.Dimensions.w div 2, Viewport^.Dimensions.h div 2, Viewport^.Dimensions.h div 2, -1.0, 1.0);
end;

procedure oxTProjectionHelper.QuickOrtho2DZero();
begin
   Ortho(0, Viewport^.Dimensions.w, 0, Viewport^.Dimensions.h, -1.0, 1.0);
end;

procedure oxTProjectionHelper.Perspective(fovY, aspect, zNear, zFar: single);
begin
   p.FovY := fovY;
   p.IsOrtographic := false;
   p.Aspect := aspect;

   SetZ(zNear, zFar);
   SetProjectionMatrix();
end;

procedure oxTProjectionHelper.Perspective(fovY, zNear, zFar: single);
begin
   Perspective(fovY, Viewport^.a.Aspect, zNear, zFar);
end;

procedure oxTProjectionHelper.DefaultPerspective();
begin
   Perspective(oxDefaultPerspective.FovY,
      oxDefaultPerspective.ZNear, oxDefaultPerspective.ZFar);
end;

procedure oxTProjectionHelper.GetRect(out r: oxTRect);
begin
   r.x := round(p.l);
   r.y := round(p.t);
   r.w := round(p.r - p.l);
   r.w := round(p.t - p.b);
end;

procedure oxTProjectionHelper.From(const source: oxTProjection);
begin
   Self := source;
end;

procedure oxTProjectionHelper.UpdateViewport();
begin
   if(not IsOrtographic) then
      Perspective(p.FovY, Viewport^.a.Aspect, p.ZNear, p.ZFar);
end;

function oxTProjectionHelper.Unproject(x, y, z: single; const view: TMatrix4f; out world: TVector3f): boolean;
var
   transform: TMatrix4f;
   vin, vout: TVector4f;

begin
   transform := ProjectionMatrix * view;
   transform := transform.Inversed();

   Viewport^.GetNormalizedPointerCoordinates(x, y, z, vin);

   vout := transform * vin;
   if(vout[3] = 0) then begin
      world := vmvZero3f;
      exit(false);
   end;

   vout[0] := vout[0] / vout[3];
   vout[1] := vout[1] / vout[3];
   vout[2] := vout[2] / vout[3];

   world[0] := vout[0];
   world[1] := vout[1];
   world[2] := vout[2];

   Result := true;
end;

INITIALIZATION
   oxTProjection.Create(oxDefaultProjection);
   oxProjection := @oxDefaultProjection;

   serialization := oxTSerialization.CreateRecord('oxTProjection');

   serialization.AddProperty('Name', @oxTProjection(nil^).Name, oxSerialization.Types.tString);
   serialization.AddProperty('IsOrtographic', @oxTProjection(nil^).IsOrtographic, oxSerialization.Types.Boolean);

   {TODO: Complete serialization
    serialization.AddProperty('Position', @oxTProjection(nil^).Position, oxSerialization.Types.TPoint);
    serialization.AddProperty('Offset', @oxTProjection(nil^).Offset, oxSerialization.Types.TPoint);
    serialization.AddProperty('Dimensions', @oxTProjection(nil^).Dimensions, oxSerialization.Types.TDimensions);}

FINALIZATION
   FreeObject(serialization);

END.
