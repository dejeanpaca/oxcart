{
   oxuContext, provides context management
   Copyright (c) 2011. Dejan Boras

   Started On:    09.02.2011.
}

{$INCLUDE oxdefines.inc}
UNIT oxuProjection;

INTERFACE

   USES
      uStd, uColors, vmVector, uLog,
      {oX}
      oxuAspect, oxuTypes, oxuRenderer, oxuRender, oxuTransform;

TYPE
   {projection properties}
   oxPProjectionSettings = ^oxTProjectionSettings;
   oxTProjectionSettings = record
      isOrtho: boolean; {is the projection orthographic?}
      fovY,
      zNear,
      zFar,
      l,
      r,
      b,
      t: double;
   end;

CONST
   oxDefaultProjection: oxTProjectionSettings = (
      isOrtho:    false;
      fovY:       45;
      zNear:      0.5;
      zFar:       1000.0;
      l:          -50;
      r:          50;
      b:          -50;
      t:          50
   );

TYPE
   { oxTProjection }

   oxTProjection = class
      Enabled: boolean;
      Name: string;

      Position,
      {offset the position}
      Offset: oxTPoint;
      Dimensions: oxTDimensions;

      {is the projection relative}
      Relative,
      {always scissor when clearing}
      ScissorOnClear: boolean;

      {set position and dimensions}
      Positionf: oxTPointf;
      Dimensionsf: oxTDimensionsf;

      ClearBits: TBitSet;
      ClearColor: TColor4f;

      p: oxTProjectionSettings;
      a: oxTAspect;
      ProjectionMatrix: TMatrix4f;

      constructor Create();
      constructor Create(x, y, w, h: longint);

      constructor Create(source: oxTProjection);

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
      procedure From(source: oxTProjection);

      {get normalized pointer coordinates}
      procedure GetNormalizedPointerCoordinates(x, y: single; out n: TVector2f);
      procedure GetNormalizedPointerCoordinates(x, y, z: single; out n: TVector4f);
      function Unproject(x, y, z: single; const view: TMatrix4f; out world: TVector3f): boolean;
   end;

VAR
   oxProjection: oxTProjection;

IMPLEMENTATION

constructor oxTProjection.Create();
begin
   Enabled        := true;
   ScissorOnClear := true;

   ClearBits      := oxrBUFFER_CLEAR_DEFAULT;
   p              := oxDefaultProjection;

   SetViewport(0, 0, 640, 480);
   SetProjectionMatrix();
end;

constructor oxTProjection.Create(x, y, w, h: longint);
begin
   Create();

   SetViewport(x, y, w, h);
end;

constructor oxTProjection.Create(source: oxTProjection);
begin
   From(source);
end;

procedure oxTProjection.Apply(doClear: boolean);
begin
   if(Enabled) then begin
      Viewport();

      if(doClear) then
         Clear();

      Projection();
   end;
end;

procedure oxTProjection.SetViewport(newW, newH: longint);
begin
   SetViewport(0, 0, newW, newH);
end;

procedure oxTProjection.SetViewport(newX, newY, newW, newH: longint);
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

procedure oxTProjection.SetViewportf(newX, newY, newW, newH: single);
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

procedure oxTProjection.SetOffset(offsetX, offsetY: longint);
begin
   Offset.x := offsetX;
   Offset.y := offsetY;
end;

procedure oxTProjection.Viewport();
begin
   if(Enabled) then begin
      if(not Relative) then
         oxRenderer.Viewport(Offset.x + Position.x, Offset.y + Position.y, Dimensions.w, Dimensions.h)
      else
         oxRenderer.Viewport(Offset.x + round(Dimensions.w * Positionf.x), Offset.y + round(Dimensions.h * Positionf.y),
            round(Dimensions.w * Dimensionsf.w), round(Dimensions.h  * Dimensionsf.h));
   end;
end;

procedure oxTProjection.Clear();
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

procedure oxTProjection.GetProjectionMatrix(out m: TMatrix4f);
begin
   if(not p.isOrtho) then begin
      {perspective}
      m := oxTTransform.PerspectiveFrustum(p.fovY, Dimensions.w / Dimensions.h, p.zNear, p.zFar)
   end else
      {orthographic}
      m := oxTTransform.OrthoFrustum(p.l, p.r, p.b, p.t, p.zNear, p.zFar);
end;

