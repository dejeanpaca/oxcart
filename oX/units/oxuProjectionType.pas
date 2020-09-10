{
   oxuProjectionType, base projection type
   Copyright (c) 2011. Dejan Boras
}

{$INCLUDE oxheader.inc}
UNIT oxuProjectionType;

INTERFACE

   USES
      uStd, uColors, vmVector, uLog,
      {oX}
      oxuViewportType;

TYPE
   {projection properties}
   oxPProjectionSettings = ^oxTProjectionSettings;

   { oxTProjectionSettings }

   oxTProjectionSettings = record
      IsOrthographic: boolean; {is the projection orthographic?}
      FovY,
      Aspect,
      ZNear,
      ZFar,
      Size,
      l,
      r,
      b,
      t: double;

      function GetZDistance(): double;
      function GetWidth(): double;
      function GetHeight(): double;
   end;

   oxPProjection = ^oxTProjection;

   { oxTProjection }

   oxTProjection = record
      Name: StdString;

      Viewport: oxPViewport;

      {use viewport aspect when updating the projection}
      UseViewportAspect: boolean;

      p: oxTProjectionSettings;
      ProjectionMatrix: TMatrix4f;
   end;

CONST
   oxDefaultPerspective: oxTProjectionSettings = (
      IsOrthographic: false;
      FovY:       60;
      Aspect:     1.7777777;
      ZNear:      0.5;
      ZFar:       1000.0;
      Size:       50;
      l:          -50;
      r:          50;
      b:          -50;
      t:          50
   );

   oxDefaultOrthographic: oxTProjectionSettings = (
      IsOrthographic: true;
      FovY:       60;
      Aspect:     1.7777777;
      ZNear:      -1.0;
      ZFar:       1.0;
      Size:       50;
      l:          -50;
      r:          50;
      b:          -50;
      t:          50
   );

IMPLEMENTATION

{ oxTProjectionSettings }

function oxTProjectionSettings.GetZDistance(): double;
begin
   Result := ZFar - ZNear;
end;

function oxTProjectionSettings.GetWidth(): double;
begin
   Result := abs(l) + abs(r);
end;

function oxTProjectionSettings.GetHeight(): double;
begin
   Result := abs(t) + abs(b);
end;

END.
