{
   oxuProjection, provides projection management
   Copyright (c) 2011. Dejan Boras

   Started On:    09.02.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuProjection;

INTERFACE

   USES
      uStd, uColors, vmVector, uLog,
      {oX}
      oxuAspect, oxuProjectionType, oxuTypes, oxuRenderer, oxuRender, oxuTransform;

TYPE
   oxTProjectionHelper = record helper for oxTProjection
      procedure Initialize();
      procedure Initialize(x, y, w, h: longint);

      procedure Initialize(const source: oxTProjection);

      {apply this projection}
      procedure Apply(doClear: boolean = true);

      {set viewport properties}
      procedure SetViewport(newW, newH: longint);
      procedure SetViewport(newX, newY, newW, newH: longint);
      procedure SetViewportf(newX, newY, newW, newH: single);
      {set the new offset}
      procedure SetOffset(offsetX, offsetY: longint);
      {sets a viewport from the projection}
      procedure Viewport();

      {clear buffers}
      procedure Clear();

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

      {immediately make a perspective projection}
      procedure QuickPerspective(fovY, zNear, zFar: single);
      {immediately make a 2d orthographic projection}
      procedure QuickOrtho2D();
      {immediately make a 2d orthographic projection, with 0x0 as the lower left origin }
      procedure QuickOrtho2DZero();

      {set properties of perspective projection}
      procedure Perspective(fovY, zNear, zFar: single);

      procedure GetRect(out r: oxTRect);

      procedure SetViewport(const pt: oxTPoint; const d: oxTDimensions);
      {get settings from another projection}
      procedure From(const source: oxTProjection);

      {get normalized pointer coordinates}
      procedure GetNormalizedPointerCoordinates(x, y: single; out n: TVector2f);
      procedure GetNormalizedPointerCoordinates(x, y, z: single; out n: TVector4f);
      function Unproject(x, y, z: single; const view: TMatrix4f; out world: TVector3f): boolean;
   end;

VAR
   oxProjection: oxPProjection;

IMPLEMENTATION

procedure oxTProjectionHelper.Initialize();
begin
   Enabled        := true;
   ScissorOnClear := true;

   ClearBits      := oxrBUFFER_CLEAR_DEFAULT;
   p              := oxDefaultProjection;

   SetViewport(0, 0, 640, 480);
   SetProjectionMatrix();
end;

procedure oxTProjectionHelper.Initialize(x, y, w, h: longint);
begin
   Initialize();

   SetViewport(x, y, w, h);
end;

procedure oxTProjectionHelper.Initialize(const source: oxTProjection);
begin
   From(source);
end;

procedure oxTProjectionHelper.Apply(doClear: boolean);
begin
   if(Enabled) then begin
      Viewport();

      if(doClear) then
         Clear();

      Projection();
   end;
end;

procedure oxTProjectionHelper.SetViewport(newW, newH: longint);
begin
   SetViewport(0, 0, newW, newH);
end;

procedure oxTProjectionHelper.SetViewport(newX, newY, newW, newH: longint);
begin
   if (Dimensions.w <> newW) or (Dimensions.h <> newH) or (newX <> Position.x) or (newY <> Position.y) then begin
      Dimensions.w := newW;
      Dimensions.h := newH;

      Position.x := newX;
      Position.y := newY;

      a.Calculate(Dimensions.w, Dimensions.h);
      SetProjectionMatrix();
   end;
end;

procedure oxTProjectionHelper.SetViewportf(newX, newY, newW, newH: single);
begin
   Relative := true;

   if (Dimensionsf.w <> newW) or (Dimensionsf.h <> newH) or (Positionf.x <> newX) or (Positionf.y <> newY) then begin
      Dimensionsf.w := newW;
      Dimensionsf.h := newH;

      Positionf.x := newX;
      Positionf.y := newY;

      a.Calculate(Dimensionsf.w, Dimensionsf.h);
      SetProjectionMatrix();
   end;
end;

procedure oxTProjectionHelper.SetOffset(offsetX, offsetY: longint);
begin
   Offset.x := offsetX;
   Offset.y := offsetY;
end;

procedure oxTProjectionHelper.Viewport();
begin
   if(Enabled) then begin
      if(not Relative) then
         oxRenderer.Viewport(Offset.x + Position.x, Offset.y + Position.y, Dimensions.w, Dimensions.h)
      else
         oxRenderer.Viewport(Offset.x + round(Dimensions.w * Positionf.x), Offset.y + round(Dimensions.h * Positionf.y),
            round(Dimensions.w * Dimensionsf.w), round(Dimensions.h  * Dimensionsf.h));
   end;
end;

procedure oxTProjectionHelper.Clear();
begin
   oxRenderer.ClearColor(ClearColor);

   if(Enabled) then begin
      if(ScissorOnClear) then
         oxRender.Scissor(Offset.x + Position.x, Offset.y + Position.y + Dimensions.h - 1, Dimensions.w, Dimensions.h);

      oxRenderer.Clear(ClearBits);

      if(ScissorOnClear) then
         oxRender.DisableScissor();
   end;
end;

procedure oxTProjectionHelper.GetProjectionMatrix(out m: TMatrix4f);
begin
   if(not p.isOrtho) then begin
      {perspective}
      m := oxTTransform.PerspectiveFrustum(p.fovY, Dimensions.w / Dimensions.h, p.zNear, p.zFar)
   end else
      {orthographic}
      m := oxTTransform.OrthoFrustum(p.l, p.r, p.b, p.t, p.zNear, p.zFar);
end;

procedure oxTProjectionHelper.SetProjectionMatrix();
begin
   if(not p.isOrtho) then begin
      {perspective}
      ProjectionMatrix := oxTTransform.PerspectiveFrustum(p.fovY, Dimensions.w / Dimensions.h, p.zNear, p.zFar)
   end else
      {orthographic}
      ProjectionMatrix := oxTTransform.OrthoFrustum(p.l, p.r, p.b, p.t, p.zNear, p.zFar);
end;

procedure oxTProjectionHelper.Projection();
begin
   if(Enabled) then
      oxRenderer.SetProjectionMatrix(ProjectionMatrix);
end;

procedure oxTProjectionHelper.SetZ(zNear, zFar: single);
begin
   p.zNear := zNear;
   p.zFar := zFar;

   if(zNear <= 0.0) then
      log.w('zNear value should not be 0 or less');
end;

procedure oxTProjectionHelper.Ortho(zNear, zFar: single);
begin
   Ortho(Dimensions.w div 2, Dimensions.h div 2, zNear, zFar);
end;

procedure oxTProjectionHelper.Ortho(l, r, b, t: single; zNear, zFar: single);
begin
   p.isOrtho := true;

   p.l := l;
   p.r := r;
   p.b := b;
   p.t := t;

   SetZ(zNear, zFar);

   if(zNear <= 0.0) then
      log.w('zNear value should not be 0 or less');

   SetProjectionMatrix();
end;

procedure oxTProjectionHelper.Ortho(w, h: single; zNear, zFar: single);
var
   fx, fy: single;

begin
   fx := w * a.acX;
   fy := h * a.acY;

   Ortho(-fx, fx, -fy, fy, zNear, zFar);
end;

procedure oxTProjectionHelper.Ortho2D(w, h: single);
begin
   Ortho(w, h, -1.0, 1.0);
end;

procedure oxTProjectionHelper.QuickPerspective(fovY, zNear, zFar: single);
var
   m: TMatrix4f;

begin
   m := oxTTransform.PerspectiveFrustum(fovY, Dimensions.w / Dimensions.h, zNear, zFar);
   oxRenderer.SetProjectionMatrix(m);
end;

procedure oxTProjectionHelper.QuickOrtho2D();
var
   m: TMatrix4f;

begin
   m := oxTTransform.OrthoFrustum(-Dimensions.w div 2, Dimensions.w div 2, -Dimensions.h div 2, Dimensions.h div 2, -1.0, 1.0);
   oxRenderer.SetProjectionMatrix(m);
end;

procedure oxTProjectionHelper.QuickOrtho2DZero();
var
   m: TMatrix4f;

begin
   m := oxTTransform.OrthoFrustum(0, Dimensions.w, 0, Dimensions.h, -1.0, 1.0);
   oxRenderer.SetProjectionMatrix(m);
end;

procedure oxTProjectionHelper.Perspective(fovY, zNear, zFar: single);
begin
   p.fovY := fovY;
   p.isOrtho := false;

   SetZ(zNear, zFar);
   SetProjectionMatrix();
end;

procedure oxTProjectionHelper.GetRect(out r: oxTRect);
begin
   r.x := round(p.l);
   r.y := round(p.t);
   r.w := round(p.r - p.l);
   r.w := round(p.t - p.b);
end;

procedure oxTProjectionHelper.SetViewport(const pt: oxTPoint; const d: oxTDimensions);
begin
   SetViewport(pt.x, pt.y - d.h + 1, d.w, d.h);
end;

procedure oxTProjectionHelper.From(const source: oxTProjection);
begin
   Enabled := source.Enabled;
   Name := source.Name;

   Position := source.Position;
   Offset := source.Offset;
   Dimensions := source.Dimensions;
   Relative := source.Relative;
   ScissorOnClear := source.ScissorOnClear;
   Positionf := source.Positionf;
   Dimensionsf := source.Dimensionsf;

   ClearBits := source.ClearBits;
   ClearColor := source.ClearColor;

   p := source.p;
   a := source.a;
   ProjectionMatrix := source.ProjectionMatrix;
end;

procedure oxTProjectionHelper.GetNormalizedPointerCoordinates(x, y: single; out n: TVector2f);
begin
   n[0] := (2 * x) / Dimensions.w - 1;
   n[1] := (2 * y) / Dimensions.h - 1;
end;

procedure oxTProjectionHelper.GetNormalizedPointerCoordinates(x, y, z: single; out n: TVector4f);
begin
   n[0] := (2 * x / Dimensions.w) - 1;
   n[1] := (2 * y / Dimensions.h) - 1;
   n[2] := z * 2 - 1;
   n[3] := 1;
end;


function oxTProjectionHelper.Unproject(x, y, z: single; const view: TMatrix4f; out world: TVector3f): boolean;
var
   transform: TMatrix4f;
   vin, vout: TVector4f;

begin
   transform := ProjectionMatrix * view;
   transform := transform.Inversed();

   GetNormalizedPointerCoordinates(x, y, z, vin);

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

END.
