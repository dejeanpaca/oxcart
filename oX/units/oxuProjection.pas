{
   oxuProjection, provides projection management
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuProjection;

INTERFACE

   USES
      sysutils, uStd, uColors, vmVector, uLog, StringUtils,
      {oX}
      oxuAspect, oxuProjectionType, oxuTypes,
      oxuViewportType, oxuViewport,
      oxuSerialization,
      oxuRenderer, oxuRender, oxuRenderingContext, oxuTransform;

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

      {set properties of orthographic projection}
      procedure Ortho(size, zNear, zFar: single);
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
      procedure UseViewport(var v: oxTViewport);

      {get world position for given pointer coordinates}
      function Unproject(x, y, z: single; const view: TMatrix4f; out world: TVector3f): boolean;
      {get world position for given pointer coordinates for 2D (works only for straight ortho view, as Z is lost)}
      function Unproject(x, y: single; const view: TMatrix4f; out world: TVector2f): boolean;

      {get description of the projection}
      function GetDescription(): StdString;
   end;

IMPLEMENTATION

VAR
   serialization: oxTSerialization;

class procedure oxTProjectionHelper.Create(out projection: oxTProjection; withViewport: oxPViewport = nil);
begin
   ZeroPtr(@projection, SizeOf(projection));

   if(withViewport <> nil) then
      projection.Initialize(withViewport)
   else
      projection.Initialize(oxRenderingContext.Viewport);
end;

procedure oxTProjectionHelper.Initialize(withViewport: oxPViewport);
begin
   Viewport := withViewport;
   p := oxDefaultPerspective;
   UseViewportAspect := True;

   SetProjectionMatrix();
end;

procedure oxTProjectionHelper.Initialize(const source: oxTProjection);
begin
   From(source);
end;

procedure oxTProjectionHelper.Apply();
begin
   Projection();
   oxRenderingContext.Projection := @Self;
end;

procedure oxTProjectionHelper.GetProjectionMatrix(out m: TMatrix4f);
begin
   if(not p.IsOrthographic) then begin
      {perspective}
      m := oxTTransform.PerspectiveFrustum(p.FovY, Viewport^.a.Aspect, p.ZNear, p.ZFar)
   end else
      {orthographic}
      m := oxTTransform.OrthoFrustum(p.l, p.r, p.b, p.t, p.ZNear, p.ZFar);
end;

procedure oxTProjectionHelper.SetProjectionMatrix();
begin
   if(not p.IsOrthographic) then begin
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

   if(zNear <= 0.0) and (not p.IsOrthographic) then
      log.w('zNear value should not be 0 or less');
end;

procedure oxTProjectionHelper.Ortho(size, zNear, zFar: single);
var
   s: single;

begin
   p.IsOrthographic := true;
   UseViewportAspect := true;

   p.Aspect := Viewport^.a.Aspect;
   p.Size := size;

   SetZ(zNear, zFar);

   s := size / 2;

   p.l := -s;
   p.r := s;
   p.b := -s;
   p.t := s;

   {we asssume size is minimum size for width or height, whichever is smaller}

   if(p.Aspect > 1) then begin
      p.l := -s * p.Aspect;
      p.r := s * p.Aspect;
      p.b := -s;
      p.t := s;
   end else if(p.Aspect < 1) then begin
      p.l := -s;
      p.r := s;
      p.b := -s / p.Aspect;
      p.t := s / p.Aspect;
   end;

   SetProjectionMatrix();
end;

procedure oxTProjectionHelper.Ortho(zNear, zFar: single);
begin
   if(Viewport <> nil) then
      Ortho(Viewport^.Dimensions.w div 2, Viewport^.Dimensions.h div 2, zNear, zFar);
end;

procedure oxTProjectionHelper.Ortho(l, r, b, t: single; zNear, zFar: single);
begin
   p.IsOrthographic := true;
   UseViewportAspect := false;

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
   p.IsOrthographic := false;
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
   if(UseViewportAspect) then begin
      if(not p.IsOrthographic) then
         Perspective(p.FovY, Viewport^.a.Aspect, p.ZNear, p.ZFar)
      else begin
         if(abs(p.Size) > TSingleHelper.Epsilon) then
            Ortho(p.Size, p.ZNear, p.ZFar);
      end;
   end;
end;

procedure oxTProjectionHelper.UseViewport(var v: oxTViewport);
begin
   Viewport := @v;
   UpdateViewport();
end;

function oxTProjectionHelper.Unproject(x, y, z: single; const view: TMatrix4f; out world: TVector3f): boolean;
var
   transform: TMatrix4f;
   vin,
   vout: TVector4f;

begin
   transform := ProjectionMatrix * view;
   transform := transform.Inversed();

   Viewport^.GetNormalizedPointerCoordinates(x, y, z, vin);

   vout := transform * vin;
   if(vout[3] = 0) then begin
      world := vmvZero3f;
      exit(false);
   end;

   world[0] := vout[0] / vout[3];
   world[1] := vout[1] / vout[3];
   world[2] := vout[2] / vout[3];

   Result := true;
end;

function oxTProjectionHelper.Unproject(x, y: single; const view: TMatrix4f; out world: TVector2f): boolean;
var
   world3: TVector3f;

begin
   world := vmvZero2f;

   Result := Unproject(x, y, 0.0, view, world3);

   if(Result) then begin
      world[0] := world3[0];
      world[1] := world3[1];
   end else
      world := vmvZero2f;
end;

function oxTProjectionHelper.GetDescription(): StdString;
begin
   if(not p.IsOrthographic) then begin
      Result := 'Perspective > Aspect: ' + sf(p.Aspect, 3) + ', FovY: ' + sf(p.FovY, 2) + ', Z(' + sf(p.ZNear, 3) + ' .. ' + sf(p.ZFar, 3) + ')';
   end else begin
      if(p.Size > 0) then
         Result := 'Ortho > Aspect: ' + sf(p.Aspect, 3) + ', Size: ' + sf(p.Size, 3) +
            '(' + sf(p.GetWidth(), 3) + 'x' + sf(p.GetHeight(), 3) +
            '), Z(' + sf(p.ZNear, 3) + ' .. ' + sf(p.ZFar, 3) + ')'
      else
         Result := 'Ortho > Aspect: ' + sf(p.Aspect, 3) + ', Z(' + sf(p.ZNear, 3) + ' .. ' + sf(p.ZFar, 3) + '), ' +
            'l: ' + sf(p.l, 3) + ', r: ' + sf(p.r, 3) + ', t: ' + sf(p.t, 3) + ', b: ' + sf(p.b, 3);
   end;
end;

INITIALIZATION
   serialization := oxTSerialization.CreateRecord('oxTProjection');

   serialization.AddProperty('Name', @oxTProjection(nil^).Name, oxSerialization.Types.tString);
   serialization.AddProperty('IsOrthographic', @oxTProjection(nil^).p.IsOrthographic, oxSerialization.Types.Boolean);

   serialization.AddProperty('FovY', @oxTProjection(nil^).p.FovY, oxSerialization.Types.Single);
   serialization.AddProperty('Aspect', @oxTProjection(nil^).p.Aspect, oxSerialization.Types.Single);
   serialization.AddProperty('ZNear', @oxTProjection(nil^).p.ZNear, oxSerialization.Types.Single);
   serialization.AddProperty('ZFar', @oxTProjection(nil^).p.ZFar, oxSerialization.Types.Single);
   serialization.AddProperty('Size', @oxTProjection(nil^).p.Size, oxSerialization.Types.Single);
   serialization.AddProperty('Left', @oxTProjection(nil^).p.l, oxSerialization.Types.Single);
   serialization.AddProperty('Right', @oxTProjection(nil^).p.r, oxSerialization.Types.Single);
   serialization.AddProperty('Top', @oxTProjection(nil^).p.t, oxSerialization.Types.Single);
   serialization.AddProperty('Bottom', @oxTProjection(nil^).p.b, oxSerialization.Types.Single);

FINALIZATION
   FreeObject(serialization);

END.