procedure oxTProjection.SetProjectionMatrix();
begin
   if(not p.isOrtho) then begin
      {perspective}
      ProjectionMatrix := oxTTransform.PerspectiveFrustum(p.fovY, Dimensions.w / Dimensions.h, p.zNear, p.zFar)
   end else
      {orthographic}
      ProjectionMatrix := oxTTransform.OrthoFrustum(p.l, p.r, p.b, p.t, p.zNear, p.zFar);
end;

procedure oxTProjection.Projection();
begin
   if(Enabled) then
      oxRenderer.SetProjectionMatrix(ProjectionMatrix);
end;

procedure oxTProjection.SetZ(zNear, zFar: single);
begin
   p.zNear := zNear;
   p.zFar := zFar;

   if(zNear <= 0.0) then
      log.w('zNear value should not be 0 or less');
end;

procedure oxTProjection.Ortho(zNear, zFar: single);
begin
   Ortho(Dimensions.w div 2, Dimensions.h div 2, zNear, zFar);
end;

procedure oxTProjection.Ortho(l, r, b, t: single; zNear, zFar: single);
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

procedure oxTProjection.Ortho(w, h: single; zNear, zFar: single);
var
   fx, fy: single;

begin
   fx := w * a.acX;
   fy := h * a.acY;

   Ortho(-fx, fx, -fy, fy, zNear, zFar);
end;

procedure oxTProjection.Ortho2D(w, h: single);
begin
   Ortho(w, h, -1.0, 1.0);
end;

procedure oxTProjection.QuickPerspective(fovY, zNear, zFar: single);
var
   m: TMatrix4f;

begin
   m := oxTTransform.PerspectiveFrustum(fovY, Dimensions.w / Dimensions.h, zNear, zFar);
   oxRenderer.SetProjectionMatrix(m);
end;

procedure oxTProjection.QuickOrtho2D();
var
   m: TMatrix4f;

begin
   m := oxTTransform.OrthoFrustum(-Dimensions.w div 2, Dimensions.w div 2, -Dimensions.h div 2, Dimensions.h div 2, -1.0, 1.0);
   oxRenderer.SetProjectionMatrix(m);
end;

procedure oxTProjection.QuickOrtho2DZero();
var
   m: TMatrix4f;

begin
   m := oxTTransform.OrthoFrustum(0, Dimensions.w, 0, Dimensions.h, -1.0, 1.0);
   oxRenderer.SetProjectionMatrix(m);
end;

procedure oxTProjection.Perspective(fovY, zNear, zFar: single);
begin
   p.fovY := fovY;
   p.isOrtho := false;

   SetZ(zNear, zFar);
   SetProjectionMatrix();
end;

procedure oxTProjection.GetRect(out r: oxTRect);
begin
   r.x := round(p.l);
   r.y := round(p.t);
   r.w := round(p.r - p.l);
   r.w := round(p.t - p.b);
end;

procedure oxTProjection.SetViewport(const pt: oxTPoint; const d: oxTDimensions);
begin
   SetViewport(pt.x, pt.y - d.h + 1, d.w, d.h);
end;

procedure oxTProjection.From(source: oxTProjection);
begin
   Name := source.Name;
   Enabled := source.Enabled;
   ScissorOnClear := source.ScissorOnClear;

   Position := source.Position;
   Offset := source.Offset;
   Dimensions := source.Dimensions;
   Relative := source.Relative;
   Positionf := source.Positionf;
   Dimensionsf := source.Dimensionsf;

   ClearBits := source.ClearBits;
   ClearColor := source.ClearColor;

   p := source.p;
   a := source.a;
   ProjectionMatrix := source.ProjectionMatrix;
end;

procedure oxTProjection.GetNormalizedPointerCoordinates(x, y: single; out n: TVector2f);
begin
   n[0] := (2 * x) / Dimensions.w - 1;
   n[1] := (2 * y) / Dimensions.h - 1;
end;

procedure oxTProjection.GetNormalizedPointerCoordinates(x, y, z: single; out n: TVector4f);
begin
   n[0] := (2 * x / Dimensions.w) - 1;
   n[1] := (2 * y / Dimensions.h) - 1;
   n[2] := z * 2 - 1;
   n[3] := 1;
end;


function oxTProjection.Unproject(x, y, z: single; const view: TMatrix4f; out world: TVector3f): boolean;
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
